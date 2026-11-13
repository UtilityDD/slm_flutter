# MODULE5_LADDER.md — Module 5 (অ্যাডভান্সড) master list

Built 2026-11-12 on `fix/audit-2026-11-11`: one builder per rung → independent reviewer → fixer (workflows B5), then wired by
the director. Design: `docs/module_specs/module5_spec.json` + `docs/module_specs/module5_items/*.json`; rulings that win over the
item specs: [docs/module_specs/module5_rulings.md](docs/module_specs/module5_rulings.md) (M5-1 … M5-15).
Same frame as [MODULE4_LADDER.md](MODULE4_LADDER.md) and the playbook. Rank at the gate: **অ্যাডভান্সড** · badge: **ফল্ট ফাইন্ডার**
· 30 rungs (10 Learn, 19 Do, 1 gate).
Status: built on the shared kit, each rung's own tests green, wired into the catalog / `doGameFor` / mistakes book / board lookup.
**Pending owner review** — open content questions are in **Owner decisions** below. Coworker/rival lines are recorded by the
director with `tool/rival_clip.py` (until then they are silent with the caption held); guide, operator, neighbour and customer
lines are device TTS (ruling M5-14). No YouTube ids for 5.x boards yet.

## Master table

The Deadly column lists each level's `deadly: true` mistake keys (the same list is in the catalog's `deadlyRules`; `test/m5_wiring_test.dart` keeps them equal).

