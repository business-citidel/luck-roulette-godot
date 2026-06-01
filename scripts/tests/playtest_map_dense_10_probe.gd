extends SceneTree

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

	await _show_map("00_dense_10_start", 0, [])
	await _show_map("01_dense_10_first_branch", 1, ["d0"])
	await _show_map("02_dense_10_mid_branch", 3, ["d0", "d1", "d2"])
	await _show_map("03_dense_10_rest_current", 4, ["d0", "d1", "d2", "d3"])
	await _show_map("04_dense_10_late_shop", 6, ["d0", "d1", "d2", "d3", "d4", "d5"])
	await _show_map("05_dense_10_boss_gate", 7, ["d0", "d1", "d2", "d3", "d4", "d5", "d6"])

	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("dense 10 map probe playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_map(name: String, map_step: int, completed_nodes: Array[String]) -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"map_variant": "dense_10",
		"map_step": map_step,
		"completed_nodes": completed_nodes,
		"player_hp": 31,
		"player_max_hp": 42,
		"gold": 42,
		"relic_ids": ["loaded_die", "green_purse"],
		"next_combat_mods": []
	})
	root.add_child(active_scene)
	await _settle(18)
	await _shot(name)

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
