class_name BattleDiceRollHandoff
extends RefCounted

const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const DiceFlow := preload("res://scripts/battle/battle_dice_flow.gd")

static func can_use_cup_layer(use_cup_layer: bool, has_cup_layer: bool, dice_rule_id: String) -> bool:
	if not use_cup_layer or not has_cup_layer:
		return false
	var rule_data: Dictionary = DiceResolver.rule(dice_rule_id)
	var count := int(rule_data.get("dice_count", 1))
	return count >= 1 and count <= 2 and int(rule_data.get("sides", 6)) == 6

static func can_use_roll_layer(has_roll_layer: bool, dice_rule_id: String) -> bool:
	if not has_roll_layer:
		return false
	var rule_data: Dictionary = DiceResolver.rule(dice_rule_id)
	return int(rule_data.get("dice_count", 1)) == 1 and int(rule_data.get("sides", 6)) == 6

static func begin_roll(snapshot: Dictionary) -> Dictionary:
	var dice_rule_id := str(snapshot.get("dice_rule_id", "single_attack_die"))
	var is_reroll := bool(snapshot.get("is_reroll", false))
	var is_push := bool(snapshot.get("is_push", false))
	var dice: Array = (snapshot.get("dice", []) as Array).duplicate(true)
	var dice_locked: Array = (snapshot.get("dice_locked", []) as Array).duplicate(true)
	var rerolls_left := int(snapshot.get("rerolls_left", 0))
	if is_push:
		dice_locked = DiceResolver.starting_locks(dice_rule_id)
	elif is_reroll:
		rerolls_left -= 1
	else:
		dice_locked = DiceResolver.starting_locks(dice_rule_id)
		rerolls_left = int(DiceResolver.rule(dice_rule_id).get("rerolls", 2))

	var use_cup := can_use_cup_layer(
		bool(snapshot.get("use_dice_cup_layer_3d", false)),
		bool(snapshot.get("has_dice_cup_roll_layer", false)),
		dice_rule_id
	)
	var use_roll_layer := can_use_roll_layer(bool(snapshot.get("has_dice_roll_layer", false)), dice_rule_id)
	var route := "immediate"
	if use_cup:
		route = "cup"
	elif use_roll_layer:
		route = "roll_2d"

	return {
		"dice_locked": dice_locked,
		"rerolls_left": rerolls_left,
		"dice_roll_in_progress": route != "immediate",
		"dice_roll_is_reroll": is_reroll,
		"dice_roll_is_push": is_push,
		"dice_roll_fx": 1.0,
		"banner_text": "",
		"banner_alpha": 0.0,
		"table_pulse": 1.0,
		"route": route,
		"cup_payload": {
			"dice_count": int(DiceResolver.rule(dice_rule_id).get("dice_count", 1)),
			"previous_values": dice.duplicate(),
			"dice_locked": dice_locked.duplicate(),
			"avoid_previous": is_reroll
		},
		"roll_payload": {
			"theme": "combat",
			"previous_value": dice[0] if not dice.is_empty() else 0,
			"avoid_previous": is_reroll
		}
	}

static func finish_roll(snapshot: Dictionary, values: Array) -> Dictionary:
	var dice_rule_id := str(snapshot.get("dice_rule_id", "single_attack_die"))
	var dice: Array = DiceResolver.normalize_values(snapshot.get("dice", []), dice_rule_id)
	var dice_locked: Array = DiceResolver.normalize_locks(snapshot.get("dice_locked", []), dice_rule_id)
	var rolled_values: Array[int] = DiceResolver.normalize_values(values, dice_rule_id)
	if not bool(snapshot.get("dice_roll_is_reroll", false)):
		dice = rolled_values
	else:
		for i in range(dice.size()):
			if not bool(dice_locked[i]):
				dice[i] = rolled_values[min(i, rolled_values.size() - 1)]

	var out := {
		"dice_roll_in_progress": false,
		"dice": dice,
		"dice_rolled": true,
		"dice_relics_applied": false,
		"dice_role_selecting": false,
		"finish_push": bool(snapshot.get("dice_roll_is_push", false))
	}
	if bool(out.get("finish_push", false)):
		out["dice_roll_is_push"] = false
		out["dice_roll_is_reroll"] = false
		return out

	var push_state := DiceFlow.empty_push_state()
	push_state = DiceFlow.synced_push_state(dice, dice_locked, dice_rule_id, int(snapshot.get("rerolls_left", 0)), int(snapshot.get("selected_attack_die_index", -1)))
	var result := DiceFlow.apply_run_upgrades(
		DiceResolver.compute_result(dice, dice_locked, dice_rule_id, int(snapshot.get("rerolls_left", 0))),
		dice_rule_id,
		snapshot.get("active_run_upgrades", {})
	)
	out["push_state"] = push_state
	out["attack_base"] = int(result.get("attack_base", 0))
	out["guard_value"] = int(result.get("guard_value", 0))
	out["dice_roll_fx"] = 1.0
	out["banner_text"] = ""
	out["banner_alpha"] = 0.0
	out["table_pulse"] = 1.0
	out["dice_roll_is_push"] = false
	out["dice_roll_is_reroll"] = false
	return out