| Step | Rung | Name | Engine · pack · files | Core verb / moves | Deadly (💀) | Status |
|---:|---|---|---|---|---|---|
| 1 | 5.1/learn | 'লাইন ট্রিপ করেছে'—প্রথম কাজ কী? (picture board) | `learn_cards` · `learn_5_1` · `learn_board_pack51.dart` | 5 rounds (call · treat · van · storm · lock-out) + myth 'ট্রিপ মানে ডেড' | — (board traps only) | built, pending review |
| 2 | 5.1/do/0 | কন্ট্রোল রুমের ফোন | `m5_trip_call` · `do_5_1_a` · `m5_trip_call(_world).dart` | interview the operator: drag the handset, 7 question tiles (6 required incl. the logbook; vague answers need a second probe), pin the suspect, van to the start section, briefing (PTW only before touch/climb, M5-3) | 💀 asking control to charge the locked-out feeder (coworker, R8) | built, pending review |
| 3 | 5.1/do/1 | ট্রিপ মানে ডেড নয় | `m5_recloser_watch` · `do_5_1_b` | count recloser shots against decoys, report count + span; at lock-out: docket → drive → PTW → tester → spike → clamp | 💀 hands-on with no PTW · no test · no earth · clamp before spike | built, pending review |
| 4 | 5.2/learn | লাইন পেট্রোলিং-এর সঠিক নিয়ম | `learn_5_2` · `learn_board_pack52.dart` | 5 rounds + myth | — | built, pending review |
| 5 | 5.2/do/0 | ফল্টের ঠিকানা | `m5_fault_address` · `do_5_2_a` | radio control for the docket first (M5-3), drive the feeder, read FPIs in close-up, bracket with two flags; long feeder = van 2 to the far end; sectionalizer call; history note | — (slip-only level) | built, pending review |
| 6 | 5.2/do/1 | থামুন, দেখুন, শুনুন | `m5_sense_walk` · `do_5_2_b` | hold-walk / release-stop, swipe up to the pole top, ear/nose hold, tag (evidence-gated, M5-10); fallen wire ahead (stop ≥10 m, rope ≥10 m) or drop (feet-together steps out) | 💀 entering the 10 m zone · touching the wire · long stride out | built, pending review |
| 7 | 5.3/learn | সাধারণ ফল্ট: অপরাধীদের প্যারেড | `learn_5_3` · `learn_board_pack53.dart` | 5 rounds + myth | — | built, pending review |
| 8 | 5.3/do/0 | অপরাধী কে? সূত্রের সুতো | `m5_culprit_case` · `do_5_3_a` | photograph clues, thread them to the culprit, fault type and remedy deck | 💀 closing with 'charge it and see' (R8, added by builder) | built, pending review |
| 9 | 5.3/do/1 | পোড়া জোড়, নরম তার | `m5_anneal_cut` · `do_5_3_b` | earth both ends, spanner off the clamp/bolted sleeve, judge softness by colour/feel, cut out the soft length, new joint | 💀 climbing with an earth missing at either end (R4) | built, pending review |
| 10 | 5.4/learn | ফিউজ বারবার উড়ে যাওয়ার কারণ | `learn_5_4` · `learn_board_pack54.dart` | 5 rounds + myth | — | built, pending review |
| 11 | 5.4/do/0 | একে একে ফিডার — ফল্ট কোথায়? | `m5_feeder_sectionalize` · `do_5_4_a` | pull every LT way, charge, restore one by one, tag the blower; DTR/HT case → patrol or megger | 💀 charging with no LT way open · re-pushing the proved faulty way · re-charge with nothing changed · re-charge after HT proved | built, pending review |
| 12 | 5.4/do/1 | লাগাতেই, না পরে? | `m5_reblow_clock` · `do_5_4_b` | read today's logbook, look first (M5-8), hold the DO / hold the clock, stamp instant vs delayed; permanent → order deck; transient → where-to-look deck | 💀 re-fit after an instant blast · listening to 'burn it' · ordering a re-charge · thick wire / wrong rating | built, pending review |
| 13 | 5.5/learn | 'লো-ভোল্টেজ' সমস্যার সমাধান | `learn_5_5` · `learn_board_pack55.dart` | 5 rounds + myth | — (live tap-changer trap is a board trap) | built, pending review |
| 14 | 5.5/do/0 | ড্রপ কোথায়? | `m5_lv_street_read` · `do_5_5_a` | ask the street → scope chip → route → LTDB R/Y/B → line probes → evidence-gated verdict → docket/span card | 💀 turning the tap changer live (R21) | built, pending review |
| 15 | 5.5/do/1 | লোড দিয়ে মাপুন | `m5_lv_load_test` · `do_5_5_b` | measure with the load on, N–E check, evidence-gated verdict, method deck, every joint, loaded re-measure | 💀 plain spanner on live terminals · bare-hand neutral (R22) | built, pending review |
| 16 | 5.6/learn | শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট | `learn_5_6` · `learn_board_pack56.dart` | 5 rounds + myth | — | built, pending review |
| 17 | 5.6/do/0 | দুই শত্রুর খাতা | `m5_fault_casebook` · `do_5_6_a` | 4 cases, spend two clues by gesture, file into short / open / trip-no-proof (locked until both clues seen) | — (slip-only level) | built, pending review |
| 18 | 5.6/do/1 | ছেঁড়া তার, তবু লাইভ | `m5_live_wire_guard` · `do_5_6_b` | swipe to stop people reaching live metal (waves; needless stops cost time and the clean +5) | 💀 hand lift · bamboo push · joining the ends · phone-off · bystander contact | built, pending review |
| 19 | 5.7/learn | রাতের বেলা ফল্ট খোঁজার কৌশল | `learn_5_7` · `learn_board_pack57.dart` | 5 rounds + myth | — | built, pending review |
| 20 | 5.7/do/0 | সার্চলাইটের টহল | `m5_searchlight_patrol` · `do_5_7_a` | docket, two-person van, steer the searchlight, call the speed, mark poles, report | 💀 climbing to look (R1/R19, added by builder) | built, pending review |
| 21 | 5.7/do/1 | আঁধারে চোখ-কান | `m5_dark_eyes` · `do_5_7_b` | lights off, wait for the eyes, then mark the glow/sound; report pole number from the ground | 💀 climbing the live pole · bamboo poke (R19/R20) | built, pending review |
| 22 | 5.8/learn | ট্রান্সফরমারের সাধারণ সমস্যা | `learn_5_8` · `learn_board_pack58.dart` | 5 rounds + myth | — | built, pending review |
| 23 | 5.8/do/0 | লক্ষণ থেকে কারণ | `m5_cause_strike` · `do_5_8_a` | run a test, strike causes off the list (noise · leak · LT no voltage) | 💀 spanner untested · untested hands · climbing live | built, pending review |
| 24 | 5.8/do/1 | হাসপাতালের কাগজ | `m5_workshop_referral` · `do_5_8_b` | gather proof at 3 sites (bushing, IR, oil, record), pin it to the workshop slip | 💀 re-charge DTR · re-charge LT with the blower in (R8) · no HT test | built, pending review |
| 25 | 5.9/learn | কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা | `learn_5_9` · `learn_board_pack59.dart` | 5 rounds + myth | — | built, pending review |
| 26 | 5.9/do/0 | কোর থেকে কোরে: ফল্টের ধরন | `m5_cable_fault_type` · `do_5_9_a` | isolate, plan megger/multimeter tests core by core, discharge, deduce open / short / earth | 💀 live lead (R23) · earthed rod on a live core · lifting a charged clip (R24) | built, pending review |
| 27 | 5.9/do/1 | মাটির নিচের সূত্র | `m5_cable_route_locate` · `do_5_9_b` | read the TDR, trace the route, call the underground owners (M5-7), sweep for the thump, peg ('গোঁজ') | — (slip-only level) | built, pending review |
| 28 | 5.10/learn | প্রিভেন্টিভ মেইনটেন্যান্স | `learn_5_10` · `learn_board_pack510.dart` | 5 rounds + myth | — | built, pending review |
| 29 | 5.10/do/0 | লুকানো গরম: PM রাউন্ড | `m5_pm_thermal_round` · `do_5_10_a` | sweep the thermal camera, snap hotspots (>15 °C over the other two phases, M5-15b), shutdown order, tighten | 💀 no permit · no test · no earth (R4 added by builder) | built, pending review |
| 30 | m5/gate | অ্যাডভান্সডের ডকেট: এক রাতের কেস | `m5_gate_case` · `gate_m5` · `m5_gate_case(_world).dart` | one fault call as crew in-charge: phone menu, PTW clipboard, chip → map → order → hold radio dispatch (9 orders), close view or UG sheet, report, line clear; `unlockRank(5)` | 💀 hands without PTW · climb without earth · charge a fault · charge with crew · clear with crew up · wire zone · climb live · hands after clear · bamboo poke · megger live | built, pending review |

