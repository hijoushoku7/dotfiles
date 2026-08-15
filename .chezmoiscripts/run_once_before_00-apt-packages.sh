#!/bin/sh
# apt で入れておきたい最低限のパッケージ。
# 言語ランタイムや CLI ツールは mise 側 (~/.config/mise/config.toml) で管理するので
# ここには「mise で扱わないもの」だけを書く。

set -eu

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

command -v apt-get >/dev/null 2>&1 || {
    log "apt-get が無いのでパッケージのインストールはスキップします"
    exit 0
}

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    log "root でも sudo でもないのでパッケージのインストールはスキップします"
    exit 0
fi

PACKAGES="zsh git curl unzip ca-certificates locales"

missing=""
for pkg in $PACKAGES; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "^install ok installed$" \
        || missing="${missing} ${pkg}"
done

if [ -z "${missing# }" ]; then
    log "apt パッケージは全て導入済みです"
    exit 0
fi

log "apt パッケージをインストールします:${missing}"
$SUDO apt-get update -qq
# shellcheck disable=SC2086 # $missing は意図的に単語分割する
DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends $missing
