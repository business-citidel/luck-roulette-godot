extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_floor_pools()
	_check_random_map_monsters()

	if failures.is_empty():
		print("floor monster pools smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_floor_pools() -> void:
	var floor_one := MonsterCatalog.normal_pool_for_floor(1)
	var floor_two := MonsterCatalog.normal_pool_for_floor(2)
	var floor_three := MonsterCatalog.normal_pool_for_floor(3)
	for always_id in ["debt_collector", "table_crook", "loaded_dice_runner", "house_errand"]:
		if not floor_one.has(always_id) or not floor_two.has(always_id) or not floor_three.has(always_id):
			failures.append("always monster missing from a floor pool: " + always_id)
	if not floor_one.has("mug_brawler"):
		failures.append("floor one should include mug_brawler")
	if not floor_one.has("pawn_ticket") or not floor_one.has("candle_counter"):
		failures.append("floor one should include batch b table-object normals")
	if not floor_two.has("chip_stack_bruiser") or not floor_two.has("backroom_bookie"):
		failures.append("floor two should include casino backroom pressure monsters")
	if not floor_two.has("bell_ringer") or not floor_two.has("brass_lockbox"):
		failures.append("floor two should include batch b attrition objects")
	if not floor_three.has("roulette_sweeper") or not floor_three.has("pocket_ace_thief"):
		failures.append("floor three should include roulette/card pressure monsters")
	if not floor_three.has("false_dealer_hand") or not floor_three.has("snake_eye_clerk"):
		failures.append("floor three should include trick dealer pressure monsters")
	var floor_three_elites := MonsterCatalog.elite_pool_for_floor(3)
	if not floor_three_elites.has("loaded_vault_keeper"):
		failures.append("floor three elite pool should include loaded_vault_keeper")
	if MonsterCatalog.boss_id_for_floor(2) != "the_croupier":
		failures.append("floor two boss should be the_croupier")
	if MonsterCatalog.boss_id_for_floor(3) != "the_red_seal":
		failures.append("floor three boss should be the_red_seal")

func _check_random_map_monsters() -> void:
	for floor in [1, 2, 3]:
		var nodes := EncounterCatalog.map_nodes("scroll_20_random", "floor-monster-smoke:floor:" + str(floor))
		var floor_pool := MonsterCatalog.normal_pool_for_floor(floor)
		var saw_combat := false
		for node in nodes:
			var node_type := str(node.get("node_type", ""))
			var monster_id := str(node.get("monster_id", ""))
			if node_type == "combat":
				saw_combat = true
				if not floor_pool.has(monster_id):
					failures.append("floor " + str(floor) + " combat outside pool: " + monster_id)
			elif node_type == "elite" or node_type == "boss":
				if not MonsterCatalog.has_monster(monster_id):
					failures.append("floor " + str(floor) + " missing catalog monster: " + monster_id)
		if not saw_combat:
			failures.append("floor " + str(floor) + " random map had no combat nodes")
