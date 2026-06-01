class_name DiceCupRollLayer3D
extends Control

signal roll_finished(values: Array)

const DEFAULT_TRAY_RECT := Rect2(Vector2(174, 438), Vector2(318, 178))
const MAX_DICE := 2
const SHAKE_TIME := 0.42
const POUR_TIME := 0.38
const SETTLE_TIME := 0.56
const RESULT_HOLD_TIME := 0.62

const GOLD := Color("#f2be4b")
const BONE := Color("#f1e1c8")
const INK := Color("#17110b")
const CUP := Color("#15100d", 0.74)
const RIM := Color("#d2a44c", 0.72)
const SHADOW := Color("#020104", 0.28)

var rng := RandomNumberGenerator.new()
var tray_rect := DEFAULT_TRAY_RECT
var dice_count := 2
var result_values: Array[int] = [1, 1]
var previous_values: Array[int] = [0, 0]
var locked_dice: Array[bool] = [false, false]
var rolling := false
var result_live := false
var roll_elapsed := 0.0
var result_elapsed := 0.0
var roll_duration := SHAKE_TIME + POUR_TIME + SETTLE_TIME
var roll_time_scale := 1.0
var phase_name := "idle"
var debug_show_bounds := false

var viewport_container: SubViewportContainer
var sub_viewport: SubViewport
var world_root: Node3D
var camera: Camera3D
var light: DirectionalLight3D
var cup_root: Node3D
var cup_mesh: MeshInstance3D
var cup_rim: MeshInstance3D
var die_roots: Array[Node3D] = []
var die_meshes: Array[MeshInstance3D] = []
var die_labels: Array[Label3D] = []
var debug_floor: MeshInstance3D
var debug_rails: Array[MeshInstance3D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	visible = false
	set_process(true)
	_build_viewport()
	_layout_viewport()
	_reset_to_cup()

func configure(payload: Dictionary = {}) -> void:
	tray_rect = payload.get("tray_rect", tray_rect)
	debug_show_bounds = bool(payload.get("debug_show_bounds", debug_show_bounds))
	if payload.has("seed"):
		rng.seed = int(payload.get("seed", 1))
	_layout_viewport()
	_apply_debug_visibility()
	queue_redraw()

func roll(options: Dictionary = {}) -> void:
	if rolling:
		return
	if options.has("tray_rect") or options.has("seed") or options.has("debug_show_bounds"):
		configure(options)
	dice_count = clampi(int(options.get("dice_count", dice_count)), 1, MAX_DICE)
	previous_values = _int_array(options.get("previous_values", previous_values), dice_count)
	locked_dice = _bool_array(options.get("dice_locked", locked_dice), dice_count)
	result_values = _resolve_result_values(options)
	roll_time_scale = max(0.1, float(options.get("time_scale", 1.0)))
	rolling = true
	result_live = false
	roll_elapsed = 0.0
	result_elapsed = 0.0
	phase_name = "shake"
	visible = true
	modulate.a = 1.0
	_reset_to_cup()
	queue_redraw()

func reset() -> void:
	rolling = false
	result_live = false
	roll_elapsed = 0.0
	result_elapsed = 0.0
	phase_name = "idle"
	_reset_to_cup()
	visible = false
	queue_redraw()

func is_rolling() -> bool:
	return rolling

func last_values() -> Array[int]:
	return result_values.duplicate()

func _process(delta: float) -> void:
	if rolling:
		roll_elapsed += delta * roll_time_scale
		_update_roll_visuals()
		if roll_elapsed >= roll_duration:
			_finish_roll()
	elif result_live:
		result_elapsed += delta
		if result_elapsed >= RESULT_HOLD_TIME:
			result_live = false
			visible = false
	if rolling or result_live:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var draw_rect_area := tray_rect.grow(18.0)
	if debug_show_bounds:
		draw_rect(draw_rect_area, Color(GOLD, 0.10), true)
		draw_rect(draw_rect_area, Color(GOLD, 0.38), false, 2.0)
	var cup_pos := _screen_cup_position()
	draw_circle(cup_pos + Vector2(8, 12), 42.0, Color(SHADOW, 0.34))
	for i in range(dice_count):
		var p := _screen_die_position(i)
		draw_circle(p + Vector2(7, 10), 26.0, Color(SHADOW, 0.22))

func _build_viewport() -> void:
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "DiceCup3DViewport"
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = false
	add_child(viewport_container)

	sub_viewport = SubViewport.new()
	sub_viewport.name = "DiceCup3DSubViewport"
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.size = Vector2i(512, 360)
	viewport_container.add_child(sub_viewport)

	world_root = Node3D.new()
	world_root.name = "DiceCupWorld"
	sub_viewport.add_child(world_root)

	camera = Camera3D.new()
	camera.name = "DiceCupCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.9
	camera.look_at_from_position(Vector3(0.0, 5.9, 3.15), Vector3(0.0, 0.0, 0.05), Vector3.UP)
	camera.current = true
	world_root.add_child(camera)

	light = DirectionalLight3D.new()
	light.name = "DiceCupKeyLight"
	light.light_energy = 2.2
	light.rotation_degrees = Vector3(-58, 24, 0)
	world_root.add_child(light)

	_build_debug_bounds()
	_build_cup()
	_build_dice()

func _build_debug_bounds() -> void:
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(4.0, 0.03, 2.3)
	debug_floor = MeshInstance3D.new()
	debug_floor.name = "DebugInvisiblePhysicsFloor"
	debug_floor.mesh = floor_mesh
	debug_floor.position = Vector3(0, -0.035, 0)
	debug_floor.material_override = _material(Color("#1b1209", 0.18), true)
	world_root.add_child(debug_floor)
	for data in [
		[Vector3(0, 0.12, -1.18), Vector3(4.12, 0.24, 0.05)],
		[Vector3(0, 0.12, 1.18), Vector3(4.12, 0.24, 0.05)],
		[Vector3(-2.08, 0.12, 0), Vector3(0.05, 0.24, 2.3)],
		[Vector3(2.08, 0.12, 0), Vector3(0.05, 0.24, 2.3)]
	]:
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = data[1]
		var rail := MeshInstance3D.new()
		rail.name = "DebugInvisibleCatchWall"
		rail.mesh = rail_mesh
		rail.position = data[0]
		rail.material_override = _material(Color(GOLD, 0.16), true)
		world_root.add_child(rail)
		debug_rails.append(rail)
	_apply_debug_visibility()

func _build_cup() -> void:
	cup_root = Node3D.new()
	cup_root.name = "CupRoot"
	world_root.add_child(cup_root)

	var cup_body := CylinderMesh.new()
	cup_body.top_radius = 0.56
	cup_body.bottom_radius = 0.46
	cup_body.height = 0.82
	cup_body.radial_segments = 40
	cup_mesh = MeshInstance3D.new()
	cup_mesh.name = "ReadablePrototypeCup"
	cup_mesh.mesh = cup_body
	cup_mesh.material_override = _material(CUP, true)
	cup_mesh.position = Vector3(0, 0.41, 0)
	cup_root.add_child(cup_mesh)

	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.62
	rim_mesh.bottom_radius = 0.62
	rim_mesh.height = 0.055
	rim_mesh.radial_segments = 40
	cup_rim = MeshInstance3D.new()
	cup_rim.name = "PrototypeCupRim"
	cup_rim.mesh = rim_mesh
	cup_rim.material_override = _material(RIM, true)
	cup_rim.position = Vector3(0, 0.84, 0)
	cup_root.add_child(cup_rim)

func _build_dice() -> void:
	for i in range(MAX_DICE):
		var root := Node3D.new()
		root.name = "DieRoot" + str(i + 1)
		world_root.add_child(root)
		die_roots.append(root)

		var die_mesh := BoxMesh.new()
		die_mesh.size = Vector3(0.48, 0.48, 0.48)
		var mesh := MeshInstance3D.new()
		mesh.name = "PrototypeDie" + str(i + 1)
		mesh.mesh = die_mesh
		mesh.material_override = _material(BONE, false)
		root.add_child(mesh)
		die_meshes.append(mesh)

		var label := Label3D.new()
		label.name = "TopValueLabel" + str(i + 1)
		label.text = "1"
		label.font_size = 96
		label.modulate = INK
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 0.255, 0)
		root.add_child(label)
		die_labels.append(label)

