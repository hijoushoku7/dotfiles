#!/bin/sh
# dotfiles setup script
#
#   sh -c "$(curl -fsLS https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.sh)"
#
# chezmoi をインストールし、このリポジトリを適用する。

set -eu

REPO="hijoushoku7/dotfiles"
BIN_DIR="${HOME}/.local/bin"

if command -v chezmoi >/dev/null 2>&1; then
    chezmoi="$(command -v chezmoi)"
elif [ -x "${BIN_DIR}/chezmoi" ]; then
    chezmoi="${BIN_DIR}/chezmoi"
else
    echo "chezmoi が見つからないためインストールします -> ${BIN_DIR}"
    mkdir -p "${BIN_DIR}"
    if command -v curl >/dev/null 2>&1; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${BIN_DIR}"
    elif command -v wget >/dev/null 2>&1; then
        sh -c "$(wget -qO- get.chezmoi.io)" -- -b "${BIN_DIR}"
    else
        echo "curl か wget が必要です" >&2
        exit 1
    fi
    chezmoi="${BIN_DIR}/chezmoi"
fi

echo "chezmoi: ${chezmoi}"
exec "${chezmoi}" init --apply "${REPO}"
