# dotfiles

hijoushoku 専用の dotfiles。[chezmoi](https://www.chezmoi.io/) で管理し、
言語ランタイムと CLI ツールは [mise](https://mise.jdx.dev/) に任せている。

対象環境は **Ubuntu / Debian (apt)** 系。

---

## インストール

新しいマシンで、これ 1 行だけ。

```sh
sh -c "$(curl -fsLS https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.sh)"
```

終わったら zsh に入る。

```sh
exec zsh -l
```

`curl` すら無い最小構成の場合は先に入れておく。

```sh
sudo apt-get update && sudo apt-get install -y curl
```

### 何が起きるか

| 段階 | 実体 | 内容 |
|---|---|---|
| 1 | `install.sh` | `curl` / `git` / `ca-certificates` を apt で導入 |
| 2 | `install.sh` | chezmoi を `~/.local/bin` に導入 |
| 3 | `install.sh` | `chezmoi init --apply hijoushoku7/dotfiles` |
| 4 | `run_once_before_00-apt-packages.sh` | `zsh` `unzip` `locales` などを apt で導入 |
| 5 | `run_once_before_10-install-mise.sh` | mise 本体を `~/.local/bin` に導入 |
| 6 | chezmoi apply | 設定ファイルを配置 + oh-my-zsh / zsh-autosuggestions を clone |
| 7 | `run_onchange_after_20-mise-install.sh` | `mise install` で node / go / gh / starship などを導入 |
| 8 | `run_once_after_30-default-shell.sh` | `chsh` でデフォルトシェルを zsh に変更 |

`install.sh` は chezmoi を動かすための最小限しかやらない。
残りは全て `.chezmoiscripts/` に置いてあるので、**既存マシンで `chezmoi update` しても同じ処理が走る**。
セットアップ手順が新規／既存で二重管理にならないようにしている。

### bash → zsh の切り替えについて

`chsh` はパスワードを聞かれることがある。
`chsh` が使えない環境 (Docker コンテナや LDAP 管理ユーザ) では、
フォールバックとして `~/.bashrc` に「対話 bash なら `exec zsh -l`」を追記する。

---

## セットアップ後にやること

自動化できない／すべきでないもの。

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

ツールを追加したいときは `~/.config/mise/config.toml` を編集して `chezmoi apply`。
ハッシュが変わるので `mise install` が自動で走る。

---

## 構成

```
.
├── install.sh                    # ブートストラップ (curl で叩く)
├── .chezmoi.toml.tmpl            # chezmoi 自身の設定
├── .chezmoiignore                # ホームに配置しないもの
├── .chezmoiexternal.toml         # oh-my-zsh / zsh-autosuggestions の取得先
├── .chezmoiscripts/              # apply 時に自動実行されるスクリプト
│   ├── run_once_before_00-apt-packages.sh
│   ├── run_once_before_10-install-mise.sh
│   ├── run_onchange_after_20-mise-install.sh.tmpl
│   └── run_once_after_30-default-shell.sh
├── dot_zshrc                     # -> ~/.zshrc
├── dot_tmux.conf                 # -> ~/.tmux.conf
├── dot_claude/settings.json      # -> ~/.claude/settings.json
└── dot_config/
    ├── mise/config.toml          # 管理するツールとバージョン
    ├── starship.toml             # プロンプト
    ├── jgit/config
    └── wezterm/                  # クライアント側の端末設定
```

`.chezmoiscripts/` 内のスクリプトは実行されるだけで、ホームには配置されない。

### oh-my-zsh の扱い

oh-my-zsh と zsh-autosuggestions はリポジトリに同梱せず、
`.chezmoiexternal.toml` で宣言して chezmoi に clone させている
(週 1 回 `git pull` される)。`omz update` もそのまま使える。
