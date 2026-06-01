class_name BattleLegacySlotFlow
extends RefCounted

const MarbleResolver := preload("res://scripts/systems/marble_resolver.gd")
const RouletteSlotCatalog := preload("res://scripts/systems/roulette_slot_catalog.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

static func empty_slots() -> Dictionary:
	var result := {}
	for id in RouletteSlotCatalog.slot_ids():
		result[id] = []
	return result

static func normalize_slots(value: Variant) -> Dictionary:
	var result := empty_slots()
	if value is Dictionary:
		for id in RouletteSlotCatalog.slot_ids():
			for color in (value as Dictionary).get(id, []):
				result[id].append(str(color))
	return result

static func placed_count(placed_slots: Dictionary) -> int:
	var count := 0
	for id in RouletteSlotCatalog.slot_ids():
		var arr: Array = placed_slots.get(id, [])
		count += arr.size()
	return count

static func first_filled_slot(placed_slots: Dictionary) -> String:
	for id in RouletteSlotCatalog.slot_ids():
		var arr: Array = placed_slots.get(id, [])
		if arr.size() > 0:
			return id
	return ""

static func slot_center(id: String) -> Vector2:
	var index: int = RouletteSlotCatalog.index(id)
	var angle: float = deg_to_rad(-90.0 + float(index) * 72.0)
	return Vector2(640, 360) + Vector2(cos(angle), sin(angle)) * 208.0

static func slot_at(pos: Vector2) -> String:
	var wheel_center := Vector2(640, 360)
	if pos.distance_to(wheel_center) <= 232.0:
		var best_id := ""
		var best_distance := INF
		for id in RouletteSlotCatalog.slot_ids():
			var distance: float = pos.distance_to(slot_center(id))
			if distance < best_distance:
				best_distance = distance
				best_id = id
		return best_id
	for id in RouletteSlotCatalog.slot_ids():
		if pos.distance_to(slot_center(id)) <= 48.0:
			return id
	return ""

static func slot_id_for_key(event: InputEventKey) -> String:
	var slot_ids: Array[String] = RouletteSlotCatalog.slot_ids()
	var keycodes: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	var physical_keycodes: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	for i in range(min(slot_ids.size(), keycodes.size())):
		if event.keycode == keycodes[i] or event.physical_keycode == physical_keycodes[i]:
			return slot_ids[i]
	return ""

static func spread_slot_for_marble(target_slot: String, index: int, count: int) -> String:
	if count <= 1 or index <= 0:
		return target_slot
	var ids := RouletteSlotCatalog.slot_ids()
	var center := ids.find(target_slot)
	if center < 0:
		center = ids.find(RouletteSlotCatalog.fallback_id())
	var distance := int(ceil(float(index) / 2.0))
	var direction := 1 if index % 2 == 1 else -1
	return str(ids[(center + direction * distance + ids.size() * 2) % ids.size()])

static func landing_slot_for_marble(color: String, index: int, throw_power: float, rng: RandomNumberGenerator) -> String:
	return MarbleResolver.landing_slot_for_marble(color, throw_power, rng)

static func placement_patch(slot_id: String, marbles: Array) -> Dictionary:
	if marbles.is_empty():
		return {"valid": false}
	var target_slot: String = slot_id if RouletteSlotCatalog.has_slot(slot_id) else RouletteSlotCatalog.fallback_id()
	return {
		"valid": true,
		"target_slot": target_slot,
		"colors": _string_array(marbles),
		"marbles": [],
		"hovered_slot_id": "",
		"hovered_spin_wheel": false,
		"throwing_hand": false,
		"hand_marble_preview": [],
		"table_pulse": 1.0,
		"slot_feedback_id": target_slot,
		"slot_feedback_alpha": 1.0,
		"banner_text": UiText.t("battle.banner.marble_setting"),
		"banner_alpha": 1.0,
		"message": UiText.t("battle.message.marble_boost_slot", {
			"slot": RouletteSlotCatalog.label(target_slot),
			"reward": RouletteSlotCatalog.boosted_reward_text(target_slot)
		})
	}

static func particles_for_slot(colors: Array, slot_id: String, release_pos: Vector2, throw_power: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var particles: Array[Dictionary] = []
	var target_slot: String = slot_id if RouletteSlotCatalog.has_slot(slot_id) else RouletteSlotCatalog.fallback_id()
	var string_colors := _string_array(colors)
	for i in range(string_colors.size()):
		var color: String = string_colors[i]
		var landing_slot := spread_slot_for_marble(target_slot, i, string_colors.size())
		var slot_pos: Vector2 = slot_center(landing_slot)
		var scatter_angle: float = rng.randf_range(0.0, TAU)
		var scatter_radius: float = rng.randf_range(4.0, 18.0)
		var target: Vector2 = slot_pos + Vector2(cos(scatter_angle), sin(scatter_angle)) * scatter_radius
		particles.append({
			"color": color,
			"slot": landing_slot,
			"start": release_pos + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-10.0, 10.0)),
			"target": target,
			"pos": release_pos,
			"t": -float(i) * 0.035,
			"duration": rng.randf_range(0.36, 0.52),
			"arc": rng.randf_range(38.0, 62.0) * throw_power,
			"settled": false
		})
	return particles

