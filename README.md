# dotfiles

hijoushoku 専用の dotfiles。[chezmoi](https://www.chezmoi.io/) で管理し、
言語ランタイムと CLI ツールは [mise](https://mise.jdx.dev/) に任せている。

対象環境は 3 つ。

| 環境 | ブートストラップ | シェル | パッケージ |
|---|---|---|---|
| Linux (Ubuntu / Debian) | `install.sh` | zsh + oh-my-zsh | apt + mise |
| WSL (Ubuntu) | `install.sh` | zsh + oh-my-zsh | apt + mise |
| Windows ネイティブ | `install.ps1` | PowerShell 7 | winget + mise |

WSL は「Linux として」セットアップし、Windows 側と行き来するための差分だけを足す。
Windows ネイティブと WSL を両方使う場合は **両方走らせる** (それぞれ別のホームなので衝突しない)。

OS ごとの出し分けは chezmoi のテンプレート機能でおこなっている。
`.chezmoiignore` / `.chezmoiexternal.toml.tmpl` / `.chezmoi.toml.tmpl` はどれもテンプレートで、
`.chezmoi.os` と `.chezmoi.kernel.osrelease` (WSL 判定) を見て分岐する。

---

## インストール

### Linux / WSL

WSL の場合は WSL のターミナルの中で叩く。

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

### Windows ネイティブ

PowerShell で。

```powershell
irm https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.ps1 | iex
```

終わったら PowerShell を開き直す (プロファイルの読み込みと PATH の反映のため)。

`winget` が無い場合は Microsoft Store から「アプリ インストーラー」を入れておく。

### 何が起きるか (Linux / WSL)

| 段階 | 実体 | 内容 |
|---|---|---|
| 1 | `install.sh` | `curl` / `git` / `ca-certificates` を apt で導入 |
| 2 | `install.sh` | chezmoi を `~/.local/bin` に導入 |
| 3 | `install.sh` | `chezmoi init --apply hijoushoku7/dotfiles` |
| 4 | `run_once_before_00-apt-packages.sh` | `zsh` `unzip` `locales` などを apt で導入 (WSL なら `wslu` も) |
| 5 | `run_once_before_10-install-mise.sh` | mise 本体を `~/.local/bin` に導入 |
| 6 | chezmoi apply | 設定ファイルを配置 + oh-my-zsh / zsh-autosuggestions を clone |
| 7 | `run_onchange_after_20-mise-install.sh` | `mise install` で node / go / gh / starship などを導入 |
| 8 | `run_once_after_30-default-shell.sh` | `chsh` でデフォルトシェルを zsh に変更 |

### 何が起きるか (Windows)

| 段階 | 実体 | 内容 |
|---|---|---|
| 1 | `install.ps1` | `git` を winget で導入 |
| 2 | `install.ps1` | chezmoi を `~\.local\bin` に導入 + ユーザ PATH に追加 |
| 3 | `install.ps1` | `chezmoi init --apply hijoushoku7/dotfiles` |
| 4 | `run_once_before_00-windows-packages.ps1` | PowerShell 7 / WezTerm を winget で導入 |
| 5 | `run_once_before_10-install-mise.ps1` | mise 本体を winget → scoop → 単体 exe の順で導入 |
| 6 | chezmoi apply | 設定ファイルを配置 (zsh / tmux / oh-my-zsh は配置しない) |
| 7 | `run_onchange_after_20-mise-install.ps1` | `mise install` |
| 8 | `run_once_after_30-powershell-profile.ps1` | `$PROFILE` にスタブを設置 + `XDG_CONFIG_HOME` を設定 |

`install.sh` / `install.ps1` は chezmoi を動かすための最小限しかやらない。
残りは全て `.chezmoiscripts/` に置いてあるので、**既存マシンで `chezmoi update` しても同じ処理が走る**。
セットアップ手順が新規／既存で二重管理にならないようにしている。

`.chezmoiscripts/` の `*.sh` は Windows で、`*.ps1` は Unix で、それぞれ
`.chezmoiignore` によって除外される。`.ps1` を実行するインタプリタは
`.chezmoi.toml.tmpl` の `[interpreters.ps1]` で指定していて、
PowerShell 7 (`pwsh`) が無ければ Windows PowerShell (`powershell`) にフォールバックする。

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

ツールを追加したいときは `chezmoi edit ~/.config/mise/config.toml` (実体は
`dot_config/mise/config.toml.tmpl`) を編集して `chezmoi apply`。
ハッシュが変わるので `mise install` が自動で走る。

`chezmoi update` のときに
`config file template has changed, run chezmoi init to regenerate config file`
と言われたら `chezmoi init` を一度走らせる (`.chezmoi.toml.tmpl` を変えたとき)。

---

## 構成

```
.
├── install.sh                    # ブートストラップ / Linux・WSL (curl で叩く)
├── install.ps1                   # ブートストラップ / Windows (irm | iex で叩く)
├── .chezmoi.toml.tmpl            # chezmoi 自身の設定 (+ Windows の ps1 インタプリタ)
├── .chezmoiignore                # ホームに配置しないもの (OS で分岐)
├── .chezmoiexternal.toml.tmpl    # oh-my-zsh / zsh-autosuggestions の取得先 (Unix のみ)
├── .chezmoiscripts/              # apply 時に自動実行されるスクリプト
│   ├── run_once_before_00-apt-packages.sh          # Unix
│   ├── run_once_before_10-install-mise.sh          # Unix
│   ├── run_onchange_after_20-mise-install.sh.tmpl  # Unix
│   ├── run_once_after_30-default-shell.sh          # Unix
│   ├── run_once_before_00-windows-packages.ps1     # Windows
│   ├── run_once_before_10-install-mise.ps1         # Windows
│   ├── run_onchange_after_20-mise-install.ps1.tmpl # Windows
│   └── run_once_after_30-powershell-profile.ps1    # Windows
├── dot_zshrc.tmpl                # -> ~/.zshrc            (Unix のみ / WSL 用ブロックあり)
├── dot_tmux.conf                 # -> ~/.tmux.conf        (Unix のみ)
├── dot_claude/settings.json.tmpl # -> ~/.claude/settings.json (tmux フックは Unix のみ)
└── dot_config/
    ├── mise/config.toml.tmpl     # 管理するツールとバージョン (Windows は一部除外)
    ├── powershell/profile.ps1    # -> ~/.config/powershell/profile.ps1 (Windows のみ)
    ├── starship.toml             # プロンプト
    ├── nvim/                     # LazyVim
    ├── jgit/config
    └── wezterm/                  # クライアント側の端末設定
```

`.chezmoiscripts/` 内のスクリプトは実行されるだけで、ホームには配置されない。

### oh-my-zsh の扱い

oh-my-zsh と zsh-autosuggestions はリポジトリに同梱せず、
`.chezmoiexternal.toml.tmpl` で宣言して chezmoi に clone させている
(週 1 回 `git pull` される)。`omz update` もそのまま使える。
Windows ネイティブでは丸ごと出力されないので clone もされない。

### Windows の PowerShell プロファイル

`$PROFILE` の実体 (`Documents\PowerShell\profile.ps1`) は OneDrive に
リダイレクトされることがあり、PowerShell 7 と 5.1 でも場所が違うので、
chezmoi のターゲットパスとしては安定しない。

なので本体は `~/.config/powershell/profile.ps1` に置き、
`run_once_after_30-powershell-profile.ps1` が両方の `$PROFILE` に
「それを dot-source するだけ」のスタブを追記している。
編集するのは常に `chezmoi edit ~/.config/powershell/profile.ps1` のほう。

同じスクリプトがユーザ環境変数 `XDG_CONFIG_HOME` を `~\.config` にしている。
これで neovim が Windows でも `~/.config/nvim` を読み、Unix と設定を共有できる。

### WSL の扱い

`install.sh` と `.chezmoiscripts/` は `/proc/sys/kernel/osrelease` を見て WSL を判定する。
WSL のときだけ変わるのは以下。

- `install.sh`: `command -v` が Windows 側の `git.exe` / `chezmoi.exe` (`/mnt/c/...`) を
  拾わないように除外する
- `run_once_before_00-apt-packages.sh`: `wslu` を追加で入れる (任意扱い、失敗しても続行)
- `dot_zshrc.tmpl`: `pbcopy` / `pbpaste` / `open` / `e` / `winhome` と `WSL_HOST_IP`

それ以外は素の Linux とまったく同じ。
