# Marble System Handoff - 2026-06-01

Status: B-slice implemented and verified  
Scope: understand the current Godot core, compare it with the new marble design, implement the first playable numeric marble choice slice, and leave a next-session handoff.

## Source Design

Planning folder:

```text
C:\dev\front-template\make newthing\goal_Test\assets\curated\luck-roulette-current\sprints\luck-roulette-visual-system-001\02-combat-table-system\002-dice-and-marbles-system
```

Key design files:

```text
README.md
MARBLE_DECK_RULES.md
MARBLE_TYPES.md
MARBLE_UIUX.md
MARBLE_DECK_DESIGN.md
MARBLE_ENEMY_INTERACTIONS.md
ASSET_REUSE_MANIFEST.md
NEXT_DESIGN_TASKS.md
```

The new marble design is not just an art replacement. It changes the combat middle step from generic wager counters into a small deck/bag choice system:

```text
dice result -> reveal up to 3 marbles -> choose exactly 1 marble -> roulette result -> resolve combat
```

## Team Review Summary

This handoff was reviewed from three angles before writing:

```text
Core code review: current run, battle, dice, roulette, and marble dependencies.
Design source review: marble deck rules, marble type set, UI/UX assets, runtime intent.
Verification review: Godot execution path and smoke tests to use before/after changes.
```

Consensus:

```text
The safe implementation path is to add a new marble deck state/model first,
then route numeric_roulette through a marble selection phase,
then apply the selected marble to numeric roulette resolution.

Do not start by rewriting legacy slot placement.
Do not treat the new 9 marble images as color replacements for the old plain/yellow/green/curse tokens.
```

## Current Game Core

Project entry:

```text
project.godot
run/main_scene="res://scenes/run/run_root.tscn"
```

Run shell:

```text
scripts/run/run_root.gd
```

Combat entry path:

```text
RunRoot._open_combat()
EffectResolver.build_encounter_payload()
BattleScene.configure_encounter()
await BattleScene.combat_finished
```

Main combat scene:

```text
scenes/battle/battle_scene.tscn
scripts/battle/battle_scene.gd
```

Current default combat core:

```gdscript
var combat_core: String = "numeric_roulette"
```

Current high-level combat flow:

```text
dice -> wager -> spinning -> intervene -> resolution -> enemy turn or combat finish
```

Legacy flow still exists:

```text
dice -> marble placement on roulette slot -> spinning -> resolution
```

The next marble rework should target the current numeric flow first.

## Current Marble Meaning

Important current behavior:

```text
scripts/systems/marble_resolver.gd
```

`MarbleResolver` is intentionally minimal right now:

```gdscript
neutral_token() -> "plain"
token_from_die(_value) -> "plain"
color_from_die(value) -> "plain"
```

In `scripts/battle/battle_scene.gd`, dice confirmation calls `_take_marbles()`.

Current `_take_marbles()` creates:

```gdscript
{
  "attack_base": attack_base,
  "marble_count": 1,
  "marbles": ["plain"],
  ...
}
```

Then relics can mutate that payload through:

```text
scripts/battle/battle_relic_payload_bridge.gd
EffectResolver.apply_relic_trigger("marble_gain", ...)
```

For `numeric_roulette`, `_take_marbles()` does not enter a marble choice step. It calls:

```gdscript
_enter_wager_phase(max(1, int(payload.get("marble_count", 1))))
```

Numeric marble state is currently canonical here:

```text
wager_marbles_available
wager_marbles_committed
```

The `marbles` array is mostly visual loose-marble display in numeric mode:

```gdscript
_sync_wager_marbles_visual()
```

This distinction matters. New typed marbles should not be squeezed into `wager_marbles_available` as plain counters without a state layer.

## Current Numeric Roulette Core

Numeric resolver:

```text
scripts/systems/numeric_roulette_resolver.gd
```

Default wheel:

```gdscript
[0.0, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 1.5, 1.5, 3.0]
```

Current wager multiplier:

```gdscript
wager_multiplier(committed_marbles) = 1.0 + committed * 0.25
```

clamped to 4 committed marbles.

Numeric flow:

```text
scripts/battle/battle_numeric_roulette_flow.gd
```

Resolution currently computes:

```text
damage = attack_base * roulette_multiplier * wager_multiplier
```

after run upgrades, relic hooks, jackpot bonus, curse multiplier, and enemy block.

