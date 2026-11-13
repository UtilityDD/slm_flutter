# PARALLEL_BUILD_PLAN.md — handoff for every agent (director and workers)

> Read this first, then [AGENTS.md](AGENTS.md), [GAME_LEVEL_PLAYBOOK.md](GAME_LEVEL_PLAYBOOK.md),
> [GAME_DEVELOPER_GUIDE.md](GAME_DEVELOPER_GUIDE.md) and [GAME_PATH_CHECKLIST.md](GAME_PATH_CHECKLIST.md).
> This file is the single plan for the heavily parallel build. The **director** (the main session) keeps the
> status table current; **workers** never edit this file.

## 1. Goal and state (2026-11-11)

- Modules 1–4 (120 rungs) are built. A full audit (2026-11-11) found: master red (94 tests), steps 28–29 broken,
  step 30 still the rejected medley gate, kit timing gaps (praise window, freeze input), the coworker skippable and
  speaking in the wrong voice in Modules 2–4, answers given away, look-alike levels, medley gates. See §6.
- Owner asked for: fix those, **gesture hints** on every level (how to tap/drag/hold — never the answer), and build
  the remaining modules with heavy parallelism.
- Working branch: **`fix/audit-2026-11-11`** (off `master` 82fde45). Commit/push only when the owner says so.

## 2. Phases and status

| # | Phase | Agents | Depends on | Status |
|---|---|---|---|---|
| P1 | Shared kit fixes + gesture-hint kit · Modules 3–4 tests green · steps 28–29 repairs | 3 builders + reviews + fixes | — | running (`wf_0d50163c-995`) |
| D5 | Module 5 design (10 lesson designers → gate → judge) | 12 | — | ✅ done — final spec `docs/module_specs/module5_spec.json` |
| D6–D10 | Modules 6–10 design (same shape, one workflow per module: `tool`-free, script `workflows/scripts/module-design.js` with args) | ~70 | — | ✅ done — final specs `docs/module_specs/module6_spec.json` … `module10_spec.json`; owner questions `docs/decisions/` |
| P2 ✅ | Modules 1–4 per-level fixes from the audit + adopt gesture hints in every level (one agent per level → review → refix; script `level-fix.js` with args) | ~77 fixers + reviewers + refixers | P1 kit API (`scratchpad/kit_api.md`), findings `scratchpad/audit_findings.md` | running: M1 `wf_cece38d4-34a`, M2 `wf_8c792891-361`, M3 `wf_abe2c3b2-9e8`, M4 `wf_fb6f9c8e-952` |
| B5 ✅ | Module 5 build: 30 rungs built → reviewed → fixed (rulings `docs/module_specs/module5_rulings.md`, items `docs/module_specs/module5_items/`, ladder `MODULE5_LADDER.md`); wired, 51 coworker clips recorded | ~90 | P1, D5, owner ok (2026-11-12) | done 2026-11-12 (`wf_2602a25a-8d9`, `wf_d66a91c6-b4e`); owner review of open items pending |
| G30 ✅ | Step 30 hazard-spotting rank gate (approved concept) | 3 | P1 | running (`wf_4e7066ec-c0a`) |
| V | Record the coworker/rival lines that have no clip (Modules 2–5) with `tool/rival_clip.py`; list them in the dump test | director | P2, B5 | waiting |
| B6–B10 | Modules 6–10 builds (as B5) | ~90 each | D6–D10, owner ok | later |

**Owner's order (2026-11-11):** fix the old modules (1–4) first; then design and COMPLETE two modules at a time —
**5 + 6**, then **7 + 8**, then **9 + 10** (each pair built, reviewed, wired, verified and on the phone before the next).
The designs for 6–10 already exist (judged specs in the design workflows); each pair's builders use them.

## 3. How the parallel build works

1. **One rung = one worker.** A worker owns only its level's files: `lib/features/game/m<N>_<name>.dart` (+ its
   `_world.dart` painter), `test/m<N>_<name>_test.dart`, `test/perf/m<N>_<name>_perf_test.dart`, its art folder
   `assets/game/art/m<N>_<name>/`, and for a board `learn_board_pack<N><L>.dart` + `tool/<topic>_board_art.py`.
