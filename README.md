# dotfiles

hijoushoku 専用の dotfiles。[chezmoi](https://www.chezmoi.io/) で管理し、
言語ランタイムと CLI ツールは [mise](https://mise.jdx.dev/) に任せている。

対象環境は 3 つ。**環境構築までやるのは Unix 側だけ**で、Windows ネイティブは
設定ファイルを配るだけに徹する。

| 環境 | ブートストラップ | シェル | パッケージ | 役割 |
|---|---|---|---|---|
| Linux (Ubuntu / Debian) | `install.sh` | zsh + oh-my-zsh | apt + mise | 環境構築まで |
| WSL (Ubuntu) | `install.sh` | zsh + oh-my-zsh | apt + mise | 環境構築まで |
| Windows ネイティブ | 手動 (`chezmoi init`) | 触らない | 触らない | 設定配布のみ |

WSL は「Linux として」セットアップし、Windows 側と行き来するための差分だけを足す。
Windows ネイティブと WSL を両方使う場合は **両方走らせる** (それぞれ別のホームなので衝突しない)。

Windows で実際に使うのは WSL の中なので、Windows ネイティブ側で chezmoi に
やらせたいのは **WSL の外に置かざるを得ない設定** だけ、具体的には wezterm・
VS Code・`~/.config` 配下。シェルやパッケージ管理まで二重に面倒を見る価値が
無いので、スクリプト (`*.ps1`) は一切置いていない。

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

自動化していない。chezmoi を入れて init するだけ。

```powershell
winget install twpayne.chezmoi
chezmoi init --apply hijoushoku7/dotfiles
```

`winget` が無い場合は Microsoft Store から「アプリ インストーラー」を入れておく。
`chezmoi` が PATH に乗らない場合は PowerShell を開き直す。

wezterm 本体もここには含まれないので、必要なら別途入れる
(`winget install wez.wezterm`)。

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

`chezmoi apply` が設定ファイルを配置する。それだけ。スクリプトは走らない。

| 配置されるもの | 用途 |
|---|---|
| `~/.config/wezterm/` | 端末 (WSL に入る入口なので Windows 側に要る) |
| `~/.config/` のその他 (`nvim` `starship.toml` `jgit` `mise`) | Unix と共有 |
| `~/.vscode/extensions/extensions.json` | VS Code の拡張一覧 |
| `~/.claude/settings.json` | Claude Code (tmux フックは Unix だけ) |

zsh / tmux / oh-my-zsh / `.chezmoiscripts/` は `.chezmoiignore` で丸ごと落としている。
PowerShell のプロファイル、mise、winget によるパッケージ導入には**一切関与しない**。

`install.sh` は chezmoi を動かすための最小限しかやらない。
残りは全て `.chezmoiscripts/` に置いてあるので、**既存マシンで `chezmoi update` しても同じ処理が走る**。
セットアップ手順が新規／既存で二重管理にならないようにしている。

`.chezmoiscripts/` に入っているのは `*.sh` だけで、Windows では
`.chezmoiignore` がディレクトリごと除外する。そのため chezmoi の
`[interpreters]` 設定は要らない。

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
├── .chezmoi.toml.tmpl            # chezmoi 自身の設定
├── .chezmoiignore                # ホームに配置しないもの (OS で分岐)
├── .chezmoiexternal.toml.tmpl    # oh-my-zsh / zsh-autosuggestions の取得先 (Unix のみ)
├── .chezmoiscripts/              # apply 時に自動実行されるスクリプト (Unix のみ)
│   ├── run_once_before_00-apt-packages.sh
│   ├── run_once_before_10-install-mise.sh
│   ├── run_onchange_after_20-mise-install.sh.tmpl
│   └── run_once_after_30-default-shell.sh
├── dot_zshrc.tmpl                # -> ~/.zshrc            (Unix のみ / WSL 用ブロックあり)
├── dot_tmux.conf                 # -> ~/.tmux.conf        (Unix のみ)
├── dot_claude/settings.json.tmpl # -> ~/.claude/settings.json (tmux フックは Unix のみ)
├── dot_vscode/                   # -> ~/.vscode/          (拡張一覧)
└── dot_config/
    ├── mise/config.toml.tmpl     # 管理するツールとバージョン (Windows は一部除外)
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

### Windows で管理しないもの

PowerShell のプロファイル、mise、winget によるパッケージ導入は
**意図的に管理していない**。作業は WSL の中でやるので、Windows ネイティブ側の
シェル環境を整えても使われず、`$PROFILE` の場所が OneDrive にリダイレクト
されるといった Windows 固有の面倒を抱え込むだけだった。

副作用として、ユーザ環境変数 `XDG_CONFIG_HOME` も設定されない。
Windows ネイティブの neovim は既定の `%LOCALAPPDATA%\nvim` を見るので、
`~/.config/nvim` は読まれない (Windows で nvim を使わない前提)。

### WSL の扱い

`install.sh` と `.chezmoiscripts/` は `/proc/sys/kernel/osrelease` を見て WSL を判定する。
WSL のときだけ変わるのは以下。

- `install.sh`: `command -v` が Windows 側の `git.exe` / `chezmoi.exe` (`/mnt/c/...`) を
  拾わないように除外する
- `run_once_before_00-apt-packages.sh`: `wslu` を追加で入れる (任意扱い、失敗しても続行)
- `dot_zshrc.tmpl`: `pbcopy` / `pbpaste` / `open` / `e` / `winhome` と `WSL_HOST_IP`

それ以外は素の Linux とまったく同じ。
