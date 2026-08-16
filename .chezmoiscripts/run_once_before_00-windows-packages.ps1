# Windows ネイティブ環境で winget から入れておきたい最低限のもの。
# (run_once_before_00-apt-packages.sh の Windows 版)
#
# 言語ランタイムと CLI ツールは mise 側 (~/.config/mise/config.toml) が管理するので、
# ここには「mise で扱わないもの」だけを書く。

$ErrorActionPreference = 'Stop'
# ネイティブコマンドの非 0 終了で例外を投げさせない ($LASTEXITCODE で自前判定する)
$PSNativeCommandUseErrorActionPreference = $false

function Write-Log($msg)  { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host "警告: $msg" -ForegroundColor Yellow }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warn 'winget が見つかりません。パッケージのインストールをスキップします。'
    Write-Warn 'Microsoft Store から「アプリ インストーラー」を入れてから chezmoi apply を再実行してください。'
    exit 0
}

# id = winget のパッケージ ID / probe = 既に入っているか判定するコマンド名
$packages = @(
    @{ id = 'Git.Git';               probe = 'git' },
    @{ id = 'Microsoft.PowerShell';  probe = 'pwsh' },   # PowerShell 7 (5.1 のままだと辛い)
    @{ id = 'wez.wezterm';           probe = 'wezterm' }
)

foreach ($pkg in $packages) {
    if (Get-Command $pkg.probe -ErrorAction SilentlyContinue) {
        continue
    }
    Write-Log "winget install $($pkg.id)"
    # winget は「既にインストール済み」などでも非 0 を返すので失敗させない
    winget install --id $pkg.id --exact --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "$($pkg.id) のインストールに失敗しました (exit $LASTEXITCODE)。手動で入れてください。"
    }
}

Write-Log 'Windows パッケージの確認が完了しました'
