class_name RelicEffectResolver
extends RefCounted

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const RuntimeBridge := preload("res://scripts/runtime/systems/game_object_runtime_bridge.gd")

const COMBAT_START := "combat_start"
const TURN_START := "turn_start"
const DICE_RESULT := "dice_result"
const MARBLE_GAIN := "marble_gain"
const ROULETTE_BEFORE_SPIN := "roulette_before_spin"
const ROULETTE_AFTER_SPIN := "roulette_after_spin"
const RESOLUTION_BEFORE := "resolution_before"
const RESOLUTION_AFTER := "resolution_after"
const DAMAGE_TAKEN := "damage_taken"
const COMBAT_VICTORY := "combat_victory"
const COMBAT_END := "combat_end"
const REWARD_APPLY := "reward_apply"
const RELIC_PICKUP := "relic_pickup"

const SUPPORTED_TRIGGERS: Array[String] = [
	COMBAT_START,
	TURN_START,
	DICE_RESULT,
	MARBLE_GAIN,
	ROULETTE_BEFORE_SPIN,
	ROULETTE_AFTER_SPIN,
	RESOLUTION_BEFORE,
	RESOLUTION_AFTER,
	DAMAGE_TAKEN,
	COMBAT_VICTORY,
	COMBAT_END,
	REWARD_APPLY,
	RELIC_PICKUP
]

static func apply(trigger: String, payload: Dictionary, relic_ids: Array) -> Dictionary:
	var result := payload.duplicate(true)
	result["applied_effects"] = _effects(result)
	match trigger:
		COMBAT_START:
			_apply_combat_start(result, relic_ids)
		TURN_START:
			_apply_turn_start(result, relic_ids)
		DICE_RESULT:
			_apply_dice_result(result, relic_ids)
		MARBLE_GAIN:
			_apply_marble_gain(result, relic_ids)
		ROULETTE_BEFORE_SPIN:
			_apply_roulette_before_spin(result, relic_ids)
		RESOLUTION_BEFORE:
			_apply_resolution_before(result, relic_ids)
		RESOLUTION_AFTER:
			_apply_resolution_after(result, relic_ids)
		ROULETTE_AFTER_SPIN:
			_apply_roulette_after_spin(result, relic_ids)
		DAMAGE_TAKEN:
			_apply_damage_taken(result, relic_ids)
		COMBAT_VICTORY, COMBAT_END:
			_apply_combat_finish(result, relic_ids)
		REWARD_APPLY:
			_apply_reward_apply(result, relic_ids)
		RELIC_PICKUP:
			_apply_relic_pickup(result, relic_ids)
		_:
			result["unknown_relic_trigger"] = trigger
	return result

static func supported_triggers() -> Array[String]:
	return SUPPORTED_TRIGGERS.duplicate()

static func _apply_combat_start(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "warm_canteen"):
		var warm_max_hp: int = max(1, int(result.get("player_max_hp", 1)))
		if int(result.get("player_hp", warm_max_hp)) * 2 <= warm_max_hp:
			_heal_player(result, 1)
			_record(result, "warm_canteen", "warm_canteen_heal")
	if _has_relic(relic_ids, "tin_helmet") and _is_elite_encounter(result):
		result["player_block"] = int(result.get("player_block", 0)) + 3
		_record(result, "tin_helmet", "tin_helmet_elite_block")
	if _has_relic(relic_ids, "preserved_insect_pin") and _is_elite_encounter(result):
		var elite_max_hp: int = max(1, int(result.get("enemy_max_hp", result.get("enemy_hp", 1))))
		var hp_cut: int = max(1, int(ceil(float(elite_max_hp) * 0.12)))
		result["enemy_max_hp"] = max(1, elite_max_hp - hp_cut)
		result["enemy_hp"] = min(max(1, int(result.get("enemy_hp", elite_max_hp)) - hp_cut), int(result["enemy_max_hp"]))
		_record(result, "preserved_insect_pin", "preserved_insect_elite_hp")
	if _has_relic(relic_ids, "gambler_debt"):
		result["wager_marbles_available"] = int(result.get("wager_marbles_available", 1)) + 1
		_record(result, "gambler_debt", "gambler_debt_wager")
	if _has_relic(relic_ids, "golden_table"):
		result["wager_marbles_available"] = int(result.get("wager_marbles_available", 1)) + 1
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 1
		_record(result, "golden_table", "golden_table_wager")
	if _has_relic(relic_ids, "infinite_reroll_key"):
		result["rerolls_left_delta"] = int(result.get("rerolls_left_delta", 0)) + 1
		_record(result, "infinite_reroll_key", "infinite_key_reroll")
	if _has_relic(relic_ids, "gold_locked_purse"):
		result["combat_cash"] = int(result.get("combat_cash", result.get("cash", 0))) + 8
		result["cash"] = int(result.get("cash", result.get("combat_cash", 0))) + 8
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 1
		_record(result, "gold_locked_purse", "gold_locked_purse_start")

