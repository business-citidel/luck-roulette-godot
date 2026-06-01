extends SceneTree

const AttackDieHandoff := preload("res://scripts/battle/battle_attack_die_handoff.gd")
const DiceFlow := preload("res://scripts/battle/battle_dice_flow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_attack_guard_handoff()
	_check_double_attack_push_handoff()
	if failures.is_empty():
		print("battle attack die handoff smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_attack_guard_handoff() -> void:
	var result := AttackDieHandoff.select_attack_die({
		"index": 0,
		"dice_rolled": true,
		"dice": [5, 2],
		"dice_locked": [false, false],
		"dice_rule_id": "two_dice_attack_guard",
		"rerolls_left": 2,
		"player_block": 3,
		"active_run_upgrades": {},
		"push_state": DiceFlow.empty_push_state()
	})
	_assert_eq(result.get("valid"), true, "attack guard valid")
	_assert_eq(result.get("selected_attack_die_index"), 0, "selected index")
	_assert_eq(result.get("attack_base"), 5, "attack die attack")
	_assert_eq(result.get("guard_value"), 2, "support die guard")
	_assert_eq(result.get("player_block"), 5, "guard added to block")
	_assert_eq(result.get("dice_role_selecting"), false, "role selecting cleared")

func _check_double_attack_push_handoff() -> void:
	var push_state := DiceFlow.empty_push_state()
	push_state["active"] = true
	push_state["attack_base"] = 12
	push_state["count"] = 1
	push_state["current_total"] = 10
	var result := AttackDieHandoff.select_attack_die({
		"index": 1,
		"dice_rolled": true,
		"dice": [4, 6],
		"dice_locked": [false, false],
		"dice_rule_id": "two_dice_double_attack",
		"rerolls_left": 2,
		"player_block": 0,
		"active_run_upgrades": {},
		"push_state": push_state
	})
	_assert_eq(result.get("valid"), true, "double attack valid")
	_assert_eq(result.get("attack_base"), 12, "push attack override survives")
	_assert_eq((result.get("push_state", {}) as Dictionary).get("count"), 1, "push state preserved")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
