class_name CombatMarbleStatusOverlay
extends Control

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")
const ShellText := preload("res://scripts/ui/shell_text.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const GOLD := Color("#f2be4b")
const INK := Color("#090704")

const PANEL_RECT := Rect2(Vector2(160, 92), Vector2(960, 536))
const INNER_RECT := Rect2(Vector2(192, 124), Vector2(896, 472))
const CLOSE_RECT := Rect2(Vector2(936, 560), Vector2(132, 44))
const CARD_ORIGIN := Vector2(226, 184)
const CARD_SIZE := Vector2(142, 126)
const CARD_GAP := Vector2(22, 22)
const CARD_COLUMNS := 4
const STATUS_AVAILABLE := "available"
const STATUS_DISCARDED := "discarded"
const STATUS_SEALED := "sealed"

var items: Array[Dictionary] = []
var summary: Dictionary = {}
var close_button: Button
var marble_texture_source_rects: Dictionary = {}

func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_close_button()

func set_state(next_state: Dictionary) -> void:
	items = _dictionary_array(next_state.get("items", []))
	summary = (next_state.get("summary", {}) as Dictionary).duplicate(true)
	queue_redraw()

func open() -> void:
	visible = true
	if close_button != null:
		close_button.visible = true
	queue_redraw()

func close() -> void:
	visible = false
	if close_button != null:
		close_button.visible = false
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	if not PANEL_RECT.has_point(mouse.position):
		close()
	accept_event()

func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#020306", 0.58), true)
	UiSkin.draw_table_stage(self, PANEL_RECT, INNER_RECT, Color(1, 1, 1, 0.96))
	ShellText.draw_shadow(self, UiText.t("battle.marble_status.title"), Vector2(226, 160), 30, TEXT, Color("#090704", 0.62), Vector2(1, 2), -1.0, HORIZONTAL_ALIGNMENT_LEFT, "heading")
	ShellText.draw_fit_shadow(self, UiText.t("battle.marble_status.count", {
		"available": int(summary.get(STATUS_AVAILABLE, 0)),
		"discarded": int(summary.get(STATUS_DISCARDED, 0))
	}), Rect2(Vector2(690, 138), Vector2(272, 22)), 14, Color(TEXT, 0.72), 10, HORIZONTAL_ALIGNMENT_RIGHT, "bold")
	if items.is_empty():
		ShellText.draw_fit_shadow(self, UiText.t("battle.marble_status.empty"), Rect2(CARD_ORIGIN, Vector2(636, 28)), 18, Color(TEXT, 0.62), 12, HORIZONTAL_ALIGNMENT_LEFT, "bold")
		return
	for i in range(MarbleCatalog.MAX_DECK_SIZE):
		var rect := _card_rect(i)
		if i >= items.size():
			_draw_empty_card(rect)
		else:
			_draw_status_card(rect, items[i])

func _build_close_button() -> void:
	close_button = Button.new()
	close_button.name = "CombatMarbleStatusClose"
	close_button.position = CLOSE_RECT.position
	close_button.size = CLOSE_RECT.size
	close_button.text = UiText.t("battle.marble_status.close")
	close_button.visible = false
	close_button.focus_mode = Control.FOCUS_NONE
	UiSkin.apply_button(close_button, false)
	close_button.pressed.connect(close)
	add_child(close_button)

func _draw_status_card(rect: Rect2, item: Dictionary) -> void:
	_draw_card_frame(rect, false)
	var marble: Dictionary = (item.get("marble", {}) as Dictionary).duplicate(true)
	_draw_marble_on_card(rect, marble)
	_draw_status_wax(rect, str(item.get("status", STATUS_AVAILABLE)))

func _draw_empty_card(rect: Rect2) -> void:
	_draw_card_frame(rect, true)
	var center := rect.position + Vector2(rect.size.x * 0.5, 46.0)
	draw_circle(center, 30.0, Color("#090704", 0.28))
	draw_circle(center, 31.0, Color(TEXT, 0.12), false, 1.0)
	ShellText.draw_center_fit(self, "-", Rect2(rect.position + Vector2(0, 76), Vector2(rect.size.x, 24)), 22, Color(INK, 0.28), 14, "bold")

func _draw_card_frame(rect: Rect2, empty: bool) -> void:
	var texture_id := "item_locked_card" if empty else "item_card"
	var texture := AssetCatalog.shell_gallery_texture(texture_id)
	var alpha := 0.44 if empty else 0.94
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
	else:
		UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, alpha))