static func _apply_reward_apply(result: Dictionary, relic_ids: Array) -> void:
	var choice := str(result.get("choice", ""))
	var reward_tier := str(result.get("reward_tier", ""))
	var state: Dictionary = result.get("relic_state", {})
	if _has_relic(relic_ids, "black_star_contract") and choice == "combat_reward":
		var contract_chance: int = int(result.get("ticket_chance", 0))
		if contract_chance > 0:
			var taxed_chance: int = max(0, contract_chance - 10)
			result["ticket_chance"] = taxed_chance
			if int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) > 0 and int(result.get("ticket_roll", 999)) >= taxed_chance:
				result["contract_tickets_delta"] = 0
			_record(result, "black_star_contract", "black_star_ticket_tax")
	if _has_relic(relic_ids, "scarred_ticket_punch") and choice == "combat_reward":
		var old_chance: int = int(result.get("ticket_chance", 0))
		if old_chance > 0:
			var scarred_chance: int = max(0, old_chance - 5)
			result["ticket_chance"] = scarred_chance
			if int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) > 0 and int(result.get("ticket_roll", 999)) >= scarred_chance:
				result["contract_tickets_delta"] = 0
			_record(result, "scarred_ticket_punch", "scarred_ticket_tax")
	if _has_relic(relic_ids, "ticket_lint") and choice == "combat_reward":
		var lint_bonus: int = int(state.get("ticket_lint_bonus", 0))
		if lint_bonus > 0 and int(result.get("ticket_chance", 0)) > 0:
			var lint_chance: int = min(95, int(result.get("ticket_chance", 0)) + lint_bonus)
			result["ticket_chance"] = lint_chance
			if int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) <= 0 and int(result.get("ticket_roll", 999)) < lint_chance:
				result["contract_tickets_delta"] = 1
			_record(result, "ticket_lint", "ticket_lint_chance")
	if _has_relic(relic_ids, "ticket_primer") and choice == "combat_reward":
		var old_chance: int = int(result.get("ticket_chance", 0))
		if old_chance > 0:
			var new_chance: int = min(95, old_chance + 10)
			result["ticket_chance"] = new_chance
			if int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) <= 0 and int(result.get("ticket_roll", 999)) < new_chance:
				result["contract_tickets_delta"] = 1
			_record(result, "ticket_primer", "ticket_primer_chance")
	if _has_relic(relic_ids, "ticket_lint") and choice == "combat_reward":
		if int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) > 0:
			state["ticket_lint_bonus"] = 0
		else:
			state["ticket_lint_bonus"] = min(15, int(state.get("ticket_lint_bonus", 0)) + 3)
		result["relic_state"] = state
		_record(result, "ticket_lint", "ticket_lint_bank")
	if _has_relic(relic_ids, "punched_ticket") and choice == "combat_reward":
		var punched_state: Dictionary = result.get("relic_state", {})
		var count: int = int(punched_state.get("punched_ticket_count", 0)) + 1
		if count >= 3:
			count = 0
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) + 1
			_record(result, "punched_ticket", "punched_ticket_paid")
		punched_state["punched_ticket_count"] = count
		result["relic_state"] = punched_state
	if _has_relic(relic_ids, "bruise_receipt") and choice == "combat_reward":
		var max_hp: int = max(1, int(result.get("player_max_hp", 1)))
		if int(result.get("player_hp", max_hp)) * 2 <= max_hp:
			result["hp_delta"] = int(result.get("hp_delta", 0)) + 3
			_record(result, "bruise_receipt", "bruise_receipt_heal")
	if _has_relic(relic_ids, "cult_mask_chip") and choice == "combat_reward":
		var cult_key := "cult_mask_floor_" + str(int(result.get("floor_index", 1)))
		if not bool(state.get(cult_key, false)):
			result["gold_delta"] = int(result.get("gold_delta", 0)) + 1
			state[cult_key] = true
			result["relic_state"] = state
			_record(result, "cult_mask_chip", "cult_mask_gold")
	if _has_relic(relic_ids, "double_stamp_pad") and int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) > 0:
		var stamp_key := "double_stamp_floor_" + str(int(result.get("floor_index", 1)))
		if not bool(state.get(stamp_key, false)) and _stable_percent(result, "double_stamp_pad") < 25:
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			state[stamp_key] = true
			result["relic_state"] = state
			_record(result, "double_stamp_pad", "double_stamp_ticket")
	if _has_relic(relic_ids, "red_cordial") and (choice == "elite_reward" or reward_tier == "elite"):
		result["hp_delta"] = int(result.get("hp_delta", 0)) + 5
		_record(result, "red_cordial", "red_cordial_elite_heal")
	if _has_relic(relic_ids, "quiet_scalper") and (choice == "elite_reward" or reward_tier == "elite"):
		var scalper_key := "quiet_scalper_floor_" + str(int(result.get("floor_index", 1)))
		if not bool(state.get(scalper_key, false)):
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			state[scalper_key] = true
			result["relic_state"] = state
			_record(result, "quiet_scalper", "quiet_scalper_ticket")
	if _has_relic(relic_ids, "scarred_ticket_punch") and (choice == "elite_reward" or reward_tier == "elite"):
		result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
		_record(result, "scarred_ticket_punch", "scarred_elite_ticket")
	if _has_relic(relic_ids, "black_star_contract") and (choice == "elite_reward" or reward_tier == "elite"):
		result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
		result["relic_reward_option_delta"] = int(result.get("relic_reward_option_delta", 0)) + 1
		_record(result, "black_star_contract", "black_star_elite_contract")
	if _has_relic(relic_ids, "black_star_stub") and (choice == "elite_reward" or reward_tier == "elite"):
		result["relic_reward_option_delta"] = int(result.get("relic_reward_option_delta", 0)) + 1
		_record(result, "black_star_stub", "black_star_option")
	if _has_relic(relic_ids, "elite_souvenir_mask") and (choice == "elite_reward" or reward_tier == "elite"):
		var souvenir_max_hp: int = max(1, int(result.get("player_max_hp", 1)))
		if int(result.get("player_hp", souvenir_max_hp)) * 2 < souvenir_max_hp:
			var target_hp: int = int(ceil(float(souvenir_max_hp) * 0.5))
			result["hp_delta"] = int(result.get("hp_delta", 0)) + max(0, target_hp - int(result.get("player_hp", 0)))
			_record(result, "elite_souvenir_mask", "elite_souvenir_heal")
	if _has_relic(relic_ids, "empty_trophy") and (choice == "elite_reward" or reward_tier == "elite"):
		if not bool(state.get("empty_trophy_used", false)):
			result["gold_delta"] = int(result.get("gold_delta", 0)) + 7
			state["empty_trophy_used"] = true
			result["relic_state"] = state
			_record(result, "empty_trophy", "empty_trophy_elite_gold")
	if _has_relic(relic_ids, "shop_meal_ticket") and choice == "shop_leave":
		result["hp_delta"] = int(result.get("hp_delta", 0)) + 6
		_record(result, "shop_meal_ticket", "shop_meal_ticket_heal")
	if _has_relic(relic_ids, "polite_haggle") and choice == "shop_leave":
		if int(result.get("gold", 0)) + int(result.get("gold_delta", 0)) < 10:
			result["hp_delta"] = int(result.get("hp_delta", 0)) + 3
			_record(result, "polite_haggle", "polite_haggle_heal")
	if _has_relic(relic_ids, "velvet_price_tag") and choice == "shop_leave" and not (result.get("relic_ids", []) as Array).is_empty():
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 5
		_record(result, "velvet_price_tag", "velvet_price_refund")
	if _has_relic(relic_ids, "blood_coupon") and choice == "shop_leave" and _shop_result_has_relic_purchase(result):
		result["hp_delta"] = int(result.get("hp_delta", 0)) - 2
		_record(result, "blood_coupon", "blood_coupon_discount")
	if _has_relic(relic_ids, "cashback_chip") and choice == "shop_leave" and _shop_result_has_purchase(result):
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 1
		_record(result, "cashback_chip", "cashback_chip_gold")
	if _has_relic(relic_ids, "sample_tray") and choice == "shop_leave" and not (result.get("potion_ids", []) as Array).is_empty():
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 4
		_record(result, "sample_tray", "sample_tray_refund")
	if _has_relic(relic_ids, "dealer_smile") and choice == "shop_leave":
		var dealer_key := "dealer_smile_floor_" + str(int(result.get("floor_index", 1)))
		if not bool(state.get(dealer_key, false)):
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			state[dealer_key] = true
			result["relic_state"] = state
			_record(result, "dealer_smile", "dealer_smile_ticket")
	if _has_relic(relic_ids, "rest_change_jar") and choice.begins_with("rest_"):
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 2
		_record(result, "rest_change_jar", "rest_change_gold")
	if _has_relic(relic_ids, "regal_pillow_chip") and choice == "rest_heal":
		result["hp_delta"] = int(result.get("hp_delta", 0)) + 5
		_record(result, "regal_pillow_chip", "regal_pillow_rest")
	if _has_relic(relic_ids, "ivory_ambulance") and choice == "rest_heal":
		result["hp_delta"] = 0
		_record(result, "ivory_ambulance", "ivory_ambulance_rest_block")
	if _has_relic(relic_ids, "voucher_forge_contract") and choice == "rest_heal":
		result["hp_delta"] = int(floor(float(int(result.get("hp_delta", 0))) * 0.75))
		_record(result, "voucher_forge_contract", "voucher_forge_rest_tax")
	if _has_relic(relic_ids, "upgrade_receipt") and (choice.begins_with("upgrade_") or choice == "ticket_upgrade_voucher"):
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 3
		_record(result, "upgrade_receipt", "upgrade_receipt_gold")
	if _has_relic(relic_ids, "voucher_coupon") and choice == "ticket_upgrade_voucher":
		var voucher_state: Dictionary = result.get("relic_state", {})
		if not bool(voucher_state.get("voucher_coupon_used", false)):
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			voucher_state["voucher_coupon_used"] = true
			result["relic_state"] = voucher_state
			_record(result, "voucher_coupon", "voucher_coupon_refund")
	if _has_relic(relic_ids, "royal_voucher_press") and choice == "ticket_upgrade_voucher":
		var royal_potions: Array = result.get("potion_ids", [])
		royal_potions.append("upgrade_voucher")
		result["potion_ids"] = royal_potions
		_record(result, "royal_voucher_press", "royal_press_voucher")
	if _has_relic(relic_ids, "infinite_reroll_key") and (choice.begins_with("upgrade_") or choice == "ticket_upgrade_voucher"):
		result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) - 1
		_record(result, "infinite_reroll_key", "infinite_key_upgrade_tax")
	if _has_relic(relic_ids, "carbon_copy_coupon") and choice == "ticket_upgrade_voucher":
		if _stable_percent(result, "carbon_copy_coupon") < 10:
			var potions: Array = result.get("potion_ids", [])
			potions.append("upgrade_voucher")
			result["potion_ids"] = potions
			_record(result, "carbon_copy_coupon", "carbon_copy_voucher")
	if _has_relic(relic_ids, "voucher_forge_contract") and choice == "ticket_upgrade_voucher":
		if _stable_percent(result, "voucher_forge_contract") < 50:
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			_record(result, "voucher_forge_contract", "voucher_forge_refund")
	if _has_relic(relic_ids, "ticket_monopoly") and int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) > 0:
		result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
		_record(result, "ticket_monopoly", "ticket_monopoly_plus")
	if _has_relic(relic_ids, "lucky_jury") and int(result.get("contract_tickets_delta", result.get("ticket_delta", 0))) > 0:
		if _stable_percent(result, "lucky_jury") < 25:
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			_record(result, "lucky_jury", "lucky_jury_ticket")
	if _has_relic(relic_ids, "pocket_map") and _is_event_reward_choice(choice):
		var map_key := "pocket_map_floor_" + str(int(result.get("floor_index", 1)))
		if not bool(state.get(map_key, false)):
			result["gold_delta"] = int(result.get("gold_delta", 0)) + 2
			state[map_key] = true
			result["relic_state"] = state
			_record(result, "pocket_map", "pocket_map_gold")
	if _has_relic(relic_ids, "stamp_album") and _is_event_reward_choice(choice):
		var event_count: int = int(state.get("stamp_album_event_count", 0)) + 1
		if event_count >= 4:
			event_count = 0
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			_record(result, "stamp_album", "stamp_album_ticket")
		state["stamp_album_event_count"] = event_count
		result["relic_state"] = state
	if _has_relic(relic_ids, "dusty_shelf") and choice == "shop_offer_preview":
		result["shop_relic_offer_delta"] = int(result.get("shop_relic_offer_delta", 0)) + 1
		_record(result, "dusty_shelf", "dusty_shelf_offer")
	if _has_relic(relic_ids, "appraisal_lens") and choice == "relic_reward_preview" and reward_tier != "boss":
		result["relic_reward_option_delta"] = int(result.get("relic_reward_option_delta", 0)) + 1
		_record(result, "appraisal_lens", "appraisal_lens_option")
	if _has_relic(relic_ids, "raincheck_tag") and choice == "skip_relic_reward":
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 6
		_record(result, "raincheck_tag", "raincheck_gold")
	if _has_relic(relic_ids, "tiny_mascot") and (choice == "boss_reward" or reward_tier == "boss"):
		result["gold_delta"] = int(result.get("gold_delta", 0)) + 8
		_record(result, "tiny_mascot", "tiny_mascot_boss_gold")
	if _has_relic(relic_ids, "souvenir_keyring") and _is_event_reward_choice(choice):
		result["risk_reward_chance_delta"] = int(result.get("risk_reward_chance_delta", 0)) + 10
		_record(result, "souvenir_keyring", "souvenir_keyring_risk")
	if _has_relic(relic_ids, "boss_map_bounty") and (choice == "boss_reward_preview" or reward_tier == "boss"):
		result["boss_relic_option_delta"] = int(result.get("boss_relic_option_delta", 0)) + 1
		_record(result, "boss_map_bounty", "boss_map_option")
	if _has_relic(relic_ids, "empty_vault") and choice == "combat_reward":
		var vault_state: Dictionary = result.get("relic_state", {})
		if bool(vault_state.get("empty_vault_next_floor", false)):
			result["gold_delta"] = 0
			_record(result, "empty_vault", "empty_vault_gold_lock")

