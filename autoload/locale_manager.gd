# autoload/locale_manager.gd
extends Node

const SETTINGS_PATH := "user://settings.cfg"
const LOCALES: Array[String] = ["ko", "en", "fr", "it", "es", "ja", "el", "zh"]
const DISPLAY_NAMES := {
	"ko": "한국어",
	"en": "English",
	"fr": "Français",
	"it": "Italiano",
	"es": "Español",
	"ja": "日本語",
	"el": "Ελληνικά",
	"zh": "中文",
}

signal locale_changed(new_locale: String)

var current_locale: String = "ko"

func _ready() -> void:
	_load_locale()
	_setup_fonts()
	TranslationServer.set_locale(current_locale)
	print("[Locale] boot → %s" % current_locale)

func _setup_fonts() -> void:
	const FONT_PATH := "res://resources/theme/fonts/NotoSans-Regular.ttf"
	if not ResourceLoader.exists(FONT_PATH):
		return
	var main_font: FontFile = load(FONT_PATH)
	const CJK_PATH := "res://resources/theme/fonts/NotoSansCJK-Regular.ttc"
	if ResourceLoader.exists(CJK_PATH):
		main_font.fallbacks.append(load(CJK_PATH))
	const AR_PATH := "res://resources/theme/fonts/NotoSansArabic-Regular.ttf"
	if ResourceLoader.exists(AR_PATH):
		main_font.fallbacks.append(load(AR_PATH))
	ThemeDB.get_project_theme().default_font = main_font

func set_locale(code: String) -> void:
	if not code in LOCALES:
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
