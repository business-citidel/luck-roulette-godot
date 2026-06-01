extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

var shot_dir: String = ""
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)

	var scene: PackedScene = load(BATTLE_SCENE)
	if scene == null:
		push_error("Could not load battle scene")
		quit(1)
		return

	var battle: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(battle)
	await _settle(8)
	battle.configure_encounter({
		"combat_cash": 18,
		"enemy_damage_delta": -2,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 30,
		"enemy_max_hp": 30,
		"relic_ids": ["loaded_die", "green_purse", "yellow_guard"],
		"applied_effects": []
	})
	await _settle(12)
	battle._show_feedback_from_effects([
		{"relic_id": "loaded_die", "effect_id": "dice_count_plus_one", "name": "Loaded Die"},
		{"relic_id": "yellow_guard", "effect_id": "marked_hit_guard", "name": "Yellow Guard"},
		{"relic_id": "green_purse", "effect_id": "green_payout_multiplier", "name": "Green Purse"},
		{"relic_id": "second_chance", "effect_id": "roulette_respin_plus_one", "name": "Second Chance"},
		{"source_id": "heavy_hp_strike", "effect_id": "hp_damage", "name": "Heavy Strike"},
		{"relic_id": "bust_insurance", "effect_id": "bust_delta_cancelled", "name": "Bust Insurance"}
	], "rendered_feedback_check")
	await _settle(18)
	await _shot("00_trigger_feedback_matrix")

	if failures.is_empty():
		print("trigger feedback playtest passed")
		battle.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		battle.queue_free()
		await process_frame
		quit(1)

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
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
