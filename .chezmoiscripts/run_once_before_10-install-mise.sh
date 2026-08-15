#!/bin/sh
# mise 本体をインストールする。
# ツールの中身 (node/go/eza/...) は ~/.config/mise/config.toml が配置されたあとに
# run_onchange_after_20-mise-install.sh がインストールする。

set -eu

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if command -v mise >/dev/null 2>&1 || [ -x "${HOME}/.local/bin/mise" ]; then
    log "mise は導入済みです"
    exit 0
fi

log "mise をインストールします -> ~/.local/bin/mise"
curl -fsSL https://mise.run | MISE_QUIET=1 sh
