extends SceneTree

const RouletteSpinLayer2D := preload("res://scripts/ui/roulette_spin_layer_2d.gd")

var failures: Array[String] = []
var results: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var layer: Control = RouletteSpinLayer2D.new()
	root.add_child(layer)
	layer.spin_finished.connect(func(slot_id: String) -> void: results.append(slot_id))
	await process_frame

	layer.configure({
		"wheel_center": Vector2(640, 330),
		"wheel_size": Vector2(360, 360),
		"draw_result_badge": false
	})
	layer.spin({"forced_slot": "jackpot"})
	await _wait_for_result_count(1, 180)
	if results.size() != 1 or results[0] != "jackpot":
		failures.append("roulette layer did not emit forced jackpot: " + str(results))
	if bool(layer.is_spinning()):
		failures.append("roulette layer stayed spinning after result")

	layer.spin({"forced_slot": "bust"})
	await _wait_for_result_count(2, 180)
	if results.size() != 2 or results[1] != "bust":
		failures.append("roulette layer did not emit forced bust: " + str(results))
	if bool(layer.is_spinning()):
		failures.append("roulette layer stayed spinning after second result")

	layer.queue_free()
	await process_frame
	if failures.is_empty():
		print("2D roulette spin layer contract smoke passed")
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
