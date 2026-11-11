# MODULE4_LADDER.md — Module 4 (স্কিলড) master list

Built 2026-11-11 by 30 parallel agents on `feature/module4` (one git worktree per level), merged and wired by the director.
Same frame as [MODULE1_LADDER.md](MODULE1_LADDER.md), [MODULE2_LADDER.md](MODULE2_LADDER.md) and the playbook. Rank at the gate: **স্কিলড** · badge: **কাজের কারিগর** · 30 rungs (10 Learn, 19 Do, 1 gate).
Status: built on the shared kit, tests green. Every row's open content questions are in **Owner decisions** below.

## Master table

| Step | Rung | Name | Moves | Deadly (💀) | Status |
|---:|---|---|---|---|---|
| 1 | 4.1/learn | পিন বা ডিস্ক ইনসুলেটর বদলানো (picture board) | 5 picture rounds (prep · hold · fit · bypass · disc) + myth | — | playable (tests green) |
| 2 | 4.1 কাজ 1 | বদলের আগে (`do_4_1_a`, `m4_insulator_prep`) | spot (the faulty insulator: crack or burn/puncture) · choose (the right kind of new insulator + its fittings from the van's shelf) · inspect (a cracked spare of each kind on the shelf) · order (PTW → tester → earth both sides → helmet + harness → climb) · say no (coworker: "এক দিকে আর্থ দিলেই হবে") | 💀 climbing with no PTW / shutdown · 💀 climbing without earth on both sides (also by listening to him) | built, tests green |
| 3 | 4.1/do/1 | পোলের ওপর বদল | spot (the faulty insulator) · order (lesson steps with tools) · inspect + choose (a tray of 3 spares: cracked / punctured / sound; rusted pin) · say no (coworker) | pliers on a tension string still under load (no load bypass) | built, tests green (20) |
| 4 | `4.2/learn` | জাম্পার কানেকশন ও টাইট করা (picture board) | 5 picture rounds (bridge · connector · fit · shape · patrol) + myth | — | built, tests green |
| 5 | `4.2/do/0` (`do_4_2_a`) | জাম্পার বানাও | choose + inspect (jumper piece: cut end beside the line's, same size or bigger) · order (brush → paste → connector → two spanners, at both joints) · choose (connector by metal: PG·Al, or বাই-মেটালিক on the copper span) · spot (the smooth U among three bends) · inspect (trim the stray strand) · say no (coworker: "ব্রাশ-ট্রাশ লাগবে না, সোজা লাগিয়ে দাও!") | none — all slips (the line is dead and earthed) | built, tests green (15) |
| 6 | `4.2/do/2` · `do_4_2_b` | ঢিলে জাম্পার ধরো | spot (the bad PG clamp: red glow / sparking at night, a melted clamp by day) · order (শাটডাউন/PTW → টেস্টার → আর্থ → ব্রাশ-পেস্ট → [নতুন ক্ল্যাম্প] → দুই রেঞ্চে সঠিক টর্ক → আর্থ খোলা → PTW ফেরত → আবার দেখা) · inspect (melted → replace, loose → clean + tighten; the torque band) · say no (coworker: "চালু অবস্থায় প্লাস দিয়ে একটু টাইট দাও!") | any tool on a live jumper; listening to him | built, tests green |
| 7 | `4.3/learn` | নতুন সার্ভিস কানেকশন — ছবির বোর্ড | 5 picture rounds (plan · anchor · ipc · meter · test) + why chips + the rival's myth (no bearer wire) | — | built, tests green |
| 8 | `4.3/do/0` | কানেকশনের প্রস্তুতি | inspect (papers) · choose (route on the survey sketch) · choose (material shelf) · order (work card) · say no (coworker on papers / route / GI wire) | — (planning; all slips) | built, tests green |
| 9 | 4.3/do/1 (do_4_3_b) | সংযোগ দাও (m4_service_connect) | order (strap → drip loop → meter L/N → pole: harness → shutdown → tester → earth → IPC sheared → earth off → PTW back → fuse → multimeter → offcuts → hand over) · choose (IPC vs pliers; read the multimeter: 230-240 V vs 0 V) · spot (the L/N marks on the meter, the cores and the LT conductors, which are dealt; the offcuts) · say no (coworker: "ফেজ-নিউট্রাল যেকোনোটা যেকোনো দিকে") | IPC/pliers or the earth set on the LT line without the shutdown | built, 17/17 tests green, analyze clean |
| 10 | 4.4/learn | ডিও (DO) ফিউজ পরিচালনা করা — picture board | 5 picture rounds (prep · link · open · close · field) + why chips + rival myth (gloves without hot stick) | — | built, tests green |
| 11 | 4.4/do/0 | ডিও খোলো নিয়মে (`m4_do_open`, `do_4_4_a`) | choose (operating rod from the van rack: not cracked or short; head = puller / load-break tool) · inspect (গ্লাভস + face shield before the rod goes up) · spot (dry ground to the side, not under the DO set, not in the puddle) · order (hook → face aside → one quick pull, each fuse; all three open before "done") · say no (coworker: "লোড থাকলেও টেনে দাও" on the heavy job / "বাকি দুটো খোলার দরকার নেই" on the fault job) | 💀 heavy-load fuse pulled without the load-break tool (arc not quenched) | built, tests green |
| 12 | `do_4_4_b` | ফিউজ উড়েছে — কেন? | spot (the dropped barrel) · choose (what first; the docket's link from a tray with thick wire; spark vs re-blow) · order (clean → button → wind tail + nut → port → ready) · stance + face aside + one push · say no (coworker: "মোটা তার দিয়ে বেঁধে দাও" / "যতবার উড়বে ততবার লাগাও") | 💀 thick wire in place of the fuse link (from the tray or on his say-so) | built, tests green |
| 13 | 4.5/learn | ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা (picture board) | 5 picture rounds (level · check · heat · leak · topup) + myth (engine oil) | — | built, 13/13 tests green |
| 14 | 4.5 কাজ 1 (`do_4_5_a`) | তেলের মাপ | read (conservator gauge MIN · 30°C · MAX against the dealt weather: summer noon / winter dawn / mild day) · spot (leak at the bushing gasket, weld, drain cock or fin) · choose (ঠিক আছে / রিপোর্ট; the right drum: new filtered transformer oil vs engine / used / rain-wet oil) · order (শাটডাউন → টেস্টার → আর্থ → উঠুন, then hold to pour up to the mark) · say no (coworker: "চালু অবস্থায় একটু তেল ঢেলে দাও!") | 💀 climbing the live transformer (also by listening to him); 💀 the earth put on before the shutdown | built, tests green |
| 15 | 4.5 কাজ 2 (`do_4_5_b`) | গরম কতটা? | choose (ইনফ্রারেড থার্মোমিটার vs হাতে ছুঁয়ে) · read (thermometer heat bar + shimmer → স্বাভাবিক / অতিরিক্ত গরম) · spot (tap oil gauge / fins / LT cables with clamp meter + nameplate to find the cause) · choose (the action deck + reason) · say no (coworker: "হাত দিয়ে ছুঁয়ে দেখো কত গরম") | a hand on the live DTR's tank (own pick or on the coworker's word) | built, tests green |
| 16 | 4.6/learn | আর্থিং: দেখা, মাপা, যত্ন (শেখা) | 5 picture rounds (patrol · measure · tx · care · soil) + myth | — | built, 13/13 tests green |
| 17 | 4.6 কাজ 1 | মাটির পরীক্ষা | spot (visual check of a DTR's double earthing, pits N-1 N-2 B-1 B-2: tag 1–2 dealt faults — strip cut/stolen, rusty loose joint, pit cover off; "দেখা শেষ" with one missed = slip) · order (for one neutral pit and one body pit: drive two temporary spikes → connect the tester's leads → TEST; leads before both spikes / TEST before the circuit = slip) · read (the earth tester counts up to the ohms; mark "মান ঠিক" / "মান বেশি" against the lesson's value for a distribution line, < 5–8 Ω; one good ≤ 4.2 Ω and one high ≥ 12 Ω a play; a wrong mark = slip) · say no (coworker, one of two dealt: "চোখে তো সবই দেখলে! মেগার-টেগার লাগবে না, চলো।" before the first test, or "লাইন তো দিব্যি চলছে! খাতায় মান ঠিক লিখে দাও…" on the high reading — listening = slip) | none | built, tests green (14; flows cover both coworker pushes) |
| 18 | 4.6/do/1 | আর্থ মেরামত (`m4_earth_fix`, `do_4_6_b`) | inspect (joint · strip · pit) · choose (the fix) · order (the fix's steps) · measure again (earth tester) · say no (coworker: "তার কেটে গেছে? ঝুলিয়ে রাখো, কেউ দেখবে না") | 💀 signing off with the earth strip still cut (also by listening to him) | built, 16/16 tests green |
| 19 | 4.7/learn | ডিপি (DP) স্ট্রাকচার ড্রেসিং (picture board) | 5 picture rounds (jumper · align · cable · gap · finish) + myth | — | playable (tests green) |
| 20 | `4.7/do/0` | এলোমেলো স্ট্রাকচার — survey 3 DP transformer structures from the ground and write the dressing list: tap what is untidy (binding wire's long tail · tangled jumper · tilted DO cross-arm · low clearance phase-phase / phase-pole · LT cables hanging loose · two LT wires touching); half the plays deal one fully tidy DP ("সব পরিপাটি"); a list with HT and LT work is ordered HT first (pro tip 1); reason deck per DP; at the end, how the dressing will be done (shutdown, PTW, test, earth) | spot + order + choose + say no | choosing to dress the structure live (no shutdown / PTW / test / earth) — **flagged** | ✅ built on the shared kit (2026-11-11): drawn DP (HT arm + pin insulators + line, upper jumpers, DO fuse arm, lower jumpers, DTR on the platform, LT cables to the LT box, LT arm with outgoing wires, danger + DP number plates), red numbered rings on marked parts, orange dashed rings on missed ones, the dressing list chip, order card, reason deck, coworker once (myth 1 "যা আছে চলছে তো…" or myth 2 "ওগুলো তো ইনসুলেটেড" = slip), plan deck, freeze with an arc at the jumpers; slips: tidy part marked, a fault missed, LT before HT, listening to him |
| 21 | 4.7 কাজ 2 (`do_4_7_b`) | পরিচ্ছন্নতার শিল্প | order (permit → tester 0 V → earth on both side spans → harness → climb; line clear in reverse: down → look + photo → both earths off → line clear) · spot (4 of 6 untidy places on the DP, HT before LT; a tidy place = slip) · choose (the fix per place, card deck) · say no (coworker: "আর্থের তারটা হাতে বাধছে! এক দিকের আর্থ খুলে কাজ সেরে ফেলো।") | climbing without both earth sets; listening to him (one earth off while aloft) | built, tests green (19) |
| 22 | 4.8/learn | গাছের ডালপালা ছাঁটা (learn_4_8) | 5 picture rounds (why · plan · tool · cut · trim) + myth | — | done |
| 23 | `do_4_8_a` (`m4_tree_plan`) | কাটার আগে পরিকল্পনা | spot (branches grown into the line's clearance — only those; the drop zone under the tree, off the road) · choose (tool by branch size: insulated pruner / saw for thin, chainsaw + rope for thick; plain saw wrong) · order (শাটডাউন · PTW, helper below, গ্লাভস · গগলস, rope, tool — all before the first cut) · say no (coworker: "লাইন চালু থাক! শাটডাউনের ঝামেলা কে করবে? উঠে কেটে দাও।") | 💀 starting the cut with the line live (no শাটডাউন, or kept on at his say-so) | built · 18 tests green · perf 9 rebuilds/s, 0 idle frames |
| 24 | `4.8/do/1` | ডাল নামাও, লাইন বাঁচিয়ে — the line is shut down (docket: শাটডাউন · PTW · আর্থ, earth set drawn on the dead-end pole), the area below is roped off; the trainee is up a roadside tree whose heavy limb droops over the conductors. ক trim small → big (the 2–3 dealt twigs, then the side branch; the limb or side branch first = slip) · খ the rope on the limb before any saw (চেইনসঅ first = slip); the coworker "দড়ি লাগবে না, কেটে ফেলে দাও!" (listen = slip) · গ where to stand for the cut (beside the trunk = right) · ঘ the 3-cut: under → top (the limb comes free onto the rope) → hold "ধীরে নামান" length by length (it swings in to the trunk, clear of the line; "দড়ি ছেড়ে দিন" = slip) → the collar cut (out of order = slip) · ঙ clearance: cut the one shoot growing at the line (dealt low/mid); cutting a shoot growing away = slip (directional pruning); "ক্লিয়ারেন্স ঠিক" with it left = slip | order + choose + spot + say no | standing below the limb or out on it (in its fall line) | ✅ built on the shared kit (2026-11-11): drawn roadside scene, ground mate holding the rope, reason deck per station, coworker once, freeze with the limb falling onto the spot; 16 tests green, idle 9 rebuilds/s · 0 frames |
| 25 | `4.9/learn` | রাস্তার আলো মেরামত — ছবির বোর্ড | 5 picture rounds (dark · day · cycle · isolate · platform) + rival myth | — | playable (board + test green) |
| 26 | 4.9 কাজ 1 | অন্ধকার রাস্তা — দোষ কোথায়? | read (multimeter 230 V / 0 V) · order (supply → lamp → ballast) · isolate (MCB OFF + meter proves 0 V) · spot (ballast that matches the lamp's rating) · say no (coworker) | 💀 lamp/ballast into the fitting with the MCB ON; listening to the coworker | built, 18/18 tests green |
| 27 | `do_4_9_b` · engine `m4_streetlight_fix` | আলো ফেরাও | order (isolate → ladder → tie → harness → climb; prove → tighten → part; down → scrap → MCB ON) · spot (THIS light's MCB by the pole plate; the safe ladder side; the loose, corroded terminal) · choose (part matching the ballast / LED driver; scrap crate vs dustbin) · inspect (tester 0 V / LIVE) · say no (coworker: "কোনো দরকার নেই MCB নামানোর! শুধু তো ল্যাম্প — মই লাগিয়ে উঠে পড়ো।" or, if the MCB is already off, "আবার টেস্টার কেন?") | 💀 a hand on the terminals / lamp holder while live (untested, after a LIVE reading, or by listening to the coworker) — lesson point 2 + myth 1 | built, tests green |
| 28 | `4.10/learn` | এলটি (LT) লাইনের ফেজ ব্যালেন্সিং — ছবির বোর্ড | 5 picture rounds (spot · measure · plan · work · check) + myth (নিউট্রালে কারেন্ট থাকে না) | — | built, tests green |
| 29 | 4.10/do/0 (do_4_10_a) | তিন ফেজে সমান ভার (m4_phase_balance) | read (tong tester round R, Y, B and N at the feeder pillar, then say which phase is heavy) · spot (the neutral must be measured too) · choose (the phase chart: move connections off the heavy phase and give the 2 new ones a phase until the 3 phases are within 10 A) · order (tell consumers → LT main OFF → PTW → tester 0 V → earth → spanner on the bars → earth off → PTW back → ON → measure all 4 again → record book) · say no (coworker: "সব নতুন কানেকশন <heavy> ফেজেই দিয়ে দাও") | spanner on the bars with the LT main ON (changing service connections live) | built, 19/19 tests green, analyze clean |
| 30 | m4/gate | স্কিলডের ডকেট · র‍্যাঙ্ক গেট (9 কাজ) | DO off-load + PPE + stance; read oil gauge + IR temp, report/write; earth test (2 spikes) → water pit + clamp → retest; earths both sides + insulator order (coworker: "skip earths"); spot hot jumper clamp → brush/paste → two wrenches; DP dressing top→bottom + nuts; cordon + rope + three-cut (no topping); MCB off → test 0 V → lamp → MCB on; tong tester R/Y/B/N → shift heavy→light under shutdown → re-measure | DO on load · DO from underneath · line work without earths both sides · lamp on a live MCB · moving service lines on a live LT | built, tests green |

## Owner decisions (flagged by the level agents — please confirm or change)

### Top decisions for Module 4 (director's summary — details per level below)
1. **DO fuse on load — the levels disagree.** 4.4 board and 4.4a follow lesson 4.4: heavy load is opened with a load-break tool (pulling without it = fatal). The Module 4 gate follows Module 2 / lesson 2.5: LT off first, opening on load = fatal (no load-break tool offered). Pick one rule; the fix is either the gate or the two 4.4 levels.
2. **Lesson 4.2 calls jumper tightening "live line maintenance".** Board 4.2, 4.2a and 4.2b keep the job dead (shutdown, test, earth); the lesson text likely needs correcting.
3. **Touching the transformer tank** (4.5b, gate): lesson 4.5 says feeling it by hand is OK if earthed; the checked film says never. Levels follow the film (hand on tank = fatal in 4.5b, slip in the gate).
4. **4.9a street light**: MCB off + prove 0 V, but no lock-and-tag (lesson doesn't ask for it). 230 V borrowed from other lessons.
5. **4.6 board — earth pits**: lesson says "two separate pits", film says neutral and body each get two; the card draws four.
6. **Harness**: 4.7b makes no-harness only a slip (lesson 4.7 silent). 4.1a/4.1b treat harness as required.
7. **Made-up numbers** to confirm: 4.5b nameplate/clamp currents, 4.6a/4.6b earth readings, 4.4b link ratings 6–20 A, 4.10 board uses the lesson's own R/Y/B currents.
8. **4.7a**: the "live dressing = fatal" plan beat comes from the brief's safety rule, not lesson 4.7.

### m4lb1
- hold/block: the second safe card draws the rope run over a block at the pole top; the lesson only says "rope or other support".
- bypass/half (clamp on the conductor only, not anchored to the cross-arm) is inferred from "bypass from both sides of the string".
- disc/nosplit and disc/cracked rejects say "check puncture and crack both — a damaged disc must be replaced"; the lesson says "check both" (advanced facts + film line 13), the "must be replaced" is the job's premise.
- prep: the lesson's "right size insulator / tools / binding wire" point is in the reason deck only (no picture trap for it).
- Live-line (hot-stick) replacement pro tip deliberately left out of the board.

### m4do1a
- **Not in lesson 4.1's text (module rules from the brief / lesson 1.6):** "test the line dead with a tester before
  the earths go on" (slips `earth-live`, `earth-untested`) and "helmet + harness before climbing" (slip
  `no-harness`). Lesson 4.1 says only PTW, de-energise and earth from both sides.
- **Deadly for one-side earth:** the lesson says earthing from both sides is required and that a dead line can carry
  induced voltage; making a one-side-earth climb deadly is my call per the brief.
- **Left out:** lesson 4.1's "inspect the pole and crossarm before climbing" — no hands-on move for it (it is not
  scored); ratings/sizes (11 kV, insulator ratings) — the lesson gives none, so the shelf only distinguishes pin vs
  disc and sound vs cracked; spanner/pliers (assumed on the tool belt).
- **Kit per job (from lesson points 2–3):** pin = new pin insulator + binding wire + rope (conductor support);
  disc = new disc + come-along + turnbuckle. Extra fittings are not a slip.
- **Scene drawing:** conductors are drawn running across the scene at a gentle slope (a cheat of perspective so
  three phases never overlap); the tension pole is drawn in vertical formation with a string to each side and a
  jumper. Earth sets are clamps on all three conductors shorted to a rod at x = 32 and x = 342 (design px).
- Coworker exit line reuses his recorded clip "হুঁ! যা খুশি করুন।".

### m4do1b
1. **Pin order.** The lesson (and film) say: free the conductor from the binding, THEN hold it on a rope. Roping first
   is allowed (not a slip — it is not less safe); the slips are the spanner on a still-bound conductor and on a free,
   unsupported one.
2. **Harness anchored / earths removed last** (from the concept seed) are NOT in lesson 4.1's text. The harness is drawn
   anchored and the earth set drawn on; neither is a move or a deadly. Earth removal / line-clear is left out.
3. **Only one deadly**: opening a strain string under load — the lesson's own words "মারাত্মক ভুল". Pliers after the
   come-along is clamped but before the turnbuckle took the load up is also deadly (the load is still on the string).
4. **Rusted pin = slip** (pro tip 2 says "ভালো অভ্যাস"; the film's S5_02 lists it as a field rule). Owner may prefer it
   non-scoring.
5. **Spare inspection** (cracked / punctured spare = slip) comes from the engineering-facts box + film S4_03 ("দুটোই
   পরীক্ষা করুন"), applied to the new insulator as well as the old.
6. Inferred right reasons: "ঢিলে বাঁধনে তার খাঁজ থেকে সরে যেতে পারে" (pro tip 3: firm seating),
   "পিন আটকানো না থাকলে টানে স্ট্রিং খুলে যেতে পারে" (step 4 "পিন সুরক্ষিতভাবে আটকে দিন").
7. Tension string drawn as one string per phase (no second string on the far side / jumper); disc "cap and pin
   matched" orientation is not a move (the spare goes in one way).
8. No voltage, no torque or tension figures used (the lesson gives none). Hot-line (live-line) replacement and
   suspension strings (pro tips 1, 4) are not in this level.
9. The listening-to-him outcome is a slip, not deadly (a loose binding is a fault, not an instant injury).
10. Mistake art (8 SVGs) is hand-built wrong | right; `pin_first.svg` serves both `release-gap` and `no-split-pin`.

### m4lb2
- The lesson's safety tip calls tightening a loose jumper "লাইভ লাইন মেইনটেন্যান্স" (with PTW, PPE, procedure). That clashes with
  the house rule (line work only after shutdown, PTW, test, earth). The board does NOT say "live"; it only keeps
  "লুজ জাম্পার টাইটে PTW, PPE আর সঠিক পদ্ধতি চাই" as a reason chip, and no card shows anyone working on the pole.
  Owner: please reconcile the lesson text.
- Two traps are inferred from "use the right type of connector" / "use the hydraulic tool with the right die":
  `connector/twist` (wires twisted together, no connector) and `connector/pliers` (compression connector squeezed with pliers).
- "C shape" is drawn only as the support-insulator card (a C-ish curve held by a jumper support insulator).
- Close-up cards show gloved hands only (no full figure), so PPE beyond gloves is not visible there.
- The test imports `learn_board_pack42.dart` directly (needed until registered; drop it after registration if the
  analyzer calls it unnecessary).

### m4do2a
- **No deadly move.** The job is on a dead, earthed line (brief), and the lesson's harms (hotspot, melting, fire, corona) come later, not on the spot — all slips.
- **Lesson's safety tip says tightening a loose jumper is "লাইভ লাইন মেইনটেন্যান্স"** with PTW/PPE. The level keeps the job dead (shutdown · PTW · আর্থ on the docket, earth set drawn) as the brief requires; the wording in lesson 4.2 may need a look.
- **The copper span is inferred.** Pro tip 3 says a copper jumper on an aluminium line needs a bi-metallic connector; the level stages it as "the right span is an old copper conductor" (docket line "ডান পাশে তামার তার"). Flagged.
- **"PG · Cu" on an all-aluminium joint is a slip** — from step 1's "কন্ডাক্টরের মেটেরিয়াল অনুযায়ী কানেক্টর নির্বাচন করুন"; the galvanic reason is from pro tip 3.
- **"বাঁধাই তার" (a twisted binding-wire joint)** is used as the not-a-connector option; the lesson only says "সঠিক ধরনের কানেক্টর (PG বা কম্প্রেশন)".
- **Left out:** the compression connector + hydraulic die (step 3 — that is Module 2's crimping), torque values (lesson gives none), the jumper-support insulator ("প্রয়োজনে"), C shape (only U drawn).
- **"Pulled straight" slip** — the lesson asks for a smooth U or C shape; a taut straight jumper is the counter-example (inferred).
- **Too-long loop** is drawn swinging into the pole/arm hardware (side view of the pole); the card uses the lesson's words "ক্রস-আর্ম বা পাশের ফেজ".
- **Stray strand / corona** comes from the film's field rule 3 ("কোনো ধারালো প্রান্ত রাখবেন না") and the lesson's advanced fact; trimming the strand is the shown fix.
- Piece sizes are relative (0.5 / 0.65 / 0.8 / 1.0 / 1.3 × the line's conductor); no ratings or code names shown.
- Shape tiles have screen-reader labels "আকার 1/2/3" only (no text on screen).

### m4do2b
1. **Live vs shutdown:** lesson 4.2's safety tip says tightening a loose jumper is "লাইভ লাইন মেইনটেন্যান্স" (with PTW and PPE). The level follows the module brief instead: shutdown + PTW, tester, earth, then the work; any tool on a live jumper is deadly. Please confirm, and consider correcting the lesson's tip.
2. **Torque:** the lesson only says "সমানভাবে এবং সঠিক টর্কে". No value is given, so the dial has no numbers — its green band is a game abstraction. Going past the band is a slip ("বেশি টাইটে বোল্ট আর ক্ল্যাম্প নষ্ট হয়"); that consequence is inferred, not in the lesson.
3. **Melted clamp → replace:** the lesson says a loose connector can melt and the wire fall; that a melted clamp must be replaced (tightening it = slip) is inferred. Replacing an intact loose clamp is allowed (no slip).
4. **Brush + paste before re-tightening:** the lesson gives this for making a connection (point 1, pro tip 4); the level applies it to re-tightening a hotspot too.
5. **Tester → earth → work, earth off before the PTW goes back:** from the module safety rules (lesson 1.6), not lesson 4.2's text; those cards have no lesson point.
6. **Left out:** a thermal camera (not in the lesson); the hiss/hum and radio/TV interference signs (in the lesson but hard to show without hint text); the bi-metallic connector and jumper size (only in the reason myths); the jumper support insulator.
7. The structure is drawn as a single angle pole with the three phases stacked vertically (so the spans don't cross on screen); the earth set clamps on the right span of each phase.

### m4lb3
- **Road clearance:** the lesson says the clearance over a road must be "as the law requires" but gives no figure, so the board names none.
- **Drip loop:** the reject line for the no-drip-loop card says that without the loop, water runs down the cable into the meter. That is my reading of the film's "জল আটকানো ড্রিপ লুপ"; the lesson doesn't say it in those words.
- **Pole work:** the sources don't say whether the IPC is fitted with the LT line live or shut down. So no worker is drawn on the pole: the pole and IPC cards are close-ups of the hardware, with one gloved hand at most. House rule: line work only after shutdown, PTW, test and earth.
- **Pole anchor:** the lesson only says the anchor clamp goes "below the LT line". The chip that puts it above the line is a wrong chip. The board gives no reason for "below", because the lesson doesn't give one.
- **Second myth:** myth 2 (a twisted joint instead of an IPC) is used as two traps in the ipc round, not as the rival's line.
- **ladderIndex 64** in the test is a placeholder (the test only renders the board).

### m4do3a
- Seed items NOT in lesson 4.3 or its film script and therefore left out: sanctioned load, twin vs four-core cable,
  meter box position, MCB / cut-out, earthing at the consumer end. No cable size (mm²) and no road clearance figure
  is shown — the sources give none (lesson only says "আইন অনুযায়ী").
- Cable size is shown only as "কেবিল (মাপমতো)" vs "কেবিল (সরু)" (lesson: "সঠিক সাইজের সার্ভিস কেবিল"; voltage-drop fact).
- "জোড়ের টেপ" on the shelf stands for the stripped-and-twisted joint of myth 2 — taking it books the no-IPC mistake (inferred).
- The long-way-round route as a mistake rests on point 1 ("সবচেয়ে সোজা এবং নিরাপদ রাস্তা") + the voltage-drop fact (length).
- Work order follows the lesson's sequence (anchoring → GI wire first → cable strapped → connections → test). The lesson
  says nothing about shutdown/PTW before the IPC on the LT line; this level does not show that step (level b's concern).
- Fetching a paper that was fine is booked as a slip (`paper-misread`) — a design choice, not a lesson rule.

### m4do3b
1. **The safety steps around the LT tap are not in lesson 4.3.** The lesson never says how the LT line is made safe for the IPC. I followed the brief's module rules: helmet and harness on the pole, then shutdown/PTW, prove it dead with a tester, earth it, and remove the earth before the line or the fuse comes back. The deadly mistake is a tool or the earth set on the line without a shutdown. In real work IPCs are often fitted live on LT ABC with insulated gloves, but the lesson doesn't support that, so the level never allows it. Owner to confirm.
2. **"House end first, the pole last."** This follows the order of lesson point 2 (strap the cable, connect the meter, then the pole). The lesson presents that order but does not state it as a rule. Doing the pole first books the `pole-before-meter` slip. Owner to confirm.
3. **Colours and marks.** The phase core is red with an "L" sleeve and the neutral core is black with an "N" sleeve. The LT conductors carry R/Y/B/N tags. The lesson only says to "mark phase and neutral". The colours are an assumption.
4. **No harness item in the lesson.** `no-harness`, `not-proven-dead`, `no-earth` and `earth-left-on` have no lesson point, so their cards have no "পাঠে দেখুন". The same goes for `offcuts-left`, which comes from pro tip 4, not a numbered point.
5. **The road clearance (pro tip 1) and the cable size / voltage drop topics are not used.** The lesson gives no figures for them.
6. **The art's SVG text.** The mistake art in `assets/game/art/m4_service_connect/` uses some Bangla `<text>` (as `m2_gate_field` does). In the test renders it showed as boxes, because the test has no fonts. Please check it on a phone. `order.svg` depends mostly on its text.
7. **Environment.** At 13:28 `~/Desktop` was moved into iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/Desktop`). I built and committed at that real path. The worktree's `.git` file still points at `/Users/roumak/Desktop/roumak-projects/...`, so I committed with `--git-dir`/`--work-tree`. Other agents' writes to the old path end up in `~/Desktop/roumak-projects` / `~/Desktop/.stray_roumak_1328` (a stray copy of `m4_service_connect.dart` is there; ignore it).

### m4lb4
- `prep/wet` draws mud and standing water; the lesson only says "check the standing place is dry and level".
- Lesson pro tip 3 (wet/humid weather makes the arc likelier and longer) is used only as a wrong why chip
  ("ভেজা আবহাওয়ায় আর্ক ছোট হয়, চিন্তা নেই"), not as a picture.
- `field/three` shows all three cutouts dropped open after a fault; the fault repair itself is not drawn.
- `link/button` reject ("a wrongly tied link may fail to drop out on a fault") is the lesson's general
  warning about a badly tied link, applied to an unseated top button.
- `link/port` reject keeps the lesson's English term "leader wire".
- Second myth (re-opening on a closing spark) is used as the `close/reopen` trap, not as a myth beat.
- The test imports `learn_board_pack44.dart` directly (the models file does not export it until registered).

### m4do4a
- **Lessons 2.5 and 4.4 disagree on load.** Lesson 4.4 treats the DO as a switch worked ON LOAD ("মনে রাখবেন, আপনি একটি লোডযুক্ত সুইচ অপারেট করছেন"), with a load-break tool for heavy load (pro tip 1). Lesson 2.5 (and `m2_hotstick_operate`) says a DO fuse is opened off-load. This level follows 4.4, so there is no "off-load first" step here. Please settle which rule is right.
- **The deadly is an inference.** Lesson 4.4 says to use the load-break tool on heavy load. Film line 1 says an arc flash can blind or kill. Making "a heavy-load fuse pulled without the load-break tool" deadly combines the two.
- **Two parts of the concept seed were left out (not in the lesson or the film):**
  - "switch the LT side off first";
  - any phase ORDER for opening (e.g. middle first).
  The "order" move is the lesson's own order (hook → face aside → one quick pull), plus "all three open" (pro tip 2).
- The wet-ground slip uses point 1's "শুকনো এবং সমতল" and pro tip 3 (wet weather makes arcs bigger). The puddle is a scene device.
- "Too short" and "cracked" rods come from point 1 ("সঠিক দৈর্ঘ্যের … অক্ষত"). No voltage or length numbers are shown.
- The face shield and arc-flash painters are imported from `m2_hotstick_operate_world.dart` (`HsShieldPainter`, `HsArcPainter`). If that file changes, this level changes with it.

### m4do4b
- **Patrol / DTR-LT check / "report"** (from the concept seed) are not in lesson 4.4 or its film. I kept it to one neutral line ("দল লাইনটা ঘুরে দেখে এল।") and the lesson's own rule (pro tip 2: open all three, clear the fault, refit one by one). No patrol procedure is shown.
- **Re-blow → stop** is inferred from pro tip 2 + myth 2 ("if there is no permanent fault, a small spark is normal"); the lesson does not say it in so many words. Reclosing after a re-blow is a slip, not deadly.
- **Thick wire = deadly**: the lesson says only "the right ampere-rating fuse element" (point 1) and that a badly made link "may fail to drop out on a fault" (point 2). Deadly is my call (seed allowed it); the card says only that it will not drop out on a fault.
- **Link ratings 6A / 8A / 10A / 16A / 20A** are a match-the-docket task; no sizing rule (kVA → link) is claimed or shown. Owner may want real WBSEDCL ratings.
- Opening the other two phases and closing them again is a single tap each (stance/face aside are tested only on the main closing, to keep the round short; lesson 4.4 কাজ 1 covers opening).
- PPE (helmet, insulated গ্লাভস, face shield) is always shown on the trainee, not a move here.
- Reuses three painters from lesson 2.5 (`HsRodPainter`, `HsShieldPainter`, `HsArcPainter` from `m2_hotstick_operate_world.dart`) — same rod, shield and flash.

### m4lb5
- **Lesson vs film on touching the tank:** the lesson says *if safe, feel the tank by hand (after checking it is
  earthed)*; the reviewed film (S3_03) says *don't touch the tank — measure from afar with an infrared thermometer*.
  The board follows the film: hand-on-tank is a trap, infrared thermometer is a safe card. Please confirm.
- **Leak / climb trap:** the reject says the leak is mended "শাটডাউন নিয়ে" — the house rule, not the lesson's words
  (the lesson only says report and arrange top-up and leak repair).
- **check / climb trap:** standing on a live transformer to read the gauge — the lesson only says the gauge can be
  read from the ground with the line on; "don't climb on" is the inference.
- **Top-up cards** draw the DO fuses hanging open for "line shut down" (lesson: transformer switched off before
  top-up; film: line off). Filtered new oil is shown as a funnel with a mesh; "same grade" as a sealed new drum/can.
- **Heat round:** "summer noon is normal" comes from the lesson (warmer at noon / peak load is normal). No
  temperatures, ratings or times are given anywhere — none used.
- Left out: OTI / WTI, BDV and DGA lab tests (film's field rules 1–2) — not picture-able without words; the lesson's
  second myth (heat ≠ broken) is folded into the heat round.
- Plinth-mounted transformer drawn (so the tank is at arm's height for the hand/ear traps); the overhead DO fuses
  are on a pole at the left.
- **Environment:** at ~13:28 `~/Desktop` stopped pointing at the iCloud Desktop; this worktree lives at
  `~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/roumak-projects/smartlineman/slm_wt/m4lb5`. Tests and
  the commit ran there (git via `--git-dir …/slm_flutter/.git/worktrees/m4lb5`).

### m4do5a
- **Test → earth → climb (with helmet + harness) before the top-up** comes from the brief's module safety rule ("line work only after shutdown, PTW, test and earth"). It is not in lesson 4.5's text. The lesson (pro tip 1) and the film (line 11) only say the transformer/line is switched off first. The deadly "earth on a live line" is mine, from the same rule.
- **Shutdown = DO fuses dropped open** (a single শাটডাউন step, as in the M2 gate). I did not invent an LT-before-HT order; the lesson does not give one.
- **Drum choice:** the lesson says "একই গ্রেডের এবং ফিল্টার করা নতুন তেল" and warns against "ভুল তেল বা আর্দ্র তেল". The myth is engine oil. I show the moist oil as a transformer-oil drum left open in the rain (water on the lid). The labels "OIL · FILTERED", "USED OIL" and the seal band are my drawings. **Sludge is left out** (not in the lesson).
- **Low-oil response:** the lesson says report to the supervisor first; the top-up and leak repair are arranged. In the game the supervisor's go-ahead is one guide line ("সুপারভাইজার বললেন, টপ-আপ করুন"), then the player does the top-up.
- **Leak with the level still fine → রিপোর্ট** comes from film line 15 ("বুশিং বা ড্রেন ভালভ থেকে তেল লিক দেখলে সঙ্গে সঙ্গে রিপোর্ট"). The lesson lists the four leak places (point 3).
- **Temperature reading:** the lesson gives the 30°C mark example and says oil rises in heat and falls in cold (pro tip 2). The dealt bands are mine: winter 0.30–0.40 of the glass (MIN 0.2, mark 0.5), summer 0.60–0.70 (MAX 0.8), mild 0.46–0.54, low 0.07–0.14. Reporting a fine heat/cold level is booked as a slip ("misread").
- The weather is shown by the sky and the inspection slip's date and time ("22 মে · দুপুর 2টা", "8 জানুয়ারি · ভোর 6টা", "15 মার্চ · সকাল 10টা"). No thermometer is drawn. Most DTRs have none (lesson point 2).
- The temperature checks (touch, humming, fins, overload) are left to কাজ 2.

### m4do5b
- **Touching the tank:** the lesson (point 2, sign 1) says feel the tank by hand "if safely possible, after making
  sure the tank is earthed"; the accuracy-checked film (S3_03) says "তাপ মাপতে ট্যাঙ্কে হাত দেবেন না; দূর থেকে
  ইনফ্রারেড থার্মোমিটারে মাপুন". We follow the film: a hand on the tank is deadly (burn + a live body if the earth is
  bad). Please confirm.
- **No temperature limits in the sources:** the lesson gives none for DTRs (only OTI/WTI alarms on big power
  transformers). So the IR thermometer's screen shows a colour heat bar with a pointer, no numbers; overheating is
  also shown by heat shimmer over the tank. "Compare with the lesson's limits" from the seed is left out.
- **Load check numbers are ours:** the lesson says only "লোড পরীক্ষা করুন". The close-up shows a nameplate
  "100 kVA · LV 415 V · I 139 A" (computed: 100 000 / (√3 × 415); 415 V as on lesson 3.6's nameplate) and clamp
  meter readings R/Y/B 168/174/161 A (overloaded) or 96/104/99 A. The clamp meter itself is from lesson 4.10.
- **Fins cleaning on a shutdown:** the lesson says "কুলিং ফিনগুলো পরিষ্কার করুন" without saying how; we made the right
  answer "শাটডাউন নিয়ে / লাইন বন্ধ করিয়ে" (the project's rule: no work near live parts without a shutdown), and
  pulling creepers off live is a wrong option.
- **Low oil:** right action = report to the supervisor for the leak repair + top-up (lesson point 3); the
  "top-up with the line off, same grade filtered oil" detail is from the pro tip / film S4_03.
- **Left out:** the loose LT terminal hotspot from the concept seed (not in the lesson or film); the hum/boiling
  sound sign (no fitting sound asset; shown as shimmer only).
- Misreading is a slip both ways: overheating called normal (point 2) and normal warmth called a fault (the myth
  buster: "গরম হওয়া মানেই খারাপ নয়"). A fine spot tapped while looking for the cause is not scored.

### m4lb6
- **measure / `lying` trap**: the lesson says only that the two spikes are driven into the ground. The trap's point (spikes lying on the surface give no reading) is inferred from that.
- **soil / `short` trap**: built from the second myth's reality ("সঠিক দৈর্ঘ্য"). The lesson gives no length figure, and none is shown.
- **tx / double earthing**: the lesson says "two separate earth pits". The film says the neutral and the body each get two separate earth connections, and the `double` card draws that (four pits). Please confirm this fits WBSEDCL practice.
- **Earth resistance test conditions**: the lesson doesn't say whether the electrode is disconnected or shut down for the test, so the cards and text say nothing about it. The lesson's pro tip says a special maintenance team usually does this test. The board doesn't imply the lineman does it alone.
- **Test flake**: `board waits quietly … (anim)` failed once in four runs (load from the parallel agents); the other three runs, including the last two, were 13/13 green. It is the same idle-frame check as the 2.8 test. If it recurs on the merged tree, look at late SVG decoding during the measured window.
- **Art**: the tester and megger are generic orange cases (an LCD with bars, or a dial and crank), with no text or numbers on them. The ohm values appear only in the why chips.

### m4do6a
- **Not in lesson 4.6 or its film, so left out** (the concept seed asked for them): the spike spacing (and that the
  spikes go in a straight line), the tester's E/P/C terminals and which lead goes where (the three leads are drawn
  only by colour), and disconnecting the earth lead from the system before the test. The lesson says only: an earth
  resistance tester / earth megger, the fall-of-potential method with two temporary spikes besides the electrode,
  and the tester shows ohms directly.
- The seed's coworker line "স্পাইক কাছাকাছি পুঁতে দাও, একই তো" was replaced, because spacing is not in the sources:
  his two pushes are the lesson's own points — "চোখে দেখাই যথেষ্ট" (point 3: "শুধুমাত্র চাক্ষুষ পরিদর্শন যথেষ্ট নয়")
  and myth 1 ("লাইন তো চলছে" → "মারাত্মক ভুল…").
- **Target values:** the lesson gives "সাবস্টেশনের জন্য ১ ওহমের কম, সাধারণ ডিস্ট্রিবিউশন লাইনের জন্য ৫-৮ ওহমের কম". It
  gives no separate targets for the DTR neutral / body / LA earths, so the line value is used for all four pits, and
  the deal never shows a reading between 5 and 8 Ω (the lesson's range is not one number). Readings are ours:
  good 1.8–4.2 Ω, high 12–27.5 Ω.
- The double earthing (neutral and body, each to two separate pits) is from pro tip 1 and film line 4. The pit
  markings N-1 N-2 B-1 B-2 are ours.
- No deadly move: the lesson names no danger to the worker in the test itself. Passing a high reading and listening
  to the "line runs" myth are slips (the myth's card quotes the lesson: "প্রাণহানির কারণ").
- No PPE or shutdown is shown or asked: the test is ground work on the earth pits and the lesson does not say the DTR
  is switched off for it. If the owner wants the earth lead disconnected (and so a shutdown), that needs a source.
- Maintenance (tighten/grease, water, charcoal and salt, more electrodes) is left to কাজ 2 (`do_4_6_b`).
- Tapping a sound earth point in the look round costs nothing (a plain ring). The tools wait for the coworker's
  moment (before the first test, or on the high reading), so he always comes once.

### m4do6b
- **Readings are ours:** before the fix 14.8–36.2 Ω (and "OL" on a cut strip — over range, the tester has no path);
  after the right fix 2.3–4.4 Ω. The lesson's target is "সাধারণ ডিস্ট্রিবিউশন লাইনের জন্য ৫-৮ ওহমের কম"; the after-values
  sit under 5 so they pass either end. The reason cards say "5 Ω-এর কম".
- **Site and shutdown are ours:** an LT feeder pillar (named in the lesson's point 1) with its handle at OFF; the intro
  says "শাটডাউন নেওয়া আছে". The lesson does not say whether earth repair needs a shutdown — please confirm.
- **Stolen-lead replacement steps are inferred:** the lesson names the theft ("আর্থিং তার চুরি") but gives no
  replacement procedure; the steps (clean both joints → new earth lead → tighten with a brass nut) reuse point 4
  (clean, grease, tighten) and pro tip 3 (brass/stainless nuts). No GI-pipe or lead-size detail is used.
- **Loose-joint step order** ("জোড় খুলুন → মরিচা পরিষ্কার → গ্রিজ → পিতলের নাটে টাইট"): "open first" is implied, not stated.
- **Left out on purpose:** the seed's "modern compound" and "touching a broken DTR earth lead while live" (not in the
  lesson or the film); salt/charcoal and multiple electrodes (lesson + film S5) are not used as fixes, to keep each
  fault's right answer unambiguous (water vs. treatment for a dry pit is not separated by the lesson).
- **Deadly** is from myth 1 ("কাটা থাকলেও লাইন চলে" → no trip in a fault → death) and film S4_02; the consequence
  plays as a later fault: the pillar body glows live, sparks at the cut ends (non-graphic).
- **Score events:** the right fix pays +5 through `_levelDelta` (a move's points, existing function); refusing him +10;
  slips −10; table 15 (+5 thorough); pass +20, quick +10. Same shapes as Module 2.

### m4lb7
- No clearance distances anywhere: the lesson only says "নির্ধারিত নিরাপদ দূরত্ব" / IS-IEC standard, no numbers.
- finish/bottom shows a worker on the transformer platform with helmet + harness, and portable earths (green leads) on the HT conductors; the finish/tight and finish/loose close-ups show a portable earth on the conductor. Shutdown + earthing is the house rule; the lesson itself does not mention it (not put into words).
- jumper/taut and cable/strain rejects use the lesson's "no needless stress or pull on the wire/cable"; the lesson does not name a "taut jumper" as such.
- jumper/long reject ties the unmeasured jumper to clearance (lesson: measure the length; clearance between phases). The RoW advanced fact is not used.
- gap/body reject says live-to-structure clearance is "আইনত বাধ্যতামূলক" — from the film script line 5 (IS rule, legally mandatory).
- finish/bottom: the lesson calls "start at the top (HT), come down to LT" a good habit (pro tip 1, film line 2); the trap draws it as the wrong order.
- The U jumper is drawn as a U loop between two insulators with a tee down to the DO fuse; the C jumper runs from the insulator head to the DO fuse. Stylised.
- Idle-rebuild guard (`board waits quietly … (anim)`) is borderline for every board, not just this one: a diagnostic
  run measured 36 rebuilds per 2 s (18/s) in fake time for both 4.7 and 2.8, all in the shared guide bubble
  (AiLinemanGuide/_GuideBubble/MascotFaceRig, 4 rebuilds each), and the same for any intro length. On top of that
  the runner's choice clock (`_clockPoll`, Stopwatch = real time) adds rebuilds when the machine is loaded, which
  pushed this test to exactly 20.0 twice while 60 agents ran; the same code passed on the third run. Worth a look in
  `learn_board_runner.dart` (shared — not touched here). The first prompt was shortened to
  "ডিপির মাথায় জাম্পার — কোনটা ঠিক?" while chasing this; it did not change the count.
- The lesson's second myth (insulated wires touching) is used as the gap/touch trap and a reason chip, not as the board's myth beat.

### m4do7a
- **Deadly beat is not from the lesson text.** Lesson 4.7 never mentions shutdown/PTW. The final "how will the dressing be done?" deck uses the project rule (line work only after shutdown, PTW, test and earth); any live-work option is the deadly. Wrong options include "শাটডাউন পেলেই উঠি, টেস্ট-আর্থ লাগবে না" — also treated as deadly. Remove the beat if you want the level slips-only.
- **Left out (not in the lesson or the film script):** danger plate missing, anti-climbing device, bird nests (the concept seed's ideas). The danger plate is drawn only as correct decor.
- **Loose connections** (lesson mistake 4, film line about torque) are not a spot item: they can't be seen from the ground. Not in the level.
- **"Two insulated LT wires touching"** is drawn on the outgoing LT wires from the myth ("তার একটু ছুঁয়ে থাকলে কিছু হয় না, ওগুলো তো ইনসুলেটেড") — the lesson does not say which wires.
- **Order rule** is HT before LT only (pro tip 1 / film line 3); within HT or within LT any order is accepted.
- A tidy part marked counts as a slip (the card shows what tidy looks like) — inferred design choice, to stop tap-everything play.
- Phase-to-body clearance is drawn as the B-phase lower jumper bowing onto the pole; no distance numbers are shown or claimed (the lesson gives none).
- `lessonPoint` mapping (single section): 0 why · 1 elements · 2 common mistakes; the order slip and the deadly have none.

### m4do7b
- **Safety steps not in lesson 4.7's text.** The shutdown order (permit → test → earth → climb) and the line-clear order
  (everyone down → earth off → line clear / permit returned) come from lessons 1.5 / 1.6 and the brief, not 4.7.
  Earthing "from both sides" is lesson 4.1 point 1 ("দুই দিক থেকে আর্থিং"); I drew it as one earth set on each side
  span (left / right) of the DP — please confirm that reading for a DP structure.
- **Harness = slip, not deadly.** The brief says "helmet + harness for anyone on a pole", but lesson 4.7 says nothing about
  it, so climbing without the harness is a slip with its own card. Make it deadly if you want.
- **Left out (no source):** danger plate, anti-climbing device, bird nests (from the concept seed) and any clearance
  figures. The lesson and film give no clearance figures, so the level never shows one.
- **"HT before LT" as a slip.** It's a pro tip in the lesson ("a good habit") and an instruction in the film
  ("ড্রেসিং শুরু করুন উপর থেকে নিচে"). I made LT-before-HT a slip (card, no lesson point, because pro tips aren't
  a numbered point).
- **Look + photo.** "দূর থেকে দেখে ক্লিয়ারেন্স পরীক্ষা" (mistake 2) and "ছবি তুলুন" (pro tip 4) are one step,
  done from the ground before the line clear. Looking from up the pole is a slip.
- The six untidy places map to the lesson's elements: jumper shape, clearance from the body, extra binding wire,
  level cross-arms, a loose connection (shown as a loose LT lug), LT cables without ties/clamps. The DO-fuse cross-arm
  as the "out of level" one is my choice.
- The coworker's push is new: device TTS until recorded. His exit line is his existing recorded clip.

### m4lb8
- plan/ptw card draws earth leads on the dead line (house rule "test and earth"); the lesson only says "PTW, de-energise".
- cut/flush trap ("cut flush into the trunk, collar and all") inverts the film's "finish cut just outside the collar"; the lesson only says wrong cuts can infect the tree.
- trim/fell reject names forest department + local administration written permission (film script); the lesson text itself has no legal part.
- The metal-handled saw trap is inferred from the lesson's "use insulated fibreglass tools near the line"; no claim about conduction made in words.
- Climbing left out on purpose: every worker stands on the ground with a long pruner (no harness question arises).
- ladderIndex 0 in the test's runner (only display).
- Scratch shots test logs 3 MissingPluginException (platform stream `listen`) in the test harness only; the real test is clean.

### m4do8a
- **Metal ladder / bamboo jugaad** (from the concept seed) are not in lesson 4.8 or its film script — left out; the
  coworker's line and the deadly are about keeping the line live instead.
- **Live-line tool work as an alternative to shutdown** is not in the sources — the lesson says branches very close to
  the line → PTW + de-energise before work; the film says "লাইনের কাছে কাজের আগে শাটডাউন নিন". The level always
  requires শাটডাউন · PTW.
- **Test + earth**: after শাটডাউন the scene draws portable earth leads on the pole (Module rule: shutdown, PTW, test,
  earth). Lesson 4.8 itself mentions only PTW and de-energising — not asked of the player, only shown.
- **How the cutter reaches high/heavy branches** (climbing, lift) is not in the lesson; the level shows only the plan
  and the branches coming down into the cordon. No ladder, no climbing drawn.
- The **3-cut method** and "cut from outside in" (point 3) are left to কাজ 2 (`do_4_8_b`, tree cut) to avoid overlap.
- "Insulated tool near the line" is from point 2 + pro tip 2 ("extra protection"); a plain saw is a slip, not deadly
  (the line is already off by then).
- The safe distance "1.5 থেকে 3 মিটার" is quoted from point 3 (the lesson's "সাধারণত") in the missed-branch card;
  the scene shows no distances (the branches in the line visibly reach the wires).

### m4do8b
- **Earth set / "আর্থ" on the docket** come from the project rule (line work only after shutdown, PTW, test, earth). Lesson 4.8 itself mentions only PTW and de-energising.
- **The deadly (fall line)** is my reading of the lesson's "পতনশীল ডাল" danger together with "ডালটি কোন দিকে পড়বে তা আগে থেকে পরিকল্পনা করুন". The lesson never says where to stand. "Out on the limb beyond the cut" is also counted as in the fall line. Make it a slip if you prefer.
- **Rope rigging:** the rope runs from a tie on the limb, outboard of the cuts, over a higher crotch, down to the ground mate. The lesson only says "দড়ি দিয়ে বেঁধে এর পতনকে নিয়ন্ত্রণ করুন"; the crotch and the ground mate are drawn and carry no rule. The ground mate is a plain helper (white helmet), not the careless coworker. He follows the pro tip "একা কাজ করবেন না".
- **Where the twigs fall:** the small twigs drop free into the roped-off area without a rope. In the 2D view they fall past the (dead) conductors.
- **Order rule** is by size rank: every twig, then the side branch, then the heavy limb. Within the twigs any order is fine.
- **Clearance figure** "দেড় থেকে তিন মিটার" is the lesson's own (point 3 / film line 9), shown only in words, never as a number on the scene.
- **Left out:** goggles are not drawn (the figure has no goggles option; the lesson asks for gloves + goggles; gloves are drawn). Chainsaw kickback and two-hand grip (pro tip 3) are not modelled. Topping / V-trimming / legal points from the film are not in this level. The chainsaw is only a tool chip, not drawn in his hands.
- **lessonPoint:** every mistake points to point 2 ("কাটার সঠিক কৌশল"), except the directional-pruning slip (advanced section → `null`).
- His exit line reuses the recorded `হুঁ! যা খুশি করুন।`.

### m4lb9
- House rules drawn, not in the lesson: helmet + harness on anyone in the bucket / on the ladder; the platform reason chip "ওপরের কাজে হেলমেট আর হারনেস সবসময় চাই" says it in words.
- Rounds day and cycle draw the pole switch box OFF (green lamp) on every card — isolation before repair; the lesson's own isolation rule, not shown as a step there.
- The "dark" round shows a gloved worker measuring the live terminal voltage (lesson step 1); the lesson gives no PPE detail for that live measurement.
- "Tilt" trap reject ("হেলে থাকা লিফট স্থিতিশীল নয়…") and "slope" (ladder on a stone) are pictures of the lesson's "stable and secured" platform rule; specific causes are inferred.
- "glow" trap reject tells the player to switch off "that specific light's" fuse/MCB — from the lesson's "ওই নির্দিষ্ট লাইটের ফিউজ, MCB"; that the wrong breaker was pulled is inferred.
- Left out: CCMS, LED module+driver replaced together, gas-discharge warm-up, ballast wattage examples (70W/150W) — no pictures for them; myth 2 (any ballast) appears as the "any" trap in round cycle.

### m4do9a
- **230 V**: lesson 4.9 gives no supply figure. The meter reads 230 (the course's single-phase figure,
  used in other lessons). Confirm or give the real street-light supply voltage.
- **Where the MCB sits**: the lesson says "ওই নির্দিষ্ট লাইটের ফিউজ, MCB বা সার্কিট ব্রেকার" without a
  place. I drew a small MCB box on the pole at hand height. Change if the field has it elsewhere
  (feeder pillar, cut-out).
- **No lock-and-tag**: the lesson's isolation rule is fuse/MCB off + test with a tester or multimeter;
  lock-out/tag is not in 4.9, so it is not asked here. Say if the module rule should be added.
- **0 V → "supply line or fuse"** ends that light as a diagnosis (stamp "সাপ্লাই / ফিউজ"). The lesson
  gives no procedure for fixing the supply/fuse, so nothing is repaired there.
- **Platform**: a ladder is drawn against the pole and the trainee works from the ground (the scene
  abstracts the climb). The lesson's platform rule (stable ladder/sky lift, clear of overhead lines) and
  helmet + harness for climbing are not played. Nobody is shown on the pole.
- Left out of this কাজ (lesson has them): LED driver (module + driver changed together), photocell
  faults (burning day and night), cycling lamps, group control at the feeder pillar, loose connections,
  disposal of old lamps (mercury). Good material for কাজ 2.
- Wrong-reason "myths" are from lesson myths plus field excuses; one ("যত বেশি ওয়াটের ব্যালাস্ট, তত
  বেশি আলো হয়") is my wording of myth 2's idea.
- Pole numbers on the docket ("খুঁটি 21") are random, for variety only.

### m4do9b
- **Coworker line refined.** The seed line was "কোন দরকার নেই, রাস্তায় মই দাঁড় করিয়ে উঠে পড়ো" (cones). Traffic cones /
  road warning are NOT in lesson 4.9 or its film script, so they are neither drawn nor scored. The coworker pushes the
  lesson's myth 1 instead ("কোনো দরকার নেই MCB নামানোর! শুধু তো ল্যাম্প — মই লাগিয়ে উঠে পড়ো।"). If the player has already
  switched the MCB off before he can come, he comes at the top with "MCB তো নামিয়েছ — আবার টেস্টার কেন?" (lesson:
  "কোনো অনুমান নয়, পরীক্ষা করুন"). Listening there: live = deadly, dead = the "not proven dead" slip.
- **Helmet + harness** come from the brief's module rule, not lesson 4.9 (the `no-harness` mistake has no lesson point).
  The figure always wears a helmet, so only the harness is a step.
- **Pole numbers on the MCB tags** ("SL-12" on the pole plate and the feeder-pillar MCB) are my device so the player can
  find "ওই নির্দিষ্ট লাইটের MCB" (lesson point 2). The lesson does not describe tags.
- **Ladder spot**: the lesson says stable, secured and a safe distance from overhead lines — no distance number is shown
  or stated. The "tie the ladder to the pole" step is my reading of "সুরক্ষিত".
- **Test after repair**: the seed's "test with the photocell covered" is not in the lesson; the scene is at dusk, so the
  photocell switches the repaired light on when the MCB goes back ON. No photocell-covering step.
- **Docket "সাপ্লাই ঠিক"**: the supply check (lesson flow step 1, a live multimeter reading) is treated as already done —
  that diagnosis belongs to কাজ 1. The film says a mismatched lamp "পুড়ে ছাই"; I used the lesson's wording (won't light /
  fails early).
- **Disposal**: only the discharge lamps (HPSV / MH) go to the "বাতিল ল্যাম্প" crate (lesson: mercury). For the LED fault
  there is no disposal step (the lesson says nothing about LED modules); the last reason then asks why he tested first.
- The coworker's push lines need recording in his voice; his exit line reuses the recorded "হুঁ! যা খুশি করুন।".

### m4lb10
- Work round, safe card `shutdown`: it draws the pillar switch OFF, a red PTW tag and an earth lead. The lesson only
  says "সঠিক PTW এবং সুরক্ষা নিয়ম মেনে" (the film says "শাটডাউন নিয়ে"); the tag and the earth lead are the house rule.
- Plan round trap `all_to_b` ("R-এর প্রায় সব লাইন B ফেজে… এবার B-ই ওভারলোডেড হবে"): reasoning from the lesson's
  goal (roughly equal phases, "লোডকে পুনরায় ভাগ করে"); the lesson does not say it in words.
- Check round trap `bare` (neutral held bare-handed): from the lesson's "নিউট্রাল তার দিয়ে কারেন্ট প্রবাহিত হয়… বিপজ্জনক
  হতে পারে" and the film's "আনব্যালেন্স লাইনে নিউট্রালও প্রাণঘাতী হয়ে ওঠে". The lesson names no PPE for clamp
  measurement; the worker is drawn in helmet and gloves anyway.
- Measure round traps `count` (counting houses) and `bulb` (judging by a bulb's glow) are field examples of the
  lesson's "সঠিক পরিমাপ ছাড়া… অনুমানের ওপর কাজ"; the lesson names neither.
- Readings in the plan art are bars only (no numbers in art); the numbers R=120A, Y=70A, B=50A are in the prompt
  (the lesson's own example). The house counts per phase in that art (4 / 2 / 2) are illustrative.
- Left out: the transformer de-rating figures (100 kVA → 70–80 kVA; the film says 80) and the vector-sum theory —
  not picturable as an act; the "check periodically" point is only a reason chip.

### m4do10a
- **The "balanced" mark is my inference.** The game accepts the chart when the three phases are within 10 A of each other. Lesson 4.10 gives no tolerance, only the after-example 85/80/75 A (a 10 A spread). The re-measure then shows the neutral at about 10 A or less.
- **Gloves for the tong test come from lesson 1.1, not 4.10** ("লাইভ বা সম্ভাব্য লাইভ কাজের সময় এটাই হাতের মূল ঢাল"). Lesson 4.10 does not mention PPE for the clamp meter. That mistake has no "পাঠে দেখুন" point.
- **Prove dead → earth before the work, and earth off + PTW back before ON, are the module's rules.** Lesson 4.10 only says "সঠিক PTW এবং সুরক্ষা নিয়ম মেনে"; the film says "শাটডাউন নিয়ে". The no-prove, no-earth and on-early mistakes have no lesson point.
- **"Tell the consumers before the shutdown" is a slip.** The lesson's pro tip 4 says "সম্ভব হলে", the film says to tell them before the change, so it is enforced when the LT main goes OFF. There is no lesson point.
- **The only deadly is the spanner on live bars.** Every other mistake is a slip. Listening to the coworker (all new connections on one phase) is a slip because the lesson treats unbalance as overload, low voltage and loss, not instant death. The film calls an unbalanced neutral "প্রাণঘাতী", but I did not make that deadly.
- **Simplifications:**
  - The work happens at the feeder pillar's bars. The lesson says "ফিডার পিলার বা পোলের ওপর", and I chose the pillar so there is no climb.
  - Pressing the spanner on the bars once moves every planned connection.
  - Each phase current is the plain sum of its consumers' loads, at the same power factor.
- **Left out:**
  - "Measure at peak load" is only the scene's setting (evening) and the guide's line ("পিক-লোডের সময়"). There is no time-of-day choice.
  - Pro tip 2 ("big three-phase loads first") is not in the level.
- Rung id `4.10/do/0` is my guess, used in the tests only. The catalog decides.
- **Environment:** at about 13:28, `~/Desktop` lost its iCloud redirect, so `~/Desktop/roumak-projects/...` no longer holds the repo. I worked in the real worktree at `~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/roumak-projects/smartlineman/slm_wt/m4do10a`. Some of my first writes landed in the new local `~/Desktop/roumak-projects/smartlineman/slm_wt/m4do10a/` (see Scratch).

### m4gate
1. **Hand on the tank (4.5):** the lesson text says touching the tank is OK "if safe and the body is earthed"; the
   accuracy-checked film says never touch, use an IR thermometer. The gate follows the film (a hand on the tank is a slip).
2. **Illustrative numbers (not from the sources):** IR reading 44–57 °C (no judgement is made on it); earth readings
   11–19 Ω before the fix and 2.6–4.5 Ω after (judged against the film's "line earth below 5–8 Ω"); currents use the
   lesson's own example (heavy 120 A, 70 A, 50 A, N 50 A); after one shift 84/70/86 A with N 6 A — illustrative.
3. **Engine oil** in the transformer is a slip, not deadly (film: "fire at once"; no deadly rule in the lesson). Change if wanted.
4. **DO off-load:** 4.4 says heavy load needs a load-break tool; the gate keeps Module 2's rule (switch the LT off first,
   pulling on load is deadly).
5. **Order inside a day:** the DTR is isolated by its three DOs for stations 1–3; stations 4–7 run on the 11 kV section under
   a written PTW with earths both sides (shown in the docket); the street light uses its own MCB; the LT shift is "under
   shutdown". Closing the DOs back at the end of the day is not played.
6. **Lesson 4.3 (new service connection)** is not one of the nine seed jobs, so no station teaches it.
7. **Pole PPE:** the player figure is the stock `LinemanFigure` (helmet, no visible harness); the docket lists helmet +
   harness. Harness is not a separate move.
8. The DO mistake cards reuse `m2_gate_field/do_load.svg`, `do_stance.svg`, `do_ppe.svg` (exact match). All other cards are
   new, generated by `tool/m4_gate_field_art.py`.
