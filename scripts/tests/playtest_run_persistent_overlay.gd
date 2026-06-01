extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var shot_dir: String = ""
var failures: Array[String] = []
var run_root: Control

func _initialize() -> void:
	print("run persistent overlay playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	var scene: PackedScene = load(RUN_SCENE)
	run_root = scene.instantiate()
	root.add_child(run_root)

	await _wait_for_run_scene("title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene("intro", 900)
	run_root._test_skip_intro()
	await _wait_for_run_scene("map", 900)
	await _settle(8)
	await _shot("00_map_overlay_top_hud")

	run_root.run_state.relic_ids.append("loaded_die")
	run_root._test_mount_combat_encounter("crook_table")
	await _wait_for_combat(900)
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("combat missing for overlay screenshot")
	else:
		combat.set("player_hp", 19)
		combat._render()
	await _settle(8)
	await _shot("01_combat_overlay_status_cleanup")
	if combat != null:
		combat.queue_free()
		run_root.set("active_combat", null)
		await process_frame

	run_root.run_director.show_terminal_scene("shop", load("res://scenes/run/shop_scene.tscn"), {
		"run_state": run_root.run_state.to_payload(),
		"map_result": {"node_type": "shop", "node_index": 2}
	})
	run_root.set("phase", "shop")
	run_root._sync_overlay()
	await _settle(8)
	await _shot("01_shop_overlay_with_proceed")

	_press_overlay_proceed()
	await _settle(8)
	await _shot("02_shop_after_overlay_proceed")

	run_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("run persistent overlay playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _press_overlay_proceed() -> void:
	var overlay: Control = run_root.get("run_overlay") as Control
	if overlay == null:
		failures.append("overlay missing for proceed")
		return
	var button: Button = overlay.get("proceed_button") as Button
	if button == null:
		failures.append("proceed button missing")
		return
	button.pressed.emit()

func _wait_for_run_scene(expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame
	failures.append("timed out waiting for " + expected)

func _wait_for_combat(max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == "combat" and run_root.get("active_combat") != null:
			return
		await process_frame
	failures.append("timed out waiting for combat")

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
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
