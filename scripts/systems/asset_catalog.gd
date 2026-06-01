class_name AssetCatalog
extends RefCounted

const PORTRAITS_TEXTURE := "res://assets/external/opengameart-rpg-portraits-buch/rpgportraits.png"
const GOBLIN_TEXTURE := "res://assets/external/opengameart-goblin-imogia/spritesheet-goblinbighead-32x32-alpha.png"
const DICE_MOTION_TEXTURE := "res://assets/external/opengameart-360-die-spritesheet/360die2048transparent-cc0.png"
const DICE_MOTION_COLUMNS := 16
const DICE_MOTION_ROWS := 16
const DICE_MOTION_FRAME_SIZE := Vector2(128, 128)

const NODE_ICONS := {
	"combat": "res://assets/external/game-icons-node-icons/crossed-swords.png",
	"elite": "res://assets/external/game-icons-node-icons/radial-balance.png",
	"event": "res://assets/external/game-icons-node-icons/hanging-sign.png",
	"shop": "res://assets/external/game-icons-node-icons/shop.png",
	"rest": "res://assets/external/game-icons-node-icons/campfire.png",
	"boss": "res://assets/external/game-icons-node-icons/spinning-wheel.png",
	"fallback": "res://assets/external/game-icons-node-icons/rolling-dices.png"
}

const PROP_ICONS := {
	"dice": "res://assets/external/game-icons-node-icons/rolling-dices.png",
	"roulette": "res://assets/external/game-icons-node-icons/spinning-wheel.png",
	"pouch": "res://assets/external/game-icons-node-icons/hanging-sign.png"
}

const UI_TEXTURES := {
	"panel_frame": "res://assets/external/kenney-fantasy-ui-borders/extracted/PNG/Default/Border/panel-border-004.png",
	"panel_frame_round": "res://assets/external/kenney-fantasy-ui-borders/extracted/PNG/Default/Border/panel-border-012.png",
	"button_frame": "res://assets/external/kenney-fantasy-ui-borders/extracted/PNG/Default/Border/panel-border-020.png",
	"divider": "res://assets/external/kenney-fantasy-ui-borders/extracted/PNG/Default/Divider/divider-000.png",
	"divider_thin": "res://assets/external/kenney-fantasy-ui-borders/extracted/PNG/Default/Divider/divider-003.png"
}

const PHYSICAL_UI_BASE_PATH := "res://assets/ui/physicalization_001/"
const PHYSICAL_UI_PARCHMENT_CARD_SMALL := PHYSICAL_UI_BASE_PATH + "parchment_card_small.png"
const PHYSICAL_UI_PARCHMENT_CARD_LARGE := PHYSICAL_UI_BASE_PATH + "parchment_card_large.png"
const PHYSICAL_UI_LEDGER_SLIP := PHYSICAL_UI_BASE_PATH + "ledger_slip.png"
const PHYSICAL_UI_PROMPT_STRIP := PHYSICAL_UI_BASE_PATH + "prompt_strip.png"
const PHYSICAL_UI_PLAQUE_PRIMARY := PHYSICAL_UI_BASE_PATH + "plaque_primary.png"
const PHYSICAL_UI_PLAQUE_SECONDARY := PHYSICAL_UI_BASE_PATH + "plaque_secondary.png"
const PHYSICAL_UI_MARKER_COIN := PHYSICAL_UI_BASE_PATH + "marker_coin.png"
const PHYSICAL_UI_MARKER_WAX := PHYSICAL_UI_BASE_PATH + "marker_wax.png"
const PHYSICAL_UI_ROUTE_PIN := PHYSICAL_UI_BASE_PATH + "route_pin.png"
const PHYSICAL_UI_ROUTE_CORD := PHYSICAL_UI_BASE_PATH + "route_cord.png"

const PHYSICAL_UI_TEXTURES := {
	"parchment_card_small": PHYSICAL_UI_PARCHMENT_CARD_SMALL,
	"parchment_card_large": PHYSICAL_UI_PARCHMENT_CARD_LARGE,
	"ledger_slip": PHYSICAL_UI_LEDGER_SLIP,
	"prompt_strip": PHYSICAL_UI_PROMPT_STRIP,
	"plaque_primary": PHYSICAL_UI_PLAQUE_PRIMARY,
	"plaque_secondary": PHYSICAL_UI_PLAQUE_SECONDARY,
	"marker_coin": PHYSICAL_UI_MARKER_COIN,
	"marker_wax": PHYSICAL_UI_MARKER_WAX,
	"route_pin": PHYSICAL_UI_ROUTE_PIN,
	"route_cord": PHYSICAL_UI_ROUTE_CORD
}

const MAP_NODE_KIT_BASE_PATH := "res://assets/runtime/map/"

