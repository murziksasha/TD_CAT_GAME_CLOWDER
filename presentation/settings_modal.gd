# Clowder: Alley Siege - Settings & Accessibility Modal
class_name SettingsModal
extends PanelContainer

const SimSaveManager = preload("res://sim/save_manager.gd")

signal closed
signal settings_changed

var save_mgr: SimSaveManager
var auto_start_check: CheckBox
var shake_btn: OptionButton
var flash_check: CheckBox
var text_scale_btn: OptionButton
var audio_slider: HSlider
var lang_btn: OptionButton

func setup(p_save_mgr: SimSaveManager) -> void:
	save_mgr = p_save_mgr
	_build_ui()
	_load_current_settings()

func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 480)
	offset_left = 360.0
	offset_top = 120.0
	offset_right = 920.0
	offset_bottom = 600.0

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	add_child(root_vbox)

	# Header
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "⚙ Settings & Accessibility"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = " ✕ Close "
	close_btn.pressed.connect(func():
		visible = false
		closed.emit()
	)
	header_hbox.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# 0. Auto-Start Waves
	var auto_hbox := HBoxContainer.new()
	root_vbox.add_child(auto_hbox)
	var auto_lbl := Label.new()
	auto_lbl.text = "Auto-Start Waves (0.4s delay):"
	auto_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_hbox.add_child(auto_lbl)

	auto_start_check = CheckBox.new()
	auto_start_check.text = "Enabled"
	auto_start_check.toggled.connect(_on_setting_changed)
	auto_hbox.add_child(auto_start_check)

	# 1. Screen Shake
	var shake_hbox := HBoxContainer.new()
	root_vbox.add_child(shake_hbox)
	var shake_lbl := Label.new()
	shake_lbl.text = "Screen Shake Impact:"
	shake_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shake_hbox.add_child(shake_lbl)

	shake_btn = OptionButton.new()
	shake_btn.custom_minimum_size = Vector2(160, 36)
	shake_btn.add_item("Off", 0)
	shake_btn.add_item("Low (Default)", 1)
	shake_btn.add_item("Full", 2)
	shake_btn.item_selected.connect(_on_setting_changed)
	shake_hbox.add_child(shake_btn)

	# 2. VFX Flash Limiter
	var flash_hbox := HBoxContainer.new()
	root_vbox.add_child(flash_hbox)
	var flash_lbl := Label.new()
	flash_lbl.text = "Reduce High-Intensity Flashes:"
	flash_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flash_hbox.add_child(flash_lbl)

	flash_check = CheckBox.new()
	flash_check.text = "Enabled"
	flash_check.toggled.connect(_on_setting_changed)
	flash_hbox.add_child(flash_check)

	# 3. Text Scaling
	var text_hbox := HBoxContainer.new()
	root_vbox.add_child(text_hbox)
	var text_lbl := Label.new()
	text_lbl.text = "UI Text Scaling:"
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_hbox.add_child(text_lbl)

	text_scale_btn = OptionButton.new()
	text_scale_btn.custom_minimum_size = Vector2(160, 36)
	text_scale_btn.add_item("100% (Default)", 0)
	text_scale_btn.add_item("125%", 1)
	text_scale_btn.add_item("150%", 2)
	text_scale_btn.item_selected.connect(_on_setting_changed)
	text_hbox.add_child(text_scale_btn)

	# 4. Audio Volume
	var audio_vbox := VBoxContainer.new()
	root_vbox.add_child(audio_vbox)
	var audio_lbl := Label.new()
	audio_lbl.text = "Audio Synthesizer Volume:"
	audio_vbox.add_child(audio_lbl)

	audio_slider = HSlider.new()
	audio_slider.min_value = 0.0
	audio_slider.max_value = 1.0
	audio_slider.step = 0.05
	audio_slider.value = 0.8
	audio_slider.value_changed.connect(_on_setting_changed)
	audio_vbox.add_child(audio_slider)

	# 5. Language
	var lang_hbox := HBoxContainer.new()
	root_vbox.add_child(lang_hbox)
	var lang_lbl := Label.new()
	lang_lbl.text = "Game Language:"
	lang_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_hbox.add_child(lang_lbl)

	lang_btn = OptionButton.new()
	lang_btn.custom_minimum_size = Vector2(160, 36)
	lang_btn.add_item("English (EN)", 0)
	lang_btn.add_item("Українська (UK)", 1)
	lang_btn.item_selected.connect(_on_setting_changed)
	lang_hbox.add_child(lang_btn)

func _load_current_settings() -> void:
	if save_mgr == null:
		return
	var s: Dictionary = save_mgr.data.get("settings", {})

	auto_start_check.button_pressed = bool(s.get("auto_start", false))

	match str(s.get("screen_shake", "low")):
		"off": shake_btn.selected = 0
		"low": shake_btn.selected = 1
		"full": shake_btn.selected = 2

	flash_check.button_pressed = bool(s.get("vfx_reduced", false))

	match int(s.get("text_scale", 100)):
		100: text_scale_btn.selected = 0
		125: text_scale_btn.selected = 1
		150: text_scale_btn.selected = 2

	audio_slider.value = float(s.get("audio_volume", 0.8))

	var l = str(s.get("language", "en"))
	lang_btn.selected = 1 if l == "uk" else 0

func _on_setting_changed(_val = null) -> void:
	if save_mgr == null:
		return
	var s: Dictionary = save_mgr.data.get("settings", {})

	s["auto_start"] = auto_start_check.button_pressed

	var shake_options = ["off", "low", "full"]
	s["screen_shake"] = shake_options[shake_btn.selected]

	s["vfx_reduced"] = flash_check.button_pressed

	var scale_options = [100, 125, 150]
	s["text_scale"] = scale_options[text_scale_btn.selected]

	s["audio_volume"] = audio_slider.value

	s["language"] = "uk" if lang_btn.selected == 1 else "en"

	save_mgr.data["settings"] = s
	save_mgr.save_profile()
	settings_changed.emit()
