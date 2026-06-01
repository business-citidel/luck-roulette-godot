extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const GoStopButtonDriver := preload("res://scripts/tests/support/go_stop_button_driver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_numeric_damage_relics()
	await _check_numeric_safety_relics()
	if failures.is_empty():
		print("numeric relic battle flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_numeric_damage_relics() -> void:
	var combat := await _ready_combat(["purple_contract"], [9], 1)
	_press_button_by_text(combat, "Stop", "purple contract roulette spin")
	await _wait_for_phase(combat, "intervene", 180)
	_press_button_by_text(combat, "Stop", "purple contract roulette resolve")
	await process_frame
	if int(combat.get("enemy_hp")) != 34:
		failures.append("purple_contract should make 4 x (x3*x1.25 + .35) deal 16, got enemy_hp=" + str(combat.get("enemy_hp")))
	combat.queue_free()
	await process_frame

func _check_numeric_safety_relics() -> void:
	var combat := await _ready_combat(["bust_insurance", "second_chance"], [0, 8, 9], 1)
	_press_button_by_text(combat, "Stop", "safety relic roulette spin")
	await _wait_for_phase(combat, "intervene", 180)
	if abs(float(combat.get("numeric_roulette_multiplier")) - 0.0) > 0.001:
		failures.append("forced first spin should be x0 before resolution relics")
	if not bool(combat.get("numeric_go_available")):
		failures.append("numeric go should be available after first spin")
	_press_button_by_text(combat, "Go", "safety relic first roulette Go")
	await _wait_for_phase(combat, "intervene", 180)
	if not bool(combat.get("numeric_go_available")):
		failures.append("second_chance should leave one extra go after first go")
	_press_button_by_text(combat, "Go", "safety relic second roulette Go")
	await _wait_for_phase(combat, "intervene", 180)
	if bool(combat.get("numeric_go_available")):
		failures.append("extra go chance should be consumed after second go")
	_press_button_by_text(combat, "Stop", "safety relic roulette resolve")
	await process_frame
	if int(combat.get("enemy_hp")) >= 50:
		failures.append("second chance path should eventually deal numeric damage")
	combat.queue_free()
	await process_frame

func _ready_combat(relics: Array[String], forced_indices: Array[int], committed: int) -> Control:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"numeric_forced_indices": forced_indices,
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "single_attack_die",
		"relic_ids": relics,
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	for i in range(committed):
		_press_button_by_text(combat, "Go", "numeric relic wager Go")
		await process_frame
	return combat

func _press_button_by_text(combat: Control, text: String, context: String) -> void:
	var result: String = GoStopButtonDriver.press_button_by_text(combat, text)
	if result != "":
		failures.append(context + " action " + text + " was " + result)

func _wait_for_phase(combat: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(combat.get("phase")) == expected:
			return
		await process_frame
