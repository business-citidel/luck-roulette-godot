extends Control

signal completed(result: Dictionary)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")
const CollectionProgressService := preload("res://scripts/systems/collection_progress_service.gd")
const ShellText := preload("res://scripts/ui/shell_text.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TEXT := Color("#f6efe2")
const INK := Color("#090704")
const GOLD := Color("#f2be4b")

const TAB_SPECS := [
	{"id": "characters", "key": "gallery.category.characters", "texture": "tab_characters", "rect": Rect2(Vector2(126, 82), Vector2(142, 58))},
	{"id": "relics", "key": "gallery.category.relics", "texture": "tab_relics", "rect": Rect2(Vector2(274, 82), Vector2(142, 58))},
	{"id": "monsters", "key": "gallery.category.monsters", "texture": "tab_monsters", "rect": Rect2(Vector2(422, 82), Vector2(142, 58))}
]
const CARD_ORIGIN := Vector2(128, 174)
const CARD_SIZE := Vector2(142, 184)
const CARD_GAP := Vector2(22, 22)
const ITEMS_PER_PAGE := 8
const DETAIL_RECT := Rect2(Vector2(836, 128), Vector2(320, 456))
const BACK_BUTTON_RECT := Rect2(Vector2(548, 612), Vector2(184, 48))
const LEFT_PAGE_RECT := Rect2(Vector2(82, 320), Vector2(42, 98))
const RIGHT_PAGE_RECT := Rect2(Vector2(774, 320), Vector2(42, 98))
const PAGE_LABEL_RECT := Rect2(Vector2(344, 580), Vector2(196, 26))

var active_category := "characters"
var page_index := 0
var selected_slot_index := 0
var back_button: Button
var next_page_button: Button
var previous_page_button: Button
var item_buttons: Array[Button] = []
var category_buttons: Dictionary = {}
var category_pages: Dictionary = {}
var selected_slots: Dictionary = {}

func configure(payload: Dictionary) -> void:
	active_category = _normalize_category(str(payload.get("category", "characters")))
	page_index = clampi(int(payload.get("page", 0)), 0, _page_count() - 1)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	UiSkin.draw_table_stage(self, Rect2(Vector2(72, 52), Vector2(1136, 616)), Rect2(Vector2(104, 84), Vector2(1072, 552)), Color(1, 1, 1, 0.96))
	_draw_tabs()
	_draw_detail_panel()
	_draw_text(UiText.t("gallery.title"), Vector2(130, 160), 30, TEXT)
	_draw_items()
	_draw_page_controls()

func _build_controls() -> void:
	for i in range(TAB_SPECS.size()):
		var spec: Dictionary = TAB_SPECS[i]
		var button := Button.new()
		var rect: Rect2 = spec.get("rect", Rect2())
		var category := str(spec.get("id", ""))
		button.name = "GalleryCategory_" + category
		button.position = rect.position
		button.size = rect.size
		button.text = ""
		_apply_transparent_button(button)
		button.pressed.connect(_set_category.bind(category))
		button.mouse_entered.connect(func() -> void: queue_redraw())
		button.mouse_exited.connect(func() -> void: queue_redraw())
		add_child(button)
		category_buttons[category] = button
	back_button = Button.new()
	back_button.name = "GalleryBackButton"
	back_button.position = BACK_BUTTON_RECT.position
	back_button.size = BACK_BUTTON_RECT.size
	back_button.text = UiText.t("gallery.back")
	back_button.add_theme_font_override("font", ShellText.ui_bold_font())
	UiSkin.apply_button(back_button, true)
	back_button.pressed.connect(_close)
	add_child(back_button)

	next_page_button = Button.new()
	next_page_button.name = "GalleryNextPageButton"
	next_page_button.position = RIGHT_PAGE_RECT.position
	next_page_button.size = RIGHT_PAGE_RECT.size
	next_page_button.text = ""
	_apply_transparent_button(next_page_button)
	next_page_button.pressed.connect(_go_next_page)
	next_page_button.mouse_entered.connect(func() -> void: queue_redraw())
	next_page_button.mouse_exited.connect(func() -> void: queue_redraw())
	add_child(next_page_button)

	previous_page_button = Button.new()
	previous_page_button.name = "GalleryPreviousPageButton"
	previous_page_button.position = LEFT_PAGE_RECT.position
	previous_page_button.size = LEFT_PAGE_RECT.size
	previous_page_button.text = ""
	_apply_transparent_button(previous_page_button)
	previous_page_button.pressed.connect(_go_previous_page)
	previous_page_button.mouse_entered.connect(func() -> void: queue_redraw())
	previous_page_button.mouse_exited.connect(func() -> void: queue_redraw())
	add_child(previous_page_button)

	for i in range(ITEMS_PER_PAGE):
		var item_button := Button.new()
		item_button.name = "GalleryItemButton_%d" % i
		var rect := _card_rect(i)
		item_button.position = rect.position
		item_button.size = rect.size
		item_button.text = ""
		_apply_transparent_button(item_button)
		item_button.pressed.connect(_select_item_slot.bind(i))
		item_button.mouse_entered.connect(func() -> void: queue_redraw())
		item_button.mouse_exited.connect(func() -> void: queue_redraw())
		add_child(item_button)
		item_buttons.append(item_button)

func _set_category(category: String) -> void:
	category_pages[active_category] = page_index
	active_category = _normalize_category(category)
	page_index = clampi(int(category_pages.get(active_category, 0)), 0, _page_count() - 1)
	_sync_selected_slot()
	queue_redraw()

func _draw_items() -> void:
	var items := _page_items()
	_sync_selected_slot()
	for i in range(ITEMS_PER_PAGE):
		var rect := _card_rect(i)
		var hovered := i < item_buttons.size() and (item_buttons[i] as Button).is_hovered()
		if i >= items.size():
			_draw_item_card({}, rect, true, false, hovered)
			continue
		var item: Dictionary = items[i]
		_draw_item_card(item, rect, false, i == selected_slot_index, hovered)
	if not items.is_empty():
		if str(items[selected_slot_index].get("gallery_state", "normal")) == "locked":
			_draw_locked_item_detail(items[selected_slot_index])
		else:
			_draw_detail_text(items[selected_slot_index])
	else:
		_draw_locked_detail()

func _draw_page_controls() -> void:
	var total_pages := _page_count()
	_draw_arrow(LEFT_PAGE_RECT, true, previous_page_button != null and previous_page_button.is_hovered())
	_draw_arrow(RIGHT_PAGE_RECT, false, next_page_button != null and next_page_button.is_hovered())
	var label := "%02d / %02d" % [page_index + 1, total_pages]
	draw_rect(PAGE_LABEL_RECT, Color("#090704", 0.46), true)
	draw_rect(PAGE_LABEL_RECT, Color(GOLD, 0.34), false, 1.0)
	ShellText.draw_center_fit_shadow(self, label, PAGE_LABEL_RECT, 13, Color(TEXT, 0.84), 10, "bold")

func _draw_arrow(rect: Rect2, points_left: bool, hovered: bool) -> void:
	var fill := Color("#1b1009", 0.82 if hovered else 0.62)
	var border := Color(GOLD, 0.88 if hovered else 0.46)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0 if hovered else 1.0)
	var center := rect.get_center()
	var points: PackedVector2Array
	if points_left:
		points = PackedVector2Array([
			center + Vector2(-10, 0),
			center + Vector2(9, -18),
			center + Vector2(9, 18)
		])
	else:
		points = PackedVector2Array([
			center + Vector2(10, 0),
			center + Vector2(-9, -18),
			center + Vector2(-9, 18)
		])
	draw_colored_polygon(points, Color(TEXT, 0.92 if hovered else 0.72))
	draw_polyline(points + PackedVector2Array([points[0]]), border, 1.0)

