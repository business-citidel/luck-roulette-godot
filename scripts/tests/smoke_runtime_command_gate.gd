extends SceneTree

const Command := preload("res://scripts/runtime/core/game_command.gd")
const CommandGate := preload("res://scripts/runtime/core/game_command_gate.gd")
const Hook := preload("res://scripts/runtime/core/game_hook.gd")
const Registry := preload("res://scripts/runtime/registry/game_object_registry.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_check_contract()
	_check_gate()
	_check_registry()
	_finish()

func _check_contract() -> void:
	_assert_eq(Hook.is_valid("turn_start"), true, "turn start hook valid")
	_assert_eq(Hook.is_valid("missing"), false, "missing hook invalid")
	_assert_eq(Command.validate(Command.make(Command.CASH, "turn_token", "player", 1)).is_empty(), true, "valid cash command")
	_assert_eq(Command.validate(Command.make("bad", "", "player", 1)).is_empty(), false, "bad command rejected")

func _check_gate() -> void:
	var result := CommandGate.apply_batch({
		"cash": 8,
		"player_block": 0,
		"active_potion_ids": ["guard_potion"],
		"consumed_potion_ids": [],
		"applied_effects": []
	}, [
		Command.make(Command.CASH, "turn_token", "player", 1, {"relic_id": "turn_token", "effect_id": "turn_cash_tip"}),
		Command.make(Command.BLOCK, "guard_potion", "player", 10, {"potion_id": "guard_potion", "effect_id": "guard_potion_block"}),
		Command.make(Command.CONSUME_POTION, "guard_potion", "guard_potion", 0, {"id": "guard_potion"})
	])
	var state: Dictionary = result.get("state", {})
	_assert_eq(result.get("ok"), true, "gate ok")
	_assert_eq(state.get("cash"), 9, "cash applied")
	_assert_eq(state.get("player_block"), 10, "block applied")
	_assert_eq((state.get("active_potion_ids", []) as Array).has("guard_potion"), false, "potion consumed from active")
	_assert_eq((state.get("consumed_potion_ids", []) as Array).has("guard_potion"), true, "potion added to consumed")
	_assert_eq((state.get("applied_effects", []) as Array).size(), 2, "effects recorded")

func _check_registry() -> void:
	var registry = Registry.with_pilots()
	_assert_eq(registry.has_object("turn_token"), true, "registry has turn token")
	_assert_eq(registry.has_object("guard_potion"), true, "registry has guard potion")
	var commands: Array[Dictionary] = registry.dispatch_hook("turn_start", {"cash": 8}, {}, ["turn_token"])
	_assert_eq(commands.size(), 1, "turn token emits command")
	_assert_eq((commands[0] as Dictionary).get("type"), Command.CASH, "turn token cash command")

func _finish() -> void:
	if failures.is_empty():
		print("runtime command gate smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
