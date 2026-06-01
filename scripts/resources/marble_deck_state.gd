class_name MarbleDeckState
extends Resource

const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")

var all_marbles: Array[Dictionary] = []
var bag: Array[String] = []
var discard: Array[String] = []
var sealed: Array[String] = []
var removed: Array[String] = []
var temporary: Array[String] = []
var revealed: Array[String] = []
var selected: String = ""
var _next_instance_number: int = 1

func reset_starting_deck(rng: RandomNumberGenerator) -> void:
	all_marbles.clear()
	bag.clear()
	discard.clear()
	sealed.clear()
	removed.clear()
	temporary.clear()
	revealed.clear()
	selected = ""
	_next_instance_number = 1
	for marble_id in MarbleCatalog.starting_deck_ids():
		var instance := _create_instance(str(marble_id), "starting_deck", false)
		all_marbles.append(instance)
		bag.append(str(instance.get("instance_id", "")))
	_shuffle_ids(bag, rng)

func reveal_next(rng: RandomNumberGenerator, count: int = MarbleCatalog.REVEAL_COUNT) -> Array[Dictionary]:
	if selected != "":
		return revealed_instances()
	if not revealed.is_empty():
		return revealed_instances()
	if bag.is_empty():
		_reshuffle_discard_into_bag(rng)
	var draw_count: int = min(max(1, count), bag.size())
	for _i in range(draw_count):
		if bag.is_empty():
			break
		revealed.append(str(bag.pop_front()))
	return revealed_instances()

func choose_revealed(index: int) -> Dictionary:
	if revealed.is_empty():
		return {}
	var clamped := clampi(index, 0, revealed.size() - 1)
	selected = str(revealed[clamped])
	for instance_id in revealed:
		var id := str(instance_id)
		if id != selected:
			discard.append(id)
	revealed.clear()
	return selected_instance()

func finish_selected(rng: RandomNumberGenerator) -> void:
	if selected != "":
		discard.append(selected)
	selected = ""
	if bag.is_empty():
		_reshuffle_discard_into_bag(rng)

func selected_instance() -> Dictionary:
	return instance_by_id(selected)

func revealed_instances() -> Array[Dictionary]:
	return _instances_from_ids(revealed)

func instances_for_zone(zone: String) -> Array[Dictionary]:
	match zone:
		"all":
			return all_marbles.duplicate(true)
		"bag":
			return _instances_from_ids(bag)
		"discard":
			return _instances_from_ids(discard)
		"sealed":
			return _instances_from_ids(sealed)
		"removed":
			return _instances_from_ids(removed)
		"temporary":
			return _instances_from_ids(temporary)
		"revealed":
			return _instances_from_ids(revealed)
		"selected":
			var selected_result: Array[Dictionary] = []
			if selected != "":
				selected_result.append(selected_instance())
			return selected_result
	var empty_result: Array[Dictionary] = []
	return empty_result

func zone_counts() -> Dictionary:
	return {
		"all": all_marbles.size(),
		"bag": bag.size(),
		"discard": discard.size(),
		"sealed": sealed.size(),
		"removed": removed.size(),
		"temporary": temporary.size(),
		"revealed": revealed.size(),
		"selected": 1 if selected != "" else 0
	}

func instance_by_id(instance_id: String) -> Dictionary:
	if instance_id == "":
		return {}
	for marble in all_marbles:
		if str(marble.get("instance_id", "")) == instance_id:
			return marble.duplicate(true)
	return {}

func to_payload() -> Dictionary:
	return {
		"all_marbles": all_marbles.duplicate(true),
		"bag": bag.duplicate(),
		"discard": discard.duplicate(),
		"sealed": sealed.duplicate(),
		"removed": removed.duplicate(),
		"temporary": temporary.duplicate(),
		"revealed": revealed.duplicate(),
		"selected": selected,
		"next_instance_number": _next_instance_number
	}

func apply_payload(payload: Dictionary) -> void:
	all_marbles = (payload.get("all_marbles", []) as Array).duplicate(true)
	bag = _string_array(payload.get("bag", []))
	discard = _string_array(payload.get("discard", []))
	sealed = _string_array(payload.get("sealed", []))
	removed = _string_array(payload.get("removed", []))
	temporary = _string_array(payload.get("temporary", []))
	revealed = _string_array(payload.get("revealed", []))
	selected = str(payload.get("selected", ""))
	_next_instance_number = max(1, int(payload.get("next_instance_number", all_marbles.size() + 1)))

func _create_instance(marble_id: String, source: String, is_temporary: bool) -> Dictionary:
	var instance_id := "marble_%03d" % _next_instance_number
	_next_instance_number += 1
	return MarbleCatalog.instance_from_id(instance_id, marble_id, source, is_temporary)

func _reshuffle_discard_into_bag(rng: RandomNumberGenerator) -> void:
	if discard.is_empty():
		return
	bag = discard.duplicate()
	discard.clear()
	_shuffle_ids(bag, rng)

func _shuffle_ids(ids: Array[String], rng: RandomNumberGenerator) -> void:
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := ids[i]
		ids[i] = ids[j]
		ids[j] = tmp

func _instances_from_ids(ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance_id in ids:
		var instance := instance_by_id(str(instance_id))
		if not instance.is_empty():
			result.append(instance)
	return result

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
