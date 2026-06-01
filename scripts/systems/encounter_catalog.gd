class_name EncounterCatalog
extends RefCounted

const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")

const ENCOUNTERS := {
	"opening_debt": {
		"encounter_id": "opening_debt",
		"node_id": "n0",
		"node_type": "combat",
		"node_index": 0,
		"label": "combat",
		"monster_id": "debt_collector",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(210, 430)
	},
	"crossroad_event": {
		"encounter_id": "crossroad_event",
		"node_id": "n1",
		"node_type": "event",
		"node_index": 1,
		"label": "event",
		"event_pool": "first_pack",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(390, 300)
	},
	"risky_elite": {
		"encounter_id": "risky_elite",
		"node_id": "n1e",
		"node_type": "elite",
		"node_index": 1,
		"label": "elite",
		"monster_id": "elite_house",
		"reward_tier": "elite",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(390, 510)
	},
	"mid_shop": {
		"encounter_id": "mid_shop",
		"node_id": "n2",
		"node_type": "shop",
		"node_index": 2,
		"label": "shop",
		"monster_id": "",
		"reward_tier": "shop",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(590, 384)
	},
	"rest_before_table": {
		"encounter_id": "rest_before_table",
		"node_id": "n3",
		"node_type": "rest",
		"node_index": 3,
		"label": "rest",
		"monster_id": "",
		"reward_tier": "rest",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(780, 260)
	},
	"crook_table": {
		"encounter_id": "crook_table",
		"node_id": "n4",
		"node_type": "combat",
		"node_index": 4,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(960, 394)
	},
	"final_house_table": {
		"encounter_id": "final_house_table",
		"node_id": "n5",
		"node_type": "boss",
		"node_index": 5,
		"label": "boss",
		"monster_id": "final_house",
		"reward_tier": "final",
		"is_final": true,
		"on_victory": "run_clear",
		"pos": Vector2(1110, 276)
	}
}

const ORDER := [
	"opening_debt",
	"crossroad_event",
	"risky_elite",
	"mid_shop",
	"rest_before_table",
	"crook_table",
	"final_house_table"
]

const DENSE_10_ENCOUNTERS := {
	"dense_opening_debt": {
		"encounter_id": "opening_debt",
		"node_id": "d0",
		"node_type": "combat",
		"node_index": 0,
		"label": "combat",
		"monster_id": "debt_collector",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(170, 424)
	},
	"dense_red_event": {
		"encounter_id": "crossroad_event",
		"node_id": "d1",
		"node_type": "event",
		"node_index": 1,
		"label": "event",
		"event_pool": "catalog",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(310, 276)
	},
	"dense_elite_gate": {
		"encounter_id": "risky_elite",
		"node_id": "d1e",
		"node_type": "elite",
		"node_index": 1,
		"label": "elite",
		"monster_id": "elite_house",
		"reward_tier": "elite",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(310, 518)
	},
	"dense_coupon_shop": {
		"encounter_id": "mid_shop",
		"node_id": "d2",
		"node_type": "shop",
		"node_index": 2,
		"label": "shop",
		"monster_id": "",
		"reward_tier": "shop",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(458, 398)
	},
	"dense_crook_table": {
		"encounter_id": "crook_table",
		"node_id": "d3",
		"node_type": "combat",
		"node_index": 3,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(604, 276)
	},
	"dense_story_event": {
		"encounter_id": "crossroad_event",
		"node_id": "d3e",
		"node_type": "event",
		"node_index": 3,
		"label": "event",
		"event_pool": "catalog",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(604, 518)
	},
	"dense_rest_before_table": {
		"encounter_id": "rest_before_table",
		"node_id": "d4",
		"node_type": "rest",
		"node_index": 4,
		"label": "rest",
		"monster_id": "",
		"reward_tier": "rest",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(746, 398)
	},
	"dense_late_combat": {
		"encounter_id": "crook_table",
		"node_id": "d5",
		"node_type": "combat",
		"node_index": 5,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(888, 282)
	},
	"dense_last_shop": {
		"encounter_id": "mid_shop",
		"node_id": "d6",
		"node_type": "shop",
		"node_index": 6,
		"label": "shop",
		"monster_id": "",
		"reward_tier": "shop",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(1018, 408)
	},
	"dense_final_house": {
		"encounter_id": "final_house_table",
		"node_id": "d7",
		"node_type": "boss",
		"node_index": 7,
		"label": "boss",
		"monster_id": "final_house",
		"reward_tier": "final",
		"is_final": true,
		"on_victory": "run_clear",
		"pos": Vector2(1130, 354)
	}
}

