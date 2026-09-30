#!/usr/bin/env bash
# Prints a traefik-ready labels/networks snippet for a docker-compose service.
# Usage: ./dc-setup <service-name> <container-port> [domain] [network]
set -euo pipefail

name="${1:?usage: dc-setup <service-name> <container-port> [domain] [network]}"
port="${2:?usage: dc-setup <service-name> <container-port> [domain] [network]}"
domain="${3:-hijoushoku.com}"
network="${4:-cloudflare_tunnel_net}"

cat <<EOF
# --- paste into the service block in compose.yml / docker-compose.yml ---
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${name}.rule=Host(\`${name}.${domain}\`)"
      - "traefik.http.services.${name}.loadbalancer.server.port=${port}"
      - "traefik.docker.network=${network}"
    networks:
      - ${network}

# --- add once at the bottom of the compose file ---
networks:
  ${network}:
    external: true
    name: ${network}
EOF
