extends SceneTree

const RestScene := preload("res://scenes/run/rest_scene.tscn")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	print("rest room flow upgrade proof playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_rest()
	await _shot("00_rest_front_heal_tune_relic")
	active_scene._choose_by_id("rest_tune")
	await _settle(8)
	await _shot("01_rest_upgrade_primary_secondary_roulette_cell")
	active_scene._choose_upgrade("upgrade_roulette_cell")
	await _settle(8)
	await _shot("02_rest_roulette_cell_upgrade_screen")
	active_scene._choose_roulette_cell(1)
	await _settle(8)
	await _shot("03_rest_roulette_cell_selected_result")

	await _clear_active()
	if failures.is_empty():
		print("rest room flow upgrade proof playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_rest() -> void:
	await _clear_active()
	active_scene = RestScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 12,
			"potion_ids": ["upgrade_voucher"],
			"potion_slots_used": 1,
			"potion_slots_max": 2,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": [],
			"run_upgrades": {}
		},
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(8)

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
