class_name BattleDiceFlow
extends RefCounted

const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const DicePushResolver := preload("res://scripts/systems/dice_push_resolver.gd")

static func apply_run_upgrades(result: Dictionary, dice_rule_id: String, active_run_upgrades: Dictionary) -> Dictionary:
	var next_result := result.duplicate(true)
	var primary_bonus := int(round(float(active_run_upgrades.get("primary_die_bonus", active_run_upgrades.get("dice_bonus", 0.0)))))
	var secondary_bonus := int(round(float(active_run_upgrades.get("secondary_die_bonus", 0.0))))
	var attack_mode := str(next_result.get("dice_rule", DiceResolver.rule(dice_rule_id)).get("attack_base_mode", ""))
	if primary_bonus != 0:
		next_result["attack_base"] = max(0, int(next_result.get("attack_base", 0)) + primary_bonus)
		next_result["run_upgrade_primary_die_bonus"] = primary_bonus
	if secondary_bonus != 0:
		if attack_mode == "choice_double_attack":
			next_result["attack_base"] = max(0, int(next_result.get("attack_base", 0)) + secondary_bonus)
		elif next_result.has("guard_value"):
			next_result["guard_value"] = max(0, int(next_result.get("guard_value", 0)) + secondary_bonus)
		if attack_mode != "choice_double_attack" and next_result.has("player_block"):
			next_result["player_block"] = max(0, int(next_result.get("player_block", 0)) + secondary_bonus)
		next_result["run_upgrade_secondary_die_bonus"] = secondary_bonus
	return next_result

static func attack_mode(dice_rule_id: String) -> String:
	return str(DiceResolver.rule(dice_rule_id).get("attack_base_mode", ""))

static func is_attack_guard_rule(dice_rule_id: String) -> bool:
	return attack_mode(dice_rule_id) == "choice_attack_guard"

static func is_double_attack_rule(dice_rule_id: String) -> bool:
	return attack_mode(dice_rule_id) == "choice_double_attack"

static func is_black_signer_rule(dice_rule_id: String) -> bool:
	return attack_mode(dice_rule_id) == "black_signer_contract"

static func is_dice_push_rule(dice_rule_id: String) -> bool:
	var rule_data: Dictionary = DiceResolver.rule(dice_rule_id)
	var mode := str(rule_data.get("attack_base_mode", ""))
	return int(rule_data.get("dice_count", 1)) == 2 and int(rule_data.get("sides", 6)) == 6 and mode in ["sum", "choice_attack_guard", "choice_double_attack"]

static func visible_total(dice: Array) -> int:
	var total := 0
	for value in dice:
		total += int(value)
	return total

static func empty_push_state() -> Dictionary:
	return {
		"count": 0,
		"current_total": 0,
		"attack_base": 0,
		"active": false,
		"failed": false,
		"locked": false,
		"pending_total": 0,
		"history": []
	}

static func synced_push_state(dice: Array, dice_locked: Array, dice_rule_id: String, rerolls_left: int, selected_attack_die_index: int) -> Dictionary:
	if not is_dice_push_rule(dice_rule_id):
		return empty_push_state()
	var current_total := visible_total(dice)
	return {
		"count": 0,
		"current_total": current_total,
		"attack_base": int(DiceResolver.compute_result(dice, dice_locked, dice_rule_id, rerolls_left, [], selected_attack_die_index).get("attack_base", 0)),
		"active": false,
		"failed": false,
		"locked": current_total >= DicePushResolver.MAX_TOTAL,
		"pending_total": 0,
		"history": []
	}

static func push_has_attack_override(dice_rule_id: String, push_active: bool, push_failed: bool) -> bool:
	return is_dice_push_rule(dice_rule_id) and (push_active or push_failed)

static func can_push(phase: String, dice_rolled: bool, dice_roll_in_progress: bool, dice_role_selecting: bool, dice_rule_id: String, dice_push_failed: bool, dice_push_locked: bool, dice_push_current_total: int, dice_push_count: int, dice: Array) -> bool:
	if phase != "dice" or not dice_rolled or dice_roll_in_progress:
		return false
	if dice_role_selecting:
		return false
	if not is_dice_push_rule(dice_rule_id) or dice_push_failed or dice_push_locked:
		return false
	var current_total := dice_push_current_total if dice_push_current_total > 0 else visible_total(dice)
	return DicePushResolver.can_push(current_total, dice_push_count)

static func requires_attack_die_choice(dice_rule_id: String) -> bool:
	var mode := attack_mode(dice_rule_id)
	return mode == "choice_attack_guard" or mode == "choice_double_attack"

static func current_result(dice: Array, dice_locked: Array, dice_rule_id: String, rerolls_left: int, selected_attack_die_index: int, push_state: Dictionary) -> Dictionary:
	var result := DiceResolver.compute_result(dice, dice_locked, dice_rule_id, rerolls_left, [], selected_attack_die_index)
	if push_has_attack_override(dice_rule_id, bool(push_state.get("active", false)), bool(push_state.get("failed", false))):
		result["attack_base"] = max(0, int(push_state.get("attack_base", 0)))
		result["dice_push_count"] = int(push_state.get("count", 0))
		result["dice_push_current_total"] = int(push_state.get("current_total", 0))
		result["dice_push_failed"] = bool(push_state.get("failed", false))
		result["dice_push_locked"] = bool(push_state.get("locked", false))
		result["dice_push_history"] = (push_state.get("history", []) as Array).duplicate(true)
	return result

static func dice_values_text(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(int(value)))
	return " / ".join(parts)

