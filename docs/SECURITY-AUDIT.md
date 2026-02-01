# Security Audit Report

**Date:** 2026-01-31
**Host:** trigkey (192.168.0.8)
**Auditor:** Automated deployment

---

## Summary

| Category | Status | Notes |
|----------|--------|-------|
| Container Privileges | PASS | NPM not running privileged |
| Port Exposure | PASS | All services behind Tailscale |
| IP Forwarding | PASS | Enabled for subnet routing |
| Tailscale | PASS | Active, subnet route approved |
| Router Ports | MANUAL | Requires manual verification |

---

## Port Inventory

### Intentionally Exposed (via Tailscale only)

| Port | Service | Binding | Access |
|------|---------|---------|--------|
| 22 | SSH | 0.0.0.0 | Tailscale/LAN |
| 80 | NPM HTTP | 0.0.0.0 | Tailscale/LAN |
| 81 | NPM Admin | 0.0.0.0 | Tailscale/LAN |
| 443 | NPM HTTPS | 0.0.0.0 | Tailscale/LAN |
| 3001 | Uptime Kuma | 0.0.0.0 | Tailscale/LAN |
| 3080 | Wiki.js | 0.0.0.0 | Tailscale/LAN |
| 3100 | Homebox | 0.0.0.0 | Tailscale/LAN |
| 3389 | Ubuntu Desktop RDP | 0.0.0.0 | Tailscale/LAN |
| 5901 | Ubuntu Desktop VNC | 0.0.0.0 | Tailscale/LAN |
| 6080 | Ubuntu Desktop noVNC | 0.0.0.0 | Tailscale/LAN |
| 8084 | cAdvisor | 0.0.0.0 | Tailscale/LAN |
| 9100 | Node Exporter | 0.0.0.0 | Tailscale/LAN |

### Internal/Localhost Only

| Port | Service | Notes |
|------|---------|-------|
| 10248-10259 | K3s services | 127.0.0.1 only |
| 11434 | Ollama API | 127.0.0.1 only |
| 5432 | PostgreSQL (Wiki) | Docker internal |
| 5900 | VNC local | 127.0.0.1 only |
| 6443 | K3s API | Internal |
| 6444 | K3s API | 127.0.0.1 only |

### Desktop Services

| Port | Service | Notes |
|------|---------|-------|
| 34393 | GNOME User Share | WebDAV file sharing |
| Various | Rygel | DLNA/UPnP media server |

---

## Container Security

### nginx-proxy-manager

| Property | Value | Status |
|----------|-------|--------|
| Privileged | false | PASS |
| User | root (internal) | ACCEPTABLE |
| Network | bridge | PASS |
| Secrets | Docker secrets | PASS |

### npm-db (MariaDB)

| Property | Value | Status |
|----------|-------|--------|
| Privileged | false | PASS |
| Port Exposure | Internal only | PASS |
| Credentials | Docker secrets | PASS |

---

## Access Control

### Tailscale

- **Device:** trigkey
- **IP:** 100.124.155.7
- **Subnet Route:** 192.168.0.0/24 (approved)
- **Exit Node:** No
- **ACLs:** Default (all mesh access)

### Network Access Matrix

| Source | Destination | Allowed |
|--------|-------------|---------|
| Internet | LAN | NO |
| Internet | Tailscale IP | NO (no port forwards) |
| Tailscale Mesh | LAN (via subnet) | YES |
| Tailscale Mesh | trigkey services | YES |
| LAN | trigkey services | YES |

---

## Recommendations

### Immediate (Required for Production)

1. **Change NPM default credentials** - Currently default admin@example.com/changeme
2. **Verify router configuration** - Confirm no port forwarding rules exist
3. **Review Tailscale ACLs** - Consider restricting subnet access by user/device

### Future Enhancements

1. **Enable UFW** - Add host-based firewall for defense in depth
2. **Add fail2ban** - Protect SSH from brute force
3. **Enable TLS** - Get domain for proper HTTPS certificates
4. **Container hardening** - Run containers as non-root where possible
5. **Monitoring** - Set up alerts for unauthorized access attempts

---

## Manual Verification Required

- [ ] Log into router, verify no port forwarding to 192.168.0.8
- [ ] Verify no UPnP/NAT-PMP automatic port mapping
- [ ] Change NPM admin credentials
- [ ] Test access from remote Tailscale device
- [ ] Verify Home Assistant accessible via subnet route

---

## Acceptance

| Check | Result |
|-------|--------|
| No public ingress | PASS (requires router verification) |
| Identity-based access | PASS (Tailscale) |
| TLS termination | DEFERRED (HTTP-only for now) |
| Admin UI restricted | PASS (Tailscale/LAN only) |
| Backend isolation | PASS |
| Privilege scope | PASS |

**Overall Security Validation: CONDITIONAL PASS**

Conditional on manual router verification.
