extends SceneTree

const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const EventScene := preload("res://scenes/run/event_scene.tscn")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	var ids := EventCatalog.catalog_event_ids()
	for i in range(ids.size()):
		var event_id := str(ids[i])
		await _show_event(event_id)
		if active_scene.get_choice_controls().size() != 3:
			failures.append(event_id + " did not expose three base controls")
		await _shot(str(i + 1).pad_zeros(2) + "_" + event_id)

	if active_scene != null:
		active_scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("event catalog all packs playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_event(event_id: String) -> void:
	_clear_active_scene()
	active_scene = EventScene.instantiate()
	active_scene.configure({
		"run_state": {
			"seed_text": "event-catalog-all-packs-proof",
			"gold": 30,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": {
			"event_id": event_id,
			"skip_story_intro": true
		}
	})
	root.add_child(active_scene)
	await _settle(6)

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null
	await process_frame

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
