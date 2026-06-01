class_name CombatCameraRig
extends Node2D

const BEAT_WIDE := "wide_table"
const BEAT_DICE := "dice_hand"
const BEAT_POUCH := "marble_pouch"
const BEAT_WHEEL := "wheel_close"
const BEAT_OPPONENT := "opponent_intent"
const BEAT_RESULT := "result_hit"

var active_beat: String = ""
var camera: Camera2D
var anchors: Dictionary = {}
var active_tween: Tween
var phantom_camera_vendored: bool = false

func _ready() -> void:
	phantom_camera_vendored = FileAccess.file_exists("res://addons/phantom_camera/plugin.cfg")
	_build_camera()
	set_beat(BEAT_WIDE, true)

func set_beat(beat: String, instant: bool = false) -> void:
	if not anchors.has(beat):
		return
	if active_beat == beat and not instant:
		return
	active_beat = beat
	var target: Dictionary = anchors[beat]
	if active_tween != null:
		active_tween.kill()
	if instant:
		camera.position = target["position"]
		camera.zoom = target["zoom"]
		return
	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.set_trans(Tween.TRANS_SINE)
	active_tween.set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(camera, "position", target["position"], target["duration"])
	active_tween.tween_property(camera, "zoom", target["zoom"], target["duration"])

func get_active_beat() -> String:
	return active_beat

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "CombatCamera2D"
	camera.position = Vector2(640, 360)
	camera.zoom = Vector2.ONE
	add_child(camera)
	camera.make_current()

	_add_anchor(BEAT_WIDE, Vector2(640, 360), Vector2(0.92, 0.92), 0.45)
	_add_anchor(BEAT_DICE, Vector2(300, 356), Vector2(1.08, 1.08), 0.42)
	_add_anchor(BEAT_POUCH, Vector2(292, 494), Vector2(1.06, 1.06), 0.35)
	_add_anchor(BEAT_WHEEL, Vector2(640, 340), Vector2(0.9, 0.9), 0.46)
	_add_anchor(BEAT_OPPONENT, Vector2(640, 340), Vector2(0.9, 0.9), 0.42)
	_add_anchor(BEAT_RESULT, Vector2(640, 340), Vector2(0.9, 0.9), 0.3)

func _add_anchor(beat: String, pos: Vector2, zoom: Vector2, duration: float) -> void:
	anchors[beat] = {
		"position": pos,
		"zoom": zoom,
		"duration": duration
	}
