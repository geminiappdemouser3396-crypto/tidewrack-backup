# Narrative — Flags & Branches

*Tidewrack — Fogline Games · source snapshot dated 2026-07-06 · narrative, flags*

> Corrected repository copy based on the supplied source snapshot. Candidate findings refer to `8c9b1e40`. Later branch changes are identified separately. The distributed Steam build has not been matched to that commit.

## Canonical flags

| Flag | Narrative intent | Candidate write |
|---|---|---|
| `skeptic` | Coincidence reading | First skeptical logbook choice sets true. |
| `believer` | Signal reading | First believing logbook choice sets true. |
| `trusted_edith` | Whether the player takes Edith's account at face value | Second logbook choice uses the decision to radio as a proxy: radio sets true, keep quiet explicitly sets false. |
| `radioed_tom` | Whether the player reached out for help | Both responses in the actual radio conversation set true. Choosing to radio in the logbook only changes `trusted_edith`. |

Interactables are repeatable. Reading the logbook again can leave both `skeptic` and `believer` true. The most recent trust choice overwrites the previous value. A missing key and a stored false can read alike through the default getter; inspect key presence to distinguish them.

## Endings

The four canonical endings are the corners of (reading × trust): the light explained away, the light
believed and Edith vindicated, the light believed but Edith doubted, and the ambiguous ending where the
keeper simply keeps the light. `radioed_tom` colours the epilogue rather than branching the ending.
This is the narrative design. The lighthouse graph does not select or deliver these endings. How a later ending selector should interpret two true reading flags remains a design decision.

## Bug history

PR6 recorded the missing quiet-branch write as fixed (FB-021, #32). The candidate JSON supports that narrow claim: choice index 1 at `logbook_choice2` assigns `trusted_edith=false`. The manager writes choice flags before entering the destination, then applies any node-entry flags. Neither checked-in graph currently authors node-level assignments.

The candidate validator had no flag report. On the later branch, `8bb007f1` lists all six choice writes, including both writes of `radioed_tom=true`. Python tests cover node writes and explicit false. A missing required write, a contradictory stance, and the value seen after Continue still need separate checks. Branch v2 persists the dictionary; verify replay and reload in Godot.
