# Luck Roulette Godot

Status: Godot 4 run shell plus reusable battle slice for the real product direction.

This is the Godot version of the dice, marble, wheel-of-fortune roguelike. The
preferred art direction is a medieval tavern gambling den: bone dice, rune
marbles, a cursed table wheel, coin purses, and dangerous opponents across the
table. The Phaser prototype remains useful as a fast web testbed, but the
product candidate moves here because adjacent successful games in this space
often use Godot.

## Current Scope

- Run shell:
  - Title/start screen.
  - Short table-entry/loading beat before the map.
  - Run clear/fail result screen with `다시 시작` and `메인으로`.
  - Scene transitions use the adopted MIT `EasyTransition` addon through
    `TransitionService`.
- First mini medieval UI skin:
  - Kenney Fantasy UI Borders, CC0, is the current external UI frame source.
  - `AssetCatalog` resolves shared UI frame/divider textures.
  - `UiSkin` applies framed panels/corner marks to title, intro, map, reward,
    event, shop, rest, and run-end screens.
  - This is a replaceable baseline, not final art direction.
- One agency-focused combat encounter surface.
- Phase-based combat:
  - Dice Time
  - Roulette Time
  - Enemy Time
- Maximum three bottom buttons per phase.
- Current default combat actions are intentionally smaller than that cap:
  `굴리기`, `구슬 놓기`, `돌리기`, `방어`, `받기`, and `다음 턴`.
- Dice reroll is handled inside the dice ritual as `다시 굴리기`.
- Roulette respin is handled inside the roulette ritual as `다시 돌리기`.
- Dice rolling now opens as a centered modal tray over the table instead of
  leaving the battle screen completely.
- Marble placement and roulette spin now happen directly on the central table
  roulette instead of opening separate full ritual screens.
- Marble placement is direct: click a roulette slot to place the marble there.
  The visible fallback button is `구슬 놓기`; hidden number keys `1`-`5` also
  place on slots without table labels.
- Monster responses apply inline on the battle table through `방어` / `받기`;
  no separate enemy attack screen opens in the default flow.
- The current combat contract is extension-tested: alternate dice rules,
  boosted roulette slot damage, inline monster pressure, and battle-local
  marble reset behavior are covered by smoke tests.
- Dice values generate this-turn base attack damage through `DiceResolver`.
- The default turn creates one attack marble; relics/modifiers can later alter
  count or type through payload hooks.
- The marble is now a slot modifier token: the player places it on one roulette
  slot, and that slot uses a boosted outcome only if the roulette lands there.
- Base roulette slots are pure combat multipliers:
  `실패 x0`, `명중 x1`, `명중 x1`, `강타 x1.5`, `대박 x2`.
- Placed marbles boost the landed slot:
  `실패 x0 -> x1`, `명중 x1 -> x1.5`, `강타 x1.5 -> x2`,
  `대박 x2 -> x3`.
- `RouletteSlotCatalog` still keeps explicit cash/HP/risk/safety delta fields
  for future relic/monster/event exceptions, but they are not default base slot
  meaning.
- Battle winnings are reward potential; they no longer determine direct damage.
- Enemy HP, player HP, risk, safety, cash, busts, and cash out.
- Code-drawn Godot UI for the tavern table, wheel, dice, marbles, opponent
  intent, result banners, and hit feedback.
- Dice can be locked/rerolled before committing resources.
- Marbles are placed onto roulette plates to boost the chosen slot outcome.
- Roulette gives one last-second intervention: brake, nudge, or double down.
- Presentation feel pass:
  - CC0 Kenney casino audio for dice, marble/chip, wheel tick, coin, and table
    hit feedback.
  - 2.5D bone dice with wobble, shadows, pips, and lock feedback.
  - Marble pickup/drop snap rings and slot pulse feedback.
  - Roulette pointer tick flash while spinning.
  - Tavern opponent portrait reactions for hit, smirk, and table pressure.
  - Coin burst particles when profit converts into opponent pressure.
- Clarity pass:
  - Bottom actions use plain table verbs instead of system labels.
  - A short "지금 할 일" prompt explains the current phase.
  - Roulette outcomes are shown as table plates: 실패, 명중, 명중, 강타, 대박.
  - Marbles are placed onto one roulette slot as setup only.
  - The roulette still spins normally; if it lands on the placed slot, that
    slot uses its boosted result.
  - After placement, the UI highlights `룰렛 돌리기` as the next step before any
    damage resolves.
- Refactor pass 1:
  - The old playable slice was temporarily preserved under `scenes/legacy/` and
    `scripts/legacy/`; those folders were removed during the approved cleanup
    pass after the Godot run-loop became the active prototype.
  - Temporary combat/run state resources were added.
  - Marble, roulette, payout, and enemy intent rules were extracted into
    `scripts/systems/`.
  - Presentation was still hosted by `scripts/main.gd` at this stage; later
    passes moved the battle body into `scripts/battle/battle_scene.gd`.
