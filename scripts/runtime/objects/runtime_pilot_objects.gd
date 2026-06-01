class_name RuntimePilotObjects
extends RefCounted

const Command := preload("res://scripts/runtime/core/game_command.gd")
const Hook := preload("res://scripts/runtime/core/game_hook.gd")
const ObjectDef := preload("res://scripts/runtime/core/game_object_def.gd")

static func definitions() -> Array[Dictionary]:
	return [
		turn_token(),
		guard_potion()
	]

static func turn_token() -> Dictionary:
	return ObjectDef.make("turn_token", "relic", "Turn Token", {
		Hook.TURN_START: "turn_token_turn_start"
	}, {
		"cash": 1,
		"effect_id": "turn_cash_tip",
		"description": "Adds a small cash tip at the start of each turn.",
		"icon_id": "turn_token",
		"rarity": "common",
		"shop_price": 26
	})

static func guard_potion() -> Dictionary:
	return ObjectDef.make("guard_potion", "potion", "Guard Potion", {
		Hook.POTION_USED: "guard_potion_used"
	}, {
		"block": 10,
		"effect_id": "guard_potion_block",
		"description": "Gain 10 block.",
		"display_key": "potion.guard_potion",
		"icon_id": "guard_potion"
	})

static func commands_for_hook(definition: Dictionary, hook: String, _state: Dictionary, context: Dictionary) -> Array[Dictionary]:
	var id := str(definition.get("id", ""))
	match id:
		"turn_token":
			return _turn_token_commands(definition, hook)
		"guard_potion":
			return _guard_potion_commands(definition, hook, context)
	return []

static func _turn_token_commands(definition: Dictionary, hook: String) -> Array[Dictionary]:
	if hook != Hook.TURN_START:
		return []
	var payload: Dictionary = definition.get("payload", {})
	return [Command.make(Command.CASH, "turn_token", "player", int(payload.get("cash", 1)), {
		"relic_id": "turn_token",
		"effect_id": str(payload.get("effect_id", "turn_cash_tip")),
		"name": str(definition.get("display_name", "Turn Token"))
	})]

static func _guard_potion_commands(definition: Dictionary, hook: String, context: Dictionary) -> Array[Dictionary]:
	if hook != Hook.POTION_USED:
		return []
	if str(context.get("potion_id", "")) != "guard_potion":
		return []
	var payload: Dictionary = definition.get("payload", {})
	return [
		Command.make(Command.BLOCK, "guard_potion", "player", int(payload.get("block", 10)), {
			"potion_id": "guard_potion",
			"effect_id": str(payload.get("effect_id", "guard_potion_block")),
			"name": str(definition.get("display_name", "Guard Potion"))
		}),
		Command.make(Command.CONSUME_POTION, "guard_potion", "guard_potion", 0, {
			"id": "guard_potion"
		})
	]
