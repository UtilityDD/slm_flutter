# Module 8 rulings (2026-11-16) — apply over `module8_items/*.json`

> **BINDING (2026-11-16).** The owner said "build Module 8" and "no need to wait for my approval, continue with the drafts": every recommendation in `docs/review/m8_questions_2026-11-16.xlsx` (22 questions + all 'Need your call' rows) is accepted as written below. New Bangla text stays DRAFT wording (M6-12) for the owner's later wording sheet.

The 16 Module 8 design questions are in `docs/decisions/OWNER_DECISIONS_M5-10.md`, section "Module 8 (16 decisions)" (and
the spec's `ownerDecisions`). Six more (M8-17 to M8-22) came from today's check against the live lessons and the Module 1–7
rulings. The cross-module rulings of Modules 1–7 (M1-4 rulings A1–A9 and B1–B8, the Module 5 rulings, M6-1 to M6-14 and
X1–X7, M7-1 to M7-13 and Module 7 X1–X7) already apply. Where a ruling below differs from an item spec, **this file wins
over an item spec** . The last column names the spec rows (R-numbers, as in every item's
`deadlySlipTable`), spec fields or items that the ruling overrides.

**Content source:** lesson text comes from `tool/all_training_chapters_bn.json` only. The live 8.x text differs from the
spec's quotes in several places (8.1 myth 2, 8.3 time limits and notice, 8.4 voltage, 8.5 road height, 8.6 compensation,
8.10 pro tip 1 and myth 2). The live text wins (X3). Every item lists its differences under `notes.mismatches`. Do **not**
edit the lesson file. Never use a Bangladesh source.

Row ids: R1–R23 follow `module8_spec.json` `deadlySlipTable` in order. These rulings add rows N1–N6. Every item's
`deadlySlipTable` already carries `classAfterRulings`, `ruling`, `rulingNote` and `rulingStatus: "DRAFT pending owner"` on
each row (rows that were `needsOwner` keep `needsOwnerInSpec: true`), and its new rows are under `addedRows`.

## Owner answers (decisions 1–16) — DRAFT

