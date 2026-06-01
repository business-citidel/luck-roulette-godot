extends SceneTree

const FixtureScene := preload("res://scenes/run/run_choice_fixture.tscn")
const RewardScene := preload("res://scenes/run/reward_scene.tscn")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_fixture_button_rects()
	await _check_fixture_card_center_click()
	await _check_fixture_blocked_states()
	await _check_fixture_double_click_once()
	await _check_reward_card_center_pilot()
	if failures.is_empty():
		print("run choice primitive smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_fixture_button_rects() -> void:
	var scene: Control = FixtureScene.instantiate()
	root.add_child(scene)
	await process_frame
	var controls: Array[Button] = scene.get_choice_controls()
	if controls.size() != 3:
		failures.append("fixture choice control count changed")
	for i in range(controls.size()):
		_assert_button_matches_offer_rect(controls[i], i, "fixture")
	scene.queue_free()
	await process_frame

func _check_fixture_card_center_click() -> void:
	var scene: Control = FixtureScene.instantiate()
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _click_card_center(scene, 0)
	await process_frame
	if results.size() != 1:
		failures.append("fixture card-center click did not emit exactly once")
	elif str(results[0].get("choice", "")) != "sample_gold":
		failures.append("fixture card-center click emitted wrong choice")
	if not bool(scene.get("submitted")) or str(scene.get("selected_choice")) != "sample_gold":
		failures.append("fixture did not update submitted/selected_choice")
	for button in scene.get_choice_controls():
		if not button.disabled:
			failures.append("fixture button stayed enabled after submit")
			break
	scene.queue_free()
	await process_frame

func _check_fixture_blocked_states() -> void:
	await _assert_blocked_fixture_click("mixed", 1, "disabled fixture choice emitted")
	await _assert_blocked_fixture_click("mixed", 2, "sold fixture choice emitted")
	await _assert_blocked_fixture_click("unaffordable", 1, "unaffordable fixture choice emitted")
	await _assert_blocked_fixture_click("resolved", 1, "resolved fixture choice emitted")

func _assert_blocked_fixture_click(mode: String, index: int, label: String) -> void:
	var scene: Control = FixtureScene.instantiate()
	scene.configure({"mode": mode})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	await _click_card_center(scene, index)
	await process_frame
	if results.size() != 0:
		failures.append(label)
	scene.queue_free()
	await process_frame

func _check_fixture_double_click_once() -> void:
	var scene: Control = FixtureScene.instantiate()
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	var point := UiLayoutSpec.offer_card_rect(0).get_center()
	await _click_control_at(scene, point)
	await _click_control_at(scene, point)
	await process_frame
	if results.size() != 1:
		failures.append("fixture double card-center click emitted " + str(results.size()) + " times")
	scene.queue_free()
	await process_frame

func _check_reward_card_center_pilot() -> void:
	var scene: Control = RewardScene.instantiate()
	scene.configure({
		"run_state": {"gold": 0, "player_hp": 42, "player_max_hp": 42, "relic_ids": []},
		"combat_result": {"winnings": 18}
	})
	var results: Array[Dictionary] = []
	scene.completed.connect(func(result: Dictionary) -> void: results.append(result))
	root.add_child(scene)
	await process_frame
	if not scene.has_method("get_choice_controls"):
		failures.append("reward pilot does not expose get_choice_controls")
	else:
		var controls: Array[Button] = scene.get_choice_controls()
		if controls.size() != 1:
			failures.append("reward claim control count changed")
		elif controls[0].disabled:
			failures.append("reward claim control should start enabled")
	await _click_button(scene.get_choice_controls()[0])
	await process_frame
	if results.size() != 1:
		failures.append("reward claim click did not emit exactly once")
	elif str(results[0].get("choice", "")) != "combat_reward":
		failures.append("reward claim click emitted wrong choice")
	scene.queue_free()
	await process_frame

func _assert_button_matches_offer_rect(button: Button, index: int, label: String) -> void:
	var rect := RunChoice.hit_rect(index)
	if button.position.distance_to(rect.position) > 0.01:
		failures.append(label + " button " + str(index) + " position did not match offer card rect")
	if button.size.distance_to(rect.size) > 0.01:
		failures.append(label + " button " + str(index) + " size did not match offer card rect")

func _click_card_center(scene: Control, index: int) -> void:
	if scene.has_method("get_choice_rect"):
		await _click_control_at(scene, scene.get_choice_rect(index).get_center())
		return
	await _click_control_at(scene, UiLayoutSpec.offer_card_rect(index).get_center())

func _click_control_at(scene: Control, pos: Vector2) -> void:
	var target := _button_at(scene, pos)
	if target == null:
		failures.append("no choice button found at " + str(pos))
		return
	await _click_button(target)

func _button_at(scene: Control, pos: Vector2) -> Button:
	var controls: Array[Button] = scene.get_choice_controls()
	for button in controls:
		var rect := Rect2(button.position, button.size)
		if rect.has_point(pos):
			return button
	return null

func _click_button(button: Button) -> void:
	var screen_center := button.position + button.size * 0.5
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = screen_center
	press.global_position = screen_center
	button.get_viewport().push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = screen_center
	release.global_position = screen_center
	button.get_viewport().push_input(release, true)
	await process_frame
