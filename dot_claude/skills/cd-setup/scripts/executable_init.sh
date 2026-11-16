#!/usr/bin/env bash
# production Environment を作り、~/himitu/.env の Tailscale OAuth だけを secrets に登録する。
# 本番サーバー上で、作業用ユーザー（gh auth login 済み）として実行する。
set -euo pipefail

env_file=~/himitu/.env
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

# .env は source しない。該当行だけを grep で読む
get() {
  local v
  v=$(grep -E "^$1=" "$env_file" | tail -n1 | cut -d= -f2-) || true
  v=${v%\"}; v=${v#\"}; v=${v%\'}; v=${v#\'}
  printf '%s' "$v"
}

[[ -r $env_file ]] || { echo "cannot read $env_file" >&2; exit 1; }
id=$(get TS_OAUTH_CLIENT_ID)
secret=$(get TS_OAUTH_SECRET)
[[ -n $id && -n $secret ]] || { echo "TS_OAUTH_CLIENT_ID / TS_OAUTH_SECRET missing or empty in $env_file" >&2; exit 1; }

# Environment を作り、デプロイできるブランチを main に限定する
gh api -X PUT "repos/$repo/environments/production" --input - >/dev/null <<JSON
{"deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
JSON
gh api "repos/$repo/environments/production/deployment-branch-policies" --jq '.branch_policies[].name' | grep -qx main ||
  gh api -X POST "repos/$repo/environments/production/deployment-branch-policies" -f name=main -f type=branch >/dev/null

# 値は標準入力で渡す（--body だと ps に出る）。printf は builtin なので ps に出ない
printf '%s' "$id"     | gh secret set TS_OAUTH_CLIENT_ID --env production --repo "$repo"
printf '%s' "$secret" | gh secret set TS_OAUTH_SECRET    --env production --repo "$repo"
echo "done: $repo (production)"
