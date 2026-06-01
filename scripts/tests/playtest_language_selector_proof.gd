extends SceneTree

const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const TitleScene := preload("res://scenes/run/title_scene.tscn")
const SettingsScene := preload("res://scenes/run/settings_scene.tscn")
const GalleryScene := preload("res://scenes/run/gallery_scene.tscn")
const ShellPauseOverlay := preload("res://scripts/ui/shell_pause_overlay.gd")
const RunEndScene := preload("res://scenes/run/run_end_scene.tscn")

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

	DemoSettingsService.update_value("language", "ko")
	await _show_title("ko")
	await _shot("01_title_ko")
	await _show_settings()
	await _shot("02_settings_ko")

	var language_buttons: Dictionary = active_scene.get("language_buttons")
	if language_buttons.has("en"):
		(language_buttons["en"] as Button).pressed.emit()
	await _settle(8)
	await _shot("03_settings_after_english_click")

	await _show_title("en")
	await _shot("04_title_en")
	await _show_gallery("relics")
	await _shot("05_gallery_en")
	await _show_pause_confirm()
	await _shot("06_pause_confirm_en")
	await _show_run_clear()
	await _shot("07_run_clear_en")

	DemoSettingsService.update_value("language", "ko")
	_clear_active_scene()
	await process_frame
	if failures.is_empty():
		print("language selector proof playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_title(language: String) -> void:
	DemoSettingsService.update_value("language", language)
	_clear_active_scene()
	active_scene = TitleScene.instantiate()
	active_scene.configure({"seed_text": "language-proof", "has_continue": false})
	root.add_child(active_scene)
	await _settle(8)

func _show_settings() -> void:
	_clear_active_scene()
	active_scene = SettingsScene.instantiate()
	active_scene.configure({})
	root.add_child(active_scene)
	await _settle(8)

func _show_gallery(category: String) -> void:
	_clear_active_scene()
	active_scene = GalleryScene.instantiate()
	active_scene.configure({"category": category})
	root.add_child(active_scene)
	await _settle(8)

func _show_pause_confirm() -> void:
	_clear_active_scene()
	active_scene = Control.new()
	active_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(active_scene)
	var pause := ShellPauseOverlay.new()
	active_scene.add_child(pause)
	await _settle(2)
	pause.open_for_phase("map")
	pause._request_action("abandon_run")
	await _settle(8)

func _show_run_clear() -> void:
	_clear_active_scene()
	active_scene = RunEndScene.instantiate()
	active_scene.configure({
		"result_type": "run_clear",
		"run_state": {
			"player_hp": 42,
			"player_max_hp": 42,
			"gold": 21,
			"relic_ids": [],
			"floor_index": 3,
			"max_floor": 3,
			"character_id": "double_attack_dice",
			"seed_text": "language-proof"
		},
		"combat_result": {"winnings": 34},
		"completed_node_count": 12,
		"run_stats": {
			"battles_won": 4,
			"elites_defeated": 1,
			"bosses_defeated": 1,
			"events_resolved": 2,
			"shops_visited": 1,
			"rests_used": 1,
			"floor_reached": 3,
			"character_id": "double_attack_dice",
			"seed_text": "language-proof"
		}
	})
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
	await _settle(3)
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path := shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)

