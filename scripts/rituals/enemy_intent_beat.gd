extends Control

signal completed(result: Dictionary)

const EnemyIntentResolver := preload("res://scripts/systems/enemy_intent_resolver.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TABLE := Color("#161017")
const TEXT := Color("#f7ecd7")
const MUTED := Color("#aeb7c6")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")

var rng := RandomNumberGenerator.new()
var enemy_intent: String = ""
var player_hp: int = 42
var reduction: int = 0
var damage: int = 0
var next_intent: String = ""
var move_id: String = ""
var move_label: String = ""

func configure(payload: Dictionary) -> void:
	enemy_intent = str(payload.get("enemy_intent", UiText.t("ritual.enemy.default_intent")))
	player_hp = int(payload.get("player_hp", 42))
	reduction = int(payload.get("reduction", 0))
	move_id = str(payload.get("move_id", ""))
	move_label = str(payload.get("move_label", ""))
	rng.seed = int(payload.get("seed", Time.get_ticks_usec()))
	damage = int(payload.get("damage_override", max(0, 7 - reduction)))
	next_intent = str(payload.get("next_intent", EnemyIntentResolver.next_intent_text(rng)))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	call_deferred("_auto_finish")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	draw_circle(Vector2(640, 560), 620, Color("#12090c"))
	draw_rect(Rect2(Vector2(270, 120), Vector2(740, 402)), TABLE, true)
	draw_rect(Rect2(Vector2(270, 120), Vector2(740, 402)), RED.darkened(0.18), false, 4.0)
	_draw_text("ENEMY INTENT BEAT", Vector2(352, 132), 34, TEXT)
	_draw_text(enemy_intent, Vector2(354, 190), 20, GOLD)
	if move_label != "":
		_draw_text(move_label, Vector2(354, 232), 18, MUTED)
	_draw_text("Damage " + str(damage), Vector2(470, 302), 46, RED if damage > 0 else MUTED)
	_draw_text("Next: " + next_intent, Vector2(354, 420), 18, MUTED)

func _build_buttons() -> void:
	var button := Button.new()
	button.text = UiText.t("ritual.enemy.apply")
	button.position = Vector2(550, 620)
	button.size = Vector2(180, 72)
	button.pressed.connect(_confirm)
	add_child(button)

func _auto_finish() -> void:
	await get_tree().create_timer(0.9).timeout
	if is_inside_tree():
		_confirm()

func _confirm() -> void:
	completed.emit({
		"accepted": true,
		"move_id": move_id,
		"move_label": move_label,
		"damage": damage,
		"player_hp": max(0, player_hp - damage),
		"next_intent": next_intent,
		"reduction": reduction
	})

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
