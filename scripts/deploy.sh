#!/bin/bash
#
# ExternalAccess Deployment Script
# Deploys Tailscale subnet router and Nginx Proxy Manager
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NPM_DIR="$PROJECT_DIR/docker/nginx-proxy-manager"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo "========================================"
echo "   ExternalAccess Deployment"
echo "   $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo

# Pre-flight checks
info "Running pre-flight checks..."

if [ "$(id -u)" -eq 0 ]; then
    error "Do not run as root. Script will use sudo when needed."
fi

if ! command -v docker &> /dev/null; then
    error "Docker not found. Please install Docker first."
fi

if ! docker info &> /dev/null; then
    error "Docker daemon not running or user not in docker group."
fi

# Check for port conflicts
if ss -tlnp | grep -q ':80 ' && ! docker ps | grep -q nginx-proxy-manager; then
    error "Port 80 in use by non-NPM service. Resolve conflict first."
fi

echo

# Step 1: Install Tailscale (if not present)
info "Checking Tailscale installation..."

if ! command -v tailscale &> /dev/null; then
    info "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    info "Tailscale already installed: $(tailscale version | head -1)"
fi

# Step 2: Configure Tailscale as subnet router
info "Configuring Tailscale as subnet router..."

if ! tailscale status &> /dev/null; then
    info "Starting Tailscale authentication..."
    echo
    echo "A browser window will open for authentication."
    echo "After authenticating, approve the subnet route in the admin console:"
    echo "  https://login.tailscale.com/admin/machines"
    echo
    sudo tailscale up --advertise-routes=192.168.0.0/24 --accept-dns=false
else
    # Check if already advertising routes
    if tailscale status | grep -q "192.168.0.0/24"; then
        info "Subnet route already advertised"
    else
        info "Advertising subnet route..."
        sudo tailscale set --advertise-routes=192.168.0.0/24
    fi
fi

echo

# Step 3: Verify IP forwarding
info "Verifying IP forwarding..."

if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ]; then
    warn "IP forwarding disabled. Enabling..."
    echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
    sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
else
    info "IP forwarding already enabled"
fi

echo

# Step 4: Generate secrets (if not present)
info "Checking secrets..."

SECRETS_DIR="$NPM_DIR/secrets"
mkdir -p "$SECRETS_DIR"

if [ ! -f "$SECRETS_DIR/npm_db_password.txt" ]; then
    info "Generating database password..."
    openssl rand -base64 32 > "$SECRETS_DIR/npm_db_password.txt"
fi

if [ ! -f "$SECRETS_DIR/npm_db_root_password.txt" ]; then
    info "Generating database root password..."
    openssl rand -base64 32 > "$SECRETS_DIR/npm_db_root_password.txt"
fi

# Secure permissions
chmod 600 "$SECRETS_DIR"/*.txt

echo

# Step 5: Deploy Nginx Proxy Manager
info "Deploying Nginx Proxy Manager..."

cd "$NPM_DIR"
docker compose up -d

# Wait for health check
info "Waiting for NPM to become healthy..."
sleep 10

ATTEMPTS=0
MAX_ATTEMPTS=30

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if docker ps | grep nginx-proxy-manager | grep -q "healthy"; then
        info "NPM is healthy"
        break
    fi

    if docker ps | grep nginx-proxy-manager | grep -q "unhealthy"; then
        error "NPM is unhealthy. Check logs: docker logs nginx-proxy-manager"
    fi

    ((ATTEMPTS++))
    echo -n "."
    sleep 2
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    warn "NPM health check timeout. Container may still be starting."
fi

echo
echo

# Step 6: Display access information
info "Deployment complete!"
echo
echo "========================================"
echo "   Access Information"
echo "========================================"
echo
echo "NPM Admin UI: http://192.168.0.8:81"
echo
echo "Default credentials (CHANGE IMMEDIATELY):"
echo "  Email: admin@example.com"
echo "  Password: changeme"
echo
echo "Tailscale Status:"
tailscale status | head -5
echo
echo "========================================"
echo "   Next Steps"
echo "========================================"
echo
echo "1. Approve subnet route in Tailscale admin console"
echo "2. Change NPM default credentials"
echo "3. Add SSL certificates"
echo "4. Configure proxy hosts"
echo "5. Run validation: ./scripts/validate.sh"
echo
