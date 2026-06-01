extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

const P0_ASSET_IDS: Array[String] = [
	"strawberry_chip",
	"warm_canteen",
	"ticket_primer",
	"velvet_price_tag",
	"low_stakes_mat",
	"high_roller_lint",
	"lazy_susan",
	"umbrella_button",
	"cleric_face_coin",
	"preserved_insect_pin",
	"scarred_ticket_punch",
	"noon_duel",
	"golden_table",
	"royal_voucher_press",
	"ivory_ambulance"
]

const RUNTIME_RELIC_IDS: Array[String] = [
	"strawberry_chip",
	"warm_canteen",
	"ticket_primer",
	"velvet_price_tag",
	"low_stakes_mat",
	"high_roller_lint",
	"lazy_susan",
	"umbrella_button",
	"cleric_face_coin",
	"scarred_ticket_punch",
	"ivory_ambulance"
]

var failures: Array[String] = []

func _initialize() -> void:
	for relic_id in P0_ASSET_IDS:
		var icon := AssetCatalog.relic_icon(relic_id)
		var object := AssetCatalog.relic_object(relic_id)
		if icon == null:
			failures.append(relic_id + " icon failed to load")
		elif icon.get_width() != 128 or icon.get_height() != 128:
			failures.append(relic_id + " icon should be 128x128")
		if object == null:
			failures.append(relic_id + " object failed to load")
		elif object.get_width() != 256 or object.get_height() != 256:
			failures.append(relic_id + " object should be 256x256")
	for relic_id in RUNTIME_RELIC_IDS:
		if not RelicCatalog.has_relic(relic_id):
			failures.append("missing relic catalog id " + relic_id)
			continue
		if RelicCatalog.icon_id(relic_id) != relic_id:
			failures.append(relic_id + " should use its dedicated icon id")
	if failures.is_empty():
		print("p0 relic design assets smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
