extends SceneTree

const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const ShopScene := preload("res://scenes/run/shop_scene.tscn")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	print("relic icon batch proof playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	_assert_icon_batch_loads()
	await _show_reward_with_distinct_icons()
	await _click_at(Vector2(654, 404))
	await _shot("relic_icons_01_reward_offer_and_tray_detail")
	await _show_shop_with_distinct_offer()
	active_scene._select_purchase(active_scene._relic_result())
	await _settle(4)
	await _shot("relic_icons_02_shop_offer_detail")
	await _show_map_with_all_relics()
	await _click_at(Vector2(134, 216))
	await _shot("relic_icons_03_map_tray_detail")
	await _show_battle_with_all_relics()
	await _click_at(Vector2(118, 126))
	await _shot("relic_icons_04_battle_hud_detail")

	await _clear_active()
	if failures.is_empty():
		print("relic icon batch proof playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert_icon_batch_loads() -> void:
	for relic_id in RelicCatalog.all_ids():
		var icon := AssetCatalog.relic_icon(RelicCatalog.icon_id(relic_id))
		if icon == null:
			failures.append("missing relic icon for " + relic_id)

func _show_reward_with_distinct_icons() -> void:
	await _clear_active()
	active_scene = RewardScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 32,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die", "green_purse", "yellow_guard"]
		},
		"combat_result": {
			"winnings": 18
		}
	})
	root.add_child(active_scene)
	await _settle(8)

func _show_shop_with_distinct_offer() -> void:
	await _clear_active()
	active_scene = ShopScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 48,
			"player_hp": 34,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die", "green_purse", "yellow_guard"]
		},
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(8)

func _show_map_with_all_relics() -> void:
	await _clear_active()
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"gold": 54,
		"player_hp": 38,
		"player_max_hp": 42,
		"relic_ids": RelicCatalog.all_ids(),
		"next_combat_mods": [{"id": "shop_soft_prep", "enemy_damage_delta": -2}],
		"map_step": 4,
		"completed_nodes": ["n0", "n1", "n2", "n3"]
	})
	root.add_child(active_scene)
	await _settle(8)

func _show_battle_with_all_relics() -> void:
	await _clear_active()
	active_scene = BattleScene.instantiate()
	root.add_child(active_scene)
	await _settle(2)
	active_scene.configure_encounter({
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

func _click_at(pos: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	release.global_position = pos
	root.push_input(release, true)
	await _settle(4)

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
