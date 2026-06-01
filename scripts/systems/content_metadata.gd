class_name ContentMetadata
extends RefCounted

const RARITY_COMMON := "common"
const RARITY_UNCOMMON := "uncommon"
const RARITY_RARE := "rare"
const RARITY_SPECIAL := "special"

static func apply(base: Dictionary, metadata: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in metadata.keys():
		result[key] = metadata[key]
	return result

static func build(id: String, image_id: String = "", implemented: bool = true, unlocked: bool = true, visual_ready: bool = false, rarity: String = RARITY_COMMON, tags: Array = []) -> Dictionary:
	return {
		"id": id,
		"image_id": image_id if image_id != "" else id,
		"implemented": implemented,
		"unlocked": unlocked,
		"visual_ready": visual_ready,
		"rarity": rarity,
		"tags": _string_array(tags)
	}

static func runtime_relic_visual_ready(image_id: String) -> bool:
	var clean_id := safe_asset_id(image_id)
	if clean_id == "":
		return false
	return _res_file_exists("res://assets/runtime/relics/icons/" + clean_id + "_icon.png") or _res_file_exists("res://assets/runtime/relics/objects/" + clean_id + "_object.png")

static func runtime_event_visual_ready(image_id: String) -> bool:
	var clean_id := safe_asset_id(image_id)
	if clean_id == "":
		return false
	return _res_file_exists("res://assets/runtime/event/illustrations/" + clean_id + "_image.png")

static func runtime_monster_visual_ready(image_id: String) -> bool:
	var clean_id := safe_asset_id(image_id)
	if clean_id == "":
		return false
	return _res_file_exists("res://assets/runtime/combat/opponents/opponent_" + clean_id + "_emblem_001.png")

static func runtime_character_visual_ready(image_id: String) -> bool:
	var clean_id := safe_asset_id(image_id)
	if clean_id == "":
		return false
	return _res_file_exists("res://assets/runtime/characters/" + clean_id + "/select_screen.png") or _res_file_exists("res://assets/runtime/characters/" + clean_id + "/contract_card.png")

static func safe_asset_id(value: String) -> String:
	var result := value.strip_edges().to_lower()
	for ch in [" ", "-", ".", "/", "\\"]:
		result = result.replace(ch, "_")
	return result

static func _res_file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))

static func _string_array(value: Array) -> Array[String]:
	var result: Array[String] = []
	for item in value:
		result.append(str(item))
	return result
