class_name LegacySlotPlaytestGuard
extends RefCounted

const ENV := "LUCK_ALLOW_LEGACY_SLOT_PLAYTEST"

static func is_allowed() -> bool:
	return OS.get_environment(ENV) == "1"

static func message(script_name: String) -> String:
	return script_name + " is a legacy slot-marble visual playtest. Current proof should use numeric Go/Stop tests. Set " + ENV + "=1 for historical inspection."

