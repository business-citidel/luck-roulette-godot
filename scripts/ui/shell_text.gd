class_name ShellText
extends RefCounted

const FONT_HEADING := "res://assets/runtime/fonts/shell_heading_serif_bold.ttf"
const FONT_UI_BOLD := "res://assets/runtime/fonts/shell_ui_sans_bold.ttf"
const FONT_UI_REGULAR := "res://assets/runtime/fonts/shell_ui_sans_regular.ttf"

static var _heading_font: Font
static var _ui_bold_font: Font
static var _ui_regular_font: Font

static func heading_font() -> Font:
	if _heading_font == null:
		_heading_font = _load_font(FONT_HEADING)
	return _heading_font

static func ui_bold_font() -> Font:
	if _ui_bold_font == null:
		_ui_bold_font = _load_font(FONT_UI_BOLD)
	return _ui_bold_font

static func ui_regular_font() -> Font:
	if _ui_regular_font == null:
		_ui_regular_font = _load_font(FONT_UI_REGULAR)
	return _ui_regular_font

static func draw(target: CanvasItem, text: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, style: String = "regular") -> void:
	var font := _font_for_style(style)
	target.draw_string(font, pos, text, align, width, font_size, color)

static func draw_shadow(target: CanvasItem, text: String, pos: Vector2, font_size: int, color: Color, shadow_color: Color = Color(0, 0, 0, 0.58), shadow_offset: Vector2 = Vector2(1, 2), width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, style: String = "regular") -> void:
	var font := _font_for_style(style)
	target.draw_string(font, pos + shadow_offset, text, align, width, font_size, shadow_color)
	target.draw_string(font, pos, text, align, width, font_size, color)

static func draw_fit(target: CanvasItem, text: String, rect: Rect2, font_size: int, color: Color, min_size: int = 10, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, style: String = "regular") -> void:
	var font := _font_for_style(style)
	var fitted_size := fit_size(text, rect.size.x, font_size, min_size, style)
	var clipped := ellipsize(text, rect.size.x, fitted_size, style)
	target.draw_string(font, rect.position + Vector2(0, fitted_size), clipped, align, rect.size.x, fitted_size, color)

static func draw_fit_shadow(target: CanvasItem, text: String, rect: Rect2, font_size: int, color: Color, min_size: int = 10, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, style: String = "regular", shadow_color: Color = Color(0, 0, 0, 0.58), shadow_offset: Vector2 = Vector2(1, 2)) -> void:
	var font := _font_for_style(style)
	var fitted_size := fit_size(text, rect.size.x, font_size, min_size, style)
	var clipped := ellipsize(text, rect.size.x, fitted_size, style)
	var pos := rect.position + Vector2(0, fitted_size)
	target.draw_string(font, pos + shadow_offset, clipped, align, rect.size.x, fitted_size, shadow_color)
	target.draw_string(font, pos, clipped, align, rect.size.x, fitted_size, color)

static func draw_center_fit(target: CanvasItem, text: String, rect: Rect2, font_size: int, color: Color, min_size: int = 10, style: String = "regular") -> void:
	var font := _font_for_style(style)
	var fitted_size := fit_size(text, rect.size.x, font_size, min_size, style)
	var clipped := ellipsize(text, rect.size.x, fitted_size, style)
	var y := rect.position.y + rect.size.y * 0.5 + float(fitted_size) * 0.36
	target.draw_string(font, Vector2(rect.position.x, y), clipped, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fitted_size, color)

static func draw_center_fit_shadow(target: CanvasItem, text: String, rect: Rect2, font_size: int, color: Color, min_size: int = 10, style: String = "regular", shadow_color: Color = Color(0, 0, 0, 0.62), shadow_offset: Vector2 = Vector2(1, 2)) -> void:
	var font := _font_for_style(style)
	var fitted_size := fit_size(text, rect.size.x, font_size, min_size, style)
	var clipped := ellipsize(text, rect.size.x, fitted_size, style)
	var pos := Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + float(fitted_size) * 0.36)
	target.draw_string(font, pos + shadow_offset, clipped, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fitted_size, shadow_color)
	target.draw_string(font, pos, clipped, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fitted_size, color)

static func fit_size(text: String, width: float, font_size: int, min_size: int = 10, style: String = "regular") -> int:
	var font := _font_for_style(style)
	var size := font_size
	while size > min_size and _text_width(font, text, size) > width:
		size -= 1
	return size

static func ellipsize(text: String, width: float, font_size: int, style: String = "regular") -> String:
	var font := _font_for_style(style)
	if _text_width(font, text, font_size) <= width:
		return text
	var suffix := "..."
	var result := text
	while result.length() > 1 and _text_width(font, result + suffix, font_size) > width:
		result = result.substr(0, result.length() - 1)
	return result + suffix

static func _font_for_style(style: String) -> Font:
	if style == "heading":
		return heading_font()
	if style == "bold":
		return ui_bold_font()
	return ui_regular_font()

static func _load_font(path: String) -> Font:
	var font := FontFile.new()
	var err := font.load_dynamic_font(ProjectSettings.globalize_path(path))
	if err == OK:
		return font
	return ThemeDB.fallback_font

static func _text_width(font: Font, text: String, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
