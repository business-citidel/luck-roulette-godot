extends SceneTree

const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const RunStateScript := preload("res://scripts/resources/run_state.gd")
const EffectResolver := preload("res://scripts/systems/effect_resolver.gd")
const EncounterCatalog := preload("res://scripts/systems/encounter_catalog.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	print("001e/001f continuity playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_shop("")
	await _shot("00_shop_relic_offer_clickable")
	await _show_shop("select_relic")
	await _shot("01_shop_relic_selected_preview")
	await _show_shop("buy_relic")
	await _shot("02_shop_relic_purchased_owned_receipt")
	await _show_shop("buy_prep")
	await _shot("03_shop_prep_purchased_queued_note")
	await _show_map_with_inventory()
	await _shot("04_map_with_relic_tray_and_prep_note")
	await _show_battle_entry_with_receipts()
	await _shot("05_next_combat_entry_relics_and_start_mods")
	await _show_map_after_prep_consumed()
	await _shot("06_map_after_next_combat_prep_consumed")

	await _clear_active()
	if failures.is_empty():
		print("001e/001f continuity playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_shop(mode: String) -> void:
	await _clear_active()
	active_scene = ShopScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 48,
			"player_hp": 36,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"],
			"next_combat_mods": []
		},
		"map_result": {}
	})
	active_scene.completed.connect(func(_result: Dictionary) -> void: pass)
	root.add_child(active_scene)
	await _settle(6)
	match mode:
		"select_relic":
			active_scene._select_purchase(active_scene._relic_result())
		"buy_relic":
			active_scene._buy_relic()
		"buy_prep":
			active_scene._buy_prep()
	if mode != "":
		await _settle(6)
	if mode == "select_relic" and str(active_scene.get("selected_choice")) != "shop_relic":
		failures.append("shop relic preview selected wrong choice")

func _show_map_with_inventory() -> void:
	await _clear_active()
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"gold": 18,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die", "green_purse"],
		"next_combat_mods": [{"id": "shop_soft_prep", "enemy_damage_delta": -2}],
		"map_step": 4,
		"completed_nodes": ["n0", "n1", "n2", "n3"]
	})
	root.add_child(active_scene)
	await _settle(6)

func _show_battle_entry_with_receipts() -> void:
	await _clear_active()
	var run_state = RunStateScript.new()
	run_state.gold = 18
	run_state.player_hp = 36
	run_state.player_max_hp = 42
	run_state.relic_ids.append("loaded_die")
	run_state.relic_ids.append("green_purse")
	run_state.next_combat_mods.append({"id": "shop_soft_prep", "enemy_damage_delta": -2})
	var payload: Dictionary = EffectResolver.build_encounter_payload(run_state, EncounterCatalog.get_encounter("crook_table"))
	active_scene = BattleScene.instantiate()
	root.add_child(active_scene)
	await _settle(2)
	active_scene.configure_encounter(payload)
	await _settle(12)

func _show_map_after_prep_consumed() -> void:
	await _clear_active()
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"gold": 18,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die", "green_purse"],
		"next_combat_mods": [],
		"map_step": 4,
		"completed_nodes": ["n0", "n1", "n2", "n3"]
	})
	root.add_child(active_scene)
	await _settle(6)

func _clear_active() -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null
		await process_frame

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

func _shot(name: String) -> void:
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name + "; run without --headless")
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
