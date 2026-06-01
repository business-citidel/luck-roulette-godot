class_name NumericRouletteResolver
extends RefCounted

const DEFAULT_MULTIPLIERS: Array[float] = [0.0, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 1.5, 1.5, 3.0]
const CELL_BONUS_KEY_PREFIX := "numeric_roulette_cell_bonus_"

static func cell_count() -> int:
	return DEFAULT_MULTIPLIERS.size()

static func cells(run_upgrades: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(DEFAULT_MULTIPLIERS.size()):
		var multiplier := multiplier_for_index(i, run_upgrades)
		result.append({
			"index": i,
			"multiplier": multiplier,
			"label": multiplier_label(multiplier),
			"color": color_for_multiplier(multiplier),
			"base_multiplier": float(DEFAULT_MULTIPLIERS[i]),
			"upgrade_cost": upgrade_cost_for_index(i, run_upgrades),
			"next_multiplier": upgraded_multiplier(multiplier)
		})
	return result

static func multiplier_for_index(index: int, run_upgrades: Dictionary = {}) -> float:
	if DEFAULT_MULTIPLIERS.is_empty():
		return 1.0
	var normalized_index := wrapi(index, 0, DEFAULT_MULTIPLIERS.size())
	return _snapped_multiplier(float(DEFAULT_MULTIPLIERS[normalized_index]) + cell_bonus_for_index(normalized_index, run_upgrades))

static func pick_index(rng: RandomNumberGenerator) -> int:
	if DEFAULT_MULTIPLIERS.is_empty():
		return 0
	return rng.randi_range(0, DEFAULT_MULTIPLIERS.size() - 1)

static func spin(rng: RandomNumberGenerator, forced_index: int = -1, run_upgrades: Dictionary = {}) -> Dictionary:
	var index := forced_index if forced_index >= 0 else pick_index(rng)
	index = wrapi(index, 0, DEFAULT_MULTIPLIERS.size())
	var multiplier := multiplier_for_index(index, run_upgrades)
	return {
		"index": index,
		"multiplier": multiplier,
		"label": multiplier_label(multiplier),
		"color": color_for_multiplier(multiplier)
	}

static func cell_bonus_key(index: int) -> String:
	return CELL_BONUS_KEY_PREFIX + str(wrapi(index, 0, DEFAULT_MULTIPLIERS.size()))

static func cell_bonus_for_index(index: int, run_upgrades: Dictionary) -> float:
	if DEFAULT_MULTIPLIERS.is_empty():
		return 0.0
	var normalized_index := wrapi(index, 0, DEFAULT_MULTIPLIERS.size())
	return float(run_upgrades.get(cell_bonus_key(normalized_index), 0.0))

static func upgrade_cost_for_index(index: int, run_upgrades: Dictionary = {}) -> int:
	return upgrade_cost_for_multiplier(multiplier_for_index(index, run_upgrades))

static func upgrade_cost_for_multiplier(multiplier: float) -> int:
	if _approximately(multiplier, 0.5):
		return 1
	if _approximately(multiplier, 1.0):
		return 2
	if _approximately(multiplier, 1.5):
		return 3
	return 0

static func upgraded_multiplier(multiplier: float) -> float:
	if _approximately(multiplier, 0.5):
		return 1.0
	if _approximately(multiplier, 1.0):
		return 1.5
	if _approximately(multiplier, 1.5):
		return 3.0
	return multiplier

static func upgrade_delta_for_index(index: int, run_upgrades: Dictionary = {}) -> float:
	var current := multiplier_for_index(index, run_upgrades)
	var next := upgraded_multiplier(current)
	return max(0.0, _snapped_multiplier(next - current))

static func can_upgrade_index(index: int, run_upgrades: Dictionary = {}, voucher_count: int = -1) -> bool:
	var cost := upgrade_cost_for_index(index, run_upgrades)
	if cost <= 0:
		return false
	return voucher_count < 0 or voucher_count >= cost

static func wager_multiplier(committed_marbles: int) -> float:
	var clamped := clampi(committed_marbles, 0, 4)
	return 1.0 + float(clamped) * 0.25

static func preview_damage(stake_damage: int, roulette_multiplier: float, committed_marbles: int, player_damage_multiplier: float = 1.0) -> int:
	var raw: float = float(max(0, stake_damage)) * max(0.0, roulette_multiplier) * wager_multiplier(committed_marbles)
	return max(0, int(round(raw * max(0.0, player_damage_multiplier))))

static func multiplier_label(multiplier: float) -> String:
	if abs(multiplier - round(multiplier)) < 0.001:
		return "x" + str(int(round(multiplier)))
	return "x" + str(snapped(multiplier, 0.01))

static func color_for_multiplier(multiplier: float) -> String:
	if multiplier <= 0.0:
		return "#dd4e59"
	if multiplier < 1.0:
		return "#d9c46d"
	if multiplier < 1.5:
		return "#60cf86"
	if multiplier < 3.0:
		return "#4fa9ff"
	return "#a879ef"

static func _approximately(left: float, right: float) -> bool:
	return abs(left - right) < 0.001

static func _snapped_multiplier(value: float) -> float:
	return snapped(value, 0.01)
