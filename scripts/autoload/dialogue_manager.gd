extends Node
## DialogueManager — plays JSON-driven branching dialogue graphs.
##
## Autoloaded as `DialogueManager`. A graph is a dictionary of node id -> node.
## Each node:
##   { "speaker": String, "text": String,
##     "next": String|null,                     # linear node; null ends the graph
##     "choices": [ {"text": String, "next": String, "set_flag": {..}} ],
##     "set_flag": { "flag_name": value } }      # applied when the node is entered
##
## UI (dialogue_box.gd) listens to these signals; it does not read the graph.

signal dialogue_started
signal line_shown(speaker: String, text: String, choices: Array)
signal dialogue_finished

var _graph: Dictionary = {}
var _graph_path: String = ""
var _current_id: String = ""
var is_active: bool = false


func start(path: String, start_id: String = "start") -> bool:
	var graph := _load_graph(path)
	if not graph.has(start_id):
		return false
	_graph = graph
	_graph_path = path
	is_active = true
	dialogue_started.emit()
	_goto(start_id)
	return true


func checkpoint() -> Dictionary:
	if not is_active:
		return {}
	return {"graph": _graph_path, "node": _current_id}


## Read and validate without touching the live or previously staged conversation.
func read_checkpoint_graph(cursor: Dictionary) -> Dictionary:
	var path: Variant = cursor.get("graph")
	var id: Variant = cursor.get("node")
	if typeof(path) != TYPE_STRING or typeof(id) != TYPE_STRING or id.is_empty():
		return {}
	if not path.begins_with("res://data/dialogue/") or path.contains("..") or not path.ends_with(".json"):
		return {}
	var graph := _load_graph(path)
	if typeof(graph.get(id)) != TYPE_DICTIONARY:
		return {}
	return graph


func stage_checkpoint(cursor: Dictionary, graph: Dictionary) -> void:
	reset()
	if not cursor.is_empty():
		_graph = graph
		_graph_path = cursor["graph"]
		_current_id = cursor["node"]


func resume_checkpoint() -> void:
	if is_active or _current_id.is_empty():
		return
	is_active = true
	dialogue_started.emit()
	# Node-entry effects are already included in the restored flags.
	_show_line(_graph[_current_id])


## Advance a linear node (no choices). Ignored while choices are pending.
func advance() -> void:
	if not is_active:
		return
	var node: Dictionary = _graph.get(_current_id, {})
	if node.has("choices") and not (node["choices"] as Array).is_empty():
		return  # waiting on choose()
	var next: Variant = node.get("next", null)
	if next == null:
		_finish()
	else:
		_goto(str(next))


## Pick choice `index` on a choice node.
func choose(index: int) -> void:
	if not is_active:
		return
	var node: Dictionary = _graph.get(_current_id, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	_apply_flags(choice.get("set_flag", {}))
	var next: Variant = choice.get("next", null)
	if next == null:
		_finish()
	else:
		_goto(str(next))


func _goto(id: String) -> void:
	if not _graph.has(id):
		push_error("DialogueManager: missing node '%s'." % id)
		_finish()
		return
	_current_id = id
	var node: Dictionary = _graph[id]
	_apply_flags(node.get("set_flag", {}))
	_show_line(node)


func _show_line(node: Dictionary) -> void:
	line_shown.emit(
		str(node.get("speaker", "")),
		str(node.get("text", "")),
		node.get("choices", [])
	)


func _apply_flags(dict: Dictionary) -> void:
	for key in dict:
		GameState.set_flag(str(key), dict[key])


func _finish() -> void:
	reset()
	dialogue_finished.emit()


func reset() -> void:
	_graph_path = ""
	is_active = false
	_graph = {}
	_current_id = ""


func _load_graph(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DialogueManager: dialogue file not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DialogueManager: dialogue file is not a JSON object: %s" % path)
		return {}
	return parsed