func _layout_viewport() -> void:
	if viewport_container == null:
		return
	var rect := tray_rect.grow_individual(118.0, 96.0, 94.0, 70.0)
	viewport_container.position = rect.position
	viewport_container.size = rect.size
	if sub_viewport != null:
		sub_viewport.size = Vector2i(max(64, int(rect.size.x)), max(64, int(rect.size.y)))

func _reset_to_cup() -> void:
	if cup_root == null:
		return
	cup_root.position = _cup_home()
	cup_root.rotation_degrees = Vector3(-8.0, 0.0, -10.0)
	for i in range(MAX_DICE):
		var root := die_roots[i]
		root.visible = i < dice_count
		root.position = _cup_home() + _cup_die_offset(i)
		root.rotation_degrees = Vector3(22.0 + 19.0 * i, 0.0, -12.0 + 24.0 * i)
		die_labels[i].text = str(result_values[min(i, result_values.size() - 1)])

func _update_roll_visuals() -> void:
	var t := clampf(roll_elapsed / roll_duration, 0.0, 1.0)
	if roll_elapsed < SHAKE_TIME:
		phase_name = "shake"
		_update_shake(roll_elapsed / SHAKE_TIME)
	elif roll_elapsed < SHAKE_TIME + POUR_TIME:
		phase_name = "pour"
		_update_pour((roll_elapsed - SHAKE_TIME) / POUR_TIME)
	else:
		phase_name = "settle"
		_update_settle((roll_elapsed - SHAKE_TIME - POUR_TIME) / SETTLE_TIME)
	modulate.a = 1.0