const MAP_NODE_KIT_TEXTURES := {
	"room_background_clean": MAP_NODE_KIT_BASE_PATH + "background/map_room_background_clean_001.png",
	"room_background_floor_1": MAP_NODE_KIT_BASE_PATH + "background/map_room_background_clean_001.png",
	"room_background_floor_2": MAP_NODE_KIT_BASE_PATH + "background/map_theme_02_enemy_power_clean.png",
	"room_background_floor_3": MAP_NODE_KIT_BASE_PATH + "background/map_theme_04_max_hp_pressure_clean.png",
	"map_theme_01_base": MAP_NODE_KIT_BASE_PATH + "background/map_room_background_clean_001.png",
	"map_theme_02_enemy_power": MAP_NODE_KIT_BASE_PATH + "background/map_theme_02_enemy_power_clean.png",
	"map_theme_03_player_damage_down": MAP_NODE_KIT_BASE_PATH + "background/map_theme_03_player_damage_down_clean.png",
	"map_theme_04_max_hp_pressure": MAP_NODE_KIT_BASE_PATH + "background/map_theme_04_max_hp_pressure_clean.png",
	"card_base_premium": MAP_NODE_KIT_BASE_PATH + "cards/node_card_front_base.png",
	"card_front_base": MAP_NODE_KIT_BASE_PATH + "cards/node_card_front_base.png",
	"card_back_covered": MAP_NODE_KIT_BASE_PATH + "cards/node_card_back_covered.png",
	"overlay_future": MAP_NODE_KIT_BASE_PATH + "cards/node_card_future_dim_overlay.png",
	"overlay_current": MAP_NODE_KIT_BASE_PATH + "cards/node_card_current_overlay.png",
	"overlay_selected": MAP_NODE_KIT_BASE_PATH + "cards/node_card_selected_hover_overlay.png",
	"overlay_completed": MAP_NODE_KIT_BASE_PATH + "cards/node_card_completed_overlay.png",
	"overlay_boss": MAP_NODE_KIT_BASE_PATH + "cards/node_card_boss_overlay.png",
	"emblem_combat": MAP_NODE_KIT_BASE_PATH + "nodes/node_emblem_combat.png",
	"emblem_event": MAP_NODE_KIT_BASE_PATH + "nodes/node_emblem_event.png",
	"emblem_shop": MAP_NODE_KIT_BASE_PATH + "nodes/node_emblem_shop.png",
	"emblem_rest": MAP_NODE_KIT_BASE_PATH + "nodes/node_emblem_rest.png",
	"emblem_elite": MAP_NODE_KIT_BASE_PATH + "nodes/node_emblem_elite.png",
	"emblem_boss": MAP_NODE_KIT_BASE_PATH + "nodes/node_emblem_boss.png",
	"route_cord": MAP_NODE_KIT_BASE_PATH + "table/route_cord.png",
	"route_pin": MAP_NODE_KIT_BASE_PATH + "table/route_pin.png",
	"wax_current": MAP_NODE_KIT_BASE_PATH + "table/wax_seal_current.png",
	"wax_completed": MAP_NODE_KIT_BASE_PATH + "table/wax_seal_completed.png",
	"wax_boss": MAP_NODE_KIT_BASE_PATH + "table/wax_seal_boss.png",
	"boss_endpoint_02": MAP_NODE_KIT_BASE_PATH + "boss/boss_endpoint_02_hand_of_fate_card.png",
	"legend_panel_003": MAP_NODE_KIT_BASE_PATH + "legend/map_node_legend_panel_003_premium_512x768.png"
}

const MAP_NODE_TOKEN_BASE_PATH := MAP_NODE_KIT_BASE_PATH + "tokens/"

const MAP_NODE_TOKEN_TEXTURES := {
	"combat": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_combat.png",
	"elite": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_elite.png",
	"boss": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_boss.png",
	"shop": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_shop.png",
	"rest": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_rest.png",
	"event_mystery": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_event_mystery.png",
	"event_chest": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_event_chest.png",
	"event_quest": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_event_quest.png",
	"event_gamble": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_event_gamble.png",
	"event": MAP_NODE_TOKEN_BASE_PATH + "map_node_token_event_mystery.png"
}

const TITLE_TEXTURES := {
	"style_target_001": "res://assets/runtime/title/luck-roulette-title-style-target-001.png",
	"background": "res://assets/runtime/title/title_background_1280x720.png",
	"logo_lockup": "res://assets/runtime/title/title_logo_lockup.png",
	"menu_button_idle": "res://assets/runtime/title/title_menu_button_idle.png",
	"menu_button_hover": "res://assets/runtime/title/title_menu_button_hover.png",
	"menu_button_disabled": "res://assets/runtime/title/title_menu_button_disabled.png",
	"continue_save_badge": "res://assets/runtime/title/title_continue_save_badge.png"
}

const SHELL_PAUSE_BASE_PATH := "res://assets/runtime/shell/pause/"

const SHELL_PAUSE_TEXTURES := {
	"menu_panel": SHELL_PAUSE_BASE_PATH + "pause_menu_panel_empty.png",
	"confirm_abandon_panel": SHELL_PAUSE_BASE_PATH + "pause_confirm_abandon_panel_empty.png",
	"button_primary": SHELL_PAUSE_BASE_PATH + "pause_button_primary.png",
	"button_secondary": SHELL_PAUSE_BASE_PATH + "pause_button_secondary.png",
	"button_danger": SHELL_PAUSE_BASE_PATH + "pause_button_danger.png",
	"divider": SHELL_PAUSE_BASE_PATH + "pause_divider.png"
}

const SHELL_RESULT_BASE_PATH := "res://assets/runtime/shell/result/"

const SHELL_RESULT_TEXTURES := {
	"board_clear": SHELL_RESULT_BASE_PATH + "run_clear_result_board_1280x720.png",
	"board_failed": SHELL_RESULT_BASE_PATH + "run_failed_result_board_1280x720.png",
	"ledger_panel": SHELL_RESULT_BASE_PATH + "result_ledger_panel_empty.png",
	"stat_battle": SHELL_RESULT_BASE_PATH + "result_stat_badge_battle.png",
	"stat_boss": SHELL_RESULT_BASE_PATH + "result_stat_badge_boss.png",
	"stat_event": SHELL_RESULT_BASE_PATH + "result_stat_badge_event.png",
	"stat_gold": SHELL_RESULT_BASE_PATH + "result_stat_badge_gold.png",
	"stat_relic": SHELL_RESULT_BASE_PATH + "result_stat_badge_relic.png",
	"stat_seed": SHELL_RESULT_BASE_PATH + "result_stat_badge_seed.png",
	"button_restart": SHELL_RESULT_BASE_PATH + "result_button_restart.png",
	"button_main_table": SHELL_RESULT_BASE_PATH + "result_button_main_table.png"
}

const SHELL_SETTINGS_BASE_PATH := "res://assets/runtime/shell/settings/"

const SHELL_SETTINGS_TEXTURES := {
	"board": SHELL_SETTINGS_BASE_PATH + "settings_board_1280x720.png",
	"slider_track": SHELL_SETTINGS_BASE_PATH + "settings_slider_track.png",
	"slider_knob": SHELL_SETTINGS_BASE_PATH + "settings_slider_knob.png",
	"toggle_off": SHELL_SETTINGS_BASE_PATH + "settings_toggle_off.png",
	"toggle_on": SHELL_SETTINGS_BASE_PATH + "settings_toggle_on.png",
	"button_reset_save": SHELL_SETTINGS_BASE_PATH + "settings_button_reset_save.png",
	"button_back": SHELL_SETTINGS_BASE_PATH + "settings_button_back.png"
}

