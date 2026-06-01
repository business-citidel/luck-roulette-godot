# Third Party Notices

## Kenney Casino Audio

- Source: https://kenney.nl/assets/casino-audio
- Local path: `assets/audio/kenney_casino-audio/`
- Version in archive: Casino Audio 1.1
- Author: Kenney Vleugels / Kenney.nl
- License: Creative Commons Zero, CC0
- Use in prototype:
  - dice throw and dice lock sounds
  - chip/marble pick and drop sounds
  - wheel tick sounds
  - coin spill and table hit feedback

The included `License.txt` states the assets may be used in personal and
commercial projects, and that credit is appreciated but not required.

## Phantom Camera

- Source: https://github.com/ramokz/phantom-camera
- Local path: `addons/phantom_camera/`
- Vendored version: v0.9.3.1
- Author: Marcus Skov / Ramokz
- License: MIT, per the official Godot Asset Store and repository metadata
- Use in prototype:
  - vendored as the first camera-system wheel candidate
  - not enabled as a runtime plugin in the current pass because headless
    validation exposed Godot class registration order issues when the addon
    autoload is enabled directly
  - current runtime uses a small `Camera2D` beat adapter with the same named
    camera-beat interface so Phantom Camera can be retried behind that seam

## EasyTransition

- Source: https://github.com/IUXGames/EasyTransition
- Local research copy: `vendor/external-wheels/EasyTransition/`
- Runtime copy: `addons/easytransition/`
- License: MIT
- Use in prototype:
  - adopted for the first ritual scene transition spike
  - wrapped behind `scripts/systems/transition_service.gd`
  - used through manual `cover()` / `uncover()` calls instead of whole-scene
    `transition_to()` so the combat table can launch reusable ritual scenes and
    receive explicit result payloads

## Kenney Fantasy UI Borders

- Source: https://opengameart.org/content/fantasy-ui-borders
- Local path: `assets/external/kenney-fantasy-ui-borders/`
- Author: Kenney / Kenney.nl
- License: Creative Commons Zero, CC0
- Use in prototype:
  - adopted as the first mini medieval UI skin source
  - shared panel/corner/divider textures resolved through `AssetCatalog`
  - title, intro, map, reward, event, shop, rest, and run-end panel framing
    drawn through local `UiSkin` glue

Credit to Kenney.nl is appreciated but not required by the asset page.

## Buch RPG Portraits

- Source: https://opengameart.org/content/rpg-portraits
- Local path: `assets/external/opengameart-rpg-portraits-buch/`
- Author: Buch
- License: Creative Commons Zero, CC0
- Use in prototype:
  - first-pass opponent/player portrait token sheet
  - mapped through `scripts/systems/asset_catalog.gd`

Credit to Buch is appreciated but not required by the asset page.

## Goblin Monster

- Source: https://opengameart.org/content/goblin-monster
- Local path: `assets/external/opengameart-goblin-imogia/`
- Author: ImogiaGames, remixed after MoikMellah's Goblin Corps Platformer Set
- License: Creative Commons Zero, CC0
- Use in prototype:
  - first-pass elite opponent token sheet
  - mapped through `scripts/systems/asset_catalog.gd`

Attribution is not required, but the asset page suggests:
`Goblin Monster by Imogia, remixed after MoikMellah's Goblin Corps Platformer Set`.

## Game-icons.net

- Source: https://game-icons.net
- Local path: `assets/external/game-icons-node-icons/`
- Authors used in this prototype: Lorc, Delapouite, Caro Asercion, and contributors
- License: CC BY 3.0
- Use in prototype:
  - map node icons for combat, event, elite, shop, rest, and boss
  - small prop identity icons for dice, pouch, and roulette
  - loaded through `scripts/systems/asset_catalog.gd`

Imported icons are stored as SVG source plus PNG runtime copies:

- `crossed-swords` by Lorc
- `campfire` by Lorc
- `radial-balance` by Lorc
- `shop` by Delapouite
- `rolling-dices` by Delapouite
- `hanging-sign` by Delapouite
- `spinning-wheel` by Caro Asercion
