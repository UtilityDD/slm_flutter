export const meta = {
  name: 'module7-wave-b-boards',
  whenToUse: 'Build Module 7 Wave B (lessons 7.6-7.10 + gate). Run with no args; resume with resumeFromRunId.',
  description: 'Rebuild Module 7 Wave B boards 7.6-7.10 with sonnet (haiku attempt wrote nothing): one builder per rung, independent review, fix',
  phases: [
    { title: 'Build', detail: 'one builder per rung' },
    { title: 'Review', detail: 'independent reviewer per rung' },
    { title: 'Fix', detail: 'fix must/should findings' },
  ],
}

const ITEMS = (Array.isArray(args) && args.length) ? args : [{"id": "learn_7_6", "kind": "board", "spec": "board_76.json", "file": "lib/features/game/learn_board_pack76.dart", "engineType": "learn_cards", "art": "assets/game/art/m7_board76/", "lessonId": "7.6"}, {"id": "do_7_6_a", "kind": "do", "spec": "do_7_6_a.json", "file": "lib/features/game/m7_ppe_counter_claim.dart", "engineType": "m7_ppe_counter_claim", "art": "assets/game/art/m7_ppe_counter_claim/", "lessonId": "7.6"}, {"id": "do_7_6_b", "kind": "do", "spec": "do_7_6_b.json", "file": "lib/features/game/m7_ppe_mishap_route.dart", "engineType": "m7_ppe_mishap_route", "art": "assets/game/art/m7_ppe_mishap_route/", "lessonId": "7.6"}, {"id": "learn_7_7", "kind": "board", "spec": "board_77.json", "file": "lib/features/game/learn_board_pack77.dart", "engineType": "learn_cards", "art": "assets/game/art/m7_board77/", "lessonId": "7.7"}, {"id": "do_7_7_a", "kind": "do", "spec": "do_7_7_a.json", "file": "lib/features/game/m7_scene_guard.dart", "engineType": "m7_scene_guard", "art": "assets/game/art/m7_scene_guard/", "lessonId": "7.7"}, {"id": "do_7_7_b", "kind": "do", "spec": "do_7_7_b.json", "file": "lib/features/game/m7_report_note.dart", "engineType": "m7_report_note", "art": "assets/game/art/m7_report_note/", "lessonId": "7.7"}, {"id": "learn_7_8", "kind": "board", "spec": "board_78.json", "file": "lib/features/game/learn_board_pack78.dart", "engineType": "learn_cards", "art": "assets/game/art/m7_board78/", "lessonId": "7.8"}, {"id": "do_7_8_a", "kind": "do", "spec": "do_7_8_a.json", "file": "lib/features/game/m7_spill_boom.dart", "engineType": "m7_spill_boom", "art": "assets/game/art/m7_spill_boom/", "lessonId": "7.8"}, {"id": "do_7_8_b", "kind": "do", "spec": "do_7_8_b.json", "file": "lib/features/game/m7_waste_handover.dart", "engineType": "m7_waste_handover", "art": "assets/game/art/m7_waste_handover/", "lessonId": "7.8"}, {"id": "learn_7_9", "kind": "board", "spec": "board_79.json", "file": "lib/features/game/learn_board_pack79.dart", "engineType": "learn_cards", "art": "assets/game/art/m7_board79/", "lessonId": "7.9"}, {"id": "do_7_9_a", "kind": "do", "spec": "do_7_9_a.json", "file": "lib/features/game/m7_doorstep_visit.dart", "engineType": "m7_doorstep_visit", "art": "assets/game/art/m7_doorstep_visit/", "lessonId": "7.9"}, {"id": "do_7_9_b", "kind": "do", "spec": "do_7_9_b.json", "file": "lib/features/game/m7_honest_reply.dart", "engineType": "m7_honest_reply", "art": "assets/game/art/m7_honest_reply/", "lessonId": "7.9"}, {"id": "learn_7_10", "kind": "board", "spec": "board_710.json", "file": "lib/features/game/learn_board_pack710.dart", "engineType": "learn_cards", "art": "assets/game/art/m7_board710/", "lessonId": "7.10"}, {"id": "do_7_10_a", "kind": "do", "spec": "do_7_10_a.json", "file": "lib/features/game/m7_crew_papers.dart", "engineType": "m7_crew_papers", "art": "assets/game/art/m7_crew_papers/", "lessonId": "7.10"}, {"id": "gate_m7", "kind": "gate", "spec": "gate_m7.json", "file": "lib/features/game/m7_gate_permit_day.dart", "engineType": "m7_gate_permit_day", "art": "assets/game/art/m7_gate_permit_day/", "lessonId": "7.10"}]

