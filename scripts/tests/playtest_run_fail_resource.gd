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
		push_error("Could not load run root")
		quit(1)
		return
	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)
	await _settle(20)
	if run_root.has_method("_test_force_run_failed"):
		run_root._test_force_run_failed()
		await _settle(10)
		await _shot("00_run_failed_hp_zero")
		if str(run_root.get("phase")) != "run_failed":
			failures.append("run fail playtest did not enter run_failed")
	else:
		failures.append("missing run fail helper")

	if failures.is_empty():
		print("run fail resource playtest passed")
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

func _shot(name: String) -> void:
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
