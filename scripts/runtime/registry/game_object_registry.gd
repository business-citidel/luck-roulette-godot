class_name RuntimeGameObjectRegistry
extends RefCounted

const Hook := preload("res://scripts/runtime/core/game_hook.gd")
const ObjectDef := preload("res://scripts/runtime/core/game_object_def.gd")
const PilotObjects := preload("res://scripts/runtime/objects/runtime_pilot_objects.gd")

var _objects: Dictionary = {}

func register(definition: Dictionary) -> Array[String]:
	var errors := ObjectDef.validate(definition)
	if not errors.is_empty():
		return errors
	_objects[str(definition.get("id", ""))] = definition.duplicate(true)
	return []

func register_many(definitions: Array[Dictionary]) -> Array[String]:
	var errors: Array[String] = []
	for definition in definitions:
		errors.append_array(register(definition))
	return errors

func has_object(id: String) -> bool:
	return _objects.has(id)

func get_object(id: String) -> Dictionary:
	return (_objects.get(id, {}) as Dictionary).duplicate(true)

func dispatch_hook(hook: String, state: Dictionary, context: Dictionary, object_ids: Array) -> Array[Dictionary]:
	if not Hook.is_valid(hook):
		return []
	var commands: Array[Dictionary] = []
	for object_id in object_ids:
		var id := str(object_id)
		if not _objects.has(id):
			continue
		var definition: Dictionary = _objects[id]
		var hooks: Dictionary = definition.get("hooks", {})
		if not hooks.has(hook):
			continue
		commands.append_array(PilotObjects.commands_for_hook(definition, hook, state, context))
	return commands

static func with_pilots():
	var registry = load("res://scripts/runtime/registry/game_object_registry.gd").new()
	registry.register_many(PilotObjects.definitions())
	return registry
