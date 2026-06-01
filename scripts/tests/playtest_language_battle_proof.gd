extends SceneTree

const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var shot_dir := ""
var battle: Control
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

	battle = BattleScene.instantiate()
	root.add_child(battle)
	await _settle(10)
	await _shot("01_battle_start_en")

	battle._roll_dice()
	await _wait_for_dice_roll(180)
	await _settle(8)
	await _shot("02_battle_dice_en")

	if battle._requires_attack_die_choice() and int(battle.get("selected_attack_die_index")) < 0:
		battle._select_attack_die(0)
	else:
		battle._take_marbles()
	await _settle(20)
	await _shot("03_battle_marble_en")

	DemoSettingsService.update_value("language", "ko")
	if battle != null:
		battle.queue_free()
		await process_frame
	if failures.is_empty():
		print("language battle proof passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_dice_roll(max_frames: int) -> void:
	for i in range(max_frames):
		if battle != null and bool(battle.get("dice_rolled")):
			return
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
