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

## Module 6 owner answers (2026-11-15)

Answered by the owner in docs/review/lessons_m5-10_and_m6_questions.xlsx. Rule used for the analysis: authentic documents; national (CEA, BIS) over WBSEDCL when they conflict; never Bangladesh sources.

1. If a worker finishes a job and leaves equipment running while its earth (safety ground) wire is cut or unbolted, is that a deadly mistake or a small mistake? Module 3 (level 3.5b) called it small; Modules 4 and 6 call it deadly. We need one rule.
   - **Answer:** Adopt the single rule (broken earth path = deadly, weak but connected = slip) and re-score 3.5b.
   - Basis: National law over WBSEDCL. CEA Safety Regulations 2023 Reg 43(ix)(c): earthing must 'retain electrical continuity' and be tested 'before ... apparatus are energised'. Reg 50(1)(i) requires earthing to limit touch and step voltage. Reg 77(1) says the arrester's job is to send lightning surges to earth because they 'may result into injuries'. DHBVN Safety Manual Don'ts 8: 'DO NOT disconnect earthing connection'. Precedent M1-4 ruling B1: listening is deadly only when the act pushed is deadly in that level, so 3.5b listening becomes deadly once the act is deadly.
2. Lesson 6.3 says WBSEDCL transformers usually have no drop-out (DO) fuses; they use an AB switch plus horn-gap (HG) fuses. But built Modules 3 and 4 show DO fuses on transformers. How do we make the game consistent?
   - **Answer:** Split into two. (2a) Module 6 levels show the WBSEDCL DTR with AB switch + HG fuses only (WBSEDCL HVDS BOQ; CEA 2023 Reg 37(3)(i) allows either). (2b) Built M3/M4 levels keep their DO fuses; add one short line on the 3.4 picture board: some companies use DO fuses, a normal WBSEDCL DTR has AB switch + HG fuses (owner to give the natural Bangla wording). Ask a WBSEDCL lineman whether older DTRs/branch lines still have DO fuses.
   - Basis: CEA Safety Regulations 2023 Reg 37(3)(i): 'a linked switch with fuse or gang operated air break switch with fuse or circuit breaker'. WBSEDCL HVDS BOQ, Malda 2020 (items 1.17, 1.18, 1.26: TPGO isolator + 'H.T Horn Gap Fuse Unit', no DO fuse). No WBSEDCL document found that says DO fuses are never used. A WBSEDCL field lineman can say whether older transformers or branch lines in his division still have DO fuses.
3. Module 2 marks a quick AB switch turn as a mistake, but lesson 6.4 says to work the AB switch handle 'quickly and firmly'. Which is right?
   - **Answer:** Apply ruling A3 in 6.4 and in 2.5/do/1.
   - Basis: Owner ruling A3 (2026-11-15, OWNER_DECISIONS_M1-4): 'AB switch: one firm, continuous stroke after the preparation. A slow or stalled stroke = slip.' DHBVN Safety Manual Don'ts 9: 'DO NOT open or close switch or fuse slowly or hesitatingly.' WBSEDCL TPGO isolator spec cl 4.4(iii): a spring makes contact opening speed 'independent of the speed of manual operation'.
4. Confirm which acts in Module 6 kill the player (deadly): closing an AB switch while power flows, hooking the discharge rod before its earth clamp, opening a transformer tank in the field, switching back on a transformer whose oil is burnt, working a pillar cable with its switch ON, water on a live joint, pulling a bypass wire bare-handed, putting earth leads on a live line, and climbing a live transformer because a coworker said so.
   - **Answer:** Confirm the eight deadly rows. Lower field tank opening on a dead, earthed transformer to slip in do_6_1_b and the gate.
   - Basis: TANGEDCO Safety Manual p.65: isolators 'should not be operated (open or close) on charged line / transformer'. WBSEDCL buys these as 'off-load' isolators. OSHA 1910.269(n)(6)(i): 'attach the ground-end connection first'. CEA 2023 Reg 21(1) and DHBVN Don'ts: touch nothing unless 'DEAD AND EARTHED'. DHBVN: 'DO NOT throw water on live electrical equipment'. CEA Schedule I Part-II(6), and precedent M1-4 B8: earth on a live line is deadly everywhere. Precedent M5-1: re-charging a transformer after a blow without finding the cause is deadly; lesson 6.1 says 'চার্জ করার ঝুঁকি নেবেন না'. Tank opening: IS 10028-3 cl 5.4.2 (national standard) treats it as a moisture/fire procedure risk. Precedent M5-6: a lesson's 'মারাত্মক' about equipment harm with nobody exposed stays a slip. Precedent A4: never touch a running transformer tank.
