extends SceneTree

# Every card description (base and upgraded, every locale) must fit inside the
# card's description box after LabelUtils.fit_text has shrunk it.
# Rendered runs also save a sheet of the longest descriptions for review.
const BOX_H := 70.0
# strings_*.csv의 모든 언어. en이 먼저 와야 번역이 빠진(영어 그대로인) 설명을 가려낼 수 있다.
const LOCALES := ["en", "ko", "fr", "it", "es", "ja", "el", "zh", "zh_TW", "ru", "pt", "pl", "de"]
const SHEET_COUNT := 12

var passed := 0
var _en_texts: Dictionary = {}  # 카드 순번 → 영어 설명
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var gm: Node = root.get_node("GameManager")
	var cards: Array = []
	for card: Resource in load("res://resources/card_catalog.gd").get_all_cards():
		cards.append(card)
		if card.can_upgrade():
			var up: Resource = card.duplicate(true)
			gm.upgrade_card(up)
			cards.append(up)
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		await _check_locale(cards, locale)
	print("Card text fit: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _check_locale(cards: Array, locale: String) -> void:
	var scene: PackedScene = load("res://scenes/card/card_scene_v2.tscn")
	var holder := Control.new()
	root.add_child(holder)
	var nodes: Array = []
	for card: Resource in cards:
		var node: Control = scene.instantiate()
		holder.add_child(node)
		node.setup(card, node.Mode.REWARD)
		nodes.append(node)
	# fit_text shrinks one point per frame (14 → 9 worst case).
	for i in 30:
		await process_frame
	var rows: Array = []
	for i in nodes.size():
		var lbl: Label = nodes[i]._desc_label
		var used: float = lbl.get_line_count() * lbl.get_line_height()
		var ok: bool = used <= BOX_H + 1.0
		if locale == "en":
			_en_texts[i] = lbl.text
		var native: bool = locale == "en" or not _mostly_english(lbl.text, _en_texts.get(i, ""))
		rows.append({"used": used, "len": lbl.text.length(), "native": native, "card": cards[i], "size": lbl.get_theme_font_size("font_size")})
		if ok:
			passed += 1
		else:
			failed += 1
			printerr("FAIL: [%s] %s (+%d) overflows: %.0f > %.0f at %dpx — %s" % [locale, cards[i].card_name, cards[i].upgrade_level, used, BOX_H, rows[-1].size, lbl.text])
	# 확인용 사진은 그 언어로 번역된 설명 중 긴 것부터 고른다.
	rows.sort_custom(func(a, b): return a.len > b.len if a.native == b.native else a.native)
	var smallest := 999
	for r in rows:
		smallest = mini(smallest, r.size)
	var untranslated := rows.filter(func(r): return not r.native).size()
	print("[%s] %d cards, longest translated text %d chars at %dpx, smallest font %dpx, %d still in English" % [locale, rows.size(), rows[0].len, rows[0].size, smallest, untranslated])
	holder.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await _save_sheet(scene, rows.slice(0, SHEET_COUNT), locale)

# 가장 긴 설명 카드들을 1.5배로 늘어놓고 찍는다(카드 선택 화면과 같은 배율).
func _save_sheet(scene: PackedScene, rows: Array, locale: String) -> void:
	var holder := Control.new()
	root.add_child(holder)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.09)
	bg.size = Vector2(1920, 1080)
	holder.add_child(bg)
	var s := 1.5
	for i in rows.size():
		var node: Control = scene.instantiate()
		var cell := Vector2(40 + (i % 6) * 310, 40 + (i / 6) * 500)
		holder.add_child(node)
		root.get_node("GameSettings").apply_card_transform(node, cell + Vector2(70.0 * (s - 1.0), 200.0 * (s - 1.0)), Vector2(70.0, 200.0), s)
		node.setup(rows[i].card, node.Mode.REWARD)
	for i in 60:
		await process_frame
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("STSL_UI_CAPTURE_OUTPUT")
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
		root.get_texture().get_image().save_png(out.path_join("card_text_longest_%s.png" % locale))
	holder.queue_free()
	await process_frame

# 일부만 번역된 문장("ブロック 4 Cancel a counterable…")도 영어로 친다: 낱말 절반 이상이 영어 설명과 같으면.
func _mostly_english(text: String, en_text: String) -> bool:
	var en_words := {}
	for w in en_text.split(" ", false):
		en_words[w] = true
	var words := text.split(" ", false)
	var shared := 0
	for w in words:
		if en_words.has(w):
			shared += 1
	return words.size() > 0 and shared * 2 >= words.size()