const SHELL_GALLERY_BASE_PATH := "res://assets/runtime/shell/gallery/"

const SHELL_GALLERY_TEXTURES := {
	"board": SHELL_GALLERY_BASE_PATH + "gallery_board_1280x720.png",
	"detail_panel": SHELL_GALLERY_BASE_PATH + "gallery_detail_panel_empty.png",
	"item_card": SHELL_GALLERY_BASE_PATH + "gallery_item_card_empty.png",
	"item_locked_card": SHELL_GALLERY_BASE_PATH + "gallery_item_locked_card_empty.png",
	"tab_characters": SHELL_GALLERY_BASE_PATH + "gallery_tab_characters.png",
	"tab_relics": SHELL_GALLERY_BASE_PATH + "gallery_tab_relics.png",
	"tab_monsters": SHELL_GALLERY_BASE_PATH + "gallery_tab_monsters.png",
	"tab_events": SHELL_GALLERY_BASE_PATH + "gallery_tab_events.png"
}

const COMBAT_RUNTIME_BASE_PATH := "res://assets/runtime/combat/"

const COMBAT_RUNTIME_TEXTURES := {
	"roulette_wheel": COMBAT_RUNTIME_BASE_PATH + "roulette/wheel.png",
	"roulette_pointer": COMBAT_RUNTIME_BASE_PATH + "roulette/pointer.png",
	"dice_tray": COMBAT_RUNTIME_BASE_PATH + "tray/dice_tray.png",
	"marble_pouch": COMBAT_RUNTIME_BASE_PATH + "pouch/marble_pouch.png",
	"die_1": COMBAT_RUNTIME_BASE_PATH + "dice/die_1.png",
	"die_2": COMBAT_RUNTIME_BASE_PATH + "dice/die_2.png",
	"die_3": COMBAT_RUNTIME_BASE_PATH + "dice/die_3.png",
	"die_4": COMBAT_RUNTIME_BASE_PATH + "dice/die_4.png",
	"die_5": COMBAT_RUNTIME_BASE_PATH + "dice/die_5.png",
	"die_6": COMBAT_RUNTIME_BASE_PATH + "dice/die_6.png",
	"marble_plain": COMBAT_RUNTIME_BASE_PATH + "marbles/marble_plain.png",
	"marble_yellow": COMBAT_RUNTIME_BASE_PATH + "marbles/marble_star.png",
	"marble_green": COMBAT_RUNTIME_BASE_PATH + "marbles/marble_guard.png",
	"marble_curse": COMBAT_RUNTIME_BASE_PATH + "marbles/marble_skull.png",
	"marble_plain_v2": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_plain_001.png",
	"marble_heavy": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_heavy_001.png",
	"marble_leech": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_leech_001.png",
	"marble_guard_v2": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_guard_001.png",
	"marble_pierce": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_pierce_001.png",
	"marble_gamble": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_gamble_001.png",
	"marble_stable": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_stable_001.png",
	"marble_poison": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_poison_001.png",
	"marble_cracked": COMBAT_RUNTIME_BASE_PATH + "marbles/v2/marble_cracked_001.png",
	"marble_choice_tray": COMBAT_RUNTIME_BASE_PATH + "marbles/ui/marble_choice_tray_empty_candidate.png",
	"marble_bag_overlay_board": COMBAT_RUNTIME_BASE_PATH + "marbles/ui/marble_bag_overlay_board_empty_candidate.png",
	"marble_quick_view_slot": COMBAT_RUNTIME_BASE_PATH + "marbles/ui/marble_quick_view_slot_empty_candidate.png"
}

const SHOP_RUNTIME_BASE_PATH := "res://assets/runtime/shop/"

const SHOP_RUNTIME_TEXTURES := {
	"shop_room_background_clean": SHOP_RUNTIME_BASE_PATH + "background/shop_room_background_clean_001.png",
	"background_style_target_001": SHOP_RUNTIME_BASE_PATH + "background/shop_style_target_001.png",
	"offer_slot_base": SHOP_RUNTIME_BASE_PATH + "slots/offer_slot_base.png",
	"offer_slot_selected": SHOP_RUNTIME_BASE_PATH + "slots/offer_slot_selected.png",
	"offer_slot_sold": SHOP_RUNTIME_BASE_PATH + "slots/offer_slot_sold.png",
	"offer_slot_disabled": SHOP_RUNTIME_BASE_PATH + "slots/offer_slot_disabled.png",
	"price_tag_wide": SHOP_RUNTIME_BASE_PATH + "tags/price_tag_wide.png",
	"price_tag_small": SHOP_RUNTIME_BASE_PATH + "tags/price_tag_small.png",
	"detail_plate": SHOP_RUNTIME_BASE_PATH + "plates/detail_plate.png",
	"coin_stack": SHOP_RUNTIME_BASE_PATH + "tokens/coin_stack.png",
	"wax_sold": SHOP_RUNTIME_BASE_PATH + "tokens/wax_sold.png",
	"wax_disabled": SHOP_RUNTIME_BASE_PATH + "tokens/wax_disabled.png",
	"pin_gold": SHOP_RUNTIME_BASE_PATH + "tokens/pin_gold.png",
	"ticket_token_48": SHOP_RUNTIME_BASE_PATH + "tokens/rest_ticket_token_48.png",
	"ticket_token_96": SHOP_RUNTIME_BASE_PATH + "tokens/rest_ticket_token_96.png",
	"exchange_object_heal_vial": SHOP_RUNTIME_BASE_PATH + "exchange/exchange_heal_vial.png",
	"exchange_object_random_potion": SHOP_RUNTIME_BASE_PATH + "exchange/exchange_random_potion.png",
	"exchange_object_upgrade_ticket": SHOP_RUNTIME_BASE_PATH + "exchange/exchange_upgrade_ticket.png",
	"exchange_object_relic_pouch": SHOP_RUNTIME_BASE_PATH + "exchange/exchange_relic_pouch.png"
}

