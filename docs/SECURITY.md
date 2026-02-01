# Security Notes

## Security Posture Overview

This infrastructure implements a **zero-trust external access model**:
- No public ports
- Identity-based access via Tailscale
- TLS for all proxied traffic
- Admin interfaces restricted

---

## Access Control Matrix

| Resource | Public Internet | Tailscale Mesh | LAN Direct |
|----------|----------------|----------------|------------|
| Proxied services (443) | No | Yes | Yes |
| NPM Admin (81) | No | Yes | Yes |
| Backend services | No | Via proxy | Yes |
| SSH (22) | No | Yes | Yes |
| Home Assistant | No | Via proxy | Yes |

---

## Hardening Checklist

### Tailscale

- [ ] SSO/MFA enabled on Tailscale account
- [ ] Device approval required for new nodes
- [ ] Key expiry policy configured
- [ ] ACLs configured (if using Tailscale ACLs)
- [ ] Subnet routes explicitly approved
- [ ] No unintended exit nodes

### Nginx Proxy Manager

- [ ] Default admin credentials changed
- [ ] Admin port (81) not exposed publicly
- [ ] TLS 1.2+ only (no SSLv3, TLS 1.0/1.1)
- [ ] Strong cipher suites configured
- [ ] HSTS enabled where appropriate
- [ ] Access lists applied to sensitive proxies

### Host System

- [ ] Automatic security updates enabled
- [ ] SSH key-only authentication
- [ ] Fail2ban installed (optional)
- [ ] No unnecessary services running
- [ ] Firewall rules reviewed (UFW recommended)

### Docker

- [ ] Containers run as non-root where possible
- [ ] No privileged containers unless required
- [ ] Images from official/trusted sources only
- [ ] Regular image updates
- [ ] No exposed ports except through proxy

---

## TLS Configuration

### Recommended Cipher Suites (NPM)

```
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
TLS_AES_128_GCM_SHA256
ECDHE-RSA-AES256-GCM-SHA384
ECDHE-RSA-AES128-GCM-SHA256
```

### Disabled Protocols

- SSLv2
- SSLv3
- TLS 1.0
- TLS 1.1

### Certificate Management

- Provider: Let's Encrypt
- Renewal: Automatic (NPM handles)
- Validity: 90 days
- Renewal window: 30 days before expiry

---

## Sensitive Files

| File | Purpose | Protection |
|------|---------|------------|
| `/var/lib/tailscale/` | Tailscale state | Root only |
| NPM database | Proxy config, certs | Container volume |
| Docker secrets | Service credentials | Docker secrets API |
| SSH keys | Host access | User permissions |

---

## Incident Response

### Suspected Compromise

1. **Isolate:** Disconnect affected system from network
2. **Preserve:** Capture logs, memory dump if possible
3. **Revoke:** Disable Tailscale node, rotate credentials
4. **Investigate:** Review logs, identify scope
5. **Remediate:** Rebuild affected systems
6. **Document:** Update threat model, lessons learned

### Contact Points

- Tailscale: admin console for node management
- Home Assistant: local console access via LAN
- Docker: host CLI access

---

## Monitoring Recommendations

| Component | Monitoring Method | Alert Threshold |
|-----------|-------------------|-----------------|
| Tailscale | Admin console | New device, key expiry |
| NPM | Uptime Kuma | Service unavailable |
| Host | node-exporter + Prometheus | CPU > 90%, disk > 85% |
| Certificates | NPM automatic | 14 days before expiry |
| Docker | cadvisor | Container restart |

---

## Compliance Notes

This is a personal homelab infrastructure. No formal compliance requirements apply. However, the following principles are followed:

- **Least Privilege:** Services have minimum required access
- **Defense in Depth:** Multiple security layers
- **Audit Trail:** All changes documented
- **Regular Updates:** Security patches applied promptly

---

## Security Contacts

For security issues with this infrastructure:
1. Review logs on proxy host
2. Check Tailscale admin console
3. Review CHANGELOG.md for recent changes
4. Consult THREAT-MODEL.md for known risks