static func random_throw_particles(colors: Array, release_pos: Vector2, throw_power: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var particles: Array[Dictionary] = []
	var string_colors := _string_array(colors)
	for i in range(string_colors.size()):
		var color: String = string_colors[i]
		var slot_id: String = landing_slot_for_marble(color, i, throw_power, rng)
		var slot_pos: Vector2 = slot_center(slot_id)
		var scatter_angle: float = rng.randf_range(0.0, TAU)
		var scatter_radius: float = rng.randf_range(4.0, 28.0 + throw_power * 8.0)
		var target: Vector2 = slot_pos + Vector2(cos(scatter_angle), sin(scatter_angle)) * scatter_radius
		particles.append({
			"color": color,
			"slot": slot_id,
			"start": release_pos + Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-16.0, 16.0)),
			"target": target,
			"pos": release_pos,
			"t": -float(i) * 0.045,
			"duration": rng.randf_range(0.42, 0.68),
			"arc": rng.randf_range(52.0, 92.0) * throw_power,
			"settled": false
		})
	return particles

static func advance_thrown_marbles(thrown_marbles: Array, delta: float) -> Dictionary:
	var had_thrown: bool = not thrown_marbles.is_empty()
	var next_marbles: Array = thrown_marbles.duplicate(true)
	var settled: Array[Dictionary] = []
	for i in range(next_marbles.size() - 1, -1, -1):
		var marble: Dictionary = next_marbles[i]
		marble["t"] = float(marble["t"]) + delta
		var progress: float = clamp(float(marble["t"]) / float(marble["duration"]), 0.0, 1.0)
		var start: Vector2 = marble["start"]
		var target: Vector2 = marble["target"]
		var pos: Vector2 = start.lerp(target, _ease_out(progress))
		pos.y -= sin(progress * PI) * float(marble["arc"])
		marble["pos"] = pos
		if progress >= 1.0 and not bool(marble["settled"]):
			settled.append(marble.duplicate(true))
			marble["settled"] = true
		if progress >= 1.0:
			next_marbles.remove_at(i)
		else:
			next_marbles[i] = marble
	return {
		"had_thrown": had_thrown,
		"thrown_marbles": next_marbles,
		"settled": settled,
		"finished": had_thrown and next_marbles.is_empty()
	}

static func settle_patch(marble: Dictionary, placed_slots: Dictionary) -> Dictionary:
	var slot_id := str(marble.get("slot", RouletteSlotCatalog.fallback_id()))
	if not RouletteSlotCatalog.has_slot(slot_id):
		slot_id = RouletteSlotCatalog.fallback_id()
	var color := str(marble.get("color", "plain"))
	var next_slots := normalize_slots(placed_slots)
	var arr: Array = next_slots.get(slot_id, [])
	arr.append(color)
	next_slots[slot_id] = arr
	return {
		"placed_slots": next_slots,
		"slot_feedback_id": slot_id,
		"slot_feedback_alpha": 1.0,
		"marble_feedback_pos": marble.get("target", Vector2.ZERO),
		"marble_feedback_color_id": color,
		"marble_feedback_alpha": 1.0,
		"banner_text": UiText.t("battle.banner.marble_setting"),
		"banner_alpha_min": 0.42,
		"audio_cue": {"key": "marble_drop", "pitch": 0.95, "pitch_jitter": 0.08, "volume_db": -7.0}
	}

static func finish_setup_patch(placed_slots: Dictionary) -> Dictionary:
	if placed_count(placed_slots) <= 0:
		return {"valid": false}
	return {
		"valid": true,
		"spin_ready_flash": 1.0,
		"banner_text": UiText.t("battle.banner.spin_ready"),
		"banner_alpha": 1.0,
		"message": UiText.t("battle.message.marble_ready"),
		"audio_cue": {"key": "table_hit", "pitch": 0.88, "volume_db": -10.0}
	}

static func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
