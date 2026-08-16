# mise 本体をインストールする (run_once_before_10-install-mise.sh の Windows 版)。
# ツールの中身 (node/go/gh/...) は ~/.config/mise/config.toml が配置されたあとに
# run_onchange_after_20-mise-install.ps1 がインストールする。

$ErrorActionPreference = 'Stop'
# ネイティブコマンドの非 0 終了で例外を投げさせない ($LASTEXITCODE で自前判定する)
$PSNativeCommandUseErrorActionPreference = $false

function Write-Log($msg)  { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host "警告: $msg" -ForegroundColor Yellow }

$binDir = Join-Path $HOME '.local\bin'

if ((Get-Command mise -ErrorAction SilentlyContinue) -or
    (Test-Path (Join-Path $binDir 'mise.exe'))) {
    Write-Log 'mise は導入済みです'
    exit 0
}

# 1. winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Log 'mise をインストールします (winget)'
    winget install --id jdx.mise --exact --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { exit 0 }
    Write-Warn "winget での導入に失敗しました (exit $LASTEXITCODE)。別の方法を試します。"
}

# 2. scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Log 'mise をインストールします (scoop)'
    scoop install mise
    if ($LASTEXITCODE -eq 0) { exit 0 }
    Write-Warn "scoop での導入に失敗しました (exit $LASTEXITCODE)。別の方法を試します。"
}

# 3. 公式配布の単体 exe を ~/.local/bin へ
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
$url  = "https://mise.jdx.dev/mise-latest-windows-$arch.exe"
$dest = Join-Path $binDir 'mise.exe'

Write-Log "mise をダウンロードします -> $dest"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
try {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
} catch {
    Write-Warn "mise のダウンロードに失敗しました: $($_.Exception.Message)"
    Write-Warn 'https://mise.jdx.dev/installing-mise.html を見て手動で入れてください。'
    exit 0   # ここで apply 全体を止めない
}

# chezmoi はスクリプトごとに別プロセスなので $env:PATH は引き継がれない。
# 後続の run_onchange_after_20-mise-install.ps1 は自前で ~/.local/bin を見る。
# 対話シェルからは ~/.config/powershell/profile.ps1 が PATH に足している。
Write-Log 'mise を導入しました'
