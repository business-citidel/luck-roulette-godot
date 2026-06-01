extends SceneTree

const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")
const ShopScene := preload("res://scenes/run/shop_scene.tscn")

var shot_dir := ""
var active_scene: Control
var failures: Array[String] = []

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	DemoSettingsService.update_value("language", "en")

	await _show_reward("")
	await _shot("01_reward_en")
	await _show_reward("money")
	await _shot("02_reward_money_en")
	await _show_rest(false)
	await _shot("03_rest_front_en")
	await _show_rest_upgrade()
	await _shot("04_rest_upgrade_en")
	await _show_shop(48)
	await _shot("05_shop_en")
	active_scene._select_by_id("shop_prep")
	await _settle(8)
	await _shot("06_shop_prep_selected_en")

	DemoSettingsService.update_value("language", "ko")
	await _clear_active()
	if failures.is_empty():
		print("language reward rest shop proof passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_reward(choice_id: String) -> void:
	await _clear_active()
	active_scene = RewardScene.instantiate()
	active_scene.configure({
		"run_state": {"gold": 18, "player_hp": 32, "player_max_hp": 42, "relic_ids": []},
		"combat_result": {"winnings": 18}
	})
	root.add_child(active_scene)
	await _settle(8)
	if choice_id == "money":
		active_scene._choose_money()
		await _settle(8)

func _show_rest(submit: bool) -> void:
	await _clear_active()
	active_scene = RestScene.instantiate()
	active_scene.configure({
		"run_state": {"gold": 12, "player_hp": 30, "player_max_hp": 42, "relic_ids": ["loaded_die"], "run_upgrades": {}},
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(8)
	if submit:
		active_scene._prepare()
		await _settle(8)

func _show_rest_upgrade() -> void:
	await _show_rest(false)
	active_scene._choose_by_id("rest_tune")
	await _settle(8)

func _show_shop(gold: int) -> void:
	await _clear_active()
	active_scene = ShopScene.instantiate()
	active_scene.configure({
		"run_state": {"gold": gold, "player_hp": 36, "player_max_hp": 42, "relic_ids": [], "next_combat_mods": []},
		"map_result": {}
	})
	active_scene.completed.connect(func(_result: Dictionary) -> void: pass)
	root.add_child(active_scene)
	await _settle(8)

func _clear_active() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null
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
	await _settle(3)
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		failures.append("viewport texture unavailable for " + name)
		return
	var image: Image = viewport_texture.get_image()
	if image.is_empty():
		failures.append("empty screenshot image for " + name)
		return
	var path := shot_dir.path_join(name + ".png")
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)

