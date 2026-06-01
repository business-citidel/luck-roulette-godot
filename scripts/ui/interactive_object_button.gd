class_name InteractiveObjectButton
extends Button

var object_motion_tween: Tween
var visual_offset := Vector2.ZERO:
	set(value):
		visual_offset = value
		queue_redraw()
var visual_scale := Vector2.ONE:
	set(value):
		visual_scale = value
		queue_redraw()

func setup_object_button(input_rect: Rect2) -> void:
	position = input_rect.position
	size = input_rect.size
	custom_minimum_size = input_rect.size
	pivot_offset = input_rect.size * 0.5
	scale = Vector2.ONE
	text = ""
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	flat = true
	reset_visual_motion()
	apply_transparent_object_style()

func reset_visual_motion() -> void:
	visual_offset = Vector2.ZERO
	visual_scale = Vector2.ONE

func visual_rect(rect: Rect2, extra_scale_x: float = 1.0) -> Rect2:
	var draw_size := Vector2(rect.size.x * visual_scale.x * extra_scale_x, rect.size.y * visual_scale.y)
	var draw_pos := rect.position + (rect.size - draw_size) * 0.5 + visual_offset
	return Rect2(draw_pos, draw_size)

func tween_visual_to(target_offset: Vector2, target_scale: Vector2, duration: float) -> void:
	kill_visual_tween()
	object_motion_tween = create_tween()
	object_motion_tween.set_parallel(true)
	object_motion_tween.tween_property(self, "visual_offset", target_offset, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	object_motion_tween.tween_property(self, "visual_scale", target_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func kill_visual_tween() -> void:
	if object_motion_tween != null and object_motion_tween.is_valid():
		object_motion_tween.kill()

func apply_transparent_object_style() -> void:
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("disabled", empty)
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
