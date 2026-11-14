class_name ClowderLocalization
extends RefCounted

const EN_PATH := "res://content/locales/en.json"
const UK_PATH := "res://content/locales/uk.json"

var language := "en"
var english: Dictionary = {}
var selected: Dictionary = {}

func setup(preferred_language: String = "en") -> void:
	english = _read_catalogue(EN_PATH)
	language = "uk" if preferred_language == "uk" else "en"
	selected = _read_catalogue(UK_PATH if language == "uk" else EN_PATH)

func toggle() -> void:
	setup("uk" if language == "en" else "en")

func text(key: String, fallback: String = "", replacements: Dictionary = {}) -> String:
	var value := str(selected.get(key, english.get(key, fallback)))
	for token in replacements:
		value = value.replace("{%s}" % token, str(replacements[token]))
	return value

func _read_catalogue(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	return json.data if json.parse(file.get_as_text()) == OK and json.data is Dictionary else {}
