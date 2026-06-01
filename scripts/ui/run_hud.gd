class_name RunHud
extends Control

const RunTableState := preload("res://scripts/run/run_table_state.gd")
const RunTableWidgets := preload("res://scripts/ui/run_table_widgets.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const LINE := Color("#495569")
const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const BLUE := Color("#66a8ff")
const RED := Color("#ee5b5b")
const HP := Color("#7dd3ff")
const INK := Color("#090704")
const COMBAT_PREP_RECT := Rect2(Vector2(74, 100), Vector2(284, 60))

var seed_text: String = ""
var turn: int = 1
var cash: int = 0
var banked: int = 0
var busts: int = 0
var player_hp: int = 1
var player_max_hp: int = 1
var enemy_hp: int = 1
var enemy_max_hp: int = 1
var monster_id: String = "debt_collector"
var monster_name: String = "Enemy"
var active_relic_ids: Array[String] = []
var active_prep_mods: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_state(next_state: Dictionary) -> void:
	seed_text = str(next_state.get("seed_text", seed_text))
	turn = int(next_state.get("turn", turn))
	cash = int(next_state.get("cash", cash))
	banked = int(next_state.get("banked", banked))
	busts = int(next_state.get("busts", busts))
	player_hp = int(next_state.get("player_hp", player_hp))
	player_max_hp = max(1, int(next_state.get("player_max_hp", player_max_hp)))
	enemy_hp = int(next_state.get("enemy_hp", enemy_hp))
	enemy_max_hp = max(1, int(next_state.get("enemy_max_hp", enemy_max_hp)))
	monster_id = str(next_state.get("monster_id", monster_id))
	monster_name = str(next_state.get("monster_name", monster_name))
	active_relic_ids = _string_array(next_state.get("active_relic_ids", active_relic_ids))
	active_prep_mods = _mod_array(next_state.get("active_prep_mods", active_prep_mods))
	queue_redraw()

func _draw() -> void:
	var prep_items: Array[Dictionary] = RunTableState.prep_items(active_prep_mods)
	for item in prep_items:
		item["state"] = "applied"
	if not prep_items.is_empty():
		RunTableWidgets.draw_prep_notes(self, COMBAT_PREP_RECT, prep_items, UiText.t("overlay.applied_notes"))

func _meter(rect: Rect2, ratio: float, color: Color) -> void:
	var clamped: float = clamp(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#1b1009", 0.6), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped, rect.size.y)), color, true)
	draw_rect(rect, Color(INK, 0.34), false, 1.0)

func _text(text: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, align, width, font_size, color)

func _short_seed() -> String:
	if seed_text.length() <= 22:
		return seed_text
	return seed_text.left(19) + "..."

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

func _mod_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result
