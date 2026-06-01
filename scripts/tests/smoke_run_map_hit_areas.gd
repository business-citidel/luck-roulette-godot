extends SceneTree

const MAP_SCENE := "res://scenes/run/run_map_scene.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(MAP_SCENE)
	if scene == null:
		push_error("Could not load run map scene")
		quit(1)
		return

	var run_map: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	run_map.configure({
		"map_step": 1,
		"completed_nodes": ["n0"],
		"player_hp": 42,
		"player_max_hp": 42,
		"gold": 20,
		"relic_ids": [],
		"next_combat_mods": []
	})
	root.add_child(run_map)
	await process_frame

	var nodes: Array = run_map.get("nodes") as Array
	var buttons: Array = run_map.get("buttons") as Array
	if buttons.size() != nodes.size():
		failures.append("map button count did not match node count")

	for i in range(min(buttons.size(), nodes.size())):
		var button: Button = buttons[i] as Button
		var node: Dictionary = nodes[i] as Dictionary
		var rect: Rect2 = run_map._node_rect(node)
		if button == null:
			failures.append("map button " + str(i) + " was not a Button")
			continue
		if button.position.distance_to(rect.position) > 0.01:
			failures.append("map button " + str(i) + " position did not match card rect")
		if button.size.distance_to(rect.size) > 0.01:
			failures.append("map button " + str(i) + " size did not match card rect")
		var should_be_enabled: bool = int(node["node_index"]) == 1
		if button.disabled == should_be_enabled:
			failures.append("map button " + str(i) + " disabled state did not match map step")

	if failures.is_empty():
		print("run map hit area smoke passed")
		run_map.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_map.queue_free()
		await process_frame
		quit(1)
