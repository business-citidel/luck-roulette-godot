extends Control

signal overlay_proceed_received

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const RunDirectorScript := preload("res://scripts/systems/run_director.gd")
const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")
const ShellPauseOverlay := preload("res://scripts/ui/shell_pause_overlay.gd")
const DemoSaveService := preload("res://scripts/systems/demo_save_service.gd")
const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const CollectionProgressService := preload("res://scripts/systems/collection_progress_service.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")
const TitleScene := preload("res://scenes/run/title_scene.tscn")
const SettingsScene := preload("res://scenes/run/settings_scene.tscn")
const GalleryScene := preload("res://scenes/run/gallery_scene.tscn")
const CharacterSelectScene := preload("res://scenes/run/character_select_scene.tscn")
const RunIntroScene := preload("res://scenes/run/run_intro_scene.tscn")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")
const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const EventScene := preload("res://scenes/run/event_scene.tscn")
const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")
const RunEndScene := preload("res://scenes/run/run_end_scene.tscn")
const CombatScene := preload("res://scenes/battle/battle_scene.tscn")

const BG := Color("#05070d")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const RED := Color("#ee5b5b")
const GOLD := Color("#f2be4b")
const DEFAULT_MAP_VARIANT := "scroll_20_random"
const MAX_FLOOR := 3

var run_state: Resource
var run_director: Node
var overlay_canvas: CanvasLayer
var run_overlay: Control
var shell_canvas: CanvasLayer
var pause_overlay: ShellPauseOverlay
var active_combat: Control
var phase: String = "boot"
var last_combat_result: Dictionary = {}
var last_reward_result: Dictionary = {}
var last_encounter_payload: Dictionary = {}
var run_stats: Dictionary = {}
var stage_proceed_pending := false

func _ready() -> void:
	DemoSettingsService.apply_settings(DemoSettingsService.load_settings())
	_reset_run_state()
	run_director = RunDirectorScript.new()
	run_director.name = "RunDirector"
	add_child(run_director)
	_install_overlay()
	_install_shell_overlay()
	call_deferred("_open_title")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return
	if pause_overlay != null and pause_overlay.visible:
		_close_pause_overlay()
		get_viewport().set_input_as_handled()
	elif _can_pause_current_phase():
		_open_pause_overlay()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	if phase == "boot":
		_draw_text("Luck Roulette Run Shell", Vector2(72, 96), 34, TEXT)
		_draw_text("loading title", Vector2(74, 136), 18, MUTED)
	elif phase == "run_failed":
		_draw_text("RUN FAILED", Vector2(430, 250), 52, RED)
		_draw_text("HP reached 0. Gold and battle winnings cannot keep the run alive.", Vector2(344, 304), 20, TEXT)
		_draw_text("Final gold " + str(run_state.gold), Vector2(530, 350), 22, GOLD)

func _reset_run_state() -> void:
	run_state = RunStateScript.new()
	run_state.seed_text = "run-shell-2026-05-10"
	run_state.gold = 0
	run_state.character_id = CharacterContractCatalog.default_character_id()
	run_state.player_max_hp = CharacterContractCatalog.starting_max_hp(str(run_state.character_id))
	run_state.player_hp = int(run_state.player_max_hp)
	run_state.floor_index = 1
	run_state.max_floor = MAX_FLOOR
	run_state.map_variant = DEFAULT_MAP_VARIANT
	run_state.map_theme_id = _map_theme_for_floor(run_state.floor_index)
	run_state.map_step = 0
	run_state.completed_nodes.clear()
	if run_state.has_method("reset_starting_marbles"):
		run_state.reset_starting_marbles()
	_reset_run_stats()

func _reset_run_stats() -> void:
	run_stats = {
		"battles_won": 0,
		"elites_defeated": 0,
		"bosses_defeated": 0,
		"events_resolved": 0,
		"shops_visited": 0,
		"rests_used": 0,
		"rewards_claimed": 0,
		"gold_earned": 0,
		"floor_reached": int(run_state.floor_index),
		"character_id": str(run_state.character_id),
		"seed_text": str(run_state.seed_text)
	}

