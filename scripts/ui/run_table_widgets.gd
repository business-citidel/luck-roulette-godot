class_name RunTableWidgets
extends RefCounted

const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const INK := Color("#090704")
const GOLD := Color("#f2be4b")
const MUTED_INK := Color("#5b5146")
const TEXT := Color("#f6efe2")

static func draw_result_summary(target: CanvasItem, rect: Rect2, pickup: Dictionary) -> void:
	UiSkin.draw_result_tray(target, rect, Color(1, 1, 1, 0.92))
	_draw_text(target, str(pickup.get("label", UiText.t("overlay.result_settled"))), rect.position + Vector2(16, 24), 13, TEXT)
	var lines: Array = pickup.get("lines", [])
	var y := rect.position.y + 48.0
	for i in range(min(2, lines.size())):
		_draw_text(target, str(lines[i]), Vector2(rect.position.x + 16.0, y), 12, Color(TEXT, 0.82))
		y += 18.0

static func draw_relic_tray(target: CanvasItem, rect: Rect2, items: Array, title: String = "", selected_id: String = "", detail_rect: Rect2 = Rect2()) -> void:
	UiSkin.draw_ledger_slip(target, rect, Color(1, 1, 1, 0.92))
	_draw_text(target, title if title != "" else UiText.t("overlay.relic_tray"), rect.position + Vector2(14, 20), 12, Color(INK, 0.72))
	if items.is_empty():
		_draw_text(target, UiText.t("overlay.empty"), rect.position + Vector2(14, min(48.0, rect.size.y - 12.0)), 13, Color(INK, 0.48))
		return
	var icon_entries := relic_icon_rects(rect, items)
	for entry in icon_entries:
		if bool(entry.get("overflow", false)):
			_draw_overflow_chip(target, entry.get("rect", Rect2()), int(entry.get("count", 0)))
		else:
			_draw_relic_icon_chip(target, entry.get("rect", Rect2()), entry.get("item", {}) as Dictionary, selected_id)
	if selected_id != "" and detail_rect.size.x > 0.0 and detail_rect.size.y > 0.0:
		var selected_item := relic_item_by_id(items, selected_id)
		if not selected_item.is_empty():
			draw_relic_detail_panel(target, detail_rect, selected_item)

