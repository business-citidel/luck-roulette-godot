extends SceneTree

const MAIN_SCENE := "res://scenes/battle/battle_scene.tscn"

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)

	var scene: PackedScene = load(MAIN_SCENE)
	if scene == null:
		push_error("Could not load main scene")
		quit(1)
		return

	var main: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(main)
	await _settle(14)
	await _shot("00_table_dice_prop", main)

	main._roll_dice()
	await _settle(12)
	await _shot("01_table_dice_roll_motion", main)
	await _wait_for_dice_roll(main, 180)
	await _settle(8)
	await _shot("02_table_dice_result_focus", main)
	await _mouse_click(main, main._die_rect(0).get_center())
	await _settle(14)
	await _shot("03_table_dice_locked", main)

	if main.ritual_director.active_ritual != null:
		failures.append("inline table dice opened a ritual")
	if not main.dice_rolled:
		failures.append("combat table did not roll dice")
	if main.phase != "dice":
		failures.append("combat table should stay in dice phase before confirm")

	if failures.is_empty():
		print("ritual scene playtest passed")
		main.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		main.queue_free()
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

func _wait_for_dice_roll(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(main.get("dice_rolled")):
			return
		await process_frame

func _wait_for_ritual(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if main.ritual_director != null and main.ritual_director.active_ritual != null:
			return
		await process_frame

func _wait_for_ritual_close(main: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if main.ritual_director != null and main.ritual_director.active_ritual == null:
			return
		await process_frame

func _mouse_click(control: Control, pos: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	control._gui_input(press)
	await _settle(1)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	control._gui_input(release)

func _shot(name: String, main: Control) -> void:
	main._update_visual_layers()
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