const SPEC_DIR = 'docs/module_specs/module7_items/'
const COMMON = `Repo D:\\Dipankar\\MyCodes\\AndroidProjects\\SLMToolBox\\slm_flutter (Flutter, Bangla lineman-safety game). Branch fix/audit-2026-11-11 — do NOT commit, push, stash or switch branches; other agents are editing other files in the same working tree right now.
Read first: AGENTS.md, PARALLEL_BUILD_PLAN.md (§3, §4 Worker contract, §6 Audit lessons), GAME_LEVEL_PLAYBOOK.md, GAME_DEVELOPER_GUIDE.md.
Module 7 rulings: docs/module_specs/module7_rulings.md — where it differs from the item spec, THE RULINGS FILE WINS (owner answers M7-1..M7-13 of 2026-11-16, cross-module rulings X1–X7, open items O1–O3). Module 7 is the law/rules module (Electricity rules, compensation, clearances, permit-to-work, theft): the lesson text is today's live text and it already changed many numbers vs the spec — each item spec lists them under notes.mismatches; THE LIVE LESSON TEXT WINS. No DO anywhere: the DTR isolation is the AB switch + HG fuses (M7-9 / M6-2).
Module 6 is built (lessons 6.1–6.11 + gate) and is your closest template: Do levels lib/features/game/m6_fuse_chain.dart, m6_ab_unjam.dart, m6_breaker_rack.dart, m6_meter_pulse.dart, m6_earth_pit_test.dart (+ _world.dart, tests in test/m6_*_test.dart, test/perf/m6_*_perf_test.dart); boards lib/features/game/learn_board_pack63.dart / 64 / 610 with test/learn_board_63_test.dart and tool/m6_board63_art.py. Name your classes with an M7 prefix; never edit Module 6 files.
Lesson text (the only content source; today's corrected live text): tool/all_training_chapters_bn.json (find the lesson id). Read-only. Never use any Bangladesh source.
Flutter: ALWAYS through the slot wrapper (6 slots shared with another running build, you may wait), never flutter.bat directly, never the whole suite:
  powershell -NoProfile -ExecutionPolicy Bypass -File tool/flk.ps1 test test/<your>_test.dart
  powershell -NoProfile -ExecutionPolicy Bypass -File tool/flk.ps1 analyze <your files>
Shared files are director-only — do NOT edit: lib/features/game/do_games.dart, assets/game/catalog/content_catalog.json, lib/features/game/learn_board_models.dart, mistakes_book.dart, tool/dump_learn_voice_lines_test.dart, tool/learn_voice_lines.json, pubspec.yaml (your art folder is already declared and created; delete only YOUR folder's .gitkeep once you add art — never touch other folders), learn_voice_map.dart, tool/voice_inventory.json, tool/voice_pending.json, kit files (full_scene_frame.dart, reason_table.dart, coworker_moment.dart, gesture_hint.dart, choice_deck.dart, level_juice.dart, do_parts.dart, mascot_speech_library.dart, freeze frame, learn_board_runner.dart, learn_board_deal.dart), docs, other rungs' files. Put the exact edits you need into wiring_needed (file + exact code/JSON to add). Do not run tool/dump_learn_voice_lines_test.dart (it rewrites a tracked file).
KIT BEHAVIOUR (adopt it): ReasonTable.askReason opens the "কেন?" cards at once (praise + question voice play over the open deck) — see reason_table.dart doc comments; the coworker never comes while tableBusy; every Do level records stars with save.recordStars(rungId, starsFor(...)) (or starsForMark(...) for percent-scored levels, level_juice.dart) right after save.recordBestTime.
Bangla: UTF-8 only (never PowerShell Set-Content). English digits on screen. Locked words ডকেট · শাটডাউন · জল · গ্লাভস. Owner term rules: «ডেড» (not মৃত), LT/HT/11 kV in English letters, ON/OFF (not অন/অফ), AB/isolator closing = «লাগানো» (never «AB বন্ধ»), য়/ড়/ঢ় as base+nukta. All new Bangla text is a DRAFT for the owner's wording: short, natural, simple West Bengal Bangla. Every spoken line (guide, coworker, crew, spoken why-questions, mistake texts) must be in the level's newGuideLines / newRivalLines lists; also list every NEW spoken line under rival_lines_missing as "speaker | exact text" (do not record audio). Option groups (cards/chips) stay within 1.3x length (test/support/option_lengths.dart). Scratch screenshot tests test/zz_* must be deleted before you finish.`

