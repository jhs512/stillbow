$godotPath = Join-Path $env:LOCALAPPDATA 'CodexGameTools\Godot_v4.5.1-stable_win64.exe'
if (!(Test-Path -LiteralPath $godotPath)) {
    Write-Error 'Godot 4.5.1 is required. Import project.godot in Godot and press F6.'
    exit 1
}
Start-Process -FilePath $godotPath -ArgumentList @('--path', ('"' + $PSScriptRoot + '"')) -WindowStyle Hidden
