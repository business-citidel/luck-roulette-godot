extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")
const EventPropActionObjectNode := preload("res://scripts/ui/event_prop_action_object_node.gd")
const EventCardNode := preload("res://scripts/ui/event_card_node.gd")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_dice_module()
	await _shot("event_prop_matrix_01_dice_table_ready")
	await _hover_prop(0, "event_prop_matrix_02_dice_table_hover")

	await _show_roulette_module()
	await _shot("event_prop_matrix_03_roulette_wheel_ready")
	await _hover_prop(0, "event_prop_matrix_04_roulette_wheel_hover")

	await _show_card_module()
	await _shot("event_prop_matrix_05_card_objects_ready")
	var controls: Array[Button] = active_scene.get_choice_controls()
	if controls.is_empty() or not (controls[0] is EventCardNode):
		failures.append("card module should expose EventCardNode objects")

	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("event prop action matrix playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_dice_module() -> void:
	await _show_event({"event_id": "backroom_die_test", "dice_forced_values": [4, 5]})
	active_scene._choose_by_id("backroom_die_roll")
	await _settle(8)
	var controls: Array[Button] = active_scene.get_choice_controls()
	if controls.is_empty() or not (controls[0] is EventPropActionObjectNode):
		failures.append("dice module should expose EventPropActionObjectNode")

func _show_roulette_module() -> void:
	await _show_event({"event_id": "crooked_wheel_bet", "roulette_forced_slot": "jackpot"})
	active_scene._choose_by_id("crooked_wheel_risky")
	await _settle(8)
	var controls: Array[Button] = active_scene.get_choice_controls()
	if controls.is_empty() or not (controls[0] is EventPropActionObjectNode):
		failures.append("roulette module should expose EventPropActionObjectNode")

func _show_card_module() -> void:
	await _show_event({"event_id": "sealed_side_box", "card_forced_index": 1})
	active_scene._choose_by_id("sealed_cards_draw")
	await _settle(8)

func _show_event(map_payload: Dictionary) -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	active_scene = EventScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": map_payload
	})
	root.add_child(active_scene)
	await _settle(8)

func _hover_prop(index: int, shot_name: String) -> void:
	var controls: Array[Button] = active_scene.get_choice_controls()
	if index < 0 or index >= controls.size():
		failures.append("event prop control missing " + str(index))
		return
	var prop := controls[index] as EventPropActionObjectNode
	if prop == null:
		failures.append("event prop control is not EventPropActionObjectNode")
		return
	prop.set_hovered(true)
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