const SHOP_OPTIONAL_RUNTIME_TEXTURES := {
	"service_icon_cash_bait": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_cash_bait.png",
	"service_icon_dice_tune": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_dice_tune.png",
	"service_icon_roulette_tune": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_roulette_tune.png",
	"service_icon_risk_contract": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_risk_contract.png",
	"service_icon_blood_discount": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_blood_discount.png",
	"service_icon_heal_vial": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_heal_vial.png",
	"service_icon_marble_polish": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_marble_polish.png",
	"service_icon_discount_cut_coin": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_discount_cut_coin.png",
	"service_icon_contract_seal": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_contract_seal.png",
	"service_icon_gamble_token": SHOP_RUNTIME_BASE_PATH + "services/shop_service_icon_gamble_token.png",
	"service_header_ready": SHOP_RUNTIME_BASE_PATH + "headers/shop_service_card_header_ready.png",
	"service_header_contract": SHOP_RUNTIME_BASE_PATH + "headers/shop_service_card_header_contract.png",
	"service_header_limited": SHOP_RUNTIME_BASE_PATH + "headers/shop_service_card_header_limited.png",
	"service_header_special": SHOP_RUNTIME_BASE_PATH + "headers/shop_service_card_header_special.png",
	"service_header_gamble": SHOP_RUNTIME_BASE_PATH + "headers/shop_service_card_header_gamble.png",
	"badge_ready": SHOP_RUNTIME_BASE_PATH + "badges/shop_badge_ready.png",
	"badge_special": SHOP_RUNTIME_BASE_PATH + "badges/shop_badge_special.png",
	"badge_discount": SHOP_RUNTIME_BASE_PATH + "badges/shop_badge_discount.png",
	"badge_limited": SHOP_RUNTIME_BASE_PATH + "badges/shop_badge_limited.png",
	"badge_contract": SHOP_RUNTIME_BASE_PATH + "badges/shop_badge_contract.png",
	"badge_gamble": SHOP_RUNTIME_BASE_PATH + "badges/shop_badge_gamble.png",
	"button_reroll": SHOP_RUNTIME_BASE_PATH + "buttons/shop_button_reroll_normal.png",
	"button_reroll_hover": SHOP_RUNTIME_BASE_PATH + "buttons/shop_button_reroll_hover.png",
	"button_reroll_disabled": SHOP_RUNTIME_BASE_PATH + "buttons/shop_button_reroll_disabled.png"
}

const REST_RUNTIME_BASE_PATH := "res://assets/runtime/rest/"

const REST_RUNTIME_TEXTURES := {
	"room_background_clean": REST_RUNTIME_BASE_PATH + "background/rest_room_background_clean_002.png",
	"front_direction_lock": REST_RUNTIME_BASE_PATH + "background/rest_room_flow_front_direction_lock_002.png",
	"upgrade_direction_lock": REST_RUNTIME_BASE_PATH + "background/rest_room_flow_upgrade_direction_lock_CURRENT.png",
	"ticket_exchange_shop": SHOP_RUNTIME_BASE_PATH + "background/shop_room_background_clean_001.png"
}

const REWARD_RUNTIME_BASE_PATH := "res://assets/runtime/reward/"

const REWARD_RUNTIME_TEXTURES := {
	"reward_screen_full_board": REWARD_RUNTIME_BASE_PATH + "background/reward_screen_full_board_001.png"
}

const EVENT_RUNTIME_BASE_PATH := "res://assets/runtime/event/"

const EVENT_RUNTIME_TEXTURES := {
	"room_background_clean": EVENT_RUNTIME_BASE_PATH + "background/event_room_background_clean_001.png",
	"screen_base": EVENT_RUNTIME_BASE_PATH + "background/event_screen_base_mockup_001.png",
	"dice_check_focus": EVENT_RUNTIME_BASE_PATH + "background/event_dice_check_focus_mockup_001.png",
	"roulette_check_focus": EVENT_RUNTIME_BASE_PATH + "background/event_roulette_check_focus_mockup_001.png",
	"card_draw_focus": EVENT_RUNTIME_BASE_PATH + "background/event_card_draw_focus_mockup_001.png",
	"result_receipt_focus": EVENT_RUNTIME_BASE_PATH + "background/event_result_receipt_focus_mockup_001.png"
}

const EVENT_PROP_TEXTURES := {
	"roulette_medallion": EVENT_RUNTIME_BASE_PATH + "props/roulette_medallion.png",
	"dice_table": EVENT_RUNTIME_BASE_PATH + "props/dice_table.png",
	"choice_slip": EVENT_RUNTIME_BASE_PATH + "props/choice_slip.png",
	"card_front": EVENT_RUNTIME_BASE_PATH + "props/card_front.png",
	"card_back": EVENT_RUNTIME_BASE_PATH + "props/card_back.png"
}

const EVENT_SLIP_TEXTURES := {
	"choice_card_gain_hover": EVENT_RUNTIME_BASE_PATH + "slips/choice_card_gain_hover.png",
	"choice_card_blood_risk": EVENT_RUNTIME_BASE_PATH + "slips/choice_card_blood_risk.png",
	"choice_card_disabled": EVENT_RUNTIME_BASE_PATH + "slips/choice_card_disabled.png",
	"choice_card_cost_reward": EVENT_RUNTIME_BASE_PATH + "slips/choice_card_cost_reward.png",
	"choice_card_refuse": EVENT_RUNTIME_BASE_PATH + "slips/choice_card_refuse.png",
	"dice_result_one": EVENT_RUNTIME_BASE_PATH + "slips/dice_result_one.png",
	"dice_result_three": EVENT_RUNTIME_BASE_PATH + "slips/dice_result_three.png",
	"dice_result_six": EVENT_RUNTIME_BASE_PATH + "slips/dice_result_six.png"
}

const CHARACTER_RUNTIME_BASE_PATH := "res://assets/runtime/characters/"

