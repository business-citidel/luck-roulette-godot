class_name ShellPauseOverlay
extends Control

signal action_requested(action: String)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const ShellText := preload("res://scripts/ui/shell_text.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TEXT := Color("#f6efe2")
const INK := Color("#090704")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")

const PANEL_RECT := Rect2(Vector2(430, 100), Vector2(420, 520))
const TITLE_POS := Vector2(500, 196)
const BODY_POS := Vector2(502, 232)
const DIVIDER_RECT := Rect2(Vector2(504, 258), Vector2(272, 18))
const BUTTON_SIZE := Vector2(272, 52)
const BUTTON_TEXTURE_PAD := Vector2(32, 16)

var phase := ""
var buttons: Dictionary = {}
var confirming_abandon := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_buttons()
	hide()

func open_for_phase(next_phase: String) -> void:
	phase = next_phase
	confirming_abandon = false
	visible = true
	_refresh_buttons()
	queue_redraw()

func close() -> void:
	visible = false

func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(BG, 0.72), true)
	draw_rect(Rect2(Vector2(0, 0), size), Color("#000000", 0.24), true)
	draw_rect(Rect2(PANEL_RECT.position + Vector2(12, 16), PANEL_RECT.size), Color("#000000", 0.38), true)
	_draw_panel()
	_draw_text(UiText.t("pause.abandon_title") if confirming_abandon else UiText.t("pause.title"), TITLE_POS, 36, RED if confirming_abandon else INK)
	_draw_text(_confirm_label() if confirming_abandon else _phase_label(), BODY_POS, 15, Color(INK, 0.62))
	_draw_divider()
	_draw_button_skins()

func _build_buttons() -> void:
	var specs := [
		["resume", "pause.resume", true],
		["settings", "pause.settings", false],
		["main_menu", "pause.main_menu", false],
		["abandon_run", "pause.abandon", false]
	]
	for i in range(specs.size()):
		var spec: Array = specs[i]
		var button := Button.new()
		var action := str(spec[0])
		button.name = "Pause_" + action
		button.text = UiText.t(str(spec[1]))
		button.position = Vector2(504, 292 + i * 66)
		button.size = BUTTON_SIZE
		_apply_transparent_button(button, bool(spec[2]))
		button.pressed.connect(_request_action.bind(action))
		button.mouse_entered.connect(func() -> void: queue_redraw())
		button.mouse_exited.connect(func() -> void: queue_redraw())
		add_child(button)
		buttons[action] = button

func _refresh_buttons() -> void:
	for action in buttons.keys():
		var button := buttons[action] as Button
		if button == null:
			continue
		button.disabled = false
		button.visible = true
	if confirming_abandon:
		(buttons["resume"] as Button).text = UiText.t("pause.return")
		(buttons["settings"] as Button).visible = false
		(buttons["main_menu"] as Button).visible = false
		(buttons["abandon_run"] as Button).text = UiText.t("pause.confirm_abandon")
	else:
		(buttons["resume"] as Button).text = UiText.t("pause.resume")
		(buttons["settings"] as Button).text = UiText.t("pause.settings")
		(buttons["main_menu"] as Button).text = UiText.t("pause.main_menu")
		(buttons["abandon_run"] as Button).text = UiText.t("pause.abandon")

func _request_action(action: String) -> void:
	if action == "abandon_run" and not confirming_abandon:
		confirming_abandon = true
		_refresh_buttons()
		queue_redraw()
		return
	if action == "resume" and confirming_abandon:
		confirming_abandon = false
		_refresh_buttons()
		queue_redraw()
		return
	action_requested.emit(action)

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if confirming_abandon:
				confirming_abandon = false
				_refresh_buttons()
				queue_redraw()
			else:
				action_requested.emit("resume")
			accept_event()
	elif event is InputEventMouseMotion:
		queue_redraw()

func _phase_label() -> String:
	if phase == "map":
		return UiText.t("pause.phase.map")
	if phase == "combat":
		return UiText.t("pause.phase.combat")
	if phase == "reward":
		return UiText.t("pause.phase.reward")
	if phase == "event":
		return UiText.t("pause.phase.event")
	if phase == "shop":
		return UiText.t("pause.phase.shop")
	if phase == "rest":
		return UiText.t("pause.phase.rest")
	return UiText.t("pause.phase.default")

func _confirm_label() -> String:
	return UiText.t("pause.confirm_label")

func _draw_panel() -> void:
	var texture_id := "confirm_abandon_panel" if confirming_abandon else "menu_panel"
	var texture := AssetCatalog.shell_pause_texture(texture_id)
	if texture != null:
		draw_texture_rect(texture, PANEL_RECT, false, Color.WHITE)
	else:
		UiSkin.draw_parchment_card(self, PANEL_RECT, "large", Color(1, 1, 1, 0.96))

func _draw_divider() -> void:
	var texture := AssetCatalog.shell_pause_texture("divider")
	if texture != null:
		draw_texture_rect(texture, DIVIDER_RECT, false, Color(1, 1, 1, 0.82))
	else:
		draw_line(DIVIDER_RECT.position, DIVIDER_RECT.position + Vector2(DIVIDER_RECT.size.x, 0), Color("#6b4b2c", 0.38), 2.0)

func _draw_button_skins() -> void:
	for action in buttons.keys():
		var button := buttons[action] as Button
		if button == null or not button.visible:
			continue
		var texture_id := _button_texture_id(str(action), button)
		var texture := AssetCatalog.shell_pause_texture(texture_id)
		if texture == null:
			continue
		var rect := Rect2(button.position - BUTTON_TEXTURE_PAD, button.size + BUTTON_TEXTURE_PAD * 2.0)
		draw_texture_rect(texture, rect, false, Color.WHITE)

func _button_texture_id(action: String, button: Button) -> String:
	if confirming_abandon and action == "abandon_run":
		return "button_danger"
	if button.is_hovered():
		return "button_primary"
	return "button_primary" if action == "resume" else "button_secondary"

func _apply_transparent_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 21 if primary else 18)
	button.add_theme_font_override("font", ShellText.ui_bold_font())
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color("#fff2c8"))
	button.add_theme_color_override("font_pressed_color", Color("#f7d27a"))
	button.add_theme_color_override("font_disabled_color", Color(TEXT, 0.45))
	var style := _transparent_style()
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_stylebox_override("focus", style)

func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var style := "heading" if font_size >= 30 else "regular"
	ShellText.draw(self, text, pos, font_size, color, -1.0, HORIZONTAL_ALIGNMENT_LEFT, style)