## Deadly / slip table (module design, with rulings applied)

From `module5_items/*.json` `deadlySlipTable`; where a ruling (M5-x) changed a row, the ruling is shown.

| # | Act | Class | Used in |
|---|---|---|---|
| R1 | Touching/climbing a tripped line or any hands-on work before a written PTW (incl. phone 'line off') | 💀 | 5.1b, 5.6b, 5.10a, gate (5.7a climb) |
| R2 | Hands, tool or climb before the tester shows 0 V (M5-2: raised from slip in 5.8a/5.8b) | 💀 | 5.1b, 5.8a, 5.8b, 5.10a, gate |
| R3 | Earth set before the tester proved the line dead (card: test first, then earth) | slip | 5.1b, 5.3b, 5.10a |
| R4 | Climbing or cutting after the test but before the earth (personal / both ends) | 💀 | 5.1b, 5.3b, gate (5.10a by builder) |
| R5 | Earth clamp on the line before the spike | 💀 | 5.1b |
| R6 | Patrol (no touch) of a tripped/locked-out feeder without informing control (M5-3: docket, never a PTW as a legal must) | slip | 5.1b, 5.2a, 5.7a, gate |
| R7 | Ground patrol of an in-service line needs no PTW; any climb or touch of it | 💀 | 5.2b, 5.7b, gate case F |
| R8 | Re-energizing a faulted line: charge before the fault is found / after the test charge failed; DO re-fit after an instant blast; closing a DO with the blowing LT way in; re-charging a DTR after an HT blow (M5-1) | 💀 | 5.1a, 5.3a, 5.4a, 5.4b, 5.8b, gate |
| R9 | First DO re-fit on a fresh blow: allowed after one visual check; re-fit with no check (M5-8) | slip | 5.4b |
| R10 | Re-fit after a delayed (transient) blow before checking sag/branch spots | slip | 5.4b |
| R11 | Charging the HT with only some LT ways open | slip | 5.4a |
| R12 | Charging with a crew member at the work spot or before line clear | 💀 | gate |
| R13 | Walking into the 10 m zone of a fallen wire (M5-4) | 💀 | 5.2b, 5.6b, gate |
| R14 | Touching/lifting/moving a fallen wire by hand, foot, stick or dry bamboo, or joining the ends | 💀 | 5.2b, 5.6b, gate |
| R15 | Leaving the step-potential zone with a long stride (M5-4) | 💀 | 5.2b |
| R16 | Cordon under 10 m (M5-4) | slip | 5.2b, gate |
| R17 | Bystander reaches live metal because the player did not stop them (M5-5) | 💀 | 5.6b |
| R18 | Late but successful stop (M5-5) | slip | 5.6b |
| R19 | Climbing a live pole or DTR platform to look closer | 💀 | 5.7b, 5.8a, gate F |
| R20 | Bamboo poke at a live insulator | 💀 | 5.7b, gate F |
| R21 | Turning the off-load tap changer live | 💀 | 5.5a |
| R22 | Plain spanner on live terminals; bare-hand neutral | 💀 | 5.5b |
| R23 | Megger/meter lead on a cable with an end not isolated | 💀 | 5.9a, gate |
| R24 | Lifting a megger clip after TEST without discharging | 💀 | 5.9a |
| R25 | First test lead before the pre-test discharge | slip | 5.9a |
| R26 | Thick wire or wrong link in place of a fuse | 💀 | 5.4b, board 5.4, gate |
| R27 | Night patrol alone / one person driving and watching | slip | 5.7a, gate |
| R28 | Low battery, dark jacket at the roadside, unfamiliar field track | slip | 5.7a |
| R29 | Listening to the coworker: same class as the act he pushes; a myth with no immediate danger = slip | per act | all |
| R30 | Tagging/pinning/snapping a sound item as a fault | slip | 5.2b, 5.3a, 5.7a, 5.7b, 5.8b, 5.9b, 5.10a, gate |
| R31 | Closing a search with a real finding missed | slip | 5.1a, 5.2b, 5.7a, 5.8b, 5.10a, gate |
| R32 | Accepting water in DTR oil as harmless (M5-6) | slip | 5.8b |
| R33 | Pegging/digging before calling the underground-service owners (M5-7) | slip | 5.9b, gate |