func _draw_tabs() -> void:
	for spec in TAB_SPECS:
		var rect: Rect2 = spec.get("rect", Rect2())
		var category := str(spec.get("id", ""))
		var texture := AssetCatalog.shell_gallery_texture(str(spec.get("texture", "")))
		var tint := Color.WHITE if category == active_category else Color(0.72, 0.72, 0.72, 0.82)
		if texture != null:
			draw_texture_rect(texture, rect, false, tint)
		else:
			UiSkin.draw_ledger_slip(self, rect, tint)
		var label_rect := Rect2(rect.position + Vector2(14, 34), Vector2(rect.size.x - 28, 18))
		draw_rect(label_rect, Color("#090704", 0.64), true)
		draw_rect(label_rect, Color(GOLD, 0.54 if category == active_category else 0.22), false, 1.0)
		if category == active_category:
			draw_line(label_rect.position + Vector2(8, label_rect.size.y + 2), label_rect.position + Vector2(label_rect.size.x - 8, label_rect.size.y + 2), GOLD, 2.0)
		ShellText.draw_center_fit_shadow(self, UiText.t(str(spec.get("key", ""))), label_rect, 12, TEXT if category == active_category else Color(TEXT, 0.72), 9, "bold")

func _draw_detail_panel() -> void:
	var texture := AssetCatalog.shell_gallery_texture("detail_panel")
	if texture != null:
		draw_texture_rect(texture, DETAIL_RECT, false, Color(1, 1, 1, 0.94))
	else:
		UiSkin.draw_parchment_card(self, DETAIL_RECT, "large", Color(1, 1, 1, 0.94))

