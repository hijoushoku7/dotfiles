#!/bin/sh
# apt で入れておきたい最低限のパッケージ。
# 言語ランタイムや CLI ツールは mise 側 (~/.config/mise/config.toml) で管理するので
# ここには「mise で扱わないもの」だけを書く。
#
# Windows ネイティブ側の対応物は run_once_before_00-windows-packages.ps1。

set -eu

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }

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

# 無いと困るもの。入らなければ失敗させる。
PACKAGES="zsh git curl unzip ca-certificates locales"

# 入れば嬉しいが、無くても動くもの。失敗しても apply を止めない。
OPTIONAL_PACKAGES=""

# WSL では Windows 側と行き来するためのユーティリティを足す。
# wslu = wslview (Windows 既定のブラウザで開く) など。
# ディストリによっては universe に無いので optional 扱い。
if [ -r /proc/sys/kernel/osrelease ]; then
    case "$(tr '[:upper:]' '[:lower:]' < /proc/sys/kernel/osrelease)" in
        *microsoft*|*wsl*)
            log "WSL を検出しました"
            OPTIONAL_PACKAGES="${OPTIONAL_PACKAGES} wslu"
            ;;
    esac
fi

# 未インストールのものを拾う
select_missing() {
    _missing=""
    for _pkg in $1; do
        dpkg-query -W -f='${Status}' "$_pkg" 2>/dev/null | grep -q "^install ok installed$" \
            || _missing="${_missing} ${_pkg}"
    done
    printf '%s' "${_missing# }"
}

missing="$(select_missing "$PACKAGES")"
missing_optional="$(select_missing "$OPTIONAL_PACKAGES")"

if [ -z "$missing" ] && [ -z "$missing_optional" ]; then
    log "apt パッケージは全て導入済みです"
    exit 0
fi

$SUDO apt-get update -qq

if [ -n "$missing" ]; then
    log "apt パッケージをインストールします: ${missing}"
    # shellcheck disable=SC2086 # $missing は意図的に単語分割する
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends $missing
fi

if [ -n "$missing_optional" ]; then
    log "任意の apt パッケージをインストールします: ${missing_optional}"
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends \
        $missing_optional \
        || warn "${missing_optional} は入りませんでした (無くても動きます)"
fi
