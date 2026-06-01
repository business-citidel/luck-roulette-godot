class_name RuntimeGameCommand
extends RefCounted

const CASH := "cash"
const BLOCK := "block"
const CONSUME_POTION := "consume_potion"
const MESSAGE := "message"

const ALL := [
	CASH,
	BLOCK,
	CONSUME_POTION,
	MESSAGE
]

static func make(type: String, source_id: String, target: String = "", amount: int = 0, payload: Dictionary = {}) -> Dictionary:
	return {
		"type": type,
		"source_id": source_id,
		"target": target,
		"amount": amount,
		"payload": payload.duplicate(true)
	}

static func is_valid_type(type: String) -> bool:
	return type in ALL

static func validate(command: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var type := str(command.get("type", ""))
	if not is_valid_type(type):
		errors.append("unknown command type: " + type)
	if str(command.get("source_id", "")) == "":
		errors.append("missing source_id")
	if not command.has("payload") or not command.get("payload") is Dictionary:
		errors.append("payload must be a dictionary")
	return errors