func _open_title(use_transition: bool = false) -> void:
	phase = "title"
	_sync_overlay()
	queue_redraw()
	if use_transition:
		await run_director.transition_service.cover(0.24)
	var scene: Node = await run_director.mount_scene("title", TitleScene, {
		"seed_text": run_state.seed_text,
		"has_continue": DemoSaveService.has_save()
	})
	if use_transition:
		await run_director.transition_service.uncover(0.24)
	var result: Dictionary = {"accepted": true, "action": "start_run"} if bool(scene.get("started")) else await scene.completed
	var action := str(result.get("action", ""))
	if action == "start_run":
		await _start_new_run()
	elif action == "continue_run":
		await _continue_saved_run()
	elif action == "open_settings":
		await _open_title_settings()
	elif action == "open_gallery":
		await _open_title_gallery()
	elif action == "quit_game":
		get_tree().quit()

func _start_new_run() -> void:
	_reset_run_state()
	await _open_character_select()
	_save_map_boundary()
	await _open_map()

func _continue_saved_run() -> void:
	var run_payload := DemoSaveService.load_run_state_payload()
	if run_payload.is_empty():
		await _open_title(true)
		return
	run_state.apply_payload(run_payload)
	if (run_state.get("marble_deck") as Array).is_empty() and run_state.has_method("reset_starting_marbles"):
		run_state.reset_starting_marbles()
	run_stats = DemoSaveService.load_run_stats()
	_normalize_run_stats()
	await _open_map()

func _open_title_settings() -> void:
	phase = "settings"
	_sync_overlay()
	var scene: Node = await run_director.mount_scene("settings", SettingsScene, {"context": "title"})
	await scene.completed
	await _open_title(true)

func _open_pause_settings() -> void:
	if pause_overlay == null:
		return
	pause_overlay.hide()
	var scene := SettingsScene.instantiate()
	scene.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.configure({"context": "pause"})
	shell_canvas.add_child(scene)
	await scene.completed
	scene.queue_free()
	await get_tree().process_frame
	if _can_pause_current_phase():
		pause_overlay.open_for_phase(phase)

func _open_title_gallery() -> void:
	phase = "gallery"
	_sync_overlay()
	var scene: Node = await run_director.mount_scene("gallery", GalleryScene, {"context": "title"})
	await scene.completed
	await _open_title(true)

func _open_character_select() -> void:
	phase = "character_select"
	_sync_overlay()
	queue_redraw()
	await run_director.transition_service.cover(0.24)
	var scene: Node = await run_director.mount_scene("character_select", CharacterSelectScene, run_state.to_payload())
	await run_director.transition_service.uncover(0.24)
	var result: Dictionary = {"accepted": true, "action": "character_selected", "character_id": run_state.character_id} if bool(scene.get("selected")) else await scene.completed
	if bool(result.get("accepted", false)):
		run_state.character_id = str(result.get("character_id", CharacterContractCatalog.default_character_id()))
		CollectionProgressService.discover_character(str(run_state.character_id))
		_apply_character_starting_relics()
		_record_collection_from_relic_ids(run_state.relic_ids)
	await run_director.transition_service.cover(0.18)
	await run_director.clear_active_scene()
	await run_director.transition_service.uncover(0.18)

func _open_run_intro() -> void:
	phase = "intro"
	_sync_overlay()
	await run_director.transition_service.cover(0.24)
	var scene: Node = await run_director.mount_scene("intro", RunIntroScene, run_state.to_payload())
	await run_director.transition_service.uncover(0.24)
	var result: Dictionary = {"accepted": true, "action": "intro_complete"} if bool(scene.get("finished")) else await scene.completed
	if bool(result.get("accepted", false)):
		await run_director.transition_service.cover(0.18)
		await run_director.clear_active_scene()
		await run_director.transition_service.uncover(0.18)