static func relic_icon_rects(rect: Rect2, items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if items.is_empty():
		return result
	var icon_size: float = 24.0
	var gap: float = 6.0
	var x: float = rect.position.x + 14.0
	var y: float = rect.position.y + min(48.0, max(30.0, rect.size.y - 34.0))
	var usable_width: float = max(0.0, rect.size.x - 28.0)
	var max_slots: int = max(1, int(floor((usable_width + gap) / (icon_size + gap))))
	var visible_count: int = items.size()
	var overflow_count: int = 0
	if items.size() > max_slots:
		visible_count = max(0, max_slots - 1)
		overflow_count = items.size() - visible_count
	for i in range(visible_count):
		result.append({
			"rect": Rect2(Vector2(x + float(i) * (icon_size + gap), y), Vector2(icon_size, icon_size)),
			"item": items[i],
			"overflow": false
		})
	if overflow_count > 0:
		result.append({
			"rect": Rect2(Vector2(x + float(visible_count) * (icon_size + gap), y), Vector2(34.0, icon_size)),
			"count": overflow_count,
			"overflow": true
		})
	return result

static func relic_at_position(rect: Rect2, items: Array, pos: Vector2) -> String:
	for entry in relic_icon_rects(rect, items):
		if bool(entry.get("overflow", false)):
			continue
		var icon_rect: Rect2 = entry.get("rect", Rect2())
		if icon_rect.has_point(pos):
			var item: Dictionary = entry.get("item", {}) as Dictionary
			return str(item.get("id", ""))
	return ""

static func relic_item_by_id(items: Array, relic_id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == relic_id:
			return (item as Dictionary)
	return {}

static func draw_relic_detail_panel(target: CanvasItem, rect: Rect2, item: Dictionary) -> void:
	UiSkin.draw_ledger_slip(target, rect, Color(1, 1, 1, 0.93))
	var icon: Texture2D = AssetCatalog.relic_icon(str(item.get("icon_id", item.get("id", ""))))
	if rect.size.y < 58.0:
		if icon != null:
			target.draw_texture_rect(icon, Rect2(rect.position + Vector2(10, 10), Vector2(22, 22)), false, Color(1, 1, 1, 0.92))
		_draw_text(target, str(item.get("name", "")), rect.position + Vector2(38, 19), 12, INK)
		var compact_description := _clip(str(item.get("description", "")), max(18, int((rect.size.x - 46.0) / 6.0)))
		_draw_text(target, compact_description, rect.position + Vector2(38, 34), 9, Color(INK, 0.62))
		return
	if icon != null:
		target.draw_texture_rect(icon, Rect2(rect.position + Vector2(12, 14), Vector2(34, 34)), false, Color(1, 1, 1, 0.92))
	_draw_text(target, str(item.get("name", "")), rect.position + Vector2(54, 28), 15, INK)
	var description := str(item.get("description", ""))
	var lines := _wrap_words(description, max(18, int((rect.size.x - 64.0) / 7.0)), 2)
	for i in range(lines.size()):
		_draw_text(target, str(lines[i]), rect.position + Vector2(54, 48 + i * 15), 11, Color(INK, 0.66))

static func draw_prep_notes(target: CanvasItem, rect: Rect2, items: Array, title: String = "") -> void:
	UiSkin.draw_prompt_strip(target, rect, Color(1, 1, 1, 0.82))
	_draw_text(target, title if title != "" else UiText.t("overlay.prep_notes"), rect.position + Vector2(14, 20), 12, Color(TEXT, 0.78))
	if items.is_empty():
		_draw_text(target, UiText.t("overlay.no_pending"), rect.position + Vector2(14, 46), 12, Color(TEXT, 0.48))
		return
	var limit: int = min(2 if rect.size.y >= 64.0 else 1, items.size())
	for i in range(limit):
		var item: Dictionary = items[i]
		var line_y: float = rect.position.y + min(42.0, max(36.0, rect.size.y - 18.0)) + float(i) * 18.0
		var marker := _prep_marker(str(item.get("state", "queued")))
		_draw_text(target, marker + " " + str(item.get("description", "")), Vector2(rect.position.x + 14.0, line_y), 11, Color(TEXT, 0.78))
	if items.size() > limit:
		_draw_text(target, "+" + str(items.size() - limit), rect.position + Vector2(rect.size.x - 30.0, rect.size.y - 14.0), 11, Color(TEXT, 0.68))

static func _draw_relic_chip(target: CanvasItem, rect: Rect2, item: Dictionary) -> void:
	var incoming := str(item.get("state", "owned")) == "incoming"
	var fill := Color("#f1d79c", 0.88) if incoming else Color("#c2ad82", 0.8)
	var line := GOLD if incoming else Color("#5a4128", 0.56)
	target.draw_rect(rect, fill, true)
	target.draw_rect(rect, line, false, 1.0)
	var icon: Texture2D = AssetCatalog.relic_icon(str(item.get("icon_id", item.get("id", ""))))
	if icon != null:
		target.draw_texture_rect(icon, Rect2(rect.position + Vector2(5, 3), Vector2(18, 18)), false, Color(1, 1, 1, 0.9))
	_draw_text(target, _clip(str(item.get("name", "")), 7), rect.position + Vector2(28, 17), 10, Color(INK, 0.82))
	if incoming:
		UiSkin.draw_state_token(target, rect.position + Vector2(rect.size.x - 10.0, 12.0), "chosen", 7.0, Color(1, 1, 1, 0.85))

static func _draw_relic_icon_chip(target: CanvasItem, rect: Rect2, item: Dictionary, selected_id: String) -> void:
	var incoming := str(item.get("state", "owned")) == "incoming"
	var selected: bool = selected_id != "" and str(item.get("id", "")) == selected_id
	var fill: Color = Color("#f1d79c", 0.88) if incoming else Color("#c2ad82", 0.78)
	var line: Color = GOLD if selected or incoming else Color("#5a4128", 0.58)
	target.draw_rect(rect, fill, true)
	target.draw_rect(rect, line, false, 2.0 if selected else 1.0)
	var icon: Texture2D = AssetCatalog.relic_icon(str(item.get("icon_id", item.get("id", ""))))
	if icon != null:
		target.draw_texture_rect(icon, rect.grow(-3.0), false, Color(1, 1, 1, 0.92))
	if incoming:
		UiSkin.draw_state_token(target, rect.position + Vector2(rect.size.x - 3.0, 4.0), "chosen", 6.0, Color(1, 1, 1, 0.86))

static func _draw_overflow_chip(target: CanvasItem, rect: Rect2, count: int) -> void:
	target.draw_rect(rect, Color("#c2ad82", 0.72), true)
	target.draw_rect(rect, Color("#5a4128", 0.58), false, 1.0)
	_draw_text(target, "+" + str(count), rect.position + Vector2(7, 17), 10, Color(INK, 0.78))

static func _clip(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars - 1) + "."

static func _wrap_words(text: String, max_chars: int, max_lines: int) -> Array[String]:
	var words := text.split(" ", false)
	var lines: Array[String] = []
	var line := ""
	for word in words:
		var candidate := str(word) if line == "" else line + " " + str(word)
		if candidate.length() > max_chars and line != "":
			lines.append(line)
			line = str(word)
			if lines.size() >= max_lines:
				return lines
		else:
			line = candidate
	if line != "" and lines.size() < max_lines:
		lines.append(line)
	return lines

static func _prep_marker(state: String) -> String:
	match state:
		"incoming":
			return "+"
		"applied":
			return "A"
		"consumed":
			return "X"
		_:
			return "P"

static func _draw_text(target: CanvasItem, text: String, pos: Vector2, font_size: int, color: Color) -> void:
	target.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
