class_name BattleAttackDieHandoff
extends RefCounted

const DiceResolver := preload("res://scripts/systems/dice_resolver.gd")
const DiceFlow := preload("res://scripts/battle/battle_dice_flow.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func select_attack_die(snapshot: Dictionary) -> Dictionary:
	var index := int(snapshot.get("index", -1))
	var dice: Array = (snapshot.get("dice", []) as Array).duplicate(true)
	var dice_rule_id := str(snapshot.get("dice_rule_id", "single_attack_die"))
	if not bool(snapshot.get("dice_rolled", false)) or index < 0 or index >= dice.size():
		return {"valid": false}

	var dice_locked: Array = (snapshot.get("dice_locked", []) as Array).duplicate(true)
	var rerolls_left := int(snapshot.get("rerolls_left", 0))
	var active_run_upgrades: Dictionary = snapshot.get("active_run_upgrades", {})
	var push_state: Dictionary = snapshot.get("push_state", {})
	var push_has_attack_override := DiceFlow.push_has_attack_override(
		dice_rule_id,
		bool(push_state.get("active", false)),
		bool(push_state.get("failed", false))
	)
	var result := DiceFlow.current_result(dice, dice_locked, dice_rule_id, rerolls_left, index, push_state)
	result = DiceFlow.apply_run_upgrades(result, dice_rule_id, active_run_upgrades)
	var next_dice: Array = DiceResolver.normalize_values(result.get("dice_values", dice), dice_rule_id)
	var next_locks: Array = DiceResolver.normalize_locks(result.get("dice_locked", dice_locked), dice_rule_id)
	var attack_base := int(result.get("attack_base", 0))
	var guard_value := int(result.get("guard_value", 0))
	var is_attack_guard := DiceFlow.is_attack_guard_rule(dice_rule_id)
	var player_block := int(snapshot.get("player_block", 0))
	if is_attack_guard:
		player_block = max(0, player_block + guard_value)

	var out := {
		"valid": true,
		"selected_attack_die_index": index,
		"dice_role_selecting": false,
		"hovered_attack_die_index": -1,
		"dice": next_dice,
		"dice_locked": next_locks,
		"attack_base": attack_base,
		"guard_value": guard_value,
		"player_block": player_block,
		"dice_roll_fx": 0.36,
		"banner_text": UiText.t("battle.banner.attack_guard", {"attack": attack_base, "guard": player_block}) if is_attack_guard else UiText.t("battle.banner.attack_no_guard", {"attack": attack_base}),
		"banner_alpha": 1.0,
		"message": UiText.t("battle.message.attack_guard_selected", {"attack": attack_base, "guard": player_block}) if is_attack_guard else UiText.t("battle.message.double_attack_selected", {"attack": attack_base}),
		"push_state": push_state.duplicate(true)
	}
	if DiceFlow.is_dice_push_rule(dice_rule_id) and not push_has_attack_override:
		out["push_state"] = DiceFlow.synced_push_state(next_dice, next_locks, dice_rule_id, rerolls_left, index)
	return out
