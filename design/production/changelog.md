# Production — Changelog

*Tidewrack — Fogline Games · source snapshot dated 2026-08-14 · production, changelog*

> Corrected repository copy based on the supplied source snapshot. Candidate findings refer to `8c9b1e40`. Later branch changes are identified separately. The distributed Steam build has not been matched to that commit.

## v0.2-demo-rc — 2026-08-14

The submission devlog names this tag. The accessible backup does not resolve it. The following findings describe its release-labelled commit `8c9b1e40`; equivalence to the Steam export remains unverified.

The ground floor exposes logbook, radio and stair dialogue, settings, a pause menu and manual scene/flag saves. Journal stores IDs in a scaffold with no autoload, normal caller, reader or persistence. The stair ends in text. The lamp-room scene is a placeholder with a draft dialogue node and no playable lens/wick puzzle. June scoped in the reader and puzzle, deferred gamepad support to release, and excluded other island areas. The later demo plan included controllers. Candidate input maps joypad events and displaces the corresponding keyboard bindings.

| Playtest fix claim | Evidence in the candidate |
|---|---|
| First input and choice timing | Accept reveals a typing linear line before advancing. Choices stay disabled until reveal completes. Post-close input and rapid clicks need engine tests. |
| Save corruption and management | Loader rejects malformed JSON. Direct overwrite, no confirmation and no recovery copy remain. Continue is visible but disabled without a file. Normal active-dialogue pause/quit repro is unavailable here. |
| Quiet branch | PR6's quiet choice explicitly writes `trusted_edith=false`. |
| 1080p overflow | A content-fitting label and margins exist. Long lines and choices still need a rendered 1080p test. |

## v0.1-vslice — 2026-05-15

Vertical slice. Branching dialogue (DialogueManager), save/load + flags (GameState), player movement,
interactables, the dialogue box, main menu, settings, the dressed ground floor, and the keeper intro
conversation. Small but whole and playable.

## Subsequent corrections on fix/demo-keyboard-and-journal-autoload

| Commit | Change and evidence |
|---|---|
| `f554a9e6` | Restored explicit keyboard events alongside the existing pad mappings and registered Journal. Configuration verified statically. |
| `d61dec83` | V2 saves include Journal discoveries and an active graph/node cursor. Continue resumes after the recreated scene is listening. V1 preserves only its recorded scene and flags. Static path inspection and Python payload fixtures passed. |
| `8bb007f1` | Added an engine-free report for node and choice flag assignments. Two dialogue files passed with zero warnings; six writes were found, all on choices. Four focused Python tests passed. |
| `1ab3413c` | Added six corrected design and production copies from supplied snapshots. |
| `b10a6e7b` | Save reads back its temporary file before checked slot replacement. Continue rejects invalid fields and checks the scene handoff before installing live state. Overwrite confirmation remains absent. Static checks covered code ordering. Target-filesystem interruption tests and an actual Godot run are pending. |

Godot startup, physical controls, UI layout and save/Continue behavior remain unverified. The later branch adds neither the journal reader nor the lamp puzzle. Additional island areas remain outside the lighthouse demo. October release-candidate records concern a later build and do not verify August behavior.
