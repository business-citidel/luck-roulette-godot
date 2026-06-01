class_name RuntimeGameCommandGate
extends RefCounted

const Command := preload("res://scripts/runtime/core/game_command.gd")
const CommandResult := preload("res://scripts/runtime/core/game_command_result.gd")

static func apply_batch(base_state: Dictionary, commands: Array) -> Dictionary:
	var state := base_state.duplicate(true)
	var applied: Array[Dictionary] = []
	var messages: Array[String] = []
	var errors: Array[String] = []
	for item in commands:
		if not item is Dictionary:
			errors.append("command must be a dictionary")
			continue
		var command: Dictionary = item
		var command_errors := Command.validate(command)
		if not command_errors.is_empty():
			errors.append_array(command_errors)
			continue
		_apply_command(state, command, messages)
		applied.append(command.duplicate(true))
	if not errors.is_empty():
		return CommandResult.fail(state, errors, applied)
	return CommandResult.ok(state, applied, messages)

static func _apply_command(state: Dictionary, command: Dictionary, messages: Array[String]) -> void:
	var type := str(command.get("type", ""))
	var amount := int(command.get("amount", 0))
	var payload: Dictionary = command.get("payload", {})
	match type:
		Command.CASH:
			state["cash"] = int(state.get("cash", 0)) + amount
		Command.BLOCK:
			state["player_block"] = int(state.get("player_block", 0)) + amount
		Command.CONSUME_POTION:
			_consume_potion(state, str(payload.get("id", command.get("target", ""))))
		Command.MESSAGE:
			messages.append(str(payload.get("text", "")))
	_record_effect(state, command)

static func _consume_potion(state: Dictionary, potion_id: String) -> void:
	if potion_id == "":
		return
	var active: Array = state.get("active_potion_ids", [])
	var consumed: Array = state.get("consumed_potion_ids", [])
	var index := active.find(potion_id)
	if index >= 0:
		active.remove_at(index)
	if not consumed.has(potion_id):
		consumed.append(potion_id)
	state["active_potion_ids"] = active
	state["consumed_potion_ids"] = consumed

static func _record_effect(state: Dictionary, command: Dictionary) -> void:
	var payload: Dictionary = command.get("payload", {})
	var effect_id := str(payload.get("effect_id", ""))
	if effect_id == "":
		return
	var effects: Array = state.get("applied_effects", [])
	effects.append({
		"relic_id": str(payload.get("relic_id", command.get("source_id", ""))),
		"potion_id": str(payload.get("potion_id", "")),
		"source_id": str(command.get("source_id", "")),
		"effect_id": effect_id,
		"name": str(payload.get("name", command.get("source_id", "")))
	})
	state["applied_effects"] = effects