The new selected marble should probably be applied in this layer as a `selected_marble` modifier, not as a legacy `placed_slots` boost.

## New Marble Design Target

Starting deck size:

```text
9
```

Allowed deck size:

```text
min 1
max 12
```

Canonical marble type order:

```text
plain
heavy
leech
guard
pierce
gamble
stable
poison
cracked
```

Prototype starting deck:

```text
plain
plain
plain
heavy
leech
guard
pierce
gamble
cracked
```

Runtime zones required by design:

```text
all_marbles
bag
discard
sealed
removed
temporary
```

Minimum persistent data per marble:

```text
instance_id
marble_id
is_temporary
source
```

Turn rule:

```text
draw_count = min(3, current_bag_count)
reveal draw_count marbles
player chooses exactly 1
all revealed marbles move to discard
reshuffle discard into bag only when bag empties
```

Visual rule:

```text
All marbles share an ivory base.
Type identity comes from the sigil.
Do not recolor the whole marble by type.
```

## New Assets

Finished marble images:

```text
marble-sigil-set-001/marbles/marble_plain_001.png
marble-sigil-set-001/marbles/marble_heavy_001.png
marble-sigil-set-001/marbles/marble_leech_001.png
marble-sigil-set-001/marbles/marble_guard_001.png
marble-sigil-set-001/marbles/marble_pierce_001.png
marble-sigil-set-001/marbles/marble_gamble_001.png
marble-sigil-set-001/marbles/marble_stable_001.png
marble-sigil-set-001/marbles/marble_poison_001.png
marble-sigil-set-001/marbles/marble_cracked_001.png
```

Runtime UI candidates:

```text
runtime-candidates/marble_choice_tray_empty_candidate.png
runtime-candidates/marble_bag_overlay_board_empty_candidate.png
runtime-candidates/marble_quick_view_slot_empty_candidate.png
```

Existing Godot runtime marble assets are older:

```text
assets/runtime/combat/marbles/marble_plain.png
assets/runtime/combat/marbles/marble_star.png
assets/runtime/combat/marbles/marble_guard.png
assets/runtime/combat/marbles/marble_skull.png
```

Existing asset catalog currently maps:

```text
marble_plain
marble_yellow
marble_green
marble_curse
```

This needs a new 9-type mapping before UI work can be clean.

## Recommended Implementation Plan

### 1. Add Marble Catalog and State Model

Create a typed marble model before touching battle UI.

Suggested files:

```text
scripts/systems/marble_catalog.gd
scripts/resources/marble_deck_state.gd
```

Responsibilities:

```text
Define the 9 marble IDs, names, roles, effect text, and asset keys.
Create the prototype starting deck with duplicate-safe instance IDs.
Track all_marbles, bag, discard, sealed, removed, temporary.
Reveal up to 3 marbles.
Choose 1 revealed marble.
Move revealed marbles to discard.
Reshuffle only when bag empties.
Serialize/deserialize for run save later.
```

Keep `scripts/systems/marble_resolver.gd` compatibility initially. Existing tests expect `token_from_die()` to return `"plain"`.

### 2. Add Asset Catalog Entries

Import/copy the 9 new marble PNGs into a stable Godot runtime path, likely:

```text
assets/runtime/combat/marbles/v2/
```

Then add `AssetCatalog` keys:

```text
marble_plain_v2
marble_heavy
marble_leech
marble_guard_v2
marble_pierce
marble_gamble
marble_stable
marble_poison
marble_cracked
marble_choice_tray
marble_bag_overlay_board
marble_quick_view_slot
```

Keep old keys until legacy placement tests are intentionally retired.

### 3. Insert a Marble Selection Phase After Dice

Current path:

```text
_confirm_dice_result() -> _take_marbles() -> _enter_wager_phase()
```

Target first-pass path:

```text
_confirm_dice_result()
_take_marbles()
_enter_marble_choice_phase(revealed_marbles)
player selects one
_enter_wager_phase_or_spin_with_selected_marble()
```

The design says the player chooses exactly 1 revealed marble. For the first implementation, prefer one selected marble per turn rather than allowing arbitrary committed counts.

Open design bridge:

```text
Current numeric core allows committing 0-4 wager marbles.
New deck design says choose exactly 1 selected marble.
```

Recommended bridge:

```text
For v1, selected_marble replaces wager count as the meaningful modifier.
Keep wager_marbles_committed internally at 1 for compatibility where needed.
Preserve old relic hooks with compatibility payload fields until relics are migrated.
```

### 4. Apply Selected Marble Effects in Numeric Resolution

Add selected marble data to numeric payloads:

```text
selected_marble_instance
selected_marble_id
revealed_marbles
marble_zones
```

Likely modification point:

```text
scripts/battle/battle_numeric_roulette_flow.gd
resolution_before_payload()
resolution_outcome()
```

Suggested new resolver:

```text
scripts/systems/marble_effect_resolver.gd
```

Prototype effect targets from design:

```text
plain: final damage x1.25
heavy: final damage x1.60, roulette Go/reroll disabled
leech: final damage x0.75, heal 25% dealt damage
guard: final damage x0.65, convert prevented damage into guard
pierce: final damage x0.85, add flat pierce/armor-ignore value
gamble: Big/Jackpot x1.80, otherwise x0.70
stable: Bust becomes Half, Jackpot capped to Big, final damage x0.92
poison: final damage x0.55, apply poison
cracked: final damage x0.60, if dice is 1 or 2 gain small guard
```

Do the first pass with data-driven payload mutation, not hardwired UI behavior.

### 5. Build Minimal Selection UI

Recommended first UI target:

```text
After dice resolves, show up to 3 revealed marble buttons/cards on the combat table.
Each shows marble image, name, and short effect.
Click selects exactly 1.
Enemy intent and dice result stay visible.
Then roulette begins.
```

Likely UI files:

```text
scripts/ui/hand_layer.gd
scripts/ui/table_layer.gd
scripts/ui/prompt_layer.gd
scripts/battle/battle_visual_layer_snapshots.gd
scripts/battle/battle_prompt_presenter.gd
scripts/ui/ui_text.gd
```

Do not build the full bag modal first. Start with the combat choice tray, then add the inspect modal.

### 6. Preserve or Fence Legacy Slot Flow

Legacy slot placement is isolated here:

```text
scripts/battle/battle_legacy_slot_flow.gd
```

Keep it compiling and passing tests while numeric marble selection is added.

Do not remove these until a later cleanup pass:

```text
placed_slots
RouletteSlotCatalog
PayoutResolver legacy slot handling
LegacySlotFlow
```

### 7. Update Tests

Add focused tests before broad UI work:

```text
scripts/tests/smoke_marble_deck_state.gd
scripts/tests/smoke_marble_effect_resolver.gd
scripts/tests/smoke_numeric_marble_selection_flow.gd
```

Existing tests to keep green:

```text
scripts/tests/smoke_combat_rules.gd
scripts/tests/smoke_numeric_roulette_model.gd
scripts/tests/smoke_battle_numeric_roulette_flow_helper.gd
scripts/smoke_presentation.gd
```

Update old expectations only when the new flow intentionally supersedes them.

## Risks

### Numeric Wager vs New Single Marble Choice

Current numeric core treats marbles as a count-based stake. The design treats a marble as a typed choice. This is the central design/code mismatch.

Do not let both systems stack accidentally:

```text
typed selected marble effect
plus old committed count multiplier
plus relic wager bonuses
```

That can over-amplify damage and break balance.

### Relic Hooks

Relics currently use fields such as:

```text
marble_gain
wager_marbles_available
wager_marbles_committed
placed_slots
roulette_before_spin
roulette_after_spin
resolution_before
resolution_after
```

Compatibility payloads are needed during migration.

### Save/Run State

The new design needs persistent deck state. Current `CombatState` only stores:

```text
marbles
stored
placed_slots
```

Do not make deck state combat-only unless the short-term goal is a throwaway prototype.

### UI Scope

The design includes combat choice, bag view, reward flow, shop/rest/event support, and deck inspection across screens. That is too much for one implementation slice.

First slice should be:

```text
combat-only starting deck
reveal 3
choose 1
apply selected effect
discard/reshuffle state
basic visual display
```

Rewards and deck editing should be a later slice.

## Verification Done Today

Godot executable found:

```text
C:\Users\xogns\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe
```

When running from WSL, invoke the Windows executable directly through `/mnt/c/...`.
PowerShell launching from WSL returned early during this pass and should not be trusted for verification unless its output is checked carefully.

These commands were run successfully from the project root:

```bash
G='/mnt/c/Users/xogns/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.6.2-stable_win64_console.exe'

"$G" --headless --path . --script res://scripts/tests/smoke_marble_deck_state.gd
"$G" --headless --path . --script res://scripts/tests/smoke_marble_effect_resolver.gd
"$G" --headless --path . --script res://scripts/tests/smoke_numeric_marble_selection_flow.gd
"$G" --headless --path . --script res://scripts/tests/smoke_numeric_roulette_model.gd
"$G" --headless --path . --script res://scripts/tests/smoke_battle_numeric_roulette_flow_helper.gd
"$G" --headless --path . --script res://scripts/tests/smoke_combat_rules.gd
"$G" --headless --path . --script res://scripts/tests/smoke_run_flow.gd
"$G" --headless --path . --script res://scripts/tests/smoke_screen_loads.gd
"$G" --headless --path . --script res://scripts/smoke_presentation.gd
```

Use this PowerShell setup only when running directly in PowerShell:

```powershell
$G = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64_console.exe"
```

Recommended before/after regression set:

```powershell
& $G --headless --path . --quit
& $G --headless --path . --script res://scripts/tests/smoke_combat_rules.gd
& $G --headless --path . --script res://scripts/tests/smoke_numeric_roulette_model.gd
& $G --headless --path . --script res://scripts/tests/smoke_battle_numeric_roulette_flow_helper.gd
& $G --headless --path . --script res://scripts/tests/smoke_numeric_roulette_battle_flow.gd
& $G --headless --path . --script res://scripts/smoke_presentation.gd
& $G --headless --path . --script res://scripts/tests/smoke_run_flow.gd
& $G --headless --path . --script res://scripts/tests/smoke_screen_loads.gd
```

Rendered `playtest_*.gd` scripts may require non-headless execution and a `--shot-dir`. Use them after logic smokes pass.

## B-Slice Implementation Completed

Implemented in this pass:

```text
1. MarbleCatalog and MarbleDeckState.
2. Starting 9-marble deck with bag/revealed/discard zones.
3. Numeric combat marble_choice phase after dice.
4. Reveal up to 3 marbles and choose exactly 1.
5. Selected marble payload carried through numeric roulette.
6. Prototype selected-marble effects via MarbleEffectResolver.
7. New v2 marble image mappings and runtime copied assets.
8. Basic combat-table choice cards and selected marble badge.
9. Regression and screenshot playtest coverage.
```

New core files:

```text
scripts/systems/marble_catalog.gd
scripts/resources/marble_deck_state.gd
scripts/systems/marble_effect_resolver.gd
scripts/battle/battle_marble_choice_flow.gd
```

New verification files:

```text
scripts/tests/smoke_marble_deck_state.gd
scripts/tests/smoke_marble_effect_resolver.gd
scripts/tests/smoke_numeric_marble_selection_flow.gd
scripts/tests/playtest_numeric_marble_choice_flow.gd
```

Generated screenshot proof:

```text
C:\dev\front-template\make newthing\goal_Test\runs\2026-06-01Tmarble-choice-flow\01_marble_choice_phase.png
C:\dev\front-template\make newthing\goal_Test\runs\2026-06-01Tmarble-choice-flow\02_selected_marble_spin_ready.png
```

Important current bridge:

```text
For numeric_roulette, selected typed marble now replaces player-controlled wager count.
The old legacy slot placement remains fenced behind legacy_slot and still has presentation coverage.
```

## Next Session Starting Point

Start here:

```text
1. Decide whether the selected typed marble fully replaces old wager count long-term.
2. Move MarbleDeckState persistence into run/save state instead of per-combat reset.
3. Add reward/shop/event/rest deck-edit operations.
4. Expand UI from combat choice cards to bag inspect and deck management.
5. Tune all 9 prototype marble effects with balance simulations.
6. Migrate relic hooks from count-based wager assumptions to selected_marble-aware payloads.
7. Add localization polish for marble names/effects.
8. Retire or formally keep legacy slot placement after design approval.
```

Open decision for the human/design lead:

```text
Should the old committed-marble stake multiplier remain at all,
or should the selected typed marble fully replace wager count in the new main core?
```

Recommended default:

```text
For the first playable implementation, selected typed marble should replace player-controlled wager count.
Keep internal committed count at 1 only as a compatibility bridge.
```