func _update_shake(t: float) -> void:
	var tick := float(Time.get_ticks_msec())
	var shake := sin(tick * 0.045) * 0.09
	cup_root.position = _cup_home() + Vector3(shake, sin(tick * 0.055) * 0.045, cos(tick * 0.041) * 0.08)
	cup_root.rotation_degrees = Vector3(-8.0 + sin(tick * 0.031) * 4.0, 0.0, -10.0 + sin(tick * 0.05) * 9.0)
	for i in range(dice_count):
		var root := die_roots[i]
		root.position = cup_root.position + _cup_die_offset(i) + Vector3(sin(tick * 0.061 + i) * 0.12, cos(tick * 0.057 + i) * 0.05, cos(tick * 0.065 + i) * 0.11)
		root.rotation_degrees += Vector3(19.0 + 3.0 * i, 24.0 + 5.0 * i, 17.0)

func _update_pour(t: float) -> void:
	var eased := _ease_in_out(t)
	cup_root.position = _cup_home().lerp(_cup_pour(), eased)
	cup_root.rotation_degrees = Vector3(-10.0, 0.0, lerpf(-10.0, -82.0, eased))
	for i in range(dice_count):
		var start := _cup_home() + _cup_die_offset(i)
		var target := _die_target(i)
		var arc := sin(eased * PI) * 0.46
		var pos := start.lerp(target, eased) + Vector3(0.0, arc, 0.0)
		die_roots[i].position = pos
		die_roots[i].rotation_degrees += Vector3(11.0 + 4.0 * i, 36.0, 28.0 + 6.0 * i)