func _draw_marble_on_card(rect: Rect2, marble: Dictionary) -> void:
	var marble_id := str(marble.get("marble_id", MarbleCatalog.PLAIN))
	var texture := AssetCatalog.marble_texture(str(marble.get("asset_key", MarbleCatalog.asset_key(marble_id))))
	var icon_rect := Rect2(rect.position + Vector2((rect.size.x - 78.0) * 0.5, 15.0), Vector2(78, 78))
	if texture != null:
		_draw_normalized_marble_texture(texture, icon_rect)
	else:
		draw_circle(icon_rect.get_center(), 32.0, Color("#e8e0cf"))
	var label_rect := Rect2(rect.position + Vector2(11, 96), Vector2(rect.size.x - 22, 20))
	draw_rect(label_rect, Color("#090704", 0.48), true)
	draw_rect(label_rect, Color(GOLD, 0.22), false, 1.0)
	ShellText.draw_center_fit_shadow(self, str(marble.get("short_name", MarbleCatalog.short_name(marble_id))), label_rect, 12, TEXT, 8, "bold", Color("#090704", 0.70), Vector2(1, 1))

func _draw_status_wax(rect: Rect2, status: String) -> void:
	var center := rect.position + Vector2(rect.size.x - 15.0, 16.0)
	var fill := Color("#3f9a55")
	var edge := Color("#1d4f2e")
	if status == STATUS_DISCARDED:
		fill = Color("#9e2b23")
		edge = Color("#4b100c")
	elif status == STATUS_SEALED:
		fill = Color("#4d4740")
		edge = Color("#1f1b17")
	for i in range(12):
		var angle := float(i) / 12.0 * TAU
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 14.0, 6.0, edge)
	draw_circle(center, 19.0, edge)
	draw_circle(center, 15.5, fill)
	draw_circle(center, 10.0, Color("#f7e1aa", 0.12), false, 2.0)
	draw_circle(center + Vector2(-4, -5), 4.5, Color("#fff0c8", 0.16))

func _card_rect(index: int) -> Rect2:
	var col := index % CARD_COLUMNS
	var row := int(floor(float(index) / float(CARD_COLUMNS)))
	return Rect2(CARD_ORIGIN + Vector2(float(col) * (CARD_SIZE.x + CARD_GAP.x), float(row) * (CARD_SIZE.y + CARD_GAP.y)), CARD_SIZE)

func _draw_normalized_marble_texture(texture: Texture2D, rect: Rect2) -> void:
	draw_texture_rect_region(texture, rect, _marble_texture_source_rect(texture), Color.WHITE)

func _marble_texture_source_rect(texture: Texture2D) -> Rect2:
	var cache_key := texture.resource_path
	if cache_key == "":
		cache_key = str(texture.get_instance_id())
	if marble_texture_source_rects.has(cache_key):
		return marble_texture_source_rects.get(cache_key, Rect2())
	var image := texture.get_image()
	if image == null or image.is_empty():
		var fallback := Rect2(Vector2.ZERO, texture.get_size())
		marble_texture_source_rects[cache_key] = fallback
		return fallback
	var bbox := _alpha_bbox(image, 0.04)
	if bbox.size.x <= 0 or bbox.size.y <= 0:
		var empty_fallback := Rect2(Vector2.ZERO, texture.get_size())
		marble_texture_source_rects[cache_key] = empty_fallback
		return empty_fallback
	var square_size: int = maxi(bbox.size.x, bbox.size.y)
	var center: Vector2 = Vector2(bbox.position) + Vector2(bbox.size) * 0.5
	var source_pos := Vector2i(
		int(round(center.x - float(square_size) * 0.5)),
		int(round(center.y - float(square_size) * 0.5))
	)
	source_pos.x = clampi(source_pos.x, 0, max(0, image.get_width() - square_size))
	source_pos.y = clampi(source_pos.y, 0, max(0, image.get_height() - square_size))
	var source_rect := Rect2(Vector2(source_pos), Vector2(square_size, square_size))
	marble_texture_source_rects[cache_key] = source_rect
	return source_rect

func _alpha_bbox(image: Image, threshold: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > threshold:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result
