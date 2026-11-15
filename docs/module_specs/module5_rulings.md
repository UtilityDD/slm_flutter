# Module 5 rulings (2026-11-12) — apply over `module5_items/*.json`

The owner asked to build Module 5 now. The 15 Module 5 design questions were answered from WBSEDCL Safety
Manual 2025, CEA Safety Regulations 2023, OSHA 1910.269 and international utility guidance (full quotes and
links: `docs/decisions/REFERENCE_REVIEW.md`, section M5). Where a ruling below differs from an item spec, **this
file wins**. Game-rule items use the designer's recommendation (owner can override later).

| # | Ruling | What builders do |
|---|---|---|
| M5-1 (R8) | Deadly: charging (or asking the operator to charge) while anyone is on/near the line or before the PTW is returned; asking for a charge after the test charge failed / the feeder was declared breakdown ("burning" a fault); DO re-fit after an instant blast with arc; re-charging a DTR after an HT blow with all LT open. An unspecified re-blow stays a slip. | 5.1 board trap `charge_once` → 'ব্রেকার না টেকার পরও আবার চার্জ করতে বলা'; reject text: 'একবার টেস্ট চার্জ সাবস্টেশন ইন-চার্জের সিদ্ধান্ত; ব্রেকার না টিকলে লাইন ব্রেকডাউন — ফল্ট না পেয়ে আর চার্জ নয়'. Apply the deadly grades in 5.1a, 5.4a/b, 5.8b, gate. |
| M5-2 (R2/R3) | Hands, tool or climb before the tester shows 0 V = **deadly** (do_5_8_a, do_5_8_b raised from slip). Earth before test stays a **slip**, but its card says 'আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ — এই ক্রম বাধ্যতামূলক'. | |
| M5-3 (R7/R6) | Ground-only patrol of an in-service line needs no PTW; any climb/touch = deadly. Patrolling a tripped feeder without informing control stays a **slip** as a procedure point — but never present a PTW as a legal must for ground patrol. | do_5_2_a / do_5_7_a chip and reject card: 'টহলের আগে কন্ট্রোল রুমকে জানিয়ে ফিল্ড মেমো/ডকেট নিন; লাইনে হাত দেওয়া বা ওঠার আগে PTW বাধ্যতামূলক'. |
| M5-4 (R13/R15/R16) | Fallen wire: entering within 10 m = deadly; leaving with a long stride = deadly; cordon under 10 m = slip. | Text: 'তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে ১০ মিটার'; exit 'দুই পা একসাথে রেখে ছোট ছোট পদক্ষেপে'. |
| M5-5 (R17/R18) | Bystander contact = deadly for the player; late but successful stop = slip. | Consequence card: 'জনসাধারণকে সতর্ক করা ও দূরে রাখা লাইনম্যানের দায়িত্ব'. |
| M5-6 (R32) | Listening to the water-in-oil myth = slip (equipment harm, nobody exposed). | Keep card 'জল তেলের সবচেয়ে বড় শত্রু — ডাই-ইলেকট্রিক স্ট্রেন্থ নাটকীয়ভাবে কমায়।' |
| M5-7 (R33) | Digging/pegging before calling underground-service owners = slip. | Card/chip: 'খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান'; chip name "calling underground-service owners" (not "local authority"). |
| M5-8 (R9) | First DO re-fit on a fresh blow is allowed **after one visual check** of DTR, DO and span; re-fit with no check = slip. | do_5_4_b: add one cheap check step before re-fit; re-fit art shows gloves, operating rod, trainee standing to the side (not under the barrel), correct fuse rating. |
| M5-9 | Verb cuts for distinctness approved as designed. | — |
| M5-10 | Evidence-gated verdicts (right answer without its readings = slip) approved. | — |
| M5-11 | Boards trimmed to 5 rounds approved. | — |
| M5-12 | Gate: rank অ্যাডভান্সড, engineType `m5_gate_case`, badge 'ফল্ট ফাইন্ডার', 5–7 min; case F (ground patrol of in-service line) stays. Use the unlock rank the gate spec gives; rank numbering across M1–M4 gates is an open owner item (F5) — don't change other modules. | |
| M5-13 | On-screen text uses clean Bangla; do **not** edit `tool/all_training_chapters_bn.json`. | |
| M5-14 | Coworker/rival lines: recorded voice later via `tool/rival_clip.py` by the director (list them under `rival_lines_missing`); guide, operator, neighbour, villager lines on device TTS. No YouTube ids for 5.x boards yet. | |
| M5-15 | (b) 5.10a hotspot judged against the same joint on the other two phases under similar load; > 15 °C hotter = repair now; dealt hotspots must differ by > 15 °C (or show the band). Card: 'তুলনা করুন একই লোডে থাকা অন্য দুই ফেজের একই জোড়ের সাথে; >১৫°C বেশি হলে এখনই মেরামত'. (a) 5.3b keep "cut out the damaged section"; show annealing as visible discolouration/softness rather than a precise bend-test claim. (c) 5.5a (relabelled from 5.5b at wiring, 2026-11-12; board 5.5 uses it too): text says 'এলটিডিবি-র ইনকামিং (বুশিং-এর সরাসরি কেবিল)'. | |

