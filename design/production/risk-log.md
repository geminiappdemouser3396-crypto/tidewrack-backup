# Production — Risk Log

*Tidewrack — Fogline Games · source snapshot dated 2026-06-26 · production, risk*

> Corrected repository copy based on the supplied source snapshot. Candidate findings refer to `8c9b1e40`. Later branch changes are identified separately. The distributed Steam build has not been matched to that commit.

## Top risks (solo dev)

1. **Scope creep in the narrative.** Mitigation: the slice-first plan; anything not in the four canonical
   endings is a cut.
2. **Burnout — one person, nine months.** Mitigation: weekly cadence, public dev-logs for accountability,
   a fixed runway ($14.99 launch against a $92,000 runway).
3. **Demo lands flat at Next Fest.** Mitigation: the slice is playtested (PR1–PR9) before the demo build.
   The log covers 13 May–24 July on `v0.1-vslice` and `demo-wip`. Its 39 rows represent 21 distinct summaries.
   Festival correspondence is separate. Identify the distributed build before closing a Fest report against a backup-source fix.
4. **Contractor slip (music/art/VO).** Mitigation: milestone deposits, work-for-hire agreements, buffer
   before the press build.
5. **Save/flag corruption eating a player's progress.** Keep this risk open. PR1 correspondence describes dialogue input. PR2 reports describe truncated JSON on quit and a stairwell manual-save failure; the June scope report also attributes a post-puzzle flag fix to PR2. The descriptions do not establish a common cause or an August retest.
   The candidate loader rejects malformed JSON, but Save overwrites the only file directly. The branch's v2 format (`d61dec83`) restores more state and still uses that write path. The later flag report (`8bb007f1`) lists authored assignments; it cannot detect lost saves. Mitigate with interrupted-write, old-save and in-engine Save → Continue tests on a disposable slot, including an explicit false flag and a pending choice.