const DENSE_10_ORDER := [
	"dense_opening_debt",
	"dense_red_event",
	"dense_elite_gate",
	"dense_coupon_shop",
	"dense_crook_table",
	"dense_story_event",
	"dense_rest_before_table",
	"dense_late_combat",
	"dense_last_shop",
	"dense_final_house"
]

const SCROLL_20_ENCOUNTERS := {
	"scroll_opening": {
		"encounter_id": "opening_debt",
		"node_id": "s0",
		"node_type": "combat",
		"node_index": 0,
		"label": "combat",
		"monster_id": "debt_collector",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(640, 1370)
	},
	"scroll_event_a": {
		"encounter_id": "crossroad_event",
		"node_id": "s1a",
		"node_type": "event",
		"node_index": 1,
		"label": "event",
		"event_pool": "catalog",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(450, 1260)
	},
	"scroll_elite_a": {
		"encounter_id": "risky_elite",
		"node_id": "s1b",
		"node_type": "elite",
		"node_index": 1,
		"label": "elite",
		"monster_id": "elite_house",
		"reward_tier": "elite",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(830, 1260)
	},
	"scroll_combat_a": {
		"encounter_id": "crook_table",
		"node_id": "s2a",
		"node_type": "combat",
		"node_index": 2,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(280, 1145)
	},
	"scroll_shop_a": {
		"encounter_id": "mid_shop",
		"node_id": "s2b",
		"node_type": "shop",
		"node_index": 2,
		"label": "shop",
		"monster_id": "",
		"reward_tier": "shop",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(640, 1145)
	},
	"scroll_event_b": {
		"encounter_id": "crossroad_event",
		"node_id": "s2c",
		"node_type": "event",
		"node_index": 2,
		"label": "event",
		"event_pool": "catalog",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(1000, 1145)
	},
	"scroll_combat_b": {
		"encounter_id": "crook_table",
		"node_id": "s3a",
		"node_type": "combat",
		"node_index": 3,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(450, 1030)
	},
	"scroll_rest_a": {
		"encounter_id": "rest_before_table",
		"node_id": "s3b",
		"node_type": "rest",
		"node_index": 3,
		"label": "rest",
		"monster_id": "",
		"reward_tier": "rest",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(830, 1030)
	},
	"scroll_event_c": {
		"encounter_id": "crossroad_event",
		"node_id": "s4a",
		"node_type": "event",
		"node_index": 4,
		"label": "event",
		"event_pool": "catalog",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(300, 915)
	},
	"scroll_combat_c": {
		"encounter_id": "crook_table",
		"node_id": "s4b",
		"node_type": "combat",
		"node_index": 4,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(640, 915)
	},
	"scroll_elite_b": {
		"encounter_id": "risky_elite",
		"node_id": "s4c",
		"node_type": "elite",
		"node_index": 4,
		"label": "elite",
		"monster_id": "elite_house",
		"reward_tier": "elite",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(980, 915)
	},
	"scroll_shop_b": {
		"encounter_id": "mid_shop",
		"node_id": "s5a",
		"node_type": "shop",
		"node_index": 5,
		"label": "shop",
		"monster_id": "",
		"reward_tier": "shop",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(500, 800)
	},
	"scroll_rest_b": {
		"encounter_id": "rest_before_table",
		"node_id": "s5b",
		"node_type": "rest",
		"node_index": 5,
		"label": "rest",
		"monster_id": "",
		"reward_tier": "rest",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(780, 800)
	},
	"scroll_combat_d": {
		"encounter_id": "crook_table",
		"node_id": "s6a",
		"node_type": "combat",
		"node_index": 6,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(360, 685)
	},
	"scroll_event_d": {
		"encounter_id": "crossroad_event",
		"node_id": "s6b",
		"node_type": "event",
		"node_index": 6,
		"label": "event",
		"event_pool": "catalog",
		"monster_id": "",
		"reward_tier": "event",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(640, 685)
	},
	"scroll_combat_e": {
		"encounter_id": "crook_table",
		"node_id": "s6c",
		"node_type": "combat",
		"node_index": 6,
		"label": "combat",
		"monster_id": "table_crook",
		"reward_tier": "normal",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(920, 685)
	},
	"scroll_elite_c": {
		"encounter_id": "risky_elite",
		"node_id": "s7a",
		"node_type": "elite",
		"node_index": 7,
		"label": "elite",
		"monster_id": "elite_house",
		"reward_tier": "elite",
		"is_final": false,
		"on_victory": "reward",
		"pos": Vector2(500, 570)
	},
	"scroll_shop_c": {
		"encounter_id": "mid_shop",
		"node_id": "s7b",
		"node_type": "shop",
		"node_index": 7,
		"label": "shop",
		"monster_id": "",
		"reward_tier": "shop",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(780, 570)
	},
	"scroll_rest_gate": {
		"encounter_id": "rest_before_table",
		"node_id": "s8",
		"node_type": "rest",
		"node_index": 8,
		"label": "rest",
		"monster_id": "",
		"reward_tier": "rest",
		"is_final": false,
		"on_victory": "map",
		"pos": Vector2(640, 455)
	},
	"scroll_final_house": {
		"encounter_id": "final_house_table",
		"node_id": "s9",
		"node_type": "boss",
		"node_index": 9,
		"label": "boss",
		"monster_id": "final_house",
		"reward_tier": "final",
		"is_final": true,
		"on_victory": "run_clear",
		"pos": Vector2(640, 250)
	}
}

const SCROLL_20_ORDER := [
	"scroll_opening",
	"scroll_event_a",
	"scroll_elite_a",
	"scroll_combat_a",
	"scroll_shop_a",
	"scroll_event_b",
	"scroll_combat_b",
	"scroll_rest_a",
	"scroll_event_c",
	"scroll_combat_c",
	"scroll_elite_b",
	"scroll_shop_b",
	"scroll_rest_b",
	"scroll_combat_d",
	"scroll_event_d",
	"scroll_combat_e",
	"scroll_elite_c",
	"scroll_shop_c",
	"scroll_rest_gate",
	"scroll_final_house"
]

const SCROLL_20_LINKS := {
	"s0": ["s1a", "s1b"],
	"s1a": ["s2a", "s2b"],
	"s1b": ["s2b", "s2c"],
	"s2a": ["s3a"],
	"s2b": ["s3a", "s3b"],
	"s2c": ["s3b"],
	"s3a": ["s4a", "s4b"],
	"s3b": ["s4b", "s4c"],
	"s4a": ["s5a"],
	"s4b": ["s5a", "s5b"],
	"s4c": ["s5b"],
	"s5a": ["s6a", "s6b"],
	"s5b": ["s6b", "s6c"],
	"s6a": ["s7a"],
	"s6b": ["s7a", "s7b"],
	"s6c": ["s7b"],
	"s7a": ["s8"],
	"s7b": ["s8"],
	"s8": ["s9"]
}

const RANDOM_SCROLL_STEPS := 20
const RANDOM_SCROLL_BOSS_STEP := 19
const RANDOM_SCROLL_MIN_COUNTS := {
	"event": 5,
	"elite": 2,
	"rest": 2,
	"shop": 2
}

static func get_encounter(encounter_id: String) -> Dictionary:
	return ENCOUNTERS.get(encounter_id, ENCOUNTERS["opening_debt"]).duplicate(true)

