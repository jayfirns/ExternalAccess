# Testing Procedures

## Overview

This document provides repeatable test procedures for validating the ExternalAccess infrastructure.

---

## Test Categories

1. [Subnet Routing Validation](#1-subnet-routing-validation)
2. [Reverse Proxy Validation](#2-reverse-proxy-validation)
3. [Security Validation](#3-security-validation)
4. [Failure & Recovery Testing](#4-failure--recovery-testing)

---

## 1. Subnet Routing Validation

### Test 1.1: Remote LAN Reachability

**Prerequisites:** Tailscale client on remote device, connected to Tailnet

**From a remote Tailscale device:**

```bash
# Ping test to LAN hosts
ping -c 3 192.168.0.1    # Gateway
ping -c 3 192.168.0.8    # Proxy host
ping -c 3 192.168.0.40   # Home Assistant

# TCP reachability
nc -zv 192.168.0.40 8123  # Home Assistant
nc -zv 192.168.0.8 3080   # Wiki.js
```

**Expected:** All pings succeed, TCP connections establish

**Pass Criteria:**
- [ ] Gateway reachable
- [ ] Proxy host reachable
- [ ] Home Assistant reachable
- [ ] TCP connections succeed

---

### Test 1.2: Local Parity

**From a device on the LAN:**

```bash
# Same tests as remote
ping -c 3 192.168.0.1
ping -c 3 192.168.0.40
nc -zv 192.168.0.40 8123
```

**Expected:** Results match remote behavior

**Pass Criteria:**
- [ ] LAN behavior matches remote access behavior

---

### Test 1.3: Isolation Verification

**From a device NOT on Tailscale (external network):**

```bash
# Attempt to reach LAN IPs
ping -c 3 192.168.0.8
curl http://192.168.0.8
```

**Expected:** All attempts fail (no route, timeout, or refused)

**Pass Criteria:**
- [ ] Non-Tailscale clients cannot reach LAN

---

### Test 1.4: Home Assistant Direct Access

**From remote Tailscale device:**

```bash
# Access HA directly via subnet route
curl -I http://192.168.0.40:8123
```

**Expected:** HTTP response from Home Assistant

**Pass Criteria:**
- [ ] HA accessible without modification to HA OS

---

## 2. Reverse Proxy Validation

### Test 2.1: Port Binding

```bash
ss -tlnp | grep -E ':(80|81|443)\s'
```

**Expected:**
```
LISTEN  0  ...  *:80   *:*  users:(("nginx",...))
LISTEN  0  ...  *:81   *:*  users:(("nginx",...))
LISTEN  0  ...  *:443  *:*  users:(("nginx",...))
```

**Pass Criteria:**
- [ ] Port 80 bound to NPM
- [ ] Port 81 bound to NPM
- [ ] Port 443 bound to NPM
- [ ] No other services on these ports

---

### Test 2.2: TLS Certificate Validation

```bash
# Check certificate for proxied domain
echo | openssl s_client -connect 192.168.0.8:443 -servername wiki.yourdomain.com 2>/dev/null | openssl x509 -noout -dates -issuer
```

**Expected:**
- Valid dates (notAfter in future)
- Issuer: Let's Encrypt

**Pass Criteria:**
- [ ] Valid certificate issued
- [ ] Certificate not expired
- [ ] Correct issuer

---

### Test 2.3: HTTPS Enforcement

```bash
# HTTP should redirect to HTTPS
curl -I http://192.168.0.8 -H "Host: wiki.yourdomain.com"
```

**Expected:** 301/302 redirect to HTTPS

**Pass Criteria:**
- [ ] HTTP redirects to HTTPS

---

### Test 2.4: WebSocket Support

```bash
# Test WebSocket upgrade (Home Assistant uses WS)
curl -I -H "Upgrade: websocket" -H "Connection: Upgrade" \
  https://192.168.0.8/api/websocket -H "Host: ha.yourdomain.com" -k
```

**Expected:** 101 Switching Protocols or WebSocket-related response

**Pass Criteria:**
- [ ] WebSocket connections work

---

### Test 2.5: Admin UI Restriction

**From external (non-LAN, non-Tailscale) network:**

```bash
curl -I http://<public-ip>:81
```

**Expected:** Connection refused or timeout

**From LAN or Tailscale:**

```bash
curl -I http://192.168.0.8:81
```

**Expected:** HTTP 200 or redirect to login

**Pass Criteria:**
- [ ] Admin UI accessible from LAN
- [ ] Admin UI accessible from Tailscale
- [ ] Admin UI NOT accessible from public internet

---

## 3. Security Validation

### Test 3.1: Router Port Verification

Log into router admin interface and verify:

**Pass Criteria:**
- [ ] No port forwarding rules to proxy host
- [ ] No UPnP ports opened
- [ ] No DMZ configuration

---

### Test 3.2: External Port Scan

**From external network or use online tool:**

```bash
# Using nmap from external location
nmap -Pn <public-ip>

# Or use online scanner like https://www.grc.com/shieldsup
```

**Expected:** No open ports (all filtered/closed)

**Pass Criteria:**
- [ ] Port 80 not open externally
- [ ] Port 443 not open externally
- [ ] Port 81 not open externally
- [ ] No unexpected open ports

---

### Test 3.3: TLS Posture

```bash
# Test for weak ciphers
nmap --script ssl-enum-ciphers -p 443 192.168.0.8

# Or use testssl.sh
./testssl.sh 192.168.0.8:443
```

**Expected:** Only TLS 1.2+ with strong ciphers

**Pass Criteria:**
- [ ] No SSLv3
- [ ] No TLS 1.0
- [ ] No TLS 1.1
- [ ] No weak ciphers (RC4, DES, etc.)

---

### Test 3.4: Privilege Verification

```bash
# Check container user
docker exec nginx-proxy-manager id

# Check Tailscale service
ps aux | grep tailscaled
```

**Expected:** Services run with appropriate privileges

**Pass Criteria:**
- [ ] No unnecessary root processes
- [ ] Docker containers not privileged unless required

---

## 4. Failure & Recovery Testing

### Test 4.1: Proxy Restart Recovery

```bash
# Stop proxy
docker compose -f docker/nginx-proxy-manager/docker-compose.yaml down

# Verify services return to normal after restart
docker compose -f docker/nginx-proxy-manager/docker-compose.yaml up -d

# Check health
docker ps | grep nginx-proxy-manager
curl -I https://192.168.0.8 -k
```

**Expected:** Clean startup, services accessible within 60 seconds

**Pass Criteria:**
- [ ] Container starts cleanly
- [ ] No error logs on startup
- [ ] Services accessible after restart

---

### Test 4.2: Host Reboot Recovery

```bash
# Record current state
docker ps > /tmp/pre-reboot-containers.txt
tailscale status > /tmp/pre-reboot-tailscale.txt

# Reboot
sudo reboot

# After reboot, verify
docker ps
tailscale status
curl -I http://192.168.0.8:81
```

**Expected:** All services restore automatically

**Pass Criteria:**
- [ ] Docker starts automatically
- [ ] All containers restart
- [ ] Tailscale connects automatically
- [ ] NPM accessible

---

### Test 4.3: Certificate Renewal Simulation

```bash
# Check certificate expiry
docker exec nginx-proxy-manager certbot certificates

# Force renewal test (dry run)
docker exec nginx-proxy-manager certbot renew --dry-run
```

**Expected:** Dry run succeeds

**Pass Criteria:**
- [ ] Renewal mechanism works
- [ ] No errors in dry run

---

### Test 4.4: Proxy Down - LAN Unaffected

```bash
# Stop proxy
docker compose -f docker/nginx-proxy-manager/docker-compose.yaml down

# Verify LAN services still accessible directly
curl -I http://192.168.0.40:8123  # Home Assistant
curl -I http://192.168.0.8:3080   # Wiki.js direct

# Restart proxy
docker compose -f docker/nginx-proxy-manager/docker-compose.yaml up -d
```

**Expected:** Direct LAN access unaffected when proxy is down

**Pass Criteria:**
- [ ] LAN services accessible during proxy outage
- [ ] No dependency on proxy for local access

---

## Validation Script

Save as `scripts/validate.sh`:

```bash
#!/bin/bash
set -e

echo "=== ExternalAccess Validation Suite ==="
echo

PASS=0
FAIL=0

check() {
    if eval "$2" > /dev/null 2>&1; then
        echo "[PASS] $1"
        ((PASS++))
    else
        echo "[FAIL] $1"
        ((FAIL++))
    fi
}

echo "--- Port Binding ---"
check "Port 80 bound" "ss -tlnp | grep ':80 '"
check "Port 443 bound" "ss -tlnp | grep ':443 '"
check "Port 81 bound" "ss -tlnp | grep ':81 '"

echo
echo "--- Tailscale ---"
check "Tailscale running" "tailscale status"
check "Subnet advertised" "tailscale status | grep -q 'subnet'"

echo
echo "--- Services ---"
check "NPM container running" "docker ps | grep nginx-proxy-manager"
check "Wiki accessible" "curl -sf http://localhost:3080 -o /dev/null"

echo
echo "--- Results ---"
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
```

---

## Test Log Template

```markdown
## Test Run: YYYY-MM-DD

### Environment
- Tester:
- Host: trigkey
- NPM Version:
- Tailscale Version:

### Results

| Test | Result | Notes |
|------|--------|-------|
| 1.1 Remote LAN Reachability | PASS/FAIL | |
| 1.2 Local Parity | PASS/FAIL | |
| 1.3 Isolation | PASS/FAIL | |
| 1.4 HA Direct Access | PASS/FAIL | |
| 2.1 Port Binding | PASS/FAIL | |
| 2.2 TLS Certificate | PASS/FAIL | |
| 2.3 HTTPS Enforcement | PASS/FAIL | |
| 2.4 WebSocket | PASS/FAIL | |
| 2.5 Admin Restriction | PASS/FAIL | |
| 3.1 Router Ports | PASS/FAIL | |
| 3.2 External Scan | PASS/FAIL | |
| 3.3 TLS Posture | PASS/FAIL | |
| 3.4 Privilege | PASS/FAIL | |
| 4.1 Proxy Restart | PASS/FAIL | |
| 4.2 Host Reboot | PASS/FAIL | |
| 4.3 Cert Renewal | PASS/FAIL | |
| 4.4 LAN Unaffected | PASS/FAIL | |

### Issues Found


### Sign-off
- [ ] All tests passed
- [ ] Documentation updated
- [ ] Changelog entry added
```