static func _apply_relic_pickup(result: Dictionary, relic_ids: Array) -> void:
	var picked_id := str(result.get("picked_relic_id", ""))
	if picked_id == "" or not relic_ids.has(picked_id):
		return
	match picked_id:
		"strawberry_chip":
			result["player_max_hp"] = int(result.get("player_max_hp", 0)) + 4
			result["player_hp"] = int(result.get("player_hp", 0)) + 4
			_record(result, "strawberry_chip", "strawberry_max_hp")
		"waffle_stub":
			result["player_max_hp"] = int(result.get("player_max_hp", 0)) + 3
			result["player_hp"] = int(result.get("player_max_hp", 0))
			_record(result, "waffle_stub", "waffle_full_heal")
		"cleric_face_coin":
			result["player_max_hp"] = int(result.get("player_max_hp", 0)) + 2
			result["player_hp"] = int(result.get("player_hp", 0)) + 2
			_record(result, "cleric_face_coin", "cleric_coin_pickup")
		"ivory_ambulance":
			result["player_max_hp"] = int(result.get("player_max_hp", 0)) + 10
			result["player_hp"] = int(result.get("player_max_hp", 0))
			_record(result, "ivory_ambulance", "ivory_ambulance_pickup")
		"tiny_house_box":
			result["player_max_hp"] = int(result.get("player_max_hp", 0)) + 3
			result["player_hp"] = int(result.get("player_hp", 0)) + 8
			result["gold_delta"] = int(result.get("gold_delta", 0)) + 20
			result["contract_tickets_delta"] = int(result.get("contract_tickets_delta", 0)) + 1
			var house_potions: Array = result.get("potion_ids", [])
			house_potions.append("upgrade_voucher")
			result["potion_ids"] = house_potions
			_record(result, "tiny_house_box", "tiny_house_bundle")
		"empty_vault":
			result["gold_delta"] = int(result.get("gold_delta", 0)) + 80
			var vault_state: Dictionary = result.get("relic_state", {})
			vault_state["empty_vault_next_floor"] = true
			result["relic_state"] = vault_state
			_record(result, "empty_vault", "empty_vault_pickup")
		_:
			pass

static func _apply_turn_start(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "paper_shield") and int(result.get("turn", 0)) == 1:
		result["player_block"] = int(result.get("player_block", 0)) + 1
		_record(result, "paper_shield", "paper_shield_block")
	if _has_relic(relic_ids, "turn_token"):
		_apply_runtime_patch(result, RuntimeBridge.apply_hook(TURN_START, result, ["turn_token"]))
	if _has_relic(relic_ids, "econ_low_gold") and int(result.get("turn", 0)) == 1 and int(result.get("cash", 0)) < 10:
		result["cash"] = int(result.get("cash", 0)) + 4
		_record(result, "econ_low_gold", "low_gold_tip")
	if _has_relic(relic_ids, "default_guard_crest"):
		var guard_crest_block: int = max(1, int(result.get("floor_index", 1)))
		result["player_block"] = int(result.get("player_block", 0)) + guard_crest_block
		_record(result, "default_guard_crest", "starting_guard_block")
	if _has_relic(relic_ids, "econ_gold_armor") and int(result.get("cash", 0)) >= 20:
		result["player_block"] = int(result.get("player_block", 0)) + 1
		_record(result, "econ_gold_armor", "gold_armor_block")
	if _has_relic(relic_ids, "def_low_hp"):
		var low_hp_state: Dictionary = result.get("relic_state", {})
		var max_hp: int = max(1, int(result.get("player_max_hp", 1)))
		if not bool(low_hp_state.get("def_low_hp_used", false)) and int(result.get("player_hp", max_hp)) * 2 <= max_hp:
			result["player_block"] = int(result.get("player_block", 0)) + 2
			low_hp_state["def_low_hp_used"] = true
			result["relic_state"] = low_hp_state
			_record(result, "def_low_hp", "low_hp_block")
	if _has_relic(relic_ids, "risk_action_cap"):
		if int(result.get("turn", 0)) <= 3:
			result["player_attack_delta"] = int(result.get("player_attack_delta", 0)) + 1
			_record(result, "risk_action_cap", "action_cap_early_attack")
		else:
			result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 1
			_record(result, "risk_action_cap", "action_cap_late_pressure")
	if _has_relic(relic_ids, "noon_duel"):
		if int(result.get("turn", 0)) <= 2:
			result["player_attack_delta"] = int(result.get("player_attack_delta", 0)) + 2
			_record(result, "noon_duel", "noon_duel_early_attack")
		else:
			result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 1
			_record(result, "noon_duel", "noon_duel_late_pressure")
	if _has_relic(relic_ids, "gambler_debt") and int(result.get("uncommitted_wager_marbles", 0)) > 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 1
		_record(result, "gambler_debt", "gambler_debt_pressure")
	if _has_relic(relic_ids, "cracked_hourglass") and int(result.get("turn", 0)) > 0 and int(result.get("turn", 0)) % 3 == 0:
		result["rerolls_left"] = int(result.get("rerolls_left", 0)) + 1
		_record(result, "cracked_hourglass", "cracked_hourglass_reroll")
	if _has_relic(relic_ids, "guard_engine_plaque"):
		result["player_block"] = int(result.get("player_block", 0)) + max(1, int(result.get("floor_index", 1)) + 2)
		_record(result, "guard_engine_plaque", "guard_engine_block")
	if _has_relic(relic_ids, "greedy_house_ledger"):
		result["cash"] = int(result.get("cash", 0)) + 2
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 1
		_record(result, "greedy_house_ledger", "greedy_ledger_turn")
	if _has_relic(relic_ids, "no_refund_contract") and int(result.get("turn", 0)) == 1 and int(result.get("player_hp", 0)) > 2:
		result["player_hp"] = int(result.get("player_hp", 0)) - 2
		result["player_damage_multiplier"] = float(result.get("player_damage_multiplier", 1.0)) + 0.25
		_record(result, "no_refund_contract", "no_refund_first_turn")
	if _has_relic(relic_ids, "sealed_side_box") and int(result.get("turn", 0)) == 1:
		result["cash"] = int(result.get("cash", 0)) + 5
		result["player_block"] = int(result.get("player_block", 0)) + 2
		_record(result, "sealed_side_box", "sealed_box_opened")
	var state: Dictionary = result.get("relic_state", {})
	if _has_relic(relic_ids, "def_after_bust") and int(state.get("def_after_bust_pending", 0)) > 0:
		var after_bust_block := int(state.get("def_after_bust_pending", 0))
		result["player_block"] = int(result.get("player_block", 0)) + after_bust_block
		state.erase("def_after_bust_pending")
		result["relic_state"] = state
		_record(result, "def_after_bust", "after_bust_block")
	if _has_relic(relic_ids, "def_marker_block") and int(state.get("def_marker_block_pending", 0)) > 0:
		var carry_block := int(state.get("def_marker_block_pending", 0))
		result["player_block"] = int(result.get("player_block", 0)) + carry_block
		state.erase("def_marker_block_pending")
		result["relic_state"] = state
		_record(result, "def_marker_block", "pinned_guard_carry")
	if _has_relic(relic_ids, "cracked_mirror") and int(state.get("cracked_mirror_pending", 0)) > 0:
		var mirror_block := int(state.get("cracked_mirror_pending", 0))
		result["player_block"] = int(result.get("player_block", 0)) + mirror_block
		state.erase("cracked_mirror_pending")
		result["relic_state"] = state
		_record(result, "cracked_mirror", "cracked_mirror_block")
	if _has_relic(relic_ids, "double_attack_crest") and int(state.get("double_attack_overheal_block_pending", 0)) > 0:
		var overheal_block := int(state.get("double_attack_overheal_block_pending", 0))
		result["player_block"] = int(result.get("player_block", 0)) + overheal_block
		state.erase("double_attack_overheal_block_pending")
		result["relic_state"] = state
		_record(result, "double_attack_crest", "overheal_block_carry")

