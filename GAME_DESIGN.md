# মৃত্যুহীন পথ — Game Design Guide

The single source of truth for what the app is becoming. When this file and an older guide disagree, this file wins.

**Status (Nov 2026):** through **Learn runner** — Module 1 `1.N/learn` packs are playable; ladder opens swipe cards + 2-question exit (points only, never a fall). Do/gate still Coming Soon via legacy `dsLevels` bridge. Next: **Do wire**, then Module 1 fill. See section 13 and `assets/game/catalog/content_catalog.json`.

---

## 1. Purpose

One game that teaches one idea: **a single mistake at real work is a near death.**

The player climbs a ladder of lessons and real-work games. Learning is never a separate page to search for. The game leads the player through every lesson in order, tests the habit in a realistic scene, and punishes deadly mistakes with a fall. The goal is the **emerald** at the top.

## 2. Target user

- West Bengal distribution linemen and helpers, many on contract.
- Reads Bangla, often finds long text tiring.
- Budget Android phone (3–4 GB RAM), limited data, often full storage.
- Plays in short breaks (2–5 minutes), outdoors, in sunlight, often tired.
- Opens the app to play and compete, not to study.

Design consequences: voice first, very little text, big touch targets, high contrast, works offline, small download, a rung fits in 1–2 minutes.

## 3. Core loop

```
Home  →  Ladder  →  Rung (Learn or Do)  →  Result  →  back on the ladder, one rung higher (or fallen)
```

There is nothing else to navigate. Everything the player needs comes to them on the ladder.

## 4. Home screen

Only four things:

1. Player name and photo.
2. Score `◆` and death count `💀`, with the current rank badge.
3. The lineman character in his current mood.
4. The large animated **মৃত্যুহীন পথ** shield button (`AnimatedSafetyShield`). Tap → ladder.

A small **toolbox** icon in a corner holds: emergency numbers, the identify library, settings. Emergency stays one tap away because it has real use on the job.

Removed: bottom tab bar, hero card carousel, separate quiz / lesson / life-skill / rank pages as destinations.

## 5. Ladder page

```
┌──────────────────────────────────┐
│ ←      🛡 ট্রেইনি   ◆ 1,240   💀 3 │  thin top bar
│                              ┊   │
│           (mist above)       ┊   │  progress line, right edge
│        ║══ 14 ══║            ●   │  dot = player, emerald at top
│   💡   ║══ 13 ══║            ┊   │  1–2 side items, near the player only
│        ║══ 12 ══║  🧍         ┊   │  character on his rung
│        ║══ 11 ══║            ┊   │
│                                  │
│        [ ▶  পরের ধাপ ]            │  one play button
└──────────────────────────────────┘
```

**Top bar (one line):** back · rank badge and name · `◆` score · `💀` deaths. A small "safe rungs" streak (`নিরাপদ ধাপ: 27`) may sit under the deaths. Nothing else: no title, subtitle, info button, timer, or level crest.

**Ladder:** keep the painted parallax valley and the narrow golden ladder (about 38% of the width). Rungs show **only their number**.

| Rung | Look |
|---|---|
| Learn | soft ivory coin |
| Do | gold coin |
| Rank gate | larger emerald crest with the rank badge |
| Current | gentle glow |
| Passed | quiet gold, no tick |
| Above | fades into mist; next 2–3 clear |

**Character:** stands on the current rung. Climbs on a pass, slips down on a fall. Moods: ready, climbing, proud, frightened, fallen, hero.

**Side items:** at most 1–2 on screen, near the player. Pictures only, no labels or point numbers. Finished items disappear (they do not stay dimmed). They keep the scroll zoom.

**Progress line:** thin vertical line on the right edge from ground to emerald, a notch per module, a glowing dot for the player. Replaces the legend.

**Play button:** `▶ পরের ধাপ` always starts the next rung. Tapping the glowing rung does the same. If the player scrolls away, a small round "me" button brings them back.

**Taps:**

| Tap | Result |
|---|---|
| Current rung / play button | Start the next rung |
| Passed rung | Replay for practice, no extra points |
| Rung above | Small shake, mist thickens, no text |
| Side item | Zooms to centre, then shows the tip, question, or gift |
| Emerald | Short glimpse of the goal |

**Text** appears only for a moment after something happens (pass, fall, promise, reward), as kinetic typography, then leaves.

## 6. Structure: modules, lessons, rungs

The ladder is **built from data when the app opens**. It is not a fixed number of rungs. It can be 200 today and 400 later.

- **Module** = a group of lessons + one rank gate. One module = one rank = one scenery zone.
- **Lesson** = one Learn rung + one or more Do rungs.
- **Rank gate** = the last rung of a module.
- Rung numbers are computed at load time. The emerald is always at the top of whatever exists.

Starting map (10 modules, about 10 lessons each, from `training_chapters`):

