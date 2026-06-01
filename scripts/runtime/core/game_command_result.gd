class_name RuntimeGameCommandResult
extends RefCounted

static func ok(state: Dictionary, applied: Array[Dictionary], messages: Array[String] = []) -> Dictionary:
	return {
		"ok": true,
		"state": state.duplicate(true),
		"applied": applied.duplicate(true),
		"errors": [],
		"messages": messages.duplicate()
	}

static func fail(state: Dictionary, errors: Array[String], applied: Array[Dictionary] = []) -> Dictionary:
	return {
		"ok": false,
		"state": state.duplicate(true),
		"applied": applied.duplicate(true),
		"errors": errors.duplicate(),
		"messages": []
	}
