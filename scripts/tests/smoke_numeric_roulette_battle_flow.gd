extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const GoStopButtonDriver := preload("res://scripts/tests/support/go_stop_button_driver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_higher_go_keeps_multiplier()
	await _check_equal_go_busts_multiplier()
	await _check_hoarded_wager_marbles_pressure_enemy_hit()
	if failures.is_empty():
		print("numeric roulette battle flow smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_higher_go_keeps_multiplier() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"numeric_forced_indices": [7, 9],
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "single_attack_die",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	if str(combat.get("phase")) != "wager":
		failures.append("dice confirm should enter wager phase")
	if int(combat.get("wager_marbles_available")) != 1:
		failures.append("combat should start with one wager marble")
	if _placed_marble_count(combat.get("placed_slots") as Dictionary) != 0:
		failures.append("numeric core should not place marbles on roulette slots")
	if _action_texts(combat) != ["Go", "Stop"]:
		failures.append("wager phase should expose only Go/Stop buttons, got " + str(_action_texts(combat)))
	_press_wager_key(combat, KEY_EQUAL)
	await process_frame
	if int(combat.get("wager_marbles_committed")) != 1:
		failures.append("keyboard plus should commit one marble")
	_press_wager_key(combat, KEY_MINUS)
	await process_frame
	if int(combat.get("wager_marbles_committed")) != 0:
		failures.append("keyboard minus should remove one committed marble")
	_expect_enabled_button(combat, "Go", "wager phase")
	_press_button_by_text(combat, "Go", "wager phase")
	await process_frame
	if int(combat.get("wager_marbles_committed")) != 1:
		failures.append("wager Go should commit one marble")
	_expect_enabled_button(combat, "Stop", "wager phase")
	_press_button_by_text(combat, "Stop", "wager phase")
	await _wait_for_phase(combat, "intervene", 180)
	await process_frame
	if str(combat.get("phase")) != "intervene":
		failures.append("numeric spin should reach stop/go phase")
	if abs(float(combat.get("numeric_roulette_multiplier")) - 1.5) > 0.001:
		failures.append("first forced numeric spin should land on x1.5")
	_expect_numeric_pointer_alignment(combat, "first spin")
	_expect_enabled_button(combat, "Go", "numeric intervention")
	_press_button_by_text(combat, "Go", "numeric intervention")
	await process_frame
	if str(combat.get("phase")) != "spinning":
		failures.append("go should animate through spinning phase")
	await _wait_for_phase(combat, "intervene", 180)
	if abs(float(combat.get("numeric_roulette_multiplier")) - 3.0) > 0.001:
		failures.append("go should keep higher second multiplier")
	_expect_numeric_pointer_alignment(combat, "go spin")
	if bool(combat.get("numeric_go_available")):
		failures.append("go should only be available once per attack")
	if int(combat._numeric_preview_damage()) != 15:
		failures.append("numeric preview before resolve should be 15, got " + str(combat._numeric_preview_damage()) + " attack=" + str(combat.get("attack_base")) + " wager=" + str(combat.get("wager_marbles_committed")) + " mult=" + str(combat.get("numeric_roulette_multiplier")))
	_expect_enabled_button(combat, "Stop", "numeric intervention")
	_press_button_by_text(combat, "Stop", "numeric intervention")
	await process_frame
	if int(combat.get("enemy_hp")) != 35:
		failures.append("numeric damage should be round(4 * 3 * 1.25) = 15, got enemy_hp=" + str(combat.get("enemy_hp")) + " attack=" + str(combat.get("attack_base")) + " wager=" + str(combat.get("wager_marbles_committed")) + " mult=" + str(combat.get("numeric_roulette_multiplier")))
	if not (str(combat.get("phase")) in ["enemy", "result"]):
		failures.append("numeric resolution should return to combat")

	combat.queue_free()
	for i in range(60):
		await process_frame

func _check_equal_go_busts_multiplier() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"numeric_forced_indices": [7, 7],
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "single_attack_die",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	_expect_enabled_button(combat, "Go", "equal-go wager")
	_press_button_by_text(combat, "Go", "equal-go wager")
	await process_frame
	_expect_enabled_button(combat, "Stop", "equal-go wager")
	_press_button_by_text(combat, "Stop", "equal-go wager")
	await _wait_for_phase(combat, "intervene", 180)
	await process_frame
	if abs(float(combat.get("numeric_roulette_multiplier")) - 1.5) > 0.001:
		failures.append("equal-go first forced numeric spin should land on x1.5")
	_expect_enabled_button(combat, "Go", "equal-go intervention")
	_press_button_by_text(combat, "Go", "equal-go intervention")
	await _wait_for_phase(combat, "intervene", 180)
	if abs(float(combat.get("numeric_roulette_multiplier"))) > 0.001:
		failures.append("go should bust on equal multiplier, got " + str(combat.get("numeric_roulette_multiplier")))
	if int(combat._numeric_preview_damage()) != 0:
		failures.append("equal go bust should preview zero damage")
	combat.queue_free()
	for i in range(60):
		await process_frame

func _check_hoarded_wager_marbles_pressure_enemy_hit() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"numeric_forced_indices": [7],
		"combat_cash": 18,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 50,
		"enemy_max_hp": 50,
		"dice_rule_id": "single_attack_die",
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"move_pattern": ["hp_strike"]
	})
	await process_frame
	combat._finish_dice_roll_with_values([4])
	combat._take_marbles()
	await process_frame
	if int(combat.get("wager_marbles_available")) != 1:
		failures.append("hoard pressure setup should have one wager marble")
	_press_button_by_text(combat, "Stop", "hoard pressure wager")
	await _wait_for_phase(combat, "intervene", 180)
	_press_button_by_text(combat, "Stop", "hoard pressure intervention")
	await process_frame
	if int(combat.get("wager_marbles_available")) != 1:
		failures.append("uncommitted wager marble should remain available before enemy hit")
	combat._enemy_phase_take()
	await process_frame
	if int(combat.get("player_hp")) != 34:
		failures.append("hoarded wager marble should add +1 enemy damage, got player_hp=" + str(combat.get("player_hp")))
	if int(combat.get("enemy_damage_delta")) != 0:
		failures.append("hoarded wager pressure should not persist as enemy_damage_delta")
	combat.queue_free()
	for i in range(60):
		await process_frame

