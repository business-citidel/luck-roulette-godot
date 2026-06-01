extends SceneTree

const OutcomeFlow := preload("res://scripts/battle/battle_resolution_outcome_flow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_live_patch()
	_check_result_patch()
	if failures.is_empty():
		print("battle resolution outcome flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_live_patch() -> void:
	var patch := OutcomeFlow.state_patch({
		"player_hp": 20,
		"enemy_hp": 30,
		"busts": 0,
		"run_over": false,
		"numeric_roulette_multiplier": 3.0
	}, {
		"attack_base": 5,
		"roulette_multiplier": 2.0,
		"wager_marbles_committed": 1,
		"roulette_go_used": true,
		"cash": 4,
		"player_hp": 20,
		"enemy_hp": 21,
		"enemy_block": 0,
		"enemy_damage_delta": 1,
		"applied_effects": [{"effect_id": "x"}]
	})
	_assert_eq(patch.get("phase"), "enemy", "live phase")
	_assert_eq(patch.get("run_over"), false, "live run over")
	_assert_eq(patch.get("last_attack_base"), 5, "last attack")
	_assert_eq(patch.get("numeric_roulette_index"), -1, "numeric index reset")

func _check_result_patch() -> void:
	var patch := OutcomeFlow.state_patch({
		"player_hp": 20,
		"enemy_hp": 10,
		"busts": 1,
		"run_over": false
	}, {
		"player_hp": 20,
		"enemy_hp": 0,
		"bust_delta": 0
	})
	_assert_eq(patch.get("phase"), "result", "dead enemy result phase")
	_assert_eq(patch.get("run_over"), true, "dead enemy run over")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
