# Module 7 rulings (2026-11-16) — apply over `module7_items/*.json`

The owner answered the 13 Module 7 questions on 2026-11-16 ("proceed with the recommendations";
`docs/decisions/OWNER_DECISIONS_M5-10.md`, section "Module 7 owner answers (2026-11-16)"; sheet
`docs/review/m7_questions_2026-11-16.xlsx`). Those answers are final and binding. The cross-module rulings of Modules 1–6
(M1-4 rulings A1–A9 and B1–B8, the Module 5 rulings, the Module 6 rulings M6-1 to M6-14 and X1–X7) also apply. Reference
research for each question is in `docs/decisions/REFERENCE_REVIEW.md`, section M7. Where a ruling below differs from an
item spec, **this file wins over an item spec**. The last column of each table names the spec rows (R-numbers, as in every
item's `deadlySlipTable`), spec fields or items that the ruling overrides.

**Content source:** lesson text comes from `tool/all_training_chapters_bn.json` only. That file already holds the corrected
live text for 7.x (lesson fixes of 2026-11-15). When a spec quote and the live text differ, the live text wins (X3). Every
item lists its differences under `notes.mismatches`. Do **not** edit the lesson file. Never use a Bangladesh source.

Row ids: R1–R30 follow `module7_spec.json` `deadlySlipTable` in order. The rulings below add rows N1–N4. Every item's
`deadlySlipTable` already carries `classAfterRulings`, `ruling` and `rulingNote` on each row (rows that were `needsOwner`
keep `needsOwnerInSpec: true`), and its new rows are under `addedRows`. Every DO fuse in the item copies has already been
redrawn as an AB switch (+ HG fuses) (M7-9).

## Owner answers (decisions 1–13)

| # | Ruling | What builders do | Overrides |
|---|---|---|---|
| M7-1 (dec 1) | **The four redesigns are approved:** do_7_1_b (question an order with the rulebook), do_7_2_a (tear-off calendar), do_7_6_b (route each PPE mishap; one hold to record), do_7_8_b (depot handover to arriving vehicles). | Build them as specified. Rulebook pages in do_7_1_b use the live CEA 2023 numbers (X3). | — (approves the spec) |
| M7-2 (dec 2) | **Module deadly list approved as written; everything else is a slip.** Deadly: an unsigned FIELD copy of the PTW, or a verbal 'line off' with no paper; signing for, packing or using torn gloves or gloves not rated for the 11 kV job, going to an 11 kV job without rated gloves, and touching a hook with no গ্লাভস on; a harness with cut or frayed webbing; removing a hook from a live line; an uncertified man on energised live-line work; PTW return and line charge with a man still up (F12); a public rod or bamboo reaching the line (7.3b); letting the coworker coil a wire not proven dead (7.7a S2); entering a fallen wire's zone. Every needsOwner row on the list is confirmed. | Clear every 'owner to confirm' note on these rows. **No গ্লাভস on the hook: DEADLY only while the line is not yet proven dead (before tester 0 V + earth); after the proven isolation it is a SLIP** (owner 2026-11-16, sheet Q2 recommendation (a); same as Modules 3–6, A5/X4). Hook pulled after 0 V but with no earth = DEADLY (live lesson 7.5 pro tip 4 + X1). Signing a not-understood condition, different PTW numbers, control-room copy unsigned = slips (R3). Confronting the thief, false report, wrong evidence = slips. | needsOwner cleared on R1, R3, R4, R10, R12, R13, R14, R15, R22, R25, R26, R30; do_7_5_b deadly[2] confirmed |
| M7-3 (dec 3) | **Letting another person touch a conductor you could have stopped = DEADLY** (7.3b public rod or bamboo; 7.7a S2 coworker coiling an unproven wire). Same principle as M6-1 (signing a broken earth because coworker B said so = deadly) and M5-5 (bystander contact = deadly for the player). | Fire the freeze only after a clear, timed chance to warn or block (M5-5). A late but successful stop = slip. | R17, R18 (needsOwner cleared) |
| M7-4 (dec 4) | **Past acts judged at an inquiry desk (do_7_4_b) are always slips**; the same act done in the field keeps its own class (gate F12 = deadly). | The do_7_4_b reason card (DRAFT) adds that in the field the same act is deadly, so the slip never reads as minor. | R5 |
| M7-5 (dec 5) | **Reg 3 split:** non-live (shutdown) line work by an unfit, untrained or unauthorized person = slip everywhere; energised live-line work without the live-line certificate = deadly (do_7_10_a only). | Slip cards (DRAFT) word it as a legal breach (CEA Reg 3: only a designated, certified man may do line work), never as allowed. The under-18 profiles are replaced (X3). | R7, R8, R9 |
| M7-6 (dec 6) | **No deadly in lessons 7.1, 7.2, 7.8, 7.9 and in do_7_3_a, do_7_4_b, do_7_5_a, do_7_7_b.** | Those levels have slips only. In 7.1 a cut earth lead seen at the register is a slip (nothing is being charged; M6-1 applies only to signing off or charging). | — (confirms the spec) |
| M7-7 (dec 7) | **HT side-of-house clearance is dealt on 33 kV only (2.0 m).** The lesson's 11 kV side figure is corrected to 1.2 m (CEA 2023 Reg 63(3)) — a lesson fix for the director. | do_7_3_a and board 7.3: side sites are 415 V (1.2 m) or 33 kV (2.0 m) only; every 2.0 m text names **33 kV** (rounds[2].traps[0].rejectBn 'HT লাইনের জন্য…' → '33 kV লাইনের জন্য…'). Road and roof numbers per X5. **Lesson fix status:** the live 7.3 text already reads 'HT লাইন (১১ কেভি পর্যন্ত): ১.২ মিটার' and '(১১ কেভির বেশি, ৩৩ কেভি পর্যন্ত): ২.০ মিটার' (applied 2026-11-15, checked 2026-11-16), so nothing is left to edit. | R21, board_73 rounds[2], do_7_3_a dealtVariety |
| M7-8 (dec 8) | **do_7_5_b phase 2 adds the tester live-dead-live proof after the shutdown** (Module 2.2 rule; live 7.5 pro tip 4 now also says earth: 'টেস্টার দিয়ে ডেড প্রমাণ করা, আর্থ লাগানো এবং সম্পূর্ণ PPE'). | Phase 2 items: officer's order → phone শাটডাউন (OFF tag) → **tester: live point, the hook's line (0 V), live point again** → **earth on the span** → PPE incl. গ্লাভস → hook off. Hand or tool on the hook before the 0 V = deadly (N1, M5-2). Hook off after the 0 V with no earth = deadly (N2, X1). Earth before the 0 V = slip (N3). Tester not proved on a live point = slip (N4, A9). Board 7.5 rounds[5] safe cards and reject texts add the tester and the earth. The same order is drawn in gate F7 (M7-9). | R13 (widened), R14; do_7_5_b flow[5]–[6], lessonPoints[3]; board_75 rounds[5]; unsupported[2] (obsolete) |
| M7-9 (dec 9) | **Gate F7 cue approved, but no DO anywhere in Module 7.** The lane DTR's isolation is its **AB switch (+ HG fuses)**, per M6-2. | Already applied in the items: gate scene, flow[2], flow[9], deadly[3], giveawayRisks; board 7.5 rounds[1].safe[1] and rounds[2].safe[0] (an overloaded DTR shows a **blown HG fuse wire**); do_7_8_a background DTR (AB open, blades seen, handle locked and tagged). The job DTR's AB is opened in one firm stroke, all three blades seen, handle locked and tagged; the other DTR's AB is closed (live). F7 lawful version also shows the tester 0 V and the earth on the job span (M7-8). Hook on the other DTR's live line = deadly. Term rule: closing = «AB লাগানো», never «AB বন্ধ». | gate scene / flow[2] / flow[9] / deadly[3] / giveawayRisks; board_75 rounds[1]–[2]; do_7_8_a scene; spec change 4 (DO wording) |
| M7-10 (dec 10) | **Coworker clips:** every myth line used verbatim (7.1 ×2, 7.2 ×2, 7.3 ×2, 7.4 ×2, 7.5 ×2, 7.6 ×2, 7.7 ×2, 7.8 ×2, 7.9 ×2, 7.10 myth 2) plus the shortcut lines (7.2b bills, 7.3b roof variant, 7.4a ×2, 7.5b hook, 7.7a S2/S3, 7.8a hose, 7.8b municipal truck, 7.9a ID) are recorded in the voice system after the owner words them. | DRAFT rule M6-12: each level keeps `newRivalLines` / `newGuideLines` in its Lines class (with a pinning test) and marks drafts `// DRAFT wording — owner`. Every spoken line (incl. 'why' questions, guide, radio, JE lines) is listed. Myth lines word for word need clips too. Until recorded, the existing on-device fallback plays. | coworkerPushBn texts in all items (wording only) |
| M7-11 (dec 11) | **Lesson glitches are fixed** (director's list below). | Nothing for builders: on-screen text is clean Bangla from the live file. | spec change 11; 7.4 unsupported[1], 7.6 unsupported[7] |
| M7-12 (dec 12) | **No new curved-path hint.** do_7_8_a uses the existing drag-hint fallback (as M6-11). | Boom ring: the existing drag hint along a short arc segment from the ring's start; no new HintSpec kind. | do_7_8_a gestureHints; spec ownerDecision 12 |
| M7-13 (dec 13) | **Gate: rank সুপারভাইজার** (catalog `modules` m7 `rankName`, unlockRank(7)), **badge 'আইন কি বলে?'** (the 7.x lessons' badge_name), quickMs after playtest. | One constant `M7GateLines.badge = 'আইন কি বলে?'` marked `// OWNER may rename`. Length 5–7 minutes (M5-12/M6-10). quickMs: builder's estimate (~85 % of a clean play) until playtest; state it in the report. At wiring the director changes the catalog's gate_m7 engineType from `gate_field` to `m7_gate_permit_day`. | gate pass panel; every level's quickMs |

### M7-11 — exact lesson fixes for the director (lessons 7.4, 7.5, 7.6, plus 7.8–7.10)

All were applied to the live lesson text on 2026-11-15 (sheet `docs/review/lessons_m5-10_and_m6_questions_v2.xlsx`,
'Lesson fixes applied'). Checked 2026-11-16: no Cyrillic, Tamil, Persian, Devanagari or mixed-Latin fragment is left in
7.1–7.10 of `tool/all_training_chapters_bn.json`. If the Supabase copy is restored from an older backup, re-apply:

| Lesson | Before | After |
|---|---|---|
| 7.4 briefing | 'முறையான' | 'যথাযথ' |
| 7.4 advanced | 'работодаাতা' | 'নিয়োগকর্তা' |
| 7.5 | 'असुरक्षित' | 'অসুরক্ষিত' |
| 7.5 section 3 | 'এনফোর্cement' | 'এনফোর্সমেন্ট' |
| 7.6 pro tip 4 | 'بخواهید' | 'প্রশিক্ষণ চান:' |
| 7.6 section 1 heading | 'работодаাতার' | '১. নিয়োগকর্তার আইনি দায়িত্ব' |
| 7.6 briefing | 'работодаাতা' | 'আইন আপনার নিয়োগকর্তা বা কোম্পানিকে' |
| 7.6 section 3 | 'बिना सर्टिफिकेशन' | 'সার্টিফিকেশন ছাড়া PPE' |
| 7.8 pro tip 4 | 'بایو…' | 'বায়োডিগ্রেডেবল' |
| 7.9 | 'संवाद' | 'সঠিকভাবে কথা বলতে' |
| 7.10 | 'विश्वसनीयता' / 'नवीकरण' | 'বিশ্বাসযোগ্যতা' / 'নবীকরণ' |

## Cross-module rulings applied in Module 7

| # | Ruling | What it means in Module 7 | Overrides |
|---|---|---|---|
| X1 | **Before any hands-on work: PTW → isolate → prove dead with a proven tester (live-dead-live) → earth** (M6 X1, M5-2, B8, A9). | do_7_5_b and gate F7 (M7-8). The gate's permit forks keep the PTW as the first step (M1 step 17 / B7: work without a read, signed PTW = deadly). | R13, N1–N4 |
| X2 | **Coworker rule B1:** listening = slip, unless the act he pushes is on that level's deadly list right then; then listening is that deadly. | Deadly listening only in do_7_5_b push (ii) 'হুকটা টেনে খুলে দাও' (live hook), do_7_10_a (uncertified man onto live-line work), do_7_7_a S2 (coiling an unproven wire). Every gate variant on a slip-class fork stays a slip. Myth-2 listening in 7.7a (small shock) = slip. | R30 |
| X3 | **The live lesson text wins over spec quotes** (M6 X6). Today's differences that change the specs: | **7.1:** danger notice = রেগুলেশন ২০ (not 15), earthing = ৪৩ ও ৫০ (not 18), clearance = ৬০–৬৩ ও ৭১ (not 32); Reg 3 unchanged (tabs, pages, prompts, reject texts, lessonPoints). **7.3:** road 6.5 m for 11 and 33 kV (not 6.1), LT up to 650 V; myth-1 reality re-quoted. **7.4:** PTW for any shutdown work, HT or LT (board LT trap uses the live safety tip; do_7_4_b lessonPoints[0]); no 18 kV threshold. **7.5:** tester + earth before the hook (M7-8). **7.6:** the 11 kV glove is 'IS 4770 টাইপ ৪' (১৭,০০০ ভোল্ট পর্যন্ত): cuff and kit labels show 'IS 4770 · টাইপ ৪' (English digits), an unrated glove is a lower type (e.g. 'টাইপ ২') or unmarked; never print '11 kV গ্লাভস'. **7.7:** any injury, or an accident that could have hurt someone, is reportable (Electricity Act s.161); drop the '24 ঘণ্টা off work' card; spelling 'ঘণ্টা'. **7.8:** batteries → 'Battery Waste Management Rules, 2022'; circuit boards → 'E-Waste (Management) Rules, 2022'. **7.10:** no age rule: competent = certificate of competency or electrical work permit + name on the company register + training; the under-18 helper, the birth-year rule and every 'under 18' card (7.10a, 7.1b, gate F2, board 7.10 rounds[0]) become 'no certificate', 'not on the register', 'training ongoing' or 'authorization blank'. | R8, R10, R21, R28; per-item `notes.mismatches` |
| X4 | **WBSEDCL DTR = AB switch + HG fuses** (M6-2a); **AB = one firm, continuous stroke; a stalled stroke = slip** (A3). | Every DTR drawn in Module 7 (M7-9). No AB stroke is scored in Module 7 (the crew's isolation is staging). | — |
| X5 | **Clearance numbers and wording** (A2, CEA 2023 Reg 60–63). | Road: LT 5.8 m, 11 kV 6.5 m, 33 kV 6.5 m across a road (tags, drum, reason question 'কেন এখানে 6.5 মিটার লাগবে?'). Roof: LT 2.5 m, HT 3.7 m. Side: LT 1.2 m, 33 kV 2.0 m (M7-7). Drum: **1.2 · 2.0 · 2.5 · 3.7 · 5.8 · 6.5**. An old span at 6.1 m may be lawfully existing: the verdict and reject texts say 'today's rule is 6.5 m — report it', not 'illegal'. | R21; board_73 rounds[0]; do_7_3_a flow[4], reasonQuestionsBn[1], lessonPoints[0]–[2] |
| X6 | **Module 6 Wave B build rules carry over.** | Boards: **5 rounds** (M5-11) — boards 7.2, 7.4, 7.5, 7.7, 7.9 are trimmed from 6 (7.4 drops round 6, 'which is true' consequences); 4–6 picture cards per round; every hand holds a safe card; `youtubeId: null` (M6-14). Every new Bangla line is DRAFT (M6-12). Term rules: «ডেড» never «মৃত» («টেস্টারে ডেড প্রমাণ»); LT, HT, 11 kV in English letters; ON / OFF; «AB লাগানো» never «AB বন্ধ». English digits via `enDigits`. য় ড় ঢ় as base + nukta; tests normalise the lesson's single code points. Reason cards after a slip describe what THIS item had. Quick bonus = builder's estimate. | board_72/74/75/77/79 rounds |
| X7 | **Modules 1–6 consistency** still holds. | Burns: clean running water 10–20 min after the supply is off, no ice, no ointment (A1). Full-body harness, never 'safety belt' (A7). Packing a pinholed, cracked or non-rubber glove = deadly; a wet pair = slip (B6). Fallen wire: entering 10 m = deadly, long-stride exit = deadly (M5-4). Bystander contact = deadly after a fair chance (M5-5). Asking to charge with anyone on the line = deadly (M5-1, gate F12). | — |

## Spec gaps and conflicts resolved here

| Gap / conflict | Resolution |
|---|---|
| Board art folders named `law71_board/`, `comp_board/`, `clr73_board/`, `theft_board/`, `ppe_law_board/`, `accrep_board/`, `consumer_board/`, `cert_board/` | Normalised to `m7_board71/` … `m7_board710/` (generator `tool/m7_board7N_art.py`, pack `learn_board_pack7N.dart`); item `board.artFolderInSpec` keeps the old name. |
| Gate and 7.5/7.8 art drew DO fuses | M7-9: AB switch + HG fuses (already rewritten in the items). |
| do_7_5_b had no tester or earth; the live lesson now requires both | M7-8 + X1 (N1–N4). |
| 'No গ্লাভস on the hook = deadly' vs A5 (no PPE after a proven isolation = slip) | M7-2 as written wins in Module 7. |
| Spec 'HT 2.0 m beside a house' applied to 11 kV | M7-7: side sites on 33 kV only. |
| Spec quotes predate the 2026-11-15 lesson fixes (regulation numbers, 6.1 m, '11 kV rated gloves', 18 years, 24 hours, HT-only PTW, battery rule) | X3: the live text wins; each item lists its lines under `notes.mismatches`. |
| 7.10 age rule removed from the live lesson | X3: the lesson's own competence checks replace it (open item O2 if the owner has a national source). |

## Owner answers to the open items (2026-11-16)

The owner said "proceed with the recommendations" for the whole Module 7 sheet (docs/review/m7_questions_2026-11-16.xlsx). Binding:
- **O1 field memo:** levels play the **PTW only** (11 kV shutdown jobs); the field memo appears only in the lesson's own words on board 7.4.
- **O2 age 18:** dropped; the lesson's competence checks (certificate / work permit, name on the company register, training) replace it.
- **O3 glove label:** 'IS 4770 · টাইপ ৪' on screen; a lower type for an 11 kV job = wrong glove.
- **Boards:** 5 rounds (7.2, 7.4, 7.5, 7.7, 7.9 trimmed).
- **XL7.1-T1:** the new title 'ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল' is used on the 7.1 board and levels.
- **L7.2-2:** levels say 'আইন' and never name the repealed act; the note is a lesson matter for the director.
- **L7.3-3:** the new myth-1 answer is confirmed as written in the sheet; 7.3b quotes it.
- **M7-L1 to L4:** follow the live lesson (CEA 2023 regulation numbers; PTW for HT and LT shutdown work; any injury or near-injury reportable; battery = Battery Waste Management Rules 2022, circuit board = E-Waste Rules).
- **M7-D1 to D29:** every recommendation in the sheet's 'Need your call' rows is approved as written.
- Wording of every DRAFT line still goes to the owner on a wording sheet after the build (M6-12 process).

## Open for the owner (superseded: answered above)

1. **O1 — Field memo:** live 7.4 accepts 'PTW, or a field memo where company rules use it' for shutdown work. Interim:
   the levels play **PTW only** (11 kV shutdown jobs); the field memo appears only in the lesson's words on board 7.4.
   (Also open: lesson item L7.4-3, keep the field-memo words?)
2. **O2 — Age 18:** applied X3 (no age rule). If the owner has a national source for an 18+ bar on line work, the
   under-18 helper can come back with that source.
3. **O3 — Glove label:** applied X3 ('IS 4770 · টাইপ ৪'). Confirm the on-screen label, or give the field word.
4. Lesson items still open from the 2026-11-15 sheet: XL7.1-T1 (7.1 chapter title), L7.2-2 (Code on Social Security
   note), L7.3-3 (myth-1 wording). None blocks the build.
5. The lesson-level design choices in the sheet's 'Need your call' rows (recommendations applied unless the owner says
   otherwise), and the natural Bangla wording of every DRAFT line (cards, guide, coworker). Recording comes after.
