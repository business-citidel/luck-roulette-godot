extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const RelicEffectResolver := preload("res://scripts/systems/relic_effect_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_catalog_hooks_are_known()
	_check_wrapper_compatibility()
	await _check_battle_uses_trigger_api()

	if failures.is_empty():
		print("relic hook contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog_hooks_are_known() -> void:
	var supported: Array[String] = RelicEffectResolver.supported_triggers()
	for relic_id in RelicCatalog.all_ids():
		var hooks: Array[String] = RelicCatalog.hooks(relic_id)
		if hooks.is_empty():
			failures.append(str(relic_id) + " does not declare trigger hooks")
		for hook in hooks:
			if not supported.has(hook):
				failures.append(str(relic_id) + " declares unknown hook " + hook)

func _check_wrapper_compatibility() -> void:
	var dice_payload := {
		"dice_rule_id": "single_attack_die",
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	}
	var wrapper: Dictionary = EffectResolver.apply_relics_to_dice_result(dice_payload, ["loaded_die"])
	var trigger: Dictionary = EffectResolver.apply_relic_trigger("dice_result", dice_payload, ["loaded_die"])
	if int((wrapper.get("dice", []) as Array)[0]) != int((trigger.get("dice", []) as Array)[0]):
		failures.append("dice wrapper diverged from trigger API")
	if not _has_effect(trigger, "attack_die_plus_one"):
		failures.append("dice trigger did not record loaded die effect")

	var roulette: Dictionary = EffectResolver.apply_relic_trigger("roulette_before_spin", {
		"roulette_respins_left": 1,
		"applied_effects": []
	}, ["second_chance"])
	if int(roulette.get("roulette_respins_left", 0)) != 2:
		failures.append("roulette trigger did not apply direct respin relic")

	var unknown: Dictionary = EffectResolver.apply_relic_trigger("future_trigger", {"applied_effects": []}, ["loaded_die"])
	if str(unknown.get("unknown_relic_trigger", "")) != "future_trigger":
		failures.append("unknown trigger did not preserve diagnostic marker")

func _check_battle_uses_trigger_api() -> void:
	root.size = Vector2i(1280, 720)
	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.configure_encounter({
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"combat_cash": 18,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 20,
		"enemy_max_hp": 20,
		"dice_rule_id": "single_attack_die",
		"relic_ids": ["loaded_die"],
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	await _settle(4)
	battle._apply_dice_ritual_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	})
	await _settle(8)
	var dice: Array = battle.get("dice") as Array
	if dice.is_empty() or int(dice[0]) != 3:
		failures.append("battle dice_result trigger did not apply loaded_die")
	if int(battle.get("attack_base")) != 3:
		failures.append("battle attack_base did not reflect dice_result trigger")
	var marbles: Array = battle.get("marbles") as Array
	if marbles.size() != 1:
		failures.append("battle did not continue into exactly one marble gain after dice trigger")
	elif str(marbles[0]) != "plain":
		failures.append("battle dice trigger created colored marble instead of neutral plain token")
	battle.queue_free()
	await process_frame

func _has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
