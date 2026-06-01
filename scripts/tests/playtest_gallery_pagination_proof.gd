extends SceneTree

const GalleryScene := preload("res://scenes/run/gallery_scene.tscn")
const CollectionProgressService := preload("res://scripts/systems/collection_progress_service.gd")

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	CollectionProgressService.clear_progress()

	var scene: Control = GalleryScene.instantiate()
	scene.configure({"category": "relics"})
	root.add_child(scene)
	await _settle(8)
	await _shot("00_relics_fresh_locked")

	var next_button := scene.get("next_page_button") as Button
	var previous_button := scene.get("previous_page_button") as Button
	var item_buttons: Array = scene.get("item_buttons")
	if item_buttons.size() > 1:
		(item_buttons[1] as Button).pressed.emit()
		await _settle(8)
		await _shot("01_relics_fresh_selected_locked")
	if next_button == null or previous_button == null:
		failures.append("gallery pagination buttons unavailable")
	else:
		next_button.pressed.emit()
		await _settle(8)
		await _shot("02_relics_locked_next_page")
		previous_button.pressed.emit()
		await _settle(8)
		await _shot("03_relics_locked_previous_page")
		var page_count := int(scene.call("_page_count"))
		for i in range(max(0, page_count - 1)):
			next_button.pressed.emit()
			await _settle(1)
		await _settle(8)
		await _shot("04_relics_locked_last_real_page")

	CollectionProgressService.discover_character("default_guard_dice")
	CollectionProgressService.discover_relic("loaded_die")
	CollectionProgressService.discover_monster("debt_collector")
	scene.call("_set_category", "relics")
	_reset_gallery_selection(scene, "relics")
	await _settle(8)
	await _shot("05_relics_loaded_die_discovered")

	scene.call("_set_category", "characters")
	_reset_gallery_selection(scene, "characters")
	await _settle(8)
	await _shot("06_characters_default_discovered")
	scene.call("_set_category", "monsters")
	_reset_gallery_selection(scene, "monsters")
	await _settle(8)
	await _shot("07_monsters_debt_collector_discovered")

	scene.queue_free()
	await process_frame

	if failures.is_empty():
		print("gallery pagination proof playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _reset_gallery_selection(scene: Control, category: String) -> void:
	var selected_slots: Dictionary = scene.get("selected_slots")
	var category_pages: Dictionary = scene.get("category_pages")
	selected_slots[category + ":0"] = 0
	category_pages[category] = 0
	scene.set("selected_slots", selected_slots)
	scene.set("category_pages", category_pages)
	scene.set("page_index", 0)
	scene.set("selected_slot_index", 0)
	scene.queue_redraw()

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
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
