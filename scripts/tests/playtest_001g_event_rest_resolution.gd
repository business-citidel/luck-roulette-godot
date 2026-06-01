extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	print("001g event/rest resolution playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_event(-1)
	await _shot("00_event_offer_cards_normal")
	await _show_event(1)
	await _shot("01_event_relic_trade_card_clicked_result_preview")
	await _show_event(2)
	await _shot("02_event_risk_gold_queued_note_preview")
	await _show_rest(-1)
	await _shot("03_rest_offer_cards_normal")
	await _show_rest(0)
	await _shot("04_rest_heal_card_clicked_result_preview")
	await _show_rest(1)
	await _shot("05_rest_prepare_queued_note_preview")
	await _show_map_after_event()
	await _shot("06_map_after_event_result_continuity")
	await _show_map_after_rest()
	await _shot("07_map_after_rest_prepare_continuity")

	await _clear_active()
	if failures.is_empty():
		print("001g event/rest resolution playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_event(click_index: int) -> void:
	await _clear_active()
	active_scene = EventScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	active_scene.completed.connect(func(_result: Dictionary) -> void: pass)
	root.add_child(active_scene)
	await _settle(6)
	if click_index >= 0:
		await _click_card_center(active_scene, click_index)
		await _settle(6)

func _show_rest(click_index: int) -> void:
	await _clear_active()
	active_scene = RestScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 12,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	active_scene.completed.connect(func(_result: Dictionary) -> void: pass)
	root.add_child(active_scene)
	await _settle(6)
	if click_index >= 0:
		await _click_card_center(active_scene, click_index)
		await _settle(6)

func _show_map_after_event() -> void:
	await _clear_active()
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"gold": 36,
		"player_hp": 30,
		"player_max_hp": 42,
		"relic_ids": [],
		"next_combat_mods": [{"id": "event_hot_table", "enemy_damage_delta": 2}],
		"map_step": 2,
		"completed_nodes": ["n0", "n1"]
	})
	root.add_child(active_scene)
	await _settle(6)

func _show_map_after_rest() -> void:
	await _clear_active()
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"gold": 12,
		"player_hp": 30,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die"],
		"next_combat_mods": [{"id": "rest_prepared_table", "enemy_damage_delta": -3}],
		"map_step": 4,
		"completed_nodes": ["n0", "n1", "n2", "n3"]
	})
	root.add_child(active_scene)
	await _settle(6)

func _click_card_center(scene: Control, index: int) -> void:
	var pos := _choice_rect(scene, index).get_center()
	var target := _button_at(scene, pos)
	if target == null:
		failures.append("no card hit button found at " + str(pos))
		return
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	target.get_viewport().push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	release.global_position = pos
	target.get_viewport().push_input(release, true)
	await process_frame

func _button_at(scene: Control, pos: Vector2) -> Button:
	for button in scene.get_choice_controls():
		var rect := Rect2(button.position, button.size)
		if rect.has_point(pos):
			return button
	return null

func _choice_rect(scene: Control, index: int) -> Rect2:
	var controls: Array[Button] = scene.get_choice_controls()
	if index >= 0 and index < controls.size() and scene.has_method("get_choice_rect"):
		var choice_id := str(controls[index].name).replace("RunChoice_", "")
		var rect: Rect2 = scene.get_choice_rect(choice_id)
		if rect.size != Vector2.ZERO:
			return rect
	return UiLayoutSpec.offer_card_rect(index)

func _clear_active() -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "")
	return ""

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

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
