class_name DicePushResolver
extends RefCounted

const MAX_PUSHES := 3
const MIN_TOTAL := 2
const MAX_TOTAL := 12

static func can_push(current_total: int, push_count: int) -> bool:
	return push_count < MAX_PUSHES and current_total >= MIN_TOTAL and current_total < MAX_TOTAL

static func band_for_total(current_total: int) -> String:
	if current_total >= MAX_TOTAL:
		return "locked"
	if current_total == 11:
		return "high"
	if current_total >= 7:
		return "middle"
	return "low"

static func resolve_push(current_total: int, new_total: int, push_count: int) -> Dictionary:
	var normalized_current := clampi(current_total, MIN_TOTAL, MAX_TOTAL)
	var normalized_new := clampi(new_total, MIN_TOTAL, MAX_TOTAL)
	var next_count := push_count + 1
	if not can_push(normalized_current, push_count):
		return {
			"accepted": false,
			"success": false,
			"failed": false,
			"locked": true,
			"current_total": normalized_current,
			"new_total": normalized_new,
			"attack_value": normalized_current,
			"band": band_for_total(normalized_current),
			"push_count": push_count,
			"reason": "unavailable"
		}
	var band := band_for_total(normalized_current)
	if normalized_new <= normalized_current:
		return {
			"accepted": true,
			"success": false,
			"failed": true,
			"locked": true,
			"current_total": normalized_new,
			"new_total": normalized_new,
			"attack_value": int(floor(float(normalized_new) / 2.0)),
			"band": band,
			"push_count": next_count,
			"reason": "lower_or_equal"
		}
	var attack_value := normalized_new
	match band:
		"low":
			attack_value = max(0, normalized_new - 2)
		"middle":
			attack_value = normalized_new + 1
		"high":
			attack_value = normalized_new * 2
	return {
		"accepted": true,
		"success": true,
		"failed": false,
		"locked": normalized_new >= MAX_TOTAL or next_count >= MAX_PUSHES,
		"current_total": normalized_new,
		"new_total": normalized_new,
		"attack_value": attack_value,
		"band": band,
		"push_count": next_count,
		"reason": "higher"
	}
