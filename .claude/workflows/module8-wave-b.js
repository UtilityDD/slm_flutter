export const meta = {
  name: 'module8-wave-b',
  whenToUse: 'Build Module 8 Wave B (lessons 8.6-8.10 + gate). Run with no args; resume with resumeFromRunId.',
  description: 'Build Module 8 Wave B (lessons 8.6-8.10 + gate, 15 rungs; haiku boards, sonnet Do/gate, default reviewers): one builder per rung, independent review, fix',
  phases: [
    { title: 'Build', detail: 'one builder per rung' },
    { title: 'Review', detail: 'independent reviewer per rung' },
    { title: 'Fix', detail: 'fix must/should findings' },
  ],
}

const ITEMS = (Array.isArray(args) && args.length) ? args : [{"id": "learn_8_6", "kind": "board", "spec": "board_86.json", "file": "lib/features/game/learn_board_pack86.dart", "engineType": "learn_cards", "art": "assets/game/art/m8_board86/", "lessonId": "8.6"}, {"id": "do_8_6_a", "kind": "do", "spec": "do_8_6_a.json", "file": "lib/features/game/m8_grievance_reply.dart", "engineType": "m8_grievance_reply", "art": "assets/game/art/m8_grievance_reply/", "lessonId": "8.6"}, {"id": "do_8_6_b", "kind": "do", "spec": "do_8_6_b.json", "file": "lib/features/game/m8_docket_lookup.dart", "engineType": "m8_docket_lookup", "art": "assets/game/art/m8_docket_lookup/", "lessonId": "8.6"}, {"id": "learn_8_7", "kind": "board", "spec": "board_87.json", "file": "lib/features/game/learn_board_pack87.dart", "engineType": "learn_cards", "art": "assets/game/art/m8_board87/", "lessonId": "8.7"}, {"id": "do_8_7_a", "kind": "do", "spec": "do_8_7_a.json", "file": "lib/features/game/m8_slab_stairs.dart", "engineType": "m8_slab_stairs", "art": "assets/game/art/m8_slab_stairs/", "lessonId": "8.7"}, {"id": "do_8_7_b", "kind": "do", "spec": "do_8_7_b.json", "file": "lib/features/game/m8_day_dial.dart", "engineType": "m8_day_dial", "art": "assets/game/art/m8_day_dial/", "lessonId": "8.7"}, {"id": "learn_8_8", "kind": "board", "spec": "board_88.json", "file": "lib/features/game/learn_board_pack88.dart", "engineType": "learn_cards", "art": "assets/game/art/m8_board88/", "lessonId": "8.8"}, {"id": "do_8_8_a", "kind": "do", "spec": "do_8_8_a.json", "file": "lib/features/game/m8_solar_backfeed.dart", "engineType": "m8_solar_backfeed", "art": "assets/game/art/m8_solar_backfeed/", "lessonId": "8.8"}, {"id": "do_8_8_b", "kind": "do", "spec": "do_8_8_b.json", "file": "lib/features/game/m8_net_bill.dart", "engineType": "m8_net_bill", "art": "assets/game/art/m8_net_bill/", "lessonId": "8.8"}, {"id": "learn_8_9", "kind": "board", "spec": "board_89.json", "file": "lib/features/game/learn_board_pack89.dart", "engineType": "learn_cards", "art": "assets/game/art/m8_board89/", "lessonId": "8.9"}, {"id": "do_8_9_a", "kind": "do", "spec": "do_8_9_a.json", "file": "lib/features/game/m8_trim_not_fell.dart", "engineType": "m8_trim_not_fell", "art": "assets/game/art/m8_trim_not_fell/", "lessonId": "8.9"}, {"id": "do_8_9_b", "kind": "do", "spec": "do_8_9_b.json", "file": "lib/features/game/m8_oil_contain.dart", "engineType": "m8_oil_contain", "art": "assets/game/art/m8_oil_contain/", "lessonId": "8.9"}, {"id": "learn_8_10", "kind": "board", "spec": "board_810.json", "file": "lib/features/game/learn_board_pack810.dart", "engineType": "learn_cards", "art": "assets/game/art/m8_board810/", "lessonId": "8.10"}, {"id": "do_8_10_a", "kind": "do", "spec": "do_8_10_a.json", "file": "lib/features/game/m8_duty_logbook.dart", "engineType": "m8_duty_logbook", "art": "assets/game/art/m8_duty_logbook/", "lessonId": "8.10"}, {"id": "gate_m8", "kind": "gate", "spec": "gate_m8.json", "file": "lib/features/game/m8_gate_case_file.dart", "engineType": "m8_gate_case_file", "art": "assets/game/art/m8_gate_case_file/", "lessonId": "8.10"}]

