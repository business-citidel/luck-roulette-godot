extends SceneTree

const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const EventScene := preload("res://scenes/run/event_scene.tscn")

var shot_dir := ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	DemoSettingsService.update_value("language", "en")

	await _show_event("standard_table", {})
	await _shot("01_event_base_en")
	active_scene._choose_trade()
	await _settle(8)
	await _shot("02_event_result_en")

	await _show_event("red_pin_detour", {})
	await _shot("03_event_story_intro_en")
	active_scene._choose_by_id("story_intro_next")
	await _settle(8)
	await _shot("04_event_story_next_en")
	active_scene._choose_by_id("story_intro_next")
	await _settle(8)
	await _shot("05_event_story_choices_en")

	await _show_event("backroom_die_test", {"dice_forced_values": [4, 5]})
	active_scene._choose_by_id("backroom_die_roll")
	await _settle(8)
	await _shot("06_event_dice_ready_en")
	active_scene._choose_by_id("dice_roll_now")
	await _settle(16)
	await _shot("07_event_dice_motion_en")
	await _wait_until_result(180, "dice")
	await _settle(8)
	await _shot("08_event_dice_result_en")

	await _show_event("crooked_wheel_bet", {"roulette_forced_slot": "jackpot"})
	active_scene._choose_by_id("crooked_wheel_risky")
	await _settle(8)
	await _shot("09_event_roulette_ready_en")
	active_scene._choose_by_id("roulette_spin_now")
	await _settle(16)
	await _shot("10_event_roulette_motion_en")
	await _wait_until_result(180, "roulette")
	await _settle(8)
	await _shot("11_event_roulette_result_en")

	await _show_event("sealed_side_box", {"card_forced_index": 1})
	active_scene._choose_by_id("sealed_cards_draw")
	await _settle(8)
	await _shot("12_event_card_draw_en")
	active_scene._choose_by_id("event_card_0")
	await _settle(10)
	await _shot("13_event_card_reveal_en")
	await _wait_until_result(180, "card")
	await _settle(8)
	await _shot("14_event_card_result_en")

	DemoSettingsService.update_value("language", "ko")
	await _clear_active_scene()
	if failures.is_empty():
		print("language event proof passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_event(event_id: String, map_payload: Dictionary) -> void:
	await _clear_active_scene()
	active_scene = EventScene.instantiate()
	var payload := map_payload.duplicate(true)
	if event_id != "standard_table":
		payload["event_id"] = event_id
	active_scene.configure({
		"run_state": {
			"gold": 24,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": [],
			"seed_text": "language_event_proof"
		},
		"map_result": payload
	})
	active_scene.completed.connect(func(_result: Dictionary) -> void: pass)
	root.add_child(active_scene)
	await _settle(8)

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null
	await process_frame

func _wait_until_result(max_frames: int, label: String) -> void:
	for i in range(max_frames):
		if active_scene != null and str(active_scene.get("module_id")) == "result_receipt":
			return
		await process_frame
	failures.append("event " + label + " proof did not reach result receipt")

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
	await _settle(3)
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path := shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