func _open_map() -> void:
	phase = "map"
	_sync_overlay()
	queue_redraw()
	var result: Dictionary = await run_director.show_scene("map", RunMapScene, run_state.to_payload())
	if not bool(result.get("accepted", false)):
		return
	var node_type: String = str(result.get("node_type", "combat"))
	if node_type == "combat" or node_type == "elite" or node_type == "boss":
		await _open_combat(result)
	elif node_type == "event":
		await _open_event(result)
	elif node_type == "shop":
		await _open_shop(result)
	elif node_type == "rest":
		await _open_rest(result)
	else:
		await _complete_placeholder_node(result)

func _open_combat(map_result: Dictionary) -> void:
	phase = "combat"
	_sync_overlay()
	var encounter_result: Dictionary = EncounterCatalog.resolve_node(map_result)
	await run_director.transition_service.cover(0.22)
	active_combat = CombatScene.instantiate() as Control
	add_child(active_combat)
	_connect_active_combat_overlay()
	await get_tree().process_frame
	if active_combat.has_method("configure_encounter"):
		last_encounter_payload = EffectResolver.build_encounter_payload(run_state, encounter_result)
		CollectionProgressService.discover_monster(str(last_encounter_payload.get("monster_id", "")))
		active_combat.configure_encounter(last_encounter_payload)
	await run_director.transition_service.uncover(0.22)
	last_combat_result = await active_combat.combat_finished
	run_state.player_hp = int(last_combat_result.get("player_hp", run_state.player_hp))
	if int(last_combat_result.get("gold_delta", 0)) != 0:
		run_state.gold = max(0, run_state.gold + int(last_combat_result.get("gold_delta", 0)))
	run_state.apply_reward({
		"remove_potion_ids": last_combat_result.get("remove_potion_ids", [])
	})
	_sync_overlay()
	await run_director.transition_service.cover(0.2)
	active_combat.queue_free()
	active_combat = null
	await get_tree().process_frame
	await run_director.transition_service.uncover(0.2)
	if int(run_state.player_hp) <= 0 or bool(last_combat_result.get("defeat", false)):
		_open_run_failed(last_combat_result)
	elif bool(last_combat_result.get("victory", false)):
		if str(last_encounter_payload.get("on_victory", "")) == "run_clear" or bool(last_encounter_payload.get("is_final", false)):
			_record_completed_node(encounter_result)
			_mark_node_completed(encounter_result)
			if run_state.relic_ids.has("tiny_mascot"):
				run_state.gold = max(0, int(run_state.gold) + 8)
				last_combat_result["gold_delta"] = int(last_combat_result.get("gold_delta", 0)) + 8
			if _is_final_floor():
				_open_run_clear(last_combat_result)
			else:
				await _advance_to_next_floor()
		else:
			await _open_reward(encounter_result, last_combat_result)
	else:
		await _return_to_map_after_node(encounter_result)

func _open_run_failed(result: Dictionary = {}) -> void:
	phase = "run_failed"
	DemoSaveService.clear_save()
	_sync_overlay()
	last_combat_result = result.duplicate(true)
	active_combat = null
	_mount_run_end("run_failed", result)
	queue_redraw()

func _open_run_clear(result: Dictionary = {}) -> void:
	phase = "run_clear"
	DemoSaveService.clear_save()
	_sync_overlay()
	last_combat_result = result.duplicate(true)
	active_combat = null
	_mount_run_end("run_clear", result)
	queue_redraw()

func _mount_run_end(result_type: String, result: Dictionary) -> void:
	if run_director == null:
		return
	var end_scene: Node = run_director.show_terminal_scene(result_type, RunEndScene, {
		"result_type": result_type,
		"run_state": run_state.to_payload(),
		"combat_result": result,
		"last_encounter_payload": last_encounter_payload,
		"completed_node_count": (run_state.completed_nodes as Array).size(),
		"run_stats": run_stats.duplicate(true)
	})
	if end_scene.has_signal("completed"):
		end_scene.completed.connect(_on_run_end_completed)

func _on_run_end_completed(result: Dictionary) -> void:
	var action: String = str(result.get("action", ""))
	if action == "restart_run":
		await _start_new_run()
	elif action == "main_menu":
		await _open_title(true)

