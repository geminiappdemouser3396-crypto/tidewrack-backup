extends Node
## Journal — discovered-logs system (Public Demo scaffold).
##
## Stores discovered log IDs for the current game.

signal entry_added(id: String)

var _entries: Array[String] = []


func discover(id: String) -> void:
	if id in _entries:
		return
	_entries.append(id)
	entry_added.emit(id)


func entries() -> Array[String]:
	return _entries.duplicate()


func has(id: String) -> bool:
	return id in _entries


func replace_entries(ids: Array) -> void:
	_entries.clear()
	for id in ids:
		if id not in _entries:
			_entries.append(id)
