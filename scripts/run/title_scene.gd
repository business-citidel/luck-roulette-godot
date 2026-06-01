extends Control

signal completed(result: Dictionary)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const ShellText := preload("res://scripts/ui/shell_text.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TABLE := Color("#26170f")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

const MENU_BUTTON_SIZE := Vector2(280, 54)
const MENU_BUTTON_X := 500.0
const MENU_BUTTON_Y := 280.0
const MENU_BUTTON_GAP := 62.0
const MENU_BUTTON_TEXTURE_PAD := Vector2(28, 14)

var start_button: Button
var continue_button: Button
var gallery_button: Button
var settings_button: Button
var quit_button: Button
var seed_text: String = ""
var has_continue_save: bool = false
var started: bool = false

func configure(payload: Dictionary) -> void:
	seed_text = str(payload.get("seed_text", "run-shell-2026-05-10"))
	has_continue_save = bool(payload.get("has_continue", false))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	var title_texture := AssetCatalog.title_texture("background")
	if title_texture != null:
		draw_texture_rect(title_texture, Rect2(Vector2.ZERO, size), false, Color.WHITE)
		_draw_title_logo()
		_draw_title_button_skins()
		_draw_seed_slip()
	else:
		title_texture = AssetCatalog.title_texture("style_target_001")
	if title_texture != null and AssetCatalog.title_texture("background") == null:
		draw_texture_rect(title_texture, Rect2(Vector2.ZERO, size), false, Color.WHITE)
	elif title_texture == null:
		_draw_table_backdrop()
		_draw_lobby_map()
		_draw_menu_panel()
		_draw_seed_slip()

func _build_buttons() -> void:
	start_button = Button.new()
	start_button.name = "TitleNewRunButton"
	start_button.position = _menu_button_pos(0)
	start_button.size = MENU_BUTTON_SIZE
	_apply_title_button(start_button, true)
	_connect_redraw_on_hover(start_button)
	start_button.pressed.connect(_emit_action.bind("start_run"))
	add_child(start_button)

	continue_button = Button.new()
	continue_button.name = "TitleContinueButton"
	continue_button.position = _menu_button_pos(1)
	continue_button.size = MENU_BUTTON_SIZE
	continue_button.disabled = not has_continue_save
	_apply_title_button(continue_button, has_continue_save)
	_connect_redraw_on_hover(continue_button)
	continue_button.pressed.connect(_emit_action.bind("continue_run"))
	add_child(continue_button)

	gallery_button = Button.new()
	gallery_button.name = "TitleGalleryButton"
	gallery_button.position = _menu_button_pos(2)
	gallery_button.size = MENU_BUTTON_SIZE
	_apply_title_button(gallery_button, false)
	_connect_redraw_on_hover(gallery_button)
	gallery_button.pressed.connect(_emit_action.bind("open_gallery"))
	add_child(gallery_button)

	settings_button = Button.new()
	settings_button.name = "TitleSettingsButton"
	settings_button.position = _menu_button_pos(3)
	settings_button.size = MENU_BUTTON_SIZE
	_apply_title_button(settings_button, false)
	_connect_redraw_on_hover(settings_button)
	settings_button.pressed.connect(_emit_action.bind("open_settings"))
	add_child(settings_button)

	quit_button = Button.new()
	quit_button.name = "TitleQuitButton"
	quit_button.position = _menu_button_pos(4)
	quit_button.size = MENU_BUTTON_SIZE
	_apply_title_button(quit_button, false)
	_connect_redraw_on_hover(quit_button)
	quit_button.pressed.connect(_emit_action.bind("quit_game"))
	add_child(quit_button)
	_refresh_text()

func _refresh_text() -> void:
	if start_button != null:
		start_button.text = UiText.t("title.new_run")
	if continue_button != null:
		continue_button.text = UiText.t("title.continue") if has_continue_save else UiText.t("title.continue") + "\n" + UiText.t("title.no_save")
	if gallery_button != null:
		gallery_button.text = UiText.t("title.gallery")
	if settings_button != null:
		settings_button.text = UiText.t("title.settings")
	if quit_button != null:
		quit_button.text = UiText.t("title.quit")

func _apply_title_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 21 if primary else 18)
	button.add_theme_font_override("font", ShellText.ui_bold_font())
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color("#fff2c8"))
	button.add_theme_color_override("font_pressed_color", Color("#f7d27a"))
	button.add_theme_color_override("font_disabled_color", Color(TEXT, 0.54))
	var transparent := _transparent_button_style()
	if AssetCatalog.title_texture("menu_button_idle") != null:
		button.add_theme_stylebox_override("normal", transparent)
		button.add_theme_stylebox_override("hover", transparent)
		button.add_theme_stylebox_override("pressed", transparent)
		button.add_theme_stylebox_override("disabled", transparent)
		button.add_theme_stylebox_override("focus", transparent)
	else:
		button.add_theme_stylebox_override("normal", _title_button_style(primary, false))
		button.add_theme_stylebox_override("hover", _title_button_style(true, false))
		button.add_theme_stylebox_override("pressed", _title_button_style(primary, false, true))
		button.add_theme_stylebox_override("disabled", _title_button_style(primary, true))
		button.add_theme_stylebox_override("focus", _title_button_style(primary, false))