func _open_reward(map_result: Dictionary, combat_result: Dictionary) -> void:
	phase = "reward"
	stage_proceed_pending = false
	_sync_overlay()
	var reward_scene: Node = await run_director.mount_scene("reward", RewardScene, {
		"run_state": run_state.to_payload(),
		"combat_result": combat_result
	})
	last_reward_result = await reward_scene.completed
	if bool(last_reward_result.get("accepted", false)):
		EffectResolver.apply_reward_result(run_state, last_reward_result)
		_record_collection_from_reward_result(last_reward_result)
		_record_reward_result(last_reward_result)
		_sync_overlay()
		await _settle_reward_pickup()
		await _wait_for_stage_proceed()
	await _return_to_map_after_node(map_result)

func _open_event(map_result: Dictionary) -> void:
	phase = "event"
	stage_proceed_pending = false
	_sync_overlay()
	var event_scene: Node = await run_director.mount_scene("event", EventScene, {
		"run_state": run_state.to_payload(),
		"map_result": map_result
	})
	var event_id := str(event_scene.get("active_event_id"))
	CollectionProgressService.discover_event(event_id)
	last_reward_result = await event_scene.completed
	if bool(last_reward_result.get("accepted", false)):
		EffectResolver.apply_reward_result(run_state, last_reward_result)
		CollectionProgressService.record_event_result(event_id, last_reward_result)
		_record_collection_from_reward_result(last_reward_result)
		_sync_overlay()
		await _settle_reward_pickup()
		await _wait_for_stage_proceed()
	await _return_to_map_after_node(map_result)

func _open_shop(map_result: Dictionary) -> void:
	phase = "shop"
	stage_proceed_pending = false
	_sync_overlay()
	var shop_scene: Node = await run_director.mount_scene("shop", ShopScene, {
		"run_state": run_state.to_payload(),
		"map_result": map_result
	})
	last_reward_result = await shop_scene.completed
	if bool(last_reward_result.get("accepted", false)):
		EffectResolver.apply_reward_result(run_state, last_reward_result)
		_record_collection_from_reward_result(last_reward_result)
		_sync_overlay()
		await _settle_reward_pickup()
		if str(last_reward_result.get("choice", "")) != "shop_leave":
			await _wait_for_stage_proceed()
	await _return_to_map_after_node(map_result)

func _open_rest(map_result: Dictionary) -> void:
	phase = "rest"
	stage_proceed_pending = false
	_sync_overlay()
	var rest_scene: Node = await run_director.mount_scene("rest", RestScene, {
		"run_state": run_state.to_payload(),
		"map_result": map_result
	})
	last_reward_result = await rest_scene.completed
	if bool(last_reward_result.get("accepted", false)):
		EffectResolver.apply_reward_result(run_state, last_reward_result)
		_record_collection_from_reward_result(last_reward_result)
		_sync_overlay()
		await _settle_reward_pickup()
		await _wait_for_stage_proceed()
	await _return_to_map_after_node(map_result)

func _complete_placeholder_node(map_result: Dictionary) -> void:
	last_reward_result = {
		"accepted": true,
		"choice": "placeholder",
		"gold_delta": 0,
		"hp_delta": 0,
		"relic_ids": [],
		"next_combat_mods": []
	}
	await _return_to_map_after_node(map_result)

func _settle_reward_pickup() -> void:
	for i in range(10):
		await get_tree().process_frame

func _wait_for_stage_proceed() -> void:
	stage_proceed_pending = true
	_sync_overlay()
	await overlay_proceed_received
	stage_proceed_pending = false
	_sync_overlay()

func _install_overlay() -> void:
	overlay_canvas = CanvasLayer.new()
	overlay_canvas.name = "RunPersistentOverlayCanvas"
	overlay_canvas.layer = 80
	add_child(overlay_canvas)
	run_overlay = RunPersistentOverlay.new()
	run_overlay.name = "RunPersistentOverlay"
	run_overlay.visible = false
	run_overlay.proceed_requested.connect(_on_overlay_proceed_requested)
	overlay_canvas.add_child(run_overlay)

