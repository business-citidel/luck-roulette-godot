extends SceneTree

const MarbleCatalog := preload("res://scripts/systems/marble_catalog.gd")
const MarbleDeckState := preload("res://scripts/resources/marble_deck_state.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var deck: MarbleDeckState = MarbleDeckState.new()
	deck.reset_starting_deck(rng)
	_assert_eq(deck.zone_counts().get("all"), 9, "starting deck size")
	_assert_eq(deck.zone_counts().get("bag"), 9, "starting bag size")
	var revealed := deck.reveal_next(rng)
	_assert_eq(revealed.size(), MarbleCatalog.REVEAL_COUNT, "reveal count")
	var selected := deck.choose_revealed(0)
	_assert_eq(selected.is_empty(), false, "selected marble exists")
	_assert_eq(deck.zone_counts().get("discard"), 2, "unselected choices discarded")
	deck.finish_selected(rng)
	_assert_eq(deck.zone_counts().get("discard"), 3, "selected marble discarded after turn")
	_assert_eq(deck.zone_counts().get("bag"), 6, "bag keeps remaining cycle marbles")
	for _i in range(2):
		deck.reveal_next(rng)
		deck.choose_revealed(0)
		deck.finish_selected(rng)
	_assert_eq(deck.zone_counts().get("bag"), 9, "empty bag reshuffles discard after turn")
	_assert_eq(deck.zone_counts().get("discard"), 0, "discard clears after reshuffle")
	_finish()

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))

func _finish() -> void:
	if failures.is_empty():
		print("marble deck state smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