const CHARACTER_RUNTIME_TEXTURES := {
	"character_select_table_bg": CHARACTER_RUNTIME_BASE_PATH + "common/select_table_background.png",
	"default_guard_dice_select": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/select_screen.png",
	"default_guard_dice_contract": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/contract_card.png",
	"default_guard_dice_select_card": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/select_card.png",
	"default_guard_dice_hero": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/hero.png",
	"default_guard_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/hud_emblem.png",
	"double_attack_dice_select": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/select_screen.png",
	"double_attack_dice_contract": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/contract_card.png",
	"double_attack_dice_select_card": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/select_card.png",
	"double_attack_dice_hero": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/hero.png",
	"double_attack_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/hud_emblem.png",
	"double_attack_dice_attack_medallion": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/attack_medallion.png",
	"double_attack_dice_no_guard_emblem": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/no_guard_emblem.png",
	"black_signer_no_dice_contract": CHARACTER_RUNTIME_BASE_PATH + "black_signer_no_dice/contract_card.png",
	"black_signer_no_dice_select_card": CHARACTER_RUNTIME_BASE_PATH + "black_signer_no_dice/select_card.png",
	"black_signer_no_dice_hero": CHARACTER_RUNTIME_BASE_PATH + "black_signer_no_dice/hero.png",
	"black_signer_no_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "black_signer_no_dice/hud_emblem.png",
	"future_luck_contract_hero": CHARACTER_RUNTIME_BASE_PATH + "future_luck_contract/hero.png",
	"future_luck_contract_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "future_luck_contract/hud_emblem.png"
}

const ART_PACK_TEXTURES := {
	"battle_table_bg": "res://assets/art-pack-0_1/backgrounds/battle-table-bg.png",
	"roulette_wheel": "res://assets/art-pack-0_1/props/roulette-wheel.png",
	"dice_1": "res://assets/art-pack-0_1/props/dice/die-1.png",
	"dice_2": "res://assets/art-pack-0_1/props/dice/die-2.png",
	"dice_3": "res://assets/art-pack-0_1/props/dice/die-3.png",
	"dice_4": "res://assets/art-pack-0_1/props/dice/die-4.png",
	"dice_5": "res://assets/art-pack-0_1/props/dice/die-5.png",
	"dice_6": "res://assets/art-pack-0_1/props/dice/die-6.png",
	"marble_plain": "res://assets/art-pack-0_1/props/marbles/marble-red.png",
	"marble_yellow": "res://assets/art-pack-0_1/props/marbles/marble-blue.png",
	"marble_green": "res://assets/art-pack-0_1/props/marbles/marble-blue.png",
	"marble_curse": "res://assets/art-pack-0_1/props/marbles/marble-curse.png",
	"ui_frames": "res://assets/art-pack-0_1/ui/ui-frames.png"
}

const RELIC_ICONS := {
	"loaded_die": "res://assets/art-pack-0_1/props/relics/loaded_die.png",
	"green_purse": "res://assets/art-pack-0_1/props/relics/green_purse.png",
	"yellow_guard": "res://assets/art-pack-0_1/props/relics/yellow_guard.png",
	"purple_contract": "res://assets/art-pack-0_1/props/relics/purple_contract.png",
	"bust_insurance": "res://assets/art-pack-0_1/props/relics/bust_insurance.png",
	"snake_eyes_charm": "res://assets/art-pack-0_1/props/relics/snake_eyes_charm.png",
	"second_chance": "res://assets/art-pack-0_1/props/relics/second_chance.png",
	"turn_token": "res://assets/art-pack-0_1/props/relics/turn_token.png",
	"locksmith_glove": "res://assets/art-pack-0_1/props/relics/locksmith_glove.png",
	"twin_marker": "res://assets/art-pack-0_1/props/relics/twin_marker.png",
	"blue_chisel": "res://assets/art-pack-0_1/props/relics/blue_chisel.png",
	"last_call_bell": "res://assets/art-pack-0_1/props/relics/last_call_bell.png",
	"fallback": "res://assets/external/game-icons-node-icons/rolling-dices.png"
}

const RELIC_RUNTIME_BASE_PATH := "res://assets/runtime/relics/"

const RELIC_ICON_OVERRIDES := {
	"loaded_die": RELIC_RUNTIME_BASE_PATH + "icons/loaded_die_icon.png",
	"green_purse": RELIC_RUNTIME_BASE_PATH + "icons/green_purse_icon.png",
	"yellow_guard": RELIC_RUNTIME_BASE_PATH + "icons/yellow_guard_icon.png",
	"purple_contract": RELIC_RUNTIME_BASE_PATH + "icons/purple_contract_icon.png",
	"twin_marker": RELIC_RUNTIME_BASE_PATH + "icons/twin_marker_icon.png",
	"blue_chisel": RELIC_RUNTIME_BASE_PATH + "icons/blue_chisel_icon.png",
	"last_call_bell": RELIC_RUNTIME_BASE_PATH + "icons/last_call_bell_icon.png",
	"default_guard_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/hud_emblem.png",
	"double_attack_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/hud_emblem.png"
}

const RELIC_OBJECTS := {
	"loaded_die": RELIC_RUNTIME_BASE_PATH + "objects/loaded_die_object.png",
	"green_purse": RELIC_RUNTIME_BASE_PATH + "objects/green_purse_object.png",
	"yellow_guard": RELIC_RUNTIME_BASE_PATH + "objects/yellow_guard_object.png",
	"purple_contract": RELIC_RUNTIME_BASE_PATH + "objects/purple_contract_object.png",
	"twin_marker": RELIC_RUNTIME_BASE_PATH + "objects/twin_marker_object.png",
	"blue_chisel": RELIC_RUNTIME_BASE_PATH + "objects/blue_chisel_object.png",
	"last_call_bell": RELIC_RUNTIME_BASE_PATH + "objects/last_call_bell_object.png",
	"default_guard_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "default_guard_dice/hud_emblem.png",
	"double_attack_dice_hud_emblem": CHARACTER_RUNTIME_BASE_PATH + "double_attack_dice/hud_emblem.png"
}

const CONSUMABLE_RUNTIME_BASE_PATH := "res://assets/runtime/consumables/"

const CONSUMABLE_TEXTURES := {
	"red_vial_object": CONSUMABLE_RUNTIME_BASE_PATH + "objects/red_vial_object.png",
	"red_vial_icon": CONSUMABLE_RUNTIME_BASE_PATH + "icons/red_vial_icon.png"
}

