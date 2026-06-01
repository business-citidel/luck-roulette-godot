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

	await _show_red_pin()
	await _show_shop_coupon()
	await _show_relic_pouch()

	if active_scene != null:
		active_scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("event story stakes playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_red_pin() -> void:
	await _show_event({"event_id": "red_pin_detour", "dice_forced_values": [5, 5]})
	await _shot("01_red_pin_story")
	await _advance_story()
	await _shot("02_red_pin_choices")
	active_scene._choose_by_id("detour_press")
	await _settle(4)
	await _shot("03_red_pin_dice_ready")
	active_scene._choose_by_id("dice_roll_now")
	await _wait_until_result(180)
	await _settle(8)
	await _shot("04_red_pin_result")

func _show_shop_coupon() -> void:
	await _show_event({"event_id": "shop_coupon_tag", "roulette_forced_slot": "jackpot"})
	await _shot("05_coupon_story")
	await _advance_story()
	await _shot("06_coupon_choices")
	active_scene._choose_by_id("coupon_steal")
	await _settle(4)
	await _shot("07_coupon_roulette_ready")
	active_scene._choose_by_id("roulette_spin_now")
	await _wait_until_result(180)
	await _settle(8)
	await _shot("08_coupon_result")

func _show_relic_pouch() -> void:
	await _show_event({"event_id": "relic_pouch_ritual", "card_forced_index": 5})
	await _shot("09_pouch_story")
	await _advance_story()
	await _shot("10_pouch_choices")
	active_scene._choose_by_id("pouch_paid_reveal")
	await _settle(4)
	await _shot("11_pouch_card_ready")
	active_scene._choose_by_id("event_card_0")
	await _settle(8)
	await _shot("12_pouch_card_reveal")
	await _wait_until_result(180)
	await _settle(8)
	await _shot("13_pouch_result")

func _show_event(map_payload: Dictionary) -> void:
	_clear_active_scene()
	active_scene = EventScene.instantiate()
	active_scene.configure({
		"run_state": {
			"seed_text": "event-story-stakes-proof",
			"gold": 30,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": map_payload
	})
	root.add_child(active_scene)
	await _settle(6)

func _advance_story() -> void:
	var guard := 0
	while active_scene != null and str(active_scene.get("module_id")) == "story_intro" and guard < 6:
		active_scene._choose_by_id("story_intro_next")
		guard += 1
		await _settle(4)

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null
	await process_frame

func _wait_until_result(max_frames: int) -> void:
	for i in range(max_frames):
		if active_scene != null and str(active_scene.get("module_id")) == "result_receipt":
			return
		await process_frame
	failures.append("story stakes playtest did not reach result receipt")

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
