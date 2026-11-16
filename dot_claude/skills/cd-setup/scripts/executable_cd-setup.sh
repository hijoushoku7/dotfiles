#!/usr/bin/env bash
# Usage: cd-setup.sh <server>   (git レポのルートで実行)
set -euo pipefail

server=${1:?usage: cd-setup.sh <server>}
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
skill_dir=$(cd "$(dirname "$0")" && pwd)
wf=.github/workflows/deploy.yml

for f in "$wf" init.sh; do
  [[ -e $f ]] && { echo "already exists: $f" >&2; exit 1; }
done

mkdir -p .github/workflows
cat > "$wf" <<YAML
name: deploy

on:
  push:
    branches: [main]

concurrency: deploy-\${{ github.repository }}

jobs:
  deploy:
    if: github.repository == '$repo'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: tailscale/github-action@d1b6cd204f8dceda5b3eaad7f1f767be390056cd # v4.2.0
        with:
          oauth-client-id: \${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: \${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:ci
      - run: ssh -o StrictHostKeyChecking=accept-new deploy@$server "cd /srv/apps/\${{ github.event.repository.name }} && git pull && docker compose up -d --build"
YAML

install -m 755 "$skill_dir/init.sh" init.sh
echo "created: $wf, init.sh ($repo -> deploy@$server)"
