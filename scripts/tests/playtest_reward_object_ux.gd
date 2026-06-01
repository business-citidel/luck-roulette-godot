extends SceneTree

const RewardScene := preload("res://scenes/run/reward_scene.tscn")

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
	await _shot("reward_object_01_ready")
	var controls: Array[Button] = active_scene.get_choice_controls()
	var reward_items: Array = active_scene.reward_items
	if controls.size() != 1:
		failures.append("reward object UX expected one claim control")
	if reward_items.size() != 3:
		failures.append("reward object UX expected three reward board items")
	else:
		var relic_item := _find_relic_item(reward_items)
		if relic_item.is_empty():
			failures.append("reward object UX expected one relic item")
		else:
			var object_display: Dictionary = relic_item.get("object_display", {})
			if str(relic_item.get("object_kind", "")) != "relic" or object_display.is_empty():
				failures.append("reward relic item should carry runtime object payload")
			await _settle(12)
			await _shot("reward_object_02_relic_payload")
		active_scene._claim_reward()
		await _settle(10)
		await _shot("reward_object_03_claimed")
	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("reward object UX playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _scene() -> Control:
	var scene: Control = RewardScene.instantiate()
	scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 32,
			"player_max_hp": 42,
			"relic_ids": []
		},
		"combat_result": {
			"winnings": 18,
			"node_type": "elite",
			"reward_tier": "elite",
			"encounter_id": "reward_object_ux",
			"monster_id": "debt_collector"
		}
	})
	return scene

func _find_relic_item(items: Array) -> Dictionary:
	for item in items:
		if item is Dictionary and str((item as Dictionary).get("kind", "")) == "relic":
			return item as Dictionary
	return {}

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
