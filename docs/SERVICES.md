# Service Exposure Configuration

## Overview

This document lists all services accessible through the ExternalAccess infrastructure.

---

## Access Methods

Since we're using Tailscale without a public domain:

- **Primary Access:** Direct IP via Tailscale tunnel
- **Proxy Access:** Through NPM on port 80 (HTTP)
- **Encryption:** Provided by Tailscale WireGuard tunnel

---

## Services on trigkey (192.168.0.8)

### Wiki.js

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:3080 |
| Protocol | HTTP |
| NPM Proxy | Optional |
| Direct Access | http://192.168.0.8:3080 |

### Homebox

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:3100 |
| Protocol | HTTP |
| NPM Proxy | Optional |
| Direct Access | http://192.168.0.8:3100 |

### Uptime Kuma

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:3001 |
| Protocol | HTTP |
| WebSockets | Required |
| Direct Access | http://192.168.0.8:3001 |

### Ubuntu Desktop (noVNC)

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:6080 |
| Protocol | HTTP |
| WebSockets | Required |
| Direct Access | http://192.168.0.8:6080 |
| VNC Direct | 192.168.0.8:5901 |
| RDP Direct | 192.168.0.8:3389 |

### cAdvisor

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:8084 |
| Protocol | HTTP |
| Purpose | Container metrics |
| Direct Access | http://192.168.0.8:8084 |

### Node Exporter

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:9100 |
| Protocol | HTTP (metrics) |
| Purpose | Host metrics |
| Direct Access | http://192.168.0.8:9100/metrics |

### Open WebUI

| Property | Value |
|----------|-------|
| Backend | Container internal |
| Protocol | HTTP |
| Notes | No external port exposed |

### NPM Admin

| Property | Value |
|----------|-------|
| Backend | 192.168.0.8:81 |
| Protocol | HTTP |
| Access | LAN/Tailscale only |

---

## Services on Other Hosts

### Home Assistant

| Property | Value |
|----------|-------|
| Host | 192.168.0.40 |
| Backend | 192.168.0.40:8123 |
| Protocol | HTTP |
| WebSockets | Required |
| Direct Access | http://192.168.0.40:8123 |

---

## NPM Proxy Host Configuration

For services you want accessible through NPM:

### Example: Home Assistant via NPM

In NPM Admin (http://192.168.0.8:81):

1. Go to **Hosts** → **Proxy Hosts**
2. Click **Add Proxy Host**
3. Configure:

**Details Tab:**
- Domain Names: `ha` (or any identifier)
- Scheme: `http`
- Forward Hostname/IP: `192.168.0.40`
- Forward Port: `8123`
- Block Common Exploits: ON
- Websockets Support: **ON** (required for HA)

**SSL Tab:** (skip for HTTP-only)
- Leave as "None"

**Access:** via http://192.168.0.8/ha or set up hosts file

---

## Direct Access Summary

For simplicity with Tailscale, direct access is recommended:

| Service | URL |
|---------|-----|
| Home Assistant | http://192.168.0.40:8123 |
| Wiki.js | http://192.168.0.8:3080 |
| Homebox | http://192.168.0.8:3100 |
| Uptime Kuma | http://192.168.0.8:3001 |
| Ubuntu Desktop | http://192.168.0.8:6080 |
| NPM Admin | http://192.168.0.8:81 |
| cAdvisor | http://192.168.0.8:8084 |

These URLs work from:
- Any device on the LAN (192.168.0.x)
- Any device connected to Tailscale (via subnet route)

---

## Why Use NPM Without a Domain?

The reverse proxy is still valuable for:

1. **Future TLS:** When you add a domain, NPM handles certificates
2. **Access Control:** NPM access lists can restrict by IP
3. **Logging:** Centralized access logs
4. **Single Entry Point:** One IP, multiple services
5. **WebSocket Handling:** Proper upgrade headers

For now, **direct access** via Tailscale subnet routing is the simplest approach.
