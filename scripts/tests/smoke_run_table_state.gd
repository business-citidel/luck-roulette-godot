extends SceneTree

const RunTableState := preload("res://scripts/run/run_table_state.gd")
const UiText := preload("res://scripts/ui/ui_text.gd")

var failures: Array[String] = []

func _initialize() -> void:
	UiText.set_locale("ko")
	var run_payload := {
		"gold": 10,
		"player_hp": 36,
		"player_max_hp": 42,
		"relic_ids": ["loaded_die"],
		"next_combat_mods": [{"id": "rest_prepared_table", "enemy_damage_delta": -3}]
	}
	var pending_result := {
		"accepted": true,
		"choice": "relic",
		"gold_delta": 18,
		"hp_delta": 6,
		"relic_ids": ["green_purse"],
		"next_combat_mods": [{"id": "shop_edge_note", "cash": 5}]
	}
	var table_state: Dictionary = RunTableState.from_run_payload(run_payload, pending_result)
	var ledger: Dictionary = table_state.get("ledger", {})
	if int(ledger.get("gold", 0)) != 10 or int(ledger.get("gold_preview", 0)) != 28:
		failures.append("ledger preview did not include pending gold")
	if int(ledger.get("hp_preview", 0)) != 42:
		failures.append("ledger preview did not clamp pending HP")
	var relics: Array = table_state.get("relic_tray", [])
	if relics.size() != 2:
		failures.append("relic tray did not include owned and incoming relics")
	elif str((relics[1] as Dictionary).get("state", "")) != "incoming":
		failures.append("incoming relic state missing")
	var prep_notes: Array = table_state.get("queued_prep_notes", [])
	if prep_notes.size() != 2:
		failures.append("prep notes did not include queued and incoming notes")
	elif not str((prep_notes[0] as Dictionary).get("description", "")).contains("다음 피해 -3"):
		failures.append("queued prep note description missing direct damage delta")
	var pickup: Dictionary = table_state.get("pickup", {})
	if str(pickup.get("target", "")) != "relic_tray":
		failures.append("mixed relic reward pickup should target relic tray")
	if not ((pickup.get("lines", []) as Array).size() >= 3):
		failures.append("pickup summary did not list reward effects")
	if int(run_payload.get("gold", 0)) != 10 or (run_payload.get("relic_ids", []) as Array).size() != 1:
		failures.append("RunTableState mutated input payload")

	if failures.is_empty():
		print("run table state smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
