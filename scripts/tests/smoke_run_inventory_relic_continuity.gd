extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	var run_state = RunStateScript.new()
	run_state.gold = 48
	run_state.player_hp = 38
	run_state.player_max_hp = 42
	EffectResolver.apply_reward_result(run_state, _result("reward", 0, ["loaded_die"], []))
	EffectResolver.apply_reward_result(run_state, _result("shop", -30, ["green_purse"], [{"id": "shop_edge_prep", "enemy_damage_delta": -2}]))
	EffectResolver.apply_reward_result(run_state, _result("duplicate", 0, ["loaded_die"], []))

	if run_state.relic_ids.size() != 2 or run_state.relic_ids[0] != "loaded_die" or run_state.relic_ids[1] != "green_purse":
		failures.append("run relic ids did not remain unique and ordered")
	var table_state: Dictionary = RunTableState.from_run_payload(run_state.to_payload())
	var relics: Array = table_state.get("relic_tray", [])
	if relics.size() != 2:
		failures.append("run table relic tray did not expose both owned relics")
	elif str((relics[0] as Dictionary).get("state", "")) != "owned":
		failures.append("owned relic tray state changed")
	var prep_notes: Array = table_state.get("queued_prep_notes", [])
	if prep_notes.size() != 1:
		failures.append("run table did not expose queued prep note")

	var map: Control = RunMapScene.instantiate()
	map.configure(run_state.to_payload())
	root.size = Vector2i(1280, 720)
	root.add_child(map)
	await process_frame
	var map_state: Dictionary = map.get("run_state")
	if (map_state.get("relic_ids", []) as Array).size() != 2:
		failures.append("map did not preserve relic ids in configured run state")
	if (map_state.get("next_combat_mods", []) as Array).size() != 1:
		failures.append("map did not preserve queued prep notes in configured run state")
	map.queue_free()
	await process_frame

	if failures.is_empty():
		print("run inventory relic continuity smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _result(choice: String, gold_delta: int, relic_ids: Array, mods: Array) -> Dictionary:
	return {
		"accepted": true,
		"choice": choice,
		"gold_delta": gold_delta,
		"hp_delta": 0,
		"relic_ids": relic_ids,
		"next_combat_mods": mods
	}
