extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

const VALID_TOKEN_IDS := [
	"combat",
	"elite",
	"boss",
	"shop",
	"rest",
	"event_mystery",
	"event_chest",
	"event_quest",
	"event_gamble"
]

const EVENT_SUBTYPES := ["mystery", "chest", "quest", "gamble"]

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_token_assets()
	for i in range(10):
		_check_seed("scroll-random-audit-" + str(i).pad_zeros(2))
	await _check_map_emit_for_subtypes("scroll-random-audit-04")
	if failures.is_empty():
		print("map token runtime 9 smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_token_assets() -> void:
	for token_id in VALID_TOKEN_IDS:
		var texture := AssetCatalog.map_node_token_texture(str(token_id))
		if texture == null:
			failures.append("missing map token texture " + str(token_id))
			continue
		if texture.get_width() <= 0 or texture.get_height() <= 0:
			failures.append("invalid map token texture size " + str(token_id))

func _check_seed(seed_text: String) -> void:
	var nodes := EncounterCatalog.map_nodes("scroll_20_random", seed_text)
	var subtype_counts := {"mystery": 0, "chest": 0, "quest": 0, "gamble": 0}
	for node in nodes:
		var node_type := str(node.get("node_type", ""))
		var token_id := str(node.get("node_token_id", ""))
		if not VALID_TOKEN_IDS.has(token_id):
			failures.append(seed_text + " invalid token id " + token_id + " on " + str(node.get("node_id", "")))
		if node_type == "event":
			var subtype := str(node.get("node_subtype", ""))
			if not EVENT_SUBTYPES.has(subtype):
				failures.append(seed_text + " invalid event subtype " + subtype)
			if token_id != "event_" + subtype:
				failures.append(seed_text + " event token/subtype mismatch " + token_id + " / " + subtype)
			if str(node.get("event_pool", "")) != token_id:
				failures.append(seed_text + " event pool should match token id " + token_id)
			subtype_counts[subtype] = int(subtype_counts.get(subtype, 0)) + 1
		elif token_id != node_type:
			failures.append(seed_text + " non-event token should match node type " + token_id + " / " + node_type)
	for subtype in ["chest", "quest", "gamble"]:
		if int(subtype_counts[subtype]) < 1:
			failures.append(seed_text + " missing guaranteed event subtype " + subtype)

func _check_map_emit_for_subtypes(seed_text: String) -> void:
	var nodes := EncounterCatalog.map_nodes("scroll_20_random", seed_text + ":floor:1")
	for subtype in EVENT_SUBTYPES:
		var target := _first_event_node(nodes, subtype)
		if target.is_empty():
			failures.append("no node available for subtype " + subtype)
			continue
		var scene: Control = RunMapScene.instantiate()
		var emitted: Array[Dictionary] = []
		scene.completed.connect(func(result: Dictionary) -> void: emitted.append(result))
		scene.configure({
			"map_variant": "scroll_20_random",
			"seed_text": seed_text,
			"floor_index": 1,
			"max_floor": 3,
			"map_step": int(target.get("node_index", 0)),
			"completed_nodes": _completed_prefix(nodes, int(target.get("node_index", 0))),
			"player_hp": 42,
			"player_max_hp": 42,
			"gold": 30,
			"relic_ids": [],
			"next_combat_mods": []
		})
		root.add_child(scene)
		await process_frame
		scene._select_node_by_id(str(target.get("node_id", "")))
		await process_frame
		if emitted.size() != 1:
			failures.append("map did not emit exactly once for subtype " + subtype)
		else:
			var result: Dictionary = emitted[0]
			var expected_pool: String = "event_" + subtype
			if str(result.get("node_type", "")) != "event":
				failures.append("subtype " + subtype + " should still emit node_type event")
			if str(result.get("node_subtype", "")) != subtype:
				failures.append("subtype " + subtype + " did not survive map emit")
			if str(result.get("node_token_id", "")) != expected_pool:
				failures.append("token id " + expected_pool + " did not survive map emit")
			if str(result.get("event_pool", "")) != expected_pool:
				failures.append("event pool " + expected_pool + " did not survive map emit")
			if not EventCatalog.pack_event_ids(expected_pool).has(EventCatalog.configured_event_id({
				"seed_text": seed_text
			}, result)):
				failures.append("event pool " + expected_pool + " did not configure into its own catalog pool")
		scene.queue_free()
		await process_frame

func _first_event_node(nodes: Array[Dictionary], subtype: String) -> Dictionary:
	for node in nodes:
		if str(node.get("node_type", "")) == "event" and str(node.get("node_subtype", "")) == subtype:
			return node
	return {}

func _completed_prefix(nodes: Array[Dictionary], through_step: int) -> Array[String]:
	var result: Array[String] = []
	for step in range(through_step):
		for node in nodes:
			if int(node.get("node_index", -1)) == step:
				result.append(str(node.get("node_id", "")))
				break
	return result
