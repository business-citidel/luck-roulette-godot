class_name EventPropActionObjectNode
extends "res://scripts/ui/interactive_object_button.gd"

const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const INK := Color("#090704")
const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")

var choice_id := ""
var choice_data: Dictionary = {}
var prop_kind := ""
var visual_state := RunChoice.STATE_NORMAL

func configure_action(choice: Dictionary, input_rect: Rect2, next_prop_kind: String) -> void:
	choice_data = choice.duplicate(true)
	choice_id = str(choice.get("id", ""))
	prop_kind = next_prop_kind
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))
	setup_object_button(input_rect)
	name = "RunChoice_" + choice_id
	tooltip_text = _prompt_text()
	disabled = not RunChoice.is_interactive(choice)
	queue_redraw()

func _ready() -> void:
	apply_transparent_object_style()
	mouse_entered.connect(func() -> void: set_hovered(true))
	mouse_exited.connect(func() -> void: set_hovered(false))

func set_hovered(value: bool) -> void:
	if disabled or visual_state == RunChoice.STATE_DISABLED:
		return
	if value:
		visual_state = RunChoice.STATE_HOVER
		z_index = 18
		tween_visual_to(Vector2(0, -4), Vector2(1.012, 1.012), 0.12)
	else:
		visual_state = str(choice_data.get("state", RunChoice.STATE_NORMAL))
		z_index = 1
		tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _draw() -> void:
	var rect := visual_rect(Rect2(Vector2.ZERO, size))
	if rect.size == Vector2.ZERO:
		return
	var active := visual_state == RunChoice.STATE_HOVER
	if active:
		_draw_object_focus(rect)
	_draw_prompt(rect, active)

func _draw_object_focus(rect: Rect2) -> void:
	var focus_rect := rect.grow(-12.0)
	draw_rect(focus_rect, Color(GOLD, 0.055), true)
	var short_side: float = min(focus_rect.size.x, focus_rect.size.y)
	var corner_len: float = min(44.0, short_side * 0.16)
	var width: float = 2.0
	var alpha: float = 0.58
	var tl: Vector2 = focus_rect.position
	var tr := Vector2(focus_rect.end.x, focus_rect.position.y)
	var bl := Vector2(focus_rect.position.x, focus_rect.end.y)
	var br: Vector2 = focus_rect.end
	draw_line(tl, tl + Vector2(corner_len, 0), Color(GOLD, alpha), width)
	draw_line(tl, tl + Vector2(0, corner_len), Color(GOLD, alpha), width)
	draw_line(tr, tr + Vector2(-corner_len, 0), Color(GOLD, alpha), width)
	draw_line(tr, tr + Vector2(0, corner_len), Color(GOLD, alpha), width)
	draw_line(bl, bl + Vector2(corner_len, 0), Color(GOLD, alpha), width)
	draw_line(bl, bl + Vector2(0, -corner_len), Color(GOLD, alpha), width)
	draw_line(br, br + Vector2(-corner_len, 0), Color(GOLD, alpha), width)
	draw_line(br, br + Vector2(0, -corner_len), Color(GOLD, alpha), width)

func _draw_prompt(rect: Rect2, active: bool) -> void:
	var text := _prompt_text()
	var prompt_size := Vector2(188, 38)
	var prompt_pos := Vector2(rect.position.x + (rect.size.x - prompt_size.x) * 0.5, rect.end.y - prompt_size.y - 18.0)
	var prompt_rect := Rect2(prompt_pos, prompt_size)
	if prop_kind == "roulette":
		prompt_rect.position.y = rect.end.y - prompt_size.y - 30.0
	UiSkin.draw_plaque(self, prompt_rect, active)
	_draw_text(text, prompt_rect.position + Vector2(20, 25), 15, INK, prompt_rect.size.x - 40.0)

func _prompt_text() -> String:
	match prop_kind:
		"dice":
			return UiText.t("event.prop.roll_dice")
		"roulette":
			return UiText.t("event.prop.spin_roulette")
		"receipt":
			return UiText.t("event.prop.check_slip")
		"box":
			return UiText.t("event.prop.open_box")
		_:
			return str(choice_data.get("label", UiText.t("event.prop.activate")))

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