static func _apply_dice_result(result: Dictionary, relic_ids: Array) -> void:
	var rule_id: String = str(result.get("dice_rule_id", DiceResolver.default_rule_id()))
	if _has_relic(relic_ids, "loaded_die"):
		var dice: Array[int] = DiceResolver.normalize_values(result.get("dice_values", result.get("dice", [])), rule_id)
		dice[0] = clamp(dice[0] + 1, 1, 6)
		result["dice"] = dice.duplicate()
		result["dice_values"] = dice.duplicate()
		_record(result, "loaded_die", "attack_die_plus_one")
	if _has_relic(relic_ids, "snake_eyes_charm"):
		var dice: Array[int] = DiceResolver.normalize_values(result.get("dice_values", result.get("dice", [])), rule_id)
		if dice.size() >= 2 and dice[0] == dice[1]:
			dice[0] = clamp(dice[0] + 1, 1, 6)
			result["dice"] = dice.duplicate()
			result["dice_values"] = dice.duplicate()
			_record(result, "snake_eyes_charm", "doubles_first_die_plus_one")
	if _has_relic(relic_ids, "locksmith_glove") and int(result.get("rerolls_left", 0)) <= 0:
		var dice: Array[int] = DiceResolver.normalize_values(result.get("dice_values", result.get("dice", [])), rule_id)
		if not dice.is_empty():
			dice[0] = clamp(dice[0] + 1, 1, 6)
			result["dice"] = dice.duplicate()
			result["dice_values"] = dice.duplicate()
			_record(result, "locksmith_glove", "last_reroll_die_plus_two")
	if _has_relic(relic_ids, "gamblers_last_reroll") and int(result.get("rerolls_left", 0)) <= 0:
		var gambler_dice: Array[int] = DiceResolver.normalize_values(result.get("dice_values", result.get("dice", [])), rule_id)
		var selected_index := int(result.get("selected_attack_die_index", 0))
		if selected_index < 0:
			selected_index = 0
		if selected_index < gambler_dice.size():
			gambler_dice[selected_index] = clamp(gambler_dice[selected_index] + 1, 1, 6)
			result["dice"] = gambler_dice.duplicate()
			result["dice_values"] = gambler_dice.duplicate()
			_record(result, "gamblers_last_reroll", "last_reroll_selected_die_plus_one")
	var computed: Dictionary = DiceResolver.compute_result(
		result.get("dice_values", result.get("dice", [])),
		result.get("dice_locked", []),
		rule_id,
		int(result.get("rerolls_left", 0)),
		result.get("applied_effects", []),
		int(result.get("selected_attack_die_index", -1))
	)
	for key in computed.keys():
		result[key] = computed[key]
	if _has_relic(relic_ids, "dice_low_guard") and _selected_die_value(result) <= 3:
		var base_guard := int(result.get("guard_value", 0))
		result["guard_value"] = base_guard + 3
		result["player_block"] = int(result.get("player_block", base_guard)) + 3
		_record(result, "dice_low_guard", "low_attack_guard")
	if _has_relic(relic_ids, "dice_wide_split"):
		var wide_dice: Array[int] = DiceResolver.normalize_values(result.get("dice_values", result.get("dice", [])), rule_id)
		if wide_dice.size() >= 2 and abs(wide_dice[0] - wide_dice[1]) >= 3:
			result["cash"] = int(result.get("cash", 0)) + 2
			_record(result, "dice_wide_split", "wide_split_bonus")
	if _has_relic(relic_ids, "dice_exact_four") and _selected_die_value(result) == 4:
		result["cash"] = int(result.get("cash", 0)) + 3
		_record(result, "dice_exact_four", "exact_four_gold")
	if _has_relic(relic_ids, "dice_guard_lead"):
		var guard_value := int(result.get("guard_value", 0))
		if _highest_unselected_die_value(result) > _selected_die_value(result):
			result["guard_value"] = guard_value + 2
			result["player_block"] = int(result.get("player_block", guard_value)) + 2
			_record(result, "dice_guard_lead", "guard_lead_block")
	if _has_relic(relic_ids, "even_keel") and _dice_total(result) % 2 == 0:
		var even_guard := int(result.get("guard_value", 0))
		result["guard_value"] = even_guard + 1
		result["player_block"] = int(result.get("player_block", even_guard)) + 1
		_record(result, "even_keel", "even_keel_block")
	if _has_relic(relic_ids, "split_tip") and _dice_gap(result) == 1:
		result["cash"] = int(result.get("cash", 0)) + 2
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 2
		_record(result, "split_tip", "split_tip_gold")
	if _has_relic(relic_ids, "snake_receipt") and _dice_are_double(result):
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		_record(result, "snake_receipt", "snake_receipt_gold")
	if _has_relic(relic_ids, "bent_coin") and _selected_die_value(result) <= 2:
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		_record(result, "bent_coin", "bent_coin_gold")
	if _has_relic(relic_ids, "brass_reroll_key") and int(result.get("rerolls_left", 0)) <= 0 and _dice_total(result) >= 7:
		result["cash"] = int(result.get("cash", 0)) + 2
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 2
		_record(result, "brass_reroll_key", "brass_key_gold")

static func _apply_marble_gain(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "loaded_die"):
		_record(result, "loaded_die", "attack_payload_tagged")
	if _has_relic(relic_ids, "marker_thimble") and _selected_die_value(result) <= 1:
		_add_plain_marble(result)
		_record(result, "marker_thimble", "thimble_extra_marble")
	if _has_relic(relic_ids, "high_roller_lint") and _dice_total(result) >= 10:
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		_record(result, "high_roller_lint", "high_roller_lint_gold")
	if _has_relic(relic_ids, "dice_under_six") and _dice_total(result) < 6:
		var low_marbles: Array = result.get("marbles", [])
		if low_marbles.is_empty():
			low_marbles.append("plain")
		low_marbles.append("plain")
		result["marbles"] = low_marbles
		result["marble_count"] = max(int(result.get("marble_count", 1)) + 1, low_marbles.size())
		_record(result, "dice_under_six", "low_total_extra_marker")
	if _has_relic(relic_ids, "twin_marker") and _dice_total(result) >= 9:
		_add_plain_marble(result)
		_record(result, "twin_marker", "strong_attack_extra_marker")
	if _has_relic(relic_ids, "lucky_low_marble") and _selected_die_value(result) <= 2:
		_add_plain_marble(result)
		_record(result, "lucky_low_marble", "lucky_low_extra_marker")
	if _has_relic(relic_ids, "gamblers_spare_marble") and _dice_are_double(result):
		_add_plain_marble(result)
		_record(result, "gamblers_spare_marble", "spare_marble_double")
	if _has_relic(relic_ids, "gamblers_odd_eye") and _dice_has_odd_even(result):
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		_record(result, "gamblers_odd_eye", "odd_eye_paid")
	if _has_relic(relic_ids, "marble_savant_charm") and _dice_total(result) >= 10:
		_add_plain_marble(result)
		_record(result, "marble_savant_charm", "savant_extra_marble")

static func _apply_roulette_before_spin(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "second_chance"):
		if _is_numeric_payload(result):
			result["numeric_extra_go_chances"] = int(result.get("numeric_extra_go_chances", 0)) + 1
		else:
			result["roulette_respins_left"] = int(result.get("roulette_respins_left", result.get("respins_left", 1))) + 1
		_record(result, "second_chance", "roulette_respin_plus_one")
	if _has_relic(relic_ids, "house_edge_crown"):
		result["jackpot_weight_delta"] = int(result.get("jackpot_weight_delta", 0)) + 1
		result["overdrive_weight_delta"] = int(result.get("overdrive_weight_delta", 0)) + 1
		result["bust_weight_delta"] = int(result.get("bust_weight_delta", 0)) + 1
		_record(result, "house_edge_crown", "house_edge_crown_weights")
	if _has_relic(relic_ids, "velvet_choker_chip"):
		result["numeric_extra_go_chances"] = int(result.get("numeric_extra_go_chances", 0)) + 1
		result["numeric_go_per_turn_cap"] = 1
		_record(result, "velvet_choker_chip", "velvet_choker_go")