Cross-module consistency (from the Modules 1–4 review, apply in Module 5 too): 11 kV / 33 kV road clearance
**6.5 m** across a street (CEA 2023 Reg 60); burns are cooled with clean running water ~20 min after the supply is
off, no ice; full-body harness (never "safety belt"); a cracked hot stick is deadly; declaring a live line dead is
deadly; bare-hand leads on live terminals are deadly.

## Owner rulings of 2026-11-15 applied in Module 5

From `docs/decisions/OWNER_DECISIONS_M1-4.md`, "Rulings made 2026-11-15" (national reference over WBSEDCL when they
conflict). Where they meet a row above, the 2026-11-15 ruling wins.

| Ruling | What it means in Module 5 | Where |
|---|---|---|
| B1 | Listening, or a verdict card that orders an act, takes that act's class (R29 already said so). | 5.8a: 'চালু রেখেই নাট টাইট' = live spanner, 'চালু রেখেই ওপরে উঠে' = climb live; the two 'আবার চার্জ' decoys are plain slips |
| B3 | Opening a DO on load = deadly (it was a builder slip in 5.8a); under the DO and no গ্লাভস for the DO = slips. | 5.8a; 5.4a never reopens a DO on load: the crew opens all three DOs first, then each LT way goes in with the DTR's LT switch OFF |
| B4 | Bare-hand meter leads on live terminals = deadly; on dead terminals, or a bare tong, = slip. | 5.8a (rubber gloves button in every row) |
| B8 | Earth set on a live line = deadly. | 5.8a |
| A5 | A fuse touched, pulled or pushed with the supply on = deadly; LT fuses and LT joints are worked only on a dead LT line (WBSEDCL Safety Manual 2025 3.2, Ch IV duty 8). | 5.4a (`live-carrier`); 5.5b and board 5.5 (pole-end joint: the LT line shut at the DTR / pillar way, lock and tag; a house cut-out does not make it dead); board 5.4 |
| R1/R4 (as 5.10a) | 5.8a dead-phase work: PTW → LT off → DOs open → tester 0 V on all three → LT earth set → spanner. No PTW or no earth = deadly; tester or earth before the PTW, and the earth before every 0 V, = slips. | 5.8a; board 5.8 (the earth before the bushing) |
| M5-1 → M4 | Reclosing a DO that blew again the moment it was fitted is deadly in M4 `do_4_4_b` too (it was a slip there). | M4 `do_4_4_b` |
| M5-3 (refined) | In 5.1b, a van drag before the lock-out is reported = the patrol-early slip; after the report it is ignored (ground patrol needs no PTW; climbing or touching before the PTW stays deadly, R1). | 5.1b |
| Earths both sides | WBSEDCL Safety Manual 2025 5.14(d): earths on both sides of the working zone; the crew's set is drawn on at the far pole once 0 V shows. | 5.1b |
| M5-7 (reference) | The cable route record first, then the owners of the other underground lines (India's DoT 'Call Before u Dig'). | 5.9b |
| M5-8 (with M4) | The other two phases' DOs are open before every re-fit (lesson 4.4 pro tip 2), drawn opened by the crew. | 5.4b |
| Discharge | The gate's UG step isolates both ends and discharges before the megger ('দুই প্রান্ত আইসোলেট করে ডিসচার্জ'). | gate |

New or changed Bangla card text from these fixes is DRAFT until the owner gives the natural wording (voice rule
2026-11-14); spoken lines need Subrata clips.