func _install_shell_overlay() -> void:
	shell_canvas = CanvasLayer.new()
	shell_canvas.name = "ShellOverlayCanvas"
	shell_canvas.layer = 120
	shell_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shell_canvas)
	pause_overlay = ShellPauseOverlay.new()
	pause_overlay.name = "ShellPauseOverlay"
	pause_overlay.action_requested.connect(_on_pause_action_requested)
	shell_canvas.add_child(pause_overlay)

func _can_pause_current_phase() -> bool:
	return ["map", "combat", "reward", "event", "shop", "rest"].has(phase)

func _open_pause_overlay() -> void:
	if pause_overlay == null or not _can_pause_current_phase():
		return
	get_tree().paused = true
	pause_overlay.open_for_phase(phase)

func _close_pause_overlay() -> void:
	if pause_overlay != null:
		pause_overlay.close()
	get_tree().paused = false

func _on_pause_action_requested(action: String) -> void:
	if action == "resume":
		_close_pause_overlay()
	elif action == "settings":
		await _open_pause_settings()
	elif action == "main_menu":
		_close_pause_overlay()
		_save_map_boundary()
		_open_title.call_deferred(true)
	elif action == "abandon_run":
		_close_pause_overlay()
		DemoSaveService.clear_save()
		_reset_run_state()
		_open_title.call_deferred(true)

func _sync_overlay() -> void:
	if run_overlay == null or run_state == null:
		return
	var play_phase := _overlay_play_phases().has(phase)
	run_overlay.visible = play_phase
	if not play_phase:
		return
	var proceed_visible := false
	var proceed_enabled := false
	if phase == "shop":
		proceed_visible = true
		proceed_enabled = true
	elif stage_proceed_pending and (phase == "reward" or phase == "event" or phase == "rest"):
		proceed_visible = true
		proceed_enabled = true
	run_overlay.configure(_overlay_payload(), phase, proceed_visible, proceed_enabled, UiText.t("overlay.exit"))

