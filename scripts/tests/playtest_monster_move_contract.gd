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
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"monster_tier": "normal",
		"combat_cash": 20,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 22,
		"enemy_max_hp": 22,
		"move_pattern": ["heavy_hp_strike", "hp_strike"],
		"current_move_id": "heavy_hp_strike",
		"enemy_intent": "다음 피해 11",
		"applied_effects": []
	})
	await _settle(10)
	await _shot("00_monster_intro_intent")

	battle._open_enemy_intent_beat(0)
	await _settle(20)
	await _shot("01_enemy_move_applied_inline")

	if int(battle.get("enemy_damage_delta")) != 0:
		failures.append("enemy damage delta should be consumed by enemy move")
	if str(battle.get("enemy_intent")) == "":
		failures.append("enemy intent empty after monster move")
	if battle.ritual_director != null and battle.ritual_director.active_ritual != null:
		failures.append("enemy move should apply inline without opening a ritual")

	if failures.is_empty():
		print("monster move contract playtest passed")
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
