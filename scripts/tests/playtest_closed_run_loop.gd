extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		push_error("Could not load run root scene")
		quit(1)
		return
	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)

	await _wait_for_run_scene(run_root, "title", 900)
	await _settle(12)
	await _shot("00_title_start", run_root)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	await _settle(28)
	await _shot("01_character_select_ready", run_root)
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)
	await _shot("02_map_start_with_final_route", run_root)

	run_root._test_show_map_at_step(1)
	await _settle(30)
	await _shot("03_branch_map_event_or_elite", run_root)

	var run_state = run_root.get("run_state")
	run_state.floor_index = int(run_state.max_floor)
	run_root._test_show_map_at_step(5)
	await _settle(30)
	await _shot("04_final_boss_node_visible", run_root)

	await run_root._test_mount_combat_encounter("final_house_table")
	await _wait_for_payload_monster(run_root, "final_house", 1200)
	await _settle(45)
	var boss_payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
	if str(boss_payload.get("monster_id", "")) != "final_house":
		failures.append("final node did not launch final_house")
	await _shot("05_final_house_battle", run_root)

	await run_root._test_finish_active_combat_victory("final-house-proof")
	await _wait_for_terminal_phase(run_root, "run_clear", 1200)
	await _shot("06_run_clear_with_restart_buttons", run_root)
	run_root._test_return_to_title_from_run_end()
	await _wait_for_run_scene(run_root, "title", 1200)
	await _settle(35)
	await _shot("07_returned_to_title", run_root)

	if failures.is_empty():
		print("closed run loop playtest passed")
		run_root.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_root.queue_free()
		await process_frame
		quit(1)

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

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

func _wait_for_payload_monster(run_root: Control, monster_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
		if run_root.get("active_combat") != null and str(payload.get("monster_id", "")) == monster_id:
			return
		await process_frame
	failures.append("timed out waiting for monster payload " + monster_id)

func _wait_for_terminal_phase(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == expected:
			return
		await process_frame
	failures.append("timed out waiting for terminal phase " + expected)

func _shot(name: String, run_root: Control) -> void:
	await _settle(3)
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
