# MODULE3_LADDER.md — Module 3 (টেকনিশিয়ান) master list

Built 2026-11-11 by 30 parallel agents on `feature/module3` (one git worktree per level), merged and wired by the director.
Same frame as [MODULE1_LADDER.md](MODULE1_LADDER.md), [MODULE2_LADDER.md](MODULE2_LADDER.md) and the playbook. Rank at the gate: **টেকনিশিয়ান** · badge: **লাইন চেনার জাদুকর** · 30 rungs (10 Learn, 19 Do, 1 gate).
Status: built on the shared kit, tests green. Every row's open content questions are in **Owner decisions** below.

## Master table

| Step | Rung | Name | Moves | Deadly (💀) | Status |
|---:|---|---|---|---|---|
| 1 | 3.1/learn | কন্ডাক্টর পরিচিতি: ACSR, AAAC (picture board) | 5 picture rounds (magnet · coast · sleeve · strip · old line) + myth | — | built, 13 tests green |
| 2 | `3.1/do/0` (`do_3_1_a`) | কোন তার কোনটা | inspect (rub the cut face to the core · magnet test · hand along the wraps for a cut strand) · choose (load the docket's conductor on the van / tell the store when no good drum) · say no (coworker: "দুটোই তো তার — যেটা হাতের কাছে আছে" or "একটা সরু তার কাটা তো কী") | none — all slips (lesson frames these as a line that rusts/weakens/snaps later) | built, tests green (16) |
| 3 | `3.1/do/1` | জোড় ঠিক তো? — a span under shutdown, earthed at the near pole; one phase broke and both ends lie on a tarp. Two joints (one ACSR, one AAAC; the docket names the code DOG / RABBIT / PANTHER) + one tray of 4 finished joints (2nd or 3rd round) | **order** (the step tray is shuffled each round: চুম্বক · স্লিভ · ব্রাশ · ঢোকান · চাপ দিন; the sleeve before the magnet = a guess) · **inspect** (the magnet sticks to ACSR, drops off AAAC; a tray of 4 joints: reject the wrong-type sleeve (tag ≠ sleeve print) / a cut strand at the mouth / a half-pressed sleeve) · **choose** (from the kit: the right sleeve, the other type's of the same code, the same type's of another code) · hands-on holds (push both ends fully in; pump until the valve clicks) · **say no** (coworker: "একটু ঢিলে থাকলে কিছু হয় না! অর্ধেক চাপেই ছেড়ে দাও।") | none (line shut down and earthed; the lesson's harm is a hotspot later — the joint glows under load before the card, then the job starts again) | playable, 18 tests green (perf: 9 rebuilds/s anim, 0 frames idle) |
| 4 | `3.2/learn` | ইনসুলেটর পরিচিতি: পিন, ডিস্ক, শ্যাকল (picture board) | 5 picture rounds (look · pin · end · disc · clean) + why chips + the rival's myth | — | built, tests green |
| 5 | `do_3_2_a` | কোথায় কোন ইনসুলেটর | choose (pin / shackle / disc string by spot and kV) · inspect (swipe for a hairline crack, turn for a chipped shed) · say no (coworker: “পিন ইনসুলেটরেই চলবে, ডিস্ক/শ্যাকল লাগবে না!” or the chipped-corner myth) | — (none: all slips, 3 slips fail) | built, 15 tests green |
| 6 | 3.2/do/1 | দূরবিনে টহল | spot (mark faulty insulators through binoculars) · choose (সব ঠিক / রিপোর্ট + reason) · say no (coworker) | climbing the live pole to look closer when an insulator has failed | built, tests green (19) |
| 7 | 3.3/learn | ক্রস-আর্ম ও ক্ল্যাম্প: লাইনের কঙ্কাল (picture board) | 5 picture rounds (arm · clamp · hold · bolt · climb) + reason chips + rust myth | — | built, 13/13 tests green, analyze clean |
| 8 | 3.3 কাজ 1 (`do_3_3_a`) | সঠিক ক্রস-আর্ম, সঠিক ক্ল্যাম্প | choose (docket line/formation → V / I / channel cross-arm; pole → wrap-around / bolted clamp; nuts with spring washer) · inspect (hand-slide reveals rust / bend) · say no (one part has no good one → replace; coworker "যেকোনো ক্ল্যাম্পেই হবে — শক্ত করে টাইট দিলেই চলবে" or "হালকা মরিচা — ওতে কিছু হয় না") | none — all slips | built, tests green (11) |
| 9 | 3.3 কাজ 2 | কঙ্কালের স্বাস্থ্য | inspect (look at arm/clamp/brace from below; tap-check bolts) · spot (rust, bent arm, slipped clamp, loose nut, missing spring washer) · order (washer → torque) · hands-on (hold-to-torque in the band) · say no (coworker: "একটু হেলে আছে, চলবে!") | 💀 climbing a rusty or bent cross-arm (also on his say-so) | built, 18/18 tests green, idle 9 rebuilds/s · 0 frames |
| 10 | 3.4/learn | ডিও (DO) ফিউজ ও হর্ন গ্যাপ ফিউজ: নীরব প্রহরী (picture board) | 5 picture rounds (three · operate · link · fit · horn) + why chips + the rival's myth (thick wire) | — | built, tests green |
| 11 | 3.4 কাজ 1 (`do_3_4_a`) | সঠিক ফিউজ তার | choose (read DTR plate → rated reel: 10A / 25A vs other rating, GI wire, thick copper) · inspect (wipe soot off top/bottom contacts) · do (pull link taut, tie) · say no (coworker: "মোটা তার জুড়ে দাও, বারবার উড়বে না!") · reason per DTR (rating / contacts / tie) | 💀 thick copper in the barrel (own pick or on his word) | built, tests green |
| 12 | `3.4/do/1` | হর্ন গ্যাপ ঠিক করো | order (শাটডাউন → PTW → টেস্ট → আর্থ) · inspect/spot (3 sets: blown wire + bent horn / carbon / thick wire) · choose (plate-rated fuse wire) · do (tie taut) · decide (holds / blows again) · say no (coworker) | 💀 climbing to the sets live (before শাটডাউন, or listening to "লাইন চালু থাকতেই ফিউজটা বদলে দাও"); 💀 climbing to tie again once the line is back on | built, tests green |
| 13 | `3.5/learn` | লাইটনিং অ্যারেস্টার: ছবির বোর্ড | 5 picture rounds (fit · work · body · earth · patrol) + why chips + myth | — | built, 13/13 tests green |
| 14 | `do_3_5_a` (`m3_la_patrol`) | এল এ-র খবর | spot · choose · say no | 💀 hand on the hanging / cut earth lead (his push or the choice) · 💀 climbing the live DTR to fix it | built, tests green |
| 15 | 3.5 কাজ 2 | কবচের মাটি | read (which of the R/Y/B LAs is bad: the earth lead hanging from a burst disconnector) · inspect + spot (follow the earth path LA terminals → pole → earth rod; tag one cut lead piece + one loose joint, dealt fresh) · order (ডকেট/শাটডাউন → HT tester proves dead → earth set → work; helmet + harness before work up the pole; then replace the LA and mend each fault in any order) · say no (coworker: "আর্থ তারটা একটু কাটা তো কী, বাকিটা ঠিক আছে — চলবে!" — listening is a slip) | 💀 hands on the LA (replacing it) before the shutdown | built, tests green (17) |
| 16 | 3.6/learn | DTR picture board (ডিস্ট্রিবিউশন ট্রান্সফরমার) | 5 picture rounds (side · gel · sign · tap · earth) + oil-leak myth | — | built, tests green |
| 17 | 3.6/do/1 | ডাক্তারের চোখে DTR | inspect (breather gel, oil gauge, tank leak, nameplate, listen) · spot (tap the parts from the ground) · choose (সব ঠিক / মেরামতের ডকেট / জরুরি শাটডাউন + reason) · say no (coworker: leak "চলবে" or "মাচায় উঠে দেখো") | climbing a live DTR's platform on the coworker's word | built, tests green |
| 18 | `3.6/do/1` (`do_3_6_b`) | অফ-লোড ট্যাপ | inspect/choose (voltmeter on the house's meter board → "ভোল্টেজ কম / ঠিক") · order (HT off = AB switch open + DO fuses dropped, LT lever off, তালা-ট্যাগ, টেস্টার 0 V, আর্থিং → dial: pin out → one notch → pin in → earth off, unlock, DO in, AB on, LT on → measure again) · say no (coworker: "চালু অবস্থাতেই এক ঘর ঘুরিয়ে দাও! শাটডাউনের ঝামেলা কে করে?") | a hand on the tap changer with HT live (incl. listening to him) · the earthing set on a live HT line | built, tests green (20) |
| 19 | `3.7/learn` | এলটি (LT) ডিস্ট্রিবিউশন বক্স/ফিডার পিলার: শেষ প্রবেশদ্বার (picture board) | 5 picture rounds (door · fuse · faults · balance · work) + why chips + rival myth (415 V "not dangerous") | door left open near a child, wire/strip in place of a fuse, uninsulated tool on live busbars, megger with fuses still in — as traps | built, 13/13 tests green |
| 20 | `do_3_7_a` (`m3_pillar_fuse`) | ফিউজ বদলাও ঠিকঠাক | order (PPE → door → cause → the docket's fuse → HRC → shut → lock → sign off) · inspect (read the docket F#/phase; spot the cause: hotspot / water / rat) · choose (tray: HRC ফিউজ vs তামার পাত vs মোটা তার) · say no (coworker: "তামার পাত লাগিয়ে দাও, আর উড়বে না!") | 💀 any work on a fuse without PPE (arc flash) · 💀 copper strip / thick wire in the fuse's place (also by listening to him) | built, 17 tests green |
| 21 | 3.7 কাজ 2 | পিলারের তল্লাশি | spot (outside) · inspect (inside, eyes only) · order (gloves → docket feeder OFF → fuses out → megger) · say no (coworker: "দরজা খোলা থাক, কাল আবার আসব") | megger leads on a cable whose SFU is still ON | built, tests green (15/15) |
| 22 | `3.8/learn` | সার্ভিস কেবিল ও এনার্জি মিটার: শেষ সংযোগ (picture board) | 5 picture rounds (cable · drip · box · fault · fast) + why chips + myth | — | built, tests green |
| 23 | 3.8 কাজ 1 (`do_3_8_a`) | শেষ মাইল | choose (cable by the docket's phase) · spot (cut insulation; the U drip loop) · order (bearer → cable → clips) · say no (coworker: "বিয়ারার লাগবে না, কেবিল টানটান করে বেঁধে দাও") | none (slips only) | built, tests green |
| 24 | `do_3_8_b` | গ্রাহকের ডাক | inspect (4 spots per call) · spot (the fault) · hands-on (flicker call: incoming OFF + insulated tool on the loose terminal) · choose (fast meter: explain politely, keep the seal; burnt: LT-line neutral, shutdown first) · say no (coworker: "সিলটা কেটে দেখে নাও" / "নিউট্রাল তো মরা, খালি হাতে ধরো") | bare hand on the neutral (deck or coworker); plain metal tool on the live meter terminals | built, tests green |
| 25 | 3.9/learn | গার্ড ওয়্যার ও ক্রেডল গার্ডিং (picture board) | 5 picture rounds (cross · catch · build · patrol · repair) + why chips + the rival's myth | — | built, tests green |
| 26 | 3.9 কাজ 1 (`do_3_9_a`) | জালের পাহারা | spot (guard faults: rust, snapped wire, sag, live wire too close) · inspect (the guard's earth at each pole: present, in its pipe; a sound crossing passed as sound) · say no (coworker: "গার্ডের তারে কারেন্ট নেই, হাত দিয়ে টেনে দেখো!") | 💀 a bare hand on the guard (listening to him: grabbing the hanging snapped guard wire) — card names the stolen earth when that crossing had it | built, tested (15/15) |
| 27 | 3.9 কাজ 2 (`do_3_9_b`) | জাল মেরামত | order (shutdown → PTW → test → earth, traffic held, then up; close: clearance → down → earth off → line clear) · spot (tag every fault on the cradle) · choose (the right fix per fault: tension / GI wire / spanner / pipe + earth lead; rope is the trap) · say no (coworker: "লাইন বন্ধ করার দরকার নেই, তাড়াতাড়ি সেরে নাও!") | 💀 up on the cradle with the line live (also by listening to him); 💀 the portable earth on a live line | built, tests green |
| 28 | 3.10/learn | লাইন ডায়াগ্রাম পড়া (ছবির বোর্ড) | 5 picture rounds (one · tx · iso · ring · field) + why chips + rival myth | — | built, 13/13 tests green |
| 29 | do_3_10_a | ম্যাপ দেখে বিচ্ছিন্ন | spot (docket feeder vs neighbour, not the DO fuse, the ring's other source) · order (CB → AB on each side; tester → earth → work) · say no (coworker "এলাকা আমার মুখস্থ, ম্যাপ লাগবে না") | 💀 isolator opened while its breaker is ON (on load) · 💀 work on a live section (backfeed through a ring closed today; nothing opened) · 💀 listening to the coworker | playable, 19 tests green (idle 9 rebuilds/s, 0 frames) |
| 30 | `m3/gate` | টেকনিশিয়ানের ডকেট: one shutdown job across feeder-7 | all five (choose · inspect · spot · order · say no) | planning isolation without the ring NO point (backfeed); thick wire as a DO fuse link; tap change with LT still on; copper strip for an HRC fuse; neutral with bare hands; touching the guard wire bare-handed | ✅ new (2026-11-11): 7 stations. (1) SLD: ring AB-1 + the NO point (dealt at the end or mid-feeder), wrong symbol = slip. (2) Patrol: judge pin insulator, clamp, strands, disc string, cross-arm; 3 dealt faulty (chip / slipped / cut strand / crack / rust or bent). (3) One DO dropped (dealt): open the other two, then a nameplate-rated link (thick wire 💀, GI wire / double rating = slips); LA dealt healthy / cracked / hanging disconnector lead. (4) DTR: silica gel (blue/pink) and oil (leak or not) judged, LT OFF, then the tap 3 → 2/4; the coworker pushes "HT DOs are open, skip the LT". (5) Feeder pillar: open, gloves + face shield, tester on the busbars, the blown HRC (dealt way/phase) → same-rating HRC (bigger = slip, copper strip 💀), tighten the blackened bolt (dealt), lock. (6) Service drop: twin/four core by the dealt connection, bearer wire, drip loop, gloved neutral. (7) Cradle guard: gloves, find the dealt fault (left/right earth lead cut, broken mesh wire), line back on. A reason deck after every station. Unlocks টেকনিশিয়ান (`unlockRank(3)`) and the badge লাইন চেনার জাদুকর |

## Owner decisions (flagged by the level agents — please confirm or change)

### Top decisions for Module 3 (director's summary — details per level below)
1. **Silica gel colours** (3.6 board, 3.6a, gate): lesson says used gel turns pink/white, film says orange → green. Levels use only blue/orange = good and pink/white = replace. Which is right for WBSEDCL stock?
2. **132 kV disc count** (3.2 board): lesson says 6+, film says 8–10. The card draws 8 and states no number.
3. **3.7a pillar fuse change has no switch-off step** — lesson 3.7 doesn't give one; player uses PPE + insulated fuse puller. Add an isolate-first step?
4. **3.4b horn gap**: trainee climbs with helmet + pole strap but no full harness; earth removal / PTW return before re-energising are not shown as steps.
5. **Fatal-vs-slip calls the agents made themselves**: 3.4a thick copper = fatal but an over-rated link = slip (lesson calls that "মারাত্মক ভুল"); 3.5a touching a hanging LA earth lead = fatal; 3.8b plain tool on live meter terminals = fatal; gate: leaving out the ring's NO point, copper strip for a fuse, bare-hand neutral even under shutdown = fatal.
6. **AAAC sleeve codes** (3.1b): AAAC sleeves are printed DOG / RABBIT / PANTHER like ACSR — confirm the field names.
7. **House-rule steps not in the lesson text** (shutdown → PTW → test → earth, harness, lock & tag) were applied in 3.1b, 3.3b, 3.4b, 3.5b, 3.6b, 3.9b, 3.10a from the brief / lesson 1.6.

### m3lb1
- The old-line round draws a portable earth on the pole (house rule: line work only after shutdown, PTW, test and earth). The lesson doesn't say this, and it isn't put into words.
- The cards show a sleeve's or drum's "code" as a shape (a triangle on both = a match). The art has no words, and the lesson names no real codes.
- The lesson's code names (Dog / Rabbit / Panther) and both advanced facts (skin effect, sag) are not on the board, except that the sag chart is used in round 5. The lesson doesn't say what the right cutter for ACSR is, so no card shows one.
- The worker on the copper card leans back and strain marks show on the drum, to suggest that copper is heavy.

### m3do1a
- **No deadly move.** The lesson gives no on-the-spot death in a store yard; wrong conductor / cut strand / guessing are slips (same call as Module 2's lug pick).
- **Bird-caged strands left out.** The concept seed mentioned bird-caging; lesson 3.1 and the film only support "one cut strand weakens the line". Only the cut strand is used.
- **Docket names the conductor.** Each job line says "চাই: ACSR/AAAC" plus a place. AAAC places are the lesson's own (উপকূল/নোনা হাওয়া, কারখানার ধোঁয়া); ACSR places are neutral (গ্রামের নতুন লাইন …) — the level never claims AAAC is wrong inland, only that it is not what the docket asks for.
- **Code names (Dog, Rabbit, Panther) left out.** The lesson names them but does not say which conductor each is; not shown on drums or docket.
- **Weathered blank drum tags** are a game premise (why the trainee must identify by the cut face/magnet; lesson: "দুইবার চেক… চুম্বক সাথে রাখবে… আন্দাজে ঢিল মারবে না").
- **Strand layouts drawn** 6/1 and 30/7 ACSR, 7 and 19 strand AAAC — drawing only, no counts printed or scored.
- **"Tell the store when no good drum"** is a process inference (lesson: ask a senior, don't guess); flagged.
- Joint sleeves (ACSR vs AAAC) deliberately left to কাজ 2 (`m3do1b`, `m3_conductor_joint`).
- Mistake-card `lessonPoint` for cut strand / guess / held = 3 (the "পার্থক্য / দুইবার চেক" point); the strand tip itself is a pro tip (the reader can't jump to tips).

### m3do1b
1. **Steps taken from other lessons:** 3.1 itself does not describe making a compression joint. These come from other lessons:
   - brushing the ends clean: lesson 2.3, "clean the conductor". 3.1 point 1 only says to check the ACSR steel for rust at a joint.
   - both ends fully into the sleeve: lesson 2.3, "insert fully".
   - pumping until the pressure valve clicks: lesson 2.9, pro tip 2.
2. **The film's wording, not the lesson's myth text:** the lesson's myth reality says a wrong connector causes "galvanic corrosion". The level follows the film fix instead: the joint goes loose and hot, and if the steel core is not gripped the line breaks and falls. A test also makes sure no line says galvanic.
3. **AAAC sleeves with animal code names:** the AAAC sleeves are printed "AAAC DOG / RABBIT / PANTHER". The lesson only says Dog, Rabbit and Panther are conductor code names and that you match the sleeve code to the conductor code. Please confirm AAAC uses the same names in the field. If not, the AAAC sleeve print and the tray tags need a different code.
4. **Left out (not in the sources):**
   - the compression die for the sleeve;
   - how many bites a sleeve takes and where;
   - the two-part ACSR sleeve (steel inner sleeve + aluminium outer);
   - cutting the conductor (the lesson says not to use an ordinary cutter on ACSR, but names no tool);
   - re-tensioning after the joint (pro tip 4).
5. **Shutdown, PTW and earthing are shown in the scene but are not moves:** earth leads run from all three phases to the spike, and the intro line says শাটডাউন + আর্থ.
6. **Ampacity myth:** "thicker carries more" (film line 13) is used as a wrong reason ("তার মোটা দেখালেই বেশি কারেন্ট নেয়, ব্যস").
7. **Scoring:** a make-round pays 15 + 5 when the round had no slip; the tray pays 15 + 5 when no good joint was set aside. Same shape as `m2_crimp_steps`, existing functions only. Quick bonus under 60 s.
8. **Lesson points (0-based):** cards point to point 3 ("পার্থক্য বুঝবে কী করে") or point 1 (ACSR rust, used for the brush card). The cut-strand card has no point, because pro tip 2 is not a point.

### m3lb2
- **132 kV disc count**: the lesson says "৬টা বা তার বেশি", the film says "আট-দশটি". The card draws 8 discs (true for both). No count appears in any text; the reject line says only "এত লম্বা মালা মানে… 132 কেভি".
- **Cleaning card (`clean/wash`)**: the label says "শাটডাউন, আর্থ দিয়ে ইনসুলেটর পরিষ্কার" and the art draws an earth clamp on the conductor. The lesson only says "routine insulator washing" and "clean it". Shutdown and earthing come from the house rule, not the lesson.
- **`look/lean` reject** paraphrases the lesson's "যে পোলে হাত দিত, সে ওখানেই শেষ". No procedure (reporting, etc.) is added.
- **The 33 kV string question**: the lesson's pro tip ties 3 discs to 33 kV. The lesson also says pin insulators serve straight lines up to 33 kV, so the disc round avoids pin insulators to keep it unambiguous.
- **Second myth (toughened glass shatters visibly; a hidden crack in porcelain is worse)** is not used. It could feed a later level.
- **Badge**: uses the module badge "লাইন চেনার জাদুকর" (the lesson's own badge is "ইনসুলেটর এক্সপার্ট (Guardian of the Line)"), following the 2.8 board.
- `ladderIndex: 42` in the test is a placeholder (the runner's display index). The director should set the real one when registering.

### m3do2a
- **132 kV not played.** The lesson says “৬টা বা তার বেশি” discs, the reviewed film says 8–10. No distribution pole carries it, so it's left out. Only 11 kV = 1 disc and 33 kV = 3 discs are used.
- **LT danger board reads “440 V”.** That's the usual Indian board marking, but lesson 3.2 doesn't state an LT voltage. Change `M3InsulatorPickSpot.plate` if you want “415 V” or plain “LT”.
- **No disc string at the straight-run pole.** The lesson gives discs for “tension or suspension” at 11 kV and above, but gives pin for straight lines up to 33 kV. To avoid contradicting either, discs never appear on the straight pole.
- **Too many discs (3 on 11 kV) is never offered.** The lesson doesn't call it a fault.
- **No pin voltage classes (11 kV pin vs 33 kV pin).** The lesson doesn't give them.
- **Shackle at an HT dead end is a slip.** The basis is the lesson's “এলটি লাইনে এর ব্যবহার বেশি” plus “disc at 11 kV+ tension points”.
- **Disc at an LT dead end is a slip.** The basis is “shackle: LT angle · dead end” and “disc: 11 kV or above”.
- **No deadly moves.** The line is new and not yet charged; the lesson frames a broken or wrong insulator as a fault that leaks, breaks or flashes over later.
- **Angle (turning) poles are only named in text, not drawn.** The side view shows straight and dead-end only.
- Insulators are drawn as brown-glazed porcelain; discs are grey/white.

### m3do2b
- The "patrol + report" framing is ours. The lesson says: look from below (binoculars or eye) before climbing — broken?
  black marks? — replace a broken one, clean bird droppings, wash salt. It does not name a report/shutdown procedure;
  the level only says "রিপোর্ট" and the coworker's right card says climbing is for শাটডাউন.
- Black marks (কালচে দাগ) as a reportable fault is from point 1's daily check; the lesson does not say what they mean or
  how they are fixed, so the reasons only say "বিপদের চিহ্ন, রিপোর্ট নিয়ম".
- The deadly climb rests on point 1 ("ইনসুলেটর না থাকলে কারেন্ট পোল হয়ে মাটিতে নামত, আর যে পোলে হাত দিত, সে ওখানেই
  শেষ") and on the brief's rule (line work only after shutdown, PTW, test, earth).
- Pole heads: three discs = 33 kV (pro tip 1), pin up to 33 kV shown at 11 kV, shackles on LT with D-irons (point 3).
  Faults are drawn on brown-glazed porcelain (common in the field); the lesson does not specify colour.
- Polymer is used only as a pin-type decoy (pro tip 3 says polymer replaces porcelain in many places; it does not say
  which types).
- Bird / salt / shattered-glass mistakes have no lesson point (pro tips / myths) → their card has no "পাঠে দেখুন" point.

### m3lb3
- `bolt/torque` card draws a torque wrench with a dial; the lesson only says "apply the right torque" — the
  tool itself is inferred (label: "টর্ক রেঞ্চে সঠিক টর্কে টাইট").
- `climb` round: "never hook the harness to / stand on a BENT cross-arm" comes from the film script (the lesson
  says rusty only). The safe cards show a pole strap round the pole + tools in a bag ("you and your tools
  secured" — lesson safety tip); the ladder and the bag are drawing choices.
- `climb` cards draw a portable earth set on the line (house rule: shutdown → test → earth); it is not in the
  lesson and is not put into words.
- `arm/bent` reject ends "এর ওপর ভর নয়" — from the film ("never stand on or hook to a rusty or bent arm").
- Left out: V vs I cross-arm formations (LT vertical / horizontal) and the 100x50 mm HT channel size — hard to
  draw truthfully at card size; anti-theft nuts (recognition only, no safe/unsafe act); moment of inertia.
- The lesson's second myth (any clamp on any pole) is the `clamp` round and a wrong chip there.
- Ladder index in the widget test is `0` (the runner only uses it for the record); set the real one if needed.

### m3do3a
- The concept seed said "clamp **size** that matches the pole". The lesson only gives the clamp **type** by pole
  (PCC → wrap-around; rail / H-beam → nut-bolt clamp) — no clamp sizes, so the level matches type only. The
  coworker's line was adapted from "একটু বড় ক্ল্যাম্প…" to "যেকোনো ক্ল্যাম্পেই হবে — শক্ত করে টাইট দিলেই চলবে"
  (the lesson's myth + its over-torque tip).
- Cross-arm types follow the lesson exactly (LT vertical → V, LT horizontal → I, HT → channel). The "100x50 mm"
  example is not used on screen. The drawn V is a shallow V with a pole plate — an illustration, please check it
  looks like the WBSEDCL V cross-arm.
- No deadly move: at the store a wrong/rusty part is a slip. The lesson's "never stand on / anchor to a rusty
  cross-arm" belongs on a climbing level.
- Spring washer as a must comes from the lesson's pro tip and the film ("স্প্রিং ওয়াশার মাস্ট"); left out: brace,
  tension vs suspension clamps, anti-theft nuts (not this level's job).
- The wrong reason "রং করে দিলেই তো ঠিক চলে যাবে" (paint over rust) is a field myth, not from the lesson — it is
  only ever a wrong option.
- Environment: at ~13:28 `~/Desktop` was emptied and relinked; the real tree is now under
  `~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/…`. The worktree's `.git` file still points to
  `~/Desktop/…/slm_flutter/.git/worktrees/m3do3a`, so I ran git with `GIT_DIR`/`GIT_WORK_TREE` set to the iCloud
  paths, and flutter through a slot in the iCloud `.locks` (the `~/Desktop` `flk.sh` path no longer exists).

### m3do3b
- The line is shown shut down with an earth set (the project's line-work rule, BRIEF_M34); lesson 3.3 itself does
  not mention shutdown/earthing before hardware work. Its safety tip ("কোনো হার্ডওয়্যার খোলার আগে নিশ্চিত করুন যে আপনি
  এবং আপনার সরঞ্জামগুলো সুরক্ষিত") is shown only as the trainee's pole strap in the close view — not a scored step.
- Deadly only for the rusty arm (lesson point 4 safety tip) and the bent arm (film S4_03). A slipped clamp and a rusty
  clamp are reported; climbing them is a slip, not deadly (the lesson does not say it kills).
- The torque wrench dial has a green band but no number: the lesson gives no torque values (pro tip 2 only says too
  much snaps the bolt, too little leaves it loose).
- Three bolts at the arm–clamp joint (two clamp bolts, one brace bolt) and an 11 kV-style channel arm with three pin
  insulators on a PCC pole with a wrap-around clamp are our staging (point 2: PCC → wrap-around clamp).
- The loose nut "chatters" (sound + marks) when the clamp is looked at from the ground (pro tip 1, film S4_04).
- Binoculars (in the concept seed) are left out: neither the lesson nor the film mentions them; the "look from below"
  close-up is the trainee's eye.
- A report where nothing is wrong (or before looking at the faulty part) is not scored; the guide says the rule and
  the pole stays (as m2_dead_test).

### m3lb4
- **operate / `under` trap**: "standing right under the barrel" is our picture of a wrong body position. The lesson
  only says "হট স্টিক ব্যবহার করা এবং সঠিক শারীরিক অবস্থান বজায় রাখা অপরিহার্য". The reject line adds only that the
  opened barrel drops down by gravity (lesson: "মাধ্যাকর্ষণের টানে নিচে ঝুলে পড়ে").
- **operate / `rod` trap**: "an ordinary steel rod instead of a hot stick" stretches "a hot stick is essential"; the
  reject line says only that.
- **operate / `bang` trap**: "dropping the stick in fright at the bang" is built on the film's "ছোট বিস্ফোরণের শব্দে
  ভয় পাবেন না" and the lesson's expulsion-gas pro tip.
- **horn / `parallel` trap**: horns that stay parallel are the reverse of the lesson's "the gap widens, so the arc
  goes out". This is drawn from the lesson's statement but is not stated in it.
- **three**: the walking-away traps show the worker leaving. The lesson says only that the other two phases' fuses
  are opened too ("দুটি নয়, তিনটিই খুলুন"). Nothing is said or drawn about shutdown, PTW or earthing for later
  transformer work.
- Left out: TCC curves and interrupting capacity (advanced section). No amp ratings are named (only "10A, 25A" as
  examples in the lesson). K = fast-acting and T = slow-blow appear only as a wrong chip with the two swapped.
- First prompt shortened to "থ্রি-ফেজের একটা ডিও ফিউজ উড়েছে — এবার কী করবেন?" to stay under the idle-rebuild
  guard (< 20/s).

### m3do4a
1. **Ratings:** neither the lesson nor the film gives a kVA-to-amp table, so the plate shows only the amp rating ("DO FUSE LINK 10 A"). The only figures used are the lesson's own examples, 10A and 25A. No kVA is shown anywhere.
2. **K / T type** (fast / slow-blow) is left out. The lesson says the choice "depends on the fault type" but never says which one a DTR uses.
3. **Cracked tube / burnt barrel** (from the concept seed) is left out because the lesson doesn't mention it. The barrel checks are only those in pro tips 3 and 4: soot or carbon on the top and bottom contacts, and tying the link at the right tension. Over-tightening isn't modelled because the sources don't cover it.
4. **Deadly choice:** making thick copper deadly is inferred from the myth-buster ("আত্মহত্যার সামিল"; the film says "জীবন্ত পুড়িয়ে ফেলার সামিল"). The consequence shown is the transformer burning. A higher-rated *real* link is a slip, even though the lesson calls "thicker than rating" a "মারাত্মক ভুল". Please confirm this split.
5. "Open all three fuses when one blows" (pro tip 1) isn't used here; it fits a later কাজ better.
6. The scene assumes shutdown is done: the barrels are already down at the van, and nobody is on the pole.
7. `lessonPoint`: 3 for the rating mistakes (point ৪ "সঠিক ফিউজ এলিমেন্ট নির্বাচন"); 1 for the barrel mistakes (point ২, the DO fuse). The contact and tie rules come from the pro tips, which have no point index of their own.

### m3do4b
- **Horn gap size / alignment:** lesson 3.4 gives no gap measurement and no setting procedure. Nothing is measured.
  The "bent horn" fault (the top gap no longer wider than the bottom) is inferred from point 3's mechanism (the arc
  rises and goes out as the horns' distance grows). Owner: confirm, or give the field rule for the gap.
- **Carbon on a horn terminal:** pro tip 3 (dirt/carbon → sparking) is written for DO fuse contacts; applied here to
  the horn gap terminals.
- **Safety order শাটডাউন → PTW → টেস্ট → আর্থ** and "climb only after all four" come from the module's safety rules
  (brief), not lesson 3.4's text. The restore (earth off, PTW back) before charging is left out of the play entirely
  (the earthing set just disappears in ঘ); the guide only says "লাইন চালু হচ্ছে".
- **The bang:** the film's "ওড়ার সময় ছোট বিস্ফোরণের শব্দ" is said of the DO fuse (boric acid gas); the level plays
  the flash + bang + the lesson's rising arc when the horn gap fuse blows again, and the guide's line does not
  mention boric acid.
- **Plate ratings 10A / 25A** are the lesson's own examples (point 4); the bag holds the plate's rating, the other
  example rating (thicker or thinner) and plain GI wire. No mapping from transformer size to rating is shown.
- "Tie at the right tension" is pro tip 4 (written for the DO barrel's fuse link) — a loose tie is a slip; there is no
  over-tight failure (the source does not give one).
- Harness: the trainee up the pole wears the helmet (LinemanFigure) and a painted pole strap; the figure has no
  full-body harness drawing.
- His push in ঘ uses the same line as in ক ("লাইন চালু থাকতেই ফিউজটা বদলে দাও!") — true in both moments.

### m3lb5
- Showing both porcelain and polymer LAs as right is my choice. The lesson only says polymer is lighter, breaks less and does better in polluted areas, so porcelain is never shown as wrong in itself.
- Patrol round: the lesson doesn't say what to do after spotting a bad LA (report, shutdown, replace), so the board only rewards *noticing*. Nothing about replacement is in words or art.
- The "work" round's 'leak' trap (current through the LA at normal voltage) is drawn from the lesson's "at normal voltage no current flows". The lesson never describes such a fault.
- The LA neutral point (pro tip 3, "in some cases") and insulation coordination / knee-point voltage (advanced section) are left out.
- The 'far' card puts the LAs on a pole further down the line. The lesson gives no distance figure, and none is shown.
- The patrol worker stands on the ground and only looks (helmet, gloves); nobody climbs or touches the structure.

### m3do5a
- **Inferred (not in the lesson / film text):** "never touch a hanging earth lead — the LA above is on the line, a
  failed LA's lead may be live" (the deadly), and the right action "write the DTR number and phase down from a
  distance and report". The lesson only says a hanging earth lead proves the LA has failed and the line keeps running;
  the film: "মাটিতে ঝুলে থাকা তার দেখলেই বুঝবেন এল এ খারাপ হয়ে গেছে!". Please confirm the rule wording.
- "Climb only after shutdown, permit (PTW), test and earth" is Module 1's rule, used for the climb-live deadly
  (that mistake has no "পাঠে দেখুন": the 3.5 lesson does not teach it).
- Drawing choices: each LA has its own earth lead run down a pole to its own earth rod (the lesson: "নিচের টার্মিনাল
  থেকে যে আর্থিং তারটি নেমে গেছে"); real DTRs often bond the three LA earths — a simplification for a readable scene.
  A crack or a burst is dealt only on porcelain housings (pro tip 4: polymer "সহজে ফাটে না").
- Who the report goes to (office / SDO / control room) is left general ("অফিসে জানাই") — the lesson does not say.

### m3do5b
- **Not in lesson 3.5 or its film, so left out** (the concept seed asked for them): a target earth-resistance value
  (the lesson only says "যত কম ওহম তত ভালো"), using an earth tester, a separate LA earth pit, and lead routing
  (direct / short / no sharp bends). Nothing in the level is scored on a number.
- The seed's coworker line ("এল এ-র তার বডির আর্থে জুড়ে দাও, একই তো") was replaced with the lesson's own myth 2
  ("আর্থিং তারটি একটু কাটা থাকলেও চলে…"), because the lesson does not cover a separate earth for the LA.
- Listening to him is a **slip**, not deadly: the lesson's consequence is the surge going through the transformer
  (damage to equipment), not to the worker.
- The repair order (ডকেট/শাটডাউন → test → earth → work, helmet + harness up the pole) is the project's line-work
  rule (BRIEF_M34), not lesson 3.5 text. Those mistake cards have no "পাঠে দেখুন" (lessonPoint null).
- The only deadly move: touching the LA (replacing it) before the shutdown. The LA sits on the 11 kV line (lesson
  point 2: "স্বাভাবিক সিস্টেম ভোল্টেজে (যেমন ১১ কেভি)"). After the shutdown, skipping the test or the earth is a slip
  (as m2_megger_prep). Earthing or testing before the docket is a slip too.
- The bad LA is shown only by the burst disconnector and its hanging lead (point 3). A cracked or burnt housing is
  also in the lesson, but it is not dealt (it would need a second reason library).
- Staging: a front view of a DP structure, three DO fuses opened by the shutdown, LA leads joined and run down the
  left pole to one earth rod. The mended rod clamp is ground work (no harness); every other fix is up the pole.
- Tapping a healthy joint in the inspect round costs nothing (the guide says it is fine). The last fault waits for
  the coworker's moment, so he always comes once.

### m3lb6
- `gel/empty` (an empty breather) is inferred: the lesson says the gel absorbs the moisture, never shows an empty breather.
- Lesson text: spent gel turns pink or white. Film: blue→pink, orange→**green**. Only pink/white used; green left out.
- Spent gel is drawn changing colour from the bottom up (air enters through the oil cup) — a drawing choice, not in the lesson.
- "Tap changer only with HT and LT both off" is from the film script only (the lesson says only "off-load").
- The tap cards draw the HT side open as DO fuses dropped — the lesson does not name the HT isolating device.
- The DTR is drawn plinth-mounted at ground level (worker on the ground, no climbing); pole-mounted DTRs are not shown.
- Left out: vector group / parallel running (Dyn11), Buchholz relay, nameplate reading, "body abnormally hot by hand touch" (not depicted — touching a live tank is not something to show).

### m3do6a
- The three-way call and which sign goes where are ours: the lesson names the signs (gel colour, oil level, leak,
  sound) and says a rattle means a serious fault inside, but not who is called. Our mapping: rattle → urgent
  shutdown; leak / low oil → repair docket (urgent also accepted — the film says a leak can burn the DTR); spent gel
  alone → repair docket (urgent there is an over-call: not scored, the guide explains). Please confirm.
- Over-calls (a docket on a healthy DTR, urgent for the gel alone) are not scored — the guide states the rule and
  the DTR stays.
- The nameplate kVA values (25 / 63 / 100 / 160 / 250) and the oil gauge's MIN / MAX dial are ours (not in the lesson).
  The nameplate shows "HV 11000 V  LV 415 V  Dyn11" as in the lesson (real plates often say 433 V).
- The lesson's "feel the tank by hand for abnormal heat" is left out (the film drops it too); nobody touches a live
  DTR in this level.
- The deadly move (climbing the platform of a live DTR) comes only through the coworker's climb push, which is dealt
  in half the plays (the other half he pushes the leak line from the brief). The mistake card says: check-up from
  the ground; to go up: shutdown, PTW, test and earth first (project rule, not the 3.6 lesson text).
- Silica gel: blue / orange good; blue → pink, orange → green spent (the film's fix of the lesson's "pink or white").
- No recorded hum / rattle sound yet: the rattle uses `sounds/learn/knock_hollow.wav`, the hum is silent; the
  close-up shows the waveform and "গুনগুন…" / "খটখট… গরগর!".

### m3do6b
- **Sources are thin on procedure.** Lesson 3.6 only has pro tip 2 (an off-load tap changer adjusts output voltage). The procedure comes from the film's rule 1 line ("…শুধুমাত্র ট্রান্সফরমার এইচ টি ও এল টি দুদিক থেকে বন্ধ করে") and its animation (AB open + DO dropped, LT lever off, padlock on the AB handle, portable earthing set, pin out → one notch → pin in, house meter back to normal).
- **From the module's safety rules / the brief, not lesson 3.6:** the danger tag with the lock, proving dead with a tester before earthing, earthing before touching, earth off before switching back on, measuring again after the change. Earthing a live line is made deadly (second deadly) so a wrong practice never looks rewarded.
- **Voltages are from the film's meter animation** (~200 V low, ~236 V right; game: 198–204 / 234–238). No threshold is in the sources; the misread card says "240 V-এর কাছাকাছি = ঠিক; অনেক কম (যেমন 200 V) = কম" based on the lesson's 415/240 V.
- **Which way to turn is not in the sources**, so the handle only ever moves one notch in one direction (as in the film, 3 → 4). No direction choice, no tap-ratio claims.
- **"One notch" as a rule** (a second notch = slip) follows the seed and the film; flag if the owner wants free turning.
- **The right-voltage site** (measure → right → don't touch the tap) is a game premise to make the reading matter.
- **Order of HT vs LT switching is not enforced** (sources don't give one; real practice often takes LT off first).
- **No climbing shown:** the tap is worked in a close-up card; the trainee stays on the ground. No harness/helmet beat for the platform.
- **lessonPoint:** misread → 0 (415/240 V), not-earthed → 1 (point 1's safety tip: earth before working on the tank); the rest null (the tap changer is a pro tip, the reader can't jump to tips).
- Corner guide's speech bubble sits over the lower left pole; the AB handle was raised to stay clear of it.

### m3lb7
- **Myth digits:** the rival's line is lesson 3.7's first myth word for word, except "৪১৫" is written "415" because on-screen text uses English digits.
- **`work` round, PPE card:** the lesson says inside the pillar is "as dangerous as a live panel" and requires full PPE + insulated tools. It does not say whether the incomer is isolated, so the card does not show that. The outgoing fuses are drawn pulled out (in a tray), which matches the film's "line off, fuses out" rule for meggering. The busbars are still drawn as live, and one wrong why-chip says "fuses out ⇒ busbars dead" (inferred: busbars are fed by the incomer).
- **`balance` round:** the pictures are schematic (three phase rows of houses, with a new house joined to one row). The safe act is "join the phase with the least load" (pro tip 3). The trap "keep replacing the fuse on the heavy phase" is inferred from "an overloaded phase blows its fuse again and again". The rejection text does not prescribe a fix beyond what the lesson says. "Neutral heats up" comes from the film script (S3_03); the lesson only says current flows in the neutral.
- **`door` round:** "check the door seal and the cable entry" is the lesson's daily check, and it is shown as a safe card next to "lock the door".
- **Fuse round:** "SFU" is shown as a steel box with a window onto the HRC cartridges and a handle. This is a generic look, not a specific make.
- **Left out:** diversity factor (an engineering fact, nothing a lineman acts on); myth 2 (wire/strip instead of a fuse) is not used as the rival's myth but appears as two traps in the `fuse` round.
- `ladderIndex: 37` in the test is a placeholder (only used for the runner page in the widget test).

### m3do7a
1. **Cause before the new fuse** — the lesson lists the causes (hotspot, water, rodents, unbalance) and that a fuse
   "may blow again and again" on unbalance; "find the cause first, else the new fuse blows too" is inferred. Booked as
   a slip (`no-cause`), not deadly.
2. **How the cause is mended is not in the lesson** — once spotted, the level marks it put right
   ("কারণটা সারানো হলো") and the scorch / water / rat disappears. No repair method is taught.
3. **Fuse puller** — the lesson says "insulated tools"; the named tool "ফিউজ পুলার" is from the brief, not the lesson.
4. **Same rating** — not in the sources; the level never mentions a rating number. The tray offers "HRC ফিউজ" only
   against the two bodges; the new cartridge looks the same as the old.
5. **Copper strip / thick wire = deadly** — per the brief. The lesson's consequence is "the cable or transformer burns"
   (film: "পুড়ে ছাই"); the deadly card says exactly that (no claim that it kills the lineman).
6. **PPE** — one button "পিপিই" (full PPE). The arc face shield is not named in the lesson, so it is not named on screen;
   the mistake art shows a face shield + gloves as "full PPE".
7. **No isolation step** — the lesson treats the pillar as a live panel (full PPE + insulated tools) and does not give a
   switching-off procedure for fuse replacement; the level does not add one. Owner may want a "feeder load off" step.
8. **Phase unbalance** — a lesson cause that cannot be seen in the box; left out of the spot move.
9. **Door mistakes' "পাঠে দেখুন"** point at point 1 (index 0, its daily check: the door shut properly), since pro tip 1
   (lock the door) is not a lesson point.
10. Docket line "F2 · Y ফেজে আলো নেই" — the feeder/phase naming (F1–F3, R/Y/B) is the scene's own labelling.

### m3do7b
- **Deadly = megger on a live cable** is inferred: the lesson's myth 1 (415 V kills; arc flash) + the film line
  "লাইন বন্ধ করে ফিউজ খুলে … মেগারিং". The lesson itself does not name this as a death.
- **"Switch OFF before pulling the fuses"** (slip) comes from the film's word order ("লাইন বন্ধ করে ফিউজ খুলে"),
  not stated as a rule in the lesson.
- **Gloves before a hand in the box**: from the lesson's safety tip (full PPE + insulated tools inside the
  pillar) and film line 17; the game shows only the gloves as the PPE step (helmet is on the figure).
- **Wrong feeder** slip: the lesson says each outgoing feeder is switched/fused separately; "only the docket's
  feeder" is our job framing.
- **Left out (not in the sources):** thermal camera view; where the megger's E lead goes (drawn on the earthing
  terminal, not scored); the IR value / pass threshold (the needle just reads, no number); putting the fuses back
  and switching ON after the test; neutral-link / earth-terminal faults (they are decoys, always fine); phase
  unbalance (no visual sign to spot).
- The outside "no lock" fault also shows the door not shut (lesson daily check: "দরজা ঠিকমতো বন্ধ আছে কিনা").

### m3lb8
- **Rival myth choice:** the lesson has two myths. The rival says the second (neutral is dead, hold it bare-handed) because it is
  life-safety; the first (a fast meter = a bad meter) became picture round `fast`. Module 2 boards used the first myth.
- **Gloves:** the lesson asks only for insulated tools at the meter box; the worker wears rubber gloves in every card (house rule),
  and myth chip m3 says "নিউট্রাল তারও খালি হাতে নয়, গ্লাভস পরে ধরুন" (inferred from the myth's reality, not a quote).
- **Supply off for tightening:** round `fault` safe card "সাপ্লাই বন্ধে ঢিলা টার্মিনাল টাইট" — the lesson says the incoming must be OFF
  for meter-box work (safety_tip); the tightening itself is inferred from "loose connection" as the fault.
- **Earth-leakage card:** drawn as a clamp meter round the house cable below the meter. The lesson only says "check the house load /
  earth leakage" — how to check is not in the sources; the picture is generic.
- **Drip "side" card:** the second safe drip picture is the same loop mirrored (from the right) — the lesson has only one drip-loop fact.
- **Left out:** kWh definition and smart-meter facts (advanced section) — no picture-able act; twin-core / four-core appears only as a
  why chip.
- The worker stands on the ground in all street cards and never touches the live drop cable (pointing only).

- **"কোম্পানি" avoided:** the house-word test bans the substring "পানি", which sits inside "কোম্পানি". So the seal is "মিটারের সিল"
  and the pro tip reads "আপনিই বিদ্যুৎ সংস্থার মুখ" (lesson: "আপনিই কোম্পানির মুখ").
- **Idle guard:** with the art registered in pubspec, the first run measured exactly 20.0 rebuilds/s (limit < 20). Shortening the
  intro and round-1 prompt brought it under (green twice). The 2.8 board may sit at the same edge — worth a look.
- Tests: `test/learn_board_38_test.dart` 13/13 green **with** `assets/game/art/m3_board38/` in pubspec (add it when merging).

### m3do8a
- **No deadly move.** The level is a new connection under shutdown + PTW + earth (docket; earth set drawn on the LT
  pole), so nothing in it is lethal by the sources. The lesson's deadly myth (bare-handed neutral) appears only as a
  wrong reason card ("নিউট্রালে কারেন্ট নেই, তাই কোনো চিন্তা নেই").
- The pole end of the service cable is drawn already joined to the LT line; making that termination is not a step
  (the sources give no procedure for it).
- Meter seal, insulated tools at the meter box and "incoming supply off" (lesson point 2 / pro tip 3) are left out of
  this level (could be কাজ 2).
- No cable sizes, clip spacing, sag or ground clearance anywhere — the sources give none. Drums are tagged only
  টুইন-কোর / ফোর-কোর; core colours drawn as R/Y/B/black (four-core) and red/black (twin) — a drawing convention,
  not from the lesson.
- The drip-loop mistake has no lesson point (pro tip 1), so "পাঠে দেখুন" opens the lesson from its start; the other
  four point to lesson point 0 (service cable).
- The coworker comes as station খ starts; the tool tray appears only after he has been answered (so every play
  meets him).
- The coworker's exit line reuses the recorded clip "হুঁ! যা খুশি করুন।".

### m3do8b
- **How the incoming supply is switched off** is not in the lesson ("নিশ্চিত করুন মিটারের ইনকামিং সাপ্লাই বন্ধ আছে" only). The level uses a HUD toggle "ইনকামিং ON/OFF"; no device (cut-out, pole fuse) is drawn.
- **The meter terminal and the seal:** a loose terminal is tightened without any seal step. The lesson says to try to work without breaking the seal and, if needed, arrange a new seal. Whether the terminal cover is sealed is not modelled.
- **Neutral repair:** the right action reads "শাটডাউন, টেস্ট, আর্থ" / "শাটডাউনে সারাই". That is the brief's line-work rule; the lesson gives no repair procedure. PTW is not named in the option text (length).
- **The deadly "plain metal tool on the live meter terminals"** follows from the lesson's "লাইভ প্যানেল" + insulated-tools rule. It is my call that it is deadly rather than a slip.
- **Fast meter causes** (an old fridge, an earth leakage) are from myth 1. What the customer should do about the leakage (an electrician) is left out; the trainee only explains politely.
- **Not modelled:** the service cable's own faults (insulation damage, no drip loop). The cable spot always shows "কেবিল অক্ষত, টান বিয়ারারে" (it teaches lesson point 1 but is never the fault).

### m3lb9
- `catch/torn` reject says a torn net "cannot hold the wire" — inferred from the lesson's "গার্ডিং একটি সম্মিলিত সিস্টেম… ছেঁড়া তার পুরো কাঠামোর যান্ত্রিক শক্তিকে দুর্বল করে". 
- `catch/noearth`: the lesson says poor earthing makes the guard lose its function and the whole net can turn live; the picture also shows the breaker NOT tripped (implied by no earth path; not stated in words).
- The breaker inset (lever up + red lamp lit = line on; lever down + lamp dark = tripped) is a drawing convention, not lesson content.
- `repair`: the portable earth set, cones and flagman are drawings of "শাটডাউন ও আর্থ" and "ট্র্যাফিক নিয়ন্ত্রণ"; the worker on the pole wears helmet + full-body harness + gloves (house rule; the lesson only says "সমস্ত সুরক্ষা নিয়ম মেনে চলা"). PTW is not mentioned (the lesson does not).
- Left out on purpose: the ground-clearance numbers (LT 5.8 m / HT 6.1 m, lesson's advanced facts; not in the film), "several thousand amperes" and "milliseconds" figures.
- The lesson's second myth (one or two broken guard wires don't matter) is used as the `patrol/broken` trap and a why chip, not as the rival's myth.

### m3do9a
- **Clearance figures:** no minimum vertical clearance (line ↔ guard) is used — the lesson gives none; the "too
  close" fault is drawn (conductors sagging down near the net). Ground clearance (5.8 m LT / 6.1 m HT, advanced
  facts) is not measured in the level.
- **Earth lead out of its pipe** is treated as a fault to report (pro tip 4: run it through a pipe against theft).
  The lesson calls the pipe "a good practice", not a rule — owner to confirm it should count as a fault.
- **Sagging guard:** the lesson says a sagging guard reduces the clearance to the live conductor and can swing
  into it in wind; drawn as the net drooping. Kept to the lesson's wording.
- **Touching is always deadly** (safety tip of point 4: treat the guard as live; myth 1). The card for a crossing
  whose earth was stolen says so; otherwise the general "always treat it as live".
- What a patroller does about a hanging guard wire beyond reporting it (keeping people away, traffic control)
  is not in the lesson for patrol — left out.
- The line's look (three conductors on pin insulators, 11 kV-style) and the danger plate are ours.
- Mistake art: code-drawn SVGs (`assets/game/art/m3_guard_patrol/*.svg`), wrong left / right right.

### m3do9b
- **PTW / test / earth / line-clear order** comes from lesson 1.6 (PTW golden steps; line clear: all men down, all
  equipment off) and the module's safety rule, not lesson 3.9's text. Lesson 3.9 supports only "treat the guarding as
  live until the line above is fully off and earthed" (point 4 safety tip) and "control the traffic below" (point 2).
  These mistakes carry no lesson point or the nearest one.
- **The earth lead in a pipe**: the lesson calls it "a good practice" (pro tip 4); the film makes it one of its four
  rules. I made a bare lead a *slip*. The lesson says "পাইপ", not GI pipe — the button says only "পাইপ".
- **Re-tensioning tool** is not named in the sources, so the button is just "টান" (no come-along / tensioner named).
- **Clearance check** has no number: the lesson gives no guard-to-conductor distance (only ground clearance 5.8 m LT
  / 6.1 m HT, not used). The check shows a green arrow and tick.
- **Rope as the lacing trap**: the sources say the net is GI wire and joints (binding wire / clamps) must be strong;
  "not a rope" is my inference from that.
- Helmet + harness are drawn (the trainee's helmet; a pole strap when up), not a scored step.
- Fault tap areas are 28 design px wide for the lacing / clamp (≈ 30 dp, under 48 dp); the nearest fault wins.
- The coworker's right/wrong cards and the line come from the concept seed; he walks in when the shutdown is asked
  for (so the idle start screen stays quiet and he comes every play).

### m3lb10
- **ring round:** the safe cards circle the switches on BOTH ends of the work section. The lesson says power on a ring or interconnected feeder may come from the opposite side, and to mark the work area and the isolation points (plural) before work. "Both ends" is inferred from those two points.
- **field / mark card:** the lineman marks the diagram with a pencil at the van. The lesson says to keep an SLD copy in the vehicle and to mark the work area and isolation points; the pencil mark is how the card shows that.
- **Earthing symbol** is drawn in the standard way (longest line at the top). The lesson's words ("ছোট থেকে বড় হওয়া") are ambiguous on the order.
- **Transformer symbol** is drawn as two coil windings with a gap, following the lesson's "two coils that do not touch", not the IEC two-circle symbol.
- **Left out:** the digital colour-coded SLD in control rooms (the film says "still verify with a tester"), geographic layouts, reading top-to-bottom, the rating details (kV / kVA / A / sq mm / feeder name / NO-NC). They can't be drawn without words, so the board has no cards for them.
- `ladderIndex: 0` is used in the widget test (the value doesn't matter to the board).

### m3do10a
- **Not from lesson 3.10's text (module safety rules / brief):** a tag on every point opened; lock-and-tag on
  the NO tie so nobody closes it (the lesson only says backfeed can come the other way on a ring); the earth
  after proving dead and "work only after earth". The mistake cards for test/earth carry no lesson point.
- **"Test with a tester before work"** comes from the film script (3.10 line 15), not the lesson text.
- **ON red / OFF green** on the digital SLD is my choice (common SCADA convention); the lesson only says the
  digital SLD shows ON/OFF by colour. Only switch states are coloured — line energisation is not, so the
  player has to trace the sources.
- **"NO point closed today"** (load transfer) is my reading of the lesson's ring/backfeed myth + pro tip 4;
  the coworker "remembers" it as NO.
- **Isolator on load = deadly** (lesson safety tip: never opened on load); the tie is treated "on load"
  whenever the other feeder's CB is ON, AB-1 whenever its own CB is ON.
- On the open-ring docket, opening the other feeder's CB is allowed and not scored (not needed, not unsafe).
- The DO fuse trap ("isolates the transformer only") draws on lesson 3.10's symbol list + lesson 3.4.
- Tester showing live after the docket feeder's side is open = a slip (backfeed found); a live test before
  isolating is not a slip.
- Feeder names (রামপুর, শ্যামনগর, …) and pole numbers are fictional; 100kVA is from the lesson's image note.
- Not built: re-closing breakers to restore healthy parts (not in the sources).

### m3gate
1. **Silica gel colour.** The lesson says wet gel turns pink or white; the film says blue → pink or orange → green. I used only blue (good) / pink (replace), which both sources agree on.
2. **Ring NO point = deadly at planning.** 3.10 says a ring feeder can backfeed from the other side and to mark isolation points on the SLD before work. Making "plan without the NO point" deadly (and a missing AB-1 only a slip) is my choice. Locking/tagging the NO point is not in the lesson, so the game only asks to mark it.
3. **Fuse bypass is deadly** in both places (thick wire in the DO, copper strip in the pillar). 3.4 calls it "আত্মহত্যার সামিল"; the consequence the lessons describe is the DTR/cable burning. Owner may prefer slips.
4. **"Higher rating" fuse/HRC = slip** is inferred from 3.4 (rating follows the protected equipment, film: pick the amp rating from the DTR plate). No amp values are shown (none in the lesson for a 100 kVA DTR).
5. **Tap position** ("3 → 2" or "3 → 4" on the docket) is a scene detail; which direction raises voltage is not in the lesson, so the game never asks it. The rule tested is only "HT and LT both off" (film 3.6).
6. **Feeder pillar is dead** in this job (the DTR LT is off from station 4), so no-PPE and no-tester are slips, not deadly. "Tester before work" is from the 3.10 film; "full PPE and VDE tools" from the 3.7 film.
7. **Neutral bare hand = deadly** even in a shutdown — based on the 3.8 myth (unbalance/fault puts phase voltage on the neutral).
8. **DO operation PPE/stance** (face shield, gloves, stand aside) were Module 2's gate; here the three DOs are opened with the hot stick without re-testing that. Contacts cleaning, K/T link type, meter seal, customer courtesy, vector group, Buchholz were left out.
9. **Scene details, not lesson rules:** feeder-7/9, AB-1, DTR-12/DTR-17 (100 kVA), DKT-F7-3110, the plinth-mounted DTR, three outgoing ways in the pillar, "0 V" tester reading.
10. **Mistakes-book lesson.** The book stores `ctx.lessonId` (3.10) for every gate mistake; the card's "পাঠে দেখুন" opens the right lesson via the key prefix. Lesson-point indices are my reading of each lesson's point order (pro tips/myths have no point index, so the nearest point is used).
11. Latin labels in painters use the platform default font (as Module 2); in test screenshots they render as boxes.
