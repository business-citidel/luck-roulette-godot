class_name RunChoice
extends RefCounted

const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")

const STATE_NORMAL := "normal"
const STATE_HOVER := "hover"
const STATE_SELECTED := "selected"
const STATE_DISABLED := "disabled"
const STATE_UNAFFORDABLE := "unaffordable"
const STATE_SOLD := "sold"
const STATE_CHOSEN := "chosen"
const STATE_RESOLVED := "resolved"

const STATES := [
	STATE_NORMAL,
	STATE_HOVER,
	STATE_SELECTED,
	STATE_DISABLED,
	STATE_UNAFFORDABLE,
	STATE_SOLD,
	STATE_CHOSEN,
	STATE_RESOLVED
]

const NON_EMITTING_STATES := [
	STATE_DISABLED,
	STATE_UNAFFORDABLE,
	STATE_SOLD,
	STATE_CHOSEN,
	STATE_RESOLVED
]

static func create(id: String, label: String, note: String, effect: String, result: Dictionary, state: String = STATE_NORMAL, enabled: bool = true) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"note": note,
		"effect": effect,
		"result": result.duplicate(true),
		"state": state,
		"enabled": enabled
	}

static func hit_rect(index: int, count: int = 3) -> Rect2:
	return UiLayoutSpec.offer_card_rect(index, count)

static func is_known_state(state: String) -> bool:
	return STATES.has(state)

static func is_interactive(choice: Dictionary) -> bool:
	if not bool(choice.get("enabled", true)):
		return false
	var state := str(choice.get("state", STATE_NORMAL))
	return not NON_EMITTING_STATES.has(state)

static func state_after_submit(choice_id: String, selected_choice: String) -> String:
	if choice_id == selected_choice:
		return STATE_CHOSEN
	return STATE_DISABLED

static func build_hit_button(choice: Dictionary, index: int, callback: Callable, count: int = 3, hover_in: Callable = Callable(), hover_out: Callable = Callable()) -> Button:
	var button := Button.new()
	var choice_id := str(choice.get("id", "choice_" + str(index)))
	var rect := hit_rect(index, count)
	button.name = "RunChoice_" + choice_id
	button.text = ""
	button.tooltip_text = str(choice.get("label", choice_id))
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.disabled = not is_interactive(choice)
	button.flat = true
	_apply_transparent_style(button)
	if not button.disabled:
		button.pressed.connect(callback)
	if hover_in.is_valid():
		button.mouse_entered.connect(func() -> void: hover_in.call(choice_id))
	if hover_out.is_valid():
		button.mouse_exited.connect(func() -> void: hover_out.call(choice_id))
	return button

static func _apply_transparent_style(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
