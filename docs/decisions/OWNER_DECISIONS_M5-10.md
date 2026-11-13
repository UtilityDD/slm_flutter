# Owner decisions — Modules 5–10 designs (2026-11-11)

**86 decisions in total.**

Not built yet. Each line is a question the designers could not settle from the lessons; the full designs are in `docs/module_specs/module<N>_spec.json`. Lesson contradictions found while designing are in `design_flags_M5-10.md`.

## Module 5 (15 decisions)

1. R8, the biggest call: re-energizing a faulted line to test or burn it is DEADLY across Module 5. This covers 5.1a's coworker (raised from slip), 5.4a/b, 5.8b's LT site (raised from slip) and the gate. Source: lesson 5.4's own 'মারাত্মক ভুল' and the M1 rule that the lesson's 'মারাত্মক ভুল' means deadly. Either confirm it, or rule it a slip module-wide. Then align M4 do_4_4_b, which books 'reclosing after a re-blow' as a slip; the clean split is instant blast with arc = deadly, unspecified re-blow = slip.
2. R2: working on isolated equipment before the tester shows 0 V is DEADLY. This raises do_5_8_a and do_5_8_b from slip and matches M1 step 18 and 2.6/2.9. Earthing before the test stays a slip (4.1a).
3. R7: an in-service line (tripping and reclosing) may be patrolled from the ground without a PTW. Every climb or touch on it is deadly. Lessons 5.2b and 5.7b and gate case F all depend on this. R6: patrolling a tripped or locked-out feeder before the PTW is a slip. do_5_2_a and do_5_7_a now start with a PTW docket chip.
4. Fallen wire: entering 10 m = deadly (R13), a long stride out of the zone = deadly (R15; lesson gives the rule, not death), a cordon under 10 m = slip (R16).
5. do_5_6_b: a bystander's contact is deadly for the player (R17; no M1 precedent) and a late stop is a slip (R18).
6. R32: listening to 5.8's water myth stays a slip, although the lesson calls it 'মারাত্মক ভুল!'.
7. R33: peg or dig before the local-authority call = slip, not deadly.
8. R9: the first DO re-fit on a fresh blow with no history is allowed.
9. Verb changes for distinctness: 5.4b patrol cut; 5.5a flag and thermal cut (engineType renamed m5_lv_street_read); 5.7a thermal cut; 5.7b and 5.2b sound homing cut; 5.2b binocular circle replaced; 5.3a open/short stamps moved to 5.6a. Approve as a set.
10. Evidence-gated verdicts (a right answer without its readings = slip) are used in 5.5a, 5.5b and 5.9a, and 'ask before choosing' in 5.5a. Approve this as a general rule.
11. Boards trimmed to 5 rounds each (dropped rounds listed in changes).
12. Gate: rank অ্যাডভান্সড (unlockRank(5)); content_catalog gate_m5 engineType changes from 'gate_field' to 'm5_gate_case'; badge (reuse 'ফল্ট ফাইন্ডার'?); length 5–7 min, so drop the aftershock or the history field if it runs long; case F only if R7 is accepted.
13. Source-text fixes in tool/all_training_chapters_bn.json: 5.6 (प्रचंड, टकराলে, টকরানো, شدید), 5.7 ('дорогу', '보이는'), 5.8 ('শদিদ'), 5.10 ('அவை', 'निरीक्षण, परीक्षण … विश्लेषण'), 5.1 ('टकरा'). On-screen text uses clean Bangla until these are fixed.
14. Audio: new rival clips are needed for every coworker line that is new or a myth (tool/rival_clip.py). Guide, operator, neighbour and villager lines use device TTS. No YouTube ids yet for 5.x Learn boards.
15. Content to confirm with a lineman: the hand bend-test for annealing (5.3b); judging thermal hotspots against the same joint on the other two phases (5.10a); measuring at the LTDB instead of the LT bushing (5.5a).

## Module 6 (14 decisions)

