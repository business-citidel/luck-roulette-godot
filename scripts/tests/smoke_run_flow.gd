extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const CollectionProgressService := preload("res://scripts/systems/collection_progress_service.gd")
const GoStopButtonDriver := preload("res://scripts/tests/support/go_stop_button_driver.gd")

var failures: Array[String] = []

func _initialize() -> void:
	CollectionProgressService.clear_progress()
	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		push_error("Could not load run root scene")
		quit(1)
		return

	var run_root: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(run_root)
	var run_state = run_root.get("run_state")
	var reward_relic_id := ""
	var relic_count_after_reward := 0
	await _wait_for_run_scene(run_root, "title", 900)
	if str(run_root.get("phase")) != "title":
		failures.append("run root did not open title")
	else:
		run_root._test_start_run()
	await _wait_for_run_scene(run_root, "character_select", 900)
	if str(run_root.get("phase")) != "character_select":
		failures.append("run start did not open character select")
	else:
		run_root._test_select_default_character()
	await _wait_for_run_scene(run_root, "map", 900)
	run_state = run_root.get("run_state")
	if str(run_root.get("phase")) != "map":
		failures.append("run root did not open map after character select")
	elif str(run_state.get("character_id")) != "default_guard_dice":
		failures.append("selected character did not persist into run state")
	elif not CollectionProgressService.is_character_discovered("default_guard_dice"):
		failures.append("selected character should be recorded as discovered")
	else:
		run_root._test_select_current_map_node()

	await _wait_for_combat(run_root, 900)
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("map did not launch combat")
	else:
		await _drive_combat_to_victory(combat)

	await _wait_for_run_scene(run_root, "reward", 1200)
	if str(run_root.get("phase")) != "reward" and combat != null:
		_emit_combat_victory(run_root, "normal-smoke-fallback")
		await _wait_for_run_scene(run_root, "reward", 1200)
	if str(run_root.get("phase")) != "reward":
		failures.append("combat victory did not open reward")
	else:
		run_root._test_choose_default_reward()

	await _wait_for_run_scene(run_root, "map", 1200)
	run_state = run_root.get("run_state")
	if str(run_root.get("phase")) != "map":
		failures.append("reward did not return to map")
	elif int(run_state.map_step) < 1:
		failures.append("map progress did not advance")
	elif int(run_state.gold) <= 0:
		failures.append("run gold did not persist after reward")
	elif run_state.relic_ids.is_empty():
		failures.append("reward relic did not persist into run state")
	else:
		reward_relic_id = str(run_state.relic_ids[0])
		relic_count_after_reward = run_state.relic_ids.size()
		if not CollectionProgressService.is_relic_discovered(reward_relic_id):
			failures.append("reward relic should be recorded as discovered")
		var first_monster := str((run_root.get("last_encounter_payload") as Dictionary).get("monster_id", ""))
		if first_monster != "" and not CollectionProgressService.is_monster_discovered(first_monster):
			failures.append("combat monster should be recorded as discovered")

	if failures.is_empty():
		run_root._test_jump_to_first_map_node_type("event", int(run_state.map_step))
		await _wait_for_run_scene(run_root, "map", 900)
		run_root._test_route_current_map_node_type_direct("event")
		await _wait_for_run_scene(run_root, "event", 900)
		if str(run_root.get("phase")) != "event":
			failures.append("event node did not route to EventScene")
		else:
			var event_id := str(run_root.run_director.active_scene.get("active_event_id"))
			if event_id != "" and not CollectionProgressService.is_event_discovered(event_id):
				failures.append("entered event should be recorded as discovered")
			run_root._test_choose_default_scene()
			await _wait_for_run_scene(run_root, "map", 900)
			run_state = run_root.get("run_state")
			if int(run_state.map_step) < 1:
				failures.append("event did not return to map and advance")

	if failures.is_empty():
		run_root._test_jump_to_first_map_node_type("shop", int(run_state.map_step))
		await _wait_for_run_scene(run_root, "map", 900)
		run_root._test_route_current_map_node_type_direct("shop")
		await _wait_for_run_scene(run_root, "shop", 900)
		if str(run_root.get("phase")) != "shop":
			failures.append("shop node did not route to ShopScene")
		else:
			run_root._test_choose_default_scene()
			await _wait_for_run_scene(run_root, "map", 900)
			run_state = run_root.get("run_state")
			if run_state.relic_ids.size() <= relic_count_after_reward:
				failures.append("shop relic did not persist into run state")

	if failures.is_empty():
		run_root._test_jump_to_first_map_node_type("rest", int(run_state.map_step))
		await _wait_for_run_scene(run_root, "map", 900)
		if not (run_state.potion_ids as Array).has("upgrade_voucher"):
			run_state.potion_ids.append("upgrade_voucher")
		run_root._test_route_current_map_node_type_direct("rest")
		await _wait_for_run_scene(run_root, "rest", 900)
		if str(run_root.get("phase")) != "rest":
			failures.append("rest node did not route to RestScene")
		else:
			run_root._test_choose_default_scene()
			await _wait_for_run_scene(run_root, "map", 900)
			run_state = run_root.get("run_state")
			if (run_state.run_upgrades as Dictionary).is_empty():
				failures.append("rest did not add a run upgrade")

	if failures.is_empty():
		await run_root._test_mount_combat_encounter("crook_table")
		await _wait_for_combat(run_root, 900)
		await _wait_for_combat_relic(run_root, reward_relic_id, 900)
		var next_combat: Control = run_root.get("active_combat") as Control
		if next_combat == null:
			failures.append("second combat did not open")
		elif not (next_combat.get("active_relic_ids") as Array).has(reward_relic_id):
			failures.append("second combat did not receive relic IDs")
		elif not (run_root.get("last_encounter_payload") as Dictionary).get("relic_ids", []).has(reward_relic_id):
			failures.append("encounter payload did not include persisted relic")
		elif (next_combat.get("active_relic_ids") as Array).size() < 2:
			failures.append("shop relic did not reach second combat")
		elif str((run_root.get("last_encounter_payload") as Dictionary).get("monster_id", "")) == "":
			failures.append("second combat did not receive monster_id")
		elif ((run_root.get("last_encounter_payload") as Dictionary).get("move_pattern", []) as Array).is_empty():
			failures.append("second combat did not receive monster move pattern")
		elif (run_state.run_upgrades as Dictionary).is_empty():
			failures.append("run upgrade was consumed like a one-combat modifier")
		elif int(next_combat.get("cash")) != int((run_root.get("last_encounter_payload") as Dictionary).get("combat_cash", 18)) or (next_combat.get("marbles") as Array).size() != 0:
			failures.append("second combat did not reset battle-local resources")

	if failures.is_empty():
		await _settle(45)
		await run_root._test_finish_active_combat_victory("normal-repeat")
		await _wait_for_run_scene(run_root, "reward", 1200)
		if str(run_root.get("phase")) != "reward":
			failures.append("second combat victory did not route to reward")
		else:
			run_root._test_choose_default_reward()
			await _wait_for_run_scene(run_root, "map", 1200)
			run_state = run_root.get("run_state")
			if int(run_state.map_step) < 1:
				failures.append("map did not advance after second combat reward")

	if failures.is_empty():
		run_state.floor_index = run_state.max_floor
		run_state.map_theme_id = "04_max_hp_pressure"
		run_state.map_step = EncounterCatalog.final_step(str(run_state.map_variant), str(run_state.seed_text) + ":floor:" + str(run_state.floor_index))
		run_state.completed_nodes.clear()
		run_root._test_show_map_at_step(int(run_state.map_step))
		await _wait_for_run_scene(run_root, "map", 900)
		var final_types: Array[String] = run_root._test_available_map_node_types()
		if not final_types.has("boss"):
			failures.append("final map step did not expose boss node")
		await run_root._test_mount_combat_encounter("final_house_table")
		await _wait_for_payload_monster(run_root, "final_house", 1200)
		var boss_combat: Control = run_root.get("active_combat") as Control
		var boss_payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
		if boss_combat == null:
			failures.append("boss node did not launch combat")
		elif str(boss_payload.get("monster_id", "")) != "final_house":
			failures.append("boss node did not route final_house")
		elif not bool(boss_payload.get("is_final", false)):
			failures.append("boss payload was not marked final")
		else:
			await _settle(45)
			await run_root._test_finish_active_combat_victory("boss")
			await _wait_for_terminal_phase(run_root, "run_clear", 1200)
			if str(run_root.get("phase")) != "run_clear":
				failures.append("boss victory did not route to run_clear")
			elif str(run_root.run_director.active_scene_name) != "run_clear":
				failures.append("run clear terminal scene did not mount")
			else:
				run_root._test_restart_from_run_end()
				await _wait_for_run_scene(run_root, "character_select", 900)
				run_root._test_select_default_character()
				await _wait_for_run_scene(run_root, "map", 900)
				if str(run_root.get("phase")) != "map":
					failures.append("restart from run clear did not return to map")
				run_root._test_force_run_clear()
				await _wait_for_terminal_phase(run_root, "run_clear", 900)
				run_root._test_return_to_title_from_run_end()
				await _wait_for_run_scene(run_root, "title", 900)
				if str(run_root.get("phase")) != "title":
					failures.append("main menu action did not return to title")

	if failures.is_empty():
		print("run flow smoke passed")
		run_root.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		run_root.queue_free()
		await process_frame
		quit(1)

