extends SceneTree

const TITLE_SCENE := preload("res://scenes/run/title_scene.tscn")
const MAP_SCENE := preload("res://scenes/run/run_map_scene.tscn")
const REWARD_SCENE := preload("res://scenes/run/reward_scene.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _load_scene("title", TITLE_SCENE, {})
	await _load_scene("map", MAP_SCENE, {
		"player_hp": 42,
		"player_max_hp": 42,
		"gold": 12,
		"relic_ids": [],
		"map_step": 0
	})
	await _load_scene("reward", REWARD_SCENE, {
		"run_state": {
			"player_hp": 32,
			"player_max_hp": 42,
			"gold": 18,
			"relic_ids": []
		},
		"combat_result": {
			"winnings": 9
		}
	})
	await _load_scene("battle", BATTLE_SCENE, {
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 56,
		"enemy_max_hp": 56,
		"monster_id": "debt_collector",
		"monster_name": "Debt Collector",
		"combat_cash": 18,
		"enemy_damage_delta": 0,
		"relic_ids": []
	})

	if failures.is_empty():
		print("smoke_screen_loads: passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _load_scene(label: String, scene: PackedScene, payload: Dictionary) -> void:
	if scene == null:
		failures.append(label + ": packed scene is null")
		return
	var node := scene.instantiate()
	if node == null:
		failures.append(label + ": instantiate returned null")
		return
	if node.has_method("configure"):
		node.call("configure", payload)
	root.add_child(node)
	await process_frame
	if node.has_method("configure_encounter"):
		node.call("configure_encounter", payload)
	await process_frame
	await process_frame
	if not is_instance_valid(node):
		failures.append(label + ": scene freed during load smoke")
		return
	if node.get_parent() != root:
		failures.append(label + ": scene parent changed during load smoke")
	node.queue_free()
	await process_frame
