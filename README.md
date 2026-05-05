# Homelab Cookbook

This repository contains files and documentation for setting up and maintaining a homelab infrastructure. It includes Ansible playbooks, configuration files, and guides for various services and applications commonly used in a homelab environment.

# TODO List

- Run and Manage Proxmox to leverage VMs
- Add RAID and ZFS for data backup
- Add Nginx reverse proxy for port routing
- Update Ansible playbooks to fit scenarios
- Fix GitHub Actions to only run with new release tags
- Add testing/linting/integration workflow to actions
- Better organize the homelab cookbook
- Cron jobs to check container health and restart if necessary
- Add monitoring and alerting for container health (LGTM, uptime Kuma)

For linting: YAML lint, Ansible Lint, Dockerfile Lint

# Apps to add:
- Portainer for Docker management
- LGTM for log monitoring
- Nginx Proxy Manager for reverse proxy management
- Nextcloud for file sharing and backup
- Jellyfin for media server
- Immich for photo management
- PiHole for ad blocking and DNS
- Glance for dashboard and monitoring
- BitWarden for password management
- Cockpit for server management
- Overseerr for media request management
- arr stack for media management (sonarr, radarr, etc)
- Cloudflare tunnel and DDNS for external access
- TailScale for secure VPN access (maybe, not sure if I want this yet)

# Organizing the homelab groups

## 1. Network & Access Layer

*These run in isolated LXC containers for stability and low-level network control.*

- Pi-hole  
  → 1 LXC (dedicated, no Docker)

- Nginx Proxy Manager  
  → 1 LXC (runs Docker inside)

- Cloudflare Tunnel  
  → Runs inside the same LXC as Nginx Proxy Manager (Docker container)


## 2. Monitoring & Management Layer

*These run together in a single Docker host to simplify integration and communication.*

- Grafana  
  → Docker container

- Prometheus  
  → Docker container

- Loki  
  → Docker container

- Glance  
  → Docker container

Deployment:
→ 1 LXC running Docker (all services via Docker Compose)


## 3. Storage & Personal Cloud Layer

*These run in a VM due to storage complexity, database usage, and need for stronger isolation.*

- Nextcloud  
  → Docker container

- Immich  
  → Docker container

Deployment:
→ 1 VM running Docker (both services via Docker Compose)


## 4. Media Stack

*These run in a dedicated VM for performance (disk I/O, network, optional GPU acceleration).*

- Jellyfin  
  → Docker container

- Sonarr  
  → Docker container

- Radarr  
  → Docker container

- Overseerr  
  → Docker container

Deployment:
→ 1 VM running Docker (all services via Docker Compose)


## 5. Security & Secrets Management

*This is isolated due to sensitivity.*

- Bitwarden  
  → Docker container

Deployment options:
→ Option A: 1 dedicated LXC running Docker (recommended)  
→ Option B: 1 small VM running Docker


## 6. Management & Orchestration

*These manage infrastructure and should have stable access to the system.*

- Portainer  
  → Docker container

- Cockpit  
  → Installed directly on LXC (or host-level alternative)

Deployment:
→ 1 LXC running Docker (Portainer)  
→ Cockpit installed directly in the same LXC (no Docker)


---

## Summary

LXC Containers:
- 1 × Pi-hole
- 1 × Nginx Proxy Manager + Cloudflare Tunnel (Docker inside)
- 1 × Tailscale
- 1 × Monitoring stack (Docker host)
- 1 × Management (Portainer + Cockpit)
- 1 × Bitwarden (optional, if not using VM)

Total: 5–6 LXCs

Virtual Machines:
- 1 × Storage (Nextcloud + Immich)
- 1 × Media stack

Total: 2 VMs

Docker Hosts:
- 1 × Reverse proxy LXC
- 1 × Monitoring LXC
- 1 × Management LXC
- 1 × Storage VM
- 1 × Media VM
- 1 × Bitwarden (if using LXC or VM)

Total: 5–6 Docker environments