$godot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"

if (!(Test-Path $godot)) {
  Write-Error "Godot executable not found at $godot"
  exit 1
}

& $godot --path $PSScriptRoot
