extends Node

const TransitionServiceScript := preload("res://scripts/systems/transition_service.gd")

var transition_service: CanvasLayer
var scene_canvas: CanvasLayer
var active_scene: Node
var active_scene_name: String = ""

func _ready() -> void:
	transition_service = TransitionServiceScript.new()
	transition_service.name = "RunTransitionService"
	add_child(transition_service)
	scene_canvas = CanvasLayer.new()
	scene_canvas.name = "RunSceneCanvas"
	scene_canvas.layer = 10
	add_child(scene_canvas)

func show_scene(scene_name: String, scene: PackedScene, payload: Dictionary) -> Dictionary:
	active_scene = await mount_scene(scene_name, scene, payload)
	var result: Dictionary = await active_scene.completed
	await _clear_active_scene()
	return result

func mount_scene(scene_name: String, scene: PackedScene, payload: Dictionary) -> Node:
	await _clear_active_scene()
	active_scene = scene.instantiate()
	if active_scene.has_method("configure"):
		active_scene.configure(payload)
	scene_canvas.add_child(active_scene)
	active_scene_name = scene_name
	return active_scene

func show_terminal_scene(scene_name: String, scene: PackedScene, payload: Dictionary) -> Node:
	if active_scene != null:
		active_scene.queue_free()
	active_scene = scene.instantiate()
	if active_scene.has_method("configure"):
		active_scene.configure(payload)
	scene_canvas.add_child(active_scene)
	active_scene_name = scene_name
	return active_scene

func clear_active_scene() -> void:
	await _clear_active_scene()

func _clear_active_scene() -> void:
	if active_scene == null:
		return
	active_scene.queue_free()
	active_scene = null
	active_scene_name = ""
	await get_tree().process_frame