static func _apply_roulette_after_spin(result: Dictionary, relic_ids: Array) -> void:
	if _is_numeric_payload(result):
		if _has_relic(relic_ids, "marker_adjacent") and _numeric_marked(result) and _numeric_is_even(result):
			result["cash"] = int(result.get("cash", 0)) + 2
			result["cash_delta"] = int(result.get("cash_delta", 0)) + 2
			_record(result, "marker_adjacent", "adjacent_mark_gold")
		return
	if _has_relic(relic_ids, "marker_adjacent") and _landed_adjacent_to_mark(result):
		result["cash"] = int(result.get("cash", 0)) + 2
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 2
		_record(result, "marker_adjacent", "adjacent_mark_gold")

static func _apply_resolution_before(result: Dictionary, relic_ids: Array) -> void:
	if _is_numeric_payload(result):
		_apply_numeric_resolution_before(result, relic_ids)
		return
	if _has_relic(relic_ids, "green_purse") and _landed_marked_slot(result, "profit"):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 4
		_record(result, "green_purse", "green_cash_bonus")
	if _has_relic(relic_ids, "wheel_profit_tithe") and str(result.get("pending_slot", "")) == "profit":
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + (4 if _marked_slot(result.get("placed_slots", {}), "profit") else 2)
		_record(result, "wheel_profit_tithe", "profit_tithe_gold")
	if _has_relic(relic_ids, "yellow_guard") and _landed_marked_slot(result, "safe"):
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - 2
		_record(result, "yellow_guard", "marked_hit_guard")
	if _has_relic(relic_ids, "purple_contract") and _landed_marked_slot(result, "jackpot"):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.35
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "purple_contract", "marked_jackpot_multiplier")
	if _has_relic(relic_ids, "blue_chisel") and _landed_marked_slot(result, "overdrive"):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
		_record(result, "blue_chisel", "marked_overdrive_flat_damage")
	if _has_relic(relic_ids, "wheel_overdrive_pin") and str(result.get("pending_slot", "")) == "overdrive":
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
		_record(result, "wheel_overdrive_pin", "overdrive_pin_flat_damage")
	if _has_relic(relic_ids, "def_no_block") and int(result.get("player_block", 0)) <= 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - 3
		_record(result, "def_no_block", "empty_guard_block")
	if _has_relic(relic_ids, "marker_first_hit") and _landed_on_any_mark(result):
		var state: Dictionary = result.get("relic_state", {})
		if not bool(state.get("marker_first_hit_used", false)):
			result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 3
			state["marker_first_hit_used"] = true
			result["relic_state"] = state
			_record(result, "marker_first_hit", "first_mark_flat_damage")
	if _has_relic(relic_ids, "def_marker_block") and _landed_marked_slot(result, "safe"):
		var state: Dictionary = result.get("relic_state", {})
		state["def_marker_block_pending"] = int(state.get("def_marker_block_pending", 0)) + 2
		result["relic_state"] = state
		_record(result, "def_marker_block", "pinned_guard_set")
	if _has_relic(relic_ids, "marker_repeat_slot") and _landed_on_any_mark(result):
		var state: Dictionary = result.get("relic_state", {})
		var pending_slot := str(result.get("pending_slot", ""))
		if int(state.get("marked_count_" + pending_slot, 0)) >= 3:
			result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.5
			result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
			_record(result, "marker_repeat_slot", "repeat_slot_multiplier")
	_apply_attack_pressure_relics(result, relic_ids)

