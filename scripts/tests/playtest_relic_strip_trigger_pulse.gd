extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"

var shot_dir: String = ""
var failures: Array[String] = []
var run_root: Control

func _initialize() -> void:
	print("relic strip trigger pulse playtest start")
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

	await _wait_for_phase("title", 900)
	run_root.run_state.relic_ids.append("loaded_die")
	run_root.run_state.relic_ids.append("green_purse")
	run_root._test_mount_combat_encounter("crook_table")
	await _wait_for_combat(900)
	await _settle(10)
	await _shot("00_combat_owned_relic_strip")

	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("combat did not mount")
	else:
		combat._show_feedback_from_effects([
			{
				"relic_id": "loaded_die",
				"effect_id": "attack_die_plus_one",
				"name": "Loaded Die"
			},
			{
				"relic_id": "green_purse",
				"effect_id": "green_cash_bonus",
				"name": "Green Purse"
			}
		], "proof")
		await _settle(3)
		await _shot("01_simultaneous_relic_strip_pulse")

	if run_root != null:
		run_root.queue_free()
		await process_frame
	if failures.is_empty():
		print("relic strip trigger pulse playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wait_for_phase(expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if run_root != null and str(run_root.get("phase")) == expected:
			return
		await process_frame
	failures.append("timed out waiting for phase " + expected)

func _wait_for_combat(max_frames: int) -> void:
	for i in range(max_frames):
		if run_root != null and str(run_root.get("phase")) == "combat" and run_root.get("active_combat") != null:
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
		failures.append("viewport texture unavailable for " + name)
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
