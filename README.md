# Homelab Skeleton

A robust, self-hosted homelab skeleton managed via Docker Compose and GitHub Actions, with external access provided by Cloudflare Tunnel and integrated observability using the LGTM stack.

## 🚀 Overview

This project serves as a template for a personal, self-hosted server. It automates the synchronization and deployment of several popular self-hosted applications while maintaining strict data persistence and monitoring standards.

### Features
- **Application Orchestration**: Docker Compose for easy management of services.
- **External Access**: Cloudflare Tunnel for secure, VPN-less access without opening firewall ports.
- **Automated Deployment**: GitHub Actions workflow (`Homelab Sync`) to automatically sync and restart services on push.
- **Full-Stack Observability**: Integrated LGTM stack (Loki, Grafana, Tempo, Mimir) with OpenTelemetry (Grafana Alloy).

## 📂 Directory Structure

The project follows a specific hierarchy to ensure easy backups and configuration management:

- `/opt/homelab/repo/`: Contains this repository (all configuration files).
- `/opt/homelab/data/`: Persistent application data (e.g., Nextcloud files, Immich media, Grafana DB).
- `/opt/homelab/secrets/`: Sensitive credentials and `.env` files (excluded from Git).

## 🛠 Tech Stack

### Applications
- **Immich**: High-performance self-hosted photo and video management.
- **Nextcloud**: Comprehensive productivity and file storage suite.
- **Nginx**: Lightweight web server for general use.
- **Flask-app**: Template for custom web services.

### Observability (LGTM)
- **Grafana**: Dashboarding and alerting visualization.
- **Loki**: Log aggregation with WARN+ filtering to save storage.
- **Mimir**: High-performance time-series metrics storage.
- **Tempo**: Distributed tracing for debugging application latency.
- **Grafana Alloy**: Unified OpenTelemetry collector for host and container metrics.
- **Alertmanager**: Routing and management of critical system alerts.

## ⚙️ How it Works

1. **Deployment**: When code is pushed to the `main` branch, a GitHub self-hosted runner:
   - Syncs all repository files to `/opt/homelab/repo/` using `rsync`.
   - Automatically registers any new DNS routes in the Cloudflare Tunnel.
   - Restarts `docker compose` for all stacks (Immich, Nextcloud, Nginx, Flask, Monitoring).
2. **Persistence**: All application data is mapped to `/opt/homelab/data/<app-name>` on the host, making the server easy to back up by simply targeting this folder.
3. **Monitoring**: Grafana Alloy runs as a root container to scrape system probes (`/proc`, `/sys`, Docker socket). It collects:
   - Host CPU, Memory, and Disk usage.
   - Container-level resource usage and logs.
   - OTLP traces from applications.
4. **Networking**: The Cloudflare Tunnel (`config.yml`) routes subdomains to internal services:
   - `monitoring.rafaelghiorzi.org` -> Grafana (Port 3000)
   - `fotos.rafaelghiorzi.org` -> Immich (Port 2283)
   - `drive.rafaelghiorzi.org` -> Nextcloud (Port 8080)

## 🚦 Getting Started

1. **Configure Secrets**: Ensure `/opt/homelab/secrets/.env` and `/opt/homelab/secrets/tunnel-credentials.json` are present on the host.
2. **Cloudflare**: Set up a Tunnel via the Cloudflare Zero Trust dashboard and update `cloudflare/config.yml` with your tunnel ID.
3. **Push to Main**: GitHub Actions will handle the rest.

## 🔔 Alerts

The system is configured to alert for:
- High Host/Container CPU & Memory (>80%).
- Container downtime/restarts.
- High application latency (p99 > 1s).
- Critical system errors in logs.
