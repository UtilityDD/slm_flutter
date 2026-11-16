---
name: module6-wave-b-handoff
description: Module 6 Wave B (6.6–6.11 + gate) build is pending/in progress — how to run it and what comes after (as of 2026-11-16)
metadata:
  node_type: memory
  type: project
  originSessionId: 99a527a5-89b0-485c-8931-22bf2def4dc4
  modified: 2026-11-16T00:30:55.893Z
---

State 2026-11-16 06:00: Wave A (6.1–6.5, 15 rungs) is built, owner-worded, voiced and pushed (commit a9153e41 on fix/audit-2026-11-11). Uncommitted in the tree: tap-to-repeat voice fix (learn_voice.dart, mascot_speech_library.dart, do_parts.dart, 3 clips, test/task_nudge_voice_test.dart), owner answers added to docs/module_specs/module6_rulings.md, a few partial Wave B files (learn_board_pack67/69/611.dart, tool/m6_board66/68_art.py), and tool/flk.ps1 default slots lowered 3 → 2 (restore to 3 before committing).

The old session (99a527a5…, 203 MB transcript) crashed within ~1 min every time a workflow started — run Wave B from a FRESH session.

**Run:** `Workflow({name: 'module6-wave-b'})` — the script is `.claude/workflows/module6-wave-b.js` (18 rungs built in, sliding window of 3 rungs, build → independent review → fix; tells builders partial files may exist). Before launching: stop orphan java/dart processes and clear `.flk/slot*` if no flutter run is live.

**After it finishes (director):** apply every wiring_needed (do_games cases, catalog packs + rungs playable with deadlyRules = exact deadly keys, learn_board_models, mistakes_book, voice dump test), extend test/m6_wiring_test.dart to all 33 rungs (gate included), update ladder counts (165 → 183) in ladder_focus/adventure_map/ladder_perf tests, analyze, full suite in batches, check_asset_refs; then a wording sheet docs/review/m6_waveB_wording_*.xlsx for the owner (pattern of the Wave A sheet), apply wording + [[bangla-term-rules]], record clips (Subrata bn-IN-BashkarNeural +14%, coworker bn-BD-PradeepNeural), phone build, commit/push only when asked.

**Why:** owner asked for Wave B with many agents; keep the owner's rules in [[voice-and-new-text-rules]].
