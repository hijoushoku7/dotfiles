---
name: dc-setup
description: Adds traefik routing labels (and joins the shared cloudflare_tunnel_net network) to a docker-compose service. Manual-only — invoke ONLY when the user explicitly says "/dc-setup", "dc-setup", or "./dc-setup". Do not use this on your own just because a Dockerfile or docker-compose.yml is being written; the user runs it themselves when they want it.
---

# dc-setup

Only run this when the user explicitly asks for it by name. Writing a normal
Dockerfile/docker-compose.yml does not need traefik labels by default.

## What it does

Installs a small script, `dc-setup`, into the current project root so the
user can regenerate the snippet themselves later without Claude:

```bash
cp ~/.claude/skills/dc-setup/scripts/dc-setup.sh ./dc-setup
chmod +x ./dc-setup
```

Then run it (or tell the user how) to get the snippet:

```bash
./dc-setup <service-name> <container-port> [domain] [network]
# domain defaults to hijoushoku.com
# network defaults to cloudflare_tunnel_net
```

It prints two blocks:

1. A `labels:` + `networks:` block to paste inside the service definition.
2. A top-level `networks:` block (external network) to paste once at the
   bottom of the compose file.

## Rules

- The network is always `cloudflare_tunnel_net`, and it is always declared
  `external: true` — this network is created once outside the project
  (`docker network create cloudflare_tunnel_net`) and every service that
  needs traefik routing joins it. Never invent a per-project network for
  this.
- `traefik.docker.network` must match the network name exactly, or traefik
  can't reach the container even with routing labels present.
- The script only prints the snippet — it does not edit YAML in place.
  Paste it into the relevant compose file yourself (or ask the user where).
- If asked to apply this to a Dockerfile instead of compose, use `LABEL`
  instructions with the same keys — but compose labels are the normal case
  and Dockerfile LABEL is inherited by containers, so prefer compose unless
  the user asks otherwise.