const KIND = {
  do: `Kind: a Do level on the shared kit, structured like the Module 6 Do levels (and m5_cause_strike.dart / gate_watch.dart for kit usage: FullSceneFrame(hint:, hintWaiting:, hintKey:), coworkerDue/holdForCoworker, ReasonTable putOnTable/askReason). Your files: the lib file from the work item (+ <name>_world.dart), test/<name>_test.dart, test/perf/<name>_perf_test.dart, art in the item's art folder (SVG, or drawn in code). Wiring the director will need: a do_games.dart case for the engineType, the catalog gamePack (engineType, status playable, assetRefs {}, deadlyRules = exactly the level's deadly mistake keys), mistakes_book entries (spread YourMistakes.all), coworker scripts for the voice dump test.`,
  board: `Kind: a Learn board, structured like the Module 6 boards (learn_board_pack63.dart, test/learn_board_63_test.dart, tool/m6_board63_art.py with its fairness check: no colour/backdrop gives the safe card away; every SVG in the folder is a card). 5 rounds unless the rulings say otherwise; 4–6 cards per round. Your files: the lib file from the work item, test/learn_board_6<L>_test.dart, tool/m6_board6<L>_art.py, art in the item's art folder. Wiring needed: import/export/lookup lines in learn_board_models.dart, catalog learn pack + rung status playable. No YouTube id (owner decision 14).`,
  gate: `Kind: the Module 7 rank gate (rank সুপারভাইজার via unlockRank(7), badge 'আইন কি বলে?' in one constant marked owner-may-rename, 5–7 min, mixes all 10 lessons of Module 7 as the gate spec says; F7 isolation is the AB switch + HG fuses, never DO). Copy the structure of the Module 6 gate: lib/features/game/m6_gate_storm_feeder.dart (+ _world.dart), test/m6_gate_storm_feeder_test.dart and its perf test, and how gate_m6 is wired (grep gate_m6 in content_catalog.json, do_games.dart, mistakes_book.dart). Your files: the lib file from the work item (+ _world.dart), its test, perf test, art folder. Wiring needed: do_games case, catalog gate pack + rung playable with deadlyRules, mistakes_book.`,
}

const BUILD_SCHEMA = { type: 'object', properties: {
  item: { type: 'string' }, summary: { type: 'string' },
  files: { type: 'array', items: { type: 'string' } },
  wiring_needed: { type: 'array', items: { type: 'string' } },
  rival_lines_missing: { type: 'array', items: { type: 'string' } },
  open_questions: { type: 'array', items: { type: 'string' } },
  tests_run: { type: 'string' }, tests_passed: { type: 'boolean' },
}, required: ['item', 'summary', 'files', 'wiring_needed', 'rival_lines_missing', 'open_questions', 'tests_run', 'tests_passed'] }

const REVIEW_SCHEMA = { type: 'object', properties: {
  item: { type: 'string' }, verdict: { type: 'string', enum: ['pass', 'fix'] },
  findings: { type: 'array', items: { type: 'object', properties: {
    severity: { type: 'string', enum: ['must', 'should', 'nit'] }, file: { type: 'string' }, issue: { type: 'string' }, fix: { type: 'string' },
  }, required: ['severity', 'issue', 'fix'] } },
  tests_passed: { type: 'boolean' },
}, required: ['item', 'verdict', 'findings', 'tests_passed'] }

const RESTART = "\nRESTART NOTE: an earlier attempt was stopped to run more rungs in parallel. Your rung's files may already exist partly (lib, world, test, art script, SVGs). Inspect them first: keep what is sound, finish or rewrite the rest. Never touch other rungs' files."

