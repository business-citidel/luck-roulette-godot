extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_check_catalog()
	await _check_scene()
	if failures.is_empty():
		print("scroll 20 map probe smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_catalog() -> void:
	var nodes := EncounterCatalog.map_nodes("scroll_20")
	if nodes.size() != 20:
		failures.append("scroll map should expose exactly 20 visible nodes")
	if EncounterCatalog.final_step("scroll_20") != 9:
		failures.append("scroll map final step should be 9")
	var step_two := EncounterCatalog.available_node_types(2, "scroll_20")
	if not step_two.has("combat") or not step_two.has("shop") or not step_two.has("event"):
		failures.append("scroll map step two should expose combat/shop/event")
	var step_four := EncounterCatalog.available_node_types(4, "scroll_20")
	if not step_four.has("event") or not step_four.has("combat") or not step_four.has("elite"):
		failures.append("scroll map step four should expose event/combat/elite")

func _check_scene() -> void:
	var run_map: Control = RunMapScene.instantiate()
	run_map.configure({
		"map_variant": "scroll_20",
		"map_step": 4,
		"completed_nodes": ["s0", "s1a", "s2b", "s3a"],
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
	if nodes.size() != 20 or buttons.size() != 20:
		failures.append("scroll map scene did not build 20 nodes and buttons")
	var current_visible := 0
	var current_rects: Array[Rect2] = []
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i] as Dictionary
		var button := buttons[i] as Button
		var rect: Rect2 = run_map._node_rect(node)
		if button == null:
			failures.append("scroll map button " + str(i) + " missing")
			continue
		if button.position.distance_to(rect.position) > 0.01:
			failures.append("scroll map button " + str(i) + " position mismatch")
		if button.size.distance_to(rect.size) > 0.01:
			failures.append("scroll map button " + str(i) + " size mismatch")
		var should_be_enabled := int(node["node_index"]) == 4
		if button.disabled == should_be_enabled:
			failures.append("scroll map button " + str(i) + " disabled state mismatch")
		if should_be_enabled:
			current_rects.append(rect)
			if rect.get_center().y >= 130.0 and rect.get_center().y <= 610.0:
				current_visible += 1
	if current_visible < 3:
		failures.append("scroll map did not auto-center the current branch")
	for a in range(current_rects.size()):
		for b in range(a + 1, current_rects.size()):
			if current_rects[a].intersects(current_rects[b]):
				failures.append("scroll map current hit rects overlap: " + str(a) + " and " + str(b))
	run_map.queue_free()
	await process_frame
