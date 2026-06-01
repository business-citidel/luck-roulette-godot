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
		var slot_rect: Rect2 = overlay.call("_marble_gallery_slot_rect", 0)
		overlay.call("_update_hovered_marble", slot_rect.get_center())
		await process_frame
		if int(overlay.get("hovered_marble_gallery_index")) != 0:
			failures.append("marble gallery hover should track hovered marble")
		var hovered: Dictionary = overlay.call("_hovered_marble", overlay.call("_marble_deck_items"))
		if hovered.is_empty() or str(hovered.get("marble_id", "")) == "":
			failures.append("marble gallery hover should resolve hovered marble payload")

	var close_button := overlay.get_node_or_null("RunOverlayMarbleGalleryClose") as Button
	if close_button == null or not close_button.visible:
		failures.append("marble gallery close button should be visible when open")
	else:
		close_button.pressed.emit()
		await process_frame
		if bool(overlay.get("marble_gallery_open")):
			failures.append("marble gallery should close from close button")
		button.pressed.emit()
		await process_frame
		var close_event := InputEventMouseButton.new()
		close_event.button_index = MOUSE_BUTTON_LEFT
		close_event.pressed = true
		close_event.position = (close_button.position + close_button.size * 0.5)
		overlay._gui_input(close_event)
		await process_frame
		if bool(overlay.get("marble_gallery_open")):
			failures.append("marble gallery should close from close button position")

	overlay.queue_free()
	await process_frame

	if failures.is_empty():
		print("run marble gallery overlay smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
