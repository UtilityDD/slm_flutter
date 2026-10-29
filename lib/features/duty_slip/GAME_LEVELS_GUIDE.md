# Mrityuhin Poth (মৃত্যুহীন পথ) — Game Levels Developer Guide

> **Important**: All Bengali text in this module must be saved in clean UTF-8. Do not use PowerShell `Set-Content` (which causes mojibake); edit within the IDE or agent tools (`Write` / `StrReplace`).

---

## 0. Non-Negotiable Rules (To Prevent Repeated Mistakes)

Every new level must follow these rules. Earlier iterations were rejected whenever any of these were broken.

1. **Lessons Are the Source, Habits Are the Game**
   * Every level comes from the training chapters (`c:\Dipankar\slm_web\public\quizzes\chapter_*.json`).
   * Assume the lineman has **already read the lesson**. The game tests whether he remembers the habit in the field, not whether he can read labels on the screen.
   * **Never reveal the checks before playing.** The opening speech gives only the job situation and what has already been completed. It must never list the answers.

2. **Zero Text Clutter on the Work Screen**
   * Do not put instruction banners, hint chips, floating labels, arrows, or diagnostic cards on the pole, equipment, or tools.
   * Bottom tool trays are **pictures only** (no captions).
   * If earlier steps of the job are already done (e.g., PPE, tools, shutdown, discharge, both-side earth), show them only as short unticked words down the top-left (no box, no border), and draw their green ticks one by one after ~2 seconds:
     `পিপিই` · `যন্ত্রপাতি` · `শাটডাউন` · `ডিসচার্জ` · `দুদিক আর্থ`

3. **Real Photo Style — No Flat SVG / CustomPainter Scenes**
   * Both the **title page (intro card)** and the **working scene** must use clear, realistic photographs (daylight unless the lesson is specifically a night fault).
   * Do not use stormy/collapsed-pole photos for routine habits. Routine habits happen on normal-looking poles and normal equipment so the player learns not to trust appearances.
   * Do not leave a van or stray prop behind a rotating pole.
   * The lineman stands in PPE (`spr_man_point.webp`) beside the work until the final action, then changes to the working/climbing pose (`spr_man_climb.webp`).

