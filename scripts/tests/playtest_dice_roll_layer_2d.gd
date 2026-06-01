extends SceneTree

const DiceRollLayer2D := preload("res://scripts/ui/dice_roll_layer_2d.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var result_value := 0

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)

	root.size = Vector2i(1280, 720)
	var layer: Control = DiceRollLayer2D.new()
	root.add_child(layer)
	layer.configure({
		"theme": "event",
		"tray_rect": Rect2(Vector2(430, 288), Vector2(420, 238))
	})
	layer.roll_finished.connect(func(value: int) -> void:
		result_value = value
	)
	await _settle(8)
	layer.roll({"forced_value": 5})
	await _settle(16)
	if shot_dir != "":
		await _shot("01_dice_2d_roll_motion")
	await _wait_for_result(180)
	await _settle(8)
	if shot_dir != "":
		await _shot("02_dice_2d_roll_result")

	if result_value != 5:
		failures.append("2D dice playtest did not emit forced result 5: " + str(result_value))
	if bool(layer.is_rolling()):
		failures.append("2D dice layer stayed rolling")

	layer.queue_free()
	await process_frame
	if failures.is_empty():
		print("2D dice roll layer playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _wait_for_result(max_frames: int) -> void:
	for i in range(max_frames):
		if result_value >= 1 and result_value <= 6:
			return
		await process_frame

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
