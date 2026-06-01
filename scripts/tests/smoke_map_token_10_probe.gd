extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_catalog()
	await _check_scene()
	if failures.is_empty():
		print("token 10 map probe smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog() -> void:
	var nodes := EncounterCatalog.map_nodes("token_10")
	if nodes.size() != 10:
		failures.append("token map should expose exactly 10 visible nodes")
	if EncounterCatalog.final_step("token_10") != 7:
		failures.append("token map final step should be 7")
	var step_one := EncounterCatalog.available_node_types(1, "token_10")
	if not step_one.has("event") or not step_one.has("elite"):
		failures.append("token map step one should expose event/elite branch")
	var step_three := EncounterCatalog.available_node_types(3, "token_10")
	if not step_three.has("combat") or not step_three.has("event"):
		failures.append("token map step three should expose combat/event branch")

func _check_scene() -> void:
	var run_map: Control = RunMapScene.instantiate()
	run_map.configure({
		"map_variant": "token_10",
		"map_step": 3,
		"completed_nodes": ["d0", "d1", "d2"],
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
	if nodes.size() != 10 or buttons.size() != 10:
		failures.append("token map scene did not build 10 nodes and buttons")
	var rects: Array[Rect2] = []
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i] as Dictionary
		var button := buttons[i] as Button
		var rect: Rect2 = run_map._node_rect(node)
		rects.append(rect)
		if button == null:
			failures.append("token map button " + str(i) + " missing")
			continue
		if button.position.distance_to(rect.position) > 0.01:
			failures.append("token map button " + str(i) + " position mismatch")
		if button.size.distance_to(rect.size) > 0.01:
			failures.append("token map button " + str(i) + " size mismatch")
		var should_be_enabled := int(node["node_index"]) == 3
		if button.disabled == should_be_enabled:
			failures.append("token map button " + str(i) + " disabled state mismatch")
		if rect.position.x < 78.0 or rect.end.x > 1204.0 or rect.position.y < 88.0 or rect.end.y > 634.0:
			failures.append("token map hit rect outside table bounds: " + str(node.get("node_id", "")))
	for a in range(rects.size()):
		for b in range(a + 1, rects.size()):
			if rects[a].intersects(rects[b]):
				failures.append("token map hit rects overlap: " + str(a) + " and " + str(b))
	run_map.queue_free()
	await process_frame
