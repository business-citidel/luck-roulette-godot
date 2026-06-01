# Phaser To Godot Migration Plan

## Keep From Phaser MVP

- Dice determine marble count and color.
- Yellow = safety.
- Green = profit.
- Purple = risk/jackpot.
- Roulette profit becomes the core payoff.
- Seeded runs matter.
- Max-three-button phase combat.

## Change In Godot

- Use scenes/resources instead of DOM buttons and canvas helpers.
- Author roulette, enemies, map nodes, and upgrades as Godot resources later.
- Make the editor the inspection surface for designers/operators.

## Product Architecture Target

```text
Main
  RunMapScene
  EncounterScene
    DiceTime
    RouletteTime
    EnemyTime
  RewardScene
  ShopScene
  EventScene
  RestScene
```

## First Vertical Slice

- One normal enemy.
- One elite enemy.
- One boss.
- One map act.
- Spin profit damages enemy.
- Enemy intent corrupts roulette state.
- Three-button action bar.