| Module | Main Do game | Rank at the gate |
|---|---|---|
| 1 PPE | Dress-up | ট্রেইনি |
| 2 Pole climbing | Pole inspection | জুনিয়র |
| 3 Wire handling | Spot the danger | টেকনিশিয়ান |
| 4 Transformer (DTR) | Steps in order (lock, tag, isolate) | স্কিলড |
| 5 Earthing | 8 mantras in order | অ্যাডভান্সড |
| 6 LT / HT fault repair | Field scene | সিনিয়র |
| 7 Rescue and first aid | Timed decision | সুপারভাইজার |
| 8 Rules | Spot the rule broken | স্পেশালিস্ট |
| 9 Smart meter | Identify the item | এক্সপার্ট |
| 10 Field manual | Mixed checklist run | সেফটি প্রো |

With one Learn and one Do rung per lesson, a module is 20 rungs and the gate replaces the tenth Do rung. That is a default, not a rule.

**Progress is saved by lesson and rung type** (for example `2.3/do`), never by rung number, so adding content never moves a player.

## 7. Rung types

**Learn (about 1 minute)**
- Each lesson point becomes one swipe card: picture, item name, one line on why it matters, voice.
- Long `specifications` text stays behind an optional "more".
- Ends with **2 questions** from that lesson's quiz file (`questions_M_C.json`).
- Wrong answer: lose points, see the right answer. **Never a fall.**

**Do (1–2 minutes)**
- A real-work game for the same lesson, picked from the lesson's game pool.
- Deadly mistake: **fall** (section 9).

**Rank gate**
- A full real-duty scene mixing every lesson in the module (Zero Loss / field-night style).
- Pass: next rank. Pass with 0 deaths in the module: **মৃত্যুহীন** mark on the badge.

**Optional mastery rule** (per lesson, set in data): instead of a fixed number of Do rungs, "pass N different games from the pool". Players who make mistakes get one more game before moving on. Use it for the deadly topics: earthing, live line, rescue.

## 8. Game pool per lesson

Every lesson has a **list of games**, not one. Example, lesson 1.3 gloves:

| Game | Type |
|---|---|
| Choose the right gloves for an HT line | Pick |
| Spot the torn glove in the kit | Spot the danger |
| Dress the lineman before a night fault | Dress-up |
| Customer shouts "hurry" while gloving up | Pressure decision |

Selection:
- First play: the lesson's main game (fair start for everyone).
- Later plays and after a fall: one the player has not seen yet.
- The pick is seeded per player, so friends get different games and cannot copy answers.

Variation inside a game: which item is missing, which pole is rotten, which step is out of place, day / night, rain, crowd, village road.

Surprise events in Do rungs and gates: phone call, supervisor shouting `জলদি করো`, a passer-by stepping in, sudden rain. The call mechanic already exists in the ladder game (`DsCall`).

**Game types** (built into the app; content comes from data):

| Type | Exists today |
|---|---|
| Swipe learn cards | no |
| Pick the right item / answer | yes (quizzes) |
| True or false (myths) | no |
| Dress-up | yes (`ds_dress_up.dart`) |
| Steps in order | yes (SAFE HOME / 23-step job) |
| Spot the danger | partly (pole inspect) |
| Pole inspection | yes (`ds_pole_inspect.dart`) |
| Identify the item | yes (identify quiz) |
| Timed decision / call | yes (`DsCall`) |
| Field scene | yes (field night, Zero Loss) |

A new **game type** needs an app update. A new **game, lesson, or module** does not.

## 9. Points, deaths, falls

**Two numbers, always side by side:**
- `◆` points: grows with learning and playing.
- `💀` deaths: how many times the player would have died at real work. Red. Only goes up within a season.

**What counts as a death:** only a deadly mistake in a **Do rung or rank gate** (real work). Examples: touching a line without earthing, gloves missing, breaking the 8-mantra order, climbing without the harness check. A wrong quiz answer is never a death.

**The death moment:**
1. Freeze, heartbeat, a crack across the screen.
2. `💀` ticks up with a heavy thud. Kinetic text: `বাস্তবে এটা আপনার 3 নম্বর মৃত্যু`.
3. One spoken line with the cause, for example `আর্থিং ছাড়া তারে হাত — মুহূর্তে মৃত্যু।`
4. If the player had promised this habit: `আপনি কথা দিয়েছিলেন — গ্লাভস ছাড়া তারে হাত নয়।`
5. The character falls to the **first rung of the current module** (the rank checkpoint). Never to rung 1 of the whole ladder.

Serious, not gory: no blood. Many players have lost colleagues.

**Safe rungs streak:** `নিরাপদ ধাপ` counts rungs since the last death, like a site's "days without accident" board. Resets to 0 on a death.

**Helmet cracks:** each death in the current module leaves a crack on the character's helmet. A clean gate pass gives a fresh helmet.

**Death log:** tap `💀` → `কেন মারা গেলাম`: each death with cause, rung, and lesson. These mistakes come back later as recall side items.

**Leaderboard:** ranked by points, with deaths beside every name.

**Never** sell or give a way to undo a fall.

## 10. Side items

Placed by rule (about one every 2–3 rungs), near the player, at most 1–2 visible.

