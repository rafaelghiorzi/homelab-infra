# Docker Network Architecture

This document explains the Docker networks used in this homelab repository and which stacks are attached to each network.

## Shared networks

### `proxy`
Used by the reverse proxy stack and any services that need to be reachable through Nginx Proxy Manager.

Attached services:
- `nginx-proxy-manager` (`apps/nginx/docker-compose.yml`)
- `cloudflare-tunnel` (`apps/nginx/docker-compose.yml`)
- test `helloworld` service (`apps/nginx/docker-compose.yml`)
- `portainer` (`apps/portainer/docker-compose.yml`)
- Monitoring services:
  - `prometheus`
  - `grafana`
  - `loki`
  - `cadvisor`
  - `node_exporter`
- `glance` (`apps/glance/docker-compose.yml`)
- `nextcloud` app service (`apps/nextcloud/docker-compose.yml`)
- `immich-server` (`apps/immich/docker-compose.yml`)

Purpose:
- Allows Nginx Proxy Manager to see and route traffic to exposed containers.
- Provides a shared overlay for management and other externally exposed services.

### `management`
Used by Portainer for management isolation.

Attached services:
- `portainer` (`apps/portainer/docker-compose.yml`)

Purpose:
- Keeps Portainer on its own management network while still allowing it to connect to Docker via the socket.

## Group networks

### `monitoring`
Used for the monitoring stack and the Glance dashboard.

Attached services:
- `prometheus` (`apps/monitoring/docker-compose.yml`)
- `grafana` (`apps/monitoring/docker-compose.yml`)
- `loki` (`apps/monitoring/docker-compose.yml`)
- `cadvisor` (`apps/monitoring/docker-compose.yml`)
- `node_exporter` (`apps/monitoring/docker-compose.yml`)
- `promtail` (`apps/monitoring/docker-compose.yml`)
- `glance` (`apps/glance/docker-compose.yml`)

Purpose:
- Provides internal service discovery and communication for monitoring components.
- Keeps monitoring traffic isolated from storage and other groups.

### `storage`
Used for the storage/personal cloud group.

Attached services:
- `db` and `redis` for Nextcloud (`apps/nextcloud/docker-compose.yml`)
- `app` and `cron` for Nextcloud (`apps/nextcloud/docker-compose.yml`)
- `immich-server`, `immich-machine-learning`, `redis`, and `database` for Immich (`apps/immich/docker-compose.yml`)

Purpose:
- Keeps storage-related backend services isolated while allowing the application services to communicate internally.
- Allows externally routed apps like Nextcloud and Immich server to attach to `proxy` without exposing backend-only services.

## Notes

- `proxy` is the primary network used by the reverse proxy to route traffic.
- Services that do not need direct proxy routing remain on their group network only.
- If external access is required, attach the service to both its group network and `proxy`.

## How to use

When adding a new stack, choose one of these networks based on the application group:
- `proxy` for services that need reverse proxy routing.
- `monitoring` for monitoring/dashboard services.
- `storage` for Nextcloud/Immich type services.
- `management` for management tooling like Portainer.

If a service must be routed by Nginx Proxy Manager, attach it to `proxy` as well.
