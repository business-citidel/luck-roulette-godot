extends SceneTree

const RollHandoff := preload("res://scripts/battle/battle_dice_roll_handoff.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_begin_routes()
	_check_finish_reroll_merge()
	if failures.is_empty():
		print("battle dice roll handoff smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_begin_routes() -> void:
	var start := RollHandoff.begin_roll({
		"dice_rule_id": "single_attack_die",
		"dice": [3],
		"dice_locked": [false],
		"rerolls_left": 0,
		"is_reroll": false,
		"is_push": false,
		"use_dice_cup_layer_3d": false,
		"has_dice_cup_roll_layer": true,
		"has_dice_roll_layer": true
	})
	_assert_eq(start.get("route"), "roll_2d", "2d route")
	_assert_eq(start.get("dice_roll_in_progress"), true, "visual roll in progress")
	_assert_eq(start.get("rerolls_left"), 2, "fresh reroll count")

	var immediate := RollHandoff.begin_roll({
		"dice_rule_id": "two_dice_attack_guard",
		"dice": [1, 2],
		"dice_locked": [false, false],
		"rerolls_left": 2,
		"is_reroll": true,
		"is_push": false,
		"use_dice_cup_layer_3d": false,
		"has_dice_cup_roll_layer": false,
		"has_dice_roll_layer": true
	})
	_assert_eq(immediate.get("route"), "immediate", "two dice without cup immediate")
	_assert_eq(immediate.get("rerolls_left"), 1, "reroll consumes count")

func _check_finish_reroll_merge() -> void:
	var finish := RollHandoff.finish_roll({
		"dice_rule_id": "two_dice_attack_guard",
		"dice": [6, 2],
		"dice_locked": [true, false],
		"rerolls_left": 1,
		"dice_roll_is_reroll": true,
		"dice_roll_is_push": false,
		"selected_attack_die_index": -1,
		"active_run_upgrades": {}
	}, [1, 5])
	_assert_eq(finish.get("dice"), [6, 5], "locked die survives reroll")
	_assert_eq(finish.get("dice_rolled"), true, "finish marks rolled")
	_assert_eq(finish.get("attack_base"), 0, "choice roll waits for selected die")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
