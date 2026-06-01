extends SceneTree

const AssetCatalog := preload("res://scripts/systems/asset_catalog.gd")
const RelicCatalog := preload("res://scripts/systems/relic_catalog.gd")

const P1_IDS: Array[String] = [
	"carbon_copy_coupon",
	"voucher_coupon",
	"paper_shield",
	"wager_padding",
	"jackpot_sparkler",
	"spare_heel",
	"thorn_chip",
	"glass_jackpot"
]

var failures: Array[String] = []

func _initialize() -> void:
	for relic_id in P1_IDS:
		if not RelicCatalog.has_relic(relic_id):
			failures.append("missing relic catalog id " + relic_id)
			continue
		if RelicCatalog.icon_id(relic_id) != relic_id:
			failures.append(relic_id + " should use its dedicated icon id")
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
	if failures.is_empty():
		print("p1 relic design assets smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
