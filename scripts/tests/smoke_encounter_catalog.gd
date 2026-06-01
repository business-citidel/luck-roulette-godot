extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")
const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_catalog_nodes()
	_check_payloads()
	if failures.is_empty():
		print("encounter catalog smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog_nodes() -> void:
	var nodes: Array[Dictionary] = EncounterCatalog.map_nodes()
	if nodes.size() < 6:
		failures.append("encounter catalog has too few nodes")
	if not EncounterCatalog.has_encounter("final_house_table"):
		failures.append("encounter catalog lacks final_house_table")
	var final := EncounterCatalog.get_encounter("final_house_table")
	if str(final.get("node_type", "")) != "boss":
		failures.append("final encounter is not boss node type")
	if str(final.get("monster_id", "")) != "final_house":
		failures.append("final encounter does not route final_house")
	if not bool(final.get("is_final", false)):
		failures.append("final encounter lacks is_final")
	if str(final.get("on_victory", "")) != "run_clear":
		failures.append("final encounter does not route to run_clear")
	var step_one_types: Array[String] = EncounterCatalog.available_node_types(1)
	if not step_one_types.has("event") or not step_one_types.has("elite"):
		failures.append("step one does not expose event/elite branch")
	var dense_nodes := EncounterCatalog.map_nodes("dense_10")
	if dense_nodes.size() != 10:
		failures.append("dense 10 map probe should expose exactly 10 nodes")
	if EncounterCatalog.final_step("dense_10") != 7:
		failures.append("dense 10 map probe should end at step 7")
	var token_nodes := EncounterCatalog.map_nodes("token_10")
	if token_nodes.size() != 10:
		failures.append("token 10 map probe should expose exactly 10 nodes")
	if EncounterCatalog.final_step("token_10") != 7:
		failures.append("token 10 map probe should end at step 7")
	var scroll_nodes := EncounterCatalog.map_nodes("scroll_20")
	if scroll_nodes.size() != 20:
		failures.append("scroll 20 map probe should expose exactly 20 nodes")
	if EncounterCatalog.final_step("scroll_20") != 9:
		failures.append("scroll 20 map probe should end at step 9")
	var random_floor_two_nodes := EncounterCatalog.map_nodes("scroll_20_random", "smoke:floor:2")
	var floor_two_pool: Array[String] = MonsterCatalog.normal_pool_for_floor(2)
	for node in random_floor_two_nodes:
		if str(node.get("node_type", "")) != "combat":
			continue
		var monster_id := str(node.get("monster_id", ""))
		if not floor_two_pool.has(monster_id):
			failures.append("floor two random combat used monster outside pool: " + monster_id)

func _check_payloads() -> void:
	var run_state: Resource = RunStateScript.new()
	run_state.player_hp = 31
	run_state.relic_ids.append("loaded_die")
	var normal_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("opening_debt"))
	if str(normal_payload.get("monster_id", "")) != "debt_collector":
		failures.append("normal encounter did not build debt_collector payload")
	if str(normal_payload.get("reward_tier", "")) != "normal":
		failures.append("normal encounter reward tier missing")
	if bool(normal_payload.get("is_final", true)):
		failures.append("normal encounter marked final")
	var elite_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("risky_elite"))
	if str(elite_payload.get("monster_id", "")) != "elite_house":
		failures.append("elite encounter did not build elite_house payload")
	if str(elite_payload.get("reward_tier", "")) != "elite":
		failures.append("elite encounter reward tier missing")
	var boss_payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("final_house_table"))
	if str(boss_payload.get("monster_id", "")) != "final_house":
		failures.append("boss encounter did not build final_house payload")
	if str(boss_payload.get("on_victory", "")) != "run_clear":
		failures.append("boss payload did not carry run_clear route")
	if not bool(boss_payload.get("is_final", false)):
		failures.append("boss payload is not final")
	if boss_payload.has("dice") or boss_payload.has("marbles") or boss_payload.has("placed_slots"):
		failures.append("encounter payload leaked battle-local attack resources")
