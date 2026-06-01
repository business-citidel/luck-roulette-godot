class_name GameObjectDisplayBridge
extends RefCounted

const Registry := preload("res://scripts/runtime/registry/game_object_registry.gd")

static func metadata(id: String, kind: String = "") -> Dictionary:
	var object_id := str(id)
	var registry = Registry.with_pilots()
	if not registry.has_object(object_id):
		return {}
	var definition: Dictionary = registry.get_object(object_id)
	if kind != "" and str(definition.get("kind", "")) != kind:
		return {}
	var payload: Dictionary = definition.get("payload", {})
	return {
		"id": object_id,
		"kind": str(definition.get("kind", "")),
		"display_name": str(payload.get("display_name", definition.get("display_name", object_id))),
		"description": str(payload.get("description", "")),
		"icon_id": str(payload.get("icon_id", object_id)),
		"rarity": str(payload.get("rarity", "")),
		"shop_price": int(payload.get("shop_price", 0)),
		"display_key": str(payload.get("display_key", ""))
	}

static func display_name(id: String, kind: String = "", fallback: String = "") -> String:
	var data := metadata(id, kind)
	if data.is_empty():
		return fallback
	return str(data.get("display_name", fallback))

static func description(id: String, kind: String = "", fallback: String = "") -> String:
	var data := metadata(id, kind)
	if data.is_empty():
		return fallback
	var value := str(data.get("description", ""))
	return value if value != "" else fallback

static func icon_id(id: String, kind: String = "", fallback: String = "") -> String:
	var data := metadata(id, kind)
	if data.is_empty():
		return fallback
	var value := str(data.get("icon_id", ""))
	return value if value != "" else fallback

static func rarity(id: String, kind: String = "", fallback: String = "") -> String:
	var data := metadata(id, kind)
	if data.is_empty():
		return fallback
	var value := str(data.get("rarity", ""))
	return value if value != "" else fallback

static func shop_price(id: String, kind: String = "", fallback: int = 0) -> int:
	var data := metadata(id, kind)
	if data.is_empty():
		return fallback
	var value := int(data.get("shop_price", 0))
	return value if value > 0 else fallback

static func display_key(id: String, kind: String = "", fallback: String = "") -> String:
	var data := metadata(id, kind)
	if data.is_empty():
		return fallback
	var value := str(data.get("display_key", ""))
	return value if value != "" else fallback

static func surface_payload(id: String, kind: String, fallback: Dictionary = {}) -> Dictionary:
	var object_id := str(id)
	var result := fallback.duplicate(true)
	var data := metadata(object_id, kind)
	result["object_id"] = object_id
	result["object_kind"] = kind
	if not data.is_empty():
		result["name"] = str(data.get("display_name", result.get("name", object_id)))
		var description_value := str(data.get("description", ""))
		if description_value != "":
			result["description"] = description_value
		var icon_value := str(data.get("icon_id", ""))
		if icon_value != "":
			result["icon_id"] = icon_value
		var rarity_value := str(data.get("rarity", ""))
		if rarity_value != "":
			result["rarity"] = rarity_value
		var price_value := int(data.get("shop_price", 0))
		if price_value > 0:
			result["price"] = price_value
		var display_key_value := str(data.get("display_key", ""))
		if display_key_value != "":
			result["display_key"] = display_key_value
	if not result.has("name"):
		result["name"] = object_id
	if not result.has("description"):
		result["description"] = ""
	if not result.has("icon_id"):
		result["icon_id"] = object_id
	return result
