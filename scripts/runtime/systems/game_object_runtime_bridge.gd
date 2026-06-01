class_name GameObjectRuntimeBridge
extends RefCounted

const CommandGate := preload("res://scripts/runtime/core/game_command_gate.gd")
const Registry := preload("res://scripts/runtime/registry/game_object_registry.gd")

static func apply_hook(hook: String, payload: Dictionary, object_ids: Array, context: Dictionary = {}) -> Dictionary:
	var registry = Registry.with_pilots()
	var commands: Array[Dictionary] = registry.dispatch_hook(hook, payload, context, object_ids)
	var result := CommandGate.apply_batch(payload, commands)
	var state: Dictionary = result.get("state", payload)
	if not bool(result.get("ok", false)):
		state["runtime_command_errors"] = result.get("errors", [])
	state["runtime_applied_commands"] = result.get("applied", [])
	return state
