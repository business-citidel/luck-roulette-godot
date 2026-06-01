class_name CollectionProgressService
extends RefCounted

const COLLECTION_PATH := "user://luck_roulette_collection.cfg"
const SECTION_META := "meta"
const SECTION_DISCOVERY := "discovery"
const SECTION_EVENTS := "events"
const SCHEMA_VERSION := 1

const KEY_CHARACTERS := "discovered_characters"
const KEY_RELICS := "discovered_relics"
const KEY_MONSTERS := "discovered_monsters"
const KEY_EVENTS := "discovered_events"
const KEY_EVENT_RECORDS := "event_records"

static func default_progress() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		KEY_CHARACTERS: [],
		KEY_RELICS: [],
		KEY_MONSTERS: [],
		KEY_EVENTS: [],
		KEY_EVENT_RECORDS: {}
	}

static func load_progress() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(COLLECTION_PATH)
	if err != OK:
		return default_progress()
	var progress := default_progress()
	progress["schema_version"] = int(config.get_value(SECTION_META, "schema_version", SCHEMA_VERSION))
	progress[KEY_CHARACTERS] = _string_array(config.get_value(SECTION_DISCOVERY, KEY_CHARACTERS, []))
	progress[KEY_RELICS] = _string_array(config.get_value(SECTION_DISCOVERY, KEY_RELICS, []))
	progress[KEY_MONSTERS] = _string_array(config.get_value(SECTION_DISCOVERY, KEY_MONSTERS, []))
	progress[KEY_EVENTS] = _string_array(config.get_value(SECTION_DISCOVERY, KEY_EVENTS, []))
	var records: Variant = config.get_value(SECTION_EVENTS, KEY_EVENT_RECORDS, {})
	if records is Dictionary:
		progress[KEY_EVENT_RECORDS] = (records as Dictionary).duplicate(true)
	return progress

static func save_progress(progress: Dictionary) -> void:
	var normalized := _normalized_progress(progress)
	var config := ConfigFile.new()
	config.set_value(SECTION_META, "schema_version", SCHEMA_VERSION)
	config.set_value(SECTION_DISCOVERY, KEY_CHARACTERS, normalized[KEY_CHARACTERS])
	config.set_value(SECTION_DISCOVERY, KEY_RELICS, normalized[KEY_RELICS])
	config.set_value(SECTION_DISCOVERY, KEY_MONSTERS, normalized[KEY_MONSTERS])
	config.set_value(SECTION_DISCOVERY, KEY_EVENTS, normalized[KEY_EVENTS])
	config.set_value(SECTION_EVENTS, KEY_EVENT_RECORDS, normalized[KEY_EVENT_RECORDS])
	config.save(COLLECTION_PATH)

static func clear_progress() -> void:
	if FileAccess.file_exists(COLLECTION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(COLLECTION_PATH))

static func discover_character(character_id: String) -> void:
	_discover(KEY_CHARACTERS, character_id)

static func discover_relic(relic_id: String) -> void:
	_discover(KEY_RELICS, relic_id)

static func discover_monster(monster_id: String) -> void:
	_discover(KEY_MONSTERS, monster_id)

static func discover_event(event_id: String) -> void:
	_discover(KEY_EVENTS, event_id)
	if event_id.strip_edges() == "":
		return
	var progress := load_progress()
	var records: Dictionary = progress.get(KEY_EVENT_RECORDS, {})
	var record: Dictionary = records.get(event_id, {})
	record["seen_count"] = int(record.get("seen_count", 0)) + 1
	records[event_id] = record
	progress[KEY_EVENT_RECORDS] = records
	save_progress(progress)

static func record_event_result(event_id: String, result: Dictionary) -> void:
	var clean_id := event_id.strip_edges()
	if clean_id == "":
		return
	_discover(KEY_EVENTS, clean_id)
	var progress := load_progress()
	var records: Dictionary = progress.get(KEY_EVENT_RECORDS, {})
	var record: Dictionary = records.get(clean_id, {})
	record["resolved_count"] = int(record.get("resolved_count", 0)) + 1
	record["last_choice_id"] = str(result.get("choice", ""))
	record["last_result_title"] = str(result.get("result_title", ""))
	records[clean_id] = record
	progress[KEY_EVENT_RECORDS] = records
	save_progress(progress)

static func is_character_discovered(character_id: String) -> bool:
	return _is_discovered(KEY_CHARACTERS, character_id)

static func is_relic_discovered(relic_id: String) -> bool:
	return _is_discovered(KEY_RELICS, relic_id)

static func is_monster_discovered(monster_id: String) -> bool:
	return _is_discovered(KEY_MONSTERS, monster_id)

static func is_event_discovered(event_id: String) -> bool:
	return _is_discovered(KEY_EVENTS, event_id)

static func discovered_ids(key: String) -> Array[String]:
	return _string_array(load_progress().get(key, []))

static func _discover(key: String, id: String) -> void:
	var clean_id := id.strip_edges()
	if clean_id == "":
		return
	var progress := load_progress()
	var ids := _string_array(progress.get(key, []))
	if not ids.has(clean_id):
		ids.append(clean_id)
	progress[key] = ids
	save_progress(progress)

static func _is_discovered(key: String, id: String) -> bool:
	return _string_array(load_progress().get(key, [])).has(id)

static func _normalized_progress(progress: Dictionary) -> Dictionary:
	var normalized := default_progress()
	normalized[KEY_CHARACTERS] = _deduped_string_array(progress.get(KEY_CHARACTERS, []))
	normalized[KEY_RELICS] = _deduped_string_array(progress.get(KEY_RELICS, []))
	normalized[KEY_MONSTERS] = _deduped_string_array(progress.get(KEY_MONSTERS, []))
	normalized[KEY_EVENTS] = _deduped_string_array(progress.get(KEY_EVENTS, []))
	var records: Variant = progress.get(KEY_EVENT_RECORDS, {})
	if records is Dictionary:
		normalized[KEY_EVENT_RECORDS] = (records as Dictionary).duplicate(true)
	return normalized

static func _deduped_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item in _string_array(value):
		if not result.has(item):
			result.append(item)
	return result

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var clean := str(item).strip_edges()
			if clean != "":
				result.append(clean)
	return result
