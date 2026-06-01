class_name RuntimeGameObjectDef
extends RefCounted

static func make(id: String, kind: String, display_name: String, hooks: Dictionary = {}, payload: Dictionary = {}) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"display_name": display_name,
		"hooks": hooks.duplicate(true),
		"payload": payload.duplicate(true)
	}

static func validate(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(definition.get("id", "")) == "":
		errors.append("missing id")
	if str(definition.get("kind", "")) == "":
		errors.append("missing kind")
	if str(definition.get("display_name", "")) == "":
		errors.append("missing display_name")
	if not definition.get("hooks", {}) is Dictionary:
		errors.append("hooks must be a dictionary")
	return errors
