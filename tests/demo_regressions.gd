extends Node
## Injected as a persistent autoload by the disposable-project launcher only.

const GAME := "res://scenes/game.tscn"
const TITLE := "res://scenes/main_menu.tscn"
const GRAPH := "res://data/dialogue/keeper_intro.json"
var failures := 0
var state_changes := 0


func _ready() -> void:
	if not Engine.is_editor_hint():
		call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func click(label: String) -> void:
	for control in get_tree().current_scene.find_children("*", "Button", true, false):
		var button := control as Button
		if button.text == label and button.is_visible_in_tree() and not button.disabled:
			button.pressed.emit()
			return
	check(false, "Missing enabled button: " + label)


func wait_scene(path: String) -> void:
	for frame in range(10):
		await get_tree().process_frame
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == path:
			return
	check(false, "Scene did not open: " + path)


func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	get_viewport().push_input(event)
	event.pressed = false
	get_viewport().push_input(event)


func bindings() -> void:
	var keys := {"ui_accept": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], "ui_cancel": [KEY_ESCAPE],
		"ui_left": [KEY_LEFT], "ui_right": [KEY_RIGHT], "ui_up": [KEY_UP], "ui_down": [KEY_DOWN]}
	for name in keys:
		for code in keys[name]:
			var key := InputEventKey.new()
			key.keycode = code
			check(InputMap.event_is_action(key, name, true), "%s keyboard %s" % [name, code])
	for name in ["ui_accept", "ui_cancel"]:
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_A if name == "ui_accept" else JOY_BUTTON_B
		check(InputMap.event_is_action(button, name, true), name + " joypad button")
	for name in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		var stick := InputEventJoypadMotion.new()
		stick.axis = JOY_AXIS_LEFT_X if name in ["ui_left", "ui_right"] else JOY_AXIS_LEFT_Y
		stick.axis_value = -1.0 if name in ["ui_left", "ui_up"] else 1.0
		check(InputMap.event_is_action(stick, name, true), name + " signed stick axis")


func write_fixture(contents: String) -> void:
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(contents)
	file.close()


func _run() -> void:
	var slot := OS.get_environment("TIDEWRACK_REGRESSION_SLOT")
	# Both independent paths must name the same fresh slot outside the project.
	var project_dir := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var parent := project_dir.get_base_dir()
	if not parent.get_file().begins_with("tidewrack-regression-") or slot != parent.path_join("save.json") or slot != GameState.SAVE_PATH or FileAccess.file_exists(slot):
		printerr("Unsafe test location; refusing to access any save.")
		get_tree().quit(2)
		return
	await wait_scene(TITLE)
	bindings()
	check(get_node("/root/Journal") == Journal and Journal.get_script().resource_path == "res://scripts/journal.gd", "registered Journal singleton")
	click("New Game")
	await wait_scene(GAME)
	var game = get_tree().current_scene
	# Move into range of the authored logbook, then use the gameplay input path.
	game._player.position = game._interactables[0].position
	await get_tree().process_frame
	await get_tree().process_frame
	action("ui_accept")
	check(Journal.entries() == ["logbook"], "logbook interaction discovers its ID")
	DialogueManager.advance()
	DialogueManager.advance()
	var cursor := {"graph": GRAPH, "node": "logbook_choice1"}
	check(DialogueManager.checkpoint() == cursor, "reached authored pending choice")
	GameState.set_flag("trusted_edith", false)
	action("ui_cancel")
	click("Save")
	var saved_text := FileAccess.get_file_as_string(slot)
	var saved = JSON.parse_string(saved_text)
	check(typeof(saved) == TYPE_DICTIONARY, "pause Save wrote JSON")
	if typeof(saved) != TYPE_DICTIONARY:
		get_tree().quit(1)
		return
	check(saved.get("dialogue") == cursor and saved.get("journal_entries") == ["logbook"], "saved cursor and discoveries")
	click("Main Menu")
	await wait_scene(TITLE)
	click("New Game")
	await wait_scene(GAME)
	check(GameState.flags.is_empty() and Journal.entries().is_empty() and not DialogueManager.is_active and DialogueManager._current_id.is_empty(), "New Game clears live state and staged cursor")
	check(FileAccess.get_file_as_string(slot) == saved_text, "New Game preserves disk slot")
	action("ui_cancel")
	click("Main Menu")
	await wait_scene(TITLE)
	click("Continue")
	await wait_scene(GAME)
	game = get_tree().current_scene
	check(DialogueManager.checkpoint() == cursor and Journal.entries() == ["logbook"], "Continue restored cursor and discoveries")
	check(GameState.flags == {"trusted_edith": false}, "explicit false flag restored")
	check(game._dialogue_box._root.is_visible_in_tree() and not game._player.can_move, "dialogue visible and movement locked")
	var choices = game._dialogue_box._choice_box
	check(choices.get_child_count() == 2, "Continue recreated both choice controls")
	for frame in range(240):
		if choices.get_child_count() == 2 and not choices.get_child(0).disabled:
			break
		await get_tree().process_frame
	check(choices.get_child_count() == 2 and choices.get_child(0).text == "She was tired and seeing things." and choices.get_child(0).has_focus(), "restored choice text, reveal and focus")

	action("ui_cancel")
	click("Main Menu")
	await wait_scene(TITLE)
	GameState.set_flag("sentinel", true)
	Journal.discover("sentinel")
	GameState.state_changed.connect(func(): state_changes += 1)
	var menu := get_tree().current_scene
	var bad_node: Dictionary = saved.duplicate(true)
	bad_node["dialogue"]["node"] = "missing_node"
	var bad_fields: Dictionary = saved.duplicate(true)
	bad_fields.erase("flags")
	for invalid in ["{", JSON.stringify(bad_node), JSON.stringify(bad_fields)]:
		write_fixture(invalid)
		menu._continue_button.pressed.emit()
		await get_tree().process_frame
		check(get_tree().current_scene == menu and menu._continue_button.text == "Load failed — retry", "Continue rejected damaged slot")
		check(GameState.flags == {"trusted_edith": false, "sentinel": true} and Journal.entries() == ["logbook", "sentinel"], "rejection preserves live flags and discoveries")
		check(DialogueManager.checkpoint() == cursor and state_changes == 0, "rejection preserves active cursor without state change")
		check(FileAccess.get_file_as_string(slot) == invalid, "rejection does not rewrite slot")
	# The direct API can leave a cursor staged but unpublished; a failed load
	# must preserve that state too. This is distinct from the title UI path.
	write_fixture(saved_text)
	check(GameState.load_game() and not DialogueManager.is_active, "direct load stages without publishing")
	var signals_before := state_changes
	write_fixture(JSON.stringify(bad_node))
	check(not GameState.load_game(), "direct load rejects missing node")
	check(not DialogueManager.is_active and DialogueManager._current_id == cursor.node and DialogueManager._graph_path == GRAPH, "staged graph/node retained")
	check(state_changes == signals_before and Journal.entries() == ["logbook"] and GameState.flags == {"trusted_edith": false}, "failed direct load leaves staged session intact")
	write_fixture(JSON.stringify({"version": 1, "scene": GAME, "flags": {"lamp_relit": true}}))
	menu._continue_button.pressed.emit()
	await wait_scene(GAME)
	check(GameState.flags == {"lamp_relit": true} and Journal.entries().is_empty(), "legacy flags restored and stale entries cleared")
	check(not DialogueManager.is_active and DialogueManager._current_id.is_empty() and not get_tree().current_scene._dialogue_box._root.visible, "legacy save clears cursor and leaves dialogue closed")
	for linear in [true, false]:
		for lamp_lit in [true, false]:
			await check_v2_round_trip(linear, lamp_lit)
	if failures == 0:
		print("TIDEWRACK_GODOT_REGRESSIONS_OK")
	get_tree().quit(0 if failures == 0 else 1)