func _drive_combat_to_victory(combat: Control) -> void:
	combat._roll_dice()
	await _wait_for_dice_roll(combat, 180)
	await _settle(8)
	if combat.ritual_director.active_ritual != null:
		failures.append("inline table dice opened a ritual in run combat")
		return
	if str(combat.get("dice_rule_id")) == "two_dice_attack_guard":
		combat._select_attack_die(0)
		await _settle(8)
	combat.set("attack_base", 120)
	if str(combat.get("combat_core")) == "numeric_roulette":
		if str(combat.get("phase")) != "wager" and str(combat.get("phase")) != "marble_choice":
			combat._take_marbles()
		if str(combat.get("phase")) == "marble_choice":
			combat._choose_revealed_marble(0)
			await _settle(4)
		combat.set("numeric_forced_indices", [9])
		while int(combat.get("wager_marbles_committed")) < int(combat.get("wager_marbles_available")):
			_press_button_by_text(combat, "Go", "run flow wager Go")
		await _settle(1)
		await _settle(4)
		if str(combat.get("selected_marble_id")) != "":
			_press_button_by_any_text(combat, ["Spin", "돌리기"], "run flow selected marble spin")
		else:
			_press_button_by_text(combat, "Stop", "run flow roulette spin")
		await _wait_for_combat_phase(combat, "intervene", 1200)
		if str(combat.phase) != "intervene":
			failures.append("numeric roulette spin failed in run combat")
			return
		combat.set("cash", 80)
		_press_button_by_text(combat, "Stop", "run flow roulette resolve")
		await _wait_for_combat_finished(combat, 1200)
		return
	if str(combat.get("phase")) != "marble" or (combat.get("marbles") as Array).is_empty():
		combat._take_marbles()
	await _settle(12)
	combat._open_marble_throw_ritual()
	await _wait_for_marble_setup_ready(combat, 1200)
	if not combat._marble_setup_ready():
		failures.append("inline marble placement failed in run combat")
		return
	combat._open_roulette_spin_ritual()
	await _wait_for_combat_phase(combat, "intervene", 1200)
	if str(combat.phase) != "intervene":
		failures.append("inline roulette spin failed in run combat")
		return
	combat.set("cash", 80)
	combat._resolve_pending()
	await _wait_for_combat_finished(combat, 1200)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_dice_roll(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(combat.get("dice_rolled")):
			return
		await process_frame

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame

func _wait_for_combat(run_root: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if run_root.get("active_combat") != null:
			return
		await process_frame

func _wait_for_combat_relic(run_root: Control, relic_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var combat: Control = run_root.get("active_combat") as Control
		if combat != null and (combat.get("active_relic_ids") as Array).has(relic_id):
			return
		await process_frame

func _wait_for_payload_monster(run_root: Control, monster_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
		if run_root.get("active_combat") != null and str(payload.get("monster_id", "")) == monster_id:
			return
		await process_frame

func _wait_for_ritual(combat: Control, ritual_name: String, max_frames: int) -> void:
	for i in range(max_frames):
		if combat.ritual_director != null and str(combat.ritual_director.active_ritual_name) == ritual_name:
			return
		await process_frame

func _wait_for_ritual_close(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if combat.ritual_director != null and combat.ritual_director.active_ritual == null:
			return
		await process_frame

func _wait_for_ritual_phase(ritual: Node, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if ritual != null and str(ritual.get("phase")) == expected:
			return
		await process_frame

func _wait_for_marble_setup_ready(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if combat._marble_setup_ready():
			return
		await process_frame

func _wait_for_combat_finished(combat: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(combat.get("combat_result_emitted")):
			return
		await process_frame

func _wait_for_combat_phase(combat: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(combat.phase) == expected:
			return
		await process_frame

func _emit_combat_victory(run_root: Control, reason: String) -> void:
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("cannot emit victory without active combat: " + reason)
		return
	var payload: Dictionary = (run_root.get("last_encounter_payload") as Dictionary).duplicate(true)
	var winnings: int = max(80, int(payload.get("combat_cash", 18)))
	combat.combat_finished.emit({
		"accepted": true,
		"reason": reason,
		"victory": true,
		"defeat": false,
		"cash": winnings,
		"combat_cash": winnings,
		"winnings": winnings,
		"player_hp": int(payload.get("player_hp", 42)),
		"enemy_hp": 0,
		"relic_ids": payload.get("relic_ids", []),
		"encounter_id": str(payload.get("encounter_id", "")),
		"monster_id": str(payload.get("monster_id", "")),
		"is_final": bool(payload.get("is_final", false)),
		"on_victory": str(payload.get("on_victory", "reward"))
	})

func _press_button_by_text(combat: Control, text: String, context: String) -> void:
	var result: String = GoStopButtonDriver.press_button_by_text(combat, text)
	if result != "":
		failures.append(context + " action " + text + " was " + result)

func _press_button_by_any_text(combat: Control, texts: Array[String], context: String) -> void:
	var results: Array[String] = []
	for text in texts:
		var result: String = GoStopButtonDriver.press_button_by_text(combat, text)
		if result == "":
			return
		results.append(text + ":" + result)
	failures.append(context + " actions were " + ", ".join(results))

func _wait_for_terminal_phase(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(run_root.get("phase")) == expected:
			return
		await process_frame
