class_name OpponentLayer
extends Control

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const MonsterMoveCatalog := preload("res://scripts/systems/monster_move_catalog.gd")
const UiSkin := preload("res://scripts/ui/ui_skin.gd")
const UiLayoutSpec := preload("res://scripts/ui/ui_layout_spec.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const TEXT := Color("#f6efe2")
const MUTED := Color("#aab4c3")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")
const INK := Color("#090704")

var enemy_hp: int = 1
var enemy_max_hp: int = 1
var monster_id: String = "debt_collector"
var monster_name: String = "HOUSE WARDEN"
var monster_pattern_tuning: Dictionary = {}
var enemy_intent: String = ""
var current_move_id: String = "hp_strike"
var enemy_flash: float = 0.0
var player_flash: float = 0.0
var opponent_reaction: float = 0.0
var opponent_mood: String = "watching"

func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(next_state: Dictionary) -> void:
	enemy_hp = int(next_state.get("enemy_hp", enemy_hp))
	enemy_max_hp = max(1, int(next_state.get("enemy_max_hp", enemy_max_hp)))
	monster_id = str(next_state.get("monster_id", monster_id))
	monster_name = str(next_state.get("monster_name", monster_name))
	monster_pattern_tuning = _dict(next_state.get("monster_pattern_tuning", monster_pattern_tuning))
	enemy_intent = str(next_state.get("enemy_intent", enemy_intent))
	current_move_id = str(next_state.get("current_move_id", current_move_id))
	enemy_flash = float(next_state.get("enemy_flash", enemy_flash))
	player_flash = float(next_state.get("player_flash", player_flash))
	opponent_reaction = float(next_state.get("opponent_reaction", opponent_reaction))
	opponent_mood = str(next_state.get("opponent_mood", opponent_mood))
	queue_redraw()

func _draw() -> void:
	var seat := Rect2(414, 96, 452, 104)
	draw_rect(seat.grow(-8.0), Color("#24160d", 0.42), true)
	UiSkin.draw_prompt_strip(self, seat, Color(1, 1, 1, 0.68))
	var center: Vector2 = Vector2(496, 150)
	var shake: Vector2 = Vector2(sin(float(Time.get_ticks_msec()) * 0.09) * 10.0 * opponent_reaction, 0.0)
	center += shake
	draw_circle(center, 52.0 + enemy_flash * 10.0, Color(RED, 0.22 * enemy_flash))
	_draw_opponent_token(center)
	_text(monster_name.to_upper(), Vector2(568, 126), 18, INK, 210.0)
	_meter(Rect2(568, 146, 168, 9), float(enemy_hp) / float(enemy_max_hp), RED)
	_text("HP " + str(enemy_hp) + "/" + str(enemy_max_hp), Vector2(568, 172), 14, Color("#6b1115"))
	_draw_intent_card(Rect2(Vector2(734, 120), Vector2(118, 58)))
	draw_line(center + Vector2(-38, 38), center + Vector2(38, 38), Color("#20100c"), 5.0 + opponent_reaction * 2.4)
	if opponent_mood == "press":
		draw_circle(center + Vector2(-42, 38), 8.0 + opponent_reaction * 7.0, Color(GOLD, 0.35 * opponent_reaction))
		draw_circle(center + Vector2(42, 38), 8.0 + opponent_reaction * 7.0, Color(GOLD, 0.35 * opponent_reaction))

	if player_flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(RED, 0.12 * player_flash), true)

func _draw_opponent_token(center: Vector2) -> void:
	draw_rect(Rect2(center.x - 49.0, center.y - 62.0, 98.0, 108.0), Color("#6f4723", 0.78), true)
	draw_rect(Rect2(center.x - 43.0, center.y - 56.0, 86.0, 94.0), Color("#1e1614"), true)
	draw_rect(Rect2(center.x - 45.0, center.y - 58.0, 90.0, 98.0), GOLD if monster_name.to_lower().contains("final") else Color("#463629"), false, 3.0)
	var texture: Texture2D = AssetCatalog.monster_texture(monster_id)
	if texture != null:
		var region: Rect2 = AssetCatalog.monster_region(monster_id)
		var target := Rect2(center.x - 40.0, center.y - 51.0, 80.0, 80.0)
		draw_texture_rect_region(texture, target, region)
		return
	draw_circle(center + Vector2(0, -34), 52.0, Color("#b98255"))
	draw_rect(Rect2(center.x - 44.0, center.y + 18.0, 88.0, 82.0), Color("#3a2119"), true)
	draw_circle(center + Vector2(-20, -42), 6.0, RED if opponent_mood != "hit" else Color("#f3e0b2"))
	draw_circle(center + Vector2(20, -42), 6.0, RED if opponent_mood != "hit" else Color("#f3e0b2"))
	if opponent_mood == "smirk":
		draw_arc(center + Vector2(0, -22), 24.0, 0.2, 2.9, 24, Color("#2b120e"), 4.0)
	elif opponent_mood == "hit":
		draw_line(center + Vector2(-24, -20), center + Vector2(24, -14), Color("#2b120e"), 4.0)
	else:
		draw_rect(Rect2(center.x - 30.0, center.y - 20.0, 60.0, 6.0), Color("#2b120e"), true)

func _draw_intent_card(rect: Rect2) -> void:
	var move: Dictionary = MonsterMoveCatalog.tuned_move(current_move_id, monster_pattern_tuning)
	var intent := enemy_intent
	if intent == "":
		intent = MonsterMoveCatalog.intent_text(current_move_id, monster_pattern_tuning)
	var intent_color := _intent_color(str(move.get("intent", "attack")))
	UiSkin.draw_resource_ledger(self, rect, Color(1, 1, 1, 0.82))
	_text(UiText.t("battle.layer.next"), rect.position + Vector2(14, 22), 11, Color(INK, 0.56))
	_text(intent, rect.position + Vector2(14, 43), 12, intent_color, rect.size.x - 28.0)

func _intent_color(intent: String) -> Color:
	if intent.contains("tax"):
		return GOLD
	if intent.contains("guard"):
		return Color("#23548a")
	if intent.contains("buff") or intent.contains("curse") or intent.contains("disrupt"):
		return Color("#4a2478")
	return Color("#6b1115")

func _opponent_caption() -> String:
	if opponent_mood == "smirk":
		return UiText.t("battle.caption.smirk")
	if opponent_mood == "hit":
		return UiText.t("battle.caption.hit")
	if opponent_mood == "press":
		return UiText.t("battle.caption.press")
	return UiText.t("battle.caption.watch")

func _meter(rect: Rect2, ratio: float, color: Color) -> void:
	var clamped: float = clamp(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#07090d"), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped, rect.size.y)), color, true)
	draw_rect(rect, Color(TEXT, 0.18), false, 1.0)

func _text(text: String, pos: Vector2, font_size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, align, width, font_size, color)

func _dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
