extends Control

signal completed(result: Dictionary)

const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")
const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const ShellText := preload("res://scripts/ui/shell_text.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const PANEL := Color("#111823")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const GREEN := Color("#65d48e")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

const LEDGER_RECT := Rect2(Vector2(300, 224), Vector2(680, 276))
const STAT_RECTS := [
	Rect2(Vector2(278, 500), Vector2(150, 88)),
	Rect2(Vector2(452, 500), Vector2(150, 88)),
	Rect2(Vector2(626, 500), Vector2(150, 88)),
	Rect2(Vector2(800, 500), Vector2(150, 88))
]
const RESTART_BUTTON_RECT := Rect2(Vector2(392, 604), Vector2(224, 58))
const TITLE_BUTTON_RECT := Rect2(Vector2(664, 604), Vector2(224, 58))
const BUTTON_TEXTURE_PAD := Vector2(22, 14)

var result_type: String = "run_clear"
var run_state: Dictionary = {}
var run_stats: Dictionary = {}
var combat_result: Dictionary = {}
var last_encounter_payload: Dictionary = {}
var completed_node_count: int = 0
var restart_button: Button
var title_button: Button
var submitted := false

func configure(payload: Dictionary) -> void:
	result_type = str(payload.get("result_type", "run_clear"))
	run_state = payload.get("run_state", {}).duplicate(true)
	run_stats = payload.get("run_stats", {}).duplicate(true)
	combat_result = payload.get("combat_result", {}).duplicate(true)
	last_encounter_payload = payload.get("last_encounter_payload", {}).duplicate(true)
	completed_node_count = int(payload.get("completed_node_count", (run_state.get("completed_nodes", []) as Array).size()))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	var board := _result_board_texture()
	var accent := GREEN if result_type == "run_clear" else RED
	var title := UiText.t("run_end.clear_title") if result_type == "run_clear" else UiText.t("run_end.fail_title")
	if board != null:
		draw_texture_rect(board, Rect2(Vector2.ZERO, size), false, Color.WHITE)
		_draw_board_result_text(title, accent)
	else:
		_draw_table_backdrop()
		_draw_text(title, Vector2(334, 142), 48, Color(accent, 0.96))
		_draw_text(_subtitle(), Vector2(344, 190), 18, INK)
		_draw_ledger_panel()
		_draw_ledger_text()
		_draw_stats()
		_draw_button_skins()

func _build_buttons() -> void:
	restart_button = Button.new()
	restart_button.text = UiText.t("run_end.restart")
	restart_button.position = RESTART_BUTTON_RECT.position
	restart_button.size = RESTART_BUTTON_RECT.size
	_apply_transparent_button(restart_button, true)
	restart_button.pressed.connect(_restart_run)
	restart_button.mouse_entered.connect(func() -> void: queue_redraw())
	restart_button.mouse_exited.connect(func() -> void: queue_redraw())
	add_child(restart_button)
	title_button = Button.new()
	title_button.text = UiText.t("run_end.main_menu")
	title_button.position = TITLE_BUTTON_RECT.position
	title_button.size = TITLE_BUTTON_RECT.size
	_apply_transparent_button(title_button, false)
	title_button.pressed.connect(_return_to_title)
	title_button.mouse_entered.connect(func() -> void: queue_redraw())
	title_button.mouse_exited.connect(func() -> void: queue_redraw())
	add_child(title_button)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_restart_run()
		elif event.keycode == KEY_ESCAPE:
			_return_to_title()

func _restart_run() -> void:
	if submitted:
		return
	submitted = true
	restart_button.disabled = true
	title_button.disabled = true
	completed.emit({
		"accepted": true,
		"action": "restart_run",
		"result_type": result_type
	})

func _return_to_title() -> void:
	if submitted:
		return
	submitted = true
	restart_button.disabled = true
	title_button.disabled = true
	completed.emit({
		"accepted": true,
		"action": "main_menu",
		"result_type": result_type
	})

func _subtitle() -> String:
	if result_type == "run_clear":
		return UiText.t("run_end.clear_subtitle")
	return UiText.t("run_end.fail_subtitle")

func _relic_summary() -> String:
	var relic_ids: Array = run_state.get("relic_ids", []) as Array
	if relic_ids.is_empty():
		return UiText.t("fallback.none")
	var summary := RelicCatalog.display_names(relic_ids, 4)
	if summary == "":
		return UiText.t("fallback.none")
	return summary

func _character_label() -> String:
	var character_id := str(run_stats.get("character_id", run_state.get("character_id", "")))
	if character_id == "double_attack_dice":
		return UiText.t("run_end.character.double_attack")
	return UiText.t("run_end.character.default")

func _draw_table_backdrop() -> void:
	draw_rect(Rect2(Vector2(54, 66), Vector2(1172, 590)), Color("#130b08"), true)
	draw_rect(Rect2(Vector2(76, 88), Vector2(1128, 546)), Color("#26170f", 0.96), true)
	draw_rect(Rect2(Vector2(76, 88), Vector2(1128, 546)), Color("#8a642f", 0.5), false, 3.0)
	for i in range(7):
		var y := 112.0 + float(i) * 72.0
		draw_line(Vector2(92, y), Vector2(1180, y + 22.0), Color("#5d371f", 0.15), 18.0)

func _result_board_texture() -> Texture2D:
	var texture_id := "board_clear" if result_type == "run_clear" else "board_failed"
	return AssetCatalog.shell_result_texture(texture_id)

func _draw_ledger_panel() -> void:
	var texture := AssetCatalog.shell_result_texture("ledger_panel")
	if texture != null:
		draw_texture_rect(texture, LEDGER_RECT, false, Color(1, 1, 1, 0.96))
	else:
		UiSkin.draw_ledger_slip(self, LEDGER_RECT, Color(1, 1, 1, 0.96))

func _draw_ledger_text() -> void:
	_draw_text(UiText.t("run_end.final_hp", {"hp": run_state.get("player_hp", combat_result.get("player_hp", 0)), "max_hp": run_state.get("player_max_hp", 42)}), Vector2(342, 278), 23, Color("#6b1115"))
	_draw_text(UiText.t("run_end.gold", {"gold": run_state.get("gold", 0)}), Vector2(586, 278), 23, Color("#8a5f12"))
	_draw_text(UiText.t("run_end.relics", {"count": (run_state.get("relic_ids", []) as Array).size(), "summary": _relic_summary()}), Vector2(342, 322), 16, Color(INK, 0.72))
	_draw_text(UiText.t("run_end.nodes_cleared", {"count": completed_node_count}), Vector2(342, 356), 15, Color(INK, 0.68))
	_draw_text(UiText.t("run_end.winnings", {"amount": combat_result.get("winnings", combat_result.get("combat_cash", combat_result.get("cash", 0)))}), Vector2(640, 356), 15, Color("#8a5f12"))
	_draw_text(UiText.t("run_end.stats.character_floor", {
		"character": _character_label(),
		"floor": run_stats.get("floor_reached", run_state.get("floor_index", 1)),
		"max_floor": run_state.get("max_floor", 3)
	}), Vector2(342, 392), 15, Color(INK, 0.76))
	_draw_text(UiText.t("run_end.stats.seed", {"seed": run_stats.get("seed_text", run_state.get("seed_text", ""))}), Vector2(342, 426), 13, Color(INK, 0.58))

func _draw_board_result_text(title: String, accent: Color) -> void:
	var title_color := Color("#356f53") if result_type == "run_clear" else Color("#8b2228")
	ShellText.draw_fit(self, title, Rect2(Vector2(338, 94), Vector2(300, 52)), 46, title_color, 28, HORIZONTAL_ALIGNMENT_LEFT, "heading")
	ShellText.draw_fit(self, _subtitle(), Rect2(Vector2(344, 168), Vector2(592, 30)), 18, INK, 13, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, UiText.t("run_end.final_hp", {"hp": run_state.get("player_hp", combat_result.get("player_hp", 0)), "max_hp": run_state.get("player_max_hp", 42)}), Rect2(Vector2(344, 250), Vector2(206, 34)), 22, Color("#6b1115"), 15, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, UiText.t("run_end.gold", {"gold": run_state.get("gold", 0)}), Rect2(Vector2(590, 250), Vector2(164, 34)), 22, Color("#8a5f12"), 15, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, UiText.t("run_end.relics", {"count": (run_state.get("relic_ids", []) as Array).size(), "summary": _relic_summary()}), Rect2(Vector2(344, 300), Vector2(460, 26)), 16, Color(INK, 0.72), 11, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	ShellText.draw_fit(self, UiText.t("run_end.nodes_cleared", {"count": completed_node_count}), Rect2(Vector2(344, 334), Vector2(220, 24)), 15, Color(INK, 0.68), 11, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	ShellText.draw_fit(self, UiText.t("run_end.winnings", {"amount": combat_result.get("winnings", combat_result.get("combat_cash", combat_result.get("cash", 0)))}), Rect2(Vector2(642, 334), Vector2(200, 24)), 15, Color("#8a5f12"), 11, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	ShellText.draw_fit(self, UiText.t("run_end.stats.character_floor", {
		"character": _character_label(),
		"floor": run_stats.get("floor_reached", run_state.get("floor_index", 1)),
		"max_floor": run_state.get("max_floor", 3)
	}), Rect2(Vector2(344, 368), Vector2(420, 24)), 15, Color(INK, 0.76), 11, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	ShellText.draw_fit(self, UiText.t("run_end.stats.seed", {"seed": run_stats.get("seed_text", run_state.get("seed_text", ""))}), Rect2(Vector2(344, 400), Vector2(420, 22)), 13, Color(INK, 0.58), 10, HORIZONTAL_ALIGNMENT_LEFT, "regular")
	_draw_board_stat(Rect2(Vector2(294, 526), Vector2(132, 42)), str(run_stats.get("battles_won", 0)), UiText.t("run_end.stats.label.battles"))
	_draw_board_stat(Rect2(Vector2(474, 526), Vector2(132, 42)), str(completed_node_count), UiText.t("run_end.stats.label.nodes"))
	_draw_board_stat(Rect2(Vector2(654, 526), Vector2(132, 42)), str(run_stats.get("events_resolved", 0)), UiText.t("run_end.stats.label.route"))
	_draw_board_stat(Rect2(Vector2(840, 526), Vector2(132, 42)), str(run_state.get("gold", 0)), UiText.t("run_end.stats.label.gold"))

func _draw_board_stat(rect: Rect2, value: String, label: String) -> void:
	var text_rect := Rect2(rect.position + Vector2(44, 7), Vector2(rect.size.x - 54, 18))
	var label_rect := Rect2(rect.position + Vector2(44, 26), Vector2(rect.size.x - 54, 14))
	ShellText.draw_fit_shadow(self, value, text_rect, 18, TEXT, 12, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit_shadow(self, label.to_upper(), label_rect, 10, Color(TEXT, 0.76), 8, HORIZONTAL_ALIGNMENT_LEFT, "regular")

func _draw_stats() -> void:
	var specs := [
		{"texture": "stat_battle", "top": str(run_stats.get("battles_won", 0)), "bottom": UiText.t("run_end.stats.battle_line", {"battles": run_stats.get("battles_won", 0), "elites": run_stats.get("elites_defeated", 0), "bosses": run_stats.get("bosses_defeated", 0)})},
		{"texture": "stat_boss", "top": str(run_stats.get("bosses_defeated", 0)), "bottom": UiText.t("run_end.stats.character_floor", {"character": _character_label(), "floor": run_stats.get("floor_reached", run_state.get("floor_index", 1)), "max_floor": run_state.get("max_floor", 3)})},
		{"texture": "stat_event", "top": str(completed_node_count), "bottom": UiText.t("run_end.stats.route_line", {"events": run_stats.get("events_resolved", 0), "shops": run_stats.get("shops_visited", 0), "rests": run_stats.get("rests_used", 0)})},
		{"texture": "stat_gold", "top": str(run_state.get("gold", 0)), "bottom": UiText.t("run_end.gold", {"gold": run_state.get("gold", 0)})}
	]
	for i in range(min(specs.size(), STAT_RECTS.size())):
		var spec: Dictionary = specs[i]
		_draw_stat_badge(STAT_RECTS[i], str(spec.get("texture", "")), str(spec.get("top", "")), str(spec.get("bottom", "")))

func _draw_stat_badge(rect: Rect2, texture_id: String, top: String, bottom: String) -> void:
	var texture := AssetCatalog.shell_result_texture(texture_id)
	if texture != null:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.92))
	else:
		UiSkin.draw_ledger_slip(self, rect, Color(1, 1, 1, 0.86))
	ShellText.draw_fit(self, top, Rect2(rect.position + Vector2(18, 18), Vector2(rect.size.x - 36, 28)), 22, INK, 14, HORIZONTAL_ALIGNMENT_LEFT, "bold")
	ShellText.draw_fit(self, bottom, Rect2(rect.position + Vector2(18, 48), Vector2(rect.size.x - 36, 18)), 10, Color(INK, 0.62), 8, HORIZONTAL_ALIGNMENT_LEFT, "regular")

func _draw_button_skins() -> void:
	_draw_button_skin(restart_button, "button_restart")
	_draw_button_skin(title_button, "button_main_table")

func _draw_button_skin(button: Button, texture_id: String) -> void:
	if button == null:
		return
	var texture := AssetCatalog.shell_result_texture(texture_id)
	if texture == null:
		return
	var rect := Rect2(button.position - BUTTON_TEXTURE_PAD, button.size + BUTTON_TEXTURE_PAD * 2.0)
	draw_texture_rect(texture, rect, false, Color.WHITE)

func _apply_transparent_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 20 if primary else 18)
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
	var style := "heading" if font_size >= 34 else ("bold" if font_size >= 18 else "regular")
	ShellText.draw(self, text, pos, font_size, color, -1.0, HORIZONTAL_ALIGNMENT_LEFT, style)

func _draw_icon(node_type: String, rect: Rect2, tint: Color = Color(1, 1, 1, 0.72)) -> void:
	var texture: Texture2D = AssetCatalog.node_icon(node_type)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)