5. Confirm which acts are only small mistakes (slips): pulling an HRC fuse with pliers when the switch is off, leaving a swollen capacitor in service, earthing cable armour at one end only, handling a breaker in TEST position, not waiting the full capacitor time but still using the rod, switching back on before the fault is found, wrong phase order, and the wrong size of fuse wire.
   - **Answer:** Confirm all eight as slips with the limits above, and use the reason-card lines from the reference review (owner to give the natural Bangla).
   - Basis: Precedent A5: fuse touched or pulled with supply on = deadly, no PPE after proven isolation = slip. OSHA 1910.335(a)(2)(i)(A): insulated fuse tools when the terminals are energized. GE GEH-2743B: bulged capacitors risk 'explosive case rupture'. IS 1255 cl 13.1 (national): armour 'efficiently earthed at both ends'. IS 13925-1 cl 21: the discharge device is 'not a substitute for short-circuiting', so the rod is the real protection. DHBVN/TANGEDCO: do not renew a fuse until the cause is found. Precedent M5-1 (re-charge after a failed test charge = deadly). Precedent M5-6 (equipment harm only = slip). DHBVN Do's 7 'correct size and quality of fuse wire'. Precedent B2 (3.4a thick copper = deadly). The TEST-position and phase-order rows rest on engineering logic; no reference contradicts them.
6. After switching off a capacitor bank, how long must the player wait before putting on the earthing rod: 5 game minutes or 10?
   - **Answer:** 5 minutes, with an optional bonus for waiting 10.
   - Basis: OSHA 1910.269(w)(1)(i): 'waits at least 5 minutes ... before applying the short circuit'. TANGEDCO Safety Manual (Indian discom) p.62: 'wait for at least 5 minutes'. GE GEH-2743B: 'WAIT 5 MINUTES ... THEN SHORT-CIRCUIT AND GROUND'. The national IS 13925-1 10-minute figure is a design limit for the built-in resistor, not a work rule, and it says the rod is the real safeguard. CEA's ten-minute rule is for HVDC filter banks only. Lesson 6.7 '৫-১০ মিনিট' fits.
7. Accept the reviewer's changes to what the player does in some levels, so that no two levels feel the same (for example, 6.1b becomes reading clues from a burnt coil, and 6.10b is renamed m6_meter_swap_proof)?
   - **Answer:** Approve all as one set, with gentle cable bends in 6.5b.
   - Basis: REFERENCE_REVIEW M6-7 (game rule, no safety change); precedent M5-9 (verb changes approved as a set); IS 1255 cl 5.3 bending radius.
8. Lessons 6.9 and 6.1 repeat a lot of what lessons 3.7 and 3.6 already taught, and two Module 6 boards repeat the 'thick wire as a fuse' myth from Module 3. Keep them full, or shorten them?
   - **Answer:** Shorten 6.1 and 6.9 to one recap round plus the new material, and swap the 6.9 board's thick-wire myth for a new one.
   - Basis: REFERENCE_REVIEW M6-8 (game rule); design_flags_M5-10 (6.9 nearly duplicates 3.7).
9. In level 6.11a, should the lineman dig and build a transformer earth pit, or check and test a pit someone else built? And is one hands-on level enough for lesson 6.11?
   - **Answer:** Inspect-and-test framing, with one Do level.
   - Basis: CEA Safety Regulations 2023 Reg 43(x): the supplier's earths must be 'tested for resistance on dry day during the dry season at least once in a year'. That is a lineman's check-and-test duty whoever dug the pit. TANGEDCO Safety Manual p.79-80: 'three earth pits in triangular formation at a distance of six meter'. Level 4.6 already teaches building. A WBSEDCL lineman can say who digs pits in his division, but the answer does not change this framing.
10. The Module 6 final test (gate) uses some things no single lesson teaches: one combined feeder map, 'a needless power cut = small mistake', radioing the control room to open the breaker and stop the auto-reclose, a tie switch (AB-T) as a hidden second power source, earthing on both sides of the work, how fast game time runs, and the rank name and badge.
   - **Answer:** Option 1. Keep the safety items, use rank সিনিয়র and a 5–7 minute gate, and have the owner name the badge.
   - Basis: CEA 2023 Schedule I Part-II(3): permit from the 'Operation In-charge' and isolation 'from all sources of energy'. Reg 47(1)(iii): guard against 'inadvertent paralleling or backfeed'. DHBVN cl 8.16: 'completely isolated on both sides ... discharged and earthed'. CEA Schedule I Part-II(4): local earths 'at the zone of working'. Precedent M1 sound-pole ruling (needless outage = slip). Rank সিনিয়র: GAME_PATH_CHECKLIST Module 6. Gate format precedent: M5-12 (5–7 min).
