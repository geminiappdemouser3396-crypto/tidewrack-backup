# GDD — GameState & Saves

*Tidewrack — Fogline Games · source snapshot dated 2026-03-13 · gdd, saves, code*

> Corrected repository copy based on the supplied source snapshot. Candidate findings refer to `8c9b1e40`. Later branch changes are identified separately. The distributed Steam build has not been matched to that commit.

## GameState

`scripts/autoload/game_state.gd` owns story flags and the single save slot. The candidate registers GameState and DialogueManager. Journal was an unregistered storage scaffold until `f554a9e6`. The flags dictionary accepts values; the authored choices write booleans to `skeptic`, `believer`, `trusted_edith` and `radioed_tom`. Conditional later branches are a design goal. The current keeper graph follows authored next/choice targets.

## Candidate persistence at 8c9b1e40

Pause-menu Save copies the scene path into GameState, then writes `version: 1`, `scene` and `flags` to `user://save.json`. Active dialogue blocks pause. Continue is visible and disabled if the file is absent. On a successful load, the menu changes to the restored scene and gameplay builds the player at the fixed spawn. No dialogue cursor, Journal IDs, player coordinates or settings are recorded.

Loading rejects unreadable or malformed/non-object JSON. The candidate defaults a missing scene to the ground floor and non-dictionary flags to an empty dictionary. It writes directly over the single slot with no overwrite prompt or recovery copy. A delete helper exists without a normal menu caller or confirmation.

## Later branch contract at d61dec83

- **Save.** Pause can suspend dialogue. Version 2 writes the scene and flags plus `journal_entries` and `dialogue`. The latter is empty when idle, or contains graph path and node ID. Opening the existing logbook records its discovery. The puzzle scaffold reads `lamp_relit` from the same flags dictionary; any recorded value persists, including false. No implemented lens/wick state or playable lamp sequence supplies further puzzle progress.
- **Continue.** Load validates the scene and new fields, stages a valid dialogue cursor and replaces flags and Journal entries. The recreated ground-floor scene connects its UI and movement handlers before emitting the saved line or choice. Reveal restarts at the beginning of the node. It does not reapply node-entry effects or select a pending choice. Character offset, UI focus and player position remain outside the format.
- **New Game and older saves.** New Game clears the cursor, flags and Journal discoveries, resets the scene and keeps the disk slot. Version 1 restores its scene and recorded flags. It starts without an active conversation and with an empty Journal; missing history cannot be inferred. Loading replaces prior in-memory state. Unsupported versions are rejected. At this revision Save still overwrote the slot directly without confirmation.
- **Verification.** Static inspection traced the pause Save caller and post-connection resume. Six Python v2 JSON fixtures and one v1 fixture exercised example payloads outside Godot. In-engine checks remain pending: save a partial line and a choice, Continue, inspect focus and flags, test Journal replacement, then start fresh and load a v1 slot. Test interrupted writes separately.

## Failure handling at b10a6e7b

Save closes a process-specific sibling temporary file and reads it back. It compares the text with the intended JSON before requesting replacement of the slot and checks the rename result. Open, readback or rename failure returns false. This adds neither a backup copy nor an overwrite-confirmation prompt. Interrupted replacement and power-loss durability need testing on each target filesystem.

Player-facing Continue validates the save before installing session state. It accepts the loadable, instantiable ground-floor scene used by the demo writer. V2 requires the scene, a flags dictionary, a string array of Journal IDs and a dialogue dictionary. A nonempty cursor must resolve to a permitted dialogue graph and node. Missing/unreadable files, malformed roots, unsupported versions and invalid fields take failure paths before the live flags, Journal or dialogue are replaced. The menu requests the scene transition; only after SceneTree accepts it does the loader stage the cursor and install the session. The recreated scene resumes it after its listeners connect. A failed Continue displays a retry caption. The direct load_game() API omits the scene request and only stages a successful load.

Legacy v1 (or versionless legacy-shaped data) can omit scene or flags when the other is present. An empty object, wrongly typed flags, or legacy data containing v2-only fields is rejected. Prior v1 saves cannot reconstruct discoveries or a cursor. Successful idle loads clear a prior cursor. Validation does not enforce individual flag names or value types.

Source-order checks covered rejection before mutation, scene handoff and verified temporary-file replacement. The Python dialogue tests do not exercise this loader. Godot tests of successful Continue, preservation of an existing session after failure, and filesystem failure injection remain pending. Errors after the engine accepts the scene transition are outside the rejection guarantee.

## Rule

Keep flags **append-mostly** so debugging preserves the player's choices where possible. The manager still allows overwrites: the quiet branch records false, and repeated interactions can set both reading flags. The rule is an authoring convention.
