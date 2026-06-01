extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var shot_dir := ""
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var scene: PackedScene = load(RUN_SCENE)
	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)

	await _wait_for_run_scene(run_root, "title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)
	run_root._test_open_pause()
	await _settle(8)
	await _shot("01_pause_over_map")
	var pause_overlay = run_root.get("pause_overlay")
	if pause_overlay != null:
		pause_overlay._request_action("abandon_run")
		await _settle(8)
		await _shot("01b_pause_abandon_confirm")
		pause_overlay._request_action("resume")
		await _settle(4)
	await run_root._test_pause_action("resume")
	await _settle(8)

	run_root._test_select_current_map_node()
	await _wait_for_combat(run_root, 900)
	await _settle(24)
	run_root._test_open_pause()
	await _settle(8)
	await _shot("02_pause_over_battle")
	run_root._test_pause_action("settings")
	await _settle(8)
	await _shot("03_pause_settings")

	if failures.is_empty():
		print("pause overlay proof playtest passed")
		run_root.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_root.queue_free()
		await process_frame
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame
	failures.append("timed out waiting for run scene " + expected)

func _wait_for_combat(run_root: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if run_root.get("active_combat") != null:
			return
		await process_frame
	failures.append("timed out waiting for combat")

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
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path := shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
