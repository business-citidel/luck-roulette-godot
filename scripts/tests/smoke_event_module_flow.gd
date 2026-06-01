extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_standard_base_to_result()
	await _check_dice_base_to_result()
	await _check_roulette_base_to_result()
	await _check_card_base_to_result()
	if failures.is_empty():
		print("event module flow smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_standard_base_to_result() -> void:
	var scene := _scene({})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	if str(scene.get("module_id")) != "base":
		failures.append("standard event did not start on base module")
	if scene.get_choice_controls().size() != 3:
		failures.append("standard event did not expose three base choices")
	await _click_choice(scene, 1)
	await process_frame
	if results.size() != 1:
		failures.append("standard event did not emit exactly once")
	elif str(results[0].get("choice", "")) != "event_relic_trade":
		failures.append("standard event emitted wrong result")
	if str(scene.get("module_id")) != "result_receipt":
		failures.append("standard event did not switch to result receipt")
	if not bool(scene.get("submitted")):
		failures.append("standard event did not mark submitted")
	var table_state: Dictionary = scene.get_table_state()
	if (table_state.get("relic_tray", []) as Array).is_empty():
		failures.append("standard event result receipt did not preview relic")
	scene.queue_free()
	await process_frame

func _check_dice_base_to_result() -> void:
	var scene := _scene({
		"event_id": "backroom_die_test",
		"dice_forced_values": [5, 5]
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	if str(scene.get("module_id")) != "base":
		failures.append("dice event did not start on base module")
	if scene.get_choice_controls().size() != 3:
		failures.append("dice event base did not expose three choices")
	await _click_choice(scene, 0)
	await process_frame
	if str(scene.get("module_id")) != "dice_check":
		failures.append("dice event did not switch to dice module")
	if results.size() != 0:
		failures.append("dice event emitted before rolling")
	if scene.get_choice_controls().size() != 1:
		failures.append("dice module did not expose one roll control")
	await _click_choice(scene, 0)
	await _wait_for_result(results, 180)
	if results.size() != 1:
		failures.append("dice event did not emit after roll")
	elif str(results[0].get("choice", "")) != "backroom_die_test":
		failures.append("dice event emitted wrong choice")
	elif int(results[0].get("dice_total", 0)) != 10:
		failures.append("dice event did not preserve forced 2d6 total 10")
	elif str(results[0].get("dice_tier", "")) != "great":
		failures.append("dice event did not use great-success tier for total 10")
	if str(scene.get("module_id")) != "result_receipt":
		failures.append("dice event did not end on result receipt")
	var table_state: Dictionary = scene.get_table_state()
	if (table_state.get("relic_tray", []) as Array).is_empty():
		failures.append("dice high result did not preview relic")
	scene.queue_free()
	await process_frame

func _check_roulette_base_to_result() -> void:
	var scene := _scene({
		"event_id": "crooked_wheel_bet",
		"roulette_forced_slot": "jackpot"
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	if str(scene.get("module_id")) != "base":
		failures.append("roulette event did not start on base module")
	if scene.get_choice_controls().size() != 3:
		failures.append("roulette event base did not expose three choices")
	await _click_choice(scene, 1)
	await process_frame
	if str(scene.get("module_id")) != "roulette_check":
		failures.append("roulette event did not switch to roulette module")
	if results.size() != 0:
		failures.append("roulette event emitted before spinning")
	if scene.get_choice_controls().size() != 1:
		failures.append("roulette module did not expose one spin control")
	scene._choose_by_id("roulette_spin_now")
	await _wait_for_result(results, 180)
	if results.size() != 1:
		failures.append("roulette event did not emit after spin")
	elif str(results[0].get("choice", "")) != "crooked_wheel_bet":
		failures.append("roulette event emitted wrong choice")
	elif str(results[0].get("roulette_slot", "")) != "jackpot":
		failures.append("roulette event did not preserve forced jackpot")
	if str(scene.get("module_id")) != "result_receipt":
		failures.append("roulette event did not end on result receipt")
	var table_state: Dictionary = scene.get_table_state()
	if (table_state.get("relic_tray", []) as Array).is_empty():
		failures.append("roulette jackpot result did not preview relic")
	scene.queue_free()
	await process_frame

func _check_card_base_to_result() -> void:
	var scene := _scene({
		"event_id": "sealed_side_box",
		"card_forced_index": 1
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	if str(scene.get("module_id")) != "base":
		failures.append("card event did not start on base module")
	if scene.get_choice_controls().size() != 3:
		failures.append("card event base did not expose three choices")
	await _click_choice(scene, 0)
	await process_frame
	if str(scene.get("module_id")) != "card_draw":
		failures.append("card event did not switch to card module")
	if scene.get_choice_controls().size() != 5:
		failures.append("card module did not expose five card controls")
	await _click_choice(scene, 0)
	await process_frame
	if str(scene.get("revealed_card_id")) == "":
		failures.append("card module did not reveal selected card before result")
	await _wait_for_result(results, 180)
	if results.size() != 1:
		failures.append("card event did not emit after reveal")
	elif str(results[0].get("choice", "")) != "sealed_side_box":
		failures.append("card event emitted wrong choice")
	elif str(results[0].get("card_key", "")) != "blood":
		failures.append("card event did not preserve forced blood card")
	if str(scene.get("module_id")) != "result_receipt":
		failures.append("card event did not end on result receipt")
	var table_state: Dictionary = scene.get_table_state()
	if (table_state.get("relic_tray", []) as Array).is_empty():
		failures.append("card blood result did not preview relic")
	scene.queue_free()
	await process_frame

func _scene(map_payload: Dictionary) -> Control:
	var scene: Control = EventScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": map_payload
	})
	return scene

func _click_choice(scene: Control, index: int) -> void:
	var controls: Array[Button] = scene.get_choice_controls()
	if index < 0 or index >= controls.size():
		failures.append("choice index missing: " + str(index))
		return
	var button := controls[index]
	var pos := Rect2(button.position, button.size).get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	button.get_viewport().push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	release.global_position = pos
	button.get_viewport().push_input(release, true)
	await process_frame

func _wait_for_result(results: Array[Dictionary], max_frames: int) -> void:
	for i in range(max_frames):
		if results.size() > 0:
			return
		await process_frame
