#!/bin/bash
#
# ExternalAccess Validation Suite
# Validates infrastructure deployment against acceptance criteria
#

set -e

PASS=0
FAIL=0
WARN=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN++))
}

check() {
    local desc="$1"
    local cmd="$2"

    if eval "$cmd" > /dev/null 2>&1; then
        pass "$desc"
        return 0
    else
        fail "$desc"
        return 1
    fi
}

echo "========================================"
echo "   ExternalAccess Validation Suite"
echo "   $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo

# Section 1: Host State
echo "--- 1. Host State Discovery ---"
check "OS identified" "cat /etc/os-release | grep -q 'Ubuntu'"
check "Network interface mapped" "ip addr show wlo1 | grep -q '192.168.0'"
check "Docker present" "docker --version"
check "IP forwarding enabled" "[ $(cat /proc/sys/net/ipv4/ip_forward) -eq 1 ]"
echo

# Section 2: Tailscale
echo "--- 2. Tailscale Deployment ---"
check "Tailscale installed" "which tailscale"
check "Tailscale daemon running" "systemctl is-active tailscaled"
check "Tailscale connected" "tailscale status | head -1 | grep -qv 'Logged out'"

if tailscale status 2>/dev/null | grep -q "192.168.0.0/24"; then
    pass "Subnet 192.168.0.0/24 advertised"
else
    fail "Subnet 192.168.0.0/24 advertised"
fi

check "Tailscale persistence" "systemctl is-enabled tailscaled"
echo

# Section 3: Subnet Routing
echo "--- 3. Subnet Routing Validation ---"
check "Gateway reachable" "ping -c 1 -W 2 192.168.0.1"
check "Home Assistant reachable" "ping -c 1 -W 2 192.168.0.40 || ping -c 1 -W 2 192.168.0.41"
echo

# Section 4: Reverse Proxy
echo "--- 4. Reverse Proxy Deployment ---"
check "NPM container exists" "docker ps -a | grep -q nginx-proxy-manager"
check "NPM container running" "docker ps | grep -q nginx-proxy-manager"
check "Port 80 listening" "ss -tlnp | grep -q ':80 '"
check "Port 443 listening" "ss -tlnp | grep -q ':443 '"
check "Port 81 listening" "ss -tlnp | grep -q ':81 '"
check "Admin UI accessible" "curl -sf http://localhost:81 -o /dev/null"
echo

# Section 5: Service Exposure
echo "--- 5. Service Exposure Rules ---"
check "Wiki.js not on port 80" "! docker ps | grep wiki | grep -q ':80->'"
check "Wiki.js on alternate port" "curl -sf http://localhost:3080 -o /dev/null || docker ps | grep wiki | grep -q '3080'"
echo

# Section 6: Security
echo "--- 6. Security Validation ---"
check "No privileged NPM container" "! docker inspect nginx-proxy-manager 2>/dev/null | grep -q '\"Privileged\": true'"

# Check for external port exposure (basic check)
if command -v nmap &> /dev/null; then
    # This would need to be run from external network for proper validation
    warn "External port scan requires manual verification from outside network"
else
    warn "nmap not available - external port scan requires manual verification"
fi
echo

# Section 7: Documentation
echo "--- 7. Documentation ---"
DOCS_DIR="/home/john5/Documents/git/ExternalAccess/docs"
check "PRE-FLIGHT.md exists" "[ -f $DOCS_DIR/PRE-FLIGHT.md ]"
check "ARCHITECTURE.md exists" "[ -f $DOCS_DIR/ARCHITECTURE.md ]"
check "SETUP.md exists" "[ -f $DOCS_DIR/SETUP.md ]"
check "SECURITY.md exists" "[ -f $DOCS_DIR/SECURITY.md ]"
check "THREAT-MODEL.md exists" "[ -f $DOCS_DIR/THREAT-MODEL.md ]"
check "TESTING.md exists" "[ -f $DOCS_DIR/TESTING.md ]"
echo

# Section 8: Changelog
echo "--- 8. Changelog ---"
CHANGELOG="/home/john5/Documents/git/ExternalAccess/CHANGELOG.md"
check "CHANGELOG.md exists" "[ -f $CHANGELOG ]"
check "Follows Keep a Changelog format" "grep -q 'Keep a Changelog' $CHANGELOG"
check "Has Semantic Versioning reference" "grep -q 'Semantic Versioning' $CHANGELOG"
check "Has version entry" "grep -qE '^\## \[' $CHANGELOG"
echo

# Results Summary
echo "========================================"
echo "             RESULTS"
echo "========================================"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo -e "Warnings: ${YELLOW}$WARN${NC}"
echo

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}VALIDATION FAILED${NC}"
    echo "Review failed checks above and remediate before proceeding."
    exit 1
else
    if [ $WARN -gt 0 ]; then
        echo -e "${YELLOW}VALIDATION PASSED WITH WARNINGS${NC}"
        echo "Review warnings and address if applicable."
        exit 0
    else
        echo -e "${GREEN}VALIDATION PASSED${NC}"
        exit 0
    fi
fi
