# GDD — Dialogue System

*Tidewrack — Fogline Games · source snapshot dated 2026-03-06 · gdd, dialogue, code*

> Corrected repository copy based on the supplied source snapshot. Candidate findings refer to `8c9b1e40`. Later branch changes are identified separately. The distributed Steam build has not been matched to that commit.

## DialogueManager

`scripts/autoload/dialogue_manager.gd` loads a JSON branching graph and walks it node by node. Writers edit JSON. Each keyed node supplies its speaker and text to the dialogue box. A linear node has a `next` target (or null to finish). A choice node supplies options with text and a target. A choice can set flags before advancing; entering a node can also set flags. The manager emits signals that drive the dialogue UI and movement lock.

## The vertical-slice conversation

`data/dialogue/keeper_intro.json` exercises dialogue, flags and interactables together. The logbook, radio and stair start distinct nodes. The stair ends in dialogue. The separate one-node lamp draft has no normal gameplay entry. The journal reader and lamp puzzle were planned demo content and are unfinished in the inspected source.

## Validation

Run `python3 tests/validate_dialogue.py` before committing a graph as part of the solo development workflow. In the candidate, the engine-free checker examined graph structure and did not report flags. It checks node and choice shapes, referenced string targets and the presence of a terminal somewhere in each file. It warns about nodes outside the union of known entry points. Warnings alone return 0. A structural error returns 1.

A pass does not prove every entry or route reaches an ending. A missing choice `next` counts as a terminal; a non-string, non-null linear `next` escapes target checking. The unused journal helper adds no validation.

Branch commit `8bb007f1` adds a descriptive row per node or choice assignment, preserving repeated names and false values. Python checked 14 keeper nodes and one lamp node with zero warnings. Four tests passed, including a fixture with node writes. The checked-in graphs contain six choice writes and zero node writes. The report does not enforce canonical names, required assignments or mutual exclusion, and does not exercise gameplay or save restoration.

Original companion reference: `../narrative/dialogue-graph-spec.md`. Its source snapshot is unavailable.
