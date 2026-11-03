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
	# Keep the current slot intact while writing and checking its replacement.
	var temporary_path := ProjectSettings.globalize_path(SAVE_PATH + ".%d.tmp" % OS.get_process_id())
	var serialized := JSON.stringify(payload, "\t")
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not open save file for writing.")
		return false
	file.store_string(serialized)
	file.close()
	if FileAccess.get_file_as_string(temporary_path) != serialized:
		DirAccess.remove_absolute(temporary_path)
		return false
	var result := DirAccess.rename_absolute(temporary_path, ProjectSettings.globalize_path(SAVE_PATH))
	if result != OK:
		DirAccess.remove_absolute(temporary_path)
	return result == OK


func load_game(enter_scene: bool = false) -> bool:
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
	if typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT:
		return false
	if version != 1 and version != SAVE_VERSION:
		return false
	if version == 1 and (data.has("journal_entries") or data.has("dialogue")):
		return false  # Do not silently downgrade an incomplete v2 save.
	if version == SAVE_VERSION and (not data.has("scene") or not data.has("flags")):
		return false
	if not data.has("scene") and not data.has("flags"):
		return false  # An empty object has no legacy progress to restore.
	var scene: Variant = data.get("scene", "res://scenes/game.tscn")
	# Only the ground floor exposes the save menu in this demo.
	if typeof(scene) != TYPE_STRING or scene != "res://scenes/game.tscn":
		return false
	var packed := ResourceLoader.load(scene, "PackedScene") as PackedScene
	if packed == null or not packed.can_instantiate():
		return false
	var loaded_flags: Variant = data.get("flags", {})
	if typeof(loaded_flags) != TYPE_DICTIONARY:
		return false
	var ids: Variant = []
	var cursor: Variant = {}
	if version == SAVE_VERSION:
		ids = data.get("journal_entries")
		cursor = data.get("dialogue")
		if typeof(ids) != TYPE_ARRAY or typeof(cursor) != TYPE_DICTIONARY:
			return false
		for id in ids:
			if typeof(id) != TYPE_STRING:
				return false
	var graph: Dictionary = {}
	if not cursor.is_empty():
		graph = DialogueManager.read_checkpoint_graph(cursor)
		if graph.is_empty():
			return false
	# SceneTree adds the destination at frame end. Commit only after acceptance.
	if enter_scene and get_tree().change_scene_to_packed(packed) != OK:
		return false
	DialogueManager.stage_checkpoint(cursor, graph)
	current_scene = scene
	flags = loaded_flags
	Journal.replace_entries(ids)
	state_changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
