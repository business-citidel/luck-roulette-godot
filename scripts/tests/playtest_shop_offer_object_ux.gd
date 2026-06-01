extends SceneTree

const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const ShopOfferSlotNode := preload("res://scripts/ui/shop_offer_slot_node.gd")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	await _show_shop(96)
	await _shot("shop_object_01_ready")
	var controls: Array[Button] = active_scene.get_choice_controls()
	if controls.size() < 5:
		failures.append("shop object UX expected five offer controls")
	else:
		var hover_offer := controls[3] as ShopOfferSlotNode
		if hover_offer == null:
			failures.append("shop controls are not ShopOfferSlotNode buttons")
		else:
			hover_offer.set_hovered(true)
			await _settle(12)
			await _shot("shop_object_02_hover")
		active_scene._select_by_id("shop_service_1")
		await _settle(8)
		await _shot("shop_object_03_service_selected")
		active_scene._confirm_purchase()
		await _settle(8)
		await _shot("shop_object_04_service_sold")
		active_scene._reroll_unsold_offers()
		await _settle(8)
		await _shot("shop_object_05_rerolled_unsold")
		active_scene._select_by_id("shop_special")
		await _settle(8)
		await _shot("shop_object_06_special_selected")
		active_scene._confirm_purchase()
		await _settle(8)
		await _shot("shop_object_07_two_items_bought")
		active_scene._select_by_id("shop_relic")
		await _settle(8)
		await _shot("shop_object_08_relic_selected")
	await _show_shop(10)
	await _shot("shop_object_09_low_gold_disabled")
	await _clear_active()
	if failures.is_empty():
		print("shop offer object UX playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_shop(gold: int) -> void:
	await _clear_active()
	active_scene = ShopScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": gold,
			"player_hp": 36,
			"player_max_hp": 42,
			"relic_ids": [],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	active_scene.completed.connect(func(_result: Dictionary) -> void: pass)
	root.add_child(active_scene)
	await _settle(8)

func _clear_active() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null
	await process_frame

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
	if shot_dir == "":
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
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