2. **Shared files are director-only** (wired after the wave): `do_games.dart`, `content_catalog.json`,
   `learn_board_models.dart`, `mistakes_book.dart`, `tool/dump_learn_voice_lines_test.dart`, `pubspec.yaml`,
   `learn_voice_map.dart` (except through `tool/rival_clip.py`), the docs, and the kit files. Workers put the exact
   edits they need under `wiring_needed`.
3. **Flutter runs go through slots:** `powershell -NoProfile -ExecutionPolicy Bypass -File tool/flk.ps1 test test/x_test.dart`
   (or `analyze <files>`). `FLK_SLOTS` (default 6) caps concurrent flutter processes so 16 GB RAM is enough. Never
   call `flutter.bat` directly during a wave; never run the whole suite (the director does).
4. **Waves:** design (no flutter) → build → independent review → fix → director wiring → full checks.
   Each workflow runs at most 16 agents at once; several workflows run side by side.
5. **Progress updates:** every worker sends the director a one-line update at each milestone (read the lesson,
   rules done, scene drawn, tests green, report sent) and at least every ~10 minutes, with `SendMessage` to `main`
   when that tool is available: `"<rung> · <stage> · <what is done> · <blocker or none>"`.
6. **Report schema** (final answer): summary, files changed/created/deleted, wiring_needed, open_questions
   (owner decisions, facts the lesson does not support), tests run, tests passed.

## 4. Worker contract (every level)

- The playbook's 9 beats on the shared kit; **gesture hints** declared for every waiting state (how, never what).
- Content only from the lesson (`tool/all_training_chapters_bn.json`); unsupported facts → open_questions.
- Deadly vs slip from the module's design table (one table per module); never change point values or pass marks.
- The coworker: two-beat pressure moment, recorded voice, and the next decisive control waits for him (he can't be
  skipped by playing fast); his line fits the moment.
- No answer giveaways: no ordered tool rows, no rings/ticks on targets, no free "flag everything" with a revealing
  reply, no captions naming the hazard; a wrong flag or needless stop costs something.
- English digits on screen; locked words ডকেট · শাটডাউন · জল · গ্লাভস; keyed come-and-go layers; idle = zero frames.
- Tests: rules, deal variety, option libraries, rival lines resolve, idle perf, full flow (incl. a reason pick and
  the coworker), 3-slip strike-out, deadly freeze. Scratch screenshot tests `test/zz_*` deleted after use.

## 5. Director checklist after each wave

Wire shared files (§3.2) → `flutter analyze` → full `flutter test` → `python -I tool/check_asset_refs.py .` →
screenshots spot-check → phone build (`flutter build apk --profile --target-platform android-arm64`, `adb install -r`)
→ update GAME_PATH_CHECKLIST.md, MODULE<N>_LADDER.md, this table → owner report (decisions) → commit/push on ask.

## 6. Audit lessons (do not repeat)

1. Building 90 rungs in ~1.5 h (Modules 2–4, one worktree per level, a director merging) was fast but merged red
   (tests not updated for a kit change made the same hour), and produced look-alike levels (6–7 per module playing
   "docket → rack → slide → take/reject → reason"), medley gates, a skippable coworker, answers given away, and
   deadly/slip drift. Speed is fine — **but every rung gets an independent review, and the director runs the full
   suite before merging anything.**
2. A kit change lands first; level waves start after it and adopt it.
3. Design before build: a module judge makes every level's core verb distinct and writes one deadly/slip table.

4. **Don't steer workflow agents with SendMessage mid-run.** A message to a running workflow agent starts a separate
   copy of it outside the workflow (no structured-output tool), while the original keeps running and submits its own
   result — the steer never reaches the workflow and the copy wastes tokens. Put every rule in the prompt before
   launch; fix repeats in a later pass (e.g. the cross-module verb-dedupe pass).

## 7. Resume

**If the session ends mid-wave:** workflows stop but their `flutter test` children and `tool/flk.ps1` wrappers keep
running and hold slots and RAM. Before resuming, stop processes whose command line matches `flk.ps1` or `flutter_tools`
(never the IDE's `language-server`/`analysis_server`), then relaunch each run with `Workflow({scriptPath, resumeFromRunId, args})`
using the same args — finished agents replay from cache.

Workflow runs live in this session's folder (`.claude/projects/.../workflows/scripts/`). A new session: read this
file and the memory note `step30-gate-in-progress`, check `git status`, and resume the earliest unfinished phase.
