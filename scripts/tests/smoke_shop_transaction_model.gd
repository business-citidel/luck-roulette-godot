extends SceneTree

const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_relic_slot_select_confirm()
	await _check_prep_slot_select_confirm()
	await _check_multiple_purchases_emit_on_leave()
	await _check_relic_direct_purchase()
	await _check_prep_direct_purchase()
	await _check_overlay_leave_method()
	await _check_low_gold_guards()

	if failures.is_empty():
		print("shop transaction model smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_relic_slot_select_confirm() -> void:
	var scene: Control = _shop(42)
	if not await _require_shop_scene(scene, "relic slot select"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	_assert_choice_controls_match_rects(scene)
	_assert_shop_support_rects(scene)
	await _click_control_at(scene, _choice_rect(scene, "shop_relic").get_center())
	await process_frame
	if results.size() != 0:
		failures.append("shop relic slot select emitted before confirm")
	if str(scene.get("selected_choice")) != "shop_relic":
		failures.append("shop relic slot did not select pending purchase")
	var pending: Dictionary = scene.get("pending_result")
	var pending_relics: Array = pending.get("relic_ids", []) as Array
	var expected_price := RelicCatalog.shop_price(str(pending_relics[0])) if not pending_relics.is_empty() else 0
	if int(pending.get("gold_delta", 0)) != -expected_price or pending_relics.is_empty():
		failures.append("shop relic pending result changed")
	await _click_scene_at(scene, _confirm_rect(scene).get_center())
	await process_frame
	if results.size() != 0:
		failures.append("shop confirm should not leave after a relic purchase")
	if not (scene.get("purchased_choice_ids") as Array).has("shop_relic"):
		failures.append("shop relic purchase was not marked sold")
	if int(scene.get("local_gold")) != 42 - expected_price:
		failures.append("shop relic purchase did not spend local gold")
	scene._confirm_purchase()
	await process_frame
	if results.size() != 0:
		failures.append("shop confirm double-emitted before leave")
	scene._leave()
	await process_frame
	if results.size() != 1:
		failures.append("shop leave did not emit relic visit result")
	elif str(results[0].get("choice", "")) != "shop_leave":
		failures.append("shop visit result should leave after purchase")
	elif int(results[0].get("gold_delta", 0)) != -expected_price or (results[0].get("relic_ids", []) as Array).is_empty():
		failures.append("shop relic visit result did not aggregate purchase")
	scene.queue_free()
	await process_frame

func _check_prep_slot_select_confirm() -> void:
	var scene: Control = _shop(20)
	if not await _require_shop_scene(scene, "prep slot select"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	_assert_choice_controls_match_rects(scene)
	_assert_shop_support_rects(scene)
	await _click_control_at(scene, _choice_rect(scene, "shop_prep").get_center())
	await process_frame
	if results.size() != 0:
		failures.append("shop prep slot select emitted before confirm")
	if str(scene.get("selected_choice")) != "shop_prep":
		failures.append("shop prep slot did not select pending purchase")
	var pending: Dictionary = scene.get("pending_result")
	if int(pending.get("gold_delta", 0)) != -14 or (pending.get("next_combat_mods", []) as Array).is_empty():
		failures.append("shop prep pending result changed")
	await _click_scene_at(scene, _confirm_rect(scene).get_center())
	await process_frame
	if results.size() != 0:
		failures.append("shop prep confirm should not leave after purchase")
	if int(scene.get("local_gold")) != 6:
		failures.append("shop prep purchase did not spend local gold")
	scene._leave()
	await process_frame
	if results.size() != 1:
		failures.append("shop prep leave did not emit one visit result")
	elif str(results[0].get("choice", "")) != "shop_leave":
		failures.append("shop prep visit result should be a leave result")
	elif int(results[0].get("gold_delta", 0)) != -14:
		failures.append("shop prep visit result did not aggregate gold")
	elif (results[0].get("next_combat_mods", []) as Array).is_empty():
		failures.append("shop prep visit result lost next combat mod")
	scene.queue_free()
	await process_frame

func _check_multiple_purchases_emit_on_leave() -> void:
	var scene: Control = _shop(120)
	if not await _require_shop_scene(scene, "multiple purchases"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._buy_relic()
	await process_frame
	await _click_control_at(scene, _choice_rect(scene, "shop_relic_1").get_center())
	await process_frame
	scene._confirm_purchase()
	await process_frame
	if results.size() != 0:
		failures.append("multi-purchase shop emitted before leave")
	var bought: Array = scene.get("purchased_choice_ids") as Array
	if not bought.has("shop_relic") or not bought.has("shop_relic_1"):
		failures.append("multi-purchase shop did not mark both relics sold")
	scene._leave()
	await process_frame
	if results.size() != 1:
		failures.append("multi-purchase shop did not emit on leave")
	else:
		var relics: Array = results[0].get("relic_ids", []) as Array
		if relics.size() != 2:
			failures.append("multi-purchase shop did not aggregate two relics")
		if int(results[0].get("gold_delta", 0)) >= 0:
			failures.append("multi-purchase shop did not aggregate spend")
	scene.queue_free()
	await process_frame

func _check_relic_direct_purchase() -> void:
	var scene: Control = _shop(42)
	if not await _require_shop_scene(scene, "direct relic"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._buy_relic()
	await process_frame
	if results.size() != 0:
		failures.append("direct shop relic emitted before leave")
	scene._leave()
	await process_frame
	if results.size() != 1:
		failures.append("direct shop relic did not emit on leave")
	elif (results[0].get("relic_ids", []) as Array).is_empty():
		failures.append("direct shop relic lost relic id")
	else:
		var relic_id := str((results[0].get("relic_ids", []) as Array)[0])
		if int(results[0].get("gold_delta", 0)) != -RelicCatalog.shop_price(relic_id):
			failures.append("direct shop relic gold delta changed")
	scene.queue_free()
	await process_frame

func _check_prep_direct_purchase() -> void:
	var scene: Control = _shop(20)
	if not await _require_shop_scene(scene, "direct prep"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	scene._buy_prep()
	await process_frame
	if results.size() != 0:
		failures.append("direct shop prep emitted before leave")
	scene._leave()
	await process_frame
	if results.size() != 1:
		failures.append("direct shop prep did not emit on leave")
	elif int(results[0].get("gold_delta", 0)) != -14:
		failures.append("direct shop prep gold delta changed")
	elif (results[0].get("next_combat_mods", []) as Array).is_empty():
		failures.append("direct shop prep lost next combat mod")
	scene.queue_free()
	await process_frame

func _check_overlay_leave_method() -> void:
	var scene: Control = _shop(42)
	if not await _require_shop_scene(scene, "overlay leave method"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	_assert_choice_controls_match_rects(scene)
	_assert_shop_support_rects(scene)
	scene._leave()
	await process_frame
	if results.size() != 1:
		failures.append("shop overlay leave did not emit")
	elif str(results[0].get("choice", "")) != "shop_leave":
		failures.append("shop overlay leave emitted wrong choice")
	scene.queue_free()
	await process_frame

func _check_low_gold_guards() -> void:
	var scene: Control = _shop(10)
	if not await _require_shop_scene(scene, "low gold guards"):
		return
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	_assert_choice_controls_match_rects(scene)
	_assert_shop_support_rects(scene)
	await _click_control_at(scene, _choice_rect(scene, "shop_relic").get_center())
	await _click_control_at(scene, _choice_rect(scene, "shop_prep").get_center())
	scene._buy_relic()
	scene._buy_prep()
	await process_frame
	if results.size() != 0:
		failures.append("low-gold shop purchase emitted")
	scene._choose_default()
	await process_frame
	if results.size() != 1 or str(results[0].get("choice", "")) != "shop_leave":
		failures.append("low-gold shop default did not leave")
	scene.queue_free()
	await process_frame

func _assert_choice_controls_match_rects(scene: Control) -> void:
	if not scene.has_method("get_choice_controls"):
		failures.append("shop scene does not expose get_choice_controls()")
		return
	if not scene.has_method("get_choice_rect"):
		failures.append("shop scene does not expose get_choice_rect(choice_id)")
		return
	var controls: Array[Button] = scene.get_choice_controls()
	var choice_ids := _choice_ids(scene)
	if controls.size() != choice_ids.size():
		failures.append("shop choice control count changed")
	for i in range(min(controls.size(), choice_ids.size())):
		var choice_id := str(choice_ids[i])
		var rect := _choice_rect(scene, choice_id)
		if controls[i].position.distance_to(rect.position) > 0.01 or controls[i].size.distance_to(rect.size) > 0.01:
			failures.append("shop choice " + choice_id + " hit area does not match get_choice_rect")

func _assert_shop_support_rects(scene: Control) -> void:
	if not scene.has_method("get_exit_rect") or not scene.has_method("get_price_tag_rect") or not scene.has_method("get_confirm_rect"):
		failures.append("shop scene is missing support rect helpers")
		return
	if _exit_rect(scene).size.x <= 0.0 or _exit_rect(scene).size.y <= 0.0:
		failures.append("shop exit rect should be non-empty for run overlay")
	var relic_tag := _price_tag_rect(scene, "shop_relic")
	var prep_tag := _price_tag_rect(scene, "shop_prep")
	if relic_tag.size.x <= 0.0 or relic_tag.size.y <= 0.0:
		failures.append("shop relic price tag rect should be non-empty")
	if prep_tag.size.x <= 0.0 or prep_tag.size.y <= 0.0:
		failures.append("shop prep price tag rect should be non-empty")
	var confirm_rect := _confirm_rect(scene)
	if confirm_rect.size.x <= 0.0 or confirm_rect.size.y <= 0.0:
		failures.append("shop confirm rect should be non-empty")
	var confirm_value: Variant = scene.get("confirm_button")
	if confirm_value is Button:
		var button := confirm_value as Button
		if button.position.distance_to(confirm_rect.position) > 0.01 or button.size.distance_to(confirm_rect.size) > 0.01:
			failures.append("shop confirm button does not match get_confirm_rect")

func _choice_ids(scene: Control) -> Array[String]:
	var result: Array[String] = []
	var value: Variant = scene.get("choices")
	if value is Array:
		for choice in value:
			if choice is Dictionary:
				result.append(str((choice as Dictionary).get("id", "")))
	return result

func _require_shop_scene(scene: Control, label: String) -> bool:
	if scene == null:
		failures.append("shop scene did not instantiate for " + label)
		return false
	if not scene.has_method("configure") or not scene.has_signal("completed"):
		failures.append("shop scene script did not load for " + label)
		scene.queue_free()
		await process_frame
		return false
	return true

func _choice_rect(scene: Control, choice_id: String) -> Rect2:
	if not scene.has_method("get_choice_rect"):
		return Rect2()
	var value: Variant = scene.call("get_choice_rect", choice_id)
	if typeof(value) != TYPE_RECT2:
		failures.append("shop get_choice_rect(" + choice_id + ") did not return Rect2")
		return Rect2()
	return value

func _exit_rect(scene: Control) -> Rect2:
	var value: Variant = scene.call("get_exit_rect")
	if typeof(value) != TYPE_RECT2:
		failures.append("shop get_exit_rect() did not return Rect2")
		return Rect2()
	return value

func _price_tag_rect(scene: Control, choice_id: String) -> Rect2:
	var value: Variant = scene.call("get_price_tag_rect", choice_id)
	if typeof(value) != TYPE_RECT2:
		failures.append("shop get_price_tag_rect(" + choice_id + ") did not return Rect2")
		return Rect2()
	return value

func _confirm_rect(scene: Control) -> Rect2:
	var value: Variant = scene.call("get_confirm_rect")
	if typeof(value) != TYPE_RECT2:
		failures.append("shop get_confirm_rect() did not return Rect2")
		return Rect2()
	return value

func _shop(gold: int) -> Control:
	var scene: Control = ShopScene.instantiate()
	if not scene.has_method("configure"):
		return scene
	scene.configure({
		"run_state": {
			"gold": gold,
			"player_hp": 32,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	return scene

func _click_control_at(scene: Control, pos: Vector2) -> void:
	var target := _button_at(scene, pos)
	if target == null:
		return
	await _click_scene_at(scene, pos)

func _click_scene_at(scene: Control, pos: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	scene.get_viewport().push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	release.global_position = pos
	scene.get_viewport().push_input(release, true)
	await process_frame

func _button_at(scene: Control, pos: Vector2) -> Button:
	if not scene.has_method("get_choice_controls"):
		return null
	for button in scene.get_choice_controls():
		var rect := Rect2(button.position, button.size)
		if rect.has_point(pos):
			return button
	return null
