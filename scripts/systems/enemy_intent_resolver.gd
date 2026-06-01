class_name EnemyIntentResolver
extends RefCounted

const UiText := preload("res://scripts/ui/ui_text.gd")

static func next_intent_text(rng: RandomNumberGenerator) -> String:
	var options: Array[int] = [6, 8, 10]
	return UiText.t("battle.intent.damage", {"amount": options[rng.randi_range(0, options.size() - 1)]})

static func enemy_damage(base_damage: int, reduction: int = 0, damage_delta: int = 0) -> int:
	return max(0, base_damage + damage_delta - reduction)
