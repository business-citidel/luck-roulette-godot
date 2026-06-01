extends Node

const TransitionServiceScript := preload("res://scripts/systems/transition_service.gd")

signal ritual_started(ritual_name: String)
signal ritual_finished(ritual_name: String, result: Dictionary)

var transition_service: CanvasLayer
var ritual_canvas: CanvasLayer
var active_ritual: Node
var active_ritual_name: String = ""

func _ready() -> void:
	transition_service = TransitionServiceScript.new()
	transition_service.name = "TransitionService"
	add_child(transition_service)

	ritual_canvas = CanvasLayer.new()
	ritual_canvas.name = "RitualCanvas"
	ritual_canvas.layer = 80
	add_child(ritual_canvas)

func is_ritual_active() -> bool:
	return active_ritual != null

func play_combat_resolution_beat(scene: PackedScene, payload: Dictionary) -> Dictionary:
	return await _play_ritual("combat_resolution", scene, payload)

func play_enemy_intent_beat(scene: PackedScene, payload: Dictionary) -> Dictionary:
	return await _play_ritual("enemy_intent", scene, payload)

func _play_ritual(ritual_name: String, scene: PackedScene, payload: Dictionary) -> Dictionary:
	if active_ritual != null:
		return {}
	ritual_started.emit(ritual_name)
	var use_transition := ritual_name != "dice"
	if use_transition:
		await transition_service.cover()

	active_ritual_name = ritual_name
	active_ritual = scene.instantiate()
	if active_ritual.has_method("configure"):
		active_ritual.configure(payload)
	ritual_canvas.add_child(active_ritual)

	if use_transition:
		await transition_service.uncover()
	var result: Dictionary = await active_ritual.completed
	if use_transition:
		await transition_service.cover()

	active_ritual.queue_free()
	active_ritual = null
	active_ritual_name = ""
	await get_tree().process_frame
	if use_transition:
		await transition_service.uncover()

	ritual_finished.emit(ritual_name, result)
	return result