const MONSTER_SOURCES := {
	"debt_collector": "portraits",
	"table_crook": "portraits",
	"elite_house": "goblin",
	"final_house": "portraits",
	"fallback": "portraits"
}

const MONSTER_RUNTIME_BASE_PATH := COMBAT_RUNTIME_BASE_PATH + "opponents/"

const DESIGN_PROMOTED_MONSTER_IDS := [
	"blind_call_chip",
	"cold_deck_box",
	"cut_card_switcher",
	"inkblot_accountant",
	"interest_tick",
	"paper_cut_bailiff",
	"red_ledger_bleeder",
	"side_bet_splitter",
	"stamped_default",
	"cracked_marble_usher",
	"red_black_taxer",
	"wheel_jammer",
	"orbit_pin",
	"spilled_ale_hecker",
	"broken_stool_guard",
	"lucky_rabbit_receipt",
	"coat_check_thief"
]

const MONSTER_TEXTURES := {
	"debt_collector": MONSTER_RUNTIME_BASE_PATH + "opponent_debt_collector_emblem_001.png",
	"table_crook": MONSTER_RUNTIME_BASE_PATH + "opponent_table_crook_emblem_001.png",
	"loaded_dice_runner": MONSTER_RUNTIME_BASE_PATH + "opponent_loaded_dice_runner_emblem_001.png",
	"house_errand": MONSTER_RUNTIME_BASE_PATH + "opponent_house_errand_emblem_001.png",
	"mug_brawler": MONSTER_RUNTIME_BASE_PATH + "opponent_mug_brawler_emblem_001.png",
	"backroom_bookie": MONSTER_RUNTIME_BASE_PATH + "opponent_backroom_bookie_emblem_001.png",
	"chip_stack_bruiser": MONSTER_RUNTIME_BASE_PATH + "opponent_chip_stack_bruiser_emblem_001.png",
	"busted_lantern": MONSTER_RUNTIME_BASE_PATH + "opponent_busted_lantern_emblem_001.png",
	"coin_shark": MONSTER_RUNTIME_BASE_PATH + "opponent_coin_shark_emblem_001.png",
	"roulette_sweeper": MONSTER_RUNTIME_BASE_PATH + "opponent_roulette_sweeper_emblem_001.png",
	"marked_card_sneak": MONSTER_RUNTIME_BASE_PATH + "opponent_marked_card_sneak_emblem_001.png",
	"pocket_ace_thief": MONSTER_RUNTIME_BASE_PATH + "opponent_pocket_ace_thief_emblem_001.png",
	"pawn_ticket": MONSTER_RUNTIME_BASE_PATH + "opponent_pawn_ticket_emblem_001.png",
	"candle_counter": MONSTER_RUNTIME_BASE_PATH + "opponent_candle_counter_emblem_001.png",
	"burnt_receipt": MONSTER_RUNTIME_BASE_PATH + "opponent_burnt_receipt_emblem_001.png",
	"bell_ringer": MONSTER_RUNTIME_BASE_PATH + "opponent_bell_ringer_emblem_001.png",
	"false_dealer_hand": MONSTER_RUNTIME_BASE_PATH + "opponent_false_dealer_hand_emblem_001.png",
	"brass_lockbox": MONSTER_RUNTIME_BASE_PATH + "opponent_brass_lockbox_emblem_001.png",
	"ashtray_curse": MONSTER_RUNTIME_BASE_PATH + "opponent_ashtray_curse_emblem_001.png",
	"snake_eye_clerk": MONSTER_RUNTIME_BASE_PATH + "opponent_snake_eye_clerk_emblem_001.png",
	"last_call_drunk": MONSTER_RUNTIME_BASE_PATH + "opponent_last_call_drunk_emblem_001.png",
	"elite_house": MONSTER_RUNTIME_BASE_PATH + "opponent_elite_house_emblem_001.png",
	"pit_boss_sentinel": MONSTER_RUNTIME_BASE_PATH + "opponent_pit_boss_sentinel_emblem_001.png",
	"taxed_roulette_knight": MONSTER_RUNTIME_BASE_PATH + "opponent_taxed_roulette_knight_emblem_001.png",
	"blacklist_notary": MONSTER_RUNTIME_BASE_PATH + "opponent_blacklist_notary_emblem_001.png",
	"loaded_vault_keeper": MONSTER_RUNTIME_BASE_PATH + "opponent_loaded_vault_keeper_emblem_001.png",
	"final_house": MONSTER_RUNTIME_BASE_PATH + "opponent_final_house_emblem_001.png",
	"the_croupier": MONSTER_RUNTIME_BASE_PATH + "opponent_the_croupier_emblem_001.png",
	"the_red_seal": MONSTER_RUNTIME_BASE_PATH + "opponent_the_red_seal_emblem_001.png"
}

const PORTRAIT_REGIONS := {
	"debt_collector": Rect2(108, 4, 32, 32),
	"table_crook": Rect2(144, 4, 32, 32),
	"elite_house": Rect2(0, 96, 32, 32),
	"final_house": Rect2(292, 4, 32, 32),
	"fallback": Rect2(4, 4, 32, 32)
}

static var _texture_cache: Dictionary = {}

static func node_icon_path(node_type: String) -> String:
	return str(NODE_ICONS.get(node_type, NODE_ICONS["fallback"]))

static func node_icon(node_type: String) -> Texture2D:
	return _load_texture(node_icon_path(node_type))

static func prop_icon_path(prop_id: String) -> String:
	return str(PROP_ICONS.get(prop_id, PROP_ICONS["dice"]))

static func prop_icon(prop_id: String) -> Texture2D:
	return _load_texture(prop_icon_path(prop_id))

static func relic_icon_path(relic_icon_id: String) -> String:
	var runtime_path := _runtime_relic_icon_path(relic_icon_id)
	if runtime_path != "":
		return runtime_path
	if RELIC_ICON_OVERRIDES.has(relic_icon_id):
		return str(RELIC_ICON_OVERRIDES[relic_icon_id])
	return str(RELIC_ICONS.get(relic_icon_id, RELIC_ICONS["fallback"]))

