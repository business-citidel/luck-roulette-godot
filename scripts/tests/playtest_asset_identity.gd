extends SceneTree

const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const RunStateScript := preload("res://scripts/resources/run_state.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Node
var run_state: Resource

func _initialize() -> void:
	print("asset identity playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	run_state = RunStateScript.new()
	run_state.gold = 42
	run_state.player_hp = 31
	run_state.player_max_hp = 42
	run_state.relic_ids.clear()
	run_state.relic_ids.append("loaded_die")
	run_state.relic_ids.append("green_purse")
	run_state.next_combat_mods.clear()
	run_state.next_combat_mods.append({"id": "proof_soft_start", "enemy_damage_delta": -2})

	await _show_scene("00_map_icons_and_boss_node", "res://scenes/run/run_map_scene.tscn", run_state.to_payload())
	var encounter_payload := EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("final_house_table"))
	await _show_scene("01_battle_opponent_and_table_props", "res://scenes/battle/battle_scene.tscn", encounter_payload, true)
	await _show_inline_battle_flow(encounter_payload)
	await _show_battle_result_feedback("04b_table_resolution_feedback_hit", encounter_payload)
	await _show_scene("05_reward_shared_skin", "res://scenes/run/reward_scene.tscn", {"run_state": run_state.to_payload(), "combat_result": {"winnings": 24, "player_hp": 31}})
	await _show_scene("06_event_identity", "res://scenes/run/event_scene.tscn", {"run_state": run_state.to_payload(), "map_result": EncounterCatalog.get_encounter("crossroad_event")})
	await _show_scene("07_shop_identity", "res://scenes/run/shop_scene.tscn", {"run_state": run_state.to_payload(), "map_result": EncounterCatalog.get_encounter("mid_shop")})
	await _show_scene("08_rest_identity", "res://scenes/run/rest_scene.tscn", {"run_state": run_state.to_payload(), "map_result": EncounterCatalog.get_encounter("rest_before_table")})
	await _show_scene("09_run_clear_identity", "res://scenes/run/run_end_scene.tscn", {
		"result_type": "run_clear",
		"run_state": run_state.to_payload(),
		"combat_result": {"victory": true, "winnings": 36, "player_hp": 31},
		"last_encounter_payload": encounter_payload,
		"completed_node_count": 6
	})

	if active_scene != null:
		active_scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("asset identity playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_scene(name: String, scene_path: String, payload: Dictionary, is_battle: bool = false) -> void:
	print("show " + name)
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	var scene: PackedScene = load(scene_path)
	if scene == null:
		failures.append("could not load " + scene_path)
		return
	active_scene = scene.instantiate()
	if not is_battle and active_scene.has_method("configure"):
		active_scene.configure(payload)
	root.add_child(active_scene)
	if is_battle and active_scene.has_method("configure_encounter"):
		active_scene.configure_encounter(payload)
	await _settle(45)
	await _shot(name)

func _show_battle_result_feedback(name: String, payload: Dictionary) -> void:
	print("show " + name)
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	var scene: PackedScene = load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		failures.append("could not load battle scene")
		return
	active_scene = scene.instantiate()
	root.add_child(active_scene)
	if active_scene.has_method("configure_encounter"):
		active_scene.configure_encounter(payload)
	await _settle(18)
	active_scene.set("attack_base", 5)
	active_scene.set("placed_slots", _sample_slots())
	active_scene.set("pending_slot", "bust")
	active_scene.set("damage_multiplier", 1.0)
	active_scene.set("payout_multiplier", 1.0)
	active_scene.set("enemy_damage_delta", -3)
	active_scene.set("cash", 18)
	active_scene.set("player_hp", 31)
	active_scene.set("enemy_hp", 42)
	active_scene.set("enemy_max_hp", 42)
	active_scene.set("phase", "intervene")
	if active_scene.has_method("_resolve_pending"):
		active_scene._resolve_pending()
	await _settle(9)
	await _shot(name)

func _show_inline_battle_flow(payload: Dictionary) -> void:
	print("show inline battle table flow")
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame
	var scene: PackedScene = load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		failures.append("could not load battle scene")
		return
	active_scene = scene.instantiate()
	root.add_child(active_scene)
	if active_scene.has_method("configure_encounter"):
		active_scene.configure_encounter(payload)
	await _settle(30)
	if active_scene.has_method("_roll_dice"):
		active_scene._roll_dice()
	await _wait_for_dice_roll(active_scene, 180)
	await _settle(12)
	await _shot("02_table_dice_result_inline")
	if active_scene.has_method("_take_marbles"):
		active_scene._take_marbles()
	await _settle(12)
	if active_scene.has_method("_open_marble_throw_ritual"):
		active_scene._open_marble_throw_ritual()
	await _wait_for_marble_setup_ready(active_scene, 240)
	await _settle(12)
	await _shot("03_table_marble_slot_inline")
	if active_scene.has_method("_open_roulette_spin_ritual"):
		active_scene._open_roulette_spin_ritual()
	await _wait_for_battle_phase(active_scene, "intervene", 300)
	await _settle(12)
	await _shot("04_table_roulette_result_inline")

func _sample_slots() -> Dictionary:
	return {
		"safe": [],
		"profit": [],
		"jackpot": [],
		"bust": ["plain"],
		"overdrive": []
	}

func _shot_dir_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--shot-dir="):
			return arg.replace("--shot-dir=", "").replace("\\", "/")
	return ""

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_dice_roll(scene: Node, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(scene.get("dice_rolled")):
			return
		await process_frame

func _wait_for_marble_setup_ready(scene: Node, max_frames: int) -> void:
	for i in range(max_frames):
		if scene.has_method("_marble_setup_ready") and scene._marble_setup_ready():
			return
		await process_frame

func _wait_for_battle_phase(scene: Node, expected: String, max_frames: int) -> void:
	for i in range(max_frames):
		if str(scene.get("phase")) == expected:
			return
		await process_frame

func _shot(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run this playtest without --headless")
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
