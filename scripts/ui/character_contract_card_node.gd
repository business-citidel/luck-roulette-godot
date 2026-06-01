class_name CharacterContractCardNode
extends "res://scripts/ui/interactive_object_button.gd"

const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const MUTED := Color("#aab4c3")
const INK := Color("#110b06")

var character_id := ""
var character: Dictionary = {}
var enabled_contract := false
var preview_contract := false
var hovered := false
var selected_contract := false

func configure_contract(next_character_id: String, input_rect: Rect2) -> void:
	character_id = next_character_id
	character = CharacterContractCatalog.get_character(character_id)
	enabled_contract = bool(character.get("enabled", false))
	preview_contract = enabled_contract or bool(character.get("preview_enabled", false))
	setup_object_button(input_rect)
	name = "ContractCard_" + character_id
	disabled = not preview_contract
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if preview_contract else Control.CURSOR_ARROW
	tooltip_text = str(character.get("name", character_id)) + "\n" + str(character.get("rule_text", ""))
	queue_redraw()

func _ready() -> void:
	apply_transparent_object_style()
	mouse_entered.connect(func() -> void: set_hovered(true))
	mouse_exited.connect(func() -> void: set_hovered(false))

func set_hovered(value: bool) -> void:
	if disabled or selected_contract:
		return
	hovered = value
	z_index = 22 if hovered else 1
	tween_visual_to(Vector2(0, -14) if hovered else Vector2.ZERO, Vector2(1.035, 1.035) if hovered else Vector2.ONE, 0.13)
	queue_redraw()

func set_selected(value: bool) -> void:
	selected_contract = value
	hovered = false
	z_index = 30 if selected_contract else 1
	tween_visual_to(Vector2(0, -18) if selected_contract else Vector2.ZERO, Vector2(1.045, 1.045) if selected_contract else Vector2.ONE, 0.12)
	queue_redraw()

func _draw() -> void:
	var rect := visual_rect(Rect2(Vector2.ZERO, size))
	if rect.size == Vector2.ZERO:
		return
	var active := preview_contract and (hovered or selected_contract)
	var emblem_only := _is_emblem_only(rect)
	_draw_contract_card_art(rect, active)
	if active:
		draw_rect(rect.grow(14.0), Color(GOLD, 0.16), true)
		draw_rect(rect.grow(14.0), Color(GOLD, 0.82), false, 4.0)
		draw_rect(rect.grow(5.0), Color("#fff0a8", 0.42), false, 2.0)
	if not enabled_contract:
		var disabled_alpha := 0.14 if emblem_only else 0.30
		draw_rect(rect.grow(-7.0), Color("#050505", disabled_alpha), true)
		if not emblem_only:
			draw_rect(rect.grow(3.0), Color("#090704", 0.28), true)
		if not emblem_only:
			_draw_text("LOCKED", rect.position + Vector2(0, rect.size.y * 0.52), 20, Color(TEXT, 0.58), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if preview_contract and not emblem_only:
		_draw_enabled_labels(rect, active)

func _draw_contract_card_art(rect: Rect2, active: bool) -> void:
	if _is_emblem_only(rect):
		_draw_emblem_chip(rect, active)
		return
	var texture := AssetCatalog.character_runtime_texture(character_id + "_select_card")
	if texture == null:
		return
	var tint := Color(1, 1, 1, 1.0 if active else 0.92)
	draw_texture_rect(texture, rect, false, tint)

func _draw_emblem_chip(rect: Rect2, active: bool) -> void:
	var center := rect.position + rect.size * 0.5
	var radius: float = minf(rect.size.x, rect.size.y) * 0.48
	var plate_alpha := 0.98 if preview_contract else 0.70
	draw_circle(center, radius, Color("#110e0a", plate_alpha))
	draw_circle(center, radius * 0.88, Color("#2a2014", 0.94 if preview_contract else 0.62))
	draw_arc(center, radius, 0.0, TAU, 80, Color(GOLD, 0.68 if active else 0.42), 3.0, true)
	draw_arc(center, radius * 0.82, 0.0, TAU, 80, Color("#fff0a8", 0.25 if active else 0.12), 2.0, true)
	var texture := AssetCatalog.character_runtime_texture(character_id + "_hud_emblem")
	if texture == null:
		texture = AssetCatalog.character_runtime_texture(character_id + "_select_card")
	if texture == null:
		return
	var icon_bounds := rect.grow(-16.0)
	var icon_rect := _fit_texture_rect(texture.get_size(), icon_bounds)
	var tint := Color(1, 1, 1, 1.0 if preview_contract else 0.72)
	draw_texture_rect(texture, icon_rect, false, tint)
	if selected_contract:
		draw_arc(center, radius + 6.0, 0.0, TAU, 96, Color("#65d48e", 0.72), 4.0, true)

func _fit_texture_rect(texture_size: Vector2, bounds: Rect2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return bounds
	var scale_factor: float = minf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var fitted_size: Vector2 = texture_size * scale_factor
	return Rect2(bounds.position + (bounds.size - fitted_size) * 0.5, fitted_size)

func _is_emblem_only(rect: Rect2) -> bool:
	return rect.size.x <= 140.0 and rect.size.y <= 140.0

func _draw_enabled_labels(rect: Rect2, active: bool) -> void:
	var title_color := Color(GOLD, 0.95) if active else Color(TEXT, 0.72)
	var rule_color := Color(TEXT, 0.78) if active else Color(TEXT, 0.56)
	var compact := rect.size.x < 220.0
	var title_size := 13 if compact else 19
	var rule_size := 9 if compact else 13
	var title_y := rect.size.y - (66.0 if compact else 108.0)
	var rule_y := rect.size.y - (44.0 if compact else 76.0)
	_draw_text(str(character.get("name", "")), rect.position + Vector2(8, title_y), title_size, title_color, rect.size.x - 16.0, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text(str(character.get("subtitle", "")), rect.position + Vector2(8, rule_y), rule_size, rule_color, rect.size.x - 16.0, HORIZONTAL_ALIGNMENT_CENTER)
	if selected_contract:
		var selected_size := 10 if compact else 14
		var selected_y := rect.size.y - (20.0 if compact else 42.0)
		_draw_text(UiText.t("character.select.selected"), rect.position + Vector2(8, selected_y), selected_size, Color("#65d48e", 0.90), rect.size.x - 16.0, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, width: float, align: HorizontalAlignment) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, align, width, font_size, color)