func _update_settle(t: float) -> void:
	var eased := _ease_out_cubic(t)
	cup_root.position = _cup_pour()
	cup_root.rotation_degrees = Vector3(-10.0, 0.0, -82.0)
	for i in range(dice_count):
		var target := _die_target(i)
		var wobble := (1.0 - eased)
		var roll_offset := Vector3(sin(t * TAU * (2.0 + i)) * 0.34 * wobble, abs(sin(t * TAU * 2.0)) * 0.12 * wobble, cos(t * TAU * (2.4 + i)) * 0.24 * wobble)
		die_roots[i].position = target + roll_offset
		die_roots[i].rotation_degrees = Vector3(0.0, 0.0, lerpf(220.0 + 47.0 * i, 6.0 - 14.0 * i, eased))
		die_labels[i].text = str(result_values[i])

func _finish_roll() -> void:
	if not rolling:
		return
	rolling = false
	result_live = false
	result_elapsed = 0.0
	phase_name = "result"
	cup_root.position = _cup_pour()
	cup_root.rotation_degrees = Vector3(-10.0, 0.0, -82.0)
	for i in range(dice_count):
		die_roots[i].position = _die_target(i)
		die_roots[i].rotation_degrees = Vector3(0, 0, 6.0 - 14.0 * i)
		die_labels[i].text = str(result_values[i])
	roll_finished.emit(result_values.duplicate())
	visible = false
	queue_redraw()

func _resolve_result_values(options: Dictionary) -> Array[int]:
	var forced_values: Array[int] = _int_array(options.get("forced_values", []), dice_count)
	if forced_values.is_empty() and options.has("forced_value"):
		forced_values = [clampi(int(options.get("forced_value", 1)), 1, 6)]
	var avoid_previous := bool(options.get("avoid_previous", false))
	var values: Array[int] = []
	for i in range(dice_count):
		var previous := previous_values[i] if i < previous_values.size() else 0
		var value := previous if i < locked_dice.size() and locked_dice[i] and previous >= 1 and previous <= 6 else 0
		if value == 0 and i < forced_values.size() and forced_values[i] >= 1 and forced_values[i] <= 6:
			value = forced_values[i]
		if value == 0:
			value = rng.randi_range(1, 6)
		if avoid_previous and previous >= 1 and previous <= 6 and value == previous and not (i < locked_dice.size() and locked_dice[i]):
			value = wrapi(value + rng.randi_range(1, 5), 1, 7)
		values.append(clampi(value, 1, 6))
	return values

func _cup_home() -> Vector3:
	return Vector3(-1.45, 0.18, -0.62)

func _cup_pour() -> Vector3:
	return Vector3(-0.72, 0.22, -0.36)

func _cup_die_offset(index: int) -> Vector3:
	return Vector3(-0.12 + float(index) * 0.24, 0.54 + float(index) * 0.03, -0.02 + float(index) * 0.11)

func _die_target(index: int) -> Vector3:
	return Vector3(0.42 + float(index) * 0.72, 0.25, -0.23 + float(index) * 0.42)

func _screen_cup_position() -> Vector2:
	return tray_rect.position + Vector2(40, 58)

func _screen_die_position(index: int) -> Vector2:
	return tray_rect.position + tray_rect.size * 0.5 + Vector2(26 + float(index) * 58.0, -6 + float(index) * 22.0)

func _material(color: Color, alpha: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mat.metallic = 0.0
	if alpha or color.a < 0.98:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = false
	return mat

func _apply_debug_visibility() -> void:
	if debug_floor != null:
		debug_floor.visible = debug_show_bounds
	for rail in debug_rails:
		rail.visible = debug_show_bounds

func _int_array(value: Variant, limit: int) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			if result.size() >= limit:
				break
			result.append(clampi(int(item), 1, 6))
	return result

func _bool_array(value: Variant, limit: int) -> Array[bool]:
	var result: Array[bool] = []
	if value is Array:
		for item in value:
			if result.size() >= limit:
				break
			result.append(bool(item))
	while result.size() < limit:
		result.append(false)
	return result

func _ease_in_out(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)

func _ease_out_cubic(t: float) -> float:
	var inv := 1.0 - clampf(t, 0.0, 1.0)
	return 1.0 - inv * inv * inv
