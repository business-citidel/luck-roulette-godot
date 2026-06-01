extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var battle: Control

func _initialize() -> void:
	print("relic expansion proof playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_all_relic_entry()
	await _shot("00_all_relics_combat_entry")
	await _show_dice_and_marker_feedback()
	await _shot("01_locksmith_twin_marker_feedback")
	await _show_turn_token_feedback()
	await _shot("02_turn_token_feedback")
	await _show_resolution_relic_feedback()
	await _shot("03_resolution_relics_normal_apply_path")

	if battle != null:
		battle.queue_free()
		await process_frame
	if failures.is_empty():
		print("relic expansion proof playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_all_relic_entry() -> void:
	battle = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.configure_encounter({
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"combat_cash": 20,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 80,
		"enemy_max_hp": 80,
		"dice_rule_id": "single_attack_die",
		"relic_ids": RelicCatalog.all_ids(),
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	await _settle(18)

func _show_turn_token_feedback() -> void:
	battle._next_turn()
	await _settle(6)

func _show_dice_and_marker_feedback() -> void:
	battle._apply_dice_ritual_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [3],
		"dice": [3],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	})
	await _settle(10)

func _show_resolution_relic_feedback() -> void:
	await _settle(110)
	battle.set("attack_base", 10)
	battle.set("placed_slots", {
		"safe": ["plain"],
		"profit": ["plain"],
		"jackpot": ["plain"],
		"bust": [],
		"overdrive": ["plain"]
	})
	battle.set("pending_slot", "overdrive")
	battle.set("damage_multiplier", 1.0)
	battle.set("payout_multiplier", 1.0)
	battle.set("cash", 20)
	battle.set("enemy_hp", 22)
	battle._resolve_pending()
	await _settle(14)

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
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