static func _apply_numeric_resolution_before(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "green_purse") and _numeric_marked(result) and _numeric_is_profit(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 4
		_record(result, "green_purse", "green_cash_bonus")
	if _has_relic(relic_ids, "wheel_profit_tithe") and _numeric_is_profit(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + (4 if _numeric_marked(result) else 2)
		_record(result, "wheel_profit_tithe", "profit_tithe_gold")
	if _has_relic(relic_ids, "yellow_guard") and _numeric_marked(result) and _numeric_is_safe(result):
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - 2
		_record(result, "yellow_guard", "marked_hit_guard")
	if _has_relic(relic_ids, "purple_contract") and _numeric_marked(result) and _numeric_is_jackpot(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.35
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "purple_contract", "marked_jackpot_multiplier")
	if _has_relic(relic_ids, "blue_chisel") and _numeric_marked(result) and _numeric_is_overdrive(result):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
		_record(result, "blue_chisel", "marked_overdrive_flat_damage")
	if _has_relic(relic_ids, "wheel_overdrive_pin") and _numeric_is_overdrive(result):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
		_record(result, "wheel_overdrive_pin", "overdrive_pin_flat_damage")
	if _has_relic(relic_ids, "def_no_block") and int(result.get("player_block", 0)) <= 0:
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - 3
		_record(result, "def_no_block", "empty_guard_block")
	if _has_relic(relic_ids, "marker_first_hit") and _numeric_marked(result) and _numeric_multiplier(result) > 0.0:
		var state: Dictionary = result.get("relic_state", {})
		if not bool(state.get("marker_first_hit_used", false)):
			result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 3
			state["marker_first_hit_used"] = true
			result["relic_state"] = state
			_record(result, "marker_first_hit", "first_mark_flat_damage")
	if _has_relic(relic_ids, "def_marker_block") and _numeric_marked(result) and _numeric_is_safe(result):
		var state: Dictionary = result.get("relic_state", {})
		state["def_marker_block_pending"] = int(state.get("def_marker_block_pending", 0)) + 2
		result["relic_state"] = state
		_record(result, "def_marker_block", "pinned_guard_set")
	if _has_relic(relic_ids, "marker_repeat_slot") and _numeric_marked(result) and int(result.get("wager_marbles_committed", 0)) >= 3:
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.5
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "marker_repeat_slot", "repeat_slot_multiplier")
	_apply_attack_pressure_relics(result, relic_ids)

static func _apply_numeric_resolution_after(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "bust_insurance") and _numeric_is_bust(result) and _numeric_marked(result):
		var state: Dictionary = result.get("relic_state", {})
		if not bool(state.get("bust_insurance_used", false)):
			result["player_block"] = int(result.get("player_block", 0)) + 4
			state["bust_insurance_used"] = true
			result["relic_state"] = state
			result["message"] = str(result.get("message", "")) + " Bust Insurance banks 4 block."
			_record(result, "bust_insurance", "bust_delta_cancelled")
	if _has_relic(relic_ids, "marker_miss_gold") and _numeric_marked(result) and int(result.get("damage", 0)) <= 0:
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		result["message"] = str(result.get("message", "")) + " Misread Oracle Tag pays +$1."
		_record(result, "marker_miss_gold", "marked_miss_gold")
	if _has_relic(relic_ids, "def_after_bust") and _numeric_is_bust(result):
		var state: Dictionary = result.get("relic_state", {})
		state["def_after_bust_pending"] = 3
		result["relic_state"] = state
		_record(result, "def_after_bust", "after_bust_set")
	if _has_relic(relic_ids, "zero_receipt") and _numeric_is_bust(result):
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		_record(result, "zero_receipt", "zero_receipt_gold")
static func _apply_resolution_after(result: Dictionary, relic_ids: Array) -> void:
	if _is_numeric_payload(result):
		_apply_numeric_resolution_after(result, relic_ids)
	elif _has_relic(relic_ids, "bust_insurance") and int(result.get("bust_delta", 0)) > 0:
		result["bust_delta"] = 0
		result["player_hp"] = int(result.get("player_hp", 0)) + 2
		result["message"] = str(result.get("message", "")) + " Bust Insurance absorbs the worst hit."
		_record(result, "bust_insurance", "bust_delta_cancelled")
	if _has_relic(relic_ids, "last_call_bell") and int(result.get("enemy_hp", 1)) <= 0 and int(result.get("damage", 0)) > 0:
		result["cash"] = int(result.get("cash", 0)) + 8
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 8
		result["message"] = str(result.get("message", "")) + " Last Call Bell rings +$8."
		_record(result, "last_call_bell", "victory_cash_bonus")
	if (not _is_numeric_payload(result)
			and _has_relic(relic_ids, "marker_miss_gold")
			and _has_any_mark(result.get("placed_slots", {}))
			and not RouletteSlotCatalog.has_placed_token(result.get("placed_slots", {}), str(result.get("pending_slot", "")))):
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		result["message"] = str(result.get("message", "")) + " Misread Oracle Tag pays +$1."
		_record(result, "marker_miss_gold", "marked_miss_gold")
	if not _is_numeric_payload(result) and _has_relic(relic_ids, "def_after_bust") and int(result.get("bust_delta", 0)) > 0:
		var state: Dictionary = result.get("relic_state", {})
		state["def_after_bust_pending"] = 3
		result["relic_state"] = state
		_record(result, "def_after_bust", "after_bust_set")
	if not _is_numeric_payload(result) and _has_relic(relic_ids, "zero_receipt") and int(result.get("bust_delta", 0)) > 0:
		result["cash"] = int(result.get("cash", 0)) + 1
		result["cash_delta"] = int(result.get("cash_delta", 0)) + 1
		_record(result, "zero_receipt", "zero_receipt_gold")
	if _has_relic(relic_ids, "cracked_mirror") and _is_go_collapse(result):
		var mirror_state: Dictionary = result.get("relic_state", {})
		mirror_state["cracked_mirror_pending"] = 3
		result["relic_state"] = mirror_state
		_record(result, "cracked_mirror", "cracked_mirror_set")
	if _has_relic(relic_ids, "lucky_jury") and _is_bust_outcome(result) and int(result.get("cash", 0)) > 0:
		var loss: int = min(2, int(result.get("cash", 0)))
		result["cash"] = int(result.get("cash", 0)) - loss
		result["cash_delta"] = int(result.get("cash_delta", 0)) - loss
		_record(result, "lucky_jury", "lucky_jury_bust_tax")
	if _has_relic(relic_ids, "cursed_players_red_marble") and int(result.get("damage", 0)) > 0 and _selected_die_value(result) >= 5:
		_heal_player(result, 2)
		_record(result, "cursed_players_red_marble", "red_marble_lifesteal")
	if _has_relic(relic_ids, "double_attack_crest") and int(result.get("damage", 0)) > 0:
		var healing: int = max(1, int(ceil(float(int(result.get("damage", 0))) * 0.1)))
		if _is_jackpot_outcome(result):
			healing *= 2
		var max_hp: int = int(result.get("player_max_hp", 0))
		var current_hp: int = int(result.get("player_hp", 0))
		var actual_healing := healing
		if max_hp > 0:
			var next_hp: int = min(max_hp, current_hp + healing)
			actual_healing = max(0, next_hp - current_hp)
			var overheal: int = max(0, current_hp + healing - max_hp)
			if overheal > 0:
				var state: Dictionary = result.get("relic_state", {})
				state["double_attack_overheal_block_pending"] = int(state.get("double_attack_overheal_block_pending", 0)) + overheal
				result["relic_state"] = state
				_record(result, "double_attack_crest", "overheal_block_set")
			result["player_hp"] = next_hp
		else:
			result["player_hp"] = current_hp + healing
		result["hp_delta"] = int(result.get("hp_delta", 0)) + actual_healing
		_record(result, "double_attack_crest", "starting_lifesteal")
static func _apply_damage_taken(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "default_guard_crest") and result.has("enemy_hp") and int(result.get("incoming_damage", 0)) > 0:
		var counter_damage: int = max(0, int(result.get("player_block", 0)))
		if counter_damage > 0:
			result["enemy_hp"] = max(0, int(result.get("enemy_hp", 0)) - counter_damage)
			result["guard_counter_damage"] = int(result.get("guard_counter_damage", 0)) + counter_damage
			_record(result, "default_guard_crest", "guard_counter_damage")
	if _has_relic(relic_ids, "def_first_hit") and int(result.get("damage", 0)) > 0:
		var state: Dictionary = result.get("relic_state", {})
		if not bool(state.get("def_first_hit_used", false)):
			var prevented: int = min(4, int(result.get("damage", 0)))
			result["damage"] = int(result.get("damage", 0)) - prevented
			result["player_hp"] = int(result.get("player_hp", 0)) + prevented
			state["def_first_hit_used"] = true
			result["relic_state"] = state
			_record(result, "def_first_hit", "first_hit_prevented")
	if _has_relic(relic_ids, "tiny_bandage") and int(result.get("damage", 0)) > 0:
		var bandage_state: Dictionary = result.get("relic_state", {})
		if not bool(bandage_state.get("tiny_bandage_used", false)):
			var bandaged: int = min(2, int(result.get("damage", 0)))
			result["damage"] = int(result.get("damage", 0)) - bandaged
			result["player_hp"] = int(result.get("player_hp", 0)) + bandaged
			bandage_state["tiny_bandage_used"] = true
			result["relic_state"] = bandage_state
			_record(result, "tiny_bandage", "tiny_bandage_prevented")
	if _has_relic(relic_ids, "thorn_chip") and int(result.get("damage", 0)) > 0 and result.has("enemy_hp"):
		var thorn_state: Dictionary = result.get("relic_state", {})
		if not bool(thorn_state.get("thorn_chip_used", false)):
			result["enemy_hp"] = max(0, int(result.get("enemy_hp", 0)) - 3)
			result["thorn_chip_damage"] = int(result.get("thorn_chip_damage", 0)) + 3
			thorn_state["thorn_chip_used"] = true
			result["relic_state"] = thorn_state
			_record(result, "thorn_chip", "thorn_chip_counter")
	if _has_relic(relic_ids, "cheap_insurance_stub") and int(result.get("damage", 0)) > 0:
		var cheap_state: Dictionary = result.get("relic_state", {})
		if not bool(cheap_state.get("cheap_insurance_used", false)):
			var cheap_prevented: int = min(2, int(result.get("damage", 0)))
			result["damage"] = int(result.get("damage", 0)) - cheap_prevented
			result["player_hp"] = int(result.get("player_hp", 0)) + cheap_prevented
			cheap_state["cheap_insurance_used"] = true
			result["relic_state"] = cheap_state
			_record(result, "cheap_insurance_stub", "cheap_insurance_prevented")
	if _has_relic(relic_ids, "spare_heel") and int(result.get("damage", 0)) >= 6:
		var heel_state: Dictionary = result.get("relic_state", {})
		if not bool(heel_state.get("spare_heel_used", false)):
			result["damage"] = int(result.get("damage", 0)) - 1
			result["player_hp"] = int(result.get("player_hp", 0)) + 1
			heel_state["spare_heel_used"] = true
			result["relic_state"] = heel_state
			_record(result, "spare_heel", "spare_heel_prevented")
	if _has_relic(relic_ids, "glass_jackpot") and int(result.get("damage", 0)) > 0:
		var extra_damage: int = int(ceil(float(int(result.get("damage", 0))) * 0.25))
		if extra_damage > 0:
			result["damage"] = int(result.get("damage", 0)) + extra_damage
			result["player_hp"] = max(0, int(result.get("player_hp", 0)) - extra_damage)
			result["glass_jackpot_extra_damage"] = int(result.get("glass_jackpot_extra_damage", 0)) + extra_damage
			_record(result, "glass_jackpot", "glass_jackpot_fragility")

static func _apply_combat_finish(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "econ_interest") and bool(result.get("victory", false)) and int(result.get("cash", result.get("combat_cash", 0))) >= 20:
		result["cash"] = int(result.get("cash", 0)) + 4
		result["combat_cash"] = int(result.get("combat_cash", result.get("cash", 0))) + 4
		result["winnings"] = int(result.get("winnings", result.get("cash", 0))) + 4
		_record(result, "econ_interest", "interest_token_gold")
	if bool(result.get("victory", false)) and _has_relic(relic_ids, "risk_last_hand") and _turn_number(result) <= 2:
		_heal_player(result, 4)
		_record(result, "risk_last_hand", "last_hand_heal")
	if bool(result.get("victory", false)) and _has_relic(relic_ids, "risk_rare_pull") and _turn_number(result) <= 1:
		result["cash"] = int(result.get("cash", 0)) + 10
		result["combat_cash"] = int(result.get("combat_cash", result.get("cash", 0))) + 10
		result["winnings"] = int(result.get("winnings", result.get("cash", 0))) + 10
		_record(result, "risk_rare_pull", "calling_bell_gold")
	if bool(result.get("victory", false)) and _has_relic(relic_ids, "econ_shop_heal") and int(result.get("cash", result.get("combat_cash", 0))) >= 25:
		_heal_player(result, 2)
		_record(result, "econ_shop_heal", "shop_meal_heal")
static func _has_relic(relic_ids: Array, id: String) -> bool:
	return relic_ids.has(id) and RelicCatalog.has_relic(id)

static func _record(payload: Dictionary, relic_id: String, effect_id: String) -> void:
	var effects: Array = _effects(payload)
	effects.append({
		"relic_id": relic_id,
		"effect_id": effect_id,
		"name": RelicCatalog.display_name(relic_id)
	})
	payload["applied_effects"] = effects

static func _apply_runtime_patch(result: Dictionary, patch: Dictionary) -> void:
	for key in patch.keys():
		result[key] = patch[key]

static func _effects(payload: Dictionary) -> Array:
	var effects: Array = []
	for item in payload.get("applied_effects", []):
		effects.append(item)
	return effects

static func _shop_result_has_purchase(payload: Dictionary) -> bool:
	if int(payload.get("gold_delta", 0)) < 0:
		return true
	if not (payload.get("relic_ids", []) as Array).is_empty():
		return true
	if not (payload.get("potion_ids", []) as Array).is_empty():
		return true
	if not (payload.get("next_combat_mods", []) as Array).is_empty():
		return true
	if not (payload.get("run_upgrades", {}) as Dictionary).is_empty():
		return true
	return false

static func _is_event_reward_choice(choice: String) -> bool:
	if choice == "":
		return false
	var blocked: Array[String] = [
		"combat_reward",
		"elite_reward",
		"shop_leave",
		"shop_reroll",
		"ticket_upgrade_voucher",
		"ticket_small_heal",
		"ticket_random_potion",
		"ticket_random_relic"
	]
	if blocked.has(choice):
		return false
	if choice.begins_with("rest_") or choice.begins_with("upgrade_") or choice.begins_with("shop_") or choice.begins_with("ticket_"):
		return false
	return true

static func _dice_total(payload: Dictionary) -> int:
	var total := 0
	for value in _raw_dice_values(payload):
		total += int(value)
	return total

static func _raw_dice_values(payload: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var values: Variant = payload.get("dice_values", payload.get("dice", []))
	if values is Array:
		for value in values:
			result.append(int(value))
	return result

static func _selected_die_value(payload: Dictionary) -> int:
	var dice := _raw_dice_values(payload)
	var index := int(payload.get("selected_attack_die_index", 0))
	if index < 0:
		index = 0
	if index >= 0 and index < dice.size():
		return int(dice[index])
	return int(payload.get("attack_base", 0))

static func _highest_unselected_die_value(payload: Dictionary) -> int:
	var dice := _raw_dice_values(payload)
	var selected_index := int(payload.get("selected_attack_die_index", -1))
	if selected_index < 0 or selected_index >= dice.size():
		return 0
	var highest := 0
	for i in range(dice.size()):
		if i != selected_index:
			highest = max(highest, int(dice[i]))
	return highest

static func _dice_are_double(payload: Dictionary) -> bool:
	var dice := _raw_dice_values(payload)
	return dice.size() >= 2 and int(dice[0]) == int(dice[1])

static func _dice_has_odd_even(payload: Dictionary) -> bool:
	var dice := _raw_dice_values(payload)
	if dice.size() < 2:
		return false
	var first_even := int(dice[0]) % 2 == 0
	var second_even := int(dice[1]) % 2 == 0
	return first_even != second_even

static func _add_plain_marble(payload: Dictionary) -> void:
	var marbles: Array = payload.get("marbles", [])
	if marbles.is_empty():
		marbles.append("plain")
	marbles.append("plain")
	payload["marbles"] = marbles
	payload["marble_count"] = max(int(payload.get("marble_count", 1)) + 1, marbles.size())

static func _heal_player(payload: Dictionary, amount: int) -> void:
	if amount <= 0:
		return
	var current_hp := int(payload.get("player_hp", 0))
	var max_hp := int(payload.get("player_max_hp", 0))
	var next_hp := current_hp + amount
	if max_hp > 0:
		next_hp = min(max_hp, next_hp)
	payload["player_hp"] = next_hp
	payload["hp_delta"] = int(payload.get("hp_delta", 0)) + max(0, next_hp - current_hp)

static func _turn_number(payload: Dictionary) -> int:
	if payload.has("turn"):
		return int(payload.get("turn", 999))
	return int(payload.get("turns", 999))

static func _stable_percent(payload: Dictionary, salt: String) -> int:
	var forced_key := "forced_percent_" + salt
	if payload.has(forced_key):
		return clampi(int(payload.get(forced_key, 0)), 0, 99)
	var text := str(payload.get("seed_text", "relic")) + "|" + str(payload.get("choice", "")) + "|" + salt + "|" + str(payload.get("reward_index", payload.get("map_step", 0)))
	var value := 0
	for i in range(text.length()):
		value = int((value * 31 + text.unicode_at(i)) % 2147483647)
	return value % 100

static func _apply_attack_pressure_relics(result: Dictionary, relic_ids: Array) -> void:
	if _has_relic(relic_ids, "house_edge_receipt") and _is_normal_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 1
		_record(result, "house_edge_receipt", "house_edge_gold")
	if _has_relic(relic_ids, "wheel_adjacent_pay") and _is_normal_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 2
		_record(result, "wheel_adjacent_pay", "neighbor_cut_gold")
	if _has_relic(relic_ids, "wheel_black_stop") and _is_low_safe_outcome(result):
		result["player_block"] = int(result.get("player_block", 0)) + 1
		_record(result, "wheel_black_stop", "black_stop_block")
	if _has_relic(relic_ids, "umbrella_button") and _is_low_safe_outcome(result):
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) - 1
		_record(result, "umbrella_button", "umbrella_button_soften")
	if _has_relic(relic_ids, "overdrive_confetti") and _is_overdrive_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 1
		_record(result, "overdrive_confetti", "overdrive_confetti_gold")
	if _has_relic(relic_ids, "lazy_susan") and _is_normal_outcome(result) and _wager_count(result) <= 0:
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 2
		_record(result, "lazy_susan", "lazy_susan_gold")
	if _has_relic(relic_ids, "marker_unmarked_hit") and _wager_count(result) <= 0 and not _is_bust_outcome(result):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 1
		_record(result, "marker_unmarked_hit", "unmarked_hit_damage")
	if _has_relic(relic_ids, "low_stakes_mat") and _wager_count(result) <= 1 and not _is_bust_outcome(result):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 1
		_record(result, "low_stakes_mat", "low_stakes_flat")
	if _has_relic(relic_ids, "odd_charm") and _dice_total(result) % 2 != 0:
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 1
		_record(result, "odd_charm", "odd_charm_flat_damage")
	if _has_relic(relic_ids, "wager_padding") and _wager_count(result) >= 2:
		result["player_block"] = int(result.get("player_block", 0)) + 1
		_record(result, "wager_padding", "wager_padding_block")
	if _has_relic(relic_ids, "brass_stopwatch") and _is_stop_action(result) and _is_normal_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 2
		_record(result, "brass_stopwatch", "brass_stopwatch_gold")
	if _has_relic(relic_ids, "cautious_pin") and _is_stop_action(result) and _is_low_safe_outcome(result):
		result["player_block"] = int(result.get("player_block", 0)) + 2
		_record(result, "cautious_pin", "cautious_pin_block")
	if _has_relic(relic_ids, "redline_tag") and _is_go_success(result):
		var redline_state: Dictionary = result.get("relic_state", {})
		if not bool(redline_state.get("redline_tag_used", false)):
			result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
			redline_state["redline_tag_used"] = true
			result["relic_state"] = redline_state
			_record(result, "redline_tag", "redline_tag_flat")
	if _has_relic(relic_ids, "red_letter_lease") and _is_go_success(result):
		var lease_state: Dictionary = result.get("relic_state", {})
		if not bool(lease_state.get("red_letter_lease_used", false)):
			result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 5
			lease_state["red_letter_lease_used"] = true
			result["relic_state"] = lease_state
			_record(result, "red_letter_lease", "red_letter_go_gold")
	if _has_relic(relic_ids, "red_letter_lease") and _is_go_collapse(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) - min(4, int(result.get("cash", 0)))
		_record(result, "red_letter_lease", "red_letter_collapse_tax")
	if _has_relic(relic_ids, "all_in_badge") and _is_all_in_wager(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.5
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "all_in_badge", "all_in_badge_multiplier")
	if _has_relic(relic_ids, "jackpot_knife") and _is_jackpot_outcome(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.75
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "jackpot_knife", "jackpot_knife_multiplier")
	if _has_relic(relic_ids, "cracked_scepter") and _is_jackpot_outcome(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.7
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "cracked_scepter", "cracked_scepter_jackpot")
	if _has_relic(relic_ids, "cracked_scepter") and _is_bust_outcome(result):
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 2
		_record(result, "cracked_scepter", "cracked_scepter_bust_pressure")
	if _has_relic(relic_ids, "double_or_debt") and _is_jackpot_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 8
		_record(result, "double_or_debt", "double_or_debt_jackpot_gold")
	if _has_relic(relic_ids, "double_or_debt") and _is_bust_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) - min(4, int(result.get("cash", 0)))
		_record(result, "double_or_debt", "double_or_debt_bust_debt")
	if _has_relic(relic_ids, "glass_jackpot") and _is_jackpot_outcome(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 1.0
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "glass_jackpot", "glass_jackpot_multiplier")
	if _has_relic(relic_ids, "jackpot_sparkler") and _is_jackpot_outcome(result):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 1
		_record(result, "jackpot_sparkler", "jackpot_sparkler_flat")
	if _has_relic(relic_ids, "black_candle_bet") and (_is_overdrive_outcome(result) or _is_jackpot_outcome(result)):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.3
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "black_candle_bet", "black_candle_burn")
	if _has_relic(relic_ids, "black_candle_bet") and _is_bust_outcome(result) and int(result.get("player_hp", 0)) > 1:
		result["player_hp"] = int(result.get("player_hp", 0)) - 1
		result["hp_delta"] = int(result.get("hp_delta", 0)) - 1
		_record(result, "black_candle_bet", "black_candle_bust_cost")
	if _has_relic(relic_ids, "debt_blood_quill") and not _is_bust_outcome(result) and int(result.get("player_hp", 0)) > 2:
		result["player_hp"] = int(result.get("player_hp", 0)) - 1
		result["hp_delta"] = int(result.get("hp_delta", 0)) - 1
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.2
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "debt_blood_quill", "blood_quill_paid")
	if _has_relic(relic_ids, "risk_bust_power") and _is_bust_outcome(result):
		result["cash_delta_bonus"] = int(result.get("cash_delta_bonus", 0)) + 4
		result["enemy_damage_delta"] = int(result.get("enemy_damage_delta", 0)) + 2
		_record(result, "risk_bust_power", "bust_power_debt")
	if _has_relic(relic_ids, "risk_no_safe") and _is_low_safe_outcome(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 0.5))) + 0.25
		result["payout_multiplier"] = float(result.get("damage_multiplier", 0.75))
		result["player_block"] = 0
		_record(result, "risk_no_safe", "no_safe_low_boost")
	if _has_relic(relic_ids, "heavy_crown_die") and _is_jackpot_outcome(result):
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.5
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "heavy_crown_die", "heavy_crown_jackpot")
	if _has_relic(relic_ids, "heavy_crown_die") and _selected_die_value(result) >= 5 and not _is_bust_outcome(result):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 1
		_record(result, "heavy_crown_die", "heavy_crown_die_flat")
	if _has_relic(relic_ids, "wheel_jackpot_blood") and _is_jackpot_outcome(result) and int(result.get("player_hp", 0)) > 2:
		result["player_hp"] = int(result.get("player_hp", 0)) - 2
		result["hp_delta"] = int(result.get("hp_delta", 0)) - 2
		result["damage_multiplier"] = float(result.get("damage_multiplier", result.get("payout_multiplier", 1.0))) + 0.6
		result["payout_multiplier"] = float(result.get("damage_multiplier", 1.0))
		_record(result, "wheel_jackpot_blood", "blood_jackpot_paid")
	if _has_relic(relic_ids, "cursed_players_split_tooth") and _dice_total(result) >= 9:
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
		_record(result, "cursed_players_split_tooth", "split_tooth_flat_damage")
	if _has_relic(relic_ids, "cursed_players_pain_bell"):
		var max_hp: int = max(1, int(result.get("player_max_hp", 1)))
		var player_hp: int = int(result.get("player_hp", max_hp))
		var bonus: int = 0
		if player_hp * 4 <= max_hp:
			bonus = 4
		elif player_hp * 2 <= max_hp:
			bonus = 2
		if bonus > 0:
			result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + bonus
			_record(result, "cursed_players_pain_bell", "pain_bell_low_hp")
	if _has_relic(relic_ids, "roulette_savant_pin") and _selected_die_value(result) >= 6 and (_is_jackpot_outcome(result) or _is_overdrive_outcome(result)):
		result["flat_damage_bonus"] = int(result.get("flat_damage_bonus", 0)) + 2
		_record(result, "roulette_savant_pin", "roulette_savant_pin")

