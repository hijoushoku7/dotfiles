# PowerShell プロファイル本体 (Windows ネイティブ用 / ~/.zshrc に相当)
#
# $PROFILE そのものではなく ~/.config/powershell/profile.ps1 に置いている。
# Documents\ は OneDrive にリダイレクトされることがあり、PowerShell 7 と
# Windows PowerShell 5.1 でも場所が違うため、chezmoi 側で場所が安定する
# ここに実体を置き、$PROFILE には dot-source するだけのスタブを
# .chezmoiscripts/run_once_after_30-powershell-profile.ps1 が書き込む。

# ---------------------------------------------------------------------------
# PATH / 環境変数
# ---------------------------------------------------------------------------
$localBin = Join-Path $HOME '.local\bin'
if (Test-Path $localBin -PathType Container -ErrorAction SilentlyContinue) {
    if ($env:PATH -notlike "*$localBin*") {
        $env:PATH = "$localBin;$env:PATH"
    }
}

# nvim / starship などの設定を ~/.config に寄せる (Unix 側と共有するため)
if (-not $env:XDG_CONFIG_HOME) {
    $env:XDG_CONFIG_HOME = Join-Path $HOME '.config'
}
$env:EDITOR = 'nvim'

# ---------------------------------------------------------------------------
# ツールの有効化
# ---------------------------------------------------------------------------
function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

if (Test-Command mise) {
    mise activate pwsh | Out-String | Invoke-Expression
}

if (Test-Command starship) {
    starship init powershell | Out-String | Invoke-Expression
}

# ---------------------------------------------------------------------------
# PSReadLine (zsh-autosuggestions / Ctrl-R 相当)
# ---------------------------------------------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineOption -EditMode Windows

    if (Test-Command fzf) {
        # Ctrl-R: 履歴を fzf で選ぶ (zsh の fzf-select-history 相当)
        Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
            $historyPath = (Get-PSReadLineOption).HistorySavePath
            if (-not (Test-Path $historyPath)) { return }
            $history = [System.Collections.ArrayList]@(Get-Content $historyPath)
            $history.Reverse()   # 新しいものを先頭に
            $selection = $history | Select-Object -Unique | fzf --reverse
            if ($selection) {
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
            }
        }
    }
}

# ---------------------------------------------------------------------------
# alias / 関数
#   PowerShell の Set-Alias は引数を渡せないので、引数が要るものは関数で定義する。
# ---------------------------------------------------------------------------
if (Test-Command eza) {
    function ls { eza --icons --group-directories-first @args }
    function la { eza -a --icons --group-directories-first @args }
    function ll { eza -la --icons --group-directories-first --git @args }
    function lt { eza --tree --level=2 --icons @args }
} else {
    function la { Get-ChildItem -Force @args }
    function ll { Get-ChildItem -Force @args | Format-Table -AutoSize }
}

if (Test-Command bat) {
    function cat { bat @args }
}

# tools
Set-Alias cm  chezmoi
Set-Alias cdx codex
Set-Alias cld claude
Set-Alias lg  lazygit
Set-Alias vi  nvim
Set-Alias vim nvim

# WSL のシェルへ入る
function wsl-zsh { wsl.exe -- zsh -l @args }

Remove-Item Function:\Test-Command
