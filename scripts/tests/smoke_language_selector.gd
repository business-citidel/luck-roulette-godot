extends SceneTree

const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")
const TitleScene := preload("res://scenes/run/title_scene.tscn")
const SettingsScene := preload("res://scenes/run/settings_scene.tscn")
const GalleryScene := preload("res://scenes/run/gallery_scene.tscn")
const ShellPauseOverlay := preload("res://scripts/ui/shell_pause_overlay.gd")
const RunEndScene := preload("res://scenes/run/run_end_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_service_and_ui_text()
	await _check_settings_scene_switch()
	await _check_shell_scene_texts()
	DemoSettingsService.save_settings({
		"master_volume": 1.0,
		"bgm_volume": 0.82,
		"sfx_volume": 0.9,
		"fullscreen": false,
		"language": "ko"
	})
	DemoSettingsService.apply_settings(DemoSettingsService.load_settings())
	if failures.is_empty():
		print("language selector smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_service_and_ui_text() -> void:
	DemoSettingsService.save_settings({
		"master_volume": 0.7,
		"bgm_volume": 0.6,
		"sfx_volume": 0.5,
		"fullscreen": false,
		"language": "en"
	})
	var loaded := DemoSettingsService.load_settings()
	if str(loaded.get("language", "")) != "en":
		failures.append("settings service should persist English language")
	DemoSettingsService.apply_settings(loaded)
	if UiText.t("title.settings") != "Settings":
		failures.append("UiText should use English after applying en locale")
	DemoSettingsService.update_value("language", "ko")
	if UiText.t("title.settings") != "설정":
		failures.append("UiText should use Korean after applying ko locale")

func _check_settings_scene_switch() -> void:
	DemoSettingsService.update_value("language", "ko")
	var settings_scene: Control = SettingsScene.instantiate()
	settings_scene.configure({})
	root.add_child(settings_scene)
	await process_frame
	var back_button := settings_scene.get("back_button") as Button
	var language_buttons: Dictionary = settings_scene.get("language_buttons")
	if back_button == null or back_button.text != "뒤로":
		failures.append("settings back button should start in Korean")
	if not language_buttons.has("en"):
		failures.append("settings should expose English language button")
	else:
		(language_buttons["en"] as Button).pressed.emit()
		await process_frame
		if UiText.t("settings.title") != "Settings":
			failures.append("settings language button should switch UiText to English")
		if back_button.text != "Back":
			failures.append("settings scene should refresh button labels after language switch")
	settings_scene.queue_free()
	await process_frame

func _check_shell_scene_texts() -> void:
	DemoSettingsService.update_value("language", "en")
	var title_scene: Control = TitleScene.instantiate()
	title_scene.configure({"seed_text": "language-smoke", "has_continue": false})
	root.add_child(title_scene)
	await process_frame
	var title_settings := title_scene.get("settings_button") as Button
	var title_continue := title_scene.get("continue_button") as Button
	if title_settings == null or title_settings.text != "Settings":
		failures.append("title settings button should localize to English")
	if title_continue == null or not title_continue.text.contains("No Save"):
		failures.append("title disabled continue should show English no-save text")
	title_scene.queue_free()
	await process_frame

	var gallery_scene: Control = GalleryScene.instantiate()
	gallery_scene.configure({"category": "relics"})
	root.add_child(gallery_scene)
	await process_frame
	if str(gallery_scene.call("_category_title")) != "Relics found during runs":
		failures.append("gallery category title should localize to English")
	gallery_scene.queue_free()
	await process_frame

	var pause := ShellPauseOverlay.new()
	root.add_child(pause)
	await process_frame
	pause.open_for_phase("map")
	pause._request_action("abandon_run")
	await process_frame
	var abandon_button := (pause.get("buttons") as Dictionary).get("abandon_run") as Button
	if abandon_button == null or abandon_button.text != "Confirm Abandon":
		failures.append("pause abandon confirmation should localize to English")
	pause.queue_free()
	await process_frame

	var end_scene: Control = RunEndScene.instantiate()
	end_scene.configure({
		"result_type": "run_clear",
		"run_state": {
			"player_hp": 42,
			"player_max_hp": 42,
			"gold": 0,
			"relic_ids": [],
			"floor_index": 3,
			"max_floor": 3,
			"character_id": "double_attack_dice",
			"seed_text": "language-smoke"
		},
		"combat_result": {"winnings": 34},
		"run_stats": {"character_id": "double_attack_dice", "floor_reached": 3, "seed_text": "language-smoke"}
	})
	root.add_child(end_scene)
	await process_frame
	if end_scene.call("_character_label") != "Double Attack":
		failures.append("run end character label should localize to English")
	end_scene.queue_free()
	await process_frame

