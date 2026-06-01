class_name BattleVisualDecay
extends RefCounted

const DECAY_RATES := {
	"banner_alpha": 0.8,
	"enemy_flash": 2.5,
	"player_flash": 2.2,
	"table_pulse": 1.8,
	"dice_roll_fx": 2.6,
	"marble_feedback_alpha": 3.2,
	"slot_feedback_alpha": 2.6,
	"wheel_tick_flash": 7.0,
	"wheel_pointer_kick": 8.0,
	"table_hit_flash": 2.8,
	"opponent_reaction": 1.9,
	"spin_ready_flash": 1.7
}

static func decay_fields() -> Array[String]:
	var fields: Array[String] = []
	for field in DECAY_RATES.keys():
		fields.append(str(field))
	return fields

static func state_patch(snapshot: Dictionary, delta: float) -> Dictionary:
	var patch := {"dirty": false}
	for field in decay_fields():
		var current := float(snapshot.get(field, 0.0))
		if current <= 0.0:
			continue
		patch[field] = maxf(0.0, current - delta * float(DECAY_RATES.get(field, 0.0)))
		patch["dirty"] = true
	return patch
