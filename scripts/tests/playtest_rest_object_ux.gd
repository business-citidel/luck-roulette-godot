extends SceneTree

const RestScene := preload("res://scenes/run/rest_scene.tscn")
const RestActionObjectNode := preload("res://scripts/ui/rest_action_object_node.gd")

var shot_dir: String = ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir != "":
		DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	active_scene = _scene()
	root.add_child(active_scene)
	await _settle(8)
	await _shot("rest_object_01_front_ready")
	var front_controls: Array[Button] = active_scene.get_choice_controls()
	if front_controls.size() != 3:
		failures.append("rest object UX expected three front controls")
	else:
		var tune := front_controls[1] as RestActionObjectNode
		if tune == null:
			failures.append("rest front controls should be RestActionObjectNode")
		else:
			tune.set_hovered(true)
			await _settle(12)
			await _shot("rest_object_02_front_hover_tune")
	active_scene._choose_by_id("rest_tune")
	await _settle(8)
	await _shot("rest_object_03_upgrade_ready")
	var upgrade_controls: Array[Button] = active_scene.get_choice_controls()
	if upgrade_controls.size() != 4:
		failures.append("rest object UX expected four upgrade controls")
	else:
		var roulette := upgrade_controls[1] as RestActionObjectNode
		if roulette == null:
			failures.append("rest upgrade controls should be RestActionObjectNode")
		else:
			roulette.set_hovered(true)
			await _settle(12)
			await _shot("rest_object_04_upgrade_hover_roulette")
	active_scene._choose_upgrade("upgrade_roulette")
	await _settle(10)
	await _shot("rest_object_05_upgrade_chosen_roulette")
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("rest object UX playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _scene() -> Control:
	var scene: Control = RestScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 12,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": [],
			"run_upgrades": {}
		},
		"map_result": {}
	})
	return scene

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
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
