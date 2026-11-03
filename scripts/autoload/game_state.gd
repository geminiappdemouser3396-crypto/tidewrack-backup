extends Node
## GameState — global save/load and story flags.
##
## Autoloaded as `GameState`. Holds the narrative flags set by dialogue
## choices and persists them to user://save.json so "Continue" works.

signal state_changed

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2

## Story flags set during play, e.g. {"trusted_edith": true}.
var flags: Dictionary = {}
## Path of the scene the player should resume into.
var current_scene: String = "res://scenes/game.tscn"


func set_flag(name: String, value: Variant) -> void:
	flags[name] = value
	state_changed.emit()


func get_flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func new_game() -> void:
	DialogueManager.reset()
	Journal.replace_entries([])
	flags.clear()
	current_scene = "res://scenes/game.tscn"
	state_changed.emit()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"scene": current_scene,
		"flags": flags,  # Includes puzzle flags such as lamp_relit.
		"journal_entries": Journal.entries(),
		"dialogue": DialogueManager.checkpoint(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameState: could not open save file for reading.")
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: save file is corrupt.")
		return false

	var data: Dictionary = parsed
	var version: Variant = data.get("version", 1)
	if version != 1 and version != SAVE_VERSION:
		return false
	var scene: Variant = data.get("scene", "res://scenes/game.tscn")
	if typeof(scene) != TYPE_STRING or not ResourceLoader.exists(scene, "PackedScene"):
		return false
	var loaded_flags: Variant = data.get("flags", {})
	var ids: Variant = []
	var cursor: Variant = {}
	if version == SAVE_VERSION:
		ids = data.get("journal_entries")
		cursor = data.get("dialogue")
		if typeof(ids) != TYPE_ARRAY or typeof(cursor) != TYPE_DICTIONARY or typeof(loaded_flags) != TYPE_DICTIONARY:
			return false
		for id in ids:
			if typeof(id) != TYPE_STRING:
				return false
	# Only the ground-floor scene currently owns a dialogue interface.
	if not cursor.is_empty() and scene != "res://scenes/game.tscn":
		return false
	if not DialogueManager.stage_checkpoint(cursor):
		return false
	current_scene = scene
	flags = loaded_flags if typeof(loaded_flags) == TYPE_DICTIONARY else {}
	Journal.replace_entries(ids)
	state_changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
