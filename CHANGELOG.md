# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-01-31

### Added
- Homepage portal with service launcher (docker/homepage)
- Media gallery Flask application containerized (docker/gallery)
- Custom domain integration via johnfirnschild.com subdomains
- NPM proxy hosts for all services:
  - wiki.johnfirnschild.com → Wiki.js
  - ha.johnfirnschild.com → Home Assistant
  - status.johnfirnschild.com → Uptime Kuma
  - home.johnfirnschild.com → Homebox
  - gallery.johnfirnschild.com → Media Gallery
  - npm.johnfirnschild.com → NPM Admin
  - portal.johnfirnschild.com → Homepage
  - metrics.johnfirnschild.com → Prometheus
- Prometheus monitoring integration (192.168.0.111:9090)
- Services documentation (docs/SERVICES.md)

### Changed
- NPM docker-compose.yaml switched from Docker secrets to environment variables
- Home Assistant configured with trusted_proxies for reverse proxy support

### Fixed
- NPM database authentication issue (password file not supported)

## [0.2.0] - 2026-01-31

### Added
- Tailscale subnet router (192.168.0.0/24) - version 1.94.1
- Nginx Proxy Manager deployment on ports 80/443/81
- Complete documentation suite (ARCHITECTURE, SETUP, SECURITY, THREAT-MODEL, TESTING, SERVICES)
- Security audit report
- Deployment and validation scripts
- Docker Compose configuration for NPM with secrets

### Changed
- Wiki.js port changed from 80 to 3080 (external dependency)

### Security
- Tailscale identity-based access configured (no public ingress)
- NPM database credentials stored as Docker secrets
- Container privilege verification passed
- Subnet routing isolated to 192.168.0.0/24 only
- Recovery testing validated

## [0.1.0] - 2026-01-31

### Added
- Initial project structure
- Pre-flight host state discovery documentation
- Project scaffolding with docs/, scripts/, docker/, tests/ directories
- Git repository initialization linked to GitHub remote

### Security
- Documented current firewall state (UFW inactive, no nftables rules)
- Identified port 80 conflict with Wiki.js requiring remediation
- Verified IP forwarding enabled for subnet routing

### Changed
- N/A (initial release)

---

[Unreleased]: https://github.com/jayfirns/ExternalAccess/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/jayfirns/ExternalAccess/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/jayfirns/ExternalAccess/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jayfirns/ExternalAccess/releases/tag/v0.1.0
