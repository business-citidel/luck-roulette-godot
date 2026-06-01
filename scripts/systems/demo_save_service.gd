class_name DemoSaveService
extends RefCounted

const SAVE_KEY := "luck_roulette_demo_run"
const SCHEMA_VERSION := 1

static func has_save() -> bool:
	var save_system := _save_system()
	return save_system != null and save_system.has(SAVE_KEY)

static func save_run(run_state: Resource, run_stats: Dictionary = {}) -> void:
	if run_state == null or not run_state.has_method("to_payload"):
		return
	var save_system := _save_system()
	if save_system == null:
		return
	save_system.set_var(SAVE_KEY, {
		"schema_version": SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"save_kind": "map_boundary",
		"run_state": run_state.to_payload(),
		"run_stats": run_stats.duplicate(true),
		"last_screen": "map"
	})
	save_system.save()

static func load_save() -> Dictionary:
	var save_system := _save_system()
	if save_system == null:
		return {}
	var payload: Variant = save_system.get_var(SAVE_KEY, {})
	if payload is Dictionary:
		return (payload as Dictionary).duplicate(true)
	return {}

static func load_run_state_payload() -> Dictionary:
	var payload := load_save()
	var run_payload: Variant = payload.get("run_state", {})
	if run_payload is Dictionary:
		return (run_payload as Dictionary).duplicate(true)
	return {}

static func load_run_stats() -> Dictionary:
	var payload := load_save()
	var stats_payload: Variant = payload.get("run_stats", {})
	if stats_payload is Dictionary:
		return (stats_payload as Dictionary).duplicate(true)
	return {}

static func clear_save() -> void:
	var save_system := _save_system()
	if save_system == null:
		return
	if save_system.has(SAVE_KEY):
		save_system.delete(SAVE_KEY)
	save_system.save()

static func _save_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SaveSystem")