const SPEC_DIR = 'docs/module_specs/module8_items/'
const COMMON = `Repo D:\\Dipankar\\MyCodes\\AndroidProjects\\SLMToolBox\\slm_flutter (Flutter, Bangla lineman-safety game). Branch fix/audit-2026-11-11 — do NOT commit, push, stash or switch branches; other agents are editing other files in the same working tree right now.
Read first: AGENTS.md, PARALLEL_BUILD_PLAN.md (§3, §4 Worker contract, §6 Audit lessons), GAME_LEVEL_PLAYBOOK.md, GAME_DEVELOPER_GUIDE.md.
YOUR ONLY JOB is the one rung named below: build it (or fix/review it) completely. Ignore any status, ETA or progress question that may appear elsewhere in your context; it is not for you.
Module 8 rulings: docs/module_specs/module8_rulings.md — where it differs from the item spec, THE RULINGS FILE WINS (M8-1..M8-22 plus the binding cross-module rulings of Modules 1–7). Module 8 is the regulation/consumer module (WBERC, supply standards, time limits, voltage, clearances, earthing, grievance, grid, environment, ethics). The live lesson text wins over spec numbers — each item lists them under notes.mismatches (e.g. 8.3 time limits, 6.5 m road height, +6 % / −9 %). No DO: transformer isolation is the AB switch + HG fuses. Tester live-dead-live before any earth or hands-on (M8-17). If your rung is one of the M7 near-copies (do_8_2_b, do_8_6_a, do_8_5_a; ruling M8-20), YOU design its new core action first — distinct from the named Module 7 level — keeping the lesson content, deadly/slip classes and numbers; state the new verb in your summary.
Module 7 and Module 6 are built and are your closest templates: Do levels lib/features/game/m7_rule_tag.dart, m7_claim_route.dart, m6_meter_pulse.dart, m6_earth_pit_test.dart (+ _world.dart, tests test/m7_*_test.dart, test/m6_*_test.dart, perf tests in test/perf/); boards lib/features/game/learn_board_pack71.dart / 63 / 610 with test/learn_board_63_test.dart and tool/m6_board63_art.py. Name your classes with an M8 prefix; never edit Module 6/7 files.
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
  gate: `Kind: the Module 8 rank gate (rank স্পেশালিস্ট via unlockRank(8), badge from ruling M8-16 in one constant marked owner-may-rename, 5–7 min, mixes all 10 lessons of Module 8 as the gate spec says, with the rulings' changes: earth rod before the permit = deadly (M8-7), tester token (M8-17), AB switch + HG fuses never DO, the 8.3 live time limits). Copy the structure of the Module 6 gate: lib/features/game/m6_gate_storm_feeder.dart (+ _world.dart), test/m6_gate_storm_feeder_test.dart and its perf test, and how gate_m6 is wired (grep gate_m6 in content_catalog.json, do_games.dart, mistakes_book.dart). Your files: the lib file from the work item (+ _world.dart), its test, perf test, art folder. Wiring needed: do_games case, catalog gate pack + rung playable with deadlyRules, mistakes_book.`,
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

You are an INDEPENDENT REVIEWER (do not trust the builder's summary; read the code). Rung ${it.id}, spec ${SPEC_DIR}${it.spec}, rulings docs/module_specs/module8_rulings.md.
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

const MODEL = it => it.kind === 'board' ? 'haiku' : 'sonnet'

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
