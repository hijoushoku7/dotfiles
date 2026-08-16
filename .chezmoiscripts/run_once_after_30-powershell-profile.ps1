# $PROFILE に「~/.config/powershell/profile.ps1 を読むだけ」のスタブを置く。
# (Unix 側の run_once_after_30-default-shell.sh に対応する位置づけ)
#
# なぜスタブなのか:
#   - $PROFILE の実体は Documents\PowerShell\... で、OneDrive にリダイレクト
#     されていることがあるため chezmoi のターゲットパスとして固定できない
#   - PowerShell 7 (Documents\PowerShell) と Windows PowerShell 5.1
#     (Documents\WindowsPowerShell) で場所が違う
# なので実体は ~/.config/powershell/profile.ps1 (chezmoi 管理) に置き、
# 両方の $PROFILE から dot-source する。

$ErrorActionPreference = 'Stop'

function Write-Log($msg)  { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host "警告: $msg" -ForegroundColor Yellow }

$target = Join-Path $HOME '.config\powershell\profile.ps1'
$marker = '# >>> dotfiles: chezmoi managed profile >>>'
$stub   = @"
$marker
# 実体は chezmoi 管理下の ~/.config/powershell/profile.ps1。
# ここは編集しないこと (編集は ``chezmoi edit ~/.config/powershell/profile.ps1``)。
`$dotfilesProfile = Join-Path `$HOME '.config\powershell\profile.ps1'
if (Test-Path `$dotfilesProfile) { . `$dotfilesProfile }
# <<< dotfiles: chezmoi managed profile <<<
"@

if (-not (Test-Path $target)) {
    Write-Warn "$target がまだありません。chezmoi apply のあとに再実行してください。"
    exit 0
}

# CurrentUserAllHosts = profile.ps1 (ホスト非依存)。
# 5.1 と 7 の両方に置きたいので、両方のパスを自前で組み立てる。
$docs = [Environment]::GetFolderPath('MyDocuments')
$profilePaths = @(
    (Join-Path $docs 'PowerShell\profile.ps1'),          # PowerShell 7+
    (Join-Path $docs 'WindowsPowerShell\profile.ps1')    # Windows PowerShell 5.1
) | Select-Object -Unique

foreach ($p in $profilePaths) {
    $dir = Split-Path $p -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    if ((Test-Path $p) -and (Select-String -Path $p -SimpleMatch $marker -Quiet)) {
        Write-Log "設定済みです: $p"
        continue
    }

    Write-Log "プロファイルスタブを追記します: $p"
    Add-Content -Path $p -Value "`r`n$stub" -Encoding UTF8
}

# ---------------------------------------------------------------------------
# XDG_CONFIG_HOME
# ---------------------------------------------------------------------------
# neovim は Windows では既定で %LOCALAPPDATA%\nvim を見るが、
# この dotfiles では Unix と設定を共有したいので ~/.config を使わせる。
# プロファイルでも設定しているが、エクスプローラから起動した nvim や
# 他のシェルからも効くようにユーザ環境変数として永続化しておく。
$xdg = Join-Path $HOME '.config'
if ([Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME', 'User') -ne $xdg) {
    Write-Log "ユーザ環境変数 XDG_CONFIG_HOME を $xdg にします"
    [Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $xdg, 'User')
}

Write-Log '新しい PowerShell を開くと設定が読み込まれます'
