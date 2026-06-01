extends SceneTree

const PromptLayer := preload("res://scripts/ui/prompt_layer.gd")
const RunPersistentOverlay := preload("res://scripts/ui/run_persistent_overlay.gd")
const HandLayer := preload("res://scripts/ui/hand_layer.gd")
const TableLayer := preload("res://scripts/ui/table_layer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	await _check_prompt_button_states()
	await _check_overlay_combat_detail_position()
	_check_phase_focus_payloads()

	if failures.is_empty():
		print("005a combat game-feel contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_prompt_button_states() -> void:
	var prompt := PromptLayer.new()
	root.add_child(prompt)
	await process_frame
	prompt.add_button("굴리기", Callable(self, "_noop"), true, true)
	prompt.add_button("받기", Callable(self, "_noop"), false, false)
	await process_frame
	if prompt.action_bar.get_child_count() != 2:
		failures.append("prompt should keep action buttons in stable action bar")
		prompt.queue_free()
		return
	var primary := prompt.action_bar.get_child(0) as Button
	var disabled := prompt.action_bar.get_child(1) as Button
	if primary == null or disabled == null:
		failures.append("prompt action children should be buttons")
		prompt.queue_free()
		return
	if primary.custom_minimum_size != Vector2(248, 64):
		failures.append("primary combat button size changed")
	if primary.mouse_default_cursor_shape != Control.CURSOR_POINTING_HAND:
		failures.append("enabled combat button should use pointing cursor")
	if not disabled.disabled:
		failures.append("disabled combat button should stay disabled")
	var normal := primary.get_theme_stylebox("normal") as StyleBoxFlat
	var hover := primary.get_theme_stylebox("hover") as StyleBoxFlat
	var pressed := primary.get_theme_stylebox("pressed") as StyleBoxFlat
	var disabled_style := disabled.get_theme_stylebox("disabled") as StyleBoxFlat
	if normal == null or hover == null or pressed == null or disabled_style == null:
		failures.append("combat button styles should be StyleBoxFlat")
	elif normal.bg_color == hover.bg_color or normal.bg_color == pressed.bg_color:
		failures.append("combat button normal/hover/pressed states should read differently")
	elif pressed.content_margin_top <= normal.content_margin_top:
		failures.append("pressed combat button should visually sink")
	elif disabled_style.bg_color == normal.bg_color:
		failures.append("disabled combat button style should differ from normal")
	prompt.queue_free()

func _check_overlay_combat_detail_position() -> void:
	var overlay := RunPersistentOverlay.new()
	root.add_child(overlay)
	overlay.configure({
		"player_hp": 42,
		"player_max_hp": 42,
		"gold": 12,
		"relic_ids": ["loaded_die", "green_purse"]
	}, "combat")
	overlay.set("selected_relic_id", "loaded_die")
	await process_frame
	var detail_rect: Rect2 = overlay._detail_rect()
	var opponent_read_rect := Rect2(Vector2(452, 92), Vector2(430, 132))
	if detail_rect.intersects(opponent_read_rect):
		failures.append("combat relic detail should not collide with opponent read")
	overlay.queue_free()

func _check_phase_focus_payloads() -> void:
	var hand := HandLayer.new()
	root.add_child(hand)
	hand.set_state({"active_phase": "marble"})
	if str(hand.get("active_phase")) != "marble":
		failures.append("hand layer should accept active phase focus")
	hand.queue_free()

	var table := TableLayer.new()
	root.add_child(table)
	table.set_state({"active_phase": "intervene", "pending_slot": "profit"})
	if str(table.get("active_phase")) != "intervene":
		failures.append("table layer should accept active phase focus")
	if str(table.get("pending_slot")) != "profit":
		failures.append("table layer should preserve pending slot for result focus")
	table.queue_free()

func _noop() -> void:
	pass
