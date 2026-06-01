extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var run_state = RunStateScript.new()
	run_state.player_hp = 40
	run_state.player_max_hp = 42
	run_state.relic_ids.append("loaded_die")
	run_state.relic_ids.append("green_purse")
	run_state.next_combat_mods.append({"id": "rest_prepared_table", "enemy_damage_delta": -3})
	run_state.next_combat_mods.append({"id": "shop_cash_marker", "combat_cash": 5})

	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("crook_table"))
	if not (payload.get("relic_ids", []) as Array).has("loaded_die") or not (payload.get("relic_ids", []) as Array).has("green_purse"):
		failures.append("encounter payload did not receive active relics")
	if (payload.get("next_combat_mods", []) as Array).size() != 2:
		failures.append("encounter payload did not keep consumed prep receipt")
	if int(payload.get("enemy_damage_delta", 0)) != -3:
		failures.append("encounter payload did not apply rest prep and encounter damage delta")
	if int(payload.get("combat_cash", 0)) < 23:
		failures.append("encounter payload did not apply shop combat cash")
	if not _has_effect(payload, "rest_prepared_table") or not _has_effect(payload, "shop_cash_marker"):
		failures.append("encounter payload did not record prep effects")
	if not (run_state.next_combat_mods as Array).is_empty():
		failures.append("run state did not consume next combat mods")

	var battle: Control = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.configure_encounter(payload)
	await process_frame
	if not (battle.get("active_relic_ids") as Array).has("green_purse"):
		failures.append("battle did not receive active relic ids")
	if int(battle.get("cash")) != int(payload.get("combat_cash", 0)):
		failures.append("battle cash did not use encounter payload")
	if int(battle.get("enemy_damage_delta")) != int(payload.get("enemy_damage_delta", 0)):
		failures.append("battle enemy_damage_delta did not use encounter payload")
	if not str(battle.get("message")).contains("유물"):
		failures.append("battle start message did not mention relic receipt")
	var run_hud: Control = battle.get("run_hud") as Control
	if run_hud == null or (run_hud.get("active_prep_mods") as Array).size() != 2:
		failures.append("battle HUD did not receive consumed prep receipt")
	battle.queue_free()
	await process_frame

	var second_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("crook_table"))
	if _has_effect(second_payload, "rest_prepared_table") or _has_effect(second_payload, "shop_cash_marker"):
		failures.append("next combat prep applied twice")

	if failures.is_empty():
		print("next combat receipt consumption smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _has_effect(payload: Dictionary, effect_id: String) -> bool:
	for item in payload.get("applied_effects", []):
		if item is Dictionary and str((item as Dictionary).get("effect_id", "")) == effect_id:
			return true
	return false
