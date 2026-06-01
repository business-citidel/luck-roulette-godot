extends SceneTree

const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var overlay := RunPersistentOverlay.new()
	root.add_child(overlay)
	overlay.configure({
		"player_hp": 42,
		"player_max_hp": 42,
		"gold": 12,
		"relic_ids": ["loaded_die", "green_purse"]
	}, "combat")
	await process_frame

	overlay.pulse_relics(["loaded_die"])
	await process_frame
	var timers: Dictionary = overlay.get("relic_pulse_timers") as Dictionary
	if not timers.has("loaded_die"):
		failures.append("overlay should keep a pulse timer for triggered relic")
	if timers.has("green_purse"):
		failures.append("overlay should only pulse requested relic ids")

	overlay.pulse_relics(["loaded_die", "green_purse"])
	await process_frame
	timers = overlay.get("relic_pulse_timers") as Dictionary
	if not timers.has("loaded_die") or not timers.has("green_purse"):
		failures.append("overlay should support simultaneous relic pulses")

	await _settle(90)
	timers = overlay.get("relic_pulse_timers") as Dictionary
	if timers.has("loaded_die") or timers.has("green_purse"):
		failures.append("overlay relic pulse timers should expire quickly")

	overlay.queue_free()
	await process_frame

	if failures.is_empty():
		print("relic overlay pulse feedback smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame
