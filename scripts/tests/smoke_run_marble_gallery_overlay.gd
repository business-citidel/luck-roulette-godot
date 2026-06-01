extends SceneTree

const RunStateScript := preload("res://scripts/resources/run_state.gd")
const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var run_state: Resource = RunStateScript.new()
	run_state.reset_starting_marbles()
	var payload: Dictionary = run_state.to_payload()
	if (payload.get("marble_deck", []) as Array).size() != 9:
		failures.append("run state should expose starting marble deck")

	run_state.apply_reward({
		"add_marble_ids": ["stable"],
		"source": "smoke_reward"
	})
	payload = run_state.to_payload()
	if (payload.get("marble_deck", []) as Array).size() != 10:
		failures.append("run state should accept external marble additions")

	var overlay := RunPersistentOverlay.new()
	root.add_child(overlay)
	await process_frame
	overlay.configure(payload, "map", false, false, "")
	await process_frame

	var button := overlay.get_node_or_null("RunOverlayMarbleDeckButton") as Button
	if button == null or not button.visible:
		failures.append("marble deck button should be visible on run overlay")
	else:
		button.pressed.emit()
		await process_frame
		if not bool(overlay.get("marble_gallery_open")):
			failures.append("marble gallery should open from top bar button")

	var close_button := overlay.get_node_or_null("RunOverlayMarbleGalleryClose") as Button
	if close_button == null or not close_button.visible:
		failures.append("marble gallery close button should be visible when open")
	else:
		close_button.pressed.emit()
		await process_frame
		if bool(overlay.get("marble_gallery_open")):
			failures.append("marble gallery should close from close button")

	overlay.queue_free()
	await process_frame

	if failures.is_empty():
		print("run marble gallery overlay smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
