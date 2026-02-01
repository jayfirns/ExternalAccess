# Architecture

## System Overview

ExternalAccess provides secure remote access to homelab services using a defense-in-depth approach with zero public port exposure.

## Component Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                       │
│                          (Untrusted Zone)                                   │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ No direct ingress
                                    │ No port forwarding
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                         TAILSCALE MESH                                      │
│                      (Identity-Based Access)                                │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │ Remote      │    │ Remote      │    │ Mobile      │                     │
│  │ Laptop      │    │ Server      │    │ Device      │                     │
│  │ (Tailscale) │    │ (Tailscale) │    │ (Tailscale) │                     │
│  └─────────────┘    └─────────────┘    └─────────────┘                     │
│         │                 │                  │                              │
│         └─────────────────┼──────────────────┘                              │
│                           │                                                 │
│                     Encrypted Tunnel                                        │
│                           │                                                 │
└───────────────────────────┼─────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                    PROXY HOST (trigkey - 192.168.0.8)                       │
│                         (Trust Boundary)                                    │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         Tailscale Client                              │  │
│  │                                                                       │  │
│  │  - Subnet Router: 192.168.0.0/24                                     │  │
│  │  - Accept Routes: No (this is the router)                            │  │
│  │  - Exit Node: No                                                     │  │
│  │  - Tailscale IP: 100.x.x.x (assigned)                               │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    Nginx Proxy Manager (Docker)                       │  │
│  │                                                                       │  │
│  │  Ports:                                                               │  │
│  │    - 80  → HTTP (redirect to HTTPS)                                  │  │
│  │    - 443 → HTTPS (TLS termination)                                   │  │
│  │    - 81  → Admin UI (LAN/Tailscale only)                            │  │
│  │                                                                       │  │
│  │  Features:                                                            │  │
│  │    - Let's Encrypt certificates                                      │  │
│  │    - WebSocket support                                                │  │
│  │    - Access control lists                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                         LAN (192.168.0.0/24)                                │
│                       (Backend Services Zone)                               │
│                                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                   │
│  │ Home          │  │ Wiki.js       │  │ Uptime Kuma   │                   │
│  │ Assistant     │  │               │  │               │                   │
│  │               │  │               │  │               │                   │
│  │ 192.168.0.40  │  │ 192.168.0.8   │  │ 192.168.0.8   │                   │
│  │ :8123         │  │ :3080         │  │ :3001         │                   │
│  └───────────────┘  └───────────────┘  └───────────────┘                   │
│                                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                   │
│  │ Homebox       │  │ Open WebUI    │  │ Other         │                   │
│  │               │  │               │  │ Services      │                   │
│  │ 192.168.0.8   │  │ 192.168.0.8   │  │               │                   │
│  │ :3100         │  │ (internal)    │  │               │                   │
│  └───────────────┘  └───────────────┘  └───────────────┘                   │
└────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Remote Access Path

```
1. User authenticates to Tailscale on remote device
2. Tailscale establishes encrypted tunnel to mesh
3. User requests https://service.domain.com
4. DNS resolves to Tailscale IP of proxy host
5. Request arrives at Nginx Proxy Manager (port 443)
6. NPM terminates TLS, validates host header
7. NPM proxies to backend service on LAN
8. Response returns through same path
```

### Local Access Path

```
1. User on LAN requests service directly
2. Request goes to proxy host (192.168.0.8)
3. NPM handles request same as remote
4. OR user accesses backend directly (unchanged behavior)
```

## Component Specifications

### Tailscale Subnet Router

| Setting | Value | Rationale |
|---------|-------|-----------|
| Advertised Routes | 192.168.0.0/24 | LAN subnet only |
| Accept Routes | false | Not receiving routes |
| Exit Node | false | Not providing exit |
| Key Expiry | As per Tailnet policy | Default security |

### Nginx Proxy Manager

| Setting | Value | Rationale |
|---------|-------|-----------|
| HTTP Port | 80 | Standard, redirect to HTTPS |
| HTTPS Port | 443 | TLS termination |
| Admin Port | 81 | Non-standard, restricted |
| Network Mode | bridge | Docker networking |
| SSL Provider | Let's Encrypt | Automatic renewal |

### Docker Network Layout

```
┌─────────────────────────────────────────┐
│           npm_network (bridge)           │
│                                          │
│  ┌──────────────┐  ┌──────────────────┐ │
│  │ nginx-proxy- │  │ npm-db           │ │
│  │ manager      │  │ (MariaDB)        │ │
│  │ :80, :443,   │  │ :3306 (internal) │ │
│  │ :81          │  │                  │ │
│  └──────────────┘  └──────────────────┘ │
└─────────────────────────────────────────┘
```

## Trust Boundaries

1. **Internet → Tailscale Mesh**
   - Controlled by Tailscale authentication
   - WireGuard encryption
   - No public ports

2. **Tailscale Mesh → Proxy Host**
   - All mesh members have LAN access via subnet route
   - Controlled by Tailnet ACLs (if configured)

3. **Proxy Host → LAN Services**
   - NPM controls which services are exposed
   - TLS terminates at proxy
   - Backend services receive plain HTTP

## Assumptions

1. Tailscale account is secured with appropriate authentication (SSO, MFA)
2. Only authorized devices are added to the Tailnet
3. Proxy host is not compromised
4. LAN is trusted (no hostile actors on local network)
5. DNS for service hostnames is properly configured

## Failure Modes

| Component | Failure Impact | Detection | Recovery |
|-----------|----------------|-----------|----------|
| Tailscale | No remote access | Tailscale admin console | Restart service |
| NPM | No proxied services | Direct service check | Restart container |
| Docker | All containers down | Host monitoring | Restart Docker |
| Host | Complete outage | External monitoring | Reboot/restore |

See [TESTING.md](TESTING.md) for recovery procedures.
