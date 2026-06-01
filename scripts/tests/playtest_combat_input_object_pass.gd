extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const LegacySlotPlaytestGuard := preload("res://scripts/tests/support/legacy_slot_playtest_guard.gd")

var shot_dir := ""
var failures: Array[String] = []
var battle: Control

func _initialize() -> void:
	if not LegacySlotPlaytestGuard.is_allowed():
		push_error(LegacySlotPlaytestGuard.message("playtest_combat_input_object_pass.gd"))
		quit(1)
		return
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _setup_attack_guard_combat()
	await _show_attack_die_hover()
	await _shot("01_attack_die_object_hover")
	await _click_attack_die(1)
	await _shot("02_attack_die_selected_marble_ready")
	await _show_slot_hover("profit")
	await _shot("03_marble_slot_object_hover")
	await _click_slot("profit")
	await _wait_until(func() -> bool: return bool(battle.call("_marble_setup_ready")), 120)
	await _show_spin_hover()
	await _shot("04_roulette_object_spin_hover")
	await _click_point(Vector2(640, 360))
	await _wait_until(func() -> bool: return str(battle.get("phase")) == "intervene", 140)
	await _shot("05_roulette_result_object_read")

	if str(battle.get("phase")) != "intervene":
		failures.append("roulette object click did not reach result phase")
	if battle != null:
		battle.queue_free()
		await process_frame
	if failures.is_empty():
		print("combat input object pass playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _setup_attack_guard_combat() -> void:
	battle = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.configure_encounter({
		"combat_core": "slot_marble",
		"monster_id": "table_crook",
		"monster_name": "Table Crook",
		"combat_cash": 20,
		"enemy_damage_delta": 0,
		"player_hp": 42,
		"player_max_hp": 42,
		"enemy_hp": 62,
		"enemy_max_hp": 62,
		"dice_rule_id": "two_dice_attack_guard",
		"relic_ids": [],
		"move_pattern": ["hp_strike"],
		"current_move_id": "hp_strike",
		"applied_effects": []
	})
	var forced_dice: Array[int] = [2, 6]
	battle.set("dice", forced_dice)
	battle.set("dice_rolled", true)
	battle.set("selected_attack_die_index", -1)
	battle.set("rerolls_left", 1)
	battle._render()
	await _settle(8)
	_assert_attack_die_prompt_buttons()
	var object_input_layer := battle.get("object_input_layer") as Control
	if object_input_layer == null:
		failures.append("battle should expose object input layer")
	elif object_input_layer.get_child_count() < 2:
		failures.append("attack dice should have real object input buttons")

func _show_attack_die_hover() -> void:
	var rect: Rect2 = battle.call("_die_rect", 1)
	await _move_mouse(rect.get_center())
	await _settle(8)
	if int(battle.get("hovered_attack_die_index")) != 1:
		failures.append("hovering second die did not mark attack die object")

func _click_attack_die(index: int) -> void:
	var rect: Rect2 = battle.call("_die_rect", index)
	await _click_point(rect.get_center())
	await _settle(14)
	if int(battle.get("selected_attack_die_index")) != index:
		failures.append("clicking die object did not select attack die")
	if int(battle.get("attack_base")) != 6:
		failures.append("selected die did not become attack base")
	if int(battle.get("player_block")) != 2:
		failures.append("unchosen die did not become player block")
	if str(battle.get("phase")) != "marble":
		failures.append("attack die object click did not advance to marble phase")

func _show_slot_hover(slot_id: String) -> void:
	var point: Vector2 = battle.call("_slot_center", slot_id)
	await _move_mouse(point)
	await _settle(8)
	if str(battle.get("hovered_slot_id")) != slot_id:
		failures.append("hovering roulette slot did not mark marble slot object")

func _click_slot(slot_id: String) -> void:
	var point: Vector2 = battle.call("_slot_center", slot_id)
	await _click_point(point)
	await _settle(24)

func _show_spin_hover() -> void:
	await _move_mouse(Vector2(640, 360))
	await _settle(8)
	if not bool(battle.get("hovered_spin_wheel")):
		failures.append("hovering roulette wheel did not mark spin object")

func _click_point(point: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	press.global_position = point
	battle.get_viewport().push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = point
	release.global_position = point
	battle.get_viewport().push_input(release, true)
	await process_frame

func _move_mouse(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	motion.relative = Vector2.ZERO
	battle.get_viewport().push_input(motion, true)
	await process_frame

func _assert_attack_die_prompt_buttons() -> void:
	var action_bar: HBoxContainer = battle.prompt_layer.action_bar
	var attack_buttons := 0
	for child in action_bar.get_children():
		var button := child as Button
		if button != null and button.text.contains("공격"):
			attack_buttons += 1
	if attack_buttons < 2:
		failures.append("attack die choice should keep fast prompt buttons as primary combat input")

func _wait_until(predicate: Callable, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(predicate.call()):
			return
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
