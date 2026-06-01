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
	await _settle(10)
	await _shot("00_initial", main)

	main._roll_dice()
	await _wait_for_dice_roll(main, 180)
	await _settle(8)
	_expect_beat(main, "dice_hand", "dice roll")
	await _shot("01_dice_focus", main)

	await _mouse_click(main, main._die_rect(0).get_center())
	await _settle(18)
	if not main.dice_locked[0]:
		failures.append("die lock did not toggle through gui input")
	await _shot("02_die_locked", main)

	main._take_marbles()
	await _settle(26)
	_expect_beat(main, "marble_pouch", "take marbles")
	await _shot("03_marble_pouch_focus", main)

	var hand_center: Vector2 = main._hand_rect().get_center()
	await _mouse_press(main, hand_center)
	for i in range(8):
		var drag_pos: Vector2 = hand_center + Vector2(14.0 * float(i + 1), -6.0 * float(i % 3))
		await _mouse_motion(main, drag_pos)
		await _settle(2)
	await _shot("04_hand_shake", main)
	await _mouse_release(main, hand_center + Vector2(112, -42))
	await _settle(8)
	_expect_beat(main, "wheel_close", "marble release")
	await _shot("05_throw_release", main)

	for i in range(34):
		main._update_thrown_marbles(0.05)
		await _settle(1)
	if not main._marble_setup_ready():
		failures.append("marble setup did not become spin-ready")
	await _settle(16)
	await _shot("06_wheel_ready", main)

	main._start_spin()
	await _settle(24)
	_expect_beat(main, "wheel_close", "spin")
	await _shot("07_spin_wheel_close", main)

	await _wait_for_phase(main, "intervene", 120)
	if main.phase != "intervene":
		failures.append("spin did not open intervention phase")
	await _settle(18)
	await _shot("08_intervention_window", main)

	main.pending_slot = "profit"
	main.payout_multiplier = 1.0
	main._resolve_pending()
	await _settle(28)
	_expect_beat(main, "opponent_intent", "result to enemy")
	await _shot("09_opponent_reaction", main)

	if failures.is_empty():
		print("cinematic playtest passed")
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

func _wait_for_phase(main: Control, expected_phase: String, max_frames: int) -> void:
	for i in range(max_frames):
		if main.phase == expected_phase:
			return
		await process_frame

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

func _mouse_click(main: Control, world_pos: Vector2) -> void:
	await _mouse_press(main, world_pos)
	await _settle(1)
	await _mouse_release(main, world_pos)

func _mouse_press(main: Control, world_pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = _world_to_screen(world_pos)
	main._gui_input(event)

func _mouse_release(main: Control, world_pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = _world_to_screen(world_pos)
	main._gui_input(event)

func _mouse_motion(main: Control, world_pos: Vector2) -> void:
	var current_screen: Vector2 = _world_to_screen(world_pos)
	var event := InputEventMouseMotion.new()
	event.position = current_screen
	event.relative = Vector2(24, -12)
	main._gui_input(event)

func _world_to_screen(world_pos: Vector2) -> Vector2:
	return root.get_canvas_transform() * world_pos

func _expect_beat(main: Control, expected: String, label: String) -> void:
	var actual: String = main.camera_rig.get_active_beat()
	if actual != expected:
		failures.append(label + " selected camera beat " + actual + ", expected " + expected)
