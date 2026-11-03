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
- **New Game and older saves.** New Game clears the cursor, flags and Journal discoveries, resets the scene and keeps the disk slot. Version 1 restores its scene and recorded flags. It starts without an active conversation and with an empty Journal; missing history cannot be inferred. Loading replaces prior in-memory state. Unsupported versions are rejected. The direct-write and confirmation limitations remain.
- **Verification.** Static inspection traced the pause Save caller and post-connection resume. Six Python v2 JSON fixtures and one v1 fixture exercised example payloads outside Godot. In-engine checks remain pending: save a partial line and a choice, Continue, inspect focus and flags, test Journal replacement, then start fresh and load a v1 slot. Test interrupted writes separately.

## Rule

Keep flags **append-mostly** so debugging preserves the player's choices where possible. The manager still allows overwrites: the quiet branch records false, and repeated interactions can set both reading flags. The rule is an authoring convention.