| Item | Look | What it does |
|---|---|---|
| Safety tip + promise | PPE icon matching the tip | Tip, then the promise question |
| Recall question | small spark | 1–3 questions from passed lessons, wrong ones first |
| Myth check | — | True / false swipe from the lesson's `myth_buster` |
| Gift | chest | Existing gift |
| Life-skill lesson | — | Occasional, never blocks the climb |
| Catch-up | — | A lesson added to a module the player already passed |

**Promise items** (from each lesson point's `daily_check` line):
- Buttons: **আমি করব** / **এখনো না**.
- About 5 points for the first "আমি করব" on each item. Never again for the same item.
- "এখনো না" costs nothing, shows one line on why it matters, and the item returns in about 2 days.
- Daily cap of about 3 promise rewards.
- Every promise is saved in `আমার প্রতিজ্ঞা`. The fall screen quotes it when the player breaks it. Gates show the promises made in that module.

Ten reference promises (one per module) were drafted in the design chat: gloves, harness, pole base, lock and tag, earthing both ends, test before touch, never touch a shocked person bare-handed, permit first, barricade, phone on silent.

## 11. The emerald and seasons

- The emerald sits at the top of the ladder. Reaching it: hero celebration, permanent hero badge, Hall of Heroes.
- Reaching it with 0 deaths: **মৃত্যুহীন বীর**, the rarest title.
- Then: start again, harder (fewer hints, tighter timers). Hero badge stays.
- `💀` and points are per season. The best clean record is kept.

## 12. Growing the content after release

| You add | Effect |
|---|---|
| A game to a lesson's pool | Same ladder length, more variety. Most common update. |
| A lesson inside a module | That module grows. Players already past it get a catch-up side item, never a push back. |
| A module | New zone on top, the emerald moves up. Existing heroes keep the badge and see `নতুন উচ্চতা খুলেছে`. |

**Where content lives (Supabase):** modules, lessons (existing `training_chapters`), game pool entries (type, settings, difficulty, deadly rules, live flag), promise items. The admin page switches content on. The app downloads it, caches it for offline play, and rebuilds the ladder.

What moves out of code: `_path = 200`, the `dsLevels` const list, and the `index % 8` side-item pattern in `adventure_map.dart`.

## 13. Build order (element-by-element)

Ship feel systems before filling every pack. Content add/reorder = catalog JSON `order` / `status` only.

0. **Catalog + docs** — `content_catalog.json` (327 rungs), `LadderBuilder`, this file.
1. **GameSave + HUD** — one local `◆` / lethal-only `💀`; migrate `ds_*` score once.
2. **Exit sheet** — leave level vs leave game.
3. **AI Line Man guide** — replace static corner; idle sleep/wake/inspire.
4. **Score FX** — `+/−` flies to `◆` after save commit.
5. **Death + fall** — lethal → fall to module checkpoint; climb avatar moves.
6. **Hint appear** — tip/gift/Coming Soon zoom + kinetic.
7. **Ladder shell** — render 327 from catalog, chrome-first boot, `পরের ধাপ`.
8. **Learn runner** — cards + guide reads.
9. **Do wire** — dress/pole/… via `engineType` registry.
10. **Module 1 fill** — PPE pilot + PPE gold collection; rest Coming Soon.
11. **Expand via catalog** — remap remaining scenes; no hardcoded rung indices.

Later: Supabase sync, admin CMS, remove tab bar, voice size cut, Play closed test.

## 14. Rules that do not change

- Bangla text saved as clean UTF-8. Never PowerShell `Set-Content` on Bangla files.
- English digits `0–9` everywhere, through `enDigits`.
- Words: `ডকেট`, `শাটডাউন`, `জল`, `গ্লাভস` (never দস্তানা).
- No text on map items, equipment, or work scenes. Text only after a tap or event.
- Respect the phone's "remove animations" setting: no stagger, shake, or flash; values still update.
- No new animation packages; use `lib/design/motion/`.
- Rewards are display only, after the real result is saved. Never invent points.
- Do not edit the shield ring geometry in `slm_safety_shield.dart`.
- Keep the ladder narrow (35–40% of the width). No winding road, no floating tick badges.

## Related guides

- [`GAME_DEVELOPER_GUIDE.md`](GAME_DEVELOPER_GUIDE.md): **Unified Developer Guide & Collaborator Roadmap** — complete system architecture, file map, step-by-step workflows for Mascot speeches, Learn cards, Touchable side items, and Do levels, plus the Phase 1–3 implementation roadmap.
- [`lib/features/duty_slip/GAME_LEVELS_GUIDE.md`](lib/features/duty_slip/GAME_LEVELS_GUIDE.md): screen rules and detailed scene ideas for real-work games (Levels 1–14 active, Levels 15–31 planned). The level ideas become entries in lesson game pools.
- [`AUDIO_DEVELOPMENT_GUIDE.md`](AUDIO_DEVELOPMENT_GUIDE.md): voice lines and mistake audio.
- [`lib/design/MOTION.md`](lib/design/MOTION.md): motion widgets.
- [`NEW_MACHINE.md`](NEW_MACHINE.md): machine setup and Google sign-in.
