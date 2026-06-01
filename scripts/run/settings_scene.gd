extends Control

signal completed(result: Dictionary)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const DemoSettingsService := preload("res://scripts/systems/demo_settings_service.gd")
const ShellText := preload("res://scripts/ui/shell_text.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TEXT := Color("#f6efe2")
const INK := Color("#090704")
const GOLD := Color("#f2be4b")

const SLIDER_RECTS := {
	"master_volume": Rect2(Vector2(514, 246), Vector2(330, 40)),
	"bgm_volume": Rect2(Vector2(514, 302), Vector2(330, 40)),
	"sfx_volume": Rect2(Vector2(514, 358), Vector2(330, 40))
}
const TOGGLE_RECT := Rect2(Vector2(646, 410), Vector2(74, 44))
const BACK_BUTTON_RECT := Rect2(Vector2(548, 560), Vector2(184, 54))
const BUTTON_TEXTURE_PAD := Vector2(18, 12)

var settings: Dictionary = {}
var back_button: Button
var fullscreen_button: CheckButton
var sliders: Dictionary = {}
var language_buttons: Dictionary = {}

func configure(payload: Dictionary) -> void:
	var _ignored := payload
	settings = DemoSettingsService.load_settings()
	DemoSettingsService.apply_settings(settings)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if settings.is_empty():
		settings = DemoSettingsService.load_settings()
	_build_controls()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	UiSkin.draw_table_stage(self, Rect2(Vector2(120, 70), Vector2(1040, 570)), Rect2(Vector2(152, 106), Vector2(976, 498)), Color(1, 1, 1, 0.96))
	UiSkin.draw_parchment_card(self, Rect2(Vector2(304, 104), Vector2(672, 456)), "large", Color(1, 1, 1, 0.94))
	_draw_text(UiText.t("settings.title"), Vector2(392, 166), 36, INK)
	_draw_text(UiText.t("settings.subtitle"), Vector2(394, 200), 16, Color(INK, 0.62))
	_draw_text(UiText.t("settings.master"), Vector2(394, 266), 16, INK)
	_draw_text(UiText.t("settings.bgm"), Vector2(394, 322), 16, INK)
	_draw_text(UiText.t("settings.sfx"), Vector2(394, 378), 16, INK)
	_draw_text(UiText.t("settings.fullscreen"), Vector2(394, 434), 16, INK)
	_draw_text(UiText.t("settings.language"), Vector2(394, 494), 16, INK)
	_draw_custom_sliders()
	_draw_custom_toggle()
	_draw_back_button_skin()

func _build_controls() -> void:
	_add_slider("master_volume", Vector2(520, 244), float(settings.get("master_volume", 1.0)))
	_add_slider("bgm_volume", Vector2(520, 300), float(settings.get("bgm_volume", 0.82)))
	_add_slider("sfx_volume", Vector2(520, 356), float(settings.get("sfx_volume", 0.9)))

	fullscreen_button = CheckButton.new()
	fullscreen_button.name = "SettingsFullscreenToggle"
	fullscreen_button.position = Vector2(520, 408)
	fullscreen_button.size = Vector2(210, 48)
	fullscreen_button.button_pressed = bool(settings.get("fullscreen", false))
	fullscreen_button.modulate = Color(1, 1, 1, 0.01)
	fullscreen_button.toggled.connect(func(value: bool) -> void: _set_value("fullscreen", value))
	add_child(fullscreen_button)

	_add_language_button("ko", Vector2(520, 480))
	_add_language_button("en", Vector2(654, 480))

	back_button = Button.new()
	back_button.name = "SettingsBackButton"
	back_button.position = BACK_BUTTON_RECT.position
	back_button.size = BACK_BUTTON_RECT.size
	_apply_transparent_button(back_button, true)
	back_button.pressed.connect(_close)
	back_button.mouse_entered.connect(func() -> void: queue_redraw())
	back_button.mouse_exited.connect(func() -> void: queue_redraw())
	add_child(back_button)
	_refresh_text()

func _add_slider(key: String, pos: Vector2, value: float) -> void:
	var slider := HSlider.new()
	slider.name = "SettingsSlider_" + key
	slider.position = pos
	slider.size = Vector2(318, 34)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.modulate = Color(1, 1, 1, 0.01)
	slider.value_changed.connect(func(next_value: float) -> void: _set_value(key, next_value))
	add_child(slider)
	sliders[key] = slider

func _add_language_button(language: String, pos: Vector2) -> void:
	var button := Button.new()
	button.name = "SettingsLanguage_" + language
	button.position = pos
	button.size = Vector2(120, 42)
	button.pressed.connect(_set_language.bind(language))
	button.add_theme_font_override("font", ShellText.ui_bold_font())
	add_child(button)
	language_buttons[language] = button

func _set_value(key: String, value: Variant) -> void:
	settings = DemoSettingsService.update_value(key, value)
	queue_redraw()

func _set_language(language: String) -> void:
	settings = DemoSettingsService.update_value("language", language)
	_refresh_text()
	queue_redraw()

func _refresh_text() -> void:
	if fullscreen_button != null:
		fullscreen_button.text = UiText.t("settings.fullscreen_on")
	if back_button != null:
		back_button.text = UiText.t("settings.back")
	for language in language_buttons.keys():
		var button := language_buttons[language] as Button
		if button == null:
			continue
		button.text = UiText.t("settings.language." + str(language))
		UiSkin.apply_button(button, str(settings.get("language", "ko")) == str(language))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_close()

func _close() -> void:
	completed.emit({"accepted": true, "action": "settings_closed"})

func _draw_custom_sliders() -> void:
	for key in SLIDER_RECTS.keys():
		var rect: Rect2 = SLIDER_RECTS[key]
		var track := AssetCatalog.shell_settings_texture("slider_track")
		if track != null:
			draw_texture_rect(track, rect, false, Color(1, 1, 1, 0.90))
		else:
			draw_line(rect.position + Vector2(0, rect.size.y * 0.5), rect.position + Vector2(rect.size.x, rect.size.y * 0.5), Color("#7c633e"), 5.0)
		var slider := sliders.get(key) as HSlider
		var value := float(settings.get(key, slider.value if slider != null else 0.0))
		var knob := AssetCatalog.shell_settings_texture("slider_knob")
		var knob_center := rect.position + Vector2(rect.size.x * clamp(value, 0.0, 1.0), rect.size.y * 0.5)
		if knob != null:
			draw_texture_rect(knob, Rect2(knob_center - Vector2(22, 22), Vector2(44, 44)), false, Color.WHITE)
		else:
			draw_circle(knob_center, 12.0, GOLD)

func _draw_custom_toggle() -> void:
	var texture_id := "toggle_on" if bool(settings.get("fullscreen", false)) else "toggle_off"
	var texture := AssetCatalog.shell_settings_texture(texture_id)
	if texture != null:
		draw_texture_rect(texture, TOGGLE_RECT, false, Color.WHITE)
	_draw_text(UiText.t("settings.fullscreen_on"), Vector2(526, 438), 14, INK)

func _draw_back_button_skin() -> void:
	var texture := AssetCatalog.shell_settings_texture("button_back")
	if texture == null or back_button == null:
		return
	var rect := Rect2(back_button.position - BUTTON_TEXTURE_PAD, back_button.size + BUTTON_TEXTURE_PAD * 2.0)
	draw_texture_rect(texture, rect, false, Color.WHITE)

func _apply_transparent_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18 if primary else 15)
	button.add_theme_font_override("font", ShellText.ui_bold_font())
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color("#fff2c8"))
	button.add_theme_color_override("font_pressed_color", Color("#f7d27a"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_stylebox_override("focus", style)

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var style := "heading" if font_size >= 30 else "regular"
	ShellText.draw(self, text, pos, font_size, color, -1.0, HORIZONTAL_ALIGNMENT_LEFT, style)
