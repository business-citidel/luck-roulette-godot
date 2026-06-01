# Design Runtime Status

Runtime asset status for the current design handoff.

## Runtime Promoted

Relics:

- `assets/runtime/relics/icons/*_icon.png`: 113 promoted, 128 x 128 RGBA.
- `assets/runtime/relics/objects/*_object.png`: 113 promoted, 256 x 256 RGBA.
- New relic pass: 100 front-alpha sheet candidates sliced into individual runtime objects/icons.
- Legacy current-catalog backfill: 6 pre-100 relic mini assets promoted into object/icon files.
- `assets/runtime/consumables/icons/red_vial_icon.png`: promoted, 128 x 128 RGBA.
- `assets/runtime/consumables/objects/red_vial_object.png`: promoted, 256 x 256 RGBA.

Map tokens:

- `assets/runtime/map/tokens/map_node_token_*.png`: 9 promoted, 1024 x 1024 RGBA.

Monster/opponent emblems:

- `assets/runtime/combat/opponents/opponent_*_emblem_001.png`: 45 promoted in the shared mirror.
- `game/luck-roulette-godot/assets/runtime/combat/opponents/opponent_*_emblem_001.png`: 45 promoted in the Godot-loaded copy.
- New this pass: 17 from Batch D/E.

## Candidates

Monster/opponent emblems kept out of runtime:

- `misdeal_token`: monitor small face marks at runtime scale.
- `zero_slot_acolyte`: zero-like oval is role-driven, but keep pending policy approval.
- `ashtray_curse`: readable silhouette, but needs brighter ember/card detail.

## Discard

Batch F elite/boss emblems:

- `audit_inquisitor`
- `pit_clock_judge`
- `chapel_wheelwarden`
- `vault_tax_colossus`
- `curse_notary_prime`
- `tavern_champion_mug`
- `the_auditor`
- `the_zero_wheel`
- `the_double_down_king`
- `the_black_contract`

Reason: top-level review rejected Batch F as final runtime art. Keep only as silhouette planning until repainted.

## Runtime Fix Pass

- New monster promotions are normalized through `tools/promote_opponent_runtime_assets.py`.
- Runtime monster names follow `opponent_<monster_id>_emblem_001.png`.
- Relic runtime names follow `icons/<id>_icon.png` and `objects/<id>_object.png`.
- Relic 100 slicing is normalized through `tools/slice_relic_100_front_alpha_runtime.py`.
- Legacy relic backfill is normalized through `tools/backfill_legacy_relic_runtime_assets.py`.
- No new promoted monster file is rotated, non-square, or dimension-mismatched; all new files verified as 450 x 450 RGB PNGs.
- Current `RelicCatalog` coverage is complete: 32/32 catalog icon ids have both icon and object PNGs.

## 2026-05-22 Runtime Mirror Sync

Shared runtime and Godot runtime were audited after the design integration
report. Three Godot-only map theme backgrounds were copied back into the shared
runtime mirror:

```text
map/background/map_theme_02_enemy_power_clean.png
map/background/map_theme_03_player_damage_down_clean.png
map/background/map_theme_04_max_hp_pressure_clean.png
```

Use this check before and after future promotions:

```text
tools/audit_runtime_sync.sh
```

Expected harmless difference:

```text
assets/runtime/README.md
```

## 2026-05-22 Dice Cup 3D Cleanup

The experimental dice cup 3D kit was removed from the shared runtime mirror:

```text
assets/runtime/combat/dice-cup-3d/
```

It now lives as parked design/experiment material:

```text
assets/curated/luck-roulette-current/dice-cup-3d-experiment/dice-cup-3d/
```

Reason:

```text
The current Godot game does not load those GLB/FBX/BLEND candidate files as
final runtime assets. Normal combat uses the 2D dice layer, and the opt-in 3D
cup event layer uses primitive/generated visuals.
```