## Starts and ends on the ground floor. Every combination uses the real slot UI.
func check_v2_round_trip(linear: bool, lamp_lit: bool) -> void:
	var label := "linear=%s lamp_relit=%s: " % [linear, lamp_lit]
	action("ui_cancel")
	click("Main Menu")
	await wait_scene(TITLE)
	click("New Game")
	await wait_scene(GAME)
	var game = get_tree().current_scene
	var expected_flags := {"lamp_relit": lamp_lit, "trusted_edith": false}
	# The demo has a reader for lamp_relit but no playable puzzle setter.
	GameState.set_flag("lamp_relit", lamp_lit)
	GameState.set_flag("trusted_edith", false)
	var cursor := {}
	var line_text := ""
	if linear:
		game._player.position = game._interactables[0].position
		await get_tree().process_frame
		await get_tree().process_frame
		action("ui_accept")
		DialogueManager.advance()
		cursor = {"graph": GRAPH, "node": "logbook_2"}
		line_text = game._dialogue_box._full_text
		check(not line_text.is_empty() and game._dialogue_box._typing, label + "saving a typing linear line")
	else:
		# Seed a previously discovered entry without starting a conversation.
		Journal.discover("logbook")
	check(DialogueManager.checkpoint() == cursor, label + "expected cursor before Save")
	action("ui_cancel")
	click("Save")
	var payload = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
	if typeof(payload) != TYPE_DICTIONARY:
		check(false, label + "Save did not produce a dictionary")
		return
	check(payload.get("version") == 2 and payload.get("scene") == GAME, label + "v2 gameplay slot")
	check(payload.get("dialogue") == cursor and payload.get("journal_entries") == ["logbook"], label + "on-disk cursor and discoveries")
	check(payload.get("flags") == expected_flags, label + "on-disk flags including explicit boolean")
	click("Main Menu")
	await wait_scene(TITLE)

	# Make every singleton disagree with the slot so retained memory cannot pass.
	GameState.set_flag("lamp_relit", not lamp_lit)
	GameState.set_flag("stale", true)
	Journal.replace_entries(["stale"])
	check(DialogueManager.start(GRAPH, "door"), label + "seed stale dialogue")
	click("Continue")
	await wait_scene(GAME)
	game = get_tree().current_scene
	check(GameState.flags == expected_flags and typeof(GameState.flags.get("lamp_relit")) == TYPE_BOOL, label + "exact restored flags")
	check(Journal.entries() == ["logbook"], label + "restored discoveries replace stale entries")
	check(DialogueManager.is_active == linear and DialogueManager.checkpoint() == cursor, label + "restored cursor")
	check(game._dialogue_box._root.is_visible_in_tree() == linear, label + "dialogue visibility")
	check(game._player.can_move == (not linear), label + "movement state")
	check(game._dialogue_box._choice_box.get_child_count() == 0, label + "no choice buttons")
	if linear:
		check(game._dialogue_box._full_text == line_text and game._dialogue_box._continue_hint.is_visible_in_tree(), label + "restored linear text and advance hint")
	else:
		check(DialogueManager._current_id.is_empty(), label + "no staged or active node")
