# Setup Guide

## Prerequisites

- Ubuntu 24.04 LTS (or compatible Linux distribution)
- Docker 29.x+ with Docker Compose
- Tailscale account
- Domain name(s) for TLS certificates
- SSH access to host

---

## Phase 1: Pre-Flight Verification

Before proceeding, verify the pre-flight checks have passed.

```bash
# Review pre-flight documentation
cat docs/PRE-FLIGHT.md

# Verify no conflicts on ports 80/443
ss -tlnp | grep -E ':(80|443)\s'

# If Wiki.js is on port 80, proceed to Phase 2
```

---

## Phase 2: Resolve Port Conflicts

### Move Wiki.js from Port 80 to 3080

1. Stop the Wiki.js container:
   ```bash
   cd /home/john5/Documents/Home_Network/Docker/containers/wiki
   docker compose down
   ```

2. Edit `docker-compose.yaml`:
   ```yaml
   ports:
     - "3080:3000"  # Changed from "80:3000"
   ```

3. Restart Wiki.js:
   ```bash
   docker compose up -d
   ```

4. Verify:
   ```bash
   docker ps | grep wiki
   curl -I http://localhost:3080
   ```

---

## Phase 3: Install Tailscale

### Installation

```bash
# Add Tailscale repository
curl -fsSL https://tailscale.com/install.sh | sh

# Verify installation
tailscale version
```

### Configure as Subnet Router

```bash
# Start Tailscale with subnet routing
sudo tailscale up --advertise-routes=192.168.0.0/24 --accept-dns=false

# This will provide a URL for authentication
# Open the URL in a browser to authorize
```

### Verify in Tailscale Admin Console

1. Go to https://login.tailscale.com/admin/machines
2. Find the `trigkey` node
3. Click "Edit route settings"
4. **Approve** the 192.168.0.0/24 subnet route
5. Verify "Subnet router" is enabled

### Enable IP Forwarding (if not already)

```bash
# Check current state
cat /proc/sys/net/ipv4/ip_forward

# If 0, enable:
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### Verify Persistence

```bash
# Check Tailscale status
tailscale status

# Verify it's enabled at boot
systemctl is-enabled tailscaled
```

---

## Phase 4: Deploy Nginx Proxy Manager

### Create Docker Compose Configuration

```bash
cd /home/john5/Documents/git/ExternalAccess/docker/nginx-proxy-manager
```

The `docker-compose.yaml` is provided in this repository.

### Deploy

```bash
docker compose up -d
```

### Initial Setup

1. Access admin UI: http://192.168.0.8:81
2. Default credentials:
   - Email: `admin@example.com`
   - Password: `changeme`
3. **Immediately change credentials** on first login

### Verify Ports

```bash
ss -tlnp | grep -E ':(80|81|443)\s'
```

Expected output:
- Port 80: nginx-proxy-manager
- Port 81: nginx-proxy-manager (admin)
- Port 443: nginx-proxy-manager

---

## Phase 5: Configure Proxy Hosts

### Add SSL Certificate

1. In NPM Admin UI, go to "SSL Certificates"
2. Click "Add SSL Certificate" → "Let's Encrypt"
3. Enter domain name(s)
4. Agree to terms
5. Click "Save"

### Create Proxy Hosts

For each service, create a proxy host:

#### Home Assistant

| Field | Value |
|-------|-------|
| Domain Names | ha.yourdomain.com |
| Scheme | http |
| Forward Hostname | 192.168.0.40 |
| Forward Port | 8123 |
| Websockets Support | ON |
| SSL Certificate | Select your cert |
| Force SSL | ON |

#### Wiki.js

| Field | Value |
|-------|-------|
| Domain Names | wiki.yourdomain.com |
| Scheme | http |
| Forward Hostname | 192.168.0.8 |
| Forward Port | 3080 |
| SSL Certificate | Select your cert |
| Force SSL | ON |

---

## Phase 6: Restrict Admin Access

### Option A: NPM Access Lists

1. In NPM, go to "Access Lists"
2. Create new list: "LAN-Only"
3. Add allowed IPs:
   - 192.168.0.0/24
   - 100.64.0.0/10 (Tailscale CGNAT range)
4. Apply to admin proxy (if proxying admin UI)

### Option B: Firewall Rules (UFW)

```bash
# Allow admin port only from LAN and Tailscale
sudo ufw allow from 192.168.0.0/24 to any port 81
sudo ufw allow from 100.64.0.0/10 to any port 81
sudo ufw deny 81
```

---

## Phase 7: DNS Configuration

Configure DNS records to point to your Tailscale IP (100.x.x.x) or use Tailscale MagicDNS.

| Record | Type | Value |
|--------|------|-------|
| ha.yourdomain.com | A | 100.x.x.x (Tailscale IP) |
| wiki.yourdomain.com | A | 100.x.x.x (Tailscale IP) |

Or use split-horizon DNS for LAN vs remote access.

---

## Phase 8: Validation

Run the validation tests from [TESTING.md](TESTING.md):

```bash
./scripts/validate.sh
```

Verify all checks pass before considering deployment complete.

---

## Post-Installation

1. Update CHANGELOG.md with deployment details
2. Commit all configuration to git
3. Push to GitHub repository
4. Schedule regular review of security posture

---

## Troubleshooting

### Tailscale not connecting

```bash
# Check status
tailscale status

# View logs
journalctl -u tailscaled -f

# Re-authenticate
sudo tailscale up --advertise-routes=192.168.0.0/24
```

### NPM not starting

```bash
# Check container logs
docker logs nginx-proxy-manager

# Verify port availability
ss -tlnp | grep -E ':(80|81|443)\s'
```

### Certificate issues

1. Verify domain points to correct IP
2. Check NPM logs for Let's Encrypt errors
3. Ensure port 80 is accessible for HTTP-01 challenge (via Tailscale)

### Services unreachable

1. Verify backend service is running
2. Check proxy host configuration
3. Test direct access: `curl http://192.168.0.x:port`
4. Check NPM access lists
