extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	await _show_map("00_start_combat", 0)
	await _show_map("01_mid_event_mix", 10)
	await _show_map("02_late_route_mix", 16)
	await _show_map("03_boss_gate", 19)
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("map token runtime 9 playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_map(name: String, step: int) -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	var seed_text := "map-token-runtime-9-proof"
	var nodes := EncounterCatalog.map_nodes("scroll_20_random", seed_text + ":floor:1")
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"map_variant": "scroll_20_random",
		"seed_text": seed_text,
		"floor_index": 1,
		"max_floor": 3,
		"map_step": step,
		"completed_nodes": _completed_prefix(nodes, step),
		"player_hp": 36,
		"player_max_hp": 42,
		"gold": 48,
		"relic_ids": ["loaded_die", "green_purse"],
		"next_combat_mods": []
	})
	root.add_child(active_scene)
	await _settle(18)
	await _shot(name)

func _completed_prefix(nodes: Array[Dictionary], through_step: int) -> Array[String]:
	var result: Array[String] = []
	for step in range(through_step):
		for node in nodes:
			if int(node.get("node_index", -1)) == step:
				result.append(str(node.get("node_id", "")))
				break
	return result

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
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path := shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
