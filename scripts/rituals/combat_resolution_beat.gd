extends Control

signal completed(result: Dictionary)

const PayoutResolver := preload("res://scripts/systems/payout_resolver.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

const BG := Color("#05070d")
const TABLE := Color("#1a100b")
const TEXT := Color("#f7ecd7")
const MUTED := Color("#aeb7c6")
const GOLD := Color("#f2be4b")
const RED := Color("#ee5b5b")
const GREEN := Color("#65d48e")

var payload: Dictionary = {}
var outcome: Dictionary = {}
var pending_slot: String = ""
var damage: int = 0
var bust_delta: int = 0
var cash_delta: int = 0
var message: String = ""
var auto_finish_started: bool = false

var continue_button: Button

func configure(next_payload: Dictionary) -> void:
	payload = next_payload.duplicate(true)
	pending_slot = str(payload.get("pending_slot", "safe"))
	var placed_slots: Dictionary = payload.get("placed_slots", {})
	var cash: int = int(payload.get("cash", 0))
	var player_hp: int = int(payload.get("player_hp", 42))
	var enemy_hp: int = int(payload.get("enemy_hp", 92))
	var enemy_block: int = int(payload.get("enemy_block", 0))
	var attack_base: int = int(payload.get("attack_base", 0))
	var player_damage_multiplier: float = float(payload.get("player_damage_multiplier", 1.0))
	var damage_multiplier: float = float(payload.get("damage_multiplier", payload.get("payout_multiplier", 1.0)))
	var flat_damage_bonus: int = int(payload.get("flat_damage_bonus", 0))
	var cash_delta_bonus: int = int(payload.get("cash_delta_bonus", 0))
	outcome = PayoutResolver.resolve(pending_slot, placed_slots, cash, player_hp, enemy_hp, damage_multiplier, attack_base, flat_damage_bonus, cash_delta_bonus, enemy_block, player_damage_multiplier)
	damage = int(outcome.get("damage", 0))
	bust_delta = int(outcome.get("bust_delta", 0))
	cash_delta = int(outcome.get("cash_delta", 0))
	message = str(outcome.get("message", UiText.t("ritual.resolution.default_message")))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_buttons()
	queue_redraw()
	if not auto_finish_started:
		auto_finish_started = true
		call_deferred("_auto_finish")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	draw_circle(Vector2(640, 560), 620, Color("#130b08"))
	draw_rect(Rect2(Vector2(240, 104), Vector2(800, 444)), TABLE, true)
	draw_rect(Rect2(Vector2(240, 104), Vector2(800, 444)), GOLD.darkened(0.24), false, 4.0)
	_draw_text("COMBAT RESOLUTION", Vector2(318, 112), 34, TEXT)
	_draw_text(UiText.t("ritual.resolution.formula"), Vector2(320, 150), 16, MUTED)
	var banner: String = str(outcome.get("banner", pending_slot.to_upper()))
	_draw_text(banner, Vector2(448, 246), 54, GOLD if bust_delta == 0 else RED)
	_draw_text(message, Vector2(340, 426), 20, TEXT)
	if damage > 0:
		_draw_text("Damage " + str(damage), Vector2(380, 330), 34, RED)
	if cash_delta != 0:
		_draw_text(("Cash +" if cash_delta > 0 else "Cash ") + str(cash_delta), Vector2(575, 330), 34, GREEN if cash_delta >= 0 else RED)
	if bust_delta > 0:
		_draw_text("Bust +" + str(bust_delta), Vector2(760, 330), 34, RED)
	_draw_text(UiText.t("ritual.resolution.return_note"), Vector2(452, 592), 18, MUTED)

func _build_buttons() -> void:
	continue_button = Button.new()
	continue_button.text = UiText.t("ritual.resolution.apply")
	continue_button.position = Vector2(550, 620)
	continue_button.size = Vector2(180, 72)
	continue_button.pressed.connect(_confirm)
	add_child(continue_button)

func _auto_finish() -> void:
	await get_tree().create_timer(1.1).timeout
	if is_inside_tree():
		_confirm()

func _confirm() -> void:
	if continue_button != null:
		continue_button.disabled = true
	completed.emit({
		"accepted": true,
		"outcome": outcome.duplicate(true),
		"pending_slot": pending_slot,
		"damage": damage,
		"cash_delta": cash_delta,
		"bust_delta": bust_delta
	})

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
