# Threat Model

## Overview

This document identifies threats to the ExternalAccess infrastructure, assesses risks, and documents mitigations.

---

## Assets

| Asset | Sensitivity | Impact if Compromised |
|-------|-------------|----------------------|
| Internal LAN services | High | Unauthorized access to all homelab services |
| Home Assistant OS | Critical | Smart home control, sensor data, automations |
| Docker workloads | High | Data exposure, compute abuse, lateral movement |
| Proxy host credentials | Critical | Full infrastructure compromise |
| Tailscale identity | Critical | Persistent unauthorized access |
| Service data (Wiki, Homebox, etc.) | Medium-High | Data breach, privacy violation |

---

## Threat Actors

### 1. Internet Scanners (Automated)
- **Capability:** Mass port scanning, vulnerability detection
- **Motivation:** Opportunistic exploitation
- **Mitigation:** No public ports exposed; Tailscale mesh only

### 2. Credential Stuffing Bots
- **Capability:** Automated login attempts with leaked credentials
- **Motivation:** Account takeover
- **Mitigation:** No public login surfaces; identity-based access via Tailscale

### 3. Targeted Attacker
- **Capability:** Social engineering, phishing, targeted exploitation
- **Motivation:** Specific interest in target
- **Mitigation:** Tailscale SSO/MFA; minimal attack surface

### 4. Compromised Tailscale Client
- **Capability:** Authorized network access, lateral movement
- **Motivation:** Post-compromise exploitation
- **Mitigation:** ACLs, service segmentation, monitoring

### 5. Insider/Misconfiguration
- **Capability:** Full authorized access
- **Motivation:** Accident or malice
- **Mitigation:** Change discipline, audit trail, documentation

---

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────┐
│                    UNTRUSTED                             │
│                    (Internet)                            │
└────────────────────────┬────────────────────────────────┘
                         │
            ┌────────────▼────────────┐
            │   TRUST BOUNDARY 1      │
            │   Tailscale Identity    │
            │   (WireGuard + Auth)    │
            └────────────┬────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    SEMI-TRUSTED                          │
│              (Tailscale Mesh Members)                    │
└────────────────────────┬────────────────────────────────┘
                         │
            ┌────────────▼────────────┐
            │   TRUST BOUNDARY 2      │
            │   Proxy Host Access     │
            │   (TLS + Routing)       │
            └────────────┬────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    TRUSTED                               │
│                (LAN Services)                            │
└─────────────────────────────────────────────────────────┘
```

---

## Threat Matrix

| Threat | Likelihood | Impact | Risk | Mitigation |
|--------|------------|--------|------|------------|
| Public port scanning | Eliminated | N/A | None | No public ports |
| Credential stuffing | Eliminated | N/A | None | No public auth surfaces |
| MITM on public network | Eliminated | N/A | None | WireGuard encryption |
| Tailscale account compromise | Low | Critical | Medium | SSO/MFA, device approval |
| Authorized client compromise | Medium | High | High | ACLs, monitoring |
| Proxy misconfiguration | Medium | High | High | Documentation, testing |
| TLS certificate issues | Low | Medium | Low | Let's Encrypt automation |
| Proxy host compromise | Low | Critical | Medium | Minimal attack surface, updates |
| Lateral movement from service | Low | High | Medium | Container isolation |

---

## Attack Scenarios

### Scenario 1: Internet Scanner
```
Attacker → Scans public IP → No open ports → BLOCKED
```
**Result:** Attack fails at perimeter.

### Scenario 2: Phishing for Tailscale Credentials
```
Attacker → Phishes user → Obtains Tailscale creds
        → Attempts login → MFA required → BLOCKED
        OR
        → MFA bypassed → Device added → Access granted
        → Lateral movement possible
```
**Result:** Partial protection. Residual risk documented below.

### Scenario 3: Compromised Authorized Device
```
Attacker → Compromises user laptop → Has Tailscale access
        → Accesses LAN via subnet route → Can reach all services
```
**Result:** High impact. Mitigation via ACLs and monitoring.

### Scenario 4: Proxy Vulnerability
```
Attacker → Discovers NPM vulnerability → Exploits via Tailscale
        → Gains proxy host access → Full LAN access
```
**Result:** Defense in depth fails. Critical residual risk.

---

## Mitigations (Implemented)

| Mitigation | Threat Addressed | Implementation |
|------------|------------------|----------------|
| No public ingress | Internet scanning, direct attacks | Tailscale-only access |
| Identity-based access | Unauthorized access | Tailscale authentication |
| TLS termination | MITM, eavesdropping | NPM with Let's Encrypt |
| Admin UI restriction | Unauthorized admin access | LAN/Tailscale ACL on port 81 |
| Backend isolation | Direct service access | Services behind proxy only |
| Documentation | Misconfiguration | Change discipline enforced |
| Changelog | Audit trail | All changes versioned |

---

## Residual Risks

### Risk 1: Proxy Host Compromise

**Description:** If the proxy host (trigkey) is compromised, attacker gains full LAN access.

**Detection:**
- Unusual outbound connections
- Unexpected processes
- Failed login attempts
- Resource anomalies (CPU, memory, network)
- Uptime Kuma monitoring alerts

**Recovery:**
1. Disconnect host from network
2. Revoke Tailscale node key
3. Capture forensic image
4. Rebuild from known-good state
5. Rotate all credentials
6. Review access logs

**Documentation Reference:** [SECURITY.md](SECURITY.md)

---

### Risk 2: Authorized Client Compromise

**Description:** Compromised Tailscale device has authorized LAN access.

**Detection:**
- Tailscale admin console - unusual access patterns
- Service logs - unexpected requests
- Home Assistant - unauthorized automations

**Recovery:**
1. Identify compromised device in Tailscale admin
2. Remove device from Tailnet
3. Expire device key
4. Audit access logs for affected period
5. Rotate service credentials if accessed
6. Re-authorize device after remediation

**Documentation Reference:** Tailscale admin console, service logs

---

### Risk 3: Misconfiguration During Updates

**Description:** Changes to proxy rules, Tailscale config, or services may inadvertently expose resources.

**Detection:**
- Pre-change testing procedures
- Post-change validation
- External port scanning (periodic)
- Uptime monitoring

**Recovery:**
1. Revert to previous configuration (git history)
2. Document incident
3. Update procedures to prevent recurrence
4. Verify with testing suite

**Documentation Reference:** [TESTING.md](TESTING.md), git history

---

## Security Assumptions

1. **Tailscale infrastructure is secure** - Relying on Tailscale's security model
2. **WireGuard cryptography is sound** - Industry-standard encryption
3. **Let's Encrypt is trustworthy** - Standard CA
4. **LAN is not hostile** - No attackers on local network
5. **Host OS is maintained** - Regular security updates applied
6. **Docker containers are from trusted sources** - Official images only

---

## Review Schedule

| Review Type | Frequency | Owner |
|-------------|-----------|-------|
| Configuration audit | Monthly | Admin |
| Dependency updates | Weekly | Admin |
| Tailscale ACL review | Quarterly | Admin |
| Threat model update | On significant changes | Admin |
| Penetration testing | Annually | External |