static func relic_icon(relic_icon_id: String) -> Texture2D:
	return _load_texture(relic_icon_path(relic_icon_id))

static func relic_object_path(relic_icon_id: String) -> String:
	var runtime_path := _runtime_relic_object_path(relic_icon_id)
	if runtime_path != "":
		return runtime_path
	if RELIC_OBJECTS.has(relic_icon_id):
		return str(RELIC_OBJECTS[relic_icon_id])
	return relic_icon_path(relic_icon_id)

static func relic_object(relic_icon_id: String) -> Texture2D:
	return _load_texture(relic_object_path(relic_icon_id))

static func consumable_texture_path(texture_id: String) -> String:
	return str(CONSUMABLE_TEXTURES.get(texture_id, ""))

static func consumable_texture(texture_id: String) -> Texture2D:
	var path := consumable_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func ui_texture_path(texture_id: String) -> String:
	return str(UI_TEXTURES.get(texture_id, UI_TEXTURES["panel_frame"]))

static func ui_texture(texture_id: String) -> Texture2D:
	return _load_texture(ui_texture_path(texture_id))

static func physical_ui_texture_path(texture_id: String) -> String:
	return str(PHYSICAL_UI_TEXTURES.get(texture_id, ""))

static func physical_ui_texture(texture_id: String) -> Texture2D:
	var path := physical_ui_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func map_node_kit_texture_path(texture_id: String) -> String:
	return str(MAP_NODE_KIT_TEXTURES.get(texture_id, ""))

static func map_node_kit_texture(texture_id: String) -> Texture2D:
	var path := map_node_kit_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func map_node_token_texture_path(token_id: String) -> String:
	return str(MAP_NODE_TOKEN_TEXTURES.get(token_id, MAP_NODE_TOKEN_TEXTURES["event_mystery"]))

static func map_node_token_texture(token_id: String) -> Texture2D:
	return _load_texture(map_node_token_texture_path(token_id))

static func title_texture_path(texture_id: String) -> String:
	return str(TITLE_TEXTURES.get(texture_id, ""))

static func title_texture(texture_id: String) -> Texture2D:
	var path := title_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func shell_pause_texture_path(texture_id: String) -> String:
	return str(SHELL_PAUSE_TEXTURES.get(texture_id, ""))

static func shell_pause_texture(texture_id: String) -> Texture2D:
	var path := shell_pause_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func shell_result_texture_path(texture_id: String) -> String:
	return str(SHELL_RESULT_TEXTURES.get(texture_id, ""))

static func shell_result_texture(texture_id: String) -> Texture2D:
	var path := shell_result_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func shell_settings_texture_path(texture_id: String) -> String:
	return str(SHELL_SETTINGS_TEXTURES.get(texture_id, ""))

static func shell_settings_texture(texture_id: String) -> Texture2D:
	var path := shell_settings_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func shell_gallery_texture_path(texture_id: String) -> String:
	return str(SHELL_GALLERY_TEXTURES.get(texture_id, ""))

static func shell_gallery_texture(texture_id: String) -> Texture2D:
	var path := shell_gallery_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func combat_runtime_texture_path(texture_id: String) -> String:
	return str(COMBAT_RUNTIME_TEXTURES.get(texture_id, ""))

static func combat_runtime_texture(texture_id: String) -> Texture2D:
	var path := combat_runtime_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func shop_runtime_texture_path(texture_id: String) -> String:
	if SHOP_RUNTIME_TEXTURES.has(texture_id):
		return str(SHOP_RUNTIME_TEXTURES.get(texture_id, ""))
	return str(SHOP_OPTIONAL_RUNTIME_TEXTURES.get(texture_id, ""))

static func shop_runtime_texture(texture_id: String) -> Texture2D:
	var path := shop_runtime_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func rest_runtime_texture_path(texture_id: String) -> String:
	return str(REST_RUNTIME_TEXTURES.get(texture_id, ""))

static func rest_runtime_texture(texture_id: String) -> Texture2D:
	var path := rest_runtime_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func reward_runtime_texture_path(texture_id: String) -> String:
	return str(REWARD_RUNTIME_TEXTURES.get(texture_id, ""))

static func reward_runtime_texture(texture_id: String) -> Texture2D:
	var path := reward_runtime_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func event_runtime_texture_path(texture_id: String) -> String:
	return str(EVENT_RUNTIME_TEXTURES.get(texture_id, ""))

static func event_runtime_texture(texture_id: String) -> Texture2D:
	var path := event_runtime_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func event_prop_texture_path(texture_id: String) -> String:
	return str(EVENT_PROP_TEXTURES.get(texture_id, ""))

static func event_prop_texture(texture_id: String) -> Texture2D:
	var path := event_prop_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func event_slip_texture_path(texture_id: String) -> String:
	return str(EVENT_SLIP_TEXTURES.get(texture_id, ""))

static func event_slip_texture(texture_id: String) -> Texture2D:
	var path := event_slip_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func character_runtime_texture_path(texture_id: String) -> String:
	return str(CHARACTER_RUNTIME_TEXTURES.get(texture_id, ""))

static func character_runtime_texture(texture_id: String) -> Texture2D:
	var path := character_runtime_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func art_pack_texture_path(texture_id: String) -> String:
	return str(ART_PACK_TEXTURES.get(texture_id, ""))

static func art_pack_texture(texture_id: String) -> Texture2D:
	var path := art_pack_texture_path(texture_id)
	if path == "":
		return null
	return _load_texture(path)

static func dice_face(value: int) -> Texture2D:
	var runtime_die := combat_runtime_texture("die_" + str(clamp(value, 1, 6)))
	if runtime_die != null:
		return runtime_die
	return art_pack_texture("dice_" + str(clamp(value, 1, 6)))

static func dice_motion_texture() -> Texture2D:
	return _load_texture(DICE_MOTION_TEXTURE)

static func dice_motion_region(frame_index: int) -> Rect2:
	var frame_count: int = DICE_MOTION_COLUMNS * DICE_MOTION_ROWS
	var frame: int = posmod(frame_index, frame_count)
	var x: int = frame % DICE_MOTION_COLUMNS
	var y: int = int(floor(float(frame) / float(DICE_MOTION_COLUMNS)))
	return Rect2(Vector2(float(x), float(y)) * DICE_MOTION_FRAME_SIZE, DICE_MOTION_FRAME_SIZE)

