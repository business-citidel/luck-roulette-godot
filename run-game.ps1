$godot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"
$seed = if ($args.Count -gt 0) { $args[0] } else { "godot-smoke-2026-05-09" }

if (!(Test-Path $godot)) {
  Write-Error "Godot executable not found at $godot"
  exit 1
}

& $godot --path $PSScriptRoot -- --seed=$seed
