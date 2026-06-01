extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")
const EventCardNode := preload("res://scripts/ui/event_card_node.gd")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	active_scene = _scene()
	root.add_child(active_scene)
	await _settle(6)
	active_scene._choose_by_id("sealed_cards_draw")
	await _settle(6)
	await _shot("card_object_01_ready")
	var controls: Array[Button] = active_scene.get_choice_controls()
	if controls.size() != 5:
		failures.append("card object UX expected five card controls")
	else:
		var hover_card := controls[2] as EventCardNode
		if hover_card == null:
			failures.append("card object UX controls are not EventCardNode buttons")
		else:
			hover_card.set_hovered(true)
			await _settle(12)
			await _shot("card_object_02_hover")
		active_scene._choose_by_id("event_card_0")
		await _settle(16)
		await _shot("card_object_03_reveal")
		await _wait_until_result(120)
		await _settle(8)
		await _shot("card_object_04_result")
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("event card object UX playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _scene() -> Control:
	var scene: Control = EventScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": {
			"event_id": "sealed_side_box",
			"card_forced_index": 1
		}
	})
	return scene

func _wait_until_result(max_frames: int) -> void:
	for i in range(max_frames):
		if active_scene != null and str(active_scene.get("module_id")) == "result_receipt":
			return
		await process_frame
	failures.append("card object UX did not reach result receipt")

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
