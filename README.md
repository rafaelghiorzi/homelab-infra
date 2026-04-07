# Homelab Infrastructure Skeleton

This repository serves as an infrastructure skeleton 
for a self-hosted server, also called homelab!
It is managed via Docker Compose and GitHub Actions, with external access provided 
by Cloudflare Tunnel and integrated LGTM monitoring stack

## Overview

This project automates the synchronization and deployment of popular self-hosted
applications while maintaining strict data persistence and monitoring standards.

### Features
- **Application Orchestration**: Docker Compose for easy management of services.
- **External Access**: Cloudflare Tunnel for secure, VPN-less access without opening firewall ports.
- **Automated Deployment**: GitHub Actions workflow (`Homelab Sync`) to automatically sync and restart services on push.
- **Full-Stack Observability**: Integrated LGTM stack (Loki, Grafana, Tempo, Mimir) with OpenTelemetry (Grafana Alloy).

## Directory Structure

The project follows a specific hierarchy to ensure easy backups and configuration management:

- `/opt/homelab/repo/`: Contains this repository (all configuration files).
- `/opt/homelab/data/`: Persistent application data (e.g., Nextcloud files, Immich media, Grafana DB).
- `/opt/homelab/secrets/`: Sensitive credentials and `.env` files (excluded from Git).

## How it Works

1. **Deployment**: When code is pushed to the `main` branch, a GitHub self-hosted runner:
   - Syncs all repository files to `/opt/homelab/repo/` using `rsync`.
   - Automatically registers any new DNS routes in the Cloudflare Tunnel.
   - Restarts `docker compose` for all stacks (Immich, Nextcloud, Nginx, Flask, Monitoring).
2. **Persistence**: All application data is mapped to `/opt/homelab/data/<app-name>` on the host, making the server easy to back up by simply targeting this folder (view TODO section to understando how this will change in the future).
3. **Monitoring**: Grafana Alloy runs as a root container to scrape system probes (`/proc`, `/sys`, Docker socket). It collects:
   - Host CPU, Memory, and Disk usage.
   - Container-level resource usage and logs.
   - OTLP traces from applications.
4. **Networking**: The Cloudflare Tunnel (`config.yml`) routes subdomains to internal services:
   - `monitoring.rafaelghiorzi.org` -> Grafana (Port 3000)
   - `fotos.rafaelghiorzi.org` -> Immich (Port 2283)
   - `drive.rafaelghiorzi.org` -> Nextcloud (Port 8080)

## Alerts

The system is configured to alert for:
- High Host/Container CPU & Memory (>80%).
- Container downtime/restarts.
- High application latency (p99 > 1s).
- Critical system errors in logs.

## TODO

There are still much to go over in this project, so I created a list of things that still need completion

- Add RAID and Pooling for data backup and 3-2-1 backup methods
- Add Nginx reverse proxy for port routing (if necessary, as cloudflare does this already)
- Add more security measures, stronger firewall
- Add ansible playbooks for environment reprodutibility
- Fix monitoring logic, as it is yet not fully working
- Add testing workflow to GitHub Actions
