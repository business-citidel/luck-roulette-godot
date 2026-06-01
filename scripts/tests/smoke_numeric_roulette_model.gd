extends SceneTree

const NumericRouletteResolver := preload("res://scripts/systems/numeric_roulette_resolver.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var cells: Array[Dictionary] = NumericRouletteResolver.cells()
	if cells.size() != 10:
		failures.append("numeric roulette should start with 10 cells")
	var expected: Array[float] = [0.0, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 1.5, 1.5, 3.0]
	for i in range(expected.size()):
		if abs(float(cells[i].get("multiplier", -1.0)) - expected[i]) > 0.001:
			failures.append("numeric roulette cell " + str(i) + " had wrong multiplier")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234
	var forced: Dictionary = NumericRouletteResolver.spin(rng, 9)
	if int(forced.get("index", -1)) != 9 or abs(float(forced.get("multiplier", 0.0)) - 3.0) > 0.001:
		failures.append("forced numeric roulette index did not resolve")
	var upgraded_cells := NumericRouletteResolver.cells({"numeric_roulette_cell_bonus_1": 0.5})
	if abs(float(upgraded_cells[1].get("multiplier", 0.0)) - 1.0) > 0.001:
		failures.append("numeric roulette cell upgrade did not raise x0.5 to x1")
	if NumericRouletteResolver.upgrade_cost_for_index(1, {"numeric_roulette_cell_bonus_1": 0.5}) != 2:
		failures.append("upgraded x1 cell should cost 2 for next tier")
	var upgraded_forced: Dictionary = NumericRouletteResolver.spin(rng, 1, {"numeric_roulette_cell_bonus_1": 0.5})
	if abs(float(upgraded_forced.get("multiplier", 0.0)) - 1.0) > 0.001:
		failures.append("forced numeric roulette index did not use cell upgrade")
	if abs(NumericRouletteResolver.wager_multiplier(0) - 1.0) > 0.001:
		failures.append("zero wager multiplier should be x1")
	if abs(NumericRouletteResolver.wager_multiplier(4) - 2.0) > 0.001:
		failures.append("four wager marbles should cap at x2")
	if abs(NumericRouletteResolver.wager_multiplier(8) - 2.0) > 0.001:
		failures.append("wager multiplier cap should hold above four marbles")
	if NumericRouletteResolver.preview_damage(8, 1.5, 2) != 18:
		failures.append("numeric roulette damage preview should multiply stake, roulette, and wager")

	if failures.is_empty():
		print("numeric roulette model smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
