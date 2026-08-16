#!/bin/sh
# dotfiles bootstrap script (Linux / WSL 用)
#
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.sh)"
#
# Windows ネイティブ側は自動化していない (README を参照)。
#
# ここでやるのは chezmoi を動かすための最小限だけ。
#   1. curl / git / ca-certificates を入れる
#   2. chezmoi を ~/.local/bin に入れる
#   3. chezmoi init --apply でリポジトリを展開する
#
# zsh / mise / oh-my-zsh / デフォルトシェル変更などは、展開後に
# .chezmoiscripts/ 配下のスクリプトが自動で実行する。
# こうしておくと既存マシンで `chezmoi update` しても同じ処理が走る。

set -eu

REPO="hijoushoku7/dotfiles"
BIN_DIR="${HOME}/.local/bin"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 0. 環境判定
# ---------------------------------------------------------------------------

IS_WSL=0
if [ -r /proc/sys/kernel/osrelease ]; then
    case "$(tr '[:upper:]' '[:lower:]' < /proc/sys/kernel/osrelease)" in
        *microsoft*|*wsl*) IS_WSL=1 ;;
    esac
fi

# WSL では Windows 側の PATH (/mnt/c/...) が繋がっているので、
# `command -v git` が git.exe を、`command -v chezmoi` が chezmoi.exe を
# 拾ってしまうことがある。Windows 側のバイナリを Linux 側の設定に使うと
# パス表記も改行コードも噛み合わないので、判定からは除外する。
have() {
    _p="$(command -v "$1" 2>/dev/null)" || return 1
    [ -n "$_p" ] || return 1
    if [ "$IS_WSL" -eq 1 ]; then
        case "$_p" in
            /mnt/*|*.exe) return 1 ;;
        esac
    fi
    printf '%s\n' "$_p"
}

if [ "$IS_WSL" -eq 1 ]; then
    log "WSL を検出しました (Linux 側として設定します)"
fi

# ---------------------------------------------------------------------------
# 1. 前提パッケージ
# ---------------------------------------------------------------------------

# root なら sudo 不要。そうでなければ sudo を使う。どちらも無ければ諦める。
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

missing=""
for cmd in curl git; do
    have "$cmd" >/dev/null || missing="${missing} ${cmd}"
done

if [ -n "${missing# }" ]; then
    log "不足しているコマンドをインストールします:${missing}"
    if command -v apt-get >/dev/null 2>&1; then
        if [ "$(id -u)" -ne 0 ] && [ -z "$SUDO" ]; then
            die "root でも sudo も使えないため${missing} を入れられません。手動で入れてください。"
        fi
        $SUDO apt-get update -qq
        # shellcheck disable=SC2086 # $missing は意図的に単語分割する
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends \
            ca-certificates $missing
    else
        die "apt-get が見つかりません。${missing} を手動でインストールしてから再実行してください。"
    fi
fi

# ---------------------------------------------------------------------------
# 2. chezmoi
# ---------------------------------------------------------------------------

if chezmoi="$(have chezmoi)"; then
    : # 見つかった (WSL 上の chezmoi.exe は have() が弾く)
elif [ -x "${BIN_DIR}/chezmoi" ]; then
    chezmoi="${BIN_DIR}/chezmoi"
else
    log "chezmoi をインストールします -> ${BIN_DIR}"
    mkdir -p "${BIN_DIR}"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${BIN_DIR}"
    chezmoi="${BIN_DIR}/chezmoi"
fi

log "chezmoi: ${chezmoi}"

# .chezmoiscripts から呼ばれるツールが ~/.local/bin を見られるようにしておく
PATH="${BIN_DIR}:${PATH}"
export PATH

# ---------------------------------------------------------------------------
# 3. 展開
# ---------------------------------------------------------------------------

log "dotfiles を展開します: ${REPO}"
"${chezmoi}" init --apply "${REPO}"

cat <<'EOS'

==> セットアップが完了しました。

    次のコマンドで zsh に切り替わります:

        exec zsh -l

    残りの手動作業は README の「セットアップ後にやること」を参照してください。

EOS
