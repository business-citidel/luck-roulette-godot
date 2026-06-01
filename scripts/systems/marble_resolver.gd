class_name MarbleResolver
extends RefCounted

const NEUTRAL_TOKEN := "plain"

static func neutral_token() -> String:
	return NEUTRAL_TOKEN

static func token_from_die(_value: int) -> String:
	return neutral_token()

static func color_from_die(value: int) -> String:
	var _ignored_value := value
	return neutral_token()

static func landing_slot_for_marble(color: String, throw_power: float, rng: RandomNumberGenerator) -> String:
	var _ignored_color := color
	var options: Array[String] = ["safe", "profit", "jackpot", "bust", "overdrive"]
	if throw_power > 1.2:
		options.append("jackpot")
		options.append("overdrive")
	return options[rng.randi_range(0, options.size() - 1)]
