extends SceneTree

const NumericFlow := preload("res://scripts/battle/battle_numeric_roulette_flow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_spin_state()
	_check_target_delta()
	_check_weighting_and_preview()
	_check_state_payload_helpers()
	if failures.is_empty():
		print("battle numeric roulette flow helper smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_spin_state() -> void:
	var state := NumericFlow.spin_state({"index": 9, "multiplier": 3.0}, 2)
	_assert_eq(state.get("index"), 9, "spin state index")
	_assert_eq(state.get("pending_slot"), "numeric_9", "spin state slot")
	_assert_eq(float(state.get("damage_multiplier")), 4.5, "spin state wager multiplier")

func _check_target_delta() -> void:
	var delta := NumericFlow.target_wheel_delta(0, 0.0, 2)
	_assert_eq(delta >= 720.0, true, "target delta rotations")

func _check_weighting_and_preview() -> void:
	var weighted := NumericFlow.weighted_indices({}, {
		"bust_weight_delta": 2,
		"jackpot_weight_delta": 1,
		"overdrive_weight_delta": 1
	})
	_assert_eq(weighted.size() > 10, true, "weighted indices include extras")
	_assert_eq(NumericFlow.preview_damage(4, 1.5, 2, 1.0), 8, "preview damage")

func _check_state_payload_helpers() -> void:
	var committed := NumericFlow.commit_wager_state(3, 2)
	_assert_eq(committed.get("wager_marbles_committed"), 2, "commit wager count")
	_assert_eq(committed.get("wager_marbles_available"), 1, "commit wager available")
	var snapshot := {
		"attack_base": 6,
		"wager_marbles_committed": 2,
		"wager_marbles_available": 1,
		"numeric_roulette_multiplier": 1.0,
		"relic_state": {},
		"seed": 7,
		"wheel_angle": -90.0,
		"potion_extra_go_chances": 1,
		"combat_core": "numeric_roulette",
		"pending_slot": "numeric_9",
		"cash": 0,
		"run_gold": 0,
		"gold_delta": 0,
		"player_hp": 40,
		"player_max_hp": 40,
		"player_block": 0,
		"enemy_hp": 20,
		"enemy_block": 1,
		"enemy_damage_delta": 0,
		"enemy_damage_multiplier": 1.0,
		"dice_values": [3, 3],
		"dice_rule_id": "two_dice_double_attack",
		"selected_attack_die_index": 0,
		"player_attack_delta": 0,
		"player_damage_multiplier": 1.0,
		"damage_multiplier": 4.5,
		"numeric_go_used_this_spin": true,
		"placed_slots": {}
	}
	var before := NumericFlow.roulette_before_spin_payload(snapshot)
	_assert_eq(before.get("seed"), 7, "before spin seed")
	var opened := NumericFlow.open_spin_state(snapshot, {"numeric_extra_go_chances": 1}, {"index": 9, "multiplier": 3.0})
	_assert_eq(opened.get("numeric_go_chances_left"), 3, "open spin go chances")
	_assert_eq(opened.get("phase"), "spinning", "open spin phase")
	var go_state := NumericFlow.go_spin_state(opened, {"index": 2, "multiplier": 1.0})
	_assert_eq(go_state.get("numeric_roulette_multiplier"), 0.0, "go collapse on non-improve")
	var payload := NumericFlow.resolution_before_payload(snapshot)
	var outcome := NumericFlow.resolution_outcome(payload, snapshot, 0)
	_assert_eq(outcome.get("damage"), 26, "resolution outcome damage after block")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
