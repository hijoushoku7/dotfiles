# dotfiles bootstrap script (Windows ネイティブ / PowerShell 用)
#
#   irm https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.ps1 | iex
#
# WSL / Linux 側は install.sh を使うこと (WSL の中で叩くのは install.sh)。
#
# ここでやるのは chezmoi を動かすための最小限だけ。
#   1. git を入れる (winget)
#   2. chezmoi を ~/.local/bin に入れる
#   3. chezmoi init --apply でリポジトリを展開する
#
# mise / PowerShell プロファイル / ツール類は、展開後に
# .chezmoiscripts/ 配下の *.ps1 が自動で実行する。
# こうしておくと既存マシンで `chezmoi update` しても同じ処理が走る。

$ErrorActionPreference = 'Stop'
# ネイティブコマンドの非 0 終了で例外を投げさせない ($LASTEXITCODE で自前判定する)
$PSNativeCommandUseErrorActionPreference = $false

$Repo   = 'hijoushoku7/dotfiles'
$BinDir = Join-Path $HOME '.local\bin'

function Write-Log($msg)  { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host "警告: $msg" -ForegroundColor Yellow }
function Die($msg) { Write-Host "Error: $msg" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 0. 実行環境の確認
# ---------------------------------------------------------------------------

# WSL の中から間違って叩いたとき用のガード
if ($IsLinux -or $IsMacOS) {
    Die 'これは Windows 用です。WSL / Linux では install.sh を使ってください。'
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Die "PowerShell 5.1 以上が必要です (現在 $($PSVersionTable.PSVersion))"
}

# TLS 1.2 を明示 (Windows PowerShell 5.1 の既定が古いことがある)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---------------------------------------------------------------------------
# 1. 前提コマンド
# ---------------------------------------------------------------------------

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Die 'git も winget もありません。git を手動で入れてから再実行してください: https://git-scm.com/download/win'
    }
    Write-Log 'git をインストールします (winget)'
    winget install --id Git.Git --exact --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Die "git のインストールに失敗しました (exit $LASTEXITCODE)"
    }
    # winget が入れた git を同一セッションから見えるようにする
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('PATH', 'User')
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Die 'git を入れましたが PATH から見えません。PowerShell を開き直して再実行してください。'
    }
}

# ---------------------------------------------------------------------------
# 2. chezmoi
# ---------------------------------------------------------------------------

$chezmoi = $null
$cmd = Get-Command chezmoi -ErrorAction SilentlyContinue
if ($cmd) {
    $chezmoi = $cmd.Source
} elseif (Test-Path (Join-Path $BinDir 'chezmoi.exe')) {
    $chezmoi = Join-Path $BinDir 'chezmoi.exe'
} else {
    Write-Log "chezmoi をインストールします -> $BinDir"
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    # 公式インストーラ: https://www.chezmoi.io/install/
    iex "&{$(irm 'https://get.chezmoi.io/ps1')} -b '$BinDir'"
    $chezmoi = Join-Path $BinDir 'chezmoi.exe'
}

if (-not (Test-Path $chezmoi) -and -not (Get-Command $chezmoi -ErrorAction SilentlyContinue)) {
    Die "chezmoi が見つかりません: $chezmoi"
}
Write-Log "chezmoi: $chezmoi"

# ~/.local/bin を今後の PowerShell からも見えるようにユーザ PATH に足す
# (~/.config/powershell/profile.ps1 でも足しているが、素の powershell.exe 用)
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
if ($userPath -notlike "*$BinDir*") {
    Write-Log "ユーザ PATH に $BinDir を追加します"
    [Environment]::SetEnvironmentVariable('PATH', "$BinDir;$userPath", 'User')
}
if ($env:PATH -notlike "*$BinDir*") {
    $env:PATH = "$BinDir;$env:PATH"
}

# ---------------------------------------------------------------------------
# 3. 展開
# ---------------------------------------------------------------------------

Write-Log "dotfiles を展開します: $Repo"
& $chezmoi init --apply $Repo
if ($LASTEXITCODE -ne 0) {
    Die "chezmoi init --apply が失敗しました (exit $LASTEXITCODE)"
}

Write-Host @'

==> セットアップが完了しました。

    PowerShell を開き直すと ~/.config/powershell/profile.ps1 が読み込まれます。

    WSL 側も揃えたい場合は WSL の中で:

        sh -c "$(curl -fsLS https://raw.githubusercontent.com/hijoushoku7/dotfiles/main/install.sh)"

    残りの手動作業は README の「セットアップ後にやること」を参照してください。

'@