4. **Exact Screen Consistency With Other Levels**
   * **Title card header**: Back arrow on the top-left, `লেভেল N`, the thin horizontal rule with the center diamond, and the level title. Centered guide (`DsCoach`) speaks the opening brief once. Next arrow at bottom-right. **No checklist on the title card.**
   * **Back button placement**: The back arrow is on the **title card only** (and Level 6's initial in-room coach beat). **Never** put a back arrow on the active work screen below the HUD.
   * **Clock sound**: Every playable work screen must call `ZlFx.holdClock()` in `initState` and `ZlFx.releaseClock()` in `dispose` so `clock_tick.wav` ticks throughout the work and stops cleanly when leaving. The clock never fails or closes a level.
   * **Score & Rank**: `+5` (`dressRight`) on the first time each required habit is done; `−5` (`dressWrong`) on a mistake or premature final action. Ranks stay `দারুণ` / `মোটামুটি` / `আবার`. Never pass `Offset.zero` to `onDelta`.
   * **Talking mouth**: `DsCoach` animates lips only while `DsTalk.active` is true and mood is `talk`. Glad/thanks moods use the happy face and stop cleanly when speech ends.

5. **Guide Speech Rules (One by One)**
   * **Opening (`brief.body`)**: States the job and what is already done, then ends with a natural prompt such as `এবার যা করার করুন।`
   * **First-time success (`_praise`, `DsCoachMood.glad`)**: Every correct habit check is spoken the **first time** it is done: name what was checked + `ঠিক আছে।`
   * **Mistake / premature action (`_showFaultCoach`, `DsCoachMood.oops`)**: If the player tries the final step early or touches a trap, deduct `−5` and speak **only the first missed habit** (or that single mistake). Never dump all remaining steps at once.
   * **Completion (`DsCoachMood.thanks`)**: After the end checklist ticks one line at a time, the guide speaks the closing praise while the completed scene stays visible behind.

6. **Locked Words & Digits**
   * Always **Western / English digits `0–9`** on screen (`11 kV`, `360°`, `10 মিনিট`). Run strings through [`enDigits`](../../core/en_digits.dart).
   * Words: `ডকেট`, `শাটডাউন`, `জল`, `গ্লাভস` (never দস্তানা). Tightness is the two-finger rule (never the fist line).

---

## 1. Master Level Architecture (31 Levels)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ TIER 1 (Levels 1–5)   : Foundational PPE (Basic Selection & Fitting)     │
├──────────────────────────────────────────────────────────────────────────┤
│ TIER 2 (Levels 6–10)  : Van Jobs (Dress + 3 Core Tools + Job Extras)     │
├──────────────────────────────────────────────────────────────────────────┤
│ TIER 3 (Levels 11–31) : Field Habit Mastery (Lesson-Based Real Scenes)   │
│   • 11 : पोলের ভাষা — Normal Pole Routine (ACTIVE)                       │
│   • 12–31 : 20 Planned Lesson-Based Levels (Detailed Below)              │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Tier 1: Foundational PPE (Levels 1–5) — *ACTIVE*

*Implemented in [`ds_dress_up.dart`](ds_dress_up.dart). Do not alter.*

* **Level 1 — পোশাক**: Full-sleeve cotton shirt, cotton trousers, dielectric boots.
* **Level 2 — মাথায় হেলমেট**: Remove *gamcha* to shelf, fit Class E electrical helmet.
* **Level 3 — হাতে গ্লাভস**: Clean dry rubber gloves (reject cotton, wet, punctured, bike gloves).
* **Level 4 — হারনেস**: Full-body harness (waist belt on shelf is a trap), buckle sequence + two-finger check.
* **Level 5 — পুরো কিট**: Full PPE in order.

---

## 3. Tier 2: Van Jobs (Levels 6–10) — *ACTIVE*

*Implemented in [`ds_dress_up.dart`](ds_dress_up.dart). The voltage detector (`tester`), discharge rod (`discharge`), and portable earthing kit (`earth`) are mandatory on every van. At the end of each job the van drives into the worksite and stays.*

* **Level 6 — ভ্যান সাজান**:
  * **Opening**: `কন্ট্রোল রুমের ভিতরে কাজের আদেশ এসেছে। দ্রুত তৈরি হতে হবে।`
  * **Keep**: Control-room dress (with face shield, no harness) + `tester`, `discharge`, `earth`.
* **Level 7 — খুঁটিতে ওঠা** (`bg_market_wire_down.webp`):
  * **Opening**: `গলিতে তার ছিঁড়ে মাটিতে পড়ে আছে। খুঁটিতে উঠতে হবে।`
  * **Extra tools**: FRP ladder, hand rope (`এই কাজে এফআরপি মই আর হাত-দড়িও লাগবে।`).
* **Level 8 — ট্রান্সফরমার মৃত করা** (`bg_dtr_structure.webp`):
  * **Opening**: `রিপোর্ট এসেছে, ট্রান্সফরমার খারাপ। বুশিং খুলে দেখতে হবে।`
  * **Extra tools**: Lock and board (`এই কাজে তালা আর বোর্ডও লাগবে।`).
* **Level 9 — রাতের লাইনে ফল্ট** (`bg_pole_storm.webp`):
  * **Opening**: `রাত দুপুরে লাইন ব্রেকডাউন হয়ে গেছে। রাস্তায় গাড়ি, আলো নেই। ফল্ট সারাতে হবে।`
  * **Extra dress/tools**: High-vis jacket + torch, FRP ladder, cones with tape (`এই কাজে টর্চ, এফআরপি মই আর কোন-ফিতেও লাগবে।`).
* **Level 10 — ডাল লাইনের উপর** (`bg_tree_on_line.webp`):
  * **Opening**: `ঝড়ে ডাল লাইনের উপর পড়েছে। লাইন ব্রেকডাউন। ডাল সরিয়ে লাইন চালু করতে হবে।`
  * **Extra tools**: Hand rope (`এই কাজে হাত-দড়িও লাগবে।`).

---

## 4. Level 11: পোলের ভাষা (Normal Pole Pre-Climb Habit) — *ACTIVE*

*Implemented in [`ds_pole_inspect.dart`](ds_pole_inspect.dart). Source: Lesson 1.3 (“পোলের ‘ভাষা’ পড়তে শিখুন”).*

* **Scene**: Real daylight photographs of one straight PCC pole (`pole11_title.jpg`, `pole11_front.jpg`, `pole11_front_clear.jpg`, `pole11_back.jpg`, `pole11_back_clear.jpg`) and hammer photo (`pole11_hammer.jpg`).
* **Top-Left Pre-Ticked Context** (ticks draw after 2s): `পিপিই`, `যন্ত্রপাতি`, `শাটডাউন`, `ডিসচার্জ`, `দুদিক আর্থ`.
* **Opening Speech**:
  * `পিপিই পরে নিয়েছেন, যন্ত্রপাতি সঙ্গে নিয়েছেন। শাটডাউন নিয়ে ডিসচার্জ ও দুদিক আর্থ করা হয়ে গেছে। এবার পোলে ওঠার আগে যা করার করুন।`
* **Four Habits & First-Success Speeches (`+5` each)**:
  1. Brush grass at foot (`grass`): `গোড়ার ঘাস সরানো হয়েছে। মাফিং ঠিক আছে।`
  2. Touch stay wire & insulator (`stay`): `স্টে-তার আর ইনসুলেটর টানটান। ঠিক আছে।`
  3. Turn 360° / check back earthing wire (`back`): `পেছনের দিক দেখা হয়েছে। আর্থিং তার ঠিক আছে।`
  4. Tap/drag hammer onto pole (`hammer`, `ঠক্ ঠক্`): `হাতুড়ি ঠুকে শব্দ নিরেট। ঠিক আছে।`
* **Premature Ladder Speeches (`−5`, one by one in order)**:
  * Missing `grass`: `গোড়ার ঘাস সরিয়ে মাটি আর মাফিংটা একবারও দেখলেন না?`
  * Missing `stay`: `স্টে-তার আর ইনসুলেটরটা টানটান আছে কি না ছুঁয়ে দেখলেন না?`
  * Missing `back`: `পোলের পেছনের দিকটা ঘুরে না দেখেই মই লাগাচ্ছেন? চারপাশ ও আর্থিং তারটা দেখুন।`
  * Missing `hammer`: `বাইরে থেকে দেখেই ভরসা করলেন? হাতুড়ি দিয়ে ঠুকে পোলের শব্দটা শুনুন।`
* **Closing Speech (`_pole11Done`)**:
  * `এই তো আসল লাইনম্যানের অভ্যাস! চারপাশ, গোড়া, স্টে-তার আর শব্দ দেখে তবেই মই লাগিয়েছেন।`

---

## 5. Planned 20 Lesson-Based Levels (Levels 12–31)

Every level below follows the exact Level 11 architecture: real photo title card with clean header, no back button on the work screen, `clock_tick.wav` held during play, top-left short pre-done ticks, picture-only bottom tray, one-by-one mistake coaching, first-success `ঠিক আছে` confirmation, and end checklist + thank-you.

---

### Level 12: ফাঁপা পোলের ভাষা (Hollow PCC Pole & Hidden Rebar)
* **Lesson Source**: Lesson 1.3 (“পোলের ‘ভাষা’ পড়তে শিখুন” — Pt 2 & 3: `দপ্ দপ্` hollow sound, spalling & exposed rebar at the back, reporting instead of climbing).
* **Scene**: Normal-looking PCC pole from the front. Clearing the grass reveals a hairline crack at the foot; turning 360° reveals spalled concrete and exposed rebar on the back; tapping with the hammer gives a dull hollow `দপ্ দপ্` sound instead of `ঠক্ ঠক্`.
* **Bottom Tray (Pictures Only)**: Hammer, FRP Ladder (trap here!), Red Danger Tag / Report Phone.
* **Opening Speech**:
  `পিপিই পরে নিয়েছেন, শাটডাউন ও দুদিক আর্থ করা হয়ে গেছে। পোলটা বাইরে থেকে সোজা দেখাচ্ছে। ওঠার আগে যা করার করুন।`
* **Success Speeches (`+5` each)**:
  * Grass cleared (`grass`): `গোড়ার ঘাস সরানো হয়েছে। ফাউন্ডেশনে চুলের মতো ফাটল দেখা যাচ্ছে। ঠিক আছে।`
  * Stay checked (`stay`): `স্টে-তার দেখা হয়েছে। ঠিক আছে।`
  * Back rotated (`back`): `পেছনের দিক দেখা হয়েছে। কংক্রিট খসে ভেতরের রড বেরিয়ে আছে! ঠিক আছে।`
  * Hammer tapped (`hammer` → `দপ্ দপ্`): `হাতুড়ি ঠুকে ফাঁপা দপ্ দপ্ শব্দ মিলেছে। ভেতরটা দুর্বল, ধরা পড়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Placing the FRP ladder before checking: speaks the first missed check (`_missGrass` / `_missStay` / `_missBack` / `_missHammer`).
  * Placing the FRP ladder **after** finding the hollow/rebar fault: `হাতুড়িতে দপ্ দপ্ শব্দ আর পেছনে রড বেরিয়ে আছে! এই পোল আপনার ভারে ভেঙে পড়বে। মই লাগাবেন না।`
  * Tapping Report/Danger Tag before completing the 4 checks: names the first missed check so the player proves why the pole is unfit before reporting.
* **Final Action & Closing Speech**:
  * Hang the Danger Tag / call supervisor to condemn the pole (lineman steps back safely, does not climb).
  * `সাবাশ! ফাঁপা শব্দ আর বেরিয়ে থাকা রড দেখে মই না লাগিয়ে বিপদ রিপোর্ট করেছেন। হিরো না হয়ে প্রাণ বাঁচিয়েছেন।`

---

### Level 13: স্টিল পোলের ক্যান্সার ও মাথার বিপদ (Steel Pole Base Rust & Top Scan)
* **Lesson Source**: Lesson 1.3 (“পোলের ‘ভাষা’ পড়তে শিখুন” — Pt 2, 3 & 4: Steel tubular/rail pole ground-line corrosion, `টন টন` vs dull rust flake, bottom-to-top scan for wasp nest / cable clutter / tilted cross-arm).
* **Scene**: Daylight photo of a steel tubular pole. Grass hides ground-line rust; looking up (vertical pan / look-up button) shows a cable tangle and a cracked pin insulator on the cross-arm.
* **Bottom Tray**: Hammer, Binocular/Look-Up scan, Hand Rope (to clear clutter after check), FRP Ladder.
* **Opening Speech**:
  `স্টিলের পোলে জাম্পারের কাজ আছে। শাটডাউন, ডিসচার্জ ও আর্থিং হয়ে গেছে। স্টিলের পোল ভাঙে না ভেবে সরাসরি উঠবেন না—যা করার করুন।`
* **Success Speeches (`+5` each)**:
  * Base grass & ground-line collar (`base`): `গোড়ার মাটি সরিয়ে জয়েন্ট দেখা হয়েছে। মরিচা নেই। ঠিক আছে।`
  * Hammer tap on steel (`hammer` → crisp `টন টন`): `হাতুড়ি ঠুকে পরিষ্কার টন টন শব্দ মিলেছে। ভেতরে জং নেই, ঠিক আছে।`
  * 360° clamp & weld check (`back`): `চারপাশ ঘুরে ওয়েল্ডিং জয়েন্ট ও আর্থিং দেখা হয়েছে। ঠিক আছে।`
  * Top scan (`top` — cross-arm & insulators): `নিচ থেকে মাথা পর্যন্ত ক্রস-আর্ম ও ইনসুলেটর দেখে নেওয়া হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Missing `base`: `স্টিল পোলের আসল শত্রু মাটির সংযোগস্থলের মরিচা। গোড়াটা পরিষ্কার করে দেখলেন না?`
  * Missing `hammer`: `স্টিলের পোলে হাতুড়ি ঠুকে টন টন শব্দটা যাচাই করলেন না?`
  * Missing `back`: `চারপাশ ঘুরে ওয়েল্ডিং জয়েন্ট আর ক্ল্যাম্পগুলো দেখলেন না?`
  * Missing `top`: `গোড়া থেকে ওপর পর্যন্ত চোখ বুলিয়ে ক্রস-আর্ম আর ইনসুলেটর দেখলেন না?`
* **Closing Speech**:
  `দারুণ অভ্যাস! গোড়ার জয়েন্ট, টন টন শব্দ আর মাথার ক্রস-আর্ম দেখে তবেই মই লাগিয়েছেন।`

---

### Level 14: লক্ষ্মণ রেখা (Safe Clearance & Crowd Barrier)
* **Lesson Source**: Lesson 1.2 (“পাওয়ার লাইনের ‘লক্ষ্মণ রেখা’”) & Lesson 10.4 (“সিইএ ২০২৩ ক্লিয়ারেন্স”).
* **Scene**: Roadside 11 kV pole next to a house balcony; curious bystanders standing too close; wet ground patch beside the pole; long metal pipe lying nearby.
* **Bottom Tray**: Cones & Barrier Tape, Dry Insulating Mat / Dry Board,FRP Ladder, Long Metal Pipe (trap).
* **Opening Speech**:
  `রাস্তার ধারে পোল, পাশেই বাড়ির বারান্দা আর লোকজনের ভিড়। কাজ শুরুর আগে নিজের আর সাধারণ মানুষের লক্ষ্মণ রেখা তৈরি করুন।`
* **Success Speeches (`+5` each)**:
  * Move bystanders back & place cones/tape (`crowd`): `ভিড় সরিয়ে কোন ও ফিতে দিয়ে সেফ জোন ঘেরা হয়েছে। ঠিক আছে।`
  * Clear wet/slippery ground & metal pipe at base (`ground`): `পোলের গোড়া থেকে ভেজা জঞ্জাল ও লোহার পাইপ সরানো হয়েছে। ঠিক আছে।`
  * Check overhead 11 kV horizontal clearance from balcony (`clearance`): `বারান্দা ও পাশের লাইভ লাইন থেকে নিরাপদ দূরত্ব দেখে নেওয়া হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Touching the metal pipe: `লম্বা লোহার পাইপ হাতে নিচ্ছেন কেন? ওভারহেড লাইনের লক্ষ্মণ রেখায় ঢুকে গেলে ছোঁয়ার আগেই আর্ক ফ্ল্যাশ হবে!`
  * Starting work before `crowd`: `চারপাশে লোকজন দাঁড়িয়ে আছে! আগে কোন-ফিতে দিয়ে কাজের জায়গা ঘিরে দিন।`
  * Starting work before `ground`: `পোলের নিচে লোহার পাইপ আর ভেজা জঞ্জাল পড়ে আছে। আগে জায়গাটা পরিষ্কার করুন।`
  * Starting work before `clearance`: `পাশের লাইন থেকে নিরাপদ দূরত্বটা একবারও মেপে দেখলেন না?`
* **Closing Speech**:
  `এই তো নিয়ম! ভিড় সরিয়ে, নিচের জায়গা পরিষ্কার করে আর লক্ষ্মণ রেখা মেনে কাজ শুরু করেছেন।`

---

### Level 15: হারনেসের তিন মিনিট (3-Minute Harness Pre-Use Inspection)
* **Lesson Source**: Lesson 1.4 (“সেফটি হারনেস: আপনার লাইফলাইন” — Webbing cut check, stitching check, D-ring/buckle rust check, expiry label check, high anchor above head).
* **Scene**: Close-up real photo of the full-body harness before climbing, followed by pole-top anchoring. One harness on the bench has a frayed strap / expired tag (trap); the second is sound.
* **Bottom Tray**: Good Full-Body Harness, Frayed/Expired Harness (trap), Waist Belt (trap), Energy-Absorber Lanyard.
* **Opening Speech**:
  `পোল যাচাই হয়ে গেছে। এবার নিজের প্যারাশুট, মানে ফুল বডি হারনেস পরার আগে ৩ মিনিটের গোল্ডেন রুল মেনে পরীক্ষা করুন।`
* **Success Speeches (`+5` each)**:
  * Pull-test webbing straps (`webbing`): `ফিতে টেনে দেখা হয়েছে, কোনো কাটা বা পোড়া দাগ নেই। ঠিক আছে।`
  * Inspect load stitching (`stitch`): `সবকটা সেলাই অক্ষত আছে। ঠিক আছে।`
  * Check back D-ring & buckles (`dring`): `ডি-রিং আর বকলসে কোনো ফাটল বা জং নেই। ঠিক আছে।`
  * Check manufacturer expiry label (`label`): `লেবেলে মেয়াদের তারিখ ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Picking waist belt: `কোমরের বেল্ট পতনের সময় শিরদাঁড়া ভেঙে দেয়! ফুল বডি হারনেস নিন।`
  * Picking frayed harness: `ফিতের কাটা দাগটা দেখলেন না? সামান্য ছেঁড়া ফিতে হারনেসের শক্তি অর্ধেক কমিয়ে দেয়!`
  * Wearing harness before checking `webbing` / `stitch` / `dring` / `label`: names the first unchecked part.
* **Closing Speech**:
  `চমৎকার! ফিতে, সেলাই, ডি-রিং আর মেয়াদ দেখে তবেই হারনেস পরেছেন।`

---

### Level 16: আগে মাটি, পরে লাইন (Discharge Rod & Shorting Chain Sequence)
* **Lesson Source**: Lesson 1.5 (“ডিসচার্জ রড ব্যবহারের কায়দা” — Check rod rating 11 kV, reject PVC jugaad pipe, connect earth clamp FIRST, touch R-Y-B phases with hook, then throw brass shorting chain).
* **Scene**: 11 kV pole after shutdown. On the ground: a homemade PVC-pipe hook (trap), an 11 kV fiberglass discharge rod with copper cable and earth clamp, and a clean brass ball-chain.
* **Bottom Tray**: 11 kV Standard Discharge Rod, PVC Jugaad Rod (trap), Rusty Iron Chain (trap), Clean Brass Shorting Chain.
* **Opening Speech**:
  `পারমিট হাতে পেয়েছেন, ব্রেকার অফ। কিন্তু ডেড লাইনেও ক্যাপাসিটিভ চার্জ লুকিয়ে থাকে। সঠিক নিয়মে লাইন ডিসচার্জ করুন।`
* **Success Speeches (`+5` each)**:
  * Inspect discharge rod label & copper lead (`inspect`): `১১ কেভি স্ট্যান্ডার্ড রড আর কপার কেবিল যাচাই হয়েছে। ঠিক আছে।`
  * Clamp earth lead to earth rod FIRST (`earth_first`): `আগে মাটির আর্থ পয়েন্টে ক্ল্যাম্প শক্ত করে লাগানো হয়েছে। ঠিক আছে।`
  * Touch R, Y, B conductors with the hook (`touch_ryb`): `তিনটি ফেজ ছুঁয়ে জমা চার্জ মাটিতে নামানো হয়েছে। ঠিক আছে।`
  * Throw clean brass shorting chain after rod (`chain`): `রডের পর পরিষ্কার ব্রাস চেইন দিয়ে ফেজ শর্ট করা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Touching PVC jugaad rod: `পিভিসি পাইপের জুগাড় রড ছোঁবেন না! ভেজা বা চার্জযুক্ত লাইনে ওটা নিজেই মরণফাঁদ।`
  * Touching overhead wire BEFORE clamping earth (`earth_first` missed): `সর্বনাশ! আগে আর্থ ক্ল্যাম্প মাটিতে না লাগিয়ে তারে রড ছোঁয়ালে চার্জ আপনার শরীর দিয়ে নামবে!`
  * Throwing brass chain BEFORE using the discharge rod: `চেইন রডের বদলি নয়! আগে ডিসচার্জ রড দিয়ে চার্জ নামান, তারপর চেইন ছুঁড়ুন।`
  * Picking rusty iron chain: `জং ধরা লোহার চেইনে কারেন্ট নামে না। পরিষ্কার ব্রাস বা কপার চেইন নিন।`
* **Closing Speech**:
  `একদম নিখুঁত! আগে মাটি, পরে লাইন—স্ট্যান্ডার্ড রডে ডিসচার্জ করে ব্রাস চেইন লাগিয়েছেন।`

---

### Level 17: কাগজের সই, প্রাণের গ্যারান্টি (PTW Verification & LOTO)
* **Lesson Source**: Lesson 1.6 (“পারমিট-টু-ওয়ার্ক (PTW): একটি জীবন বীমা”) & Lesson 10.5.
* **Scene**: Substation / feeder breaker panel and written PTW pad. A phone rings with a verbal “লাইন বন্ধ আছে, উঠে পড়ুন” message (trap).
* **Bottom Tray**: Padlock, Danger Tag, Written PTW Form, Verbal Phone Call Accept (trap).
* **Opening Speech**:
  `ফিডারে কাজ শুরু হবে। ফোনে কেউ বলছে লাইন বন্ধ আছে—কিন্তু নিয়ম মেনে পারমিট ও লটো (LOTO) সম্পূর্ণ করুন।`
* **Success Speeches (`+5` each)**:
  * Verify breaker OFF & visible isolation (`breaker`): `ব্রেকার অফ এবং আইসোলেশন নিশ্চিত করা হয়েছে। ঠিক আছে।`
  * Apply padlock and Danger Tag (`loto`): `ব্রেকারে তালা ও ডেঞ্জার ট্যাগ লাগানো হয়েছে। ঠিক আছে।`
  * Match Feeder Name, Permit Number, Validity Time & Signatures on PTW (`ptw_check`): `লিখিত পারমিটে ফিডারের নাম, সময় ও সই মিলিয়ে নেওয়া হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Accepting verbal phone clearance: `ফোনে বা মুখে বলা ‘লাইন বন্ধ আছে’ কথায় কখনো কাজে হাত দেবেন না! লিখিত PTW ও লটো চাই।`
  * Issuing/taking PTW before padlock & tag (`loto` missed): `ব্রেকারে তালা আর ট্যাগ না লাগালে যে কেউ ভুল করে লাইন চালু করে দেবে!`
  * Skipping feeder/time check on the PTW form: `পারমিটে ফিডারের নাম আর মেয়াদের সময়টা মিলিয়ে দেখলেন না?`
* **Closing Speech**:
  `সাবাশ! মৌখিক কথায় না ভুলে লটো করে লিখিত পারমিট মিলিয়ে তবেই কাজ ধরেছেন।`

---

### Level 18: দুদিকে প্রতিরক্ষা (Equipotential Zone & End-of-Work Un-Earthing)
* **Lesson Source**: Lesson 10.6 (“লাইন চেক ও আর্থিং: চার্জমুক্ত করার সঠিক কায়দা” — Two-side earthing for equipotential zone, and exact removal order at job end: tools down → man down → unclip phase → unclip earth last).
* **Scene**: Working span with upstream and downstream poles. Part 1 sets both-side earthing; Part 2 finishes the repair and tests the removal order.
* **Opening Speech**:
  `লাইন ডিসচার্জ করা হয়েছে। এবার কাজের জায়গাকে দুদিক থেকে সুরক্ষিত করুন, আর কাজ শেষে সঠিক ক্রমে আর্থিং খুলুন।`
* **Success Speeches (`+5` each)**:
  * Upstream earth applied (`up_earth`): `উজানের দিকে আর্থিং লাগানো হয়েছে। ঠিক আছে।`
  * Downstream earth applied (`down_earth`): `ভাটির দিকেও আর্থিং লাগিয়ে ইকুইপটেনশিয়াল জোন তৈরি হয়েছে। ঠিক আছে।`
  * Tools & lineman brought down first (`man_down`): `আগে যন্ত্রপাতি ও মানুষ পোল থেকে নিচে নেমেছে। ঠিক আছে।`
  * Phase clamp removed before ground clamp (`unearth_order`): `প্রথমে তারের দিক থেকে, আর সবার শেষে মাটির দিক থেকে আর্থ খোলা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Working with only one side earthed: `একদিকে আর্থিং করলে অন্য প্রান্তের ব্যাকফিড কে আটকাবে? দুদিকেই আর্থিং করুন।`
  * Touching earth clamp while lineman is still on the pole: `ওপরে মানুষ থাকতে আর্থিং খুলছেন কেন? আগে মানুষ ও টুলস নিচে নামবে!`
  * Removing the ground clamp before the overhead phase clamp: `আগে মাটির দিকের ক্ল্যাম্প খুললে তারের সাথে হাতে শক লাগবে! আগে তারের দিক খুলুন, শেষে মাটি।`
* **Closing Speech**:
  `দারুণ! দুদিকে আর্থিং করে কাজ করেছেন আর সবার শেষে নিয়ম মেনে আর্থ খুলেছেন।`

---

### Level 19: মেঘের ডাক ও কখন ‘না’ বলবেন (Storm, Lightning & Line Clear)
* **Lesson Source**: Lesson 1.9 (“ঝড়-বৃষ্টিতে কাজ: কখন ‘না’ বলবেন”) & Lesson 10.7 (Sec 4: Weather stop).
* **Scene**: Lineman is halfway through a job when dark thunderclouds roll in, wind rises, and lightning flashes in the distance.
* **Bottom Tray**: Bring Tools & Climb Down, Keep Working Quickly (trap), Shelter Under Tree/Pole (trap), Inform Control Room & Hold Permit Safely.
* **Opening Speech**:
  `কাজ চলছিল, হঠাৎ আকাশ কালো করে মেঘ ডাকছে আর ঝোড়ো হাওয়া শুরু হয়েছে। এই মুহূর্তে কী করবেন করুন।`
* **Success Speeches (`+5` each)**:
  * Stop work immediately & lower tools (`stop_work`): `ঝড়-বজ্রপাত দেখে সঙ্গে সঙ্গে কাজ থামিয়ে যন্ত্রপাতি নামানো হয়েছে। ঠিক আছে।`
  * Climb down from the pole (`climb_down`): `পোল থেকে নিরাপদে নিচে নেমে এসেছেন। ঠিক আছে।`
  * Move away from pole/trees to safe shelter & inform Control Room (`report_hold`): `গাছ ও পোল ছেড়ে নিরাপদ আশ্রয়ে গিয়ে কন্ট্রোল রুমকে জানানো হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Tapping Keep Working: `বজ্রপাত দূরে হচ্ছে ভেবে কাজ চালাবেন না! বিদ্যুৎ আলোর গতিতে তার বেয়ে আপনার পোলে চলে আসবে।`
  * Tapping Shelter Under Tall Tree/Pole: `বজ্রপাতের সময় উঁচু পোল বা গাছের নিচে দাঁড়ানো মানে বিপদকে ডেকে আনা!`
* **Closing Speech**:
  `বুদ্ধিমানের কাজ! প্রকৃতির বিরুদ্ধে হিরো না সেজে কাজ থামিয়ে নিরাপদে নেমে এসেছেন।`

---

### Level 20: গোল্ডেন মিনিট ও উদ্ধার (Shock First Aid & CPR)
* **Lesson Source**: Lesson 1.7 (“শক লাগলে ফার্স্ট এইড” — Do not touch victim with bare hands, cut source or push with dry fiberglass/wood at limb, check response, call ambulance, continuous chest compressions; reject mud/burial myth).
* **Scene**: A ground worker is in contact with an energized service drop wire.
* **Bottom Tray**: Bare Hand Pull (trap), Wet Bamboo (trap), Dry Fiberglass Hot Stick / Dry Wood, Mud Bucket (myth trap), Ambulance Call, CPR Hand Placement.
* **Opening Speech**:
  `সর্বনাশ! এক সহকর্মী ছেঁড়া তারে শক খেয়ে আটকে আছেন। মাথা ঠান্ডা রেখে গোল্ডেন মিনিটের নিয়ম মানুন।`
* **Success Speeches (`+5` each)**:
  * Use dry fiberglass stick / cut main switch to separate victim (`separate`): `নিজে না ছুঁয়ে শুকনো ফাইবারগ্লাস স্টিক দিয়ে তার আলাদা করা হয়েছে। ঠিক আছে।`
  * Tap shoulder & check breathing (`response`): `কাঁধে ডেকে সাড়া ও শ্বাস পরীক্ষা করা হয়েছে। ঠিক আছে।`
  * Call emergency ambulance (`ambulance`): `অবিলম্বে অ্যাম্বুলেন্সে খবর দেওয়া হয়েছে। ঠিক আছে।`
  * Start chest compressions (`cpr`): `বুকের মাঝখানে সঠিক ছন্দে সিপিআর শুরু হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Bare hand touch: `খালি হাতে ছোঁবেন না! ওঁর শরীর এখন লাইভ তারের মতো—আপনিও সার্কিটে আটকে যাবেন!`
  * Mud/earth myth: `শরীরে কাদা মাখানো বা মাটিতে পুঁতে রাখা মারাত্মক কুসংস্কার! সময় নষ্ট না করে চিকিৎসা শুরু করুন।`
  * Starting CPR before separating from wire: `আগে বিদ্যুতের উৎস থেকে মানুষটিকে আলাদা করুন!`
* **Closing Speech**:
  `সাবাশ! নিজে নিরাপদ থেকে, কুসংস্কারে না ভুলে গোল্ডেন মিনিটে সিপিআর দিয়ে প্রাণ বাঁচিয়েছেন।`

---

### Level 21: ভুয়ো টেস্টারের ফাঁদ (Non-Contact Voltage Detector & Self-Test)
* **Lesson Source**: Lesson 2.1 (“লাইনম্যানের টুলবক্স ও ভোল্টেজ টেস্টার” — Prove-Test-Prove method, battery/self-test button, never use a 230 V domestic neon screwdriver on 11 kV).
* **Scene**: 11 kV conductor inspection from the ground/ladder with telescopic hot stick.
* **Bottom Tray**: Neon Screwdriver Tester (trap), 11 kV Non-Contact HV Detector, Self-Test Button, Telescopic Insulating Rod.
* **Opening Speech**:
  `শাটডাউন নেওয়া হয়েছে, কিন্তু লাইন সত্যিই ডেড কি না নিজের চোখে প্রমাণ করতে হবে। সঠিক টেস্টার বেছে পরীক্ষা করুন।`
* **Success Speeches (`+5` each)**:
  * Select 11 kV HV detector & self-test (`self_test`): `টেস্টারের সেলফ-টেস্ট বোতাম টিপে আলো ও বিপ শব্দ যাচাই হয়েছে। ঠিক আছে।`
  * Attach to clean dry telescopic insulating rod (`rod_mount`): `শুকনো হট স্টিকের মাথায় টেস্টার বসানো হয়েছে। ঠিক আছে।`
  * Test all three phases R-Y-B (`test_phases`): `তিনটি ফেজেই কোনো ভোল্টেজ নেই, প্রমাণিত হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Picking domestic neon tester: `বাড়ির প্লাগ চেক করার নিয়ন টেস্টার ১১ কেভি লাইনে ধরলে বিস্ফোরণ হবে! হাই-ভোল্টেজ ডিটেক্টর নিন।`
  * Testing the line before pressing self-test: `টেস্টারের ব্যাটারি ঠিক আছে কি না আগে সেলফ-টেস্ট করে দেখে নিন! নষ্ট টেস্টার লাইভ লাইনকেও ডেড দেখাবে।`
* **Closing Speech**:
  `এই তো নিয়ম! আগে টেস্টার পরীক্ষা করে, হট স্টিকে লাগিয়ে তবেই লাইন ডেড নিশ্চিত করেছেন।`

---

### Level 22: কাম-অ্যালং ও বিপদের নিশানা (Conductor Pulling & Line of Fire)
* **Lesson Source**: Lesson 2.4 (“কাম-অ্যালং পুলার ও তার টানা” — Clean parallel-jaw aluminum grip, reject toothed iron grip on ACSR, clear the line-of-fire, release ratchet notch by notch).
* **Scene**: Sagging ACSR aluminum conductor being tensioned on a pole.
* **Bottom Tray**: Parallel-Jaw Aluminum Come-Along Grip, Toothed Steel Grip (trap), Wire Brush (to clean grease from jaws), Ratchet Hoist (step-by-step release vs sudden dump trap).
* **Opening Speech**:
  `অ্যালুমিনিয়ামের তার টানতে হবে। টানটান তারে শত শত কেজির শক্তি জমে থাকে। সঠিক গ্রিপ ও কৌশল ব্যবহার করুন।`
* **Success Speeches (`+5` each)**:
  * Clean grip jaws with wire brush (`clean_jaw`): `গ্রিপের চোয়াল থেকে তেল ও ময়লা পরিষ্কার করা হয়েছে। ঠিক আছে।`
  * Fit parallel-jaw grip on ACSR wire (`parallel_grip`): `অ্যালুমিনিয়াম তারে সমান্তরাল চোয়ালের গ্রিপ লাগানো হয়েছে। ঠিক আছে।`
  * Clear crew out of the line of fire (`clear_line`): `টানটান তারের সোজা নিশানা থেকে সবাইকে সরানো হয়েছে। ঠিক আছে।`
  * Release ratchet one notch at a time after clamping (`slow_release`): `ডেড-এন্ড ক্ল্যাম্পে বেঁধে এক দাঁত এক দাঁত করে টান ছাড়া হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Picking toothed grip for ACSR: `দাঁতওয়ালা গ্রিপ অ্যালুমিনিয়ামের নরম সুতো কেটে দেবে! সমান্তরাল চোয়ালের গ্রিপ নিন।`
  * Pulling before cleaning greasy jaws: `চোয়ালে তেল-গ্রিজ থাকলে টানের মুখে তার ফসকে চাবুকের মতো ছিটকে আসবে!`
  * Sudden ratchet release: `এক ঝটকায় লক খুলবেন না! প্রচণ্ড ঝাঁকুনিতে পোল বা ইনসুলেটর ভেঙে পড়বে।`
* **Closing Speech**:
  `ওস্তাদের কাজ! সঠিক গ্রিপে তার টেনে, নিশানা ফাঁকা রেখে ধাপে ধাপে টান ছেড়েছেন।`

---

### Level 23: মেগার করার আগে সতর্কতা (Megger Insulation Test Protocol)
* **Lesson Source**: Lesson 2.7 (“মেগার দিয়ে ইনসুলেশন পরীক্ষা”) & Lesson 9.4 (“কেবিল টেস্টিং”).
* **Scene**: Underground/overhead cable section ready for Insulation Resistance (IR) testing. A helper is standing near the far end unless warned; the cable still holds capacitive charge after the test.
* **Bottom Tray**: Warn & Clear Far End, Isolate Both Ends, 1000 V Megger Test, Discharge Cable After Megger.
* **Opening Speech**:
  `মেরামতের পর লাইন চার্জ করার আগে মেগার দিয়ে ইনসুলেশন রেজিস্ট্যান্স মাপতে হবে। নিরাপদ ক্রমে পরীক্ষাটি করুন।`
* **Success Speeches (`+5` each)**:
  * Isolate both ends & disconnect loads (`isolate`): `দুই প্রান্তের সংযোগ বিচ্ছিন্ন করা হয়েছে। ঠিক আছে।`
  * Warn crew & clear far end (`warn_crew`): `অন্য প্রান্ত থেকে সবাইকে সরিয়ে সতর্ক করা হয়েছে। ঠিক আছে।`
  * Run Megger & read IR value (`megger_run`): `মেগার টেস্ট সম্পূর্ণ হয়েছে, ইনসুলেশন রেজিস্ট্যান্স ঠিক আছে।`
  * Discharge cable after Megger before touching (`post_discharge`): `মেগারের হাই-ভোল্টেজ চার্জ ডিসচার্জ করে নামানো হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Cranking Megger while someone is near the conductor: `সাবধান! মেগার নিজেই হাই ভোল্টেজ পাঠায়। আগে অন্য প্রান্ত থেকে সবাইকে সরান!`
  * Unclipping leads bare-handed right after Megger without discharging: `মেগার করার পর কেবলে চার্জ জমে থাকে! হাত দেওয়ার আগে ডিসচার্জ করুন।`
* **Closing Speech**:
  `চমৎকার! সবাইকে সরিয়ে মেগার করেছেন এবং শেষে আবার ডিসচার্জ করে কেবল নিরাপদ করেছেন।`

---

### Level 24: ক্রেডল গার্ডিংয়ের ফাঁদ (Road-Crossing Cradle Guarding)
* **Lesson Source**: Lesson 3.9 (“গার্ড ওয়্যার ও ক্রেডল গার্ডিং: অতিরিক্ত সুরক্ষা জাল” — Never touch guard wire assuming it is dead; check guard earthing bond, broken cross-lacing, and vertical clearance).
* **Scene**: 11 kV road crossing where a cradle guard net hangs below the phase wires. One cross-wire is sagging and the guard earth bond at the pole is loose.
* **Bottom Tray**: Voltage Detector (test guard net first!), Bare Hand Grab (trap), Earth Bond Wrench, Guard Wire Tensioner.
* **Opening Speech**:
  `রাস্তা পারাপারের ক্রেডল গার্ডিং মেরামত করতে হবে। গার্ড তারে কারেন্ট থাকে না ভেবে সরাসরি হাত দেবেন না—নিয়ম মেনে কাজ করুন।`
* **Success Speeches (`+5` each)**:
  * Test guard wire for voltage first (`test_guard`): `আগে টেস্টার দিয়ে দেখা হয়েছে গার্ড জালটি লাইভ হয়ে নেই। ঠিক আছে।`
  * Restore/tighten guard earthing bond (`earth_bond`): `গার্ডিংয়ের আর্থিং কানেকশন মজবুত করা হয়েছে। ঠিক আছে।`
  * Repair broken cross-wire & restore clearance (`fix_cradle`): `ছিঁড়ে ঝুলে থাকা জাল বেঁধে সঠিক ক্লিয়ারেন্স রাখা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Touching guard wire before voltage test: `গার্ডিংয়ের আর্থিং কাটা থাকলে পুরো জালটাই লাইভ হয়ে থাকে! আগে টেস্টার দিয়ে পরীক্ষা করুন।`
  * Tensioning cradle before fixing its earth bond: `আগে গার্ডিং কাঠামোর আর্থিং ঠিক করুন, নইলে তার ছিঁড়ে পড়লে ব্রেকার ট্রিপ করবে না!`
* **Closing Speech**:
  `দারুণ! গার্ড তারকেও লাইভ ধরে পরীক্ষা করে, আর্থিং বেঁধে তবেই জাল মেরামত করেছেন।`

---

### Level 25: ডিও ফিউজ ও আর্ক ফ্ল্যাশ (DO Fuse Operating Stance & Hot Stick)
* **Lesson Source**: Lesson 4.4 (“ডিও (DO) ফিউজ পরিচালনা করা” — Wear face shield, use operating hot stick, never pull with gloves alone, stand to the side not directly underneath, turn face away on firm pull/close, keep expulsion port clear).
* **Scene**: 11 kV DTR structure with Drop-Out (DO) fuse barrels.
* **Bottom Tray**: Face Shield, Telescopic Hot Stick, Pull With Gloved Hand Only (trap), Stand Directly Under Barrel (trap), Side Stance & Firm Pull.
* **Opening Speech**:
  `ট্রান্সফরমারের ডিও ফিউজ খুলতে ও নতুন লিঙ্ক বাঁধতে হবে। আর্ক ফ্ল্যাশ ও গরম গ্যাসের ঝাপটা এড়িয়ে সঠিক কায়দায় কাজটি করুন।`
* **Success Speeches (`+5` each)**:
  * Lower face shield (`visor`): `চোখ ও মুখ বাঁচাতে ফেস শিল্ড নামানো হয়েছে। ঠিক আছে।`
  * Take side stance (not directly under expulsion vent) (`stance`): `ফিউজের ঠিক নিচে না দাঁড়িয়ে একপাশে অবস্থান নিয়েছেন। ঠিক আছে।`
  * Use hot stick with firm pull (`hotstick_pull`): `হট স্টিক দিয়ে মুখ পাশে রেখে এক টানে ব্যারেল খোলা হয়েছে। ঠিক আছে।`
  * Tie fuse link keeping bottom expulsion port open (`link_tie`): `এক্সপেলশন মুখ খোলা রেখে সঠিক মাপের ফিউজ লিঙ্ক বাঁধা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Pulling without face shield: `ফেস শিল্ড ছাড়া ডিও ফিউজ খুললে আর্কের ফুলকি সরাসরি চোখে-মুখে লাগবে!`
  * Standing directly under the fuse barrel: `ফিউজের ঠিক নিচে দাঁড়াবেন না! নিচের মুখ দিয়ে প্রচণ্ড গরম গ্যাস ও আগুনের ঝাপটা বেরোয়।`
  * Reaching without hot stick: `হাতে গ্লাভস থাকলেও হট স্টিক ছাড়া ফিউজ ছোঁয়া মারাত্মক ভুল!`
* **Closing Speech**:
  `এই তো পাকা হাতের কাজ! ফেস শিল্ড পরে, পাশে দাঁড়িয়ে হট স্টিকে নিরাপদে ডিও ফিউজ অপারেট করেছেন।`

---

### Level 26: অফ-লোড আইসোলেটর (AB Switch vs Load Current)
* **Lesson Source**: Lesson 6.4 (“AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার” — AB switch is strictly an OFF-LOAD device; open LT ACB/MCCB first, verify handle earthing, pull gang handle firmly, visually inspect all 3 blades).
* **Scene**: DTR DP structure with gang-operated 11 kV AB switch on top and LT distribution box below.
* **Bottom Tray**: Open LT Breaker First, Pull AB Switch Handle Under Load (lethal trap), Check Handle Earthing Braid, Binocular / Visual 3-Blade Gap Check, Padlock Handle.
* **Opening Speech**:
  `এলাকায় কাজের জন্য ১১ কেভি এবি (AB) সুইচ খুলতে হবে। মনে রাখবেন আইসোলেটরের আর্ক নেভানোর ক্ষমতা নেই—সঠিক ক্রমে সুইচ খুলুন।`
* **Success Speeches (`+5` each)**:
  * Open LT breaker / load first (`off_load`): `প্রথমে এলটি ব্রেকার অফ করে লাইন নো-লোড করা হয়েছে। ঠিক আছে।`
  * Check operating handle earth strip (`handle_earth`): `অপারেটিং হ্যান্ডেলের আর্থিং স্ট্রিপ দেখে নেওয়া হয়েছে। ঠিক আছে।`
  * Operate gang handle firmly (`open_ab`): `হ্যান্ডেল ঘুরিয়ে এবি সুইচ খোলা হয়েছে। ঠিক আছে।`
  * Verify all 3 phase blades open & lock handle (`check_blades`): `তিনটি ফেজের ব্লেডই পুরো খুলেছে দেখে হ্যান্ডেলে তালা দেওয়া হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Pulling AB switch while LT load is still ON: `সর্বনাশ! লোড চলাকালীন এবি সুইচ খুললে ভয়ানক আর্ক ফ্ল্যাশ হয়ে পুরো স্ট্রাকচার পুড়ে যাবে! আগে এলটি ব্রেকার অফ করুন।`
  * Operating handle before checking handle earthing: `অপারেটিং পাইপের আর্থিং তারটা ঠিক আছে কি না আগে দেখে নিন!`
  * Walking away without checking if a blade stuck closed: `অনেক সময় তিনটের মধ্যে একটা ব্লেড আটকে থাকে! ওপরে তাকিয়ে তিনটি ফেজের গ্যাপই নিশ্চিত করুন।`
* **Closing Speech**:
  `চমৎকার! আগে লোড কেটে, হ্যান্ডেল আর্থ দেখে এবি সুইচ খুলে তিনটি ব্লেডের গ্যাপই যাচাই করেছেন।`

---

### Level 27: এলটি ফিডার পিলার ও এইচআরসি ফিউজ (LT Feeder Pillar & HRC Fuse)
* **Lesson Source**: Lesson 6.9 (“এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার” — 415 V high fault-current arc hazard, check water/rodent entry, use insulated HRC fuse puller with face shield, reject copper-wire bridging myth, lock pillar door at the end).
* **Scene**: Open street-side 415 V LT feeder pillar with R-Y-B busbars, HRC fuse bases, and a burned loose lug hotspot.
* **Bottom Tray**: Face Shield & Insulated Fuse Puller, Bare Hand / Pliers on Fuse (trap), Thick Copper Wire Bridge (myth trap), Correct Rated HRC Fuse Link, Torque Tighten & Lock Door.
* **Opening Speech**:
  `৪১৫ ভোল্টের ফিডার পিলারে একটি ফিউজ উড়ে গেছে আর ভেতরে পোড়া গন্ধ। কম ভোল্টেজ ভেবে হালকাভাবে নেবেন না—নিরাপদে কাজ করুন।`
* **Success Speeches (`+5` each)**:
  * Inspect inside for water/rodents & hotspot (`inspect_box`): `বক্সের ভেতর জল বা শর্ট ও লুজ কানেকশনের হটস্পট দেখা হয়েছে। ঠিক আছে।`
  * Pull blown fuse using insulated HRC puller (`pull_hrc`): `ফেস শিল্ড পরে ইনসুলেটেড পুলার দিয়ে এইচআরসি ফিউজ খোলা হয়েছে। ঠিক আছে।`
  * Tighten loose busbar terminal & fit rated HRC fuse (`fit_rated`): `লুজ টার্মিনাল টাইট দিয়ে সঠিক রেটিংয়ের এইচআরসি ফিউজ বসানো হয়েছে। ঠিক আছে।`
  * Close and lock feeder pillar door (`lock_door`): `কাজ শেষে জনসাধারণের সুরক্ষায় পিলারের দরজা লক করা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Bridging fuse carrier with thick copper wire: `ফিউজের জায়গায় মোটা তামার তার বাঁধবেন না! পরের ফল্টে ফিউজ না কেটে পুরো পিলার বিস্ফোরিত হবে।`
  * Pulling HRC fuse without insulated puller: `৪১৫ ভোল্টের বাসবারে প্রচণ্ড ফল্ট কারেন্ট থাকে! খালি হাতে বা সাধারণ প্লায়ার্স দিয়ে ফিউজ ধরবেন না।`
  * Finishing without locking the pillar door: `ফিডার পিলারের দরজা খোলা রেখে যাবেন না! রাস্তার মানুষ বা বাচ্চাদের বড় বিপদ ঘটবে।`
* **Closing Speech**:
  `সাবাশ! মোটা তারের জুগাড় না করে সঠিক এইচআরসি ফিউজ লাগিয়ে পিলারের দরজা লক করেছেন।`

---

### Level 28: ছাদের সোলার ও লুকানো ব্যাকফিড (Rooftop Solar Anti-Islanding & Backfeed)
* **Lesson Source**: Lesson 8.8 (“নেট মিটারিং রেগুলেশন: সৌরশক্তির নিয়ম”) & Lesson 10.7 (“সেফ জোন ও ব্যাকফিড”).
* **Scene**: LT pole in a neighborhood where a house has rooftop solar panels and a bi-directional net meter, plus a shop with a portable diesel generator changeover.
* **Bottom Tray**: DTR LT Breaker OFF, Check Green Solar Net-Meter Tag & Isolate Prosumer Service Fuse, Check Shop Generator Changeover, Voltage Test & Earth LT Line.
* **Opening Speech**:
  `ট্রান্সফরমার থেকে শাটডাউন নেওয়া হয়েছে, কিন্তু পাড়ার ছাদে সোলার প্যানেল আর দোকানে জেনারেটর আছে। লুকানো ব্যাকফিড রুখে লাইন নিরাপদ করুন।`
* **Success Speeches (`+5` each)**:
  * Spot solar prosumer & pull pole service fuse / AC isolator (`solar_cut`): `সোলার বাড়ির সার্ভিস ফিউজ ও আইসোলেটর খুলে ব্যাকফিড পথ বন্ধ করা হয়েছে। ঠিক আছে।`
  * Verify shop generator changeover is isolated (`gen_cut`): `দোকানের জেনারেটর চেঞ্জওভার বিচ্ছিন্ন নিশ্চিত করা হয়েছে। ঠিক আছে।`
  * Test LT line dead & apply portable earth (`lt_earth`): `এলটি লাইনে ভোল্টেজ নেই দেখে আর্থিং লাগানো হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Climbing/touching LT line right after DTR shutdown without isolating solar/generator: `শুধু ট্রান্সফরমার অফ করলেই চলবে না! ছাদের সোলার ইনভার্টার বা জেনারেটর থেকে ব্যাকফিড কারেন্ট এসে মরা তারকে সজীব করে রাখবে!`
* **Closing Speech**:
  `ওস্তাদের চোখ! সোলার আর জেনারেটরের ব্যাকফিড পথ বন্ধ করে তবেই এলটি লাইনে হাত দিয়েছেন।`

---

### Level 29: ক্যাপাসিটর ব্যাংকের ঘুমন্ত বাঘ (Capacitor Bank 10-Minute Wait & Discharge)
* **Lesson Source**: Lesson 9.9 (“ক্যাপাসিটর ব্যাংক টেস্টিং: পাওয়ার বুস্টারের কার্যকারিতা” — 10-minute wait rule after isolation, terminal-by-terminal discharge rod shorting, terminal shorting wire, spotting a bulged/leaking capacitor can).
* **Scene**: 11 kV capacitor bank rack inside a fenced bay. One capacitor can is visibly bulged with oil seepage.
* **Bottom Tray**: Touch/Measure Immediately After Switch-Off (lethal trap), Wait 10-Minute Bleed Timer, Discharge Rod on Every Terminal, Short Terminals With Wire, Flag Bulged Can for Replacement.
* **Opening Speech**:
  `ক্যাপাসিটর ব্যাংক অফ করা হয়েছে। মনে রাখবেন অফ করার পরেও ক্যাপাসিটর লোডেড বন্দুকের মতো চার্জ ধরে রাখে। সঠিক নিয়মে পরীক্ষা করুন।`
* **Success Speeches (`+5` each)**:
  * Complete 10-minute bleed wait (`wait_10m`): `ডিসচার্জ রেজিস্টরে চার্জ কমার জন্য পুরো 10 মিনিট অপেক্ষা করা হয়েছে। ঠিক আছে।`
  * Discharge each capacitor terminal to earth with rod (`rod_cap`): `ডিসচার্জ রড দিয়ে প্রতিটি টার্মিনাল আর্থের সাথে শর্ট করা হয়েছে। ঠিক আছে।`
  * Apply shorting wire across terminals (`short_wire`): `কাজ চলাকালীন টার্মিনালগুলো তার দিয়ে শর্ট করে রাখা হয়েছে। ঠিক আছে।`
  * Identify bulged/leaking can for replacement (`bulge_can`): `ফুলে ওঠা ক্যাপাসিটর ক্যানটি চিহ্নিত করা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Touching or using meter before the 10-minute wait: `সুইচ অফ করেই সাথে সাথে হাত দেবেন না! অন্তত 10 মিনিট অপেক্ষা করুন, নইলে পূর্ণ ভোল্টেজের চার্জে বড় বিপদ ঘটবে।`
  * Using capacitance meter before discharge rod: `মাপার আগে ডিসচার্জ রড দিয়ে প্রতিটি টার্মিনাল শর্ট করে চার্জ শূন্য করুন!`
* **Closing Speech**:
  `দারুণ শৃঙ্খলা! 10 মিনিট অপেক্ষা করে, ডিসচার্জ ও শর্ট করে তবেই ফোলা ক্যাপাসিটর চিহ্নিত করেছেন।`

---

### Level 30: মাটির নিচের অদৃশ্য বিপদ (Underground Cable Trench & Spiking Gun)
* **Lesson Source**: Lesson 10.10 (“আন্ডারগ্রাউন্ড কেবল: মাটির নিচের বিপদ” — Stop pickaxe at red brick/warning tape, trace & tag correct cable among multiple cables in trench, remote spiking gun before cutting).
* **Scene**: Open road trench with red warning tape, protective bricks, and three black armored cables lying side by side.
* **Bottom Tray**: Heavy Pickaxe Near Cable (trap), Plastic Shovel / Hand Clear, Cable Route Tracer & Tag Check, Remote Insulated Spiking Gun, Hacksaw Cut Directly (lethal trap).
* **Opening Speech**:
  `গর্তে তিনটি আন্ডারগ্রাউন্ড কেবল পাশাপাশি রয়েছে। ভুল কেবল কাটলে মারাত্মক বিস্ফোরণ হবে। নিয়ম মেনে সঠিক কেবলটি যাচাই করুন।`
* **Success Speeches (`+5` each)**:
  * Stop sharp digging at warning tape & clear gently (`gentle_dig`): `সতর্কতা ফিতে ও ইট দেখে কোদাল থামিয়ে সাবধানে মাটি সরানো হয়েছে। ঠিক আছে।`
  * Match cable marker & tracer on target cable (`trace_tag`): `ট্রেসার ও মার্কার মিলিয়ে সঠিক কেবলটি সনাক্ত করা হয়েছে। ঠিক আছে।`
  * Clear trench crew & fire remote spiking gun (`spike_gun`): `সবাইকে দূরে সরিয়ে রিমোট স্পাইকিং গান দিয়ে কেবলটি ডেড নিশ্চিত করা হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Swinging pickaxe after warning tape: `লাল ইট আর সতর্কতা ফিতে পাওয়ার পরেও গাঁইতি চালাচ্ছেন? ইনসুলেশন কেটে এখনই ব্লাস্ট হবে!`
  * Cutting cable with hacksaw before tracer & spiking gun: `স্পাইকিং ছাড়া কখনো আন্ডারগ্রাউন্ড কেবল কাটবেন না! একই গর্তে পাশের লাইভ কেবল কাটলে মৃত্যু অবধারিত।`
* **Closing Speech**:
  `একদম সঠিক! ট্রেসার দিয়ে কেবল চিনে, দূর থেকে স্পাইকিং করে তবেই কাটার অনুমতি দিয়েছেন।`

---

### Level 31: চালু লাইনের নিচে গাছের ডাল (Tree Trimming With Rope & Clear Drop Zone)
* **Lesson Source**: Lesson 4.8 (“গাছের ডালপালা ছাঁটা”) & Lesson 10.7 (“সেফ জোন ও অটো-রিক্লোজার”).
* **Scene**: Heavy tree branch overhanging an 11 kV span; road below; helper with guide rope.
* **Bottom Tray**: Climb Out on Wet Branch (trap), Tie Guide Rope Before Cut, Clear Drop Zone Below, Insulated Pole Pruner / Saw After Shutdown & Earth.
* **Opening Speech**:
  `শাটডাউন ও আর্থিং নেওয়া হয়েছে, এবার লাইনের ওপর ঝুলে থাকা ভারী ডালটি কাটতে হবে। ডাল যেন তারের ওপর বা মানুষের গায়ে না পড়ে—যা করার করুন।`
* **Success Speeches (`+5` each)**:
  * Barricade drop zone directly under the branch (`drop_zone`): `ডাল পড়ার জায়গা থেকে সবাইকে সরিয়ে ঘিরে দেওয়া হয়েছে। ঠিক আছে।`
  * Tie hand-rope to control branch swing before cutting (`tie_rope`): `কাটার আগে ডালে হাত-দড়ি বেঁধে টান নিয়ন্ত্রণে রাখা হয়েছে। ঠিক আছে।`
  * Anchor on firm trunk/ladder (never on the branch being cut) & cut cleanly (`safe_cut`): `মজবুত জায়গায় অ্যাঙ্কর করে দড়ির টানে তার বাঁচিয়ে ডাল নামানো হয়েছে। ঠিক আছে।`
* **Mistake Speeches (`−5`)**:
  * Cutting branch before tying guide rope: `দড়ি না বেঁধে কাটলে ভারী ডাল সরাসরি তারের ওপর পড়ে তার ছিঁড়ে ফেলবে!`
  * Standing/anchoring on the branch being cut: `যে ডাল কাটছেন তার ওপর ভর দেবেন না!`
  * Cutting while people stand in the drop zone below: `নিচে মানুষ দাঁড়িয়ে আছে! আগে ডাল পড়ার জায়গা ফাঁকা করুন।`
* **Closing Speech**:
  `চমৎকার! নিচে জায়গা ফাঁকা রেখে, আগে দড়ি বেঁধে তার ও মানুষ দুই-ই বাঁচিয়ে ডাল নামিয়েছেন।`

---

## 6. Code Structure & Architecture Guidelines

* **Engine Configuration**: [`duty_slip_engine.dart`](duty_slip_engine.dart)
  - `dsLevels`: List of `DsLevelSpec`. Defines level numbers, choices, and `darunSec` target times.
  - `dressLevel`: Currently returns `true` for `level.isLetters && level.number <= 11` (extend as interactive field habit levels 12+ replace quiz placeholders).
  - `dsBriefFor`: Returns level title and opening speech (`brief.body`).
* **UI & Intro Presentation**: [`duty_slip_page.dart`](duty_slip_page.dart)
  - `_dressIntroArt`: Returns the full-screen photograph for the level introduction card.
  - `_DressIntro`: Renders the clean header (Back arrow, `লেভেল N`, diamond rule, title) and centered guide speech.
* **Interactive Habit Levels**:
  - Levels 1–10: [`ds_dress_up.dart`](ds_dress_up.dart)
  - Level 11+: [`ds_pole_inspect.dart`](ds_pole_inspect.dart) (and dedicated field habit widgets following the exact same contract: `ZlFx.holdClock()` / `ZlFx.releaseClock()`, no in-level back arrow, top-left pre-done ticks, `_praise` on first success, `_showFaultCoach` one-by-one on mistake, end checklist + thank-you).
