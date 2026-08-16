# dotfiles
The best dotfiles for hijoushoku.

---

## インストール

### Linux / WSL

```sh
sudo apt-get update && sudo apt-get install -y curl
```


```sh
sh -c "$(curl -fsLS https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.sh)"
```


```sh
exec zsh -l
```

### Windows ネイティブ

```powershell
winget install twpayne.chezmoi
chezmoi init --apply hijoushoku7/dotfiles
```


## セットアップ後にやること

```sh
gh auth login          # GitHub 認証
gh auth setup-git      # git の認証情報ヘルパーを設定 (下記の autoPush に必要)
claude                 # 初回起動でログイン
codex                  # 初回起動でログイン
```

> **注意**: `.chezmoi.toml.tmpl` で `autoCommit` / `autoPush` を有効にしているため、
> `chezmoi add` / `chezmoi edit` した内容は自動で GitHub に push される。
> 新しいマシンは HTTPS で clone されるので、`gh auth setup-git` を済ませるまで push は失敗する。

---

## 日常の使い方

```sh
chezmoi add ~/.foorc      # 新しいファイルを管理下に置く
chezmoi edit ~/.zshrc     # 管理下のファイルを編集する (cm edit でも可)
chezmoi diff              # ホームとの差分を見る
chezmoi apply             # 差分を反映する
chezmoi update            # git pull してから apply する

mise ls                   # 入っているツールを見る
mise outdated             # 更新があるか見る
mise upgrade              # config.toml の指定範囲内で最新へ
```
---
