extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var shot_dir := ""
var failures: Array[String] = []
var battle: Control

func _initialize() -> void:
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)
	battle = BattleScene.instantiate()
	root.add_child(battle)
	await _settle(8)
	battle.set("combat_core", "numeric_roulette")
	battle.set("dice_rolled", true)
	battle.set("dice_relics_applied", true)
	battle.set("dice", [4])
	battle.set("dice_locked", [false])
	battle.set("attack_base", 10)
	battle._take_marbles()
	await _settle(12)
	await _shot("01_marble_choice_phase")
	if str(battle.get("phase")) != "marble_choice":
		failures.append("battle did not enter marble choice phase")
	if (battle.get("revealed_marbles") as Array).is_empty():
		failures.append("no revealed marbles visible in choice phase")
	battle._choose_revealed_marble(0)
	await _settle(12)
	await _shot("02_selected_marble_spin_ready")
	if str(battle.get("phase")) != "wager":
		failures.append("selected marble did not advance to spin-ready phase")
	if (battle.get("selected_marble") as Dictionary).is_empty():
		failures.append("selected marble badge payload missing")
	battle.queue_free()
	await process_frame
	if failures.is_empty():
		print("numeric marble choice playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _settle(frames: int) -> void:
	for _i in range(frames):
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
	var err := image.save_png(path)
	if err != OK:
		failures.append("failed to save " + path + ": " + str(err))
	else:
		print("saved screenshot: " + path)
