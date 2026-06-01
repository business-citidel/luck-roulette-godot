extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for i in range(10):
		var seed_text := "scroll-random-audit-" + str(i).pad_zeros(2)
		_check_seed(seed_text)
	await _check_scene("scroll-random-audit-04")
	if failures.is_empty():
		print("scroll 20 random seed audit smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_seed(seed_text: String) -> void:
	var nodes := EncounterCatalog.map_nodes("scroll_20_random", seed_text)
	if EncounterCatalog.final_step("scroll_20_random", seed_text) != 19:
		failures.append(seed_text + " final step should be 19")
	var by_id := {}
	var by_step := {}
	var counts := {
		"combat": 0,
		"event": 0,
		"elite": 0,
		"shop": 0,
		"rest": 0,
		"boss": 0
	}
	for node in nodes:
		var node_id := str(node.get("node_id", ""))
		var node_type := str(node.get("node_type", ""))
		var step := int(node.get("node_index", -1))
		by_id[node_id] = node
		if not by_step.has(step):
			by_step[step] = []
		(by_step[step] as Array).append(node)
		counts[node_type] = int(counts.get(node_type, 0)) + 1
	if nodes.size() < 28:
		failures.append(seed_text + " should expose a branchy 20-step route, got " + str(nodes.size()) + " nodes")
	if int(counts["boss"]) != 1:
		failures.append(seed_text + " should have exactly one boss")
	if int(counts["event"]) < 5:
		failures.append(seed_text + " should have at least five events")
	if int(counts["elite"]) < 2:
		failures.append(seed_text + " should have at least two elites")
	if int(counts["rest"]) < 2:
		failures.append(seed_text + " should have at least two rests")
	if int(counts["shop"]) < 2:
		failures.append(seed_text + " should have at least two shops")
	if not _step_has_type(by_step, 0, "combat"):
		failures.append(seed_text + " step zero should start with combat")
	if not _step_has_type(by_step, 19, "boss"):
		failures.append(seed_text + " step nineteen should end with boss")
	for step in range(20):
		if not by_step.has(step):
			failures.append(seed_text + " missing step " + str(step))
			continue
		var row: Array = by_step[step]
		if row.size() < 1 or row.size() > 3:
			failures.append(seed_text + " step " + str(step) + " should have one to three nodes")
		var row_y := INF
		for node in row:
			var pos := (node as Dictionary).get("pos", Vector2.ZERO) as Vector2
			if row_y == INF:
				row_y = pos.y
			elif abs(pos.y - row_y) > 0.01:
				failures.append(seed_text + " step " + str(step) + " nodes should share one y axis")
	for node in nodes:
		var step := int(node.get("node_index", -1))
		if step >= 19:
			continue
		var links: Array = node.get("next_node_ids", [])
		if links.is_empty():
			failures.append(seed_text + " node " + str(node.get("node_id", "")) + " has no outgoing links")
		for link_id in links:
			if not by_id.has(str(link_id)):
				failures.append(seed_text + " link target missing: " + str(link_id))
				continue
			var target: Dictionary = by_id[str(link_id)]
			if int(target.get("node_index", -1)) != step + 1:
				failures.append(seed_text + " link " + str(node.get("node_id", "")) + " -> " + str(link_id) + " should advance one step")
	print(seed_text + " counts " + str(counts) + " total=" + str(nodes.size()))

func _step_has_type(by_step: Dictionary, step: int, node_type: String) -> bool:
	if not by_step.has(step):
		return false
	for node in by_step[step] as Array:
		if str((node as Dictionary).get("node_type", "")) == node_type:
			return true
	return false

func _check_scene(seed_text: String) -> void:
	var nodes := EncounterCatalog.map_nodes("scroll_20_random", seed_text + ":floor:1")
	var completed := _completed_prefix(nodes, 10)
	var run_map: Control = RunMapScene.instantiate()
	run_map.configure({
		"map_variant": "scroll_20_random",
		"seed_text": seed_text,
		"floor_index": 1,
		"max_floor": 3,
		"map_step": 10,
		"completed_nodes": completed,
		"player_hp": 42,
		"player_max_hp": 42,
		"gold": 20,
		"relic_ids": [],
		"next_combat_mods": []
	})
	root.add_child(run_map)
	await process_frame
	var scene_nodes: Array = run_map.get("nodes") as Array
	var buttons: Array = run_map.get("buttons") as Array
	if scene_nodes.size() != nodes.size() or buttons.size() != nodes.size():
		failures.append("random scroll map scene did not mirror catalog node count")
	var current_visible := 0
	for i in range(scene_nodes.size()):
		var node: Dictionary = scene_nodes[i] as Dictionary
		var button := buttons[i] as Button
		if button == null:
			failures.append("random scroll map button " + str(i) + " missing")
			continue
		var should_be_enabled := int(node["node_index"]) == 10
		if button.disabled == should_be_enabled:
			failures.append("random scroll map button " + str(i) + " disabled state mismatch")
		if should_be_enabled:
			var rect: Rect2 = run_map._node_rect(node)
			if rect.get_center().y >= 120.0 and rect.get_center().y <= 620.0:
				current_visible += 1
	if current_visible < 1:
		failures.append("random scroll map did not auto-center current step")
	run_map.queue_free()
	await process_frame

func _completed_prefix(nodes: Array[Dictionary], through_step: int) -> Array[String]:
	var result: Array[String] = []
	for step in range(through_step):
		var row: Array[Dictionary] = []
		for node in nodes:
			if int(node.get("node_index", -1)) == step:
				row.append(node)
		if not row.is_empty():
			result.append(str(row[0].get("node_id", "")))
	return result