func _transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _menu_button_pos(index: int) -> Vector2:
	return Vector2(MENU_BUTTON_X, MENU_BUTTON_Y + float(index) * MENU_BUTTON_GAP)

func _connect_redraw_on_hover(button: Button) -> void:
	button.mouse_entered.connect(func() -> void: queue_redraw())
	button.mouse_exited.connect(func() -> void: queue_redraw())

func _title_button_style(primary: bool, disabled: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3a2816") if primary else Color("#1d1711")
	style.border_color = Color(GOLD, 0.88) if primary else Color("#8f7752", 0.54)
	if disabled:
		style.bg_color = Color("#100d0a")
		style.border_color = Color("#7d6d55", 0.38)
	if pressed:
		style.bg_color = Color("#20140b")
	style.border_width_left = 2 if primary else 1
	style.border_width_top = 2 if primary else 1
	style.border_width_right = 2 if primary else 1
	style.border_width_bottom = 2 if primary else 1
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_emit_action("start_run")

func _start_run() -> void:
	_emit_action("start_run")

func _emit_action(action: String) -> void:
	if started:
		return
	started = true
	completed.emit({
		"accepted": true,
		"action": action
	})

func _draw_table_backdrop() -> void:
	UiSkin.draw_table_stage(self, Rect2(Vector2(32, 42), Vector2(1216, 634)), Rect2(Vector2(58, 70), Vector2(1164, 578)), Color(1, 1, 1, 0.98))
	draw_rect(Rect2(Vector2(58, 70), Vector2(1164, 578)), Color("#0d110d", 0.28), true)
	for i in range(9):
		var y := 96.0 + float(i) * 59.0
		draw_line(Vector2(74, y), Vector2(1202, y + 26.0), Color("#5d371f", 0.14), 16.0)
	draw_circle(Vector2(512, 354), 304.0, Color("#a56a34", 0.08))
	draw_circle(Vector2(512, 354), 226.0, Color("#080604", 0.14), false, 14.0)
	UiSkin.draw_pin(self, Vector2(82, 84), 28.0, Color(GOLD, 0.72))
	UiSkin.draw_pin(self, Vector2(1198, 84), 28.0, Color(GOLD, 0.72))
	UiSkin.draw_pin(self, Vector2(82, 624), 28.0, Color(GOLD, 0.72))
	UiSkin.draw_pin(self, Vector2(1198, 624), 28.0, Color(GOLD, 0.72))

func _draw_lobby_map() -> void:
	var deck_rect := Rect2(Vector2(104, 406), Vector2(132, 178))
	UiSkin.draw_parchment_card(self, deck_rect, "small", Color(1, 1, 1, 0.78))
	_draw_text("RUN", deck_rect.position + Vector2(34, 74), 22, INK)
	_draw_text("DECK", deck_rect.position + Vector2(28, 104), 16, Color(INK, 0.62))

	var route_nodes := [
		{"type": "combat", "pos": Vector2(292, 442), "state": "current"},
		{"type": "event", "pos": Vector2(438, 316), "state": "future"},
		{"type": "shop", "pos": Vector2(486, 496), "state": "future"},
		{"type": "combat", "pos": Vector2(620, 356), "state": "future"},
		{"type": "rest", "pos": Vector2(702, 492), "state": "future"},
		{"type": "boss", "pos": Vector2(738, 244), "state": "boss"}
	]
	for i in range(route_nodes.size() - 1):
		var a: Vector2 = route_nodes[i].get("pos", Vector2.ZERO)
		var b: Vector2 = route_nodes[i + 1].get("pos", Vector2.ZERO)
		UiSkin.draw_route_cord(self, a, b, Color(1, 1, 1, 0.32 if i > 0 else 0.62), 8.0 if i == 0 else 6.0)
	for node in route_nodes:
		_draw_lobby_node(node)

	UiSkin.draw_wax_stamp(self, Vector2(300, 506), 18.0, Color(GOLD, 0.84))
	UiSkin.draw_coin_marker(self, Vector2(620, 412), 16.0, Color("#9a6b3a", 0.76))
	_draw_text(UiText.t("title.route_note"), Vector2(250, 592), 15, Color(TEXT, 0.72))

func _draw_lobby_node(node: Dictionary) -> void:
	var center: Vector2 = node.get("pos", Vector2.ZERO)
	var state := str(node.get("state", "future"))
	var node_type := str(node.get("type", "combat"))
	var rect := Rect2(center - Vector2(48, 58), Vector2(96, 116))
	var tint := Color(1, 1, 1, 0.88 if state == "current" or state == "boss" else 0.58)
	UiSkin.draw_parchment_card(self, rect, "small", tint)
	var accent := GOLD if state == "current" else (RED if state == "boss" else Color("#7d6d55"))
	draw_rect(rect.grow(-8.0), Color(accent, 0.42 if state != "future" else 0.20), false, 2.0)
	_draw_node_icon(node_type, rect.position + Vector2(48, 42), Color(accent, 0.92 if state != "future" else 0.54))
	var label := "START" if state == "current" else ("HOUSE" if state == "boss" else "?")
	_draw_text(label, rect.position + Vector2(25, 91), 12, Color(INK, 0.72 if state != "future" else 0.42))
	if state == "current":
		UiSkin.draw_coin_marker(self, rect.position + Vector2(82, 92), 15.0, Color(GOLD, 0.88))
	elif state == "boss":
		UiSkin.draw_wax_stamp(self, rect.position + Vector2(82, 92), 15.0, Color(RED, 0.82))

func _draw_menu_panel() -> void:
	var rect := Rect2(Vector2(792, 118), Vector2(386, 484))
	draw_rect(Rect2(rect.position + Vector2(10, 14), rect.size), Color("#020202", 0.46), true)
	UiSkin.draw_parchment_card(self, rect, "large", Color(1, 1, 1, 0.94))
	_draw_text(UiText.t("brand.title_caps"), rect.position + Vector2(38, 82), 38, INK)
	_draw_text(UiText.t("title.tagline"), rect.position + Vector2(42, 124), 17, Color(INK, 0.72))
	_draw_icon("roulette", Rect2(rect.position + Vector2(138, 164), Vector2(108, 108)))

func _draw_seed_slip() -> void:
	var rect := Rect2(Vector2(490, 612), Vector2(300, 42)) if AssetCatalog.title_texture("background") != null else Rect2(Vector2(836, 604), Vector2(300, 42))
	UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, 0.84))
	_draw_text(UiText.t("title.seed", {"seed": seed_text}), rect.position + Vector2(22, 27), 13, Color(INK, 0.62))

