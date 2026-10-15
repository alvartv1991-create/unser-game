$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$godotPath = 'C:\Users\marco\Desktop\Random Thing\.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godotPath)) {
    throw 'Godot executable not found. Update $godotPath from AGENTS.md.'
}
& $godotPath --path $projectPath