func _card_rect(index: int) -> Rect2:
	var col := index % 4
	var row := index / 4
	return Rect2(CARD_ORIGIN + Vector2(float(col) * (CARD_SIZE.x + CARD_GAP.x), float(row) * (CARD_SIZE.y + CARD_GAP.y)), CARD_SIZE)

func _draw_item_card(item: Dictionary, rect: Rect2, empty: bool, selected: bool, hovered: bool) -> void:
	var state := "empty" if empty else str(item.get("gallery_state", "normal"))
	var locked := state == "empty" or state == "locked"
	var texture_id := "item_locked_card" if locked else "item_card"
	var texture := AssetCatalog.shell_gallery_texture(texture_id)
	var card_alpha := _card_alpha_for_state(state)
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, card_alpha))
	else:
		UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, card_alpha))
	if hovered and not empty:
		draw_rect(rect.grow(-7.0), Color("#fff0b8", 0.18), false, 2.0)
	if selected:
		draw_rect(rect.grow(-4.0), Color(GOLD, 0.30), false, 4.0)
		draw_rect(rect.grow(-10.0), Color("#fff0b8", 0.18), false, 1.0)
	if empty:
		_draw_text("-", rect.position + Vector2(64, 98), 24, Color(INK, 0.24))
		return
	if state == "locked":
		_draw_text("?", rect.position + Vector2(62, 74), 28, Color(INK, 0.42))
	else:
		var icon_drawn := _draw_item_icon(item, Rect2(rect.position + Vector2(48, 34), Vector2(46, 46)))
		if not icon_drawn:
			_draw_missing_visual_badge(Rect2(rect.position + Vector2(41, 36), Vector2(60, 34)), Color(INK, 0.54))
	ShellText.draw_fit(self, str(item.get("name", item.get("id", ""))), Rect2(rect.position + Vector2(14, 96), Vector2(rect.size.x - 28, 26)), 12, TEXT, 9, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, str(item.get("note", "")), Rect2(rect.position + Vector2(14, 122), Vector2(rect.size.x - 28, 22)), 10, Color(TEXT, 0.64), 8, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	var status := str(item.get("status_label", ""))
	if status != "":
		ShellText.draw_fit(self, status, Rect2(rect.position + Vector2(14, 148), Vector2(rect.size.x - 28, 20)), 10, Color(GOLD, 0.72), 8, HORIZONTAL_ALIGNMENT_LEFT, "bold")

func _draw_detail_text(item: Dictionary) -> void:
	if not _draw_item_icon(item, Rect2(DETAIL_RECT.position + Vector2(126, 72), Vector2(68, 68))):
		_draw_missing_visual_badge(Rect2(DETAIL_RECT.position + Vector2(114, 88), Vector2(92, 36)), Color(INK, 0.56))
	ShellText.draw_fit(self, str(item.get("name", item.get("id", ""))), Rect2(DETAIL_RECT.position + Vector2(34, 154), Vector2(DETAIL_RECT.size.x - 68, 34)), 22, INK, 15, HORIZONTAL_ALIGNMENT_LEFT, "heading")
	ShellText.draw_fit(self, str(item.get("note", "")), Rect2(DETAIL_RECT.position + Vector2(34, 196), Vector2(DETAIL_RECT.size.x - 68, 26)), 14, Color(INK, 0.66), 10, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, _category_title(), Rect2(DETAIL_RECT.position + Vector2(34, 232), Vector2(DETAIL_RECT.size.x - 68, 24)), 13, Color(INK, 0.62), 10, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	var detail := str(item.get("detail", ""))
	if detail != "":
		_draw_wrapped_lines(detail, Rect2(DETAIL_RECT.position + Vector2(34, 268), Vector2(DETAIL_RECT.size.x - 68, 126)), 13, Color(INK, 0.70), 10, "regular")
	var status := str(item.get("status_label", ""))
	if status != "":
		ShellText.draw_fit(self, status, Rect2(DETAIL_RECT.position + Vector2(34, 410), Vector2(DETAIL_RECT.size.x - 68, 24)), 13, Color(INK, 0.58), 10, HORIZONTAL_ALIGNMENT_LEFT, "bold")

func _draw_locked_detail() -> void:
	ShellText.draw_center_fit(self, UiText.t("gallery.locked.title"), Rect2(DETAIL_RECT.position + Vector2(34, 168), Vector2(DETAIL_RECT.size.x - 68, 42)), 23, Color(INK, 0.74), 15, "heading")
	ShellText.draw_center_fit(self, UiText.t("gallery.locked.body"), Rect2(DETAIL_RECT.position + Vector2(38, 220), Vector2(DETAIL_RECT.size.x - 76, 58)), 14, Color(INK, 0.58), 10, "regular")

func _draw_locked_item_detail(item: Dictionary) -> void:
	_draw_text("?", DETAIL_RECT.position + Vector2(148, 116), 36, Color(INK, 0.48))
	ShellText.draw_fit(self, str(item.get("name", "???")), Rect2(DETAIL_RECT.position + Vector2(34, 154), Vector2(DETAIL_RECT.size.x - 68, 34)), 22, INK, 15, HORIZONTAL_ALIGNMENT_LEFT, "heading")
	ShellText.draw_fit(self, str(item.get("note", UiText.t("gallery.undiscovered"))), Rect2(DETAIL_RECT.position + Vector2(34, 196), Vector2(DETAIL_RECT.size.x - 68, 26)), 14, Color(INK, 0.66), 10, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, _category_title(), Rect2(DETAIL_RECT.position + Vector2(34, 232), Vector2(DETAIL_RECT.size.x - 68, 24)), 13, Color(INK, 0.62), 10, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	ShellText.draw_fit(self, UiText.t("gallery.locked.body"), Rect2(DETAIL_RECT.position + Vector2(34, 284), Vector2(DETAIL_RECT.size.x - 68, 54)), 13, Color(INK, 0.58), 10, HORIZONTAL_ALIGNMENT_LEFT, "regular")

func _draw_item_icon(item: Dictionary, rect: Rect2) -> bool:
	var texture: Texture2D
	if active_category == "relics":
		texture = AssetCatalog.relic_icon(str(item.get("icon_id", item.get("id", ""))))
	elif active_category == "monsters":
		texture = AssetCatalog.monster_texture(str(item.get("id", "")))
	elif active_category == "characters":
		texture = _character_gallery_texture(str(item.get("id", "")), str(item.get("gallery_state", "normal")))
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.92))
		return true
	return false

func _character_gallery_texture(character_id: String, state: String) -> Texture2D:
	if state == "locked":
		return null
	for suffix in ["_select_card", "_hud_emblem", "_hero"]:
		var texture := AssetCatalog.character_runtime_texture(character_id + suffix)
		if texture != null:
			return texture
	return null

func _draw_missing_visual_badge(rect: Rect2, color: Color) -> void:
	draw_rect(rect, Color("#f1d38a", 0.18), true)
	draw_rect(rect, Color(GOLD, 0.34), false, 1.0)
	ShellText.draw_center_fit(self, UiText.t("gallery.status.needs_art"), rect, 10, color, 8, "bold")

func _card_alpha_for_state(state: String) -> float:
	match state:
		"locked":
			return 0.64
		"coming_soon":
			return 0.76
		"empty":
			return 0.42
		_:
			return 0.92

func _items() -> Array[Dictionary]:
	if active_category == "characters":
		var characters: Array[Dictionary] = []
		for id in CharacterContractCatalog.all_character_ids():
			var character := CharacterContractCatalog.get_character(id)
			var enabled := bool(character.get("enabled", false))
			var preview := bool(character.get("preview_enabled", false))
			var discovered := CollectionProgressService.is_character_discovered(id) or id == CharacterContractCatalog.default_character_id()
			var state := "normal" if enabled and discovered else ("coming_soon" if preview and not enabled else "locked")
			var name := str(character.get("name", id)) if state != "locked" or not enabled else "???"
			var note := str(character.get("subtitle", "")) if state != "locked" or not enabled else UiText.t("gallery.undiscovered")
			characters.append({
				"id": id,
				"name": name,
				"note": note,
				"detail": str(character.get("rule_text", "")) if state != "locked" or not enabled else "",
				"gallery_state": state,
				"status_label": _status_label_for_state(state)
			})
		return characters
	if active_category == "relics":
		var relics: Array[Dictionary] = []
		for id in RelicCatalog.all_ids():
			var relic := RelicCatalog.get_relic(id)
			var discovered := CollectionProgressService.is_relic_discovered(id)
			var relic_state := "normal" if bool(relic.get("unlocked", false)) and discovered else "locked"
			var tags: Array = relic.get("tags", [])
			relics.append({
				"id": id,
				"icon_id": RelicCatalog.icon_id(id),
				"name": RelicCatalog.display_name(id) if relic_state == "normal" else "???",
				"note": RelicCatalog.rarity(id) if relic_state == "normal" else UiText.t("gallery.undiscovered"),
				"detail": RelicCatalog.short_description(id) if relic_state == "normal" else "",
				"gallery_state": relic_state,
				"status_label": _status_label_for_state(relic_state),
				"meta_line": ", ".join(_string_array(tags))
			})
		return relics
	if active_category == "monsters":
		var monsters: Array[Dictionary] = []
		for id in MonsterCatalog.all_runtime_monster_ids():
			var monster := MonsterCatalog.get_monster(id)
			var discovered := CollectionProgressService.is_monster_discovered(id)
			monsters.append({
				"id": id,
				"name": str(monster.get("name", id)) if discovered else "???",
				"note": str(monster.get("tier", "")) + " / " + str(monster.get("pattern_role", "")) if discovered else UiText.t("gallery.undiscovered"),
				"detail": str(monster.get("pattern_read", "")) if discovered else "",
				"gallery_state": "normal" if discovered else "locked"
			})
		return monsters
	return []

func _page_items() -> Array[Dictionary]:
	var items := _items()
	var start := page_index * ITEMS_PER_PAGE
	var end = mini(start + ITEMS_PER_PAGE, items.size())
	if start >= items.size():
		return []
	return items.slice(start, end)

func _page_count() -> int:
	return max(1, int(ceil(float(_items().size()) / float(ITEMS_PER_PAGE))))

func _go_next_page() -> void:
	var total_pages := _page_count()
	page_index = (page_index + 1) % total_pages
	category_pages[active_category] = page_index
	_sync_selected_slot()
	queue_redraw()

func _go_previous_page() -> void:
	var total_pages := _page_count()
	page_index = (page_index - 1 + total_pages) % total_pages
	category_pages[active_category] = page_index
	_sync_selected_slot()
	queue_redraw()

func _select_item_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _page_items().size():
		return
	selected_slot_index = slot_index
	selected_slots[_selection_key()] = selected_slot_index
	queue_redraw()

func _sync_selected_slot() -> void:
	var item_count := _page_items().size()
	if item_count <= 0:
		selected_slot_index = 0
		return
	selected_slot_index = clampi(int(selected_slots.get(_selection_key(), 0)), 0, item_count - 1)
	selected_slots[_selection_key()] = selected_slot_index

func _selection_key() -> String:
	return active_category + ":" + str(page_index)

func _category_title() -> String:
	if active_category == "characters":
		return UiText.t("gallery.subtitle.characters")
	if active_category == "relics":
		return UiText.t("gallery.subtitle.relics")
	if active_category == "monsters":
		return UiText.t("gallery.subtitle.monsters")
	return UiText.t("gallery.subtitle.characters")

func _status_label_for_state(state: String) -> String:
	match state:
		"locked":
			return UiText.t("gallery.status.locked")
		"coming_soon":
			return UiText.t("gallery.status.coming_soon")
		"missing_visual":
			return UiText.t("gallery.status.needs_art")
		_:
			return ""

func _normalize_category(category: String) -> String:
	if category == "relics" or category == "monsters" or category == "characters":
		return category
	return "characters"

func _draw_wrapped_lines(text: String, rect: Rect2, font_size: int, color: Color, min_size: int, style: String) -> void:
	var words := text.split(" ", false)
	var lines: Array[String] = []
	var line := ""
	for word in words:
		var candidate := str(word) if line == "" else line + " " + str(word)
		if ShellText.fit_size(candidate, rect.size.x, font_size, min_size, style) < font_size and line != "":
			lines.append(line)
			line = str(word)
		else:
			line = candidate
	if line != "":
		lines.append(line)
	var line_height := float(font_size + 5)
	var max_lines := int(floor(rect.size.y / line_height))
	for i in range(min(lines.size(), max_lines)):
		var out := lines[i]
		if i == max_lines - 1 and lines.size() > max_lines:
			out = ShellText.ellipsize(out + "...", rect.size.x, font_size, style)
		ShellText.draw_fit(self, out, Rect2(rect.position + Vector2(0, float(i) * line_height), Vector2(rect.size.x, line_height)), font_size, color, min_size, HORIZONTAL_ALIGNMENT_LEFT, style)

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_close()
		elif event.keycode == KEY_LEFT:
			_go_previous_page()
		elif event.keycode == KEY_RIGHT:
			_go_next_page()

func _close() -> void:
	completed.emit({"accepted": true, "action": "gallery_closed"})

func _apply_transparent_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_stylebox_override("focus", style)

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var style := "heading" if font_size >= 24 else "regular"
	ShellText.draw_shadow(self, text, pos, font_size, color, Color("#090704", 0.72), Vector2(1, 2), -1.0, HORIZONTAL_ALIGNMENT_LEFT, style)
