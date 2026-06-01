extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var shot_dir: String = ""
var failures: Array[String] = []
var battle: Control

func _initialize() -> void:
	print("005a combat game-feel proof playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_combat_entry()
	await _shot("00_combat_entry_roll_focus")
	await _show_dice_result()
	await _shot("01_dice_result_confirm_focus")
	await _show_marble_ready()
	await _shot("02_marble_slot_focus")
	await _show_roulette_result()
	await _shot("03_roulette_result_tray")
	await _show_enemy_or_next_turn()
	await _shot("04_enemy_or_next_turn")

	if battle != null:
		battle.queue_free()
		await process_frame
	if failures.is_empty():
		print("005a combat game-feel proof playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_combat_entry() -> void:
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
		"enemy_hp": 62,
		"enemy_max_hp": 62,
		"dice_rule_id": "single_attack_die",
		"relic_ids": ["loaded_die", "green_purse", "turn_token"],
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	await _settle(12)

func _show_dice_result() -> void:
	battle._apply_dice_ritual_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [3],
		"dice": [3],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	})
	await _settle(12)

func _show_marble_ready() -> void:
	battle._take_marbles()
	await _settle(8)

func _show_roulette_result() -> void:
	battle.set("placed_slots", {
		"safe": ["plain"],
		"profit": ["plain"],
		"jackpot": [],
		"bust": [],
		"overdrive": []
	})
	battle.set("marbles", [])
	battle.set("pending_slot", "profit")
	battle.set("damage_multiplier", 1.0)
	battle.set("payout_multiplier", 1.0)
	battle.set("phase", "intervene")
	battle.set("banner_text", "명중")
	battle.set("banner_alpha", 1.0)
	battle._render()
	battle._resolve_pending()
	await _settle(14)

func _show_enemy_or_next_turn() -> void:
	await _settle(24)

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
