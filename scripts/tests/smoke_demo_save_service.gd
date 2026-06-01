extends SceneTree

const DemoSaveService := preload("res://scripts/systems/demo_save_service.gd")
const RunState := preload("res://scripts/resources/run_state.gd")

var failures: Array[String] = []

func _initialize() -> void:
	DemoSaveService.clear_save()
	if DemoSaveService.has_save():
		failures.append("save service should start clear after explicit clear")
	var run_state: RunState = RunState.new()
	run_state.seed_text = "save-service-smoke"
	run_state.gold = 77
	run_state.player_hp = 31
	run_state.floor_index = 2
	run_state.map_step = 5
	run_state.character_id = "double_attack_dice"
	run_state.relic_ids = ["loaded_die", "safe_pocket"]
	DemoSaveService.save_run(run_state, {"battles_won": 3})
	if not DemoSaveService.has_save():
		failures.append("save service should report save after writing")
	var payload := DemoSaveService.load_run_state_payload()
	if str(payload.get("seed_text", "")) != "save-service-smoke":
		failures.append("save service did not restore seed")
	if int(payload.get("gold", 0)) != 77:
		failures.append("save service did not restore gold")
	if str(payload.get("character_id", "")) != "double_attack_dice":
		failures.append("save service did not restore character")
	if (payload.get("relic_ids", []) as Array).size() != 2:
		failures.append("save service did not restore relic ids")
	DemoSaveService.clear_save()
	if DemoSaveService.has_save():
		failures.append("save service should clear save")
	if failures.is_empty():
		print("demo save service smoke passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

