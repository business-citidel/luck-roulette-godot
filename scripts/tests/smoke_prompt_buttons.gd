extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(BATTLE_SCENE)
	if scene == null:
		push_error("could not load battle scene")
		quit(1)
		return
	var battle: Control = scene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(battle)
	await _settle(8)
	if battle.prompt_layer == null:
		failures.append("prompt layer missing")
	elif battle.prompt_layer.action_bar == null:
		failures.append("action bar missing")
	elif battle.prompt_layer.action_bar.get_child_count() != 1:
		failures.append("expected one initial roll action button")
	else:
		var first_button: Button = battle.prompt_layer.action_bar.get_child(0) as Button
		if first_button == null:
			failures.append("first action is not a button")
		elif first_button.disabled:
			failures.append("first dice action is disabled")
		elif not (first_button.text.contains("굴리기") or first_button.text.contains("Roll")):
			failures.append("first action is not the roll action")
		else:
			var initial_x: float = first_button.global_position.x
			battle._render()
			if battle.prompt_layer.action_bar.get_child_count() != 1:
				failures.append("rerender accumulated stale initial action buttons")
			await process_frame
			var rerendered_button: Button = battle.prompt_layer.action_bar.get_child(0) as Button
			if rerendered_button != null and abs(rerendered_button.global_position.x - initial_x) > 1.0:
				failures.append("initial action button shifted after rerender")
			first_button = rerendered_button
			first_button.pressed.emit()
			await _wait_for_dice_roll(battle, 180)
			if not bool(battle.get("dice_rolled")):
				failures.append("pressing first action did not roll table dice")
			elif str(battle.get("phase")) != "dice":
				failures.append("table dice should wait for confirm before marble phase")
			elif battle.prompt_layer.action_bar.get_child_count() != 2:
				failures.append("rolled dice should show reroll and confirm actions")
			else:
				battle._render()
				if battle.prompt_layer.action_bar.get_child_count() != 2:
					failures.append("rerender accumulated stale rolled dice action buttons")
	if failures.is_empty():
		print("prompt buttons smoke passed")
		if battle.ritual_director != null and battle.ritual_director.active_ritual != null:
			battle.ritual_director.active_ritual.queue_free()
			battle.ritual_director.active_ritual = null
		battle.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		if battle.ritual_director != null and battle.ritual_director.active_ritual != null:
			battle.ritual_director.active_ritual.queue_free()
			battle.ritual_director.active_ritual = null
		battle.queue_free()
		await process_frame
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _wait_for_dice_roll(battle: Control, max_frames: int) -> void:
	for i in range(max_frames):
		if bool(battle.get("dice_rolled")):
			return
		await process_frame

func _wait_for_ritual(battle: Control, ritual_name: String, max_frames: int) -> void:
	for i in range(max_frames):
		if battle.ritual_director != null and str(battle.ritual_director.active_ritual_name) == ritual_name:
			return
		await process_frame
