extends SceneTree

const CollectionProgressService := preload("res://scripts/systems/collection_progress_service.gd")

var failures: Array[String] = []

func _initialize() -> void:
	CollectionProgressService.clear_progress()
	var empty := CollectionProgressService.load_progress()
	if int(empty.get("schema_version", 0)) != CollectionProgressService.SCHEMA_VERSION:
		failures.append("collection progress should expose schema version")
	if not (empty.get(CollectionProgressService.KEY_RELICS, []) as Array).is_empty():
		failures.append("clean collection progress should have no relic discoveries")

	CollectionProgressService.discover_character("default_guard_dice")
	CollectionProgressService.discover_relic("loaded_die")
	CollectionProgressService.discover_relic("loaded_die")
	CollectionProgressService.discover_monster("debt_collector")
	CollectionProgressService.discover_event("sealed_side_box")
	CollectionProgressService.record_event_result("sealed_side_box", {
		"choice": "sealed_side_box",
		"result_title": "Opened"
	})

	var saved := CollectionProgressService.load_progress()
	if not (saved.get(CollectionProgressService.KEY_CHARACTERS, []) as Array).has("default_guard_dice"):
		failures.append("character discovery should persist")
	if (saved.get(CollectionProgressService.KEY_RELICS, []) as Array).count("loaded_die") != 1:
		failures.append("relic discovery should dedupe ids")
	if not (saved.get(CollectionProgressService.KEY_MONSTERS, []) as Array).has("debt_collector"):
		failures.append("monster discovery should persist")
	if not CollectionProgressService.is_event_discovered("sealed_side_box"):
		failures.append("event discovery helper should read persisted event")
	var records: Dictionary = saved.get(CollectionProgressService.KEY_EVENT_RECORDS, {})
	var sealed_record: Dictionary = records.get("sealed_side_box", {})
	if int(sealed_record.get("seen_count", 0)) < 1:
		failures.append("event record should track seen count")
	if int(sealed_record.get("resolved_count", 0)) != 1:
		failures.append("event record should track resolved count")
	if str(sealed_record.get("last_choice_id", "")) != "sealed_side_box":
		failures.append("event record should track last choice")

	CollectionProgressService.clear_progress()
	var cleared := CollectionProgressService.load_progress()
	if not (cleared.get(CollectionProgressService.KEY_CHARACTERS, []) as Array).is_empty():
		failures.append("clear should remove character discoveries")

	if failures.is_empty():
		print("collection progress service smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
