# ExternalAccess

Hardened external access infrastructure for homelab using Tailscale subnet routing and Nginx Proxy Manager.

## Overview

This project establishes a **security-first external access path** into the homelab without requiring:
- Router port forwarding
- Tailscale installation on every LAN device
- Modifications to Home Assistant OS or other services

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                    Tailscale Mesh                        │
│  (Identity-based access, encrypted tunnel)              │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│              trigkey (192.168.0.8)                       │
│  ┌─────────────────┐  ┌─────────────────────────────┐   │
│  │   Tailscale     │  │   Nginx Proxy Manager       │   │
│  │  Subnet Router  │  │   Ports 80/443 (TLS)        │   │
│  │  192.168.0.0/24 │  │   Admin: 81 (LAN only)      │   │
│  └─────────────────┘  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                    LAN (192.168.0.0/24)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Home         │  │ Wiki.js      │  │ Other        │   │
│  │ Assistant    │  │ :3080        │  │ Services     │   │
│  │ :8123        │  │              │  │              │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Components

| Component | Purpose | Port(s) |
|-----------|---------|---------|
| Tailscale | Subnet router, identity-based access | - |
| Nginx Proxy Manager | Reverse proxy, TLS termination | 80, 443, 81 (admin) |
| Docker | Container runtime | - |

## Quick Start

See [docs/SETUP.md](docs/SETUP.md) for detailed installation instructions.

```bash
# 1. Clone repository
git clone git@github.com:jayfirns/ExternalAccess.git
cd ExternalAccess

# 2. Review pre-flight checks
cat docs/PRE-FLIGHT.md

# 3. Run deployment script
./scripts/deploy.sh
```

## Documentation

| Document | Description |
|----------|-------------|
| [PRE-FLIGHT.md](docs/PRE-FLIGHT.md) | Host state discovery before modifications |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and component interaction |
| [SETUP.md](docs/SETUP.md) | Step-by-step installation guide |
| [SECURITY.md](docs/SECURITY.md) | Security notes and hardening |
| [THREAT-MODEL.md](docs/THREAT-MODEL.md) | Threat analysis and mitigations |
| [TESTING.md](docs/TESTING.md) | Validation and test procedures |

## Security Model

- **No public ingress** - All access through Tailscale identity
- **TLS termination** at reverse proxy
- **Admin interfaces** restricted to LAN/Tailscale
- **Backend services** never directly exposed
- **Audit trail** via documentation and changelog

## Requirements

- Ubuntu 24.04 LTS (or compatible)
- Docker 29.x+
- Tailscale account
- Domain name (for TLS certificates)

## License

Private infrastructure project.
