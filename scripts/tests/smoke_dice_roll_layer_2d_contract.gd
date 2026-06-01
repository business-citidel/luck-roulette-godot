extends SceneTree

const DiceRollLayer2D := preload("res://scripts/ui/dice_roll_layer_2d.gd")

var failures: Array[String] = []
var results: Array[int] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var layer: Control = DiceRollLayer2D.new()
	root.add_child(layer)
	layer.roll_finished.connect(func(value: int) -> void: results.append(value))
	await process_frame

	layer.configure({
		"theme": "event",
		"tray_rect": Rect2(Vector2(420, 310), Vector2(360, 206)),
		"result_label": "이벤트 눈"
	})
	layer.roll({"forced_value": 4})
	await _wait_for_result_count(1, 180)
	if results.size() != 1 or results[0] != 4:
		failures.append("2D dice layer did not emit forced result 4: " + str(results))
	if bool(layer.is_rolling()):
		failures.append("2D dice layer stayed rolling after first result")

	layer.roll({"forced_value": 4, "previous_value": 4, "avoid_previous": true})
	await _wait_for_result_count(2, 180)
	if results.size() != 2:
		failures.append("2D dice layer did not emit second result")
	elif results[1] == 4:
		failures.append("2D dice layer did not avoid previous value on reroll feel")
	if bool(layer.is_rolling()):
		failures.append("2D dice layer stayed rolling after second result")

	layer.queue_free()
	await process_frame
	if failures.is_empty():
		print("2D dice roll layer contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wait_for_result_count(count: int, max_frames: int) -> void:
	for i in range(max_frames):
		if results.size() >= count:
			return
		await process_frame