static func dice_motion_result_region(value: int) -> Rect2:
	var result_frames: Array[int] = [0, 5, 10, 15, 20, 25]
	return dice_motion_region(result_frames[clamp(value, 1, 6) - 1])

static func dice_motion_result_texture(value: int) -> Texture2D:
	var atlas := dice_motion_texture()
	if atlas == null:
		return dice_face(value)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = dice_motion_result_region(value)
	return texture

static func marble_texture(color: String) -> Texture2D:
	if COMBAT_RUNTIME_TEXTURES.has(color):
		var typed := combat_runtime_texture(color)
		if typed != null:
			return typed
	if color == "plain":
		var plain := combat_runtime_texture("marble_plain")
		if plain != null:
			return plain
		return art_pack_texture("marble_plain")
	if color == "yellow":
		var yellow := combat_runtime_texture("marble_yellow")
		if yellow != null:
			return yellow
		return art_pack_texture("marble_yellow")
	if color == "green":
		var green := combat_runtime_texture("marble_green")
		if green != null:
			return green
		return art_pack_texture("marble_green")
	var curse := combat_runtime_texture("marble_curse")
	if curse != null:
		return curse
	return art_pack_texture("marble_curse")

static func monster_texture_path(monster_id: String) -> String:
	var runtime_path := _runtime_monster_texture_path(monster_id)
	if runtime_path != "":
		return runtime_path
	if MONSTER_TEXTURES.has(monster_id):
		return str(MONSTER_TEXTURES[monster_id])
	var source: String = str(MONSTER_SOURCES.get(monster_id, MONSTER_SOURCES["fallback"]))
	if source == "goblin":
		return GOBLIN_TEXTURE
	return PORTRAITS_TEXTURE

static func monster_texture(monster_id: String) -> Texture2D:
	return _load_texture(monster_texture_path(monster_id))

static func monster_region(monster_id: String) -> Rect2:
	if _runtime_monster_texture_path(monster_id) != "" or MONSTER_TEXTURES.has(monster_id):
		return Rect2(0, 0, 450, 450)
	return PORTRAIT_REGIONS.get(monster_id, PORTRAIT_REGIONS["fallback"])

static func first_pass_asset_ids() -> Dictionary:
	var monster_ids: Array[String] = []
	for monster_id in MONSTER_TEXTURES.keys():
		monster_ids.append(str(monster_id))
	for monster_id in DESIGN_PROMOTED_MONSTER_IDS:
		if not monster_ids.has(str(monster_id)):
			monster_ids.append(str(monster_id))
	return {
		"monsters": monster_ids,
		"node_types": ["combat", "elite", "event", "shop", "rest", "boss"],
		"props": ["dice", "roulette", "pouch"],
		"relics": [
			"loaded_die",
			"green_purse",
			"yellow_guard",
			"purple_contract",
			"bust_insurance",
			"snake_eyes_charm",
			"second_chance",
			"turn_token"
		],
		"ui": ["panel_frame", "panel_frame_round", "button_frame", "divider", "divider_thin"],
		"physical_ui": PHYSICAL_UI_TEXTURES.keys(),
		"map_node_kit": MAP_NODE_KIT_TEXTURES.keys(),
		"map_node_tokens": MAP_NODE_TOKEN_TEXTURES.keys(),
		"title": TITLE_TEXTURES.keys(),
		"shell_pause": SHELL_PAUSE_TEXTURES.keys(),
		"shell_result": SHELL_RESULT_TEXTURES.keys(),
		"shell_settings": SHELL_SETTINGS_TEXTURES.keys(),
		"shell_gallery": SHELL_GALLERY_TEXTURES.keys(),
		"combat_runtime": COMBAT_RUNTIME_TEXTURES.keys(),
		"shop_runtime": SHOP_RUNTIME_TEXTURES.keys(),
		"rest_runtime": REST_RUNTIME_TEXTURES.keys(),
		"reward_runtime": REWARD_RUNTIME_TEXTURES.keys(),
		"event_runtime": EVENT_RUNTIME_TEXTURES.keys(),
		"event_props": EVENT_PROP_TEXTURES.keys(),
		"event_slips": EVENT_SLIP_TEXTURES.keys(),
		"character_runtime": CHARACTER_RUNTIME_TEXTURES.keys(),
		"relic_objects": RELIC_OBJECTS.keys(),
		"relic_icon_overrides": RELIC_ICON_OVERRIDES.keys(),
		"consumables": CONSUMABLE_TEXTURES.keys(),
		"art_pack": ART_PACK_TEXTURES.keys(),
		"dice_motion": ["360_degree_die_spritesheet"]
	}

static func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	var err: Error = image.load(absolute_path)
	if err != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture

static func _runtime_relic_icon_path(relic_icon_id: String) -> String:
	var clean_id := _safe_asset_id(relic_icon_id)
	if clean_id == "":
		return ""
	var path := RELIC_RUNTIME_BASE_PATH + "icons/" + clean_id + "_icon.png"
	return path if _asset_file_exists(path) else ""

static func _runtime_relic_object_path(relic_icon_id: String) -> String:
	var clean_id := _safe_asset_id(relic_icon_id)
	if clean_id == "":
		return ""
	var path := RELIC_RUNTIME_BASE_PATH + "objects/" + clean_id + "_object.png"
	return path if _asset_file_exists(path) else ""

static func _runtime_monster_texture_path(monster_id: String) -> String:
	var clean_id := _safe_asset_id(monster_id)
	if clean_id == "":
		return ""
	var path := MONSTER_RUNTIME_BASE_PATH + "opponent_" + clean_id + "_emblem_001.png"
	return path if _asset_file_exists(path) else ""

static func _safe_asset_id(value: String) -> String:
	var result := value.strip_edges().to_lower()
	for ch in [" ", "-", ".", "/", "\\"]:
		result = result.replace(ch, "_")
	return result

static func _asset_file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))
