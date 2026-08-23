#!/bin/sh
# Docker Engine + Compose plugin を入れる。デーモンが要るので mise ではなく
# 公式の convenience script (get.docker.com) に任せる。
# ディストリ判定・GPGキー・apt repo 登録・compose/buildx プラグインまで面倒を見てくれる。
#
# Docker Desktop (WSL 統合) 環境では docker が既に PATH にあるので何もしない。

set -eu

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }

if command -v docker >/dev/null 2>&1; then
    log "docker は導入済みです"
    exit 0
fi

command -v apt-get >/dev/null 2>&1 || {
    log "apt-get が無いので docker のインストールはスキップします"
    exit 0
}

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    log "root でも sudo でもないので docker のインストールはスキップします"
    exit 0
fi

log "Docker Engine をインストールします (時間がかかります)"
curl -fsSL https://get.docker.com | $SUDO sh

# sudo 無しで docker を叩けるようにする。反映は再ログイン後。
if ! id -nG "$(id -un)" | grep -qw docker; then
    log "$(id -un) を docker グループに追加します (再ログインで有効)"
    $SUDO usermod -aG docker "$(id -un)" || warn "グループ追加に失敗しました"
fi

# WSL で systemd が無い場合、デーモンは自動起動しない。
if [ -r /proc/sys/kernel/osrelease ] &&
   grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease &&
   ! pidof systemd >/dev/null 2>&1; then
    warn "systemd 無しの WSL です。'sudo service docker start' で起動するか"
    warn "/etc/wsl.conf に [boot] systemd=true を書いてください"
fi
