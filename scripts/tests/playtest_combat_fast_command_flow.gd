extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const LegacySlotPlaytestGuard := preload("res://scripts/tests/support/legacy_slot_playtest_guard.gd")

var shot_dir := ""
var failures: Array[String] = []
var battle: Control

func _initialize() -> void:
	if not LegacySlotPlaytestGuard.is_allowed():
		push_error(LegacySlotPlaytestGuard.message("playtest_combat_fast_command_flow.gd"))
		quit(1)
		return
	shot_dir = _shot_dir_from_args()
	if shot_dir == "":
		push_error("Missing --shot-dir=<absolute path>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.size = Vector2i(1280, 720)

	await _setup_attack_guard_ready()
	await _shot("01_fast_attack_buttons_ready")
	await _click_action_button("오른쪽")
	await _settle(10)
	await _shot("02_fast_attack_button_selected")
	await _press_number_key(KEY_2)
	await _wait_until(func() -> bool: return bool(battle.call("_marble_setup_ready")), 120)
	await _shot("03_fast_number_key_slot_ready")
	await _click_action_button("돌리기")
	await _wait_until(func() -> bool: return str(battle.get("phase")) == "intervene", 160)
	await _shot("04_fast_spin_button_result")

	if int(battle.get("selected_attack_die_index")) != 1:
		failures.append("fast attack button did not select the right die")
	if int(battle.get("attack_base")) != 6:
		failures.append("fast attack button did not preserve selected die value")
	if str(battle.get("pending_slot")) == "":
		failures.append("fast spin button did not produce roulette result")
	if battle != null:
		battle.queue_free()
		await process_frame
	if failures.is_empty():
		print("combat fast command flow playtest passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _setup_attack_guard_ready() -> void:
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
	if _button_with_text("오른쪽") == null:
		failures.append("fast combat should expose right-die attack button")

func _click_action_button(text_part: String) -> void:
	var button := _button_with_text(text_part)
	if button == null:
		failures.append("missing action button containing " + text_part)
		return
	var pos := button.get_global_rect().get_center()
	await _click_point(pos)
	await _settle(6)

func _button_with_text(text_part: String) -> Button:
	if battle == null or battle.prompt_layer == null or battle.prompt_layer.action_bar == null:
		return null
	for child in battle.prompt_layer.action_bar.get_children():
		var button := child as Button
		if button != null and not button.disabled and button.text.contains(text_part):
			return button
	return null

func _press_number_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	battle.get_viewport().push_input(event, true)
	await process_frame

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
