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
	await run_root._test_mount_combat_encounter("opening_debt")
	await _wait_for_combat(run_root, 900)
	await run_root._test_finish_active_combat_victory("summary-normal")
	await _wait_for_run_scene(run_root, "reward", 900)
	run_root._test_accept_reward_direct()
	await _wait_for_run_scene(run_root, "map", 900)
	var stats: Dictionary = run_root.get("run_stats")
	if int(stats.get("battles_won", 0)) < 1:
		failures.append("run stats should count won combat")
	if int(stats.get("rewards_claimed", 0)) < 1:
		failures.append("run stats should count claimed reward")
	if str(stats.get("character_id", "")) == "":
		failures.append("run stats should carry character id")
	run_root._test_force_run_clear()
	await _wait_for_terminal_phase(run_root, "run_clear", 900)
	var end_scene = run_root.run_director.active_scene
	if end_scene == null:
		failures.append("run clear should mount end scene")
	else:
		var end_stats: Dictionary = end_scene.get("run_stats")
		if int(end_stats.get("battles_won", 0)) < 1:
			failures.append("run end should receive battle stats")
		if int(end_stats.get("rewards_claimed", 0)) < 1:
			failures.append("run end should receive reward stats")
	run_root.queue_free()
	await process_frame
	if failures.is_empty():
		print("run result summary stats smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

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

func _wait_for_terminal_phase(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == expected:
			return
		await process_frame
	failures.append("timed out waiting for terminal phase " + expected)

