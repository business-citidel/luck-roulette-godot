extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)

	var backdrop := ColorRect.new()
	backdrop.color = Color("#11151c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var run_state: Resource = RunStateScript.new()
	run_state.reset_starting_marbles()
	var overlay := RunPersistentOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.configure(run_state.to_payload(), "map", false, false, "")
	await _settle(3)
	_capture("01_top_bar_marble_button")

	var button := overlay.get_node_or_null("RunOverlayMarbleDeckButton") as Button
	if button == null:
		failures.append("missing marble deck button")
	else:
		button.pressed.emit()
	await _settle(3)
	_capture("02_marble_deck_gallery_open")
	var slot_rect: Rect2 = overlay.call("_marble_gallery_slot_rect", 0)
	overlay.call("_update_hovered_marble", slot_rect.get_center())
	overlay.queue_redraw()
	RenderingServer.force_draw(false)
	await _move_mouse(slot_rect.get_center())
	await _settle(3)
	_capture("03_marble_deck_gallery_hover_detail")

	overlay.queue_free()
	backdrop.queue_free()
	await process_frame

	if failures.is_empty():
		print("run marble gallery overlay playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _settle(frames: int) -> void:
	for _i in range(frames):
		await process_frame

func _move_mouse(pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	root.push_input(motion, true)
	await process_frame

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _capture(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("missing viewport texture for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed saving screenshot " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
