extends SceneTree

const DiceCupRollLayer3D := preload("res://scripts/ui/dice_cup_roll_layer_3d.gd")

var failures: Array[String] = []
var results: Array = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var layer: Control = DiceCupRollLayer3D.new()
	root.add_child(layer)
	layer.roll_finished.connect(func(values: Array) -> void: results.append(values.duplicate()))
	await process_frame

	layer.configure({
		"tray_rect": Rect2(Vector2(174, 438), Vector2(318, 178)),
		"seed": 220522
	})
	layer.roll({
		"dice_count": 2,
		"forced_values": [2, 5],
		"previous_values": [1, 1],
		"time_scale": 8.0
	})
	await _wait_for_result_count(1, 180)
	if results.size() != 1 or results[0] != [2, 5]:
		failures.append("3D dice cup did not emit forced [2, 5]: " + str(results))
	if bool(layer.is_rolling()):
		failures.append("3D dice cup stayed rolling after first result")

	layer.roll({
		"dice_count": 2,
		"forced_values": [6, 4],
		"previous_values": [2, 5],
		"dice_locked": [true, false],
		"avoid_previous": true,
		"time_scale": 8.0
	})
	await _wait_for_result_count(2, 180)
	if results.size() != 2 or results[1] != [2, 4]:
		failures.append("3D dice cup did not preserve locked die on reroll: " + str(results))
	if bool(layer.is_rolling()):
		failures.append("3D dice cup stayed rolling after second result")

	layer.reset()
	if bool(layer.visible):
		failures.append("3D dice cup did not hide after reset")

	layer.queue_free()
	await process_frame
	if failures.is_empty():
		print("3D dice cup roll layer contract smoke passed")
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
