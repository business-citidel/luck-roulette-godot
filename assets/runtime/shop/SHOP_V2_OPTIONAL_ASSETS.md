# Shop V2 Optional Runtime Assets

`AssetCatalog` already knows these optional IDs. Missing files fall back to
code-drawn placeholders and do not fail the strict asset smoke test.

```text
services/shop_service_icon_cash_bait.png
services/shop_service_icon_dice_tune.png
services/shop_service_icon_roulette_tune.png
services/shop_service_icon_risk_contract.png
services/shop_service_icon_blood_discount.png
services/shop_service_icon_heal_vial.png
services/shop_service_icon_marble_polish.png
services/shop_service_icon_discount_cut_coin.png
services/shop_service_icon_contract_seal.png
services/shop_service_icon_gamble_token.png

headers/shop_service_card_header_ready.png
headers/shop_service_card_header_contract.png
headers/shop_service_card_header_limited.png
headers/shop_service_card_header_special.png
headers/shop_service_card_header_gamble.png

badges/shop_badge_ready.png
badges/shop_badge_special.png
badges/shop_badge_discount.png
badges/shop_badge_limited.png
badges/shop_badge_contract.png
badges/shop_badge_gamble.png

buttons/shop_button_reroll_normal.png
buttons/shop_button_reroll_hover.png
buttons/shop_button_reroll_disabled.png
```

Constraints:

```text
transparent PNG
no baked language text
service icons readable at 68-96 px
corner badges readable at 32-48 px
reroll button fits roughly 190x60 in the current shop layout
```