static func _is_elite_encounter(payload: Dictionary) -> bool:
	return bool(payload.get("is_elite", false)) or str(payload.get("monster_tier", payload.get("encounter_tier", ""))) == "elite" or str(payload.get("node_type", "")) == "elite"

static func _shop_result_has_relic_purchase(payload: Dictionary) -> bool:
	return not (payload.get("relic_ids", []) as Array).is_empty()

static func _is_stop_action(payload: Dictionary) -> bool:
	return bool(payload.get("stopped", false)) or str(payload.get("roulette_action", payload.get("action", ""))) == "stop"

static func _is_go_success(payload: Dictionary) -> bool:
	if bool(payload.get("go_success", false)):
		return true
	var action := str(payload.get("roulette_action", payload.get("action", "")))
	return action == "go" and not _is_bust_outcome(payload)

static func _is_go_collapse(payload: Dictionary) -> bool:
	return bool(payload.get("go_collapsed", false)) or (str(payload.get("roulette_action", payload.get("action", ""))) == "go" and _is_bust_outcome(payload))

static func _is_all_in_wager(payload: Dictionary) -> bool:
	var committed := _wager_count(payload)
	var available := int(payload.get("wager_marbles_available", committed))
	return available > 0 and committed >= available

static func _is_numeric_payload(payload: Dictionary) -> bool:
	return str(payload.get("combat_core", payload.get("outcome_mode", ""))) == "numeric_roulette" or payload.has("roulette_multiplier")