func _wait_for_phase(combat: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(combat.get("phase")) == expected:
			return
		await process_frame

func _placed_marble_count(placed_slots: Dictionary) -> int:
	var count := 0
	for key in placed_slots.keys():
		var arr: Array = placed_slots.get(key, [])
		count += arr.size()
	return count

func _expect_numeric_pointer_alignment(combat: Control, context: String) -> void:
	var index := int(combat.get("numeric_roulette_index"))
	var wheel_angle := float(combat.get("wheel_angle"))
	var cell_step := 360.0 / 10.0
	var cell_center_angle := fposmod(wheel_angle - 90.0 + float(index) * cell_step, 360.0)
	if abs(cell_center_angle - 270.0) > 0.01:
		failures.append(context + " should align selected cell to top pointer, got angle=" + str(cell_center_angle) + " index=" + str(index))

func _action_texts(combat: Control) -> Array[String]:
	var texts: Array[String] = []
	if combat.prompt_layer == null or combat.prompt_layer.action_bar == null:
		return texts
	for child in combat.prompt_layer.action_bar.get_children():
		var button := child as Button
		if button != null:
			texts.append(button.text)
	return texts

func _button_by_text(combat: Control, text: String) -> Button:
	return GoStopButtonDriver.button_by_text(combat, text)

func _press_button_by_text(combat: Control, text: String, context: String) -> void:
	var result := GoStopButtonDriver.press_button_by_text(combat, text)
	if result == "missing":
		failures.append(context + " should expose " + text + " button")
		return
	if result == "disabled":
		failures.append(context + " should expose enabled " + text + " button")

func _expect_enabled_button(combat: Control, text: String, context: String) -> void:
	var button := _button_by_text(combat, text)
	if button == null:
		failures.append(context + " should expose " + text + " button")
		return
	if button.disabled:
		failures.append(context + " should expose enabled " + text + " button")

func _press_wager_key(combat: Control, keycode: Key) -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.physical_keycode = keycode
	key_event.pressed = true
	combat._unhandled_key_input(key_event)
