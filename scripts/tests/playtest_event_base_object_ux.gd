extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")
const EventBaseChoiceObjectNode := preload("res://scripts/ui/event_base_choice_object_node.gd")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	await _show_event("standard_table")
	await _shot("event_base_object_01_standard_ready")
	await _hover_choice(1, "event_base_object_02_standard_hover_relic")
	active_scene._choose_by_id("event_relic_trade")
	await _settle(6)
	await _shot("event_base_object_03_standard_receipt")

	await _show_event("backroom_die_test")
	await _shot("event_base_object_04_dice_ready")
	await _hover_choice(0, "event_base_object_05_dice_hover_roll")
	active_scene._choose_by_id("backroom_die_roll")
	await _settle(6)
	await _shot("event_base_object_06_dice_module")

	await _show_event("crooked_wheel_bet")
	await _shot("event_base_object_07_roulette_ready")
	await _hover_choice(1, "event_base_object_08_roulette_hover_risky")
	active_scene._choose_by_id("crooked_wheel_risky")
	await _settle(6)
	await _shot("event_base_object_09_roulette_module")

	await _show_event("sealed_side_box")
	await _shot("event_base_object_10_card_ready")
	await _hover_choice(0, "event_base_object_11_card_hover_draw")
	active_scene._choose_by_id("sealed_cards_draw")
	await _settle(6)
	await _shot("event_base_object_12_card_module")

	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("event base object UX playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_event(event_id: String) -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	active_scene = _scene(event_id)
	root.add_child(active_scene)
	await _settle(8)

func _scene(event_id: String) -> Control:
	var scene: Control = EventScene.instantiate()
	var map_payload := {}
	if event_id != "standard_table":
		map_payload["event_id"] = event_id
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

func _hover_choice(index: int, shot_name: String) -> void:
	var controls: Array[Button] = active_scene.get_choice_controls()
	if index < 0 or index >= controls.size():
		failures.append("event base object missing hover control " + str(index))
		return
	var node := controls[index] as EventBaseChoiceObjectNode
	if node == null:
		failures.append("event base choice is not EventBaseChoiceObjectNode")
		return
	node.set_hovered(true)
	await _settle(12)
	await _shot(shot_name)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("\\", "/").replace("--shot-dir=", "")
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