static func _is_normal_outcome(payload: Dictionary) -> bool:
	if _is_numeric_payload(payload):
		return _numeric_is_even(payload)
	return str(payload.get("pending_slot", "")) == "safe"

static func _is_low_safe_outcome(payload: Dictionary) -> bool:
	if _is_numeric_payload(payload):
		return _numeric_is_safe(payload)
	return false

static func _numeric_multiplier(payload: Dictionary) -> float:
	return float(payload.get("roulette_multiplier", 1.0))

static func _numeric_wager_multiplier(payload: Dictionary) -> float:
	return float(payload.get("wager_multiplier", 1.0 + float(clampi(int(payload.get("wager_marbles_committed", 0)), 0, 4)) * 0.25))

static func _numeric_marked(payload: Dictionary) -> bool:
	return int(payload.get("wager_marbles_committed", 0)) > 0

static func _numeric_is_bust(payload: Dictionary) -> bool:
	return _numeric_multiplier(payload) <= 0.001

static func _numeric_is_safe(payload: Dictionary) -> bool:
	return abs(_numeric_multiplier(payload) - 0.5) <= 0.001

static func _numeric_is_even(payload: Dictionary) -> bool:
	return abs(_numeric_multiplier(payload) - 1.0) <= 0.001

static func _numeric_is_profit(payload: Dictionary) -> bool:
	var value := _numeric_multiplier(payload)
	return value >= 1.5 and value < 3.0

static func _numeric_is_overdrive(payload: Dictionary) -> bool:
	return _numeric_is_profit(payload)

static func _numeric_is_jackpot(payload: Dictionary) -> bool:
	return _numeric_multiplier(payload) >= 3.0

static func _is_jackpot_outcome(payload: Dictionary) -> bool:
	if _is_numeric_payload(payload):
		return _numeric_is_jackpot(payload)
	return str(payload.get("pending_slot", "")) == "jackpot"

static func _is_overdrive_outcome(payload: Dictionary) -> bool:
	if _is_numeric_payload(payload):
		return _numeric_is_overdrive(payload)
	return str(payload.get("pending_slot", "")) == "overdrive"

static func _is_bust_outcome(payload: Dictionary) -> bool:
	if _is_numeric_payload(payload):
		return _numeric_is_bust(payload)
	return str(payload.get("pending_slot", "")) == "bust"

static func _set_numeric_roulette_multiplier(payload: Dictionary, multiplier: float) -> void:
	payload["roulette_multiplier"] = multiplier
	payload["damage_multiplier"] = max(0.0, multiplier) * _numeric_wager_multiplier(payload)
	payload["payout_multiplier"] = payload["damage_multiplier"]

static func _landed_marked_slot(payload: Dictionary, slot_id: String) -> bool:
	if str(payload.get("pending_slot", "")) != slot_id:
		return false
	return _marked_slot(payload.get("placed_slots", {}), slot_id)

static func _marked_slot(placed_slots: Variant, slot_id: String) -> bool:
	if not placed_slots is Dictionary:
		return false
	var arr: Array = (placed_slots as Dictionary).get(slot_id, [])
	return arr.size() > 0

static func _has_any_mark(placed_slots: Variant) -> bool:
	if not placed_slots is Dictionary:
		return false
	for slot_id in RouletteSlotCatalog.slot_ids():
		if _marked_slot(placed_slots, slot_id):
			return true
	return false

static func _landed_on_any_mark(payload: Dictionary) -> bool:
	return RouletteSlotCatalog.has_placed_token(payload.get("placed_slots", {}), str(payload.get("pending_slot", "")))

static func _dice_gap(payload: Dictionary) -> int:
	var dice := _raw_dice_values(payload)
	if dice.size() < 2:
		return 999
	return abs(int(dice[0]) - int(dice[1]))

static func _wager_count(payload: Dictionary) -> int:
	if _is_numeric_payload(payload):
		return int(payload.get("wager_marbles_committed", 0))
	var count := 0
	var placed_slots: Variant = payload.get("placed_slots", {})
	if not placed_slots is Dictionary:
		return 0
	for value in (placed_slots as Dictionary).values():
		if value is Array:
			count += (value as Array).size()
	return count

static func _landed_adjacent_to_mark(payload: Dictionary) -> bool:
	var pending := str(payload.get("pending_slot", ""))
	if not RouletteSlotCatalog.has_slot(pending):
		return false
	if _marked_slot(payload.get("placed_slots", {}), pending):
		return false
	var order := RouletteSlotCatalog.slot_ids()
	var index := order.find(pending)
	if index < 0:
		return false
	var left := str(order[(index - 1 + order.size()) % order.size()])
	var right := str(order[(index + 1) % order.size()])
	return _marked_slot(payload.get("placed_slots", {}), left) or _marked_slot(payload.get("placed_slots", {}), right)
