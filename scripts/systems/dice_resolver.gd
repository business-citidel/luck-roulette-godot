class_name DiceResolver
extends RefCounted

const DiceRuleCatalog := preload("res://scripts/systems/dice_rule_catalog.gd")

static func default_rule_id() -> String:
	return DiceRuleCatalog.default_rule_id()

static func rule(rule_id: String = "") -> Dictionary:
	return DiceRuleCatalog.get_rule(default_rule_id() if rule_id == "" else rule_id)

static func starting_values(rule_id: String = "") -> Array[int]:
	var next_rule: Dictionary = rule(rule_id)
	var values: Array[int] = []
	for i in range(int(next_rule.get("dice_count", 1))):
		values.append(1)
	return values

static func starting_locks(rule_id: String = "") -> Array[bool]:
	var next_rule: Dictionary = rule(rule_id)
	var locks: Array[bool] = []
	for i in range(int(next_rule.get("dice_count", 1))):
		locks.append(false)
	return locks

static func normalize_values(value: Variant, rule_id: String = "") -> Array[int]:
	var next_rule: Dictionary = rule(rule_id)
	var count: int = int(next_rule.get("dice_count", 1))
	var sides: int = int(next_rule.get("sides", 6))
	var result: Array[int] = []
	if value is Array:
		for item in value:
			result.append(clamp(int(item), 1, sides))
	while result.size() < count:
		result.append(1)
	if result.size() > count:
		result = result.slice(0, count)
	return result

static func normalize_locks(value: Variant, rule_id: String = "") -> Array[bool]:
	var count: int = int(rule(rule_id).get("dice_count", 1))
	var result: Array[bool] = []
	if value is Array:
		for item in value:
			result.append(bool(item))
	while result.size() < count:
		result.append(false)
	if result.size() > count:
		result = result.slice(0, count)
	return result

static func roll_open(values: Array[int], locks: Array[bool], rule_id: String, rng: RandomNumberGenerator) -> Array[int]:
	var next_rule: Dictionary = rule(rule_id)
	var result: Array[int] = normalize_values(values, rule_id)
	var normalized_locks: Array[bool] = normalize_locks(locks, rule_id)
	var sides: int = int(next_rule.get("sides", 6))
	for i in range(result.size()):
		if not normalized_locks[i]:
			result[i] = rng.randi_range(1, sides)
	return result

static func compute_result(values: Variant, locks: Variant, rule_id: String = "", rerolls_left: int = 0, applied_effects: Array = [], selected_attack_die_index: int = -1) -> Dictionary:
	var next_rule: Dictionary = rule(rule_id)
	var resolved_rule_id: String = str(next_rule.get("rule_id", DiceRuleCatalog.default_rule_id()))
	var dice_values: Array[int] = normalize_values(values, resolved_rule_id)
	var dice_locks: Array[bool] = normalize_locks(locks, resolved_rule_id)
	var total: int = 0
	var highest: int = 0
	for value in dice_values:
		total += value
		highest = max(highest, value)
	var attack_base: int = total
	var guard_value: int = 0
	var selected_index: int = -1
	match str(next_rule.get("attack_base_mode", "sum")):
		"highest":
			attack_base = highest
		"choice_attack_guard":
			if selected_attack_die_index >= 0 and selected_attack_die_index < dice_values.size():
				selected_index = selected_attack_die_index
				attack_base = dice_values[selected_index]
				for i in range(dice_values.size()):
					if i != selected_index:
						guard_value += dice_values[i]
			else:
				attack_base = 0
		"choice_double_attack":
			if selected_attack_die_index >= 0 and selected_attack_die_index < dice_values.size():
				selected_index = selected_attack_die_index
				attack_base = total
			else:
				attack_base = 0
		_:
			attack_base = total
	return {
		"accepted": true,
		"dice_values": dice_values,
		"dice": dice_values.duplicate(),
		"dice_locked": dice_locks,
		"rerolls_left": rerolls_left,
		"attack_base": max(0, attack_base),
		"guard_value": max(0, guard_value),
		"selected_attack_die_index": selected_index,
		"dice_total": total,
		"dice_rule_id": resolved_rule_id,
		"dice_rule": next_rule.duplicate(true),
		"applied_effects": applied_effects.duplicate(true)
	}
