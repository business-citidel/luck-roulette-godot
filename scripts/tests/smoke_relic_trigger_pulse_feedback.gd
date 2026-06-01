extends SceneTree

const FeedbackEventMapper := preload("res://scripts/systems/feedback_event_mapper.gd")
const FeedbackLayer := preload("res://scripts/ui/feedback_layer.gd")

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1280, 720)

	var layer := FeedbackLayer.new()
	root.add_child(layer)
	await process_frame

	var events: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"relic_id": "green_purse",
		"effect_id": "green_payout_multiplier",
		"name": "Green Purse"
	}], "resolution")
	layer.show_events(events)
	await process_frame

	var pulse := layer.find_child("RelicPulse_green_purse", true, false)
	var ring := layer.find_child("RelicPulseRing_green_purse", true, false)
	if pulse != null or ring != null:
		failures.append("feedback layer should leave relic icon pulse to persistent overlay")

	var previous_pulses := _count_named_children(layer, "RelicPulse_")
	var enemy_events: Array[Dictionary] = FeedbackEventMapper.map_effects([{
		"source_id": "table_crook",
		"effect_id": "hp_damage",
		"name": "Table Crook"
	}], "enemy")
	layer.show_events(enemy_events)
	await process_frame
	if _count_named_children(layer, "RelicPulse_") != previous_pulses:
		failures.append("non-relic feedback should not spawn relic pulse icons")

	layer.queue_free()
	await process_frame

	if failures.is_empty():
		print("relic trigger pulse feedback smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _count_named_children(node: Node, prefix: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.name.begins_with(prefix):
			count += 1
		count += _count_named_children(child, prefix)
	return count
