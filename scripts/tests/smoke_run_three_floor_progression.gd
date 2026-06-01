extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		push_error("Could not load run root scene")
		quit(1)
		return
	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)
	await _start_run_to_map(run_root)
	if failures.is_empty():
		await _clear_floor_boss(run_root, 1)
	if failures.is_empty():
		await _clear_floor_boss(run_root, 2)
	if failures.is_empty():
		await _clear_floor_boss(run_root, 3)
	if failures.is_empty():
		print("three floor progression smoke passed")
		run_root.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_root.queue_free()
		await process_frame
		quit(1)

func _start_run_to_map(run_root: Control) -> void:
	await _wait_for_run_scene(run_root, "title", 900)
	if str(run_root.get("phase")) != "title":
		failures.append("run root did not open title")
		return
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	if str(run_root.get("phase")) != "character_select":
		failures.append("start did not open character select")
		return
	run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)
	var run_state = run_root.get("run_state")
	if str(run_root.get("phase")) != "map":
		failures.append("character select did not open map")
	elif int(run_state.floor_index) != 1:
		failures.append("new run should start on floor 1")
	elif int(run_state.max_floor) != 3:
		failures.append("new run should have max floor 3")
	elif str(run_state.map_variant) != "scroll_20_random":
		failures.append("new run should use scroll_20_random map")
	elif str(run_state.map_theme_id) != "01_base":
		failures.append("floor 1 should use base map theme")

func _clear_floor_boss(run_root: Control, floor: int) -> void:
	var run_state = run_root.get("run_state")
	if int(run_state.floor_index) != floor:
		failures.append("expected floor " + str(floor) + " but got " + str(run_state.floor_index))
		return
	var final_step := EncounterCatalog.final_step(str(run_state.map_variant), str(run_state.seed_text) + ":floor:" + str(floor))
	run_state.map_step = final_step
	run_state.completed_nodes = _completed_prefix(str(run_state.map_variant), str(run_state.seed_text), floor, final_step)
	if floor < int(run_state.max_floor):
		run_state.player_hp = 7
	run_root._test_show_map_at_step(final_step)
	await _wait_for_run_scene(run_root, "map", 900)
	var types: Array[String] = run_root._test_available_map_node_types()
	if not types.has("boss"):
		failures.append("floor " + str(floor) + " final step did not expose boss")
		return
	await run_root._test_mount_combat_encounter("final_house_table")
	await _wait_for_payload_monster(run_root, "final_house", 1200)
	var boss_payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
	if str(boss_payload.get("monster_id", "")) != "final_house":
		failures.append("floor " + str(floor) + " boss did not route final_house; phase=" + str(run_root.get("phase")) + " payload=" + str(boss_payload))
		return
	if not bool(boss_payload.get("is_final", false)):
		failures.append("floor " + str(floor) + " boss payload was not final")
		return
	await run_root._test_finish_active_combat_victory("floor-" + str(floor) + "-boss")
	if floor < 3:
		await _wait_for_run_scene(run_root, "map", 1200)
		if str(run_root.get("phase")) != "map":
			failures.append("floor " + str(floor) + " boss did not return to next map")
			return
		if int(run_state.floor_index) != floor + 1:
			failures.append("floor " + str(floor) + " boss did not advance to floor " + str(floor + 1))
		if int(run_state.map_step) != 0:
			failures.append("floor " + str(floor + 1) + " map should reset to step 0")
		if int(run_state.player_hp) != int(run_state.player_max_hp):
			failures.append("floor " + str(floor) + " boss clear should fully heal for next floor")
		if not (run_state.completed_nodes as Array).is_empty():
			failures.append("floor " + str(floor + 1) + " should reset completed nodes")
		var expected_theme := "02_enemy_power" if floor + 1 == 2 else "04_max_hp_pressure"
		if str(run_state.map_theme_id) != expected_theme:
			failures.append("floor " + str(floor + 1) + " theme mismatch")
	else:
		await _wait_for_terminal_phase(run_root, "run_clear", 1200)
		if str(run_root.get("phase")) != "run_clear":
			failures.append("floor 3 boss did not route to run_clear")

func _completed_prefix(variant: String, seed_text: String, floor: int, through_step: int) -> Array[String]:
	var nodes := EncounterCatalog.map_nodes(variant, seed_text + ":floor:" + str(floor))
	var result: Array[String] = []
	for step in range(through_step):
		for node in nodes:
			if int(node.get("node_index", -1)) == step:
				result.append(str(node.get("node_id", "")))
				break
	return result

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame

func _wait_for_terminal_phase(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == expected:
			return
		await process_frame

func _wait_for_payload_monster(run_root: Control, monster_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
		if str(payload.get("monster_id", "")) == monster_id:
			return
		await process_frame
