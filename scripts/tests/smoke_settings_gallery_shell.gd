extends SceneTree

const SettingsScene := preload("res://scenes/run/settings_scene.tscn")
const GalleryScene := preload("res://scenes/run/gallery_scene.tscn")
const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const CollectionProgressService := preload("res://scripts/systems/collection_progress_service.gd")

var failures: Array[String] = []

func _initialize() -> void:
	CollectionProgressService.clear_progress()
	DemoSettingsService.save_settings({
		"master_volume": 0.64,
		"bgm_volume": 0.5,
		"sfx_volume": 0.75,
		"fullscreen": false
	})
	var loaded := DemoSettingsService.load_settings()
	if absf(float(loaded.get("master_volume", 0.0)) - 0.64) > 0.01:
		failures.append("settings service should persist master volume")
	root.size = Vector2i(1280, 720)
	var settings_scene: Control = SettingsScene.instantiate()
	settings_scene.configure({})
	root.add_child(settings_scene)
	await process_frame
	if settings_scene.get("back_button") == null:
		failures.append("settings scene should expose a back button")
	settings_scene.queue_free()
	await process_frame
	var gallery_scene: Control = GalleryScene.instantiate()
	gallery_scene.configure({"category": "relics"})
	root.add_child(gallery_scene)
	await process_frame
	if gallery_scene.get("back_button") == null:
		failures.append("gallery scene should expose a back button")
	if (gallery_scene.call("_items") as Array).is_empty():
		failures.append("gallery should load relic catalog items")
	if int(gallery_scene.call("_page_count")) != 5:
		failures.append("relic gallery should use dynamic page count for 34 relics")
	var first_relic_items: Array = gallery_scene.call("_items")
	if str((first_relic_items[0] as Dictionary).get("gallery_state", "")) != "locked":
		failures.append("fresh relic gallery should lock undiscovered relics")
	CollectionProgressService.discover_relic("loaded_die")
	var discovered_relic_items: Array = gallery_scene.call("_items")
	if str((discovered_relic_items[0] as Dictionary).get("gallery_state", "")) != "normal":
		failures.append("discovered relic should become a normal gallery entry")
	var next_button := gallery_scene.get("next_page_button") as Button
	var previous_button := gallery_scene.get("previous_page_button") as Button
	if next_button == null:
		failures.append("gallery scene should expose a next page button")
	if previous_button == null:
		failures.append("gallery scene should expose a previous page button")
	var item_buttons: Array = gallery_scene.get("item_buttons")
	if item_buttons.size() != 8:
		failures.append("gallery scene should expose eight item hit buttons")
	elif (gallery_scene.call("_page_items") as Array).size() > 1:
		(item_buttons[1] as Button).pressed.emit()
		await process_frame
		if int(gallery_scene.get("selected_slot_index")) != 1:
			failures.append("gallery item button should select the clicked card")
	var page_count := int(gallery_scene.call("_page_count"))
	if page_count > 1 and next_button != null and previous_button != null:
		next_button.pressed.emit()
		await process_frame
		if int(gallery_scene.get("page_index")) != 1:
			failures.append("gallery right arrow should advance to the next page")
		previous_button.pressed.emit()
		await process_frame
		if int(gallery_scene.get("page_index")) != 0:
			failures.append("gallery left arrow should return to the previous page")
	gallery_scene.call("_set_category", "characters")
	await process_frame
	if int(gallery_scene.call("_page_count")) != 1:
		failures.append("character gallery should fit on one dynamic page")
	var character_items: Array = gallery_scene.call("_items")
	var found_locked_future := false
	for item in character_items:
		if str((item as Dictionary).get("id", "")) == "future_luck_contract":
			found_locked_future = str((item as Dictionary).get("gallery_state", "")) == "locked"
	if not found_locked_future:
		failures.append("future luck contract should remain a locked gallery entry")
	gallery_scene.call("_set_category", "events")
	await process_frame
	if str(gallery_scene.get("active_category")) != "characters":
		failures.append("removed events gallery category should fall back to characters")
	gallery_scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("settings gallery shell smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