- Refactor pass 2:
  - Audio loading, SFX bank data, and pooled `AudioStreamPlayer` ownership moved
    into `scripts/systems/audio_bank.gd`.
  - `main.gd` now treats audio as a service and only sends named SFX requests.
  - Presentation smoke verifies audio through the `AudioBank` public API instead
    of reading `main.gd` internals.
  - The label overlay and bottom action bar moved into
    `scripts/ui/prompt_layer.gd`.
  - `main.gd` still decides which labels/buttons to show, but `PromptLayer` now
    owns their nodes and styling.
- Refactor pass 3:
  - The persistent top strip and player run/combat resource readout moved into
    `scripts/ui/run_hud.gd`.
  - The opponent portrait, intent text, enemy HP readout, hit/smirk/press
    reactions, and player damage flash moved into
    `scripts/ui/opponent_layer.gd`.
  - `main.gd` updates visual layers with state snapshots while keeping combat
    rules and table input in one place for now.
- Refactor pass 4:
  - Table/backdrop/panel/roulette/drop-slot/coin-particle drawing moved into
    `scripts/ui/table_layer.gd`.
  - Dice, hand pouch, held/stored marbles, thrown marble arcs, marble feedback,
    and throw-preview drawing moved into `scripts/ui/hand_layer.gd`.
  - The result banner moved into `PromptLayer` so it renders above gameplay
    layers.
  - `main.gd` now draws only the base background and coordinates state, input,
    rules, and layer snapshots.
- Cinematic camera pass:
  - Phantom Camera v0.9.3.1 was vendored into `addons/phantom_camera/` as the
    first external camera wheel candidate.
  - Direct plugin enablement is deferred because headless runtime validation
    exposed addon class registration order issues when its autoload is enabled
    outside the editor.
  - Added `scripts/camera/combat_camera_rig.gd`, a small `Camera2D` beat
    adapter using the same named camera beat model planned for Phantom Camera.
  - Split scene ownership into camera-affected `WorldRoot` and fixed
    `HudCanvas`.
  - Current beats: `dice_hand`, `marble_pouch`, `wheel_close`,
    `opponent_intent`, `result_hit`, and `wide_table`.
- Cinematic playtest:
  - `scripts/tests/playtest_cinematic_flow.gd` runs the dice, pouch, marble
    throw, wheel spin, intervention, and opponent reaction flow through actual
    pointer input.
  - The rendered screenshot set is stored under
    `../../runs/2026-05-09T113000p0900-cinematic-playtest/screens/`.
  - Functional result: pass.
  - Presentation feel result: fail for now. Prompt/banner overlap and crowded
    camera compositions must be fixed before adding deeper rules.
- Ritual scene spike:
  - Adopted MIT `EasyTransition` into `addons/easytransition/` and wrapped it
    with `scripts/systems/transition_service.gd`.
  - Added `scripts/systems/ritual_director.gd` to mount cinematic beat scenes
    and return explicit result payloads.
  - The old dedicated dice/marble/roulette ritual windows were later removed;
    those steps now resolve directly on the combat table.
  - Local MIT `Dice_Roll` was tested after import and kept as a reference, not
    adopted, because it is a d10/Jolt-style physics demo rather than the needed
    reusable d6 tray.
- Run/battle split:
  - Project entrypoint is now `scenes/run/run_root.tscn`.
  - `RunRoot` now routes title -> intro -> map -> run -> run end -> restart or
    title.
  - Battle/combat lives at `scenes/battle/battle_scene.tscn` with script
    `scripts/battle/battle_scene.gd`.
  - `scenes/main.tscn` and `scripts/main.gd` remain compatibility aliases only.
  - Battle-specific smoke/playtests load `BattleScene` directly.
  - Run-flow smoke/playtests load `RunRoot`.
- Run/effect package:
  - `scripts/systems/relic_catalog.gd` owns starter relic IDs.
  - `scripts/systems/effect_resolver.gd` builds encounter payloads and applies
    relic/next-combat modifiers.
  - `scenes/run/event_scene.tscn`, `shop_scene.tscn`, and `rest_scene.tscn`
    are minimal payload-driven run nodes.
  - `RunState.next_combat_mods` stores one-shot preparation effects until the
    next encounter payload consumes them.
- Asset identity foundation:
  - External first-pass visual assets live under `assets/external/`.
  - `scripts/systems/asset_catalog.gd` maps monster IDs, node types, and props
    to imported textures.
  - `scripts/ui/ui_skin.gd` provides the first shared fantasy-table button/panel
    styling.
  - Map nodes, battle opponent token, dice/pouch/roulette props, and run-node
    screens now use the catalog/skin glue.
