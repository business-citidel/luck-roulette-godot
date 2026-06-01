extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var failures: Array[String] = []

func _initialize() -> void:
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
	var pause_overlay = run_root.get("pause_overlay")
	if pause_overlay == null:
		failures.append("run root should install pause overlay")
	elif not bool(pause_overlay.visible):
		failures.append("pause overlay should open over map")
	await run_root._test_pause_action("resume")
	await _settle(4)
	if pause_overlay != null and bool(pause_overlay.visible):
		failures.append("resume should close pause overlay")
	run_root._test_open_pause()
	pause_overlay = run_root.get("pause_overlay")
	pause_overlay._request_action("abandon_run")
	await _settle(2)
	if not bool(pause_overlay.get("confirming_abandon")):
		failures.append("abandon should require confirmation")
	pause_overlay._request_action("resume")
	await _settle(2)
	if bool(pause_overlay.get("confirming_abandon")):
		failures.append("resume should cancel abandon confirmation")
	pause_overlay._request_action("abandon_run")
	await _settle(2)
	pause_overlay._request_action("abandon_run")
	await _wait_for_run_scene(run_root, "title", 900)
	if str(run_root.get("phase")) != "title":
		failures.append("confirmed abandon should return to title")
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)
	run_root._test_open_pause()
	await run_root._test_pause_action("main_menu")
	await _wait_for_run_scene(run_root, "title", 900)
	if str(run_root.get("phase")) != "title":
		failures.append("pause main menu action should return to title")
	if paused:
		failures.append("main menu action should leave scene tree unpaused")
	run_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("pause overlay contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
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
