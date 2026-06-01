# Relic Runtime Asset Handoff

Design owns relic runtime visuals.

Godot now auto-detects relic assets by `RelicCatalog.icon_id`, so design can
promote or replace PNGs without editing `AssetCatalog`.

## Naming Contract

For relic id:

```text
dice_wide_split
```

Provide:

```text
icons/dice_wide_split_icon.png
objects/dice_wide_split_object.png
```

`objects/*_object.png` is used for reward/shop/event object displays.
`icons/*_icon.png` is used for HUD/detail/icon strip displays.

## Rules

- Transparent PNG.
- No baked UI text, price, button, labels, HP, or state names.
- Front-facing or near-front object read.
- 128x128 preferred for icons.
- Keep the mirror folder under `assets/runtime/relics/` in sync.

## Lock Policy

Design may add visuals for all 100 relic candidates now.

Gameplay still decides what is unlocked through `RelicCatalog` and
`RelicPoolCatalog`. A runtime PNG does not automatically put a relic into
normal rewards.
