extends SceneTree

const BattleScene := preload("res://scenes/battle/battle_scene.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	var battle: Control = BattleScene.instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.set("banner_alpha", 1.0)
	battle.set("enemy_flash", 0.25)
	battle.set("wheel_pointer_kick", 0.1)
	battle._process(0.5)
	_assert_eq(float(battle.get("banner_alpha")), 0.6, "scene banner decay")
	_assert_eq(float(battle.get("enemy_flash")), 0.0, "scene enemy decay clamp")
	_assert_eq(float(battle.get("wheel_pointer_kick")), 0.0, "scene pointer decay clamp")
	battle.queue_free()
	await process_frame
	if failures.is_empty():
		print("battle visual decay bridge smoke passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append(label + " expected " + str(expected) + " got " + str(actual))
