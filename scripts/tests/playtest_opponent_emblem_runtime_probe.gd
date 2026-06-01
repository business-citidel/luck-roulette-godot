extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

var shot_dir: String = ""
var failures: Array[String] = []
var battle: Control

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
	root.size = Vector2i(1280, 720)
	battle = scene.instantiate()
	root.add_child(battle)
	await _settle(8)
	await _show_opponent("00_debt_collector_emblem", "debt_collector", "Debt Collector", 18, 18, ["hp_strike"])
	await _show_opponent("01_table_crook_emblem", "table_crook", "Table Crook", 22, 22, ["heavy_hp_strike", "hp_strike"])
	await _show_opponent("02_elite_house_emblem", "elite_house", "House Enforcer", 34, 34, ["heavy_hp_strike", "hp_strike"])
	await _show_opponent("03_final_house_emblem", "final_house", "Final House", 48, 48, ["heavy_hp_strike", "heavy_hp_strike"])
	if failures.is_empty():
		print("opponent emblem runtime probe playtest passed")
		battle.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		battle.queue_free()
		await process_frame
		quit(1)

func _show_opponent(name: String, monster_id: String, monster_name: String, enemy_hp: int, enemy_max_hp: int, move_pattern: Array[String]) -> void:
	battle.configure_encounter({
		"monster_id": monster_id,
		"monster_name": monster_name,
		"monster_tier": "boss" if monster_id == "final_house" else ("elite" if monster_id == "elite_house" else "normal"),
		"combat_cash": 34 if monster_id == "final_house" else 20,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_max_hp,
		"move_pattern": move_pattern,
		"current_move_id": move_pattern[0],
		"enemy_intent": "다음 피해 7",
		"applied_effects": []
	})
	await _settle(12)
	await _shot(name)

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
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path := shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