func _overlay_payload(combat_payload: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = run_state.to_payload()
	if phase == "combat":
		if active_combat != null:
			payload["player_hp"] = int(active_combat.get("player_hp"))
			payload["player_max_hp"] = int(active_combat.get("player_max_hp"))
			payload["relic_ids"] = (active_combat.get("active_relic_ids") as Array).duplicate()
		for key in combat_payload.keys():
			payload[key] = combat_payload[key]
	return payload

func _connect_active_combat_overlay() -> void:
	if active_combat == null:
		return
	var callback := Callable(self, "_on_combat_overlay_changed")
	if active_combat.has_signal("combat_overlay_changed") and not active_combat.is_connected("combat_overlay_changed", callback):
		active_combat.connect("combat_overlay_changed", callback)

func _on_combat_overlay_changed(combat_payload: Dictionary) -> void:
	if phase != "combat" or run_overlay == null or not run_overlay.visible:
		return
	run_overlay.configure(_overlay_payload(combat_payload), phase, false, false, UiText.t("overlay.exit"))
	var triggered_ids: Array = combat_payload.get("triggered_relic_ids", [])
	if not triggered_ids.is_empty() and run_overlay.has_method("pulse_relics"):
		run_overlay.pulse_relics(triggered_ids)

func _overlay_play_phases() -> Array[String]:
	return ["map", "combat", "reward", "event", "shop", "rest"]

func _on_overlay_proceed_requested() -> void:
	if stage_proceed_pending and (phase == "reward" or phase == "event" or phase == "shop" or phase == "rest"):
		overlay_proceed_received.emit()
		return
	if run_director == null or run_director.active_scene == null:
		return
	if phase == "shop" and run_director.active_scene.has_method("_leave"):
		run_director.active_scene._leave()

func _return_to_map_after_node(map_result: Dictionary) -> void:
	_record_completed_node(map_result)
	_mark_node_completed(map_result)
	run_state.map_step = min(run_state.map_step + 1, _current_final_step())
	_save_map_boundary()
	await _open_map()

func _advance_to_next_floor() -> void:
	_reset_next_floor_state()
	_sync_overlay()
	_save_map_boundary()
	await _open_map()

func _save_map_boundary() -> void:
	_normalize_run_stats()
	DemoSaveService.save_run(run_state, run_stats)

func _normalize_run_stats() -> void:
	var defaults := {
		"battles_won": 0,
		"elites_defeated": 0,
		"bosses_defeated": 0,
		"events_resolved": 0,
		"shops_visited": 0,
		"rests_used": 0,
		"rewards_claimed": 0,
		"gold_earned": 0,
		"floor_reached": int(run_state.floor_index),
		"character_id": str(run_state.character_id),
		"seed_text": str(run_state.seed_text)
	}
	for key in defaults.keys():
		if not run_stats.has(key):
			run_stats[key] = defaults[key]
	run_stats["floor_reached"] = max(int(run_stats.get("floor_reached", 1)), int(run_state.floor_index))
	run_stats["character_id"] = str(run_state.character_id)
	run_stats["seed_text"] = str(run_state.seed_text)

func _record_completed_node(map_result: Dictionary) -> void:
	var node_type := str(map_result.get("node_type", map_result.get("type", "")))
	if node_type == "combat":
		run_stats["battles_won"] = int(run_stats.get("battles_won", 0)) + 1
	elif node_type == "elite":
		run_stats["battles_won"] = int(run_stats.get("battles_won", 0)) + 1
		run_stats["elites_defeated"] = int(run_stats.get("elites_defeated", 0)) + 1
	elif node_type == "boss":
		run_stats["battles_won"] = int(run_stats.get("battles_won", 0)) + 1
		run_stats["bosses_defeated"] = int(run_stats.get("bosses_defeated", 0)) + 1
	elif node_type == "event":
		run_stats["events_resolved"] = int(run_stats.get("events_resolved", 0)) + 1
	elif node_type == "shop":
		run_stats["shops_visited"] = int(run_stats.get("shops_visited", 0)) + 1
	elif node_type == "rest":
		run_stats["rests_used"] = int(run_stats.get("rests_used", 0)) + 1
	_normalize_run_stats()

func _record_reward_result(result: Dictionary) -> void:
	run_stats["rewards_claimed"] = int(run_stats.get("rewards_claimed", 0)) + 1
	run_stats["gold_earned"] = int(run_stats.get("gold_earned", 0)) + max(0, int(result.get("gold_delta", 0)))
	_normalize_run_stats()

func _record_collection_from_reward_result(result: Dictionary) -> void:
	_record_collection_from_relic_ids(result.get("relic_ids", []))

func _record_collection_from_relic_ids(value: Variant) -> void:
	if not (value is Array):
		return
	for relic_id in value:
		CollectionProgressService.discover_relic(str(relic_id))

func _apply_character_starting_relics() -> void:
	for relic_id in CharacterContractCatalog.all_starting_relic_ids():
		run_state.relic_ids.erase(relic_id)
	run_state.player_max_hp = CharacterContractCatalog.starting_max_hp(str(run_state.character_id))
	run_state.player_hp = int(run_state.player_max_hp)
	for relic_id in CharacterContractCatalog.starting_relic_ids(str(run_state.character_id)):
		if not run_state.relic_ids.has(relic_id):
			run_state.relic_ids.append(relic_id)

func _reset_next_floor_state() -> void:
	run_state.floor_index = min(run_state.floor_index + 1, run_state.max_floor)
	run_state.player_hp = int(run_state.player_max_hp)
	run_state.map_step = 0
	run_state.completed_nodes.clear()
	run_state.map_theme_id = _map_theme_for_floor(run_state.floor_index)

func _current_final_step() -> int:
	return EncounterCatalog.final_step(str(run_state.map_variant), _floor_seed_text())

func _floor_seed_text() -> String:
	return str(run_state.seed_text) + ":floor:" + str(int(run_state.floor_index))

func _is_final_floor() -> bool:
	return int(run_state.floor_index) >= int(run_state.max_floor)

func _map_theme_for_floor(floor: int) -> String:
	if floor <= 1:
		return "01_base"
	if floor == 2:
		return "02_enemy_power"
	return "04_max_hp_pressure"

func _mark_node_completed(map_result: Dictionary) -> void:
	var node_id: String = str(map_result.get("node_id", ""))
	if node_id != "" and not run_state.completed_nodes.has(node_id):
		run_state.completed_nodes.append(node_id)

func _test_select_current_map_node() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_select_current_node"):
		run_director.active_scene._select_current_node()

func _test_start_run() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_start_run"):
		run_director.active_scene._start_run()

func _test_skip_intro() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_finish_intro"):
		run_director.active_scene._finish_intro()

func _test_select_default_character() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_select_default_character"):
		run_director.active_scene._select_default_character()

func _test_restart_from_run_end() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_restart_run"):
		run_director.active_scene._restart_run()

func _test_return_to_title_from_run_end() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_return_to_title"):
		run_director.active_scene._return_to_title()

func _test_open_pause() -> void:
	if pause_overlay != null and _can_pause_current_phase():
		pause_overlay.open_for_phase(phase)

func _test_pause_action(action: String) -> void:
	await _on_pause_action_requested(action)

func _test_select_current_map_node_type(node_type: String) -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_select_current_node_of_type"):
		run_director.active_scene._select_current_node_of_type(node_type)

func _test_jump_to_first_map_node_type(node_type: String, start_step: int = 0) -> void:
	var nodes := EncounterCatalog.map_nodes(str(run_state.map_variant), _floor_seed_text())
	var target_step := -1
	for node in nodes:
		if str(node.get("node_type", "")) == node_type and int(node.get("node_index", -1)) >= start_step:
			target_step = int(node.get("node_index", -1))
			break
	if target_step < 0:
		return
	run_state.map_step = target_step
	run_state.completed_nodes = _test_completed_prefix_for_step(target_step)
	phase = "map"
	_sync_overlay()
	run_director.show_terminal_scene("map", RunMapScene, run_state.to_payload())

func _test_route_current_map_node_type_direct(node_type: String) -> void:
	var node := _test_current_node_of_type(node_type)
	if node.is_empty():
		return
	if node_type == "combat" or node_type == "elite" or node_type == "boss":
		_open_combat(node)
	elif node_type == "event":
		_open_event(node)
	elif node_type == "shop":
		_open_shop(node)
	elif node_type == "rest":
		_open_rest(node)

func _test_available_map_node_types() -> Array[String]:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_available_node_types"):
		return run_director.active_scene._available_node_types()
	return []

func _test_current_node_of_type(node_type: String) -> Dictionary:
	var current_step := int(run_state.map_step)
	for node in EncounterCatalog.map_nodes(str(run_state.map_variant), _floor_seed_text()):
		if int(node.get("node_index", -1)) == current_step and str(node.get("node_type", "")) == node_type:
			return (node as Dictionary).duplicate(true)
	return {}

func _test_completed_prefix_for_step(step: int) -> Array[String]:
	var result: Array[String] = []
	for route_step in range(step):
		for node in EncounterCatalog.map_nodes(str(run_state.map_variant), _floor_seed_text()):
			if int(node.get("node_index", -1)) == route_step:
				result.append(str(node.get("node_id", "")))
				break
	return result

func _test_choose_default_reward() -> void:
	if run_director != null and run_director.active_scene != null and run_director.active_scene.has_method("_choose_default"):
		var scene: Node = run_director.active_scene
		scene._choose_default()
		if phase == "shop" and scene.has_method("_leave"):
			scene._leave()
			return
		_test_request_overlay_proceed_after_settle()

func _test_choose_default_scene() -> void:
	_test_choose_default_reward()

func _test_request_overlay_proceed_after_settle() -> void:
	var starting_phase := phase
	for i in range(90):
		await get_tree().process_frame
		if stage_proceed_pending:
			_on_overlay_proceed_requested()
			return
		if phase != starting_phase and not stage_proceed_pending:
			return

func _test_force_run_failed() -> void:
	run_state.player_hp = 0
	_open_run_failed({"defeat": true, "player_hp": 0})

func _test_force_run_clear() -> void:
	last_encounter_payload = EncounterCatalog.get_encounter("final_house_table")
	_open_run_clear({"victory": true, "player_hp": run_state.player_hp, "winnings": 34})

func _test_show_map_at_step(step: int) -> void:
	if active_combat != null:
		active_combat.queue_free()
		active_combat = null
	run_state.map_step = step
	phase = "map"
	_sync_overlay()
	run_director.show_terminal_scene("map", RunMapScene, run_state.to_payload())

func _test_mount_combat_encounter(encounter_id: String) -> void:
	if run_director != null and run_director.active_scene != null:
		run_director.active_scene.queue_free()
		run_director.active_scene = null
	if active_combat != null:
		active_combat.queue_free()
	active_combat = CombatScene.instantiate() as Control
	add_child(active_combat)
	_connect_active_combat_overlay()
	await get_tree().process_frame
	last_encounter_payload = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter(encounter_id))
	CollectionProgressService.discover_monster(str(last_encounter_payload.get("monster_id", "")))
	active_combat.configure_encounter(last_encounter_payload)
	phase = "combat"
	_sync_overlay()

