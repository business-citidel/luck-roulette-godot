extends SceneTree

const CharacterContractCatalog := preload("res://scripts/systems/character_contract_catalog.gd")
const EventCatalog := preload("res://scripts/systems/event_catalog.gd")
const MonsterCatalog := preload("res://scripts/systems/monster_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

const REQUIRED_FIELDS := [
	"id",
	"image_id",
	"visual_ready",
	"implemented",
	"unlocked",
	"rarity",
	"tags"
]

var failures: Array[String] = []

func _initialize() -> void:
	_check_relic_metadata()
	_check_event_metadata()
	_check_monster_metadata()
	_check_character_metadata()

	if failures.is_empty():
		print("content metadata contract smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_relic_metadata() -> void:
	for relic_id in RelicCatalog.all_ids():
		var relic := RelicCatalog.get_relic(relic_id)
		_check_common("relic", relic_id, relic)
		if str(relic.get("image_id", "")) != RelicCatalog.icon_id(relic_id):
			failures.append("relic " + relic_id + " image_id should match icon_id")
		if bool(relic.get("implemented", false)) != (RelicCatalog.implementation_status(relic_id) == "runtime"):
			failures.append("relic " + relic_id + " implemented flag mismatch")

func _check_event_metadata() -> void:
	for event_id in EventCatalog.catalog_event_ids():
		var event := EventCatalog.get_event(event_id)
		_check_common("event", event_id, event)
		if str(event.get("image_id", "")) != event_id:
			failures.append("event " + event_id + " image_id should default to event id")
		var choices: Array = event.get("choices", [])
		if choices.size() < 2:
			failures.append("event " + event_id + " metadata profile lost choices")

func _check_monster_metadata() -> void:
	for monster_id in MonsterCatalog.all_runtime_monster_ids():
		var monster := MonsterCatalog.get_monster(monster_id)
		_check_common("monster", monster_id, monster)
		if str(monster.get("image_id", "")) != monster_id:
			failures.append("monster " + monster_id + " image_id should default to monster id")
		if not bool(monster.get("visual_ready", false)):
			failures.append("monster " + monster_id + " should have runtime visual_ready")

func _check_character_metadata() -> void:
	for character_id in CharacterContractCatalog.all_character_ids():
		var character := CharacterContractCatalog.get_character(character_id)
		_check_common("character", character_id, character)
		if str(character.get("image_id", "")) != character_id:
			failures.append("character " + character_id + " image_id should default to character id")
	var default_character := CharacterContractCatalog.get_character(CharacterContractCatalog.default_character_id())
	if not bool(default_character.get("implemented", false)) or not bool(default_character.get("unlocked", false)):
		failures.append("default character should be implemented and unlocked")

func _check_common(kind: String, id: String, item: Dictionary) -> void:
	for field in REQUIRED_FIELDS:
		if not item.has(field):
			failures.append(kind + " " + id + " missing content metadata field " + str(field))
	if str(item.get("id", "")) == "":
		failures.append(kind + " " + id + " has empty id")
	if str(item.get("image_id", "")) == "":
		failures.append(kind + " " + id + " has empty image_id")
	if not (item.get("tags", []) is Array):
		failures.append(kind + " " + id + " tags should be an array")