func _draw_title_logo() -> void:
	var texture := AssetCatalog.title_texture("logo_lockup")
	if texture == null:
		_draw_text(UiText.t("brand.title_caps"), Vector2(468, 150), 42, TEXT)
		return
	draw_texture_rect(texture, Rect2(Vector2(330, 64), Vector2(620, 190)), false, Color.WHITE)
	ShellText.draw_center_fit(self, UiText.t("brand.title_caps"), Rect2(Vector2(438, 120), Vector2(404, 54)), 42, TEXT, 28, "heading")
	ShellText.draw_center_fit(self, UiText.t("title.tagline"), Rect2(Vector2(430, 178), Vector2(420, 28)), 16, Color(TEXT, 0.76), 12, "regular")

func _draw_title_button_skins() -> void:
	for button in [start_button, continue_button, gallery_button, settings_button, quit_button]:
		if button == null:
			continue
		var texture_id := "menu_button_disabled" if button.disabled else ("menu_button_hover" if button.is_hovered() else "menu_button_idle")
		var texture := AssetCatalog.title_texture(texture_id)
		if texture == null:
			continue
		var rect := Rect2(button.position - MENU_BUTTON_TEXTURE_PAD, button.size + MENU_BUTTON_TEXTURE_PAD * 2.0)
		draw_texture_rect(texture, rect, false, Color.WHITE)
	if has_continue_save and continue_button != null:
		var badge := AssetCatalog.title_texture("continue_save_badge")
		if badge != null:
			draw_texture_rect(badge, Rect2(continue_button.position + Vector2(218, -20), Vector2(120, 34)), false, Color.WHITE)

func _draw_node_icon(node_type: String, center: Vector2, tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = AssetCatalog.node_icon(node_type)
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(center - Vector2(18, 18), Vector2(36, 36)), false, tint)

func _draw_icon(prop_id: String, rect: Rect2) -> void:
	var texture: Texture2D = AssetCatalog.prop_icon(prop_id)
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.82))
	draw_arc(rect.get_center(), rect.size.x * 0.56, 0.0, TAU, 80, GOLD, 4.0)
	draw_arc(rect.get_center(), rect.size.x * 0.72, 0.0, TAU, 80, Color("#8a642f", 0.56), 2.0)

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	ShellText.draw(self, text, pos, font_size, color)
