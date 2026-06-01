class_name FeedbackEventMapper
extends RefCounted

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

const YELLOW := Color("#f4da63")
const GREEN := Color("#65d48e")
const PURPLE := Color("#a879ef")
const RED := Color("#ee5b5b")
const BLUE := Color("#66a8ff")
const GOLD := Color("#f2be4b")
const TEXT := Color("#f6efe2")

static func map_effects(applied_effects: Array, context: String = "") -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for effect in applied_effects:
		if not effect is Dictionary:
			continue
		var event := _map_effect(effect, context)
		if not event.is_empty():
			events.append(event)
	return events

static func _map_effect(effect: Dictionary, context: String) -> Dictionary:
	var effect_id: String = str(effect.get("effect_id", ""))
	var source_id: String = str(effect.get("relic_id", effect.get("source_id", "")))
	var source_name: String = str(effect.get("name", source_id))
	match effect_id:
		"enemy_damage_down":
			return _event("relic", source_id, source_name, "Hit softened", YELLOW, "table", 0.85, "dice_lock", context)
		"roulette_respin_plus_one", "velvet_choker_go":
			return _event("relic", source_id, source_name, "Extra spin", BLUE, "roulette", 0.9, "wheel_tick", context)
		"bust_to_hit":
			return _event("relic", source_id, source_name, "Failure bent", YELLOW, "roulette", 1.1, "table_hit", context)
		"dice_count_plus_one", "doubles_first_die_plus_one", "attack_die_plus_one", "low_attack_die_plus_one":
			return _event("relic", source_id, source_name, "Dice improved", BLUE, "dice", 0.8, "dice_lock", context)
		"last_reroll_die_plus_two":
			return _event("relic", source_id, source_name, "Last reroll sharpened", BLUE, "dice", 0.95, "dice_lock", context)
		"last_reroll_selected_die_plus_one":
			return _event("relic", source_id, source_name, "Last reroll sharpened", BLUE, "dice", 0.95, "dice_lock", context)
		"wide_split_bonus":
			return _event("relic", source_id, source_name, "Split paid", GOLD, "dice", 0.85, "coin_spill", context)
		"split_tip_gold":
			return _event("relic", source_id, source_name, "Split paid", GOLD, "dice", 0.85, "coin_spill", context)
		"exact_four_gold":
			return _event("relic", source_id, source_name, "Four paid", GOLD, "cash", 0.85, "coin_spill", context)
		"guard_lead_block", "even_keel_block":
			return _event("relic", source_id, source_name, "Guard led", YELLOW, "dice", 0.85, "dice_lock", context)
		"brass_key_gold", "brass_stopwatch_gold":
			return _event("relic", source_id, source_name, "Last reroll paid", GOLD, "cash", 0.8, "coin_spill", context)
		"snake_receipt_gold", "bent_coin_gold", "high_roller_lint_gold":
			return _event("relic", source_id, source_name, "Dice paid", GOLD, "dice", 0.8, "coin_spill", context)
		"strong_attack_extra_marker", "gambler_debt_wager", "golden_table_wager":
			return _event("relic", source_id, source_name, "Extra marker", BLUE, "roulette", 0.85, "marble_drop", context)
		"low_total_extra_marker":
			return _event("relic", source_id, source_name, "Low roll marker", BLUE, "roulette", 0.85, "marble_drop", context)
		"lucky_low_extra_marker":
			return _event("relic", source_id, source_name, "Lucky marker", BLUE, "roulette", 0.85, "marble_drop", context)
		"spare_marble_double", "savant_extra_marble", "thimble_extra_marble":
			return _event("relic", source_id, source_name, "Extra marker", BLUE, "roulette", 0.85, "marble_drop", context)
		"low_attack_guard":
			return _event("relic", source_id, source_name, "Low roll guard", YELLOW, "table", 0.85, "dice_lock", context)
		"green_payout_multiplier", "green_cash_bonus", "profit_bonus":
			return _event("relic", source_id, source_name, "Marked profit", GREEN, "cash", 1.0, "coin_spill", context)
		"profit_tithe_gold", "marked_miss_gold", "adjacent_mark_gold", "zero_receipt_gold", "double_or_debt_jackpot_gold", "house_edge_gold", "neighbor_cut_gold", "overdrive_confetti_gold", "lazy_susan_gold", "raincheck_gold", "tiny_mascot_boss_gold", "red_letter_go_gold":
			return _event("relic", source_id, source_name, "Table paid", GOLD, "cash", 0.95, "coin_spill", context)
		"double_or_debt_bust_debt", "lucky_jury_bust_tax", "red_letter_collapse_tax":
			return _event("relic", source_id, source_name, "Debt collected", GOLD, "cash", 0.95, "coin_spill", context)
		"odd_eye_paid", "calling_bell_gold":
			return _event("relic", source_id, source_name, "Table paid", GOLD, "cash", 0.95, "coin_spill", context)
		"shop_meal_heal", "warm_canteen_heal", "cleric_coin_heal", "shop_meal_ticket_heal", "red_cordial_elite_heal", "waffle_full_heal", "bruise_receipt_heal", "polite_haggle_heal", "elite_souvenir_heal", "regal_pillow_rest":
			return _event("relic", source_id, source_name, "Meal recovered", RED, "player", 0.8, "coin_spill", context)
		"strawberry_max_hp", "cleric_coin_pickup", "ivory_ambulance_pickup", "tiny_house_bundle":
			return _event("relic", source_id, source_name, "Health grew", RED, "player", 0.85, "coin_spill", context)
		"empty_vault_pickup":
			return _event("relic", source_id, source_name, "Vault opened", GOLD, "cash", 0.95, "coin_spill", context)
		"ticket_primer_chance", "punched_ticket_paid", "voucher_coupon_refund", "carbon_copy_voucher", "ticket_lint_chance", "ticket_lint_bank", "double_stamp_ticket", "quiet_scalper_ticket", "scarred_elite_ticket", "dealer_smile_ticket", "stamp_album_ticket", "ticket_monopoly_plus", "voucher_forge_refund", "lucky_jury_ticket", "royal_press_voucher", "black_star_elite_contract":
			return _event("relic", source_id, source_name, "Ticket paid", BLUE, "cash", 0.85, "coin_spill", context)
		"bust_power_debt", "gold_locked_purse_start", "empty_trophy_gold", "cashback_chip_gold", "rest_change_gold", "velvet_price_refund", "cult_mask_gold", "empty_trophy_elite_gold", "sample_tray_refund", "upgrade_receipt_gold", "pocket_map_gold":
			return _event("relic", source_id, source_name, "Debt paid", GOLD, "cash", 0.95, "coin_spill", context)
		"dusty_shelf_offer", "appraisal_lens_option", "black_star_option", "souvenir_keyring_risk", "boss_map_option":
			return _event("relic", source_id, source_name, "Choice widened", BLUE, "table", 0.75, "wheel_tick", context)
		"scarred_ticket_tax", "ivory_ambulance_rest_block", "voucher_forge_rest_tax", "black_star_ticket_tax", "blood_coupon_discount", "royal_press_shop_tax", "infinite_key_upgrade_tax", "empty_vault_gold_lock":
			return _event("relic", source_id, source_name, "Price paid", RED, "player", 0.85, "table_hit", context)
		"turn_cash_tip":
			return _event("relic", source_id, source_name, "Turn tip", GOLD, "cash", 0.75, "coin_spill", context)
		"low_gold_tip":
			return _event("relic", source_id, source_name, "Small change", GOLD, "cash", 0.75, "coin_spill", context)
		"gold_armor_block", "low_hp_block", "black_stop_block", "sealed_box_opened", "paper_shield_block", "regal_pillow_turn", "tin_helmet_elite_block", "cautious_pin_block", "cracked_mirror_block", "guard_engine_block":
			return _event("relic", source_id, source_name, "Guard readied", YELLOW, "table", 0.8, "dice_lock", context)
		"starting_guard_block":
			return _event("relic", source_id, source_name, "Guard readied", YELLOW, "table", 0.8, "dice_lock", context)
		"guard_counter_damage":
			return _event("relic", source_id, source_name, "Guard countered", YELLOW, "enemy", 1.0, "table_hit", context)
		"starting_lifesteal":
			return _event("relic", source_id, source_name, "Blood paid", RED, "player", 0.85, "coin_spill", context)
		"red_marble_lifesteal", "last_hand_heal":
			return _event("relic", source_id, source_name, "Blood paid", RED, "player", 0.85, "coin_spill", context)
		"overheal_block_set", "overheal_block_carry":
			return _event("relic", source_id, source_name, "Blood guarded", RED, "player", 0.85, "dice_lock", context)
		"marked_hit_guard":
			return _event("relic", source_id, source_name, "Marked hit guarded", YELLOW, "roulette", 0.9, "marble_drop", context)
		"empty_guard_block":
			return _event("relic", source_id, source_name, "Empty guard held", YELLOW, "table", 0.9, "table_hit", context)
		"marked_bust_bail":
			return _event("relic", source_id, source_name, "Bust bailed", YELLOW, "bust", 1.0, "table_hit", context)
		"first_mark_flat_damage":
			return _event("relic", source_id, source_name, "First mark struck", BLUE, "roulette", 1.0, "table_hit", context)
		"marked_jackpot_multiplier":
			return _event("relic", source_id, source_name, "Marked jackpot", PURPLE, "roulette", 1.0, "wheel_tick", context)
		"jackpot_knife_multiplier", "blood_jackpot_paid", "cracked_scepter_jackpot", "glass_jackpot_multiplier", "black_candle_burn", "heavy_crown_jackpot", "all_in_badge_multiplier":
			return _event("relic", source_id, source_name, "Jackpot cut", PURPLE, "roulette", 1.0, "wheel_tick", context)
		"cracked_scepter_bust_pressure", "action_cap_late_pressure", "greedy_ledger_turn", "noon_duel_late_pressure", "gambler_debt_pressure":
			return _event("relic", source_id, source_name, "Enemy sharpened", RED, "enemy", 0.9, "table_hit", context)
		"umbrella_button_soften":
			return _event("relic", source_id, source_name, "Hit softened", YELLOW, "enemy", 0.85, "dice_lock", context)
		"marked_overdrive_flat_damage":
			return _event("relic", source_id, source_name, "Marked strong hit", BLUE, "roulette", 1.0, "wheel_tick", context)
		"overdrive_pin_flat_damage":
			return _event("relic", source_id, source_name, "Overdrive pinned", BLUE, "roulette", 1.0, "wheel_tick", context)
		"split_tooth_flat_damage", "pain_bell_low_hp", "roulette_savant_pin", "odd_charm_flat_damage", "unmarked_hit_damage", "blood_quill_paid", "no_safe_low_boost", "heavy_crown_die_flat", "action_cap_early_attack", "no_refund_first_turn", "low_stakes_flat", "jackpot_sparkler_flat", "redline_tag_flat", "noon_duel_early_attack":
			return _event("relic", source_id, source_name, "Hit sharpened", BLUE, "roulette", 1.0, "wheel_tick", context)
		"pinned_guard_set", "pinned_guard_carry", "wager_padding_block":
			return _event("relic", source_id, source_name, "Guard pinned", YELLOW, "roulette", 0.85, "marble_drop", context)
		"repeat_slot_multiplier":
			return _event("relic", source_id, source_name, "Groove paid", PURPLE, "roulette", 0.95, "wheel_tick", context)
		"bust_delta_cancelled":
			return _event("relic", source_id, source_name, "Bust blocked", YELLOW, "bust", 1.15, "table_hit", context)
		"after_bust_set", "after_bust_block", "cracked_mirror_set":
			return _event("relic", source_id, source_name, "Bruise guarded", YELLOW, "bust", 0.95, "table_hit", context)
		"black_candle_bust_cost":
			return _event("relic", source_id, source_name, "Blood collected", RED, "player", 1.0, "table_hit", context)
		"first_hit_prevented", "cheap_insurance_prevented", "spare_heel_prevented", "tiny_bandage_prevented":
			return _event("relic", source_id, source_name, "First hit blocked", YELLOW, "enemy", 1.0, "table_hit", context)
		"preserved_insect_elite_hp":
			return _event("relic", source_id, source_name, "Elite weakened", PURPLE, "enemy", 0.95, "table_hit", context)
		"infinite_key_reroll", "cracked_hourglass_reroll":
			return _event("relic", source_id, source_name, "Reroll restored", BLUE, "dice", 0.85, "dice_lock", context)
		"house_edge_crown_weights":
			return _event("relic", source_id, source_name, "Wheel warped", PURPLE, "roulette", 0.9, "wheel_tick", context)
		"thorn_chip_counter":
			return _event("relic", source_id, source_name, "Thorns bit", RED, "enemy", 1.0, "table_hit", context)
		"glass_jackpot_fragility":
			return _event("relic", source_id, source_name, "Glass cracked", RED, "player", 1.0, "table_hit", context)
		"victory_cash_bonus":
			return _event("relic", source_id, source_name, "Last call coins", GOLD, "cash", 1.0, "coin_spill", context)
		"interest_token_gold":
			return _event("relic", source_id, source_name, "Interest paid", GOLD, "cash", 1.0, "coin_spill", context)
		"hp_damage":
			return _event("enemy", source_id, source_name, "HP hit", RED, "enemy", 1.0, "table_hit", context)
		"enemy_guard":
			return _event("enemy", source_id, source_name, "Guarded", YELLOW, "enemy", 0.8, "dice_lock", context)
		"enemy_damage_up":
			return _event("enemy", source_id, source_name, "Powered up", PURPLE, "enemy", 0.85, "wheel_tick", context)
		"player_attack_down":
			return _event("enemy", source_id, source_name, "Attack weakened", PURPLE, "dice", 0.85, "dice_lock", context)
		"cash_taxed":
			return _event("enemy", source_id, source_name, "Gold taxed", GOLD, "cash", 0.9, "coin_spill", context)
		"intent_hidden":
			return _event("enemy", source_id, source_name, "Intent hidden", BLUE, "table", 0.75, "wheel_tick", context)
		"run_mod":
			return _event("run_mod", source_id, source_name, "Hit softened", BLUE, "table", 0.7, "dice_lock", context)
		_:
			return {}

static func _event(type: String, source_id: String, source: String, label: String, color: Color, target: String, intensity: float, audio_key: String, context: String) -> Dictionary:
	var event := {
		"type": type,
		"source_id": source_id,
		"source": source,
		"label": source + ": " + label,
		"color": color,
		"target": target,
		"intensity": intensity,
		"audio_key": audio_key,
		"context": context
	}
	if type == "relic" and RelicCatalog.has_relic(source_id):
		event["relic_id"] = source_id
		event["icon_id"] = RelicCatalog.icon_id(source_id)
		event["pulse"] = "relic"
	return event
