class_name RuntimeGameHook
extends RefCounted

const TURN_START := "turn_start"
const POTION_USED := "potion_used"

const ALL := [
	TURN_START,
	POTION_USED
]

static func is_valid(hook: String) -> bool:
	return hook in ALL