const buildPrompt = it => `${COMMON}

YOUR RUNG: ${it.id} (lesson ${it.lessonId}). Spec: ${SPEC_DIR}${it.spec} (read it fully: level/board design, deadly/slip rows incl. classAfterRulings, changes, giveaway risks, gesture hints). Lib file: ${it.file}. engineType: ${it.engineType}. Art folder: ${it.art}.
${KIND[it.kind]}
Build the whole rung: rules/deal, scene, the playbook beats, the coworker two-beat moment (recorded-voice line, next decisive control waits for him), reason picks, gesture hints for every waiting state (how, never what), mistakes with lesson sources, deadly freeze, 3-slip strike-out, idle = zero frames. Tests: rules, deal variety, option libraries, every spoken line listed, idle perf, a full clean flow incl. a reason pick and the coworker, 3-slip strike-out, deadly freeze. Run analyze on your files and your tests until green.
Return item="${it.id}".`

const reviewPrompt = (it, b) => `${COMMON}

You are an INDEPENDENT REVIEWER (do not trust the builder's summary; read the code). Rung ${it.id}, spec ${SPEC_DIR}${it.spec}, rulings docs/module_specs/module7_rulings.md.
Builder report: ${JSON.stringify(b)}
Check: matches spec + rulings (deadly/slip classes exactly, incl. the cross-module rulings and the owner answers M7-1..M7-13; live lesson text over spec numbers), lesson-true content only (tool/all_training_chapters_bn.json), owner term rules in every Bangla line (ডেড, LT/HT/kV, ON/OFF, AB লাগানো, nukta form), every spoken line in newGuideLines/newRivalLines, playbook beats on the kit, coworker cannot be skipped by fast play and his line fits, no answer giveaways (§4), every board hand holds a safe card, gesture hints how-not-what, wrong flag / needless stop costs something, recordStars called, English digits, Bangla correctness, option groups within 1.3x, idle zero frames, tests meaningful and green (run them through tool/flk.ps1), analyzer clean, no edits to shared files, no leftover test/zz_*. Do NOT edit any file. Severity: must = bug/safety-wrong/test red/rule broken; should = clear quality issue; nit = polish. verdict=fix if any must or should.
Return item="${it.id}".`

const fixPrompt = (it, b, r) => `${COMMON}

FIXER for rung ${it.id} (spec ${SPEC_DIR}${it.spec}). Fix every must and should finding below (nits if cheap), keep tests green (run them via tool/flk.ps1), analyzer clean on your files.
Builder report: ${JSON.stringify(b)}
Review findings: ${JSON.stringify(r.findings)}
Return item="${it.id}" with the full, updated report (files, wiring_needed, rival_lines_missing, open_questions — carry over the builder's entries that still apply).`

// At most 6 rungs in flight at once (a sliding window): 16 parallel agents on
// this 16 GB machine ended the session twice.
const LIMIT = 15
let active = 0
const waiting = []
async function limited(fn) {
  while (active >= LIMIT) await new Promise(r => waiting.push(r))
  active++
  try { return await fn() } finally { active--; const next = waiting.shift(); if (next) next() }
}

const MODEL = it => 'sonnet'

async function rung(it) {
  const b = await agent(buildPrompt(it), { label: `build:${it.id}`, phase: 'Build', schema: BUILD_SCHEMA, model: MODEL(it) })
  if (!b) return null
  const r = await agent(reviewPrompt(it, b), { label: `review:${it.id}`, phase: 'Review', schema: REVIEW_SCHEMA })
  if (!r || r.verdict === 'pass') return { item: it.id, build: b, review: r, fix: null }
  const f = await agent(fixPrompt(it, b, r), { label: `fix:${it.id}`, phase: 'Fix', schema: BUILD_SCHEMA, model: MODEL(it) })
  return { item: it.id, build: b, review: r, fix: f }
}

const results = await parallel(ITEMS.map(it => () => limited(() => rung(it))))
const done = results.filter(Boolean)
log(`${done.length}/${ITEMS.length} rungs built and reviewed; ${done.filter(d => d.fix).length} needed a fix`)
return done
