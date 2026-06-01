extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_direct_reactive_moves()
	await _check_battle_scene_passes_last_turn_state()

	if failures.is_empty():
		print("elite reactive move contract smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_direct_reactive_moves() -> void:
	var appraised: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("dice_appraisal", {
		"player_hp": 42,
		"run_gold": 12,
		"last_attack_base": 9
	}, 0)
	if float(appraised.get("player_damage_multiplier", 1.0)) >= 1.0:
		failures.append("dice_appraisal should weaken high attack-base turns")
	if int(appraised.get("enemy_block", 0)) <= 0:
		failures.append("dice_appraisal should add enemy block against high attack-base turns")

	var low_appraised: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("dice_appraisal", {
		"player_hp": 42,
		"run_gold": 12,
		"last_attack_base": 5
	}, 0)
	if float(low_appraised.get("player_damage_multiplier", 1.0)) < 1.0 or int(low_appraised.get("enemy_block", 0)) > 0:
		failures.append("dice_appraisal should not punish modest attack-base turns")

	var audited: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("roulette_audit", {
		"player_hp": 42,
		"run_gold": 12,
		"last_roulette_multiplier": 0.0,
		"last_roulette_go_used": true
	}, 0)
	if int(audited.get("enemy_damage_delta", 0)) <= 0:
		failures.append("roulette_audit should ramp after a go attempt")
	if int(audited.get("enemy_block", 0)) <= 0:
		failures.append("roulette_audit should guard after a low/bust roulette result")

	var tithed: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("guard_tithe", {
		"player_hp": 42,
		"player_block": 8,
		"run_gold": 9
	}, 0)
	if int(tithed.get("run_gold", 0)) != 5 or int(tithed.get("gold_delta", 0)) != -4:
		failures.append("guard_tithe should tax run gold when player block is high")
	if int(tithed.get("enemy_damage_delta", 0)) <= 0:
		failures.append("guard_tithe should add future pressure when player block is high")

	var empty_tithe: Dictionary = MonsterMoveCatalog.resolve_enemy_turn("guard_tithe", {
		"player_hp": 42,
		"player_block": 8,
		"run_gold": 0
	}, 0)
	if int(empty_tithe.get("run_gold", 99)) != 0 or int(empty_tithe.get("gold_delta", 99)) != 0:
		failures.append("guard_tithe should not create negative run gold")

func _check_battle_scene_passes_last_turn_state() -> void:
	var combat: Control = BattleScene.instantiate()
	root.add_child(combat)
	await process_frame
	combat.configure_encounter({
		"combat_core": "numeric_roulette",
		"combat_cash": 18,
		"run_gold": 10,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 40,
		"enemy_max_hp": 40,
		"dice_rule_id": "single_attack_die",
		"monster_id": "taxed_roulette_knight",
		"monster_name": "Taxed Roulette Knight",
		"move_pattern": ["roulette_audit"]
	})
	await process_frame
	combat.set("last_roulette_multiplier", 0.0)
	combat.set("last_roulette_go_used", true)
	var result: Dictionary = combat._resolve_monster_move("roulette_audit", 0)
	if int(result.get("enemy_damage_delta", 0)) <= 0:
		failures.append("BattleScene should pass last roulette go state into monster move resolution")
	if int(result.get("enemy_block", 0)) <= 0:
		failures.append("BattleScene should pass last roulette multiplier into monster move resolution")
	combat.set("last_attack_base", 9)
	result = combat._resolve_monster_move("dice_appraisal", 0)
	if float(result.get("player_damage_multiplier", 1.0)) >= 1.0:
		failures.append("BattleScene should pass last attack base into monster move resolution")
	if int(result.get("enemy_block", 0)) <= 0:
		failures.append("BattleScene should pass dice appraisal block result through")
	combat.set("player_block", 8)
	combat.set("run_gold", 9)
	result = combat._resolve_monster_move("guard_tithe", 0)
	if int(result.get("run_gold", 0)) != 5 or int(result.get("gold_delta", 0)) != -4:
		failures.append("BattleScene should pass live block and run gold into guard tithe resolution")
	combat.queue_free()
	await process_frame
