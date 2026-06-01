extends SceneTree

const FixtureScene := preload("res://scenes/run/run_choice_fixture.tscn")

var failures: Array[String] = []
var shot_dir := ""

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	shot_dir = _arg_value("--shot-dir")
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	await _shot_fixture("run_choice_fixture_normal", {})
	await _shot_fixture("run_choice_fixture_unaffordable", {"mode": "unaffordable"})
	await _shot_fixture("run_choice_fixture_resolved", {"mode": "resolved"})
	if failures.is_empty():
		print("run choice fixture playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _shot_fixture(name: String, payload: Dictionary) -> void:
	var scene: Control = FixtureScene.instantiate()
	scene.configure(payload)
	root.add_child(scene)
	await _settle(3)
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		scene.queue_free()
		await process_frame
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
	else:
		var path: String = shot_dir.path_join(name + ".png")
		var err: Error = image.save_png(path)
		if err != OK:
			failures.append("failed to save " + path + ": " + str(err))
		else:
			print("saved screenshot: " + path)
	scene.queue_free()
	await process_frame

func _settle(frames: int) -> void:
	for _i in range(frames):
		await process_frame

func _arg_value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix + "="):
			return arg.substr(prefix.length() + 1)
	return ""
