class_name RestActionObjectNode
extends "res://scripts/ui/interactive_object_button.gd"

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RunChoice := preload("res://scripts/run/run_choice.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const CANVAS_SIZE := Vector2(1280, 720)
const INK := Color("#090704")
const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")

var choice_id := ""
var choice_data: Dictionary = {}
var source_texture_id := ""
var source_canvas_rect := Rect2()
var label_rect := Rect2()
var visual_state := RunChoice.STATE_NORMAL

func configure_action(choice: Dictionary, input_rect: Rect2, source_texture: String, source_rect: Rect2, text_rect: Rect2) -> void:
	choice_data = choice.duplicate(true)
	choice_id = str(choice.get("id", ""))
	source_texture_id = source_texture
	source_canvas_rect = source_rect
	label_rect = Rect2(text_rect.position - input_rect.position, text_rect.size)
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))
	setup_object_button(input_rect)
	name = "RunChoice_" + choice_id
	tooltip_text = str(choice.get("label", choice_id)) + "\n" + str(choice.get("effect", ""))
	disabled = not RunChoice.is_interactive(choice)
	queue_redraw()

func set_choice(choice: Dictionary) -> void:
	choice_data = choice.duplicate(true)
	visual_state = str(choice.get("state", RunChoice.STATE_NORMAL))
	disabled = not RunChoice.is_interactive(choice)
	tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _ready() -> void:
	apply_transparent_object_style()
	mouse_entered.connect(func() -> void: set_hovered(true))
	mouse_exited.connect(func() -> void: set_hovered(false))

func set_hovered(value: bool) -> void:
	if disabled or visual_state == RunChoice.STATE_DISABLED or visual_state == RunChoice.STATE_CHOSEN:
		return
	if value:
		visual_state = RunChoice.STATE_HOVER
		z_index = 20
		tween_visual_to(Vector2(0, -10), Vector2(1.025, 1.025), 0.12)
	else:
		visual_state = str(choice_data.get("state", RunChoice.STATE_NORMAL))
		z_index = 1
		tween_visual_to(Vector2.ZERO, Vector2.ONE, 0.12)
	queue_redraw()

func _draw() -> void:
	var rect := visual_rect(Rect2(Vector2.ZERO, size))
	if source_texture_id != "__screen_overlay":
		var texture := AssetCatalog.rest_runtime_texture(source_texture_id)
		if texture != null:
			draw_texture_rect_region(texture, rect, _source_region(texture), Color.WHITE)
		else:
			UiSkin.draw_parchment_card(self, rect, "large", Color(1, 1, 1, 0.90))
	_draw_state(rect)
	_draw_labels(rect)

func _source_region(texture: Texture2D) -> Rect2:
	var texture_size := Vector2(texture.get_width(), texture.get_height())
	var scale_factor := Vector2(texture_size.x / CANVAS_SIZE.x, texture_size.y / CANVAS_SIZE.y)
	return Rect2(source_canvas_rect.position * scale_factor, source_canvas_rect.size * scale_factor)

func _draw_state(rect: Rect2) -> void:
	if visual_state == RunChoice.STATE_HOVER:
		draw_rect(rect.grow(-8.0), Color(GOLD, 0.16), true)
		draw_rect(rect.grow(-8.0), Color(GOLD, 0.76), false, 3.0)
	elif visual_state == RunChoice.STATE_CHOSEN:
		draw_rect(rect.grow(-8.0), Color(GREEN, 0.18), true)
		draw_rect(rect.grow(-8.0), Color(GREEN, 0.78), false, 4.0)
		UiSkin.draw_state_token(self, rect.position + Vector2(rect.size.x - 46.0, rect.size.y - 48.0), RunChoice.STATE_CHOSEN, 22.0)
	elif visual_state == RunChoice.STATE_DISABLED:
		draw_rect(rect, Color("#050403", 0.38), true)

func _draw_labels(_rect: Rect2) -> void:
	if label_rect.size == Vector2.ZERO:
		return
	var state_alpha := 0.52 if visual_state == RunChoice.STATE_DISABLED else 0.94
	if choice_id.begins_with("upgrade_"):
		if choice_id == "upgrade_primary_die" or choice_id == "upgrade_secondary_die":
			var title := UiText.t("rest.upgrade.primary.short") if choice_id == "upgrade_primary_die" else UiText.t("rest.upgrade.secondary.short")
			_draw_centered_text(title, Vector2(0, 50), 18, Color(INK, state_alpha), size.x)
			_draw_centered_text("+1", Vector2(0, 82), 22, Color(INK, state_alpha * 0.92), size.x)
			return
		_draw_text(str(choice_data.get("label", choice_id)), label_rect.position + Vector2(12, 24), 16, Color(INK, state_alpha), label_rect.size.x - 24.0)
		_draw_text(str(choice_data.get("effect", "")), label_rect.position + Vector2(12, 48), 17, Color(INK, state_alpha * 0.92), label_rect.size.x - 24.0)
		_draw_text(str(choice_data.get("note", "")), label_rect.position + Vector2(12, 72), 12, Color(INK, state_alpha * 0.76), label_rect.size.x - 24.0)
		return
	_draw_text(str(choice_data.get("label", choice_id)), label_rect.position + Vector2(16, 30), 23, Color(INK, state_alpha), label_rect.size.x - 32.0)
	_draw_text(str(choice_data.get("effect", "")), label_rect.position + Vector2(16, 58), 16, Color(INK, state_alpha * 0.82), label_rect.size.x - 32.0)
	_draw_text(str(choice_data.get("note", "")), label_rect.position + Vector2(16, 84), 12, Color(INK, state_alpha * 0.76), label_rect.size.x - 32.0)

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _draw_centered_text(value: String, pos: Vector2, font_size: int, color: Color, width: float) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
