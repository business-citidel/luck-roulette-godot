extends SceneTree

const TitleScene := preload("res://scenes/run/title_scene.tscn")
const SettingsScene := preload("res://scenes/run/settings_scene.tscn")
const GalleryScene := preload("res://scenes/run/gallery_scene.tscn")
const RunState := preload("res://scripts/resources/run_state.gd")
const DemoSaveService := preload("res://scripts/systems/demo_save_service.gd")

var shot_dir := ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	DemoSaveService.clear_save()
	await _show_title(false)
	await _shot("01_title_no_save")

	var run_state: RunState = RunState.new()
	run_state.seed_text = "shell-proof-save"
	run_state.gold = 34
	run_state.player_hp = 39
	run_state.character_id = "double_attack_dice"
	DemoSaveService.save_run(run_state, {"battles_won": 1})
	await _show_title(true)
	await _shot("02_title_continue_available")

	await _show_settings()
	await _shot("03_settings_from_title")

	await _show_gallery()
	await _shot("04_gallery_relics")

	DemoSaveService.clear_save()
	_clear_active_scene()
	await process_frame
	if failures.is_empty():
		print("demo shell external wheel playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_title(has_continue: bool) -> void:
	_clear_active_scene()
	active_scene = TitleScene.instantiate()
	active_scene.configure({"seed_text": "demo-shell-proof", "has_continue": has_continue})
	root.add_child(active_scene)
	await _settle(8)

func _show_settings() -> void:
	_clear_active_scene()
	active_scene = SettingsScene.instantiate()
	active_scene.configure({})
	root.add_child(active_scene)
	await _settle(8)

func _show_gallery() -> void:
	_clear_active_scene()
	active_scene = GalleryScene.instantiate()
	active_scene.configure({"category": "relics"})
	root.add_child(active_scene)
	await _settle(8)

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null

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
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)

