class_name CombatState
extends Resource

var phase: String = "dice"
var turn: int = 1
var cash: int = 18
var banked: int = 0
var enemy_damage_delta: int = 0
var busts: int = 0

var player_hp: int = 42
var player_max_hp: int = 42
var player_block: int = 0
var enemy_hp: int = 92
var enemy_max_hp: int = 92
var enemy_intent: String = "Next damage 7"

var dice_rule_id: String = "single_attack_die"
var dice: Array[int] = [1]
var dice_locked: Array[bool] = [false]
var dice_rolled: bool = false
var rerolls_left: int = 2
var attack_base: int = 0
var selected_attack_die_index: int = -1
var guard_value: int = 0

var marbles: Array[String] = []
var stored: Array[String] = []
var placed_slots: Dictionary = {}

var pending_slot: String = ""
var payout_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var run_over: bool = false

func reset_slots(slot_ids: Array) -> void:
	placed_slots.clear()
	for id in slot_ids:
		placed_slots[id] = []

func placed_count(slot_ids: Array) -> int:
	var count: int = 0
	for id in slot_ids:
		var arr: Array = placed_slots.get(id, [])
		count += arr.size()
	return count

func slot_color_count(id: String, color: String) -> int:
	return slot_token_count(id, color)

func slot_token_count(id: String, token_id: String) -> int:
	var count: int = 0
	var arr: Array = placed_slots.get(id, [])
	for value in arr:
		if str(value) == token_id:
			count += 1
	return count

func combat_is_live() -> bool:
	return enemy_hp > 0 and player_hp > 0 and busts < 2 and not run_over
