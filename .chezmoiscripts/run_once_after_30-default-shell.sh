#!/bin/sh
# デフォルトシェルを zsh に変更する。
#
# 新しい環境はたいてい bash から始まるので、
#   1. /etc/shells に zsh を登録
#   2. chsh でログインシェルを変更
#   3. chsh が使えない環境 (Docker / LDAP ユーザなど) では
#      ~/.bashrc から zsh を exec するフォールバックを仕込む
# の順で対応する。

set -eu

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }

ZSH_BIN="$(command -v zsh 2>/dev/null || true)"

if [ -z "$ZSH_BIN" ]; then
    warn "zsh が見つからないためデフォルトシェルの変更をスキップします"
    exit 0
fi

# 既に zsh ならなにもしない
case "$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)" in
    */zsh)
        log "デフォルトシェルは既に zsh です"
        exit 0
        ;;
esac

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

# 1. /etc/shells に登録されていないと chsh が拒否する
if ! grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null; then
    if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        log "/etc/shells に ${ZSH_BIN} を登録します"
        printf '%s\n' "$ZSH_BIN" | $SUDO tee -a /etc/shells >/dev/null
    fi
fi

# 2. chsh (パスワードを聞かれることがある)
log "デフォルトシェルを ${ZSH_BIN} に変更します"
if chsh -s "$ZSH_BIN" 2>/dev/null; then
    log "変更しました。次回ログインから有効です"
    exit 0
fi

# 3. フォールバック: bash 起動時に zsh へ移る
warn "chsh に失敗しました。~/.bashrc からのフォールバックを設定します"

MARKER="# >>> dotfiles: prefer zsh >>>"
if [ -f "${HOME}/.bashrc" ] && grep -qF "$MARKER" "${HOME}/.bashrc"; then
    log "フォールバックは設定済みです"
    exit 0
fi

cat >>"${HOME}/.bashrc" <<EOS

${MARKER}
# デフォルトシェルを変更できなかったので、対話 bash なら zsh に切り替える
if [ -t 1 ] && [ -z "\${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
fi
# <<< dotfiles: prefer zsh <<<
EOS

log "~/.bashrc にフォールバックを追記しました"