func _test_finish_active_combat_victory(reason: String = "test") -> void:
	for i in range(90):
		if active_combat != null and phase == "combat":
			break
		await get_tree().process_frame
	var payload: Dictionary = last_encounter_payload.duplicate(true)
	var combat_result := {
		"accepted": true,
		"reason": reason,
		"victory": true,
		"defeat": false,
		"cash": int(payload.get("combat_cash", 18)),
		"combat_cash": int(payload.get("combat_cash", 18)),
		"winnings": int(payload.get("combat_cash", 18)),
		"player_hp": int(payload.get("player_hp", run_state.player_hp)),
		"enemy_hp": 0,
		"relic_ids": payload.get("relic_ids", []),
		"encounter_id": str(payload.get("encounter_id", "")),
		"monster_id": str(payload.get("monster_id", "")),
		"is_final": bool(payload.get("is_final", false)),
		"on_victory": str(payload.get("on_victory", "reward"))
	}
	last_combat_result = combat_result.duplicate(true)
	run_state.player_hp = int(combat_result.get("player_hp", run_state.player_hp))
	if int(combat_result.get("gold_delta", 0)) != 0:
		run_state.gold = max(0, run_state.gold + int(combat_result.get("gold_delta", 0)))
	if active_combat != null:
		active_combat.queue_free()
		active_combat = null
	await get_tree().process_frame
	if bool(payload.get("is_final", false)) or str(payload.get("on_victory", "")) == "run_clear":
		_record_completed_node(payload)
		_mark_node_completed(payload)
		if _is_final_floor():
			_open_run_clear(combat_result)
		else:
			_reset_next_floor_state()
			phase = "map"
			_sync_overlay()
			run_director.show_terminal_scene("map", RunMapScene, run_state.to_payload())
	else:
		phase = "reward"
		_sync_overlay()
		run_director.show_terminal_scene("reward", RewardScene, {
			"run_state": run_state.to_payload(),
			"combat_result": combat_result
		})

func _test_accept_reward_direct() -> void:
	if phase != "reward":
		return
	var reward_scene: Node = run_director.active_scene
	if reward_scene != null and reward_scene.get("reward_result") is Dictionary:
		last_reward_result = (reward_scene.get("reward_result") as Dictionary).duplicate(true)
	else:
		last_reward_result = {
			"accepted": true,
			"choice": "combat_reward",
			"gold_delta": int(last_combat_result.get("winnings", last_combat_result.get("combat_cash", last_combat_result.get("cash", 0)))),
			"contract_tickets_delta": 1,
			"hp_delta": 0,
			"relic_ids": [],
			"next_combat_mods": []
		}
	EffectResolver.apply_reward_result(run_state, last_reward_result)
	_record_collection_from_reward_result(last_reward_result)
	_record_reward_result(last_reward_result)
	_record_completed_node(last_encounter_payload)
	_mark_node_completed(last_encounter_payload)
	run_state.map_step = min(run_state.map_step + 1, _current_final_step())
	phase = "map"
	_sync_overlay()
	run_director.show_terminal_scene("map", RunMapScene, run_state.to_payload())

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
