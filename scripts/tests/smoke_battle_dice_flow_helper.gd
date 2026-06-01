extends SceneTree

const DiceFlow := preload("res://scripts/battle/battle_dice_flow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_rule_predicates()
	_check_run_upgrades()
	_check_push_state_and_result()
	if failures.is_empty():
		print("battle dice flow helper smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_rule_predicates() -> void:
	_assert_eq(DiceFlow.is_attack_guard_rule("two_dice_attack_guard"), true, "attack_guard predicate")
	_assert_eq(DiceFlow.is_double_attack_rule("two_dice_double_attack"), true, "double_attack predicate")
	_assert_eq(DiceFlow.is_black_signer_rule("black_signer_contracts"), true, "black_signer predicate")
	_assert_eq(DiceFlow.is_dice_push_rule("two_dice_attack_guard"), true, "push predicate")
	_assert_eq(DiceFlow.requires_attack_die_choice("single_attack_die"), false, "single attack choice predicate")
	_assert_eq(DiceFlow.visible_total([2, 6]), 8, "visible total")
	_assert_eq(DiceFlow.dice_values_text([2, 6]), "2 / 6", "dice values text")

func _check_run_upgrades() -> void:
	var result := {
		"attack_base": 6,
		"guard_value": 2,
		"player_block": 2,
		"dice_rule": {"attack_base_mode": "choice_attack_guard"}
	}
	var upgraded := DiceFlow.apply_run_upgrades(result, "two_dice_attack_guard", {
		"primary_die_bonus": 1.0,
		"secondary_die_bonus": 2.0
	})
	_assert_eq(upgraded.get("attack_base"), 7, "primary attack upgrade")
	_assert_eq(upgraded.get("guard_value"), 4, "secondary guard upgrade")
	_assert_eq(upgraded.get("player_block"), 4, "secondary block upgrade")

func _check_push_state_and_result() -> void:
	var state := DiceFlow.synced_push_state([2, 6], [false, false], "two_dice_double_attack", 2, -1)
	_assert_eq(state.get("current_total"), 8, "push current total")
	_assert_eq(state.get("locked"), false, "push lock state")
	state["active"] = true
	state["count"] = 1
	state["attack_base"] = 11
	state["current_total"] = 10
	state["history"] = [{"accepted": true}]
	var result := DiceFlow.current_result([5, 5], [false, false], "two_dice_double_attack", 2, 1, state)
	_assert_eq(result.get("attack_base"), 11, "push attack override")
	_assert_eq(result.get("dice_push_count"), 1, "push count result")
	_assert_eq(DiceFlow.can_push("dice", true, false, false, "two_dice_double_attack", false, false, 8, 0, [2, 6]), true, "can push")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))

