extends SceneTree

const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var shop: Control = ShopScene.instantiate()
	shop.configure({
		"run_state": {
			"gold": 42,
			"player_hp": 32,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"]
		},
		"map_result": {}
	})
	root.add_child(shop)
	var shop_results: Array[Dictionary] = []
	shop.completed.connect(func(result: Dictionary) -> void: shop_results.append(result))

	var overlay_canvas := CanvasLayer.new()
	overlay_canvas.layer = 80
	root.add_child(overlay_canvas)
	var overlay := RunPersistentOverlay.new()
	overlay_canvas.add_child(overlay)
	await process_frame
	overlay.configure({
		"gold": 42,
		"player_hp": 32,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die"]
	}, "shop", true, true, "나가기")
	await process_frame

	var card_rect: Rect2 = shop.call("get_choice_rect", "shop_relic")
	await _click_at(card_rect.get_center())
	await process_frame
	if str(shop.get("selected_choice")) != "shop_relic":
		failures.append("overlay blocked shop card click passthrough")

	overlay_canvas.queue_free()
	shop.queue_free()
	await process_frame
	if failures.is_empty():
		print("overlay shop passthrough smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _click_at(pos: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	release.global_position = pos
	root.push_input(release, true)
	await process_frame
