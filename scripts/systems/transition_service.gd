extends CanvasLayer

const EasyTransitionScene := preload("res://addons/easytransition/easytransition.tscn")

var easy_transition: Node
var fallback_rect: ColorRect

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	easy_transition = EasyTransitionScene.instantiate()
	add_child(easy_transition)
	fallback_rect = ColorRect.new()
	fallback_rect.color = Color(0.03, 0.02, 0.025, 0.0)
	fallback_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fallback_rect)

func cover(duration: float = 0.28) -> void:
	if easy_transition != null and easy_transition.has_method("cover"):
		await easy_transition.cover(duration, 8, Color("#08050a"), null, true, 0.72, 3.0)
		return
	await _fallback_fade(0.0, 1.0, duration)

func uncover(duration: float = 0.28) -> void:
	if easy_transition != null and easy_transition.has_method("uncover"):
		await easy_transition.uncover(duration)
		return
	await _fallback_fade(1.0, 0.0, duration)

func _fallback_fade(from_alpha: float, to_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(_set_fallback_alpha, from_alpha, to_alpha, duration)
	await tween.finished

func _set_fallback_alpha(value: float) -> void:
	fallback_rect.color = Color(0.03, 0.02, 0.025, value)

