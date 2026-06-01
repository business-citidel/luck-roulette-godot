class_name DemoSettingsService
extends RefCounted

const SETTINGS_PATH := "user://luck_roulette_settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_VIDEO := "video"
const SECTION_LANGUAGE := "language"
const DEFAULT_LANGUAGE := "ko"
const SUPPORTED_LANGUAGES := ["ko", "en"]

const DEFAULTS := {
	"master_volume": 1.0,
	"bgm_volume": 0.82,
	"sfx_volume": 0.9,
	"fullscreen": false,
	"language": DEFAULT_LANGUAGE
}

static func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		var defaults := DEFAULTS.duplicate(true)
		defaults["language"] = _normalize_language(str(defaults["language"]))
		return defaults
	return {
		"master_volume": float(config.get_value(SECTION_AUDIO, "master_volume", DEFAULTS["master_volume"])),
		"bgm_volume": float(config.get_value(SECTION_AUDIO, "bgm_volume", DEFAULTS["bgm_volume"])),
		"sfx_volume": float(config.get_value(SECTION_AUDIO, "sfx_volume", DEFAULTS["sfx_volume"])),
		"fullscreen": bool(config.get_value(SECTION_VIDEO, "fullscreen", DEFAULTS["fullscreen"])),
		"language": _normalize_language(str(config.get_value(SECTION_LANGUAGE, "locale", DEFAULTS["language"])))
	}

static func save_settings(settings: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, "master_volume", clampf(float(settings.get("master_volume", DEFAULTS["master_volume"])), 0.0, 1.0))
	config.set_value(SECTION_AUDIO, "bgm_volume", clampf(float(settings.get("bgm_volume", DEFAULTS["bgm_volume"])), 0.0, 1.0))
	config.set_value(SECTION_AUDIO, "sfx_volume", clampf(float(settings.get("sfx_volume", DEFAULTS["sfx_volume"])), 0.0, 1.0))
	config.set_value(SECTION_VIDEO, "fullscreen", bool(settings.get("fullscreen", DEFAULTS["fullscreen"])))
	config.set_value(SECTION_LANGUAGE, "locale", _normalize_language(str(settings.get("language", DEFAULTS["language"]))))
	config.save(SETTINGS_PATH)

static func apply_settings(settings: Dictionary) -> void:
	apply_language(str(settings.get("language", DEFAULTS["language"])))
	_apply_bus("Master", float(settings.get("master_volume", DEFAULTS["master_volume"])))
	_apply_bus("BGM", float(settings.get("bgm_volume", DEFAULTS["bgm_volume"])))
	_apply_bus("SFX", float(settings.get("sfx_volume", DEFAULTS["sfx_volume"])))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.get("fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

static func apply_language(language: String) -> void:
	TranslationServer.set_locale(_normalize_language(language))

static func update_value(key: String, value: Variant) -> Dictionary:
	var settings := load_settings()
	settings[key] = value
	save_settings(settings)
	apply_settings(settings)
	return settings

static func current_language() -> String:
	return _normalize_language(str(load_settings().get("language", DEFAULT_LANGUAGE)))

static func _normalize_language(language: String) -> String:
	var clean := language.strip_edges().to_lower()
	if clean.begins_with("en"):
		return "en"
	if clean.begins_with("ko"):
		return "ko"
	if SUPPORTED_LANGUAGES.has(clean):
		return clean
	return DEFAULT_LANGUAGE

static func _apply_bus(bus_name: String, linear_value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var clamped := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, clamped <= 0.001)
	if clamped > 0.001:
		AudioServer.set_bus_volume_db(index, linear_to_db(clamped))
