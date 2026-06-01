class_name RelicHookPayloads
extends RefCounted

static func dice_payload(values: Array, rule_id: String) -> Dictionary:
	return dice_payload_with_rerolls(values, rule_id, 0)

static func dice_payload_with_rerolls(values: Array, rule_id: String, rerolls_left: int) -> Dictionary:
	return {
		"dice_rule_id": rule_id,
		"dice_values": values.duplicate(),
		"dice": values.duplicate(),
		"dice_locked": [],
		"rerolls_left": rerolls_left,
		"applied_effects": []
	}

static func dice_payload_with_cash(values: Array, rule_id: String, cash: int) -> Dictionary:
	var payload := dice_payload(values, rule_id)
	payload["cash"] = cash
	return payload

static func dice_payload_selected(values: Array, rule_id: String, selected_index: int) -> Dictionary:
	var payload := dice_payload(values, rule_id)
	payload["selected_attack_die_index"] = selected_index
	return payload

static func dice_payload_selected_with_rerolls(values: Array, rule_id: String, selected_index: int, rerolls_left: int) -> Dictionary:
	var payload := dice_payload_with_rerolls(values, rule_id, rerolls_left)
	payload["selected_attack_die_index"] = selected_index
	return payload

static func dice_payload_selected_with_cash(values: Array, rule_id: String, selected_index: int, cash: int) -> Dictionary:
	var payload := dice_payload_selected(values, rule_id, selected_index)
	payload["cash"] = cash
	return payload

static func resolution_payload(pending_slot: String, marked_slot: String) -> Dictionary:
	var placed_slots := marked_payload(marked_slot)
	return {
		"pending_slot": pending_slot,
		"placed_slots": placed_slots,
		"enemy_damage_delta": 0,
		"player_block": 0,
		"damage_multiplier": 1.0,
		"payout_multiplier": 1.0,
		"relic_state": {},
		"applied_effects": []
	}

static func resolution_payload_with_block(pending_slot: String, marked_slot: String, block: int) -> Dictionary:
	var payload := resolution_payload(pending_slot, marked_slot)
	payload["player_block"] = block
	return payload

static func resolution_payload_with_state(pending_slot: String, marked_slot: String, state: Dictionary) -> Dictionary:
	var payload := resolution_payload(pending_slot, marked_slot)
	payload["relic_state"] = state.duplicate(true)
	return payload

static func numeric_resolution_payload(multiplier: float, dice_values: Array, selected_index: int, player_hp: int, player_max_hp: int) -> Dictionary:
	return {
		"pending_slot": "numeric",
		"combat_core": "numeric_roulette",
		"outcome_mode": "numeric_roulette",
		"roulette_multiplier": multiplier,
		"wager_multiplier": 1.0,
		"damage_multiplier": multiplier,
		"payout_multiplier": multiplier,
		"wager_marbles_committed": 1,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_block": 0,
		"dice_values": dice_values.duplicate(),
		"selected_attack_die_index": selected_index,
		"flat_damage_bonus": 0,
		"relic_state": {},
		"applied_effects": []
	}

static func numeric_resolution_payload_with_wager(multiplier: float, dice_values: Array, selected_index: int, player_hp: int, player_max_hp: int, committed: int) -> Dictionary:
	var payload := numeric_resolution_payload(multiplier, dice_values, selected_index, player_hp, player_max_hp)
	payload["wager_marbles_committed"] = committed
	return payload

static func numeric_resolution_payload_with_cash(multiplier: float, dice_values: Array, selected_index: int, player_hp: int, player_max_hp: int, cash: int) -> Dictionary:
	var payload := numeric_resolution_payload(multiplier, dice_values, selected_index, player_hp, player_max_hp)
	payload["cash"] = cash
	payload["cash_delta_bonus"] = 0
	return payload

static func numeric_resolution_payload_with_wager_and_cash(multiplier: float, dice_values: Array, selected_index: int, player_hp: int, player_max_hp: int, committed: int, cash: int) -> Dictionary:
	var payload := numeric_resolution_payload_with_wager(multiplier, dice_values, selected_index, player_hp, player_max_hp, committed)
	payload["cash"] = cash
	payload["cash_delta_bonus"] = 0
	return payload

static func numeric_resolution_payload_with_action(multiplier: float, action: String) -> Dictionary:
	var payload := numeric_resolution_payload_with_cash(multiplier, [3, 4], 0, 20, 42, 10)
	payload["roulette_action"] = action
	return payload

static func numeric_resolution_payload_all_in(multiplier: float, committed: int) -> Dictionary:
	var payload := numeric_resolution_payload_with_wager(multiplier, [3, 4], 0, 20, 42, committed)
	payload["wager_marbles_available"] = committed
	return payload

static func numeric_outcome_payload(multiplier: float, cash: int) -> Dictionary:
	var payload := numeric_resolution_payload(multiplier, [3, 4], 0, 20, 42)
	payload["cash"] = cash
	payload["cash_delta"] = 0
	payload["damage"] = 0 if multiplier <= 0.001 else 5
	return payload

static func marked_payload(marked_slot: String) -> Dictionary:
	var placed_slots := {
		"safe": [],
		"profit": [],
		"jackpot": [],
		"bust": [],
		"overdrive": []
	}
	if placed_slots.has(marked_slot):
		placed_slots[marked_slot].append("plain")
	return placed_slots

static func has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false
