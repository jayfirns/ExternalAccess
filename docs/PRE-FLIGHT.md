# Pre-Flight Host State Discovery

**Generated:** 2026-01-31
**Host:** trigkey
**Project:** ExternalAccess - Hardened External Access Infrastructure

---

## 1. Operating System

| Property | Value |
|----------|-------|
| Distribution | Ubuntu 24.04.3 LTS (Noble Numbat) |
| Kernel | 6.14.0-37-generic |
| Architecture | x86-64 |
| Hardware | Trigkey S5 |
| Hostname | trigkey |

---

## 2. Network Interfaces

### Primary LAN Interface

| Property | Value |
|----------|-------|
| Interface | wlo1 (wireless) |
| IP Address | 192.168.0.8/24 |
| Gateway | 192.168.0.1 |
| Broadcast | 192.168.0.255 |

### Additional Interfaces

| Interface | IP Address | Purpose | State |
|-----------|------------|---------|-------|
| lo | 127.0.0.1/8 | Loopback | UP |
| virbr99 | 10.42.0.1/24 | libvirt bridge | DOWN |
| virbr10 | 192.168.100.1/24 | libvirt bridge | UP |
| virbr0 | 192.168.122.1/24 | libvirt default | DOWN |
| docker0 | 172.17.0.1/16 | Docker default | DOWN |
| flannel.1 | 10.42.0.0/32 | K3s overlay | UP |
| cni0 | 10.42.0.1/24 | K3s CNI | UP |
| br-* | 172.x.0.1/16 | Docker networks | Various |

### Subnet to Advertise via Tailscale

```
192.168.0.0/24
```

**Note:** Only the primary LAN subnet will be advertised. Docker/K3s internal networks are excluded.

---

## 3. Existing Services Inventory

### Port 80/443 Conflicts

| Port | Service | Container | Status |
|------|---------|-----------|--------|
| 80 | Wiki.js | wiki-wiki-1 | **CONFLICT - REQUIRES REMEDIATION** |
| 443 | None | - | Available |

**Resolution:** Wiki.js will be moved to port 3080 before reverse proxy deployment.

### Running Docker Containers

| Container | Image | Ports | Status |
|-----------|-------|-------|--------|
| wiki-wiki-1 | ghcr.io/requarks/wiki:2 | 80:3000 | Up |
| wiki-db-1 | postgres:15-alpine | 5432 (internal) | Up |
| homebox | ghcr.io/sysadminsmedia/homebox | 3100:7745 | Up (healthy) |
| open-webui | ghcr.io/open-webui/open-webui | None exposed | Up |
| cadvisor | gcr.io/cadvisor/cadvisor | 8084:8080 | Up (healthy) |
| node-exporter | prom/node-exporter | 9100:9100 | Up |
| uptime-kuma | louislam/uptime-kuma:1 | 3001:3001 | Up (healthy) |
| ubuntu-desktop | dorowu/ubuntu-desktop-lxde-vnc | 3389, 5901, 6080 | Up (healthy) |

### Stopped Docker Containers

| Container | Image | Notes |
|-----------|-------|-------|
| focusos-backend | focusos-backend:latest | Exited 4 weeks ago |
| vikunja | vikunja/vikunja | Exited 5 months ago |
| filebrowser-admin | filebrowser/filebrowser:s6 | Exited 9 months ago |
| filebrowser-public | filebrowser/filebrowser:s6 | Exited 9 months ago |

### System Services

| Service | Status | Notes |
|---------|--------|-------|
| docker.service | running | Docker Engine |
| containerd.service | running | Container runtime |
| k3s.service | running | Lightweight Kubernetes |
| libvirtd.service | running | VM management |
| ssh.service | running | OpenSSH server |
| NetworkManager.service | running | Network management |
| snap.ollama.listener.service | running | Ollama LLM |

---

## 4. Firewall State

| Firewall | Status |
|----------|--------|
| UFW | **Not active** |
| iptables | Not available |
| nftables | No rules configured |

**Security Note:** Host has no active firewall rules. Security will be enforced at the Tailscale and reverse proxy layers.

---

## 5. Docker Presence

| Property | Value |
|----------|-------|
| Docker Version | 29.2.0 |
| Compose Version | 5.0.2 |
| Buildx Version | 0.31.1 |
| Storage Driver | overlay2 |
| Cgroup Driver | systemd |
| Containers | 12 total (8 running, 4 stopped) |
| Images | 88 |

---

## 6. IP Forwarding Status

```
net.ipv4.ip_forward = 1
```

**Status:** Already enabled. Required for Tailscale subnet routing.

---

## 7. LAN Device Discovery

| IP Address | Hostname | Notes |
|------------|----------|-------|
| 192.168.0.1 | modem | Gateway/Router |
| 192.168.0.2 | W1700K-* | Network device |
| 192.168.0.4 | Pixel-8-Pro | Mobile device |
| 192.168.0.8 | trigkey | **This host** |
| 192.168.0.10 | - | Unknown |
| 192.168.0.11 | BPRokuStreamingStick | Streaming device |
| 192.168.0.12 | Galaxy-Tab-S5e | Tablet |
| 192.168.0.20 | Johns-MBP | MacBook Pro |
| 192.168.0.22 | roborock-vacuum-a75 | IoT device |
| 192.168.0.40 | homeassistant | **Home Assistant OS** |
| 192.168.0.41 | homeassistant | Home Assistant (alt) |
| 192.168.0.103 | - | Unknown |
| 192.168.0.106 | - | Unknown |
| 192.168.0.107 | cyberdeck | Workstation |
| 192.168.0.109 | cyberdeck | Workstation (alt) |

---

## 8. Key Findings Summary

### Pass Criteria Status

| Check | Status | Notes |
|-------|--------|-------|
| OS identified | PASS | Ubuntu 24.04.3 LTS |
| Network interfaces mapped | PASS | wlo1 @ 192.168.0.8/24 |
| Existing services inventoried | PASS | Port 80 conflict identified |
| Firewall state captured | PASS | No active rules |
| Docker presence validated | PASS | v29.2.0 |

### Pre-Flight Score: PASS

### Action Items Before Proceeding

1. **Port 80 Conflict:** Move Wiki.js from port 80 to port 3080
2. **Tailscale Installation:** Install and configure as subnet router
3. **Reverse Proxy:** Deploy Nginx Proxy Manager on ports 80/443
4. **Home Assistant:** Verify reachability at 192.168.0.40/41

---

## Appendix: Raw Commands Used

```bash
# OS identification
cat /etc/os-release && uname -a

# Network interfaces
ip -4 addr show && ip route show

# Port conflicts
ss -tlnp | grep -E ':(80|443)\s'

# Firewall state
sudo ufw status verbose
sudo nft list ruleset

# Docker status
docker --version && docker info
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"

# IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# LAN scan
nmap -sn 192.168.0.0/24
```
