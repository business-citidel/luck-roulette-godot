extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	var all_relics: Array[String] = RelicCatalog.all_ids()
	battle.configure_encounter({
		"combat_core": "slot_marble",
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"combat_cash": 20,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 80,
		"enemy_max_hp": 80,
		"dice_rule_id": "single_attack_die",
		"relic_ids": all_relics,
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	await _settle(8)
	_check_all_relics_reached_battle(battle, all_relics)
	await _check_turn_token_scene_path(battle)
	await _check_resolution_before_scene_path(battle)
	await _check_new_relic_resolution_scene_path(battle)
	battle.queue_free()
	await process_frame

	if failures.is_empty():
		print("all relic combat state smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_all_relics_reached_battle(battle: Control, all_relics: Array[String]) -> void:
	var active: Array = battle.get("active_relic_ids") as Array
	for relic_id in all_relics:
		if not active.has(relic_id):
			failures.append("battle missing active relic " + relic_id)
	var run_hud: Control = battle.get("run_hud") as Control
	if run_hud == null:
		failures.append("battle HUD missing")
	elif (run_hud.get("active_relic_ids") as Array).size() != all_relics.size():
		failures.append("battle HUD did not receive all relic IDs")

func _check_turn_token_scene_path(battle: Control) -> void:
	var before_cash: int = int(battle.get("cash"))
	var feedback_layer: Control = battle.get("feedback_layer") as Control
	var before_feedback_count: int = feedback_layer.get_child_count() if feedback_layer != null else 0
	battle._next_turn()
	await _settle(4)
	if int(battle.get("cash")) != before_cash + 3:
		failures.append("turn_start relic cash stack did not apply through BattleScene")
	if not _has_effect(battle.get("last_applied_effects") as Array, "turn_cash_tip"):
		failures.append("turn_token did not record turn_start effect in BattleScene")
	if feedback_layer == null or feedback_layer.get_child_count() <= before_feedback_count:
		failures.append("turn_token did not spawn visible BattleScene feedback")

func _check_resolution_before_scene_path(battle: Control) -> void:
	battle.set("attack_base", 10)
	battle.set("placed_slots", {
		"safe": ["plain"],
		"profit": ["plain"],
		"jackpot": ["plain"],
		"bust": [],
		"overdrive": []
	})
	battle.set("pending_slot", "jackpot")
	battle.set("damage_multiplier", 1.0)
	battle.set("payout_multiplier", 1.0)
	battle.set("enemy_damage_delta", 0)
	battle.set("player_block", 0)
	battle.set("cash", 20)
	battle.set("enemy_hp", 80)
	battle._resolve_pending()
	await _settle(8)
	if int(battle.get("enemy_damage_delta")) != -3:
		failures.append("empty guard fallback did not apply through jackpot BattleScene resolution path")
	if _has_effect(battle.get("last_applied_effects") as Array, "marked_hit_guard"):
		failures.append("safe-mark relic should not affect jackpot BattleScene resolution path")
	if _has_effect(battle.get("last_applied_effects") as Array, "green_cash_bonus"):
		failures.append("profit-mark relic should not affect jackpot BattleScene resolution path")
	if int(battle.get("enemy_hp")) > 43:
		failures.append("jackpot-mark relic did not increase normal BattleScene resolution damage")

func _check_new_relic_resolution_scene_path(battle: Control) -> void:
	battle.set("attack_base", 10)
	battle.set("placed_slots", {
		"safe": [],
		"profit": [],
		"jackpot": [],
		"bust": [],
		"overdrive": ["plain"]
	})
	battle.set("pending_slot", "overdrive")
	battle.set("damage_multiplier", 1.0)
	battle.set("payout_multiplier", 1.0)
	battle.set("enemy_damage_delta", 0)
	battle.set("cash", 20)
	battle.set("enemy_hp", 19)
	battle._resolve_pending()
	await _settle(8)
	if int(battle.get("enemy_hp")) != 0:
		failures.append("blue_chisel overdrive path did not add enough damage to finish the enemy")
	if int(battle.get("cash")) < 28:
		failures.append("victory cash relics did not add through BattleScene")
	if not _has_effect(battle.get("last_applied_effects") as Array, "victory_cash_bonus"):
		failures.append("last_call_bell did not record BattleScene resolution effect")

func _has_effect(effects: Array, effect_id: String) -> bool:
	for item in effects:
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