| # | Ruling | What builders do | Overrides |
|---|---|---|---|
| M8-1 (dec 1) | **Deadly only for climb and earthing acts**: climbing without the written PTW (R1), with a solar fuse in (R2), without rod earth at both ends (R3), chain thrown as the earth before the rod (R4), rod hook before its earth clamp (R5), plus the gate's pre-shutdown trim (R6). **Plus the binding cross-module rows:** climb or touch before the tester shows 0 V (N1), an earth put on a still-live line (B8, R16), the Module 7 hook rules (N4). Everything regulatory, billing, grievance, grid, environmental and ethical = **slip** (R7). | 8.1, 8.2, 8.3, 8.4, 8.6, 8.7, 8.8b, 8.9 and the paperwork parts of 8.10 and the gate have slips only. Clear every 'owner to confirm' note on R7. Listening to the coworker takes the class of the act he pushes (B1): deadly only in do_8_5_b myth 3, do_8_8_a, do_8_10_a variant A and gate M1. | needsOwner cleared on R7; adds N1–N4 |
| M8-2 (dec 2) | **Climbing with any solar house's fuse still in = DEADLY every time**, whatever the dealt inverter would do (M1 step 15 logic). | do_8_8_a and the gate: grey freeze, back-feed chain in colour. Listening to 'ইনভার্টার নিজেই বন্ধ হয়ে যায়' = deadly. A non-solar fuse pulled = slip (R18). | R2 (needsOwner cleared) |
| M8-3 (dec 3) | **Gate C2: cutting the branch on the line before the shutdown/permit = DEADLY** (live 8.9 'শাটডাউন নিয়ে ডাল কাটার সময়'; M4 4.8; B8). C2 stays in the gate. | After the permit it is the right act; a harmless branch or the trunk = slip. do_8_9_a never offers a live cut. | R6 (needsOwner cleared) |
| M8-4 (dec 4) | **Frequency through 49.0 Hz before the ordered feeders are off = slip** (M5-6: system harm, nobody exposed). No module-wide 'ব্ল্যাকআউট' deadly. | do_8_4_a: the round still ends with the feeders off. | R8 (needsOwner cleared) |
| M8-5 (dec 5) | **8.5b splits confirmed, all slips:** key not in own pocket (R11), no padlock or no 'কাজ চলছে' board (R12), a rusty, broken-link, bent-hook or iron jugaad chain thrown after the rod earthed that end (R13), chain on 1–2 phases or skipped (R14), chains pulled before clearance (R15). | The rod earth at both ends is the protection and stays on (M1 step 18: LOTO faults not deadly; M1 step 14: a jugaad ROD stays deadly). Chain before the rod, climb without rod earth both ends, hook before clamp stay deadly. | R11–R15 (needsOwner cleared) |
| M8-6 (dec 6) | **PCB oil handled without গ্লাভস and mask = slip; taking cash for hooking or a bypass = slip.** | do_8_9_b card (DRAFT) quotes live 8.9 advanced: 'পুরনো ট্রান্সফরমার হ্যান্ডেল করার সময় গ্লাভস ও মাস্ক পরা বাধ্যতামূলক'; do_8_10_a card: 'ধরা পড়লে আইন আপনাকে ছাড়বে না'. B6 (bad electrical gloves = deadly) is a shock rule and does not apply to oil. | R19, R20 (needsOwner cleared) |
| M8-7 (dec 7) | **Gate: earth rod before the written permit = DEADLY** (changed from the spec's slip). Before the permit the DTR is still ON, so the rod lands on a live line (B8). After the permit but before the tester shows 0 V = slip (N2). | Grey freeze with the arc at the rod. The 'পারমিট' beat is still the only way the shutdown happens. | R16 (slip → deadly), gate slips[4] |
| M8-8 (dec 8) | *Settled.* **A wrong 'why' reason card costs the table ◆ only; a wrong card in a field decision deck (what you say or do) = slip** (GAME_LEVEL_PLAYBOOK: 'A wrong reason costs the table ◆, not a strike'). | Every level and the gate. | R23 (needsOwner cleared) |
| M8-9 (dec 9) | **The three replacement designs are approved:** do_8_1_b `m8_hearing_balance` (the trainee as mic runner is a game premise), do_8_6_b `m8_docket_lookup`, do_8_9_a pole-pruner verb. do_8_1_b stays (the catalog has two 8.1 slots). | Build them as specified, subject to M8-20 for the near-copies of Module 7 levels. | spec changes 1–3 |
| M8-10 (dec 10) | *Settled (M7-D17).* **Consumers, hearing speakers, bystanders, the tree owner and the CGRF bench are silent drawn figures with caption bubbles.** Only the guide and the coworker speak. | Captions held for reading; the guide's TTS never voices them. They are not listed as spoken lines. | — |
| M8-11 (dec 11) | **Plain text names only** (WBERC, WBSEDCL, CESC, APTEL, SLDC, as the lessons name them); no logos; office papers generic. | Art generators draw no logo and copy no real form. | — |
| M8-12 (dec 12) | **Today's lesson numbers (X3) + the game number rules.** Live numbers: see 'Lesson numbers' below. Game rules: notice days are clear days (no deals at 13–17 or 175–185 days); a maintenance block may end at 17:00 or start at 06:00; a broken line counts as the emergency exception (night allowed, the live limit for that fault applies); ±5 game-minute logbook tolerance; OLTC about 1.5 % of nominal per step. | Rebuild do_8_3_a, do_8_3_b, do_8_4_b, do_8_5_a, boards 8.3, 8.4, 8.5, 8.10 and the gate's H1 on the live numbers (each item's `notes.mismatches` lists the fields). | 8.3, 8.4, 8.5, 8.10 numbers; spec ownerDecisions 'Number rules' |
| M8-13 (dec 13) | **do_8_10_a: at most 2 slips from the signature itself.** | A deadly climb still fails the level. No point value or pass mark changes. | — |
| M8-14 (dec 14) | *Settled (M6-12, M7-10).* **Every new coworker line and every myth line used verbatim gets a Subrata clip after the owner words it.** | DRAFT rule M6-12: each level keeps `newRivalLines` / `newGuideLines` in its Lines class (with a pinning test) and marks drafts `// DRAFT wording — owner`. Every spoken line (incl. 'why' questions, guide, radio, SLDC caller if voiced) is listed. Until recorded, the on-device fallback plays. Clip list: spec ownerDecision 14 plus the reworded 8.2b line (M8-18) and 8.1b/8.3b refuse cards (L1, L6). | coworkerPushBn texts in all items (wording only) |
| M8-15 (dec 15) | *Settled.* **Quick-bonus time = builder's estimate (~85 % of a clean play)**, stated in each report; tuned after playtest. | Every Do level and the gate. | every level's quickMs |
| M8-16 (dec 16) | *Settled pattern (M6-10, M7-13).* **Gate rank স্পেশালিস্ট** (catalog `modules` m8 `rankName`, unlockRank(8)), **badge 'জরুরী রেগুলেশন (WBERC ফোকাস)'** (the 8.x lessons' badge_name), 5–7 minutes. | One constant `M8GateLines.badge` marked `// OWNER may rename` (the name is long). At wiring the director changes the catalog's gate_m8 engineType from `gate_field` to `m8_gate_case_file`. | gate pass panel |

## Questions added from today's check — DRAFT

| # | Ruling | What builders do | Overrides |
|---|---|---|---|
| M8-17 | **Tester before earth and before any climb or touch** (X1, M5-2, A9 already bind; the spec has no tester anywhere). | **do_8_5_b:** a tester beat at the first end before the rod: tester proved on a live point, then 0 V on the span. Rod before 0 V = slip (N2); 'উঠি' before 0 V = deadly (N1); tester not proved = slip (N3). **Gate:** an 11th token **টেস্টার** (as the Module 6 gate's 7th); climb checks = PTW + tester 0 V + earth at pole 1 and pole 4 + every solar fuse out. Token row stays fixed and unrelated to the right order. **do_8_8_a** (climb coda) and **do_8_10_a** (time-lapse): the crew's tester and earths are shown before anyone climbs, without new scoring. Boards 8.5 rounds[4] and 8.10 rounds[2] add the tester to the safe pictures. | do_8_5_b flow, gate tokens (10 → 11) and climb checks, do_8_8_a ownerDecision 5, do_8_10_a flow beat 1c |
| M8-18 | *Settled (M7-2, M7-8, Module 7 sheet Q2).* **Hook removal = switch off → tester 0 V → earth → গ্লাভস → hook off.** No গ্লাভস on the hook = deadly only before tester 0 V + earth, slip after. | **do_8_2_b:** 'বিচ্ছিন্ন করুন' at a hooking premises plays as a short crew cut-scene in that order (no new scoring); the player scores the evidence-first order and the close-out. A bypass house's dead point is the pole fuse or the incoming cut-out, pulled with গ্লাভস (Module 6 X5). The coworker line becomes (DRAFT) 'আগে লাইনটা কেটে দাও, ভিডিও-টিডিও পরে হবে।' (order push = slip). **Gate C1:** 'তার খোলা' is a climb and runs the full climb checks; the trainee is always gloved. | do_8_2_b flow[5] / coworkerPushBn; spec unsupported[0] of 8.2; spec change 'hook removal is an abstract hold' |
| M8-19 | *Settled (M6-2a, M7-9, A3).* **The WBSEDCL DTR has an AB switch + HG fuses, never DO fuses.** | Every DTR drawn 'OFF' (8.3 burnt DTR, board 8.8 rounds[1], do_8_8_a, gate): AB opened in one firm stroke, all three blades seen, handle locked and tagged; HG fuses. No AB stroke is scored in Module 8. Term rule: closing = «AB লাগানো», never «AB বন্ধ». | do_8_8_a scene, gate scene and 'পারমিট' beat, board 8.8 rounds[1] |
| M8-20 | **Near-copies of Module 7 levels get a short redesign before their wave:** do_8_2_b (≈ do_7_5_b phone camera on a hook), do_8_6_a (≈ do_7_9_b phrase-tile reply), do_8_5_a (≈ do_7_3_a tape + legal/breach stamp). New core action only; lesson content, deadly/slip classes and numbers stay. | The director runs one design agent per level (no flutter) and replaces the item's `level` block before the wave. Smaller overlaps keep their design and keep the look apart: do_8_2_a calendar ribbon (never a tear-off pad, unlike 7.2a); do_8_9_b oil sheet and battery station (unlike 7.8a's boom ring and 7.8b's vehicles); do_8_7_b sun dial (flag for 10.14b). | do_8_2_b, do_8_6_a, do_8_5_a `level` (core verb) |
| M8-21 | *Settled (M5-11, Module 6/7 X6).* **Boards have 5 rounds.** | Drop the round a Do level already plays: 8.1 rounds[3]; 8.2 rounds[3]; 8.3 rounds[3]; 8.5 rounds[3]; 8.6 rounds[3]; 8.7 rounds[5]; 8.9 rounds[2]; 8.10 rounds[1] (each board item's `board.trimTo5`). Boards 8.4 and 8.8 already have 5. 4–6 picture cards per round; every hand holds a safe card; `youtubeId: null` (M6-14). | board_81/82/83/85/86/87/89/810 rounds |
| M8-22 | **Gate: the snapped LT wire hangs clear of the ground, with the crew's cordon already up.** | M5-4 (10 m zone) and M7-3 (bystander contact) then do not arise in the gate (rows N5, N6 stay as the rule if a builder ever puts the wire on the ground or a passer-by within reach). | gate scene |

### Lesson numbers (live text, X3) — what changes

| Lesson | Spec said | Live text (2026-11-16) | Where it lands |
|---|---|---|---|
| 8.1 myth 2 | 'WBERC-এর তৈরি সেফটি কোড এবং সাপ্লাই কোড মেনেই…' | "WBERC-এর 'সাপ্লাই কোড' আর CEA-এর সেফটি রেগুলেশন মেনেই আপনাকে রোজ কাজ করতে হয়।" | do_8_1_b lessonPoints[4], refuse card (DRAFT 'না — সাপ্লাই কোড আর CEA-র সেফটি রেগুলেশন মেনেই রোজ কাজ করি'); board 8.1 myth reality |
| 8.3 fuse off | village 24 h | town 3 h; village **6 h, 8 h in June–September** | do_8_3_a pins (docket shows the month), board 8.3 rounds[1] (the 22 h 'in time' card is now late) |
| 8.3 DTR | town & mofussil 24 h; village 48 h | **town 12 h**; village 48 h (no 'মফস্বল') | do_8_3_a map (two zones), board 8.3 rounds[2] |
| 8.3 breakdown | 12 h everywhere | **LT wire: town 4 h, village 10 h (16 h monsoon); 11 kV pole: town 12 h, village 24 h** | do_8_3_a, do_8_3_b emergency job, board 8.3 rounds[2], **gate H1 (town LT wire = 4 h)** |
| 8.3 voltage | loose contact 24 h; 'LV 6–9 %' | loose contact **15 days**, system 6 months; LT ±6 %, HT +6 % / −9 % | do_8_3_a (loose contact = long-limit decoy); dropped board round |
| 8.3 notice | 24–48 h before any maintenance shutdown | **only a shutdown over 6 h needs notice: at least 3 days** | do_8_3_b: jobs ≤ 6 h need the 06:00–17:00 window + miking; jobs of 7–9 h also need start ≥ 72 h after the notice; planner shows 5 days; refuse card (DRAFT) 'না, 6 ঘন্টার বেশি বন্ধ রাখলে অন্তত 3 দিন আগে নোটিশ দিতেই হবে'; board 8.3 rounds[4] trap → an 8 h job with 1 day's notice |
| 8.3 compensation | ₹50/h, ₹100/day | up to ₹500 per extra day | no rupees in levels; reason cards may quote the live line |
| 8.4 voltage | ±6 % to ±9 % | **+6 % / −9 %** (33 and 11 kV) | do_8_4_b: out above +6 % or below −9 %; deals high ≥ +7 %, low ≤ −10 %, normal −5 % … +5 %; board 8.4 rounds[3] reject texts |
| 8.5 road height | 11 kV 18–19 ft | **11 kV across a road 6.5 m (~21 ft)** (A2) | do_8_5_a reads metres (0.1 m): sound 6.8–7.5 m, low 4.0–5.6 m, never 5.7–6.7 m (an old 6.1 m span = 'below today's rule, report it'); reason card; board 8.5 rounds[2] |
| 8.6 compensation | ₹1 lakh (advanced) | 'GRO বা অম্বুডসম্যান কোম্পানিকে ক্ষতিপূরণ … দেওয়ার নির্দেশ দিতে পারেন' (no amount) | no amount on any card |
| 8.10 pro tip 1 | written permit **or** own earthing | 'লিখিত পারমিট হাতে না পাওয়া **এবং** নিজের হাতে আর্থিং না করা পর্যন্ত পোল-এ উঠবেন না।' | board 8.10 rounds[2], do_8_10_a (spec unsupported[0] obsolete), gate lessonPoints[0] and reason card |
| 8.10 myth 2 | 'সুরক্ষার প্রাথমিক দায়িত্ব তার' | "সুরক্ষার নিয়ম মানার দায় শুধু অফিসারের নয়—যে নিজের হাতে কাজটি করছে (আপনি), তারও। আপনি 'না' বলতে পারেন…" | board 8.10 rounds[2].traps[2], reason cards |

Quotes that still match: 8.2 (15 clear days, Sec 56, 180 days, Sec 135 evidence first and 24 h through the officer, Sec 126
provisional/final, wayleave, meter room), 8.4 frequency (49.90–50.05, 49.0), 8.5 PTW / LOTO / two-end earth / rod then
chain / LT side 1.2 m, 8.6 (1912, CCC, CGRF 45 days, Ombudsman 60–90 days), 8.7 (102 units, MVCA, TOD, PF, categories),
8.8 (100 % of sanctioned load, anti-islanding, sticker, banking), 8.9 (trim not fell, permission, oil, batteries, PCB,
offcuts).

## Cross-module rulings applied in Module 8

| # | Ruling | What it means in Module 8 | Overrides |
|---|---|---|---|
| X1 | **Before any hands-on work or climb: written PTW → isolate → prove dead with a proven tester (live-dead-live) → earth** (M5-2, A9, B8, Module 6/7 X1). | M8-17: scored in do_8_5_b and the gate, shown by the crew in do_8_8_a, do_8_9_a and do_8_10_a. Hand or climb before 0 V = deadly (N1); earth before 0 V = slip (N2); tester not proved = slip (N3); earth on a still-live line = deadly (B8, M8-7). After a proven isolation, missing PPE = slip (A5). | R16; N1–N3 |
| X2 | **Coworker rule B1:** listening = slip, unless the act he pushes is on that level's deadly list right then. | Deadly listening only in do_8_5_b myth 3 (chain as the earth), do_8_8_a (climb with solar fuses in), do_8_10_a variant A (climb on a phone 'line off') and gate M1. Every other push = slip. | R22 |
| X3 | **The live lesson text wins over spec quotes** (M6 X6, M7 X3). | The table 'Lesson numbers' above; every item's `notes.mismatches`. | per-item `notes.mismatches` |
| X4 | **WBSEDCL DTR = AB switch + HG fuses** (M6-2a, M7-9); AB = one firm, continuous stroke (A3). | M8-19. No AB stroke is scored in Module 8. | — |
| X5 | **Hook removal follows Module 7** (M7-2, M7-8, Module 7 sheet Q2). | M8-18 (do_8_2_b crew cut-scene; gate C1 climb checks). | N4 |
| X6 | **Module 6/7 build rules carry over.** | Boards: 5 rounds (M8-21), 4–6 picture cards per round, every hand holds a safe card, `youtubeId: null`. Every new Bangla line is DRAFT (M6-12). **Term rules:** «ডেড» never «মৃত»/«মরা» (8.8a guide 'লাইন সত্যিই মরা তো?' → DRAFT 'লাইন সত্যিই ডেড তো?'; gate card 'ফোনে লাইন অফ বললেই লাইন মরা।' → DRAFT 'ফোনে লাইন OFF বললেই লাইন ডেড।'); LT, HT, 11 kV, kVA in English letters (board 8.3 'এলটি জাম্পারিং' → 'LT জাম্পারিং'; 8.5a myth '১১ কেভি' shown as '11 kV'; 8.7 'কেভিএ' → 'kVA'); switch and line states ON / OFF (the complaint name 'ফিউজ অফ' and 'অফ-পিক' stay); «AB লাগানো» never «AB বন্ধ». English digits via `enDigits`. Locked words ডকেট · শাটডাউন · জল · গ্লাভস. য় ড় ঢ় as base + nukta; tests normalise the lesson's single code points. Spelling 'ঘন্টা' follows the live 8.x text (Module 7 used the 7.7 text's 'ঘণ্টা'; one spelling in a later lesson pass). Reason cards after a slip describe what THIS item had. No new hint kinds (M6-11). | board and level texts (wording only) |
| X7 | **Modules 1–7 consistency** still holds. | Full-body harness, never 'safety belt' (A7). Packing a pinholed, cracked or non-rubber glove = deadly (B6). M6-1: a broken earth path left in service = deadly. M5-4: inside a fallen wire's 10 m zone = deadly (N5). M7-3 / M5-5: letting another person touch a live conductor you could have stopped = deadly after a clear, timed chance; late but successful stop = slip (N6; no Module 8 level deals it now). Asking to charge with anyone on the line = deadly (M5-1). | — |

## Spec gaps and conflicts resolved here

| Gap / conflict | Resolution |
|---|---|
| Board art folders `sop_board/`, `grid_board/`, `safety_code_board/`, `griev_board/`, `net_meter_board/`, `env_board/`, `field810_board/` | Normalised to `m8_board81/` … `m8_board810/` (generator `tool/m8_board8N_art.py`, pack `learn_board_pack8N.dart`, lines class `M8Board8NLines`); item `board.artFolderInSpec` keeps the old name. |
| No tester anywhere in Module 8 | M8-17 + X1 (N1–N3). |
| Gate: earth rod before the permit = slip, while the line is still live | M8-7: deadly (B8). |
| 8.2b: hook removal as 'an abstract hold, never deadly' vs M7-2 / M7-8 | M8-18: crew cut-scene in the M7-8 order; the player scores the evidence order. |
| 8.8a 'ends at the climb; test and earth not repeated' vs X1 | M8-17: the climb coda shows the crew's tester and earths. |
| DTRs drawn as 'OFF' with no isolator named | M8-19: AB switch + HG fuses. |
| Spec quotes predate the live 8.x text (8.1 myth 2, 8.3 limits and notice, 8.4 voltage, 8.5 18–19 ft, 8.6 ₹1 lakh, 8.10 'or') | X3 + M8-12; each item's `notes.mismatches`. |
| 8.10 unsupported[0] 'permit OR earthing' | Obsolete: the live pro tip says AND. |
| do_8_2_b, do_8_6_a, do_8_5_a near-copies of do_7_5_b, do_7_9_b, do_7_3_a (design_flags_M5-10) | M8-20: short redesign before the wave. |
| Eight boards with 6 rounds | M8-21. |
| Gate snapped wire position not stated | M8-22: hanging clear, cordon up. |

## Need your call (sheet) — DRAFT answers applied

- **M8-L1 to M8-L14** (lesson text changes and term rules): the 'Text after' column is applied (the live text).
- **M8-D1 to M8-D36** (small level design choices): every 'Recommended' answer in the sheet is applied as written.
- Wording of every DRAFT line goes to the owner on a wording sheet after the build (M6-12 process).

## Open for the owner

1. All 22 questions of `docs/review/m8_questions_2026-11-16.xlsx` (14 need an answer; 8 are pre-filled from earlier
   rulings and change only if the owner disagrees).
2. The 'Need your call' rows (recommendations applied unless the owner writes otherwise).
3. A shorter gate badge name, if wanted (M8-16).
4. Natural Bangla wording of every DRAFT line (cards, guide, coworker). Recording comes after.
