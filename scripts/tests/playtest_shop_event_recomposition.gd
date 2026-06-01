extends SceneTree

const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const EventScene := preload("res://scenes/run/event_scene.tscn")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	print("shop/event recomposition playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_shop(42, "")
	await _shot("shop_slots_normal")
	await _show_shop(42, "select_relic")
	await _shot("shop_slots_selected_detail")
	await _show_shop(10, "")
	await _shot("shop_slots_low_gold_disabled")
	await _show_shop(42, "shop_relic")
	await _shot("shop_slots_sold_disabled")
	await _show_event("")
	await _shot("event_choice_cards_normal")
	await _show_event("event_relic_trade")
	await _shot("event_choice_cards_chosen_disabled")

	if active_scene != null:
		active_scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("shop/event recomposition playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_shop(gold: int, submit_choice: String) -> void:
	await _clear_active()
	active_scene = ShopScene.instantiate()
	if not active_scene.has_method("configure"):
		failures.append("shop scene script did not load for " + _shop_shot_label(gold, submit_choice))
		root.add_child(active_scene)
		await _settle(6)
		return
	active_scene.configure({
		"run_state": {
			"gold": gold,
			"player_hp": 32,
			"player_max_hp": 42,
			"relic_ids": []
		},
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(6)
	if submit_choice == "select_relic":
		active_scene._select_purchase(active_scene._relic_result())
	elif submit_choice == "select_prep":
		active_scene._select_purchase(active_scene._prep_result())
	elif submit_choice == "shop_relic":
		_submit_shop_helper("_buy_relic")
	elif submit_choice == "shop_prep":
		_submit_shop_helper("_buy_prep")
	elif submit_choice == "shop_leave":
		_submit_shop_helper("_leave")
	if submit_choice != "":
		await _settle(6)

func _submit_shop_helper(method_name: String) -> void:
	if not active_scene.has_method(method_name):
		failures.append("shop scene does not expose " + method_name + "() for rendered playtest")
		return
	active_scene.call(method_name)

func _shop_shot_label(gold: int, submit_choice: String) -> String:
	if submit_choice != "":
		return submit_choice
	if gold < 14:
		return "low gold"
	return "normal"

func _show_event(submit_choice: String) -> void:
	await _clear_active()
	active_scene = EventScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 36,
			"player_max_hp": 42,
			"relic_ids": []
		},
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(6)
	if submit_choice == "event_gold":
		active_scene._choose_gold()
	elif submit_choice == "event_relic_trade":
		active_scene._choose_trade()
	elif submit_choice == "event_risk_gold":
		active_scene._choose_risk_gold()
	if submit_choice != "":
		await _settle(6)

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
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _shot(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
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
