class_name PotionCatalog
extends RefCounted

const DisplayBridge := preload("res://scripts/runtime/systems/game_object_display_bridge.gd")

const RED_RECOVERY := "red_recovery_potion"
const YELLOW_GUARD := "guard_potion"
const GREEN_REWARD := "reward_luck_potion"
const PURPLE_JACKPOT := "jackpot_potion"
const BLUE_DICE := "dice_potion"
const WHITE_WAGER := "wager_potion"
const CYAN_TIME := "time_potion"
const UPGRADE_VOUCHER := "upgrade_voucher"

const RANDOM_POOL := [
	RED_RECOVERY,
	YELLOW_GUARD,
	GREEN_REWARD,
	PURPLE_JACKPOT,
	BLUE_DICE,
	WHITE_WAGER,
	CYAN_TIME
]

static func canonical_id(potion_id: String) -> String:
	match potion_id:
		"attack_potion":
			return PURPLE_JACKPOT
		"roulette_potion":
			return CYAN_TIME
		_:
			return potion_id

static func is_combat_potion(potion_id: String) -> bool:
	return canonical_id(potion_id) in RANDOM_POOL

static func display_key(potion_id: String) -> String:
	var id := canonical_id(potion_id)
	return DisplayBridge.display_key(id, "potion", "potion." + id)
