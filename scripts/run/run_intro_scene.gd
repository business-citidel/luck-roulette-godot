extends Control

signal completed(result: Dictionary)

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const INK := Color("#090704")

var elapsed: float = 0.0
var auto_duration: float = 0.82
var finished: bool = false
var run_state: Dictionary = {}

func configure(payload: Dictionary) -> void:
	run_state = payload.duplicate(true)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	queue_redraw()
	if elapsed >= auto_duration:
		_finish_intro()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	var t: float = clamp(elapsed / max(auto_duration, 0.01), 0.0, 1.0)
	_draw_table_backdrop()
	UiSkin.draw_parchment_card(self, Rect2(Vector2(344, 174), Vector2(592, 312)), "large")
	_draw_icon("pouch", Rect2(454, 282, 78, 78), 0.72)
	_draw_icon("dice", Rect2(594, 248, 92, 92), 0.84)
	_draw_icon("roulette", Rect2(748, 282, 78, 78), 0.72)
	_draw_text(UiText.t("intro.title"), Vector2(512, 404), 34, INK)
	_draw_text(UiText.t("intro.subtitle"), Vector2(488, 440), 18, Color(INK, 0.66))
	_draw_deal_progress(t)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_finish_intro()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_finish_intro()

func _finish_intro() -> void:
	if finished:
		return
	finished = true
	completed.emit({
		"accepted": true,
		"action": "intro_complete"
	})

func _draw_icon(prop_id: String, rect: Rect2, alpha: float) -> void:
	var texture: Texture2D = AssetCatalog.prop_icon(prop_id)
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))

func _draw_table_backdrop() -> void:
	draw_rect(Rect2(Vector2(54, 66), Vector2(1172, 590)), Color("#130b08"), true)
	draw_rect(Rect2(Vector2(76, 88), Vector2(1128, 546)), Color("#26170f", 0.96), true)
	draw_rect(Rect2(Vector2(76, 88), Vector2(1128, 546)), Color("#8a642f", 0.5), false, 3.0)
	draw_circle(Vector2(640, 356), 260.0, Color("#080604", 0.18))
	for i in range(7):
		var y := 112.0 + float(i) * 72.0
		draw_line(Vector2(92, y), Vector2(1180, y + 22.0), Color("#5d371f", 0.15), 18.0)

func _draw_deal_progress(t: float) -> void:
	var start := Vector2(450, 548)
	var end := Vector2(830, 548)
	UiSkin.draw_route_cord(self, start, end, Color(1, 1, 1, 0.42), 7.0)
	for i in range(5):
		var ratio := float(i) / 4.0
		var pos := start.lerp(end, ratio)
		var active := t >= ratio - 0.02
		var tint := Color(GOLD, 0.86) if active else Color("#5e4931", 0.54)
		UiSkin.draw_coin_marker(self, pos, 14.0, tint)
	_draw_text(UiText.t("intro.progress"), Vector2(586, 590), 15, Color(TEXT, 0.72))

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