- UX composition pass:
  - Table context states keep the wide camera; focused zoom belongs to ritual
    scenes.
  - The opponent panel owns enemy name, HP, intent, expected damage, and
    portrait token.
  - The battle HUD foregrounds player HP, reward potential, and run gold.
  - Roulette table labels are quieter and centered on multiplier meaning.
- Table-stage pass:
  - The battle view is staged as a tabletop scene rather than three UI panels.
  - Roulette is the central table object, with dice and pouch as smaller player
    edge props.
  - Dice focus is now a modal tray over the table.
  - Marble placement and roulette spin now stay inline on the table roulette.
  - Roulette is the central table object.
  - Opponent, dice, and pouch are table props around that object.
  - The HUD remains a thin `CanvasLayer` overlay.

## Run

Install Godot 4, then open this folder:

```text
game/luck-roulette-godot/
```

Run the project main scene:

```text
res://scenes/run/run_root.tscn
```

Run battle-only scene for combat debugging:

```text
res://scenes/battle/battle_scene.tscn
```

CLI, if Godot is on PATH:

```powershell
godot --path game/luck-roulette-godot
```

Local helper scripts:

```powershell
.\open-editor.ps1
.\run-game.ps1
.\run-game.ps1 my-seed
```

Seeded CLI:

```powershell
godot --path game/luck-roulette-godot -- --seed=godot-smoke-2026-05-09
```

Headless validation:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --quit
```

Presentation smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/smoke_presentation.gd
```

Prompt button smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_prompt_buttons.gd
```

Combat rules smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_combat_rules.gd
```

Combat extension contract smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_combat_extension_contract.gd
```

Rendered cinematic playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_cinematic_flow.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T113000p0900-cinematic-playtest\screens"
```

Ritual flow smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_ritual_flow.gd
```

Rendered ritual scene playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_ritual_scene_flow.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T120515p0900-ritual-scene-wheel-spike\screens"
```

Rendered full ritual flow playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_full_ritual_flow.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T122833p0900-full-ritual-flow\screenshots"
```

Run flow smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_run_flow.gd
```

Effect resolver smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_effect_resolver.gd
```

Pressure simulation smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_pressure_simulation.gd
```

Feedback mapper smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_feedback_mapper.gd
```

Resource contract smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_resource_contract.gd
```

Encounter catalog smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_encounter_catalog.gd
```

Monster move contract smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_monster_move_contract.gd
```

Asset catalog smoke:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/smoke_asset_catalog.gd
```

Rendered end-to-end structure playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_end_to_end_structure.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-10T032100+0900-mini-medieval-ui-skin\screenshots\end_to_end"
```

Rendered trigger feedback playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_trigger_feedback.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T155636p0900-trigger-feedback-wheel\screenshots\trigger_feedback"
```

Rendered run-fail resource playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_run_fail_resource.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T162225p0900-survival-resource-clarity\screenshots\run_fail"
```

Rendered monster move contract playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_monster_move_contract.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T163000p0900-monster-move-contract\screenshots\monster_move"
```

Rendered closed-run playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_closed_run_loop.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-10T032100+0900-mini-medieval-ui-skin\screenshots\closed_run"
```

Rendered asset identity playtest:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe" --path . --script res://scripts/tests/playtest_asset_identity.gd -- --shot-dir="C:\dev\front-template\make newthing\goal_Test\runs\2026-05-09T205338p0900-asset-identity-foundation\screenshots"
```

## Why Godot

- Similar 2D roguelike deckbuilder/gambling games use Godot.
- UI-heavy 2D game state is easier to inspect in the editor.
- Scenes/resources make later map, encounter, shop, event, and relic modules
  easier to author visually.
- Open-source engine avoids licensing risk.

## External Wheel Notes

Inspected wheels are stored under:

```text
vendor/external-wheels/
```

Current decisions:

- `Dice_Roll`: held for later because the 3D/Jolt-style setup is heavy for this
  2D combat slice.
- `Spin Wheel`: partially adopted as a spin/tween/reward-angle pattern.
- `SwiftInv`: inspected as drag/drop slot reference, not imported wholesale.
- Godot's built-in input and tween APIs are the current lightweight integration
  layer.

## Next Step

The next phase can move into UI/UX and presentation now that the first run loop
is structurally closed and the app/run shell has title, intro, and result
return paths.

1. Research UI/UX references and Godot presentation wheels before building.
2. Improve battle table hierarchy and opponent intent readability.
3. Improve map/run shell readability.
4. Improve dice, marble throw, roulette, and resolution ritual presentation.
5. Improve reward/shop/rest/event/run-clear placeholders.
6. Keep `EncounterCatalog`, `EffectResolver`, `MonsterCatalog`, and
   `MonsterMoveCatalog` stable unless UI work exposes a real structural gap.

See also:

```text
../../docs/luck-roulette-current-state-and-next-steps-2026-05-09.md
../../docs/handoff.md
```