11. For level 6.6b, should we add two new on-screen hand hints (a 'pinch' and a 'draw a circle' gesture) to the game kit, or use the simpler hints that already exist?
   - **Answer:** Use the existing fallback hints unless later modules plan to use pinch or circle.
   - Basis: REFERENCE_REVIEW M6-11 (UI kit, no safety content).
12. Many new coworker (rival) lines in Module 6 need voice recordings. How and when should they be recorded?
   - **Answer:** Owner approves the wording first, then all lines are recorded in the voice system after decisions 1 and 4 are final.
   - Basis: Owner voice rule 2026-11-14 (VOICE_GUIDE.md: 'Every spoken line is a recorded clip in the owner's voice system'; coworker voice = bn-BD-PradeepNeural, recorded with tool/rival_clip.py). New-text rule: ask the owner for natural wording before using any new line. REFERENCE_REVIEW M6-12: record after the M6-1/M6-4 rulings.
13. Some example numbers need sign-off: the meter readings in 6.7b, the earth-resistance bands in 6.11a (cards say 'within 5 ohms'), the 120-second speed bonus in 6.1a, and the ring scales in 6.5a.
   - **Answer:** Option 1, then ask a lineman which tool name he uses and switch to 'আর্থ মেগার' if that is the field word.
   - Basis: TANGEDCO Safety Manual p.81 'Recommended Combined Values for Earth Resistance': 'Distribution Transformer 5 Ohm'. CEA 2023 sets no transformer figure (its 25 ohm in Reg 50(7) is only for guard wires at crossings). No WBSEDCL figure found. A WBSEDCL engineer can say whether WBSEDCL uses a different target and which word linemen use ('আর্থ টেস্টার' or 'আর্থ মেগার').
14. Which YouTube explainer videos (if any) should be linked to lessons 6.1 to 6.11?
   - **Answer:** Leave them empty for now; the owner adds Indian training videos later.
   - Basis: REFERENCE_REVIEW M6-14; precedent M5-14 (no YouTube ids yet); owner reference rule (Indian/international sources, never Bangladesh).

## Module 7 owner answers (2026-11-16)

Answered by the owner on 2026-11-16 ("proceed with the recommendations"), sheet docs/review/m7_questions_2026-11-16.xlsx. Rulings and what builders do: docs/module_specs/module7_rulings.md. Rule used: authentic documents; national (CEA, BIS) over WBSEDCL when they conflict; never Bangladesh sources.

1. Four levels were redesigned so no two levels play the same way: 7.1b (question an order with the rulebook), 7.2a (tear calendar pages), 7.6b (take each PPE problem to the right person), 7.8b (hand each waste to the right truck). Approve them?
   - **Answer:** Approved: the four redesigns.
   - Basis: M5-9 and M6-7 (verb changes approved as a set); REFERENCE_REVIEW M7-1.
2. Module 7 'deadly' list (level ends at once): field PTW copy not signed, or a spoken 'line off' with no paper; torn or wrong-rated gloves on an 11 kV job; cut harness strap; pulling a theft hook off a live line; untrained man on live-line work; asking to charge the line while a man is still up; a passer-by's rod touching the line because you did not warn; letting a coworker coil a fallen wire not proven dead; walking into a fallen wire's zone. Everything else is a small mistake (slip). Confirm?
   - **Answer:** Approved as written. Everything else = slip; every needsOwner row on the list is confirmed. No গ্লাভস on the hook stays deadly even after the proven isolation.
   - Basis: M1 step 17 / B7; B6; B8; M5-1; M5-4; M5-5; CEA 2023 Reg 21(1)-(2), Schedule I Part-I(1), Part-II(3), (4), (6); IS 4770 Annex B-3.2 (REFERENCE_REVIEW M7-2).
3. If the player could have stopped another person touching a live wire and did not (a passer-by's bamboo in 7.3b, a coworker coiling a wire in 7.7a), is that deadly?
   - **Answer:** DEADLY (7.3b, 7.7a S2), after a clear timed chance to warn. Matches M6-1 (signing a broken earth because coworker B said so = deadly).
   - Basis: M5-5; M6-1; CEA 2023 Schedule I Part-II(6)-(7) (REFERENCE_REVIEW M7-3).
4. At the inquiry desk (7.4b) the player only judges old records. Are mistakes there always slips, while the same act done in the field (gate: charging with a man up) stays deadly?
   - **Answer:** Approved: desk = slip; the same act in the field keeps its class.
   - Basis: M5-6 precedent; REFERENCE_REVIEW M7-4.
5. Untrained or unauthorized man on shutdown (dead) line work = slip. Man without the live-line certificate on live-line work = deadly (7.10a only). Accept this split?
   - **Answer:** Approved: non-live work by an unfit person = slip everywhere; live-line work without the certificate = deadly (7.10a only).
   - Basis: CEA 2023 Reg 3(3), Reg 21(3), Schedule I Part-I(1) (REFERENCE_REVIEW M7-5).
6. No deadly at all in lessons 7.1, 7.2, 7.8, 7.9 and in levels 7.3a, 7.4b, 7.5a, 7.7b (paperwork, waste, customer visits, surveys). OK?
   - **Answer:** Confirmed: 7.1, 7.2, 7.8, 7.9, do_7_3_a, do_7_4_b, do_7_5_a, do_7_7_b have no deadly.
   - Basis: M5-6 (nobody exposed = slip); REFERENCE_REVIEW M7-6.
7. Today's lesson 7.3 has new clearance numbers: across a road 11 kV and 33 kV = 6.5 m (was 6.1), LT = 5.8 m; beside a house 11 kV = 1.2 m and 33 kV = 2.0 m (was 2.0 m for all HT). Use them, and also show 11 kV house-side sites?
   - **Answer:** HT side-of-house clearance dealt on 33 kV only (2.0 m). The lesson's 11 kV figure is corrected to 1.2 m (CEA) as a lesson fix for the director - already present in the live 7.3 text (checked 2026-11-16).
   - Basis: CEA 2023 Reg 63(3); A2 (6.5 m across a road) (REFERENCE_REVIEW M7-7).
8. Before pulling a theft hook (7.5b and gate), add a tester check and an earth after the shutdown?
   - **Answer:** ADD the tester live-dead-live proof after the shutdown in do_7_5_b phase 2 (Module 2.2 rule). With X1 and live 7.5 pro tip 4 the earth follows the 0 V.
   - Basis: CEA 2023 Reg 21(1), Schedule I Part-II(3), (6); OSHA 1910.269(m)(3)(vi) (REFERENCE_REVIEW M7-8); M5-2.
9. Gate hook step (F7): the job's DTR is isolated and the other DTR's line is live. Should approving the hook removal also need tester 0 V and an earth on the job span? And if the player approves on the open switch alone, is that deadly or a slip?
   - **Answer:** F7 cue approved, but no DO: the lane DTR isolation is the AB switch (+ HG fuses), per M6-2. Every DO in the Module 7 items becomes the AB switch.
   - Basis: M6-2a; CEA 2023 Schedule I Part-II(3), (6), (7) (REFERENCE_REVIEW M7-9).
10. New coworker lines and the myth lines need voice clips. How to do it?
   - **Answer:** Yes: every myth line verbatim + the shortcut lines, recorded in Subrata's voice system after the owner words them (DRAFT rule M6-12).
   - Basis: Voice rule 2026-11-14; M6-12.
11. Fix the stray foreign letters in lesson text 7.4, 7.5, 7.6?
   - **Answer:** Yes; the director keeps the exact fix list (module7_rulings.md, M7-11). Already applied in the live text 2026-11-15; none left (checked 2026-11-16).
   - Basis: Lesson fixes 2026-11-15.
12. 7.8a (draw an oil boom ring) asked for a new curved hand-hint in the game kit. Add it?
   - **Answer:** No new curved-path hint: do_7_8_a uses the existing drag-hint fallback.
   - Basis: M6-11.
13. Gate: rank সুপারভাইজার, badge 'আইন কি বলে?' (the same badge as the 7.x lessons), 5-7 minutes. Quick-bonus times: builder's estimate (about 85% of a clean play)?
   - **Answer:** Rank সুপারভাইজার (unlockRank(7)); badge 'আইন কি বলে?' (one constant, owner may rename); quickMs after playtest.
   - Basis: M6-10; M5-12; lesson badge_name (REFERENCE_REVIEW M7-13).

Still open after these answers (interim defaults in module7_rulings.md): O1 field memo in levels (interim PTW only); O2 a national source for an 18+ bar (applied: no age rule, as the live 7.10 text); O3 the glove label 'IS 4770 · টাইপ ৪' (applied from the live 7.6 text); lesson items XL7.1-T1, L7.2-2, L7.3-3.
