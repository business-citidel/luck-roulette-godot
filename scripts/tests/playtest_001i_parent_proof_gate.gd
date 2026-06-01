extends SceneTree

const RUN_SCENE := "res://scenes/run/run_root.tscn"
const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const EventScene := preload("res://scenes/run/event_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")
const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control
var battle: Control

func _initialize() -> void:
	print("001i parent proof gate playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _render_end_to_end_proof()
	await _render_choice_state_matrix()
	await _render_relic_proof()
	await _clear_active()
	await _clear_battle()

	if failures.is_empty():
		print("001i parent proof gate playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _render_end_to_end_proof() -> void:
	var scene: PackedScene = load(RUN_SCENE)
	if scene == null:
		failures.append("could not load run root scene")
		return
	var run_root: Control = scene.instantiate()
	root.add_child(run_root)
	await _start_to_map(run_root)
	await _opening_reward_return(run_root)
	await _shot("00_e2e_map_return_after_reward_relic")
	await _event_return(run_root)
	await _shot("01_e2e_map_return_after_event_prep")
	await _shop_return(run_root)
	await _shot("02_e2e_map_return_after_shop_relic")
	await _rest_return(run_root)
	await _shot("03_e2e_map_return_after_rest_prep")
	await _next_combat_entry(run_root)
	await _shot("04_e2e_next_combat_hud_receipts")
	await _relic_trigger_feedback(run_root)
	await _shot("05_e2e_relic_trigger_feedback_loaded_die")
	run_root.queue_free()
	await _settle(2)

func _render_choice_state_matrix() -> void:
	await _show_reward("relic")
	await _shot("06_state_reward_chosen_disabled")
	await _show_event("event_relic_trade")
	await _shot("07_state_event_chosen_disabled")
	await _show_rest("rest_prepare")
	await _shot("08_state_rest_chosen_disabled")
	await _show_shop(42, "select_relic")
	await _shot("09_state_shop_selected_preview")
	await _show_shop(42, "buy_relic")
	await _shot("10_state_shop_sold_disabled")
	await _show_shop(10, "")
	await _shot("11_state_shop_unaffordable_disabled")
	await _show_shop(42, "leave")
	await _shot("12_state_shop_skipped_leave")
	await _show_rest("rest_leave")
	await _shot("13_state_rest_skipped_leave")

func _render_relic_proof() -> void:
	await _clear_active()
	await _show_all_relic_entry()
	await _shot("14_relic_all_relics_combat_entry")
	await _show_turn_token_feedback()
	await _shot("15_relic_turn_token_feedback")
	await _show_resolution_relic_feedback()
	await _shot("16_relic_resolution_normal_apply_path")

func _start_to_map(run_root: Control) -> void:
	await _wait_for_run_scene(run_root, "title", 900)
	run_root._test_start_run()
	await _wait_for_run_scene(run_root, "intro", 900)
	run_root._test_skip_intro()
	await _wait_for_run_scene(run_root, "map", 900)

func _opening_reward_return(run_root: Control) -> void:
	run_root._test_select_current_map_node()
	await _wait_for_combat(run_root, 900)
	await _settle(30)
	_emit_combat_victory(run_root, "001i-shot-opening")
	await _wait_for_run_scene(run_root, "reward", 900)
	var reward_scene: Control = _run_active_scene(run_root)
	if reward_scene == null:
		failures.append("opening reward scene unavailable")
		return
	reward_scene._choose_relic()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _event_return(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("event")
	await _wait_for_run_scene(run_root, "event", 900)
	var event_scene: Control = _run_active_scene(run_root)
	if event_scene == null:
		failures.append("event scene unavailable")
		return
	event_scene._choose_risk_gold()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _shop_return(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("shop")
	await _wait_for_run_scene(run_root, "shop", 900)
	var shop_scene: Control = _run_active_scene(run_root)
	if shop_scene == null:
		failures.append("shop scene unavailable")
		return
	shop_scene._buy_relic()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _rest_return(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("rest")
	await _wait_for_run_scene(run_root, "rest", 900)
	var rest_scene: Control = _run_active_scene(run_root)
	if rest_scene == null:
		failures.append("rest scene unavailable")
		return
	rest_scene._prepare()
	await _wait_for_run_scene(run_root, "map", 900)
	await _settle(10)

func _next_combat_entry(run_root: Control) -> void:
	run_root._test_select_current_map_node_type("combat")
	await _wait_for_combat(run_root, 900)
	await _wait_for_payload_node(run_root, "n4", 900)
	await _settle(18)
	if run_root.get("active_combat") == null:
		failures.append("next combat unavailable")

func _relic_trigger_feedback(run_root: Control) -> void:
	var combat: Control = run_root.get("active_combat") as Control
	if combat == null:
		failures.append("cannot trigger relic feedback without active combat")
		return
	combat._apply_dice_ritual_result({
		"dice_rule_id": "single_attack_die",
		"dice_values": [2],
		"dice": [2],
		"dice_locked": [false],
		"rerolls_left": 0,
		"applied_effects": []
	})
	await _settle(4)

func _show_reward(choice_id: String) -> void:
	await _clear_active()
	active_scene = RewardScene.instantiate()
	active_scene.configure({
		"run_state": _sample_run_state(),
		"combat_result": {
			"winnings": 18
		}
	})
	root.add_child(active_scene)
	await _settle(6)
	match choice_id:
		"money":
			active_scene._choose_money()
		"relic":
			active_scene._choose_relic()
		"heal":
			active_scene._choose_heal()
	if choice_id != "":
		await _settle(6)

func _show_event(choice_id: String) -> void:
	await _clear_active()
	active_scene = EventScene.instantiate()
	active_scene.configure({
		"run_state": _sample_run_state(),
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(6)
	match choice_id:
		"event_gold":
			active_scene._choose_gold()
		"event_relic_trade":
			active_scene._choose_trade()
		"event_risk_gold":
			active_scene._choose_risk_gold()
	if choice_id != "":
		await _settle(6)

func _show_rest(choice_id: String) -> void:
	await _clear_active()
	active_scene = RestScene.instantiate()
	active_scene.configure({
		"run_state": _sample_run_state(),
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(6)
	match choice_id:
		"rest_heal":
			active_scene._heal()
		"rest_prepare":
			active_scene._prepare()
		"rest_leave":
			active_scene._leave()
	if choice_id != "":
		await _settle(6)

func _show_shop(gold: int, action: String) -> void:
	await _clear_active()
	var run_state := _sample_run_state()
	run_state["gold"] = gold
	active_scene = ShopScene.instantiate()
	active_scene.configure({
		"run_state": run_state,
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(6)
	match action:
		"select_relic":
			active_scene._select_purchase(active_scene._relic_result())
		"buy_relic":
			active_scene._buy_relic()
		"buy_prep":
			active_scene._buy_prep()
		"leave":
			active_scene._leave()
	if action != "":
		await _settle(6)

func _show_all_relic_entry() -> void:
	await _clear_battle()
	battle = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.configure_encounter({
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"combat_cash": 20,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 80,
		"enemy_max_hp": 80,
		"dice_rule_id": "single_attack_die",
		"relic_ids": RelicCatalog.all_ids(),
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	await _settle(18)

func _show_turn_token_feedback() -> void:
	if battle == null:
		failures.append("cannot show turn-token feedback without battle")
		return
	battle._next_turn()
	await _settle(6)

func _show_resolution_relic_feedback() -> void:
	if battle == null:
		failures.append("cannot show resolution feedback without battle")
		return
	battle.set("attack_base", 10)
	battle.set("placed_slots", {
		"safe": ["plain"],
		"profit": ["plain"],
		"jackpot": ["plain"],
		"bust": [],
		"overdrive": []
	})
	battle.set("pending_slot", "jackpot")
	battle.set("damage_multiplier", 1.0)
	battle.set("payout_multiplier", 1.0)
	battle.set("cash", 20)
	battle.set("enemy_hp", 80)
	battle._resolve_pending()
	await _settle(6)

func _sample_run_state() -> Dictionary:
	return {
		"gold": 42,
		"player_hp": 32,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die"],
		"next_combat_mods": [{
			"id": "rest_prepared_table",
			"enemy_damage_delta": -3,
			"description": "Rest prep: next enemy hit is softened."
		}]
	}

func _run_active_scene(run_root: Control) -> Control:
	var director = run_root.get("run_director")
	if director == null:
		return null
	return director.active_scene as Control

func _wait_for_run_scene(run_root: Control, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		var director = run_root.get("run_director")
		if str(run_root.get("phase")) == expected and director != null and str(director.active_scene_name) == expected:
			return
		await process_frame
	failures.append("timed out waiting for run scene: " + expected)

func _wait_for_combat(run_root: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if run_root.get("active_combat") != null:
			return
		await process_frame
	failures.append("timed out waiting for combat")

func _wait_for_payload_node(run_root: Control, node_id: String, max_frames: int) -> void:
	for i in range(max_frames):
		var payload: Dictionary = run_root.get("last_encounter_payload") as Dictionary
		if run_root.get("active_combat") != null and str(payload.get("node_id", "")) == node_id:
			return
		await process_frame
	failures.append("timed out waiting for combat payload node: " + node_id)

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

func _clear_active() -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame

func _clear_battle() -> void:
	if battle != null:
		battle.queue_free()
		battle = null
		await process_frame

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _shot(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path: String = shot_dir.path_join(name + ".png")
	var err: Error = image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
