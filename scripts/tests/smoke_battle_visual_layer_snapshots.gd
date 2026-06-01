extends SceneTree

const Snapshots := preload("res://scripts/battle/battle_visual_layer_snapshots.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_table_and_hand()
	_check_hud_and_opponent()
	_check_overlay_and_camera_policy()
	if failures.is_empty():
		print("battle visual layer snapshots smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_table_and_hand() -> void:
	var snapshot := {
		"phase": "wager",
		"is_numeric_core": true,
		"active_run_upgrades": {},
		"numeric_roulette_index": 3,
		"wager_marbles_available": 2,
		"dice": [4],
		"dice_locked": [false],
		"dice_rolled": true,
		"marbles": ["plain"],
		"stored": []
	}
	var table := Snapshots.table_state(snapshot)
	_assert_eq(table.get("active_phase"), "wager", "table phase")
	_assert_eq((table.get("numeric_roulette_cells", []) as Array).is_empty(), false, "numeric cells included")
	var hand := Snapshots.hand_state(snapshot)
	_assert_eq(hand.get("dice"), [4], "hand dice")
	_assert_eq(hand.get("active_phase"), "wager", "hand phase")

func _check_hud_and_opponent() -> void:
	var snapshot := {
		"seed_text": "abc",
		"turn": 2,
		"cash": 9,
		"player_hp": 20,
		"player_max_hp": 30,
		"enemy_hp": 12,
		"enemy_max_hp": 40,
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"active_potion_ids": ["red"],
		"potion_slots_max": 3,
		"enemy_intent": "Hit",
		"current_move_id": "hp_strike",
		"opponent_mood": "hit"
	}
	var hud := Snapshots.run_hud_state(snapshot)
	_assert_eq(hud.get("potion_slots_used"), 1, "potion slots used")
	_assert_eq(hud.get("potion_slots_max"), 3, "potion slots max")
	var opponent := Snapshots.opponent_state(snapshot)
	_assert_eq(opponent.get("monster_name"), "Debt Collector", "opponent name")
	_assert_eq(opponent.get("opponent_mood"), "hit", "opponent mood")

func _check_overlay_and_camera_policy() -> void:
	var overlay := Snapshots.overlay_payload({
		"player_hp": 12,
		"player_max_hp": 20,
		"active_relic_ids": ["lucky_coin"],
		"active_potion_ids": ["red", "blue"],
		"potion_slots_max": 3,
		"player_block": 4,
		"active_run_upgrades": {"roulette_bonus": 0.2}
	})
	_assert_eq(overlay.get("potion_slots_used"), 2, "overlay potion slots used")
	_assert_eq(overlay.get("potion_slots_max"), 3, "overlay potion slots max")
	_assert_eq((overlay.get("run_upgrades", {}) as Dictionary).get("roulette_bonus"), 0.2, "overlay run upgrades")
	_assert_eq(Snapshots.camera_beat({"phase": "marble", "throwing_hand": true, "thrown_marbles": []}), "wheel_close", "throwing camera beat")
	_assert_eq(Snapshots.camera_beat({"phase": "enemy"}), "opponent_intent", "enemy camera beat")
	_assert_eq(Snapshots.camera_beat({"phase": "result"}), "result_hit", "result camera beat")

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
