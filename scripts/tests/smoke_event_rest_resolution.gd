extends SceneTree

const EventScene := preload("res://scenes/run/event_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_scene(EventScene, "event_gold", 0, "gold")
	await _check_scene(EventScene, "event_relic_trade", 1, "relic")
	await _check_scene(EventScene, "event_risk_gold", 2, "prep")
	await _check_scene(RestScene, "rest_heal", 0, "heal")
	await _check_scene(RestScene, "rest_relic", 2, "relic")
	await _check_rest_upgrade("upgrade_roulette_cell", 3)
	await _check_double_submit(EventScene, 1, "event_relic_trade")
	await _check_rest_upgrade_double_submit(3, "upgrade_roulette_cell")

	if failures.is_empty():
		print("event/rest resolution smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_scene(scene_resource: PackedScene, expected_choice: String, index: int, preview_kind: String) -> void:
	var scene: Control = _scene(scene_resource)
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	_assert_hit_rects(scene, expected_choice)
	await _click_card_center(scene, index)
	await process_frame
	if expected_choice == "upgrade_roulette_cell":
		scene._choose_roulette_cell(1)
		await process_frame
	if results.size() != 1:
		failures.append(expected_choice + " did not emit exactly once")
	elif str(results[0].get("choice", "")) != expected_choice:
		failures.append(expected_choice + " emitted wrong choice")
	if not bool(scene.get("submitted")) or str(scene.get("selected_choice")) != expected_choice:
		failures.append(expected_choice + " did not update submitted/selected")
	for button in scene.get_choice_controls():
		if not button.disabled:
			failures.append(expected_choice + " left a choice button enabled")
			break
	_assert_preview(scene, expected_choice, preview_kind)
	scene.queue_free()
	await process_frame

func _check_double_submit(scene_resource: PackedScene, index: int, expected_choice: String) -> void:
	var scene: Control = _scene(scene_resource)
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _click_card_center(scene, index)
	await _click_card_center(scene, index)
	await _click_card_center(scene, (index + 1) % 3)
	await process_frame
	if results.size() != 1:
		failures.append(expected_choice + " double/second click emitted " + str(results.size()) + " times")
	if str(scene.get("selected_choice")) != expected_choice:
		failures.append(expected_choice + " selected choice changed after second click")
	scene.queue_free()
	await process_frame

func _check_rest_upgrade(expected_choice: String, index: int) -> void:
	var scene: Control = _scene(RestScene)
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _click_card_center(scene, 1)
	await process_frame
	if results.size() != 0:
		failures.append("rest_tune should open upgrade screen without completing")
	_assert_hit_rects(scene, expected_choice)
	await _click_card_center(scene, index)
	await process_frame
	if expected_choice == "upgrade_roulette_cell":
		scene._choose_roulette_cell(1)
		await process_frame
	if results.size() != 1:
		failures.append(expected_choice + " did not emit exactly once")
	elif str(results[0].get("choice", "")) != expected_choice:
		failures.append(expected_choice + " emitted wrong choice")
	if not bool(scene.get("submitted")) or str(scene.get("selected_choice")) != expected_choice:
		failures.append(expected_choice + " did not update submitted/selected")
	for button in scene.get_choice_controls():
		if not button.disabled:
			failures.append(expected_choice + " left a choice button enabled")
			break
	_assert_preview(scene, expected_choice, "none")
	scene.queue_free()
	await process_frame

func _check_rest_upgrade_double_submit(index: int, expected_choice: String) -> void:
	var scene: Control = _scene(RestScene)
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _click_card_center(scene, 1)
	await process_frame
	await _click_card_center(scene, index)
	if expected_choice == "upgrade_roulette_cell":
		scene._choose_roulette_cell(1)
		scene._choose_roulette_cell(1)
	else:
		await _click_card_center(scene, index)
		await _click_card_center(scene, (index + 1) % 3)
	await process_frame
	if results.size() != 1:
		failures.append(expected_choice + " double/second click emitted " + str(results.size()) + " times")
	if str(scene.get("selected_choice")) != expected_choice:
		failures.append(expected_choice + " selected choice changed after second click")
	scene.queue_free()
	await process_frame

func _assert_hit_rects(scene: Control, label: String) -> void:
	if not scene.has_method("get_choice_controls"):
		failures.append(label + " scene does not expose get_choice_controls")
		return
	var controls: Array[Button] = scene.get_choice_controls()
	if controls.size() != 3 and controls.size() != 4:
		failures.append(label + " choice control count changed")
	for i in range(controls.size()):
		var rect := _choice_rect(scene, i)
		if controls[i].position.distance_to(rect.position) > 0.01 or controls[i].size.distance_to(rect.size) > 0.01:
			failures.append(label + " choice " + str(i) + " hit area does not match scene choice rect")

func _assert_preview(scene: Control, label: String, preview_kind: String) -> void:
	var table_state: Dictionary = scene.get_table_state()
	var pickup: Dictionary = table_state.get("pickup", {})
	if str(pickup.get("choice", "")) != label:
		failures.append(label + " pickup summary did not track selected choice")
	match preview_kind:
		"gold":
			var ledger: Dictionary = table_state.get("ledger", {})
			if int(ledger.get("gold_preview", 0)) <= int(ledger.get("gold", 0)):
				failures.append(label + " did not preview gold gain")
		"heal":
			var ledger: Dictionary = table_state.get("ledger", {})
			if int(ledger.get("hp_preview", 0)) <= int(ledger.get("hp", 0)):
				failures.append(label + " did not preview HP gain")
		"relic":
			if (table_state.get("relic_tray", []) as Array).is_empty():
				failures.append(label + " did not preview incoming relic")
		"prep":
			if (table_state.get("queued_prep_notes", []) as Array).is_empty():
				failures.append(label + " did not preview queued prep note")

func _scene(scene_resource: PackedScene) -> Control:
	var scene: Control = scene_resource.instantiate()
	scene.configure({
		"run_state": {
			"gold": 18,
			"potion_ids": ["upgrade_voucher"],
			"potion_slots_used": 1,
			"potion_slots_max": 2,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	return scene

func _click_card_center(scene: Control, index: int) -> void:
	var pos := _choice_rect(scene, index).get_center()
	var target := _button_at(scene, pos)
	if target == null:
		if bool(scene.get("submitted")):
			return
		failures.append("no choice button found at " + str(pos))
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
