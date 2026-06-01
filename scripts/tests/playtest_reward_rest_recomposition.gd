extends SceneTree

const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const RestScene := preload("res://scenes/run/rest_scene.tscn")
const RunMapScene := preload("res://scenes/run/run_map_scene.tscn")

var shot_dir: String = ""
var failures: Array[String] = []
var active_scene: Control

func _initialize() -> void:
	print("reward/rest recomposition playtest start")
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _show_reward("")
	await _shot("reward_offer_cards_normal")
	await _show_reward("relic")
	await _shot("reward_pickup_relic_summary")
	await _show_reward("money")
	await _shot("reward_pickup_money_summary")
	await _show_reward("heal")
	await _shot("reward_pickup_heal_summary")
	await _show_rest(false)
	await _shot("rest_offer_cards_normal")
	await _show_rest(true)
	await _shot("rest_offer_cards_chosen_disabled")
	await _show_map_state()
	await _shot("map_run_table_trays")

	if active_scene != null:
		active_scene.queue_free()
		await process_frame

	if failures.is_empty():
		print("reward/rest recomposition playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _show_reward(choice_id: String) -> void:
	await _clear_active()
	active_scene = RewardScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 18,
			"player_hp": 32,
			"player_max_hp": 42,
			"relic_ids": []
		},
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

func _show_rest(submit: bool) -> void:
	await _clear_active()
	active_scene = RestScene.instantiate()
	active_scene.configure({
		"run_state": {
			"gold": 12,
			"player_hp": 30,
			"player_max_hp": 42,
			"relic_ids": ["loaded_die"]
		},
		"map_result": {}
	})
	root.add_child(active_scene)
	await _settle(6)
	if submit:
		active_scene._prepare()
		await _settle(6)

func _show_map_state() -> void:
	await _clear_active()
	active_scene = RunMapScene.instantiate()
	active_scene.configure({
		"gold": 48,
		"player_hp": 38,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die", "green_purse"],
		"next_combat_mods": [{"id": "rest_prepared_table", "enemy_damage_delta": -3}],
		"map_step": 2,
		"completed_nodes": ["n0", "n1"]
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
