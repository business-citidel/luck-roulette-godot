extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	await _check_battle_accepts_alternate_dice_rule()
	await _check_battle_monster_payload_side_effects()

	if failures.is_empty():
		print("combat extension contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_battle_accepts_alternate_dice_rule() -> void:
	var scene: PackedScene = load(BATTLE_SCENE)
	if scene == null:
		failures.append("could not load battle scene")
		return
	var battle: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(battle)
	await _settle(8)
	battle.configure_encounter({
		"combat_core": "slot_marble",
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"monster_tier": "normal",
		"combat_cash": 18,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 80,
		"enemy_max_hp": 80,
		"dice_rule_id": "two_dice_sum_attack",
		"move_pattern": ["heavy_hp_strike", "hp_strike"],
		"current_move_id": "heavy_hp_strike",
		"enemy_intent": "다음 피해 11",
		"applied_effects": []
	})
	await _settle(6)

	if (battle.get("dice") as Array).size() != 2:
		failures.append("battle did not initialize two dice from dice_rule_id")
	if (battle.get("dice_locked") as Array).size() != 2:
		failures.append("battle did not initialize two dice locks from dice_rule_id")

	var forced_dice: Array[int] = [3, 4]
	var forced_locks: Array[bool] = [false, false]
	battle.set("dice", forced_dice)
	battle.set("dice_locked", forced_locks)
	battle.set("dice_rolled", true)
	battle.set("rerolls_left", 1)
	battle.set("attack_base", 7)
	battle._take_marbles()
	await _settle(12)

	if int(battle.get("attack_base")) != 7:
		failures.append("two dice result did not become attack_base 7")
	var marbles: Array = battle.get("marbles") as Array
	if marbles.size() != 1:
		failures.append("battle should still create one base marble after alternate dice rule")
	elif str(marbles[0]) != "plain":
		failures.append("alternate dice rule created a colored marble instead of neutral plain token")

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_5
	key_event.physical_keycode = KEY_5
	if battle._slot_id_for_key(key_event) != "jackpot":
		failures.append("hidden number key mapping did not resolve slot 5 to jackpot")

	battle._place_marbles_on_slot("jackpot")
	await _wait_for_marble_setup_ready(battle, 240)
	var placed_slots: Dictionary = battle.get("placed_slots") as Dictionary
	if (placed_slots.get("jackpot", []) as Array).size() != 1:
		failures.append("direct slot placement did not put marble on jackpot")
	elif str((placed_slots.get("jackpot", []) as Array)[0]) != "plain":
		failures.append("direct slot placement did not put a neutral plain token on jackpot")

	battle.set("pending_slot", "jackpot")
	battle.set("damage_multiplier", 1.0)
	battle._resolve_pending()
	await _settle(12)
	if int(battle.get("enemy_hp")) != 59:
		failures.append("boosted jackpot should apply two-dice attack 7 as 21 damage")
	if (battle.get("placed_slots") as Dictionary).get("jackpot", []).size() != 0:
		failures.append("resolution did not reset placed roulette slots")

	battle.set("phase", "enemy")
	battle.set("current_move_id", "heavy_hp_strike")
	battle.set("enemy_damage_delta", 2)
	battle._enemy_phase_take()
	await _settle(8)
	if int(battle.get("enemy_damage_delta")) != 0:
		failures.append("enemy damage delta was not consumed")
	if battle.ritual_director != null and battle.ritual_director.active_ritual != null:
		failures.append("inline monster move opened a ritual unexpectedly")

	battle._next_turn()
	await _settle(6)
	if (battle.get("dice") as Array).size() != 2:
		failures.append("next turn did not preserve encounter dice rule")
	if not (battle.get("marbles") as Array).is_empty():
		failures.append("next turn leaked battle marbles")

	battle.queue_free()
	await process_frame

func _check_battle_monster_payload_side_effects() -> void:
	var scene: PackedScene = load(BATTLE_SCENE)
	if scene == null:
		failures.append("could not load battle scene for monster side effects")
		return
	var battle: Control = scene.instantiate()
	root.add_child(battle)
	await _settle(8)
	battle.configure_encounter({
		"monster_id": "coin_shark",
		"monster_name": "Coin Shark",
		"monster_tier": "normal",
		"combat_cash": 18,
		"run_gold": 12,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 30,
		"enemy_max_hp": 30,
		"move_pattern": ["tax_collection", "weak_receipt"],
		"current_move_id": "tax_collection",
		"enemy_intent": "Gold -4",
		"applied_effects": []
	})
	await _settle(6)
	battle._enemy_phase_take()
	await _settle(8)
	if int(battle.get("run_gold")) != 8 or int(battle.get("gold_delta")) != -4:
		failures.append("tax monster should remove spendable run gold during battle")

	battle._next_turn()
	await _settle(6)
	battle.set("current_move_id", "weak_receipt")
	battle._enemy_phase_take()
	await _settle(8)
	if float(battle.get("player_damage_multiplier")) >= 1.0:
		failures.append("weak curse should lower next player damage multiplier")

	battle.queue_free()
	await process_frame

func _wait_for_ritual(battle: Control, ritual_name: String, max_frames: int) -> void:
	for i in range(max_frames):
		if battle.ritual_director != null and str(battle.ritual_director.active_ritual_name) == ritual_name:
			return
		await process_frame

func _wait_for_ritual_close(battle: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if battle.ritual_director != null and battle.ritual_director.active_ritual == null:
			return
		await process_frame

func _wait_for_marble_setup_ready(battle: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if battle._marble_setup_ready():
			return
		await process_frame

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