Learn boards have no deadly freeze or strike-out (kit design): deadly-class traps cost a ◆ and show their lesson/ruling text.

## Owner decisions (flagged by the builders — please confirm or change)

### Top decisions for Module 5 (director's summary)
1. **Deadly acts added beyond the item specs** (each rung needs a deadly freeze per the worker contract): 5.3a 'charge it and see' (R8), 5.7a climbing to look (R1/R19), 5.10a wrench before the earth (R4), 5.9a earthed rod on a live core (R23+R2), gate: line clear with the crew up, hands after line clear. 5.2a, 5.6a, 5.9b stay slip-only — add a deadly act or accept.
2. **R8 across the module** (re-energizing a faulted line = deadly) still conflicts with M4 `do_4_4_b` (re-blow = slip). Align the two.
3. **Learn boards have no deadly path**: deadly-class traps (charge, bare hand, live tap changer, live megger…) are ordinary ◆ traps. Kit change or accept the board rule.
4. **Gate badge = board badge**: every 5.x board uses the lesson badge 'ফল্ট ফাইন্ডার', which M5-12 also gives the gate.
5. **Fallen-wire cordon**: rope beside the wire is a slip (M5-4 cordon < 10 m) though tying it means entering the 10 m zone (deadly); confirm.
6. **New quickMs values** for every Do level and the gate (60–230 s; gate 7 min) are builder estimates; 5.9a's clean play is ~4.6 min — consider trimming.
7. **Kit requests**: a non-guide voice channel (operator/neighbour/customer TTS currently moves the guide's lips); per-level idle time on FullSceneFrame (spec asks 3–6 s, kit is 8 s); a gesture hint on the board's হ্যাঁ/না step; a circular hint kind (5.3b); board idle-rebuild check sits at ~20/s (flaky at the < 20 limit).
8. **Facts the lessons don't state** (need a lineman): all voltages/temperatures/readings, recloser shot counts, softness-by-colour for annealing, the bolted joint sleeve, fuse rating tag, thermal palette, torque shown as a click, FPI look, oil look, TDR/peg tolerances.

### m5lb1
- Two R8 'charge' traps (call round and lock-out round): keep both or drop the lock-out one?
- M5-3 vs R6 on a locked-out feeder: the safe card says inform control before the hunt, PTW before any hand. Rule if a PTW must be shown before the search itself.
- Round 1 dropped `ask_recloser` (6-option limit). Relay flag, recloser box, LOCKOUT lamp are illustration only.

### m5do1a
- Coworker push is lesson 5.1 myth 2; listening = deadly (R8, raised from the designer's slip).
- Needless re-ask costs the thorough/quick bonus only (no slip) — enough?
- Recloser counts (1 try vs 2–3) and the windy no-rain overcurrent case are game choices. quickMs 100 s.
- Operator speaks via device TTS through the guide's lips (kit gap).

### m5do1b
- Driving off before the PTW is a slip with the M5-3 card; wrong count + wrong span in one report = one slip; a needless stop costs 2 s only.
- Quick clock runs from the lock-out (70 s after it). Driving the spike before the tester is not a mistake (only the clamp counts as earth applied).
- Weather → fault mapping, inverter-house decoy, 2–3 shots in game seconds are game choices.

### m5lb2
- Round 1 dropped 'আগে টি-অফ পয়েন্ট' (taught by a trap and its reason instead). Long stride (R15) is a trap with the rule as its reason. Hand radio, rope stakes, burnt-smell source are art only.

### m5do2a
- No deadly act (spec has none): add one (e.g. climbing on the in-service call) or keep slip-only?
- Needless reading costs only the clean +5. Every play deals all three call kinds. quickMs 120 s.
- FPI look/LED, sectionalizer window, T-off FPIs, history-note format are game devices.

### m5do2b
- Eye-up/eye-down tags pay +10 with no reason deck. Decoy dirt layers on sound insulators (a false tag = slip) — lesson-true enough?
- Sight-only tag of the hidden clue = slip (blind-tag, M5-10) and is not consumed — slip or just a nudge?
- Game numbers: walk 4 m/s, step 0.8 m, 56 px drag = stride, 8 px/m scale. No hiss SFX exists. quickMs 80 s.

### m5lb3
- 'Forest team' in green shirts and the planning crew are interpretations; annealing shown as dark kinked strands (no bend-test claim, M5-15a).
- Reasons are dealt per round, not per picked card (kit limit).

### m5do3a
- Deadly 'charge it and see' card added (R8); confirm or rule it a slip (then the builder downgrades `M5CulpritMistakes.chargeTest`).
- Chain spot remedy combines the insulator + tree remedies; kite and LA have no remedy slot. Villager's blast-sound clue excluded at tree-to-ground spots. Dew on a sound insulator as a decoy — lineman check. quickMs 100 s.

### m5do3b
- Deadly booked at the climb (not at the first cut). A too-far cut is blocked with a slip card (not performed).
- Soft length and cut tolerance are game rules; softness shown by colour; bolted heat-discoloured sleeve stands for the lesson's sleeve — lineman check. quickMs 70 s.

### m5lb4
- No deadly path on boards (blast re-close, Fault Burning are ordinary traps). Round 'where' mixes action traps with place traps (reword the prompt or swap a trap). Rounds 1 and 4 both carry a Fault Burning trap.
- Cards not yet spot-checked on screen.

### m5do4a
- Re-pushing a proved faulty way on a live board = deadly (R8 reading); re-charge after a partial blast is deadly only if nothing was pulled since. `rechargeSame` reuses `no_open.svg`.
- DTR/HT case accepts both patrol and megger. quickMs 75 s.

### m5do4b
- Fuse-rating tag reads 'ফিউজ · সঠিক রেটিং' (no amp figure in the lesson) — owner may supply one.
- Look-first step comes from M5-8 (no lesson point). Held times 40 s … 3 h 30 m, older-page notes, birds as a weather sign are game devices. quickMs 60 s.

### m5lb5
- Round 5 uses the M5-15c wording 'এলটিডিবি-র ইনকামিং' (the lesson says LT bushing). Supply-off before tightening joints comes from M3/M4 rulings.
- Ruling M5-15(c) is labelled 5.5b but applies to 5.5a (relabel in the rulings file).

### m5do5a
- All voltages illustrative (LTDB 235 vs 202, 7 V/pole, ~28 V after the span). Notebook shows phase per house — would a lineman know it on site?
- Probing 8+ houses only loses the 'রিডিং দেখে ঠিক রায়' tag (no score cost). quickMs 90 s. Neighbour TTS moves the guide's lips.

### m5do5b
- Meter-seal and neutral–earth slips are not in lesson 5.5; method deck and R22 cards come from M3/M4 rulings.
- Load-grew report without asking the customer = slip (ask-first); weak-neutral call rejects 'loose joint'; the loose verdict card states a diagnosis (reword as a suspicion?). Voltages illustrative. quickMs 90 s.

### m5lb6
- Open round got a third trap (branch across two wires); fence-touching reason rests on M5-4. New rival taunt wording needs review.

### m5do6a
- No deadly act. A player ignoring the clues can still pass at 70 % (never clean) — stricter pass needs content changes.
- Does a breaker operating count as 'open' (trip-not-open card)? Smoke, scorched leaves, melted beads are art only. quickMs 70 s.

### m5do6b
- Needless-stop cost (2 s busy + lose the wave's +5 + quick bonus; trap people from wave 2) is new — tune `needlessBusyMs`.
- Late-stop threshold (under the rope or within 30 px) is a game-timing choice. A second coworker line was added (both need clips). Drawn rope ring encloses only the wire.

### m5lb7
- Prep/eyes/clue/sense rounds have exactly 3 traps (every deal shows the same traps). Default flipped myth question is not a yes/no question (this board overrides it; other boards keep the default).
- 'টর্চের প্রতিফলন নয়' wording is from the spec, not the lesson.

### m5do7a
- Deadly climb card added (R1/R19). Docket chip per M5-3 adds a 'no docket' slip. Pole number by phone is not in 5.7. New Bangla wrong-reason excuses need review. quickMs 90 s.

### m5do7b
- Final deck always deals one right, one deadly (climb/poke), one slip. Walking past the clue = slip (R31 names 5.7a only). Mark before the clue = slip (M5-10).
- Dark adaptation ~5 s; pole plate and reporting phase are not in the lesson. quickMs 75 s.

### m5lb8
- Water-in-oil myth used as a trap card (M5-6 text), not a second myth beat. Tong tester as the load check, leak sizes, oil jar look are inferred. Rival bubble lane is a fixed 150 px.

### m5do8a
- Added slip: opening a DO on load (LT lever still ON). +5 per right strike is new scoring. LT lever gated until all three phases are metered (gentle nudge, not a slip). Second listen on a loud case adds `humLate` push + `push-report` slip. quickMs 80 s.

### m5do8b
- Re-charge button reads 'এ অবস্থায় চার্জ' (width). LT box plate reads 'LT' (blower still in) so re-charge is deadly under R8. Charge push only at a transformer site (could be a tell).
- Healthy oil colour, water beads, IR needle, bushing marks are inferred. quickMs 90 s.

### m5lb9
- Round changes to fit 4–6 options (added overhead-branch trap, 'Y-to-armour ∞' trap; dropped the blank-TDR card). Thumper mic and marker posts are design choices; no megger voltage shown.

### m5do9a
- Earthed rod on a live core is deadly (R23+R2, not a named row). Lead before lock-and-tag = slip (from 2.7 and M1). Readings/nine-test rule/1.2 s TEST are game data.
- Clean play ~4.6 min (quickMs 230 s): trim round 2?

### m5do9b
- No deadly act. Calling all three underground owners before the peg (M5-7); their replies are flavour text. Calling the team after a clue is pinned is free (worker contract says needless costs something).
- Peg label changed from 'খুঁটি' to 'গোঁজ'. B1 coworker line is three sentences (shorten before recording?). Tolerances are game data. quickMs 80 s.

### m5lb10
- Rusted clamp fix shown as a new clamp; thermal scan from the ground on a live line, hot joint tightened on a shutdown with earths — inferred. No torque or temperatures shown.

### m5do10a
- Wrench after the test but before the earth = deadly (R4; item named only R1/R2). Shutdown-order slips follow M1, not lesson 5.10.
- Temperatures (loads 26–61 °C, hotspots 16–25 °C over, up to ~94 °C) and the thermal palette are invented — lineman check. Torque shown as a click. +5 for a correct স্ক্যান শেষ has no M4 counterpart. quickMs 80 s.

### m5gate
- Aftershock beat not built (the spec's right card would be R8-deadly). Restore with another card or leave out (M5-12 allows).
- Line clear with crew up / earth on = deadly (by analogy with R12); line clear early with crew down = slip; hands after line clear = deadly. None is a separate table row.
- R16 rope beside the wire = slip (M5-4); bamboo poke before tester + earth = deadly (M5-2). 'Wait till morning' coworker cuts in when the first patrol is sent.
- Needless-order and hands-before-found slips are game rules. Clash remedy 're-tension the sag' is not in lesson 5.4. quickMs 7 min; `unlockRank(5)` (rank numbering F5 open).
