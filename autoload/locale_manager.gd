# autoload/locale_manager.gd
extends Node

const SETTINGS_PATH := "user://settings.cfg"
const LOCALES: Array[String] = ["ko", "en", "fr", "it", "es", "ar", "ja", "el", "zh"]
const DISPLAY_NAMES := {
	"ko": "한국어",
	"en": "English",
	"fr": "Français",
	"it": "Italiano",
	"es": "Español",
	"ar": "العربية",
	"ja": "日本語",
	"el": "Ελληνικά",
	"zh": "中文",
}

signal locale_changed(new_locale: String)

var current_locale: String = "ko"

func _ready() -> void:
	_load_locale()
	TranslationServer.set_locale(current_locale)
	print("[Locale] boot → %s" % current_locale)

func set_locale(code: String) -> void:
	if not code in LOCALES:
		push_warning("Unknown locale: %s" % code)
		return
	current_locale = code
	TranslationServer.set_locale(code)
	_save_locale()
	emit_signal("locale_changed", code)

func get_display_name(code: String) -> String:
	return DISPLAY_NAMES.get(code, code)

func _save_locale() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("locale", "current", current_locale)
	cfg.save(SETTINGS_PATH)

func _load_locale() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	current_locale = cfg.get_value("locale", "current", "ko")