static func has_encounter(encounter_id: String) -> bool:
	return ENCOUNTERS.has(encounter_id)

static func map_nodes(variant: String = "", seed_text: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if variant == "dense_10" or variant == "token_10":
		for id in DENSE_10_ORDER:
			result.append((DENSE_10_ENCOUNTERS[id] as Dictionary).duplicate(true))
		return result
	if variant == "scroll_20":
		for id in SCROLL_20_ORDER:
			var node := (SCROLL_20_ENCOUNTERS[id] as Dictionary).duplicate(true)
			node["next_node_ids"] = SCROLL_20_LINKS.get(str(node.get("node_id", "")), [])
			result.append(node)
		return result
	if variant == "scroll_20_random":
		return generate_scroll_20_random(seed_text)
	for id in ORDER:
		result.append(get_encounter(id))
	return result

static func resolve_node(map_result: Dictionary) -> Dictionary:
	var encounter_id: String = str(map_result.get("encounter_id", ""))
	if encounter_id != "" and has_encounter(encounter_id):
		return _merge(get_encounter(encounter_id), map_result)
	var node_id: String = str(map_result.get("node_id", map_result.get("id", "")))
	for id in ORDER:
		var encounter := get_encounter(id)
		if str(encounter.get("node_id", "")) == node_id:
			return _merge(encounter, map_result)
	var node_type: String = str(map_result.get("node_type", map_result.get("type", "")))
	var node_index: int = int(map_result.get("node_index", map_result.get("index", -1)))
	for id in ORDER:
		var encounter := get_encounter(id)
		if str(encounter.get("node_type", "")) == node_type and int(encounter.get("node_index", -2)) == node_index:
			return _merge(encounter, map_result)
	return _merge(get_encounter("opening_debt"), map_result)

static func available_node_types(step: int, variant: String = "", seed_text: String = "") -> Array[String]:
	var result: Array[String] = []
	for node in map_nodes(variant, seed_text):
		if int(node.get("node_index", -1)) == step:
			result.append(str(node.get("node_type", "")))
	return result

static func final_step(variant: String = "", seed_text: String = "") -> int:
	var result := 0
	for node in map_nodes(variant, seed_text):
		if bool(node.get("is_final", false)):
			result = max(result, int(node.get("node_index", result)))
	return result

static func generate_scroll_20_random(seed_text: String = "") -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("scroll_20_random:" + seed_text)
	var floor_index := _floor_index_from_seed_text(seed_text)
	var rows: Array[Array] = []
	for step in range(RANDOM_SCROLL_STEPS):
		if step == 0:
			rows.append(["combat"])
		elif step == RANDOM_SCROLL_BOSS_STEP:
			rows.append(["boss"])
		else:
			rows.append(_random_scroll_row(step, rng))
	_apply_random_scroll_minimums(rows, rng)
	var event_subtypes := _random_scroll_event_subtypes(rows, rng)
	var nodes_by_step: Array[Array] = []
	var nodes: Array[Dictionary] = []
	for step in range(RANDOM_SCROLL_STEPS):
		var row_nodes: Array[Dictionary] = []
		var types: Array = rows[step]
		var xs := _row_x_positions(types.size(), rng)
		for i in range(types.size()):
			var node_type := str(types[i])
			var subtype := str(event_subtypes.get(_event_subtype_key(step, i), "mystery"))
			var node := _random_scroll_node(node_type, step, i, Vector2(float(xs[i]), _scroll_random_y(step)), subtype, floor_index, seed_text)
			row_nodes.append(node)
			nodes.append(node)
		nodes_by_step.append(row_nodes)
	_apply_random_scroll_links(nodes_by_step, rng)
	return nodes

static func _random_scroll_row(step: int, rng: RandomNumberGenerator) -> Array:
	var count := 1
	var roll := rng.randf()
	if roll > 0.78:
		count = 3
	elif roll > 0.34:
		count = 2
	var result: Array = []
	var attempts := 0
	while result.size() < count and attempts < 20:
		attempts += 1
		var node_type := _random_scroll_type(step, rng)
		if result.has(node_type):
			continue
		result.append(node_type)
	while result.size() < count:
		result.append("combat")
	return result

static func _random_scroll_type(step: int, rng: RandomNumberGenerator) -> String:
	var elite_allowed := step >= 3 and step <= 16
	var rest_allowed := step >= 4 and step <= 18
	var shop_allowed := step >= 2 and step <= 18
	var roll := rng.randf()
	if elite_allowed and roll < 0.09:
		return "elite"
	if rest_allowed and roll < 0.20:
		return "rest"
	if shop_allowed and roll < 0.32:
		return "shop"
	if roll < 0.58:
		return "event"
	return "combat"

static func _apply_random_scroll_minimums(rows: Array[Array], rng: RandomNumberGenerator) -> void:
	for node_type in RANDOM_SCROLL_MIN_COUNTS.keys():
		var needed := int(RANDOM_SCROLL_MIN_COUNTS[node_type]) - _count_type_in_rows(rows, str(node_type))
		while needed > 0:
			var candidates := _replacement_steps_for(str(node_type), rows)
			if candidates.is_empty():
				break
			var step := int(candidates[rng.randi_range(0, candidates.size() - 1)])
			var row: Array = rows[step]
			var replace_index := _replaceable_index(row)
			if replace_index < 0:
				break
			row[replace_index] = str(node_type)
			needed -= 1

static func _count_type_in_rows(rows: Array[Array], node_type: String) -> int:
	var count := 0
	for row in rows:
		for item in row:
			if str(item) == node_type:
				count += 1
	return count

static func _replacement_steps_for(node_type: String, rows: Array[Array]) -> Array[int]:
	var result: Array[int] = []
	for step in range(1, RANDOM_SCROLL_BOSS_STEP):
		if node_type == "elite" and (step < 3 or step > 16):
			continue
		if node_type == "rest" and step < 4:
			continue
		if node_type == "shop" and step < 2:
			continue
		if rows[step].has(node_type):
			continue
		if _replaceable_index(rows[step]) >= 0:
			result.append(step)
	return result

static func _replaceable_index(row: Array) -> int:
	for i in range(row.size()):
		if str(row[i]) == "combat" or str(row[i]) == "event":
			return i
	return -1

static func _random_scroll_event_subtypes(rows: Array[Array], rng: RandomNumberGenerator) -> Dictionary:
	var positions: Array[Vector2i] = []
	for step in range(1, RANDOM_SCROLL_BOSS_STEP):
		var row: Array = rows[step]
		for i in range(row.size()):
			if str(row[i]) == "event":
				positions.append(Vector2i(step, i))
	var result := {}
	for position in positions:
		result[_event_subtype_key(position.x, position.y)] = "mystery"
	for i in range(positions.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := positions[i]
		positions[i] = positions[j]
		positions[j] = tmp
	var guaranteed := ["chest", "quest", "gamble"]
	for i in range(min(guaranteed.size(), positions.size())):
		var position: Vector2i = positions[i]
		result[_event_subtype_key(position.x, position.y)] = guaranteed[i]
	for i in range(guaranteed.size(), positions.size()):
		var position: Vector2i = positions[i]
		var roll := rng.randf()
		if roll < 0.62:
			result[_event_subtype_key(position.x, position.y)] = "mystery"
		elif roll < 0.76:
			result[_event_subtype_key(position.x, position.y)] = "chest"
		elif roll < 0.89:
			result[_event_subtype_key(position.x, position.y)] = "quest"
		else:
			result[_event_subtype_key(position.x, position.y)] = "gamble"
	return result

static func _event_subtype_key(step: int, row_index: int) -> String:
	return str(step) + ":" + str(row_index)

static func _row_x_positions(count: int, rng: RandomNumberGenerator) -> Array[float]:
	var base: Array[float] = [640.0]
	if count == 2:
		base = [470.0, 810.0]
	elif count >= 3:
		base = [330.0, 640.0, 950.0]
	var result: Array[float] = []
	for x in base:
		result.append(float(x) + rng.randf_range(-24.0, 24.0))
	return result

static func _scroll_random_y(step: int) -> float:
	return 1580.0 - float(step) * 82.0

static func _random_scroll_node(node_type: String, step: int, row_index: int, pos: Vector2, event_subtype: String = "mystery", floor_index: int = 1, seed_text: String = "") -> Dictionary:
	var node_id := "r" + str(step) + "_" + str(row_index)
	var encounter_id := "crook_table"
	var monster_id := MonsterCatalog.id_for_random_node(node_type, floor_index, step, row_index, seed_text)
	var reward_tier := "normal"
	var on_victory := "reward"
	var node_subtype := node_type
	var node_token_id := node_type
	var event_pool := ""
	if step == 0:
		encounter_id = "opening_debt"
	match node_type:
		"event":
			node_subtype = _normalized_event_subtype(event_subtype)
			node_token_id = "event_" + node_subtype
			event_pool = node_token_id
			encounter_id = "crossroad_event"
			monster_id = ""
			reward_tier = "event"
			on_victory = "map"
		"elite":
			encounter_id = "risky_elite"
			monster_id = MonsterCatalog.id_for_random_node("elite", floor_index, step, row_index, seed_text)
			reward_tier = "elite"
		"shop":
			encounter_id = "mid_shop"
			monster_id = ""
			reward_tier = "shop"
			on_victory = "map"
		"rest":
			encounter_id = "rest_before_table"
			monster_id = ""
			reward_tier = "rest"
			on_victory = "map"
		"boss":
			encounter_id = "final_house_table"
			monster_id = MonsterCatalog.id_for_random_node("boss", floor_index, step, row_index, seed_text)
			reward_tier = "final"
			on_victory = "run_clear"
	var result := {
		"encounter_id": encounter_id,
		"node_id": node_id,
		"node_type": node_type,
		"node_subtype": node_subtype,
		"node_token_id": node_token_id,
		"node_index": step,
		"floor_index": floor_index,
		"label": node_token_id if node_type == "event" else node_type,
		"monster_id": monster_id,
		"reward_tier": reward_tier,
		"is_final": node_type == "boss",
		"on_victory": on_victory,
		"pos": pos
	}
	if node_type == "event":
		result["event_pool"] = event_pool
	return result

static func _normalized_event_subtype(event_subtype: String) -> String:
	var subtype := str(event_subtype).replace("event_", "")
	if ["mystery", "chest", "quest", "gamble"].has(subtype):
		return subtype
	return "mystery"

static func _apply_random_scroll_links(nodes_by_step: Array[Array], rng: RandomNumberGenerator) -> void:
	for step in range(nodes_by_step.size() - 1):
		var current_row: Array = nodes_by_step[step]
		var next_row: Array = nodes_by_step[step + 1]
		for node in current_row:
			var sorted_next := next_row.duplicate()
			sorted_next.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return abs(float((a.get("pos", Vector2.ZERO) as Vector2).x) - float((node.get("pos", Vector2.ZERO) as Vector2).x)) < abs(float((b.get("pos", Vector2.ZERO) as Vector2).x) - float((node.get("pos", Vector2.ZERO) as Vector2).x))
			)
			var links: Array[String] = []
			if not sorted_next.is_empty():
				links.append(str((sorted_next[0] as Dictionary).get("node_id", "")))
			if sorted_next.size() > 1 and rng.randf() > 0.46:
				links.append(str((sorted_next[1] as Dictionary).get("node_id", "")))
			node["next_node_ids"] = links

static func _floor_index_from_seed_text(seed_text: String) -> int:
	var marker := ":floor:"
	var marker_index := seed_text.rfind(marker)
	if marker_index < 0:
		return 1
	var suffix := seed_text.substr(marker_index + marker.length())
	var floor := int(suffix)
	return max(1, floor)

static func _merge(base: Dictionary, override: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in override.keys():
		result[key] = override[key]
	return result