1. EARTH CONFLICT ACROSS MODULES: 6.11a and the gate make signing off with a broken earth path deadly (as 4.6b does), but 3.5b scored listening to 'আর্থ তারটা একটু কাটা তো কী' as a slip. Pick one rule for Modules 3, 4 and 6.
2. DO-FUSE CONFLICT: lesson 6.3 says WBSEDCL 11 kV DTRs and AB switches 'সাধারণত ড্রপ আউট (DO) ফিউজ ব্যবহার করা হয় না', while M3 3.4 and M4 4.4 play DO fuses on DTRs. Module 6 uses HG only. Decide how the ladder reconciles this.
3. SPEED CONFLICT: 2.5/do/1 slips a rushed hot-stick AB turn, but 6.4 says 'দ্রুত এবং দৃঢ়ভাবে' for the AB's own ground handle. Proposal: only a stalled stroke is a slip in 6.4, and add a note in MODULE2_LADDER.
4. Confirm the deadly rows marked needsOwner: closing an AB on load; the rod-hook-before-clamp rule carried from M1; field tank opening and re-charging a burnt-oil DTR (6.1b and gate); landing a core with the SFU ON and water on a live joint (6.9); a bare-hand bypass pull (6.10b); an earth set on a live section (gate, M1 rule); the optional 6.1a climb push.
5. Confirm the slip rows marked needsOwner, in particular: pliers on an HRC (judge changed it from deadly to slip); a swollen capacitor unit left in service (if raised to deadly, raise it in 6.7b and the gate together); armour earthed at one end only (6.5a, unlike 4.6b's strip); hands-on in TEST; the capacitor wait cut short; reclosing before the fault is found; a broken R-Y-B sequence; a wrong-SWG tinned fuse wire.
6. Capacitor wait minimum: 5 game minutes (recommended) or 10. This applies to 6.7a and the gate.
7. Accept the judge's verb changes: 6.1b becomes coil forensics; 6.5b uses pegged straight legs; 6.9b uses a dropper pluck; 6.9a has no shutter; 6.10a drops note-taking; 6.10b is auto-framed and renamed m6_meter_swap_proof. 6.8b remains the module's only finger-trace level.
8. Lesson overlap: 6.9 almost duplicates 3.7, and 6.1 repeats much of 3.6. Keep both as full lessons or shorten them? Both board myths about thick wire (6.3 board, 6.9 board) repeat M3 3.4's idea.
9. Should a lineman build an earth pit (6.11a), or should the level frame him as inspecting a contractor's pit? Also: is one Do level enough for 6.11, given 4.6?
10. Gate items not in any single lesson: the combined feeder layout, 'needless outage = slip', the radio to the control room for breaker and recloser, AB-T as the backfeed source, 'both sides' earthing (Module 1), the game-time ratio, and the rank name and badge from the module plan.
11. Kit additions requested: HintSpec.pinch and HintSpec.circle for 6.6b (or the listed fallbacks).
12. New rival clips needed via tool/rival_clip.py: 6.1a myths 1 and 2; 6.1b myth 3 + push and the recharge push (shared with gate variant g); 6.2 myth 1 + push (gate a); the 6.2b pushes; the 6.3a pushes; 6.4 myth word for word and the two 6.4b pushes; the 6.5a pushes; the 6.6a/b lines; 6.7b's pushes; 6.8b myth 2 + shortcut; 6.9a shortcut; 6.9b myth 1 and SFU variant; 6.9 myth 2 (gate f); 6.10a/b pushes; 6.11 myths A/B. Board rival clips are shared where the words match.
13. Illustrative numbers that need sign-off: the 6.7b meter values, the 6.11a megger bands (the reason cards say '5 ওহমের মধ্যে'), the 6.1a quick bonus of 120 s, and the 6.5a ring scales.
14. YouTube explainer ids for 6.1–6.11 (null until given).

## Module 7 (13 decisions)

1. Approve the four redesigns made to keep verbs distinct: do_7_1_b (question orders with the rulebook), do_7_2_a (calendar tear instead of a scrubber), do_7_6_b (route the mishap, one-hold record), do_7_8_b (depot handover to arriving vehicles).
2. Module deadly list: unsigned field copy or verbal permit; torn/unrated 11 kV gloves (and no gloves on a hook); cut harness webbing; live hook removal; uncertified person on energised live-line work; charging the line with a man up (F12); a public rod/bamboo reaching the line (7.3b); letting the coworker coil a wire not proven dead (7.7a S2); entering a fallen wire's zone. Everything else is a slip. Confirm each 'needsOwner' row.
3. Rule: letting another person touch a conductor you could have stopped = deadly (7.3b, 7.7a S2). Accept, or make both heavy slips?
4. Rule: past acts judged at an inquiry desk are always slips (do_7_4_b), while the same act done in the field carries its own class (F12). Accept?
5. Reg 3 split: non-live line work by an unfit person = slip everywhere; energised live-line work without its certificate = deadly (7.10a only). Accept, or make all Reg 3 cases slips?
6. Lessons with no deadly: 7.1, 7.2, 7.8, 7.9 (and do_7_3_a, do_7_4_b, do_7_5_a, do_7_7_b). Confirm.
7. HT side-of-house clearance dealt on 33 kV only (the lesson's 2.0 m for 11 kV may need correcting).
8. do_7_5_b phase 2: add a tester proof after the shutdown (Module 2.2's rule), or keep 7.5's words only?
9. Gate F7 cue (hook on the job's isolated span vs the other DTR's live line) and the drawn DO-isolation at the lane DTR. Approve.
10. Coworker clips to record with tool/rival_clip.py: every myth line used verbatim (7.1 ×2, 7.2 ×2, 7.3 ×2, 7.4 ×2, 7.5 ×2, 7.6 ×2, 7.7 ×2, 7.8 ×2, 7.9 ×2, 7.10 myth 2) plus the shortcut lines (7.2b bills, 7.3b roof variant, 7.4a ×2, 7.5b hook, 7.7a S2/S3, 7.8a hose, 7.8b municipal truck, 7.9a ID).
11. Fix the lesson JSON glitches (Cyrillic, Tamil, Persian, Hindi and Latin fragments in 7.4, 7.5 and 7.6).
12. Kit change needed: a curved-path drag hint for do_7_8_a's boom ring.
13. quickMs for every Module 7 level after playtest; rank সুপারভাইজার (unlockRank(7)) with badge 'আইন কি বলে?' at the gate.

## Module 8 (16 decisions)

1. Confirm the module rule: Module 8 deadly only for climb/earthing acts (written PTW, rod earth both ends, solar fuses out, rod-before-chain, clamp-before-hook) plus the gate's pre-shutdown trim; everything regulatory, billing, grievance, grid, environmental and ethical is a slip.
2. New deadly row: climbing with any solar fuse in (8.8a, gate) — deadly every time. Yes?
3. Gate C2: a pre-shutdown trim is deadly (4.8/do/0 precedent) — confirm, or drop C2 from the gate.
4. Frequency through 49.0 stays a slip (alternative: module-wide 'ব্ল্যাকআউট' deadly).
5. 8.5b splits: key not in own pocket, missing lock/board, bad chain after the rod, partial/skipped chain, early chain removal — all slips (Module 1 step 14 made a jugaad rod deadly). Confirm each.
6. PCB oil without গ্লাভস/mask = slip; taking a bribe = slip. Confirm.
7. Earth rod before the permit in the gate = slip (not in the lesson).
8. Reason-deck vs decision-deck rule (◆ only vs slip) for the whole module.
9. Replacement levels: approve do_8_1_b (hearing balance, with the trainee as mic runner — a game premise) or cut it; approve do_8_6_b (docket list lookup); approve do_8_9_a's pole-pruner verb.
10. Silent drawn figures (consumers, hearing speakers, bystanders, the tree owner, CGRF bench) with caption bubbles, no TTS: acceptable under 'one guide, one coworker'?
11. Branding: the regulator and companies appear only as plain text labels the lessons name (WBERC, WBSEDCL, CESC, APTEL, SLDC), no logos; 8.2 scenes use generic office papers.
12. Number rules: 'clear' notice-day counting (deals avoid 13–17 and 175–185 days); shutdown notice ≥ 24 h accepted; 17:00/06:00 boundaries allowed; breakdown treated as the emergency exception; clearance bands 20–24 / 13–16.5 ft and 1.5–2.2 / 0.5–0.9 m; ±5 game-min logbook tolerance; OLTC ~1.5% per step.
13. do_8_10_a sign cap: at most 2 slips from the sign itself?
14. New rival clips to record via tool/rival_clip.py: 8.1a, 8.1b, 8.3a (two), 8.3b (two), 8.4a (three), 8.4b (two), 8.5a (two), 8.5b (two), 8.6a (two), 8.6b (two), 8.7a, 8.7b, 8.8a, 8.8b, 8.9a, 8.9b (b), 8.10a (two), gate (two).
15. quickMs and quick-bonus values for every Do level and the gate to be set from playtests (no point values or pass marks changed).
16. Rank name and badge for the Module 8 gate come from the director's catalog.

## Module 9 (16 decisions)

1. Module rule: returning faulty equipment is a slip (harm comes later), except where the lesson names danger to people from the returned item (OL discharge resistor, broken earth path), which is deadly. Confirm. This makes 9.10's 'verdict better than the data' and the gate's wrong hand-back slips.
2. Wrong equipment ID in 9.10: the judge recommends slip, but the lesson says 'মারাত্মক ভুল'. Pick slip or deadly.
3. Bulging or leaking capacitor can signed back to service (9.9b): judge changed it to slip. Pick slip or deadly.
4. Climbing any pole of the live feeder in 9.6a = deadly (the quiet-pole slip was removed). Confirm.
5. CRM clamp on a non-isolated breaker = deadly (same class as megger-on-live). Confirm.
6. VLF zone deadlies (person inside at START, approacher reaching a charged end) — confirm.
7. CT secondary open in either order (including the derived restore order) = deadly — confirm.
8. Broken earth path signed 'ঠিক' = deadly (M4.6b) — confirm.
9. Slips to confirm: low-SF6 operation, spring mechanism (injury inset), Remote/DC ON/AR IN, fan OFF while charging, load test without backup, crackle flame.
10. Judge verb changes to approve: 9.1a role assignment (engine m9_ir_three_roles), 9.3b state cycling with a step selector, 9.8b linear hour track, 9.2b self-running clock, 9.10a with no trend plot, 9.5b tug-and-prove core.
11. Gate: confirm it may reuse the stop-the-moment frame of the approved M1 step-30 hazard gate (it differs by reading-validity, per-item hand-back and the signature). Also: the gate's rank name and badge; the adapted main coworker line needs approval and a clip.
12. Lesson content conflicts: 9.6 '১১ কেভি লাইনে ৩টি ডিস্ক' vs 3.2 (no kV labels on strings); 9.1 'এসসি সাপ্লাই' (likely এসি); 9.5 '< 5 Ω' vs 4.6 '5–8 Ω' (no readings dealt in 5–8 Ω).
13. Game numbers: time compressions (megger 1 min ≈ 6 s, BDV 10 min ≈ 15 s, VLF 15 min ≈ 60 s, capacitor 1 min ≈ 4 s), deal windows, 62% tolerance, ±1 kV balance, VLF knob as a ×rated multiplier or kV 16.5–22.
14. Myth reuse: 9.2 myth 1 (board + Do A), 9.3 myth 1 (board + Do B). OK?
15. Rival clips to record with tool/rival_clip.py: every new coworker line in 9.1–9.10 and the gate (the guide uses device TTS).
16. Explainer video ids for 9.1–9.10 (the gate is skipped until they exist).

## Module 10 (12 decisions)

1. Approve the six redesigned Do levels (10.5a panel lock, 10.9a hazard snap, 10.11a meter probe, 10.12b storm parallax, 10.13a sign & traffic, 10.15b rig the climb) and the three trims (10.6b, 10.14b, 10.16a).
2. Module size: Module 10 has 18 lessons → 18 boards + 35 Do levels + gate (10.18 has one Do level). Keep this, or cut the overview lesson 10.1 to one Do level?
3. Every row marked needsOwner in the deadly/slip table. The main ones: unwell mate climbing = deadly; earth/man still up at permit return = deadly while earth removed with a man aloft stays slip; backfeed source / recloser / no-shutdown pull = deadly; heavy rain and gusts = slip while lightning = deadly; water/foam on electrical equipment deadly even after power off; tall vehicle under a sagging span = deadly; barefoot rescuer = deadly; un-inducted helper and climbing-gear faults = slip; working at height without the belt hold = deadly.
4. Gate H3: location mismatch changed to deadly to match M1 step 17; holder-name mismatch stays slip — confirm.
5. Needless flag/stop = slip everywhere; asking for help when not needed = time only (no strike, no new scoring event) — confirm. This replaces the drafts' ◆-burn for field mistakes.
6. New figures: a silent supervisor NPC (10.3), a silent substation operator (10.5a, 10.8, gate), a silent customer in a doorway (10.11) — approve under the 'no new characters' rule, or render as props/bubbles only.
7. Coworker clips to record with tool/rival_clip.py: every Module 10 line except reused ones (10.12b reuses the 10.12 board rival; the gate reuses the 10.5 board and 10.6a lines). Supervisor/operator voices: silent bubbles or recorded?
8. Road height for 11 kV: 6.5 m (10.4, 10.13) vs 6.1 m (lessons 3.9, 7.3) — the module uses 6.5 m.
9. 10.4b bay plates: real 11/33 kV mapped to the table's 12/36 kV rows (and 1.2's 3.0 m for 33 kV), or plates showing the table's own ratings.
10. Timer/deal values (wind-ups, act windows, countdowns, spike-live and tracer rates, night/taut/sag rates) and quickMs per level after the build.
11. Rank and badge names for the Module 10 gate (not in the brief).
12. Explainer video ids for Learn slots (10.3, 10.17 and others) — null until supplied.
