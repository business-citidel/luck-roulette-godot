extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_standard_event()
	await _shot("01_event_screen_base")
	active_scene._choose_trade()
	await _settle(4)
	await _shot("02_event_result_receipt_existing_choice")

	await _show_dice_event()
	await _shot("03_event_dice_base")
	active_scene._choose_by_id("backroom_die_roll")
	await _settle(4)
	await _shot("04_event_dice_check_ready")
	active_scene._choose_by_id("dice_roll_now")
	await _settle(16)
	await _shot("05_event_dice_check_motion")
	await _wait_until_result(180)
	await _settle(8)
	await _shot("06_event_dice_result_receipt")

	await _show_roulette_event()
	await _shot("07_event_roulette_base")
	active_scene._choose_by_id("crooked_wheel_risky")
	await _settle(4)
	await _shot("08_event_roulette_check_ready")
	active_scene._choose_by_id("roulette_spin_now")
	await _settle(16)
	await _shot("09_event_roulette_check_motion")
	await _wait_until_result(180)
	await _settle(8)
	await _shot("10_event_roulette_result_receipt")

	await _show_card_event()
	await _shot("11_event_card_base")
	active_scene._choose_by_id("sealed_cards_draw")
	await _settle(4)
	await _shot("12_event_card_draw_ready")
	active_scene._choose_by_id("event_card_0")
	await _settle(8)
	await _shot("13_event_card_reveal")
	await _wait_until_result(180)
	await _settle(8)
	await _shot("14_event_card_result_receipt")

	if active_scene != null:
		active_scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("event module flow playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_standard_event() -> void:
	_clear_active_scene()
	active_scene = _scene({})
	root.add_child(active_scene)
	await _settle(6)

func _show_dice_event() -> void:
	_clear_active_scene()
	active_scene = _scene({
		"event_id": "backroom_die_test",
		"dice_forced_values": [4, 5]
	})
	root.add_child(active_scene)
	await _settle(6)

func _show_roulette_event() -> void:
	_clear_active_scene()
	active_scene = _scene({
		"event_id": "crooked_wheel_bet",
		"roulette_forced_slot": "jackpot"
	})
	root.add_child(active_scene)
	await _settle(6)

func _show_card_event() -> void:
	_clear_active_scene()
	active_scene = _scene({
		"event_id": "sealed_side_box",
		"card_forced_index": 1
	})
	root.add_child(active_scene)
	await _settle(6)

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

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null

func _wait_until_result(max_frames: int) -> void:
	for i in range(max_frames):
		if active_scene != null and str(active_scene.get("module_id")) == "result_receipt":
			return
		await process_frame
	failures.append("event dice playtest did not reach result receipt")

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _shot(name: String) -> void:
	if shot_dir == "":
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
