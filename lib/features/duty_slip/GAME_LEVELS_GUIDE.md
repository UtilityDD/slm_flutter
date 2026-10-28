# Mrityuhin Poth (মৃত্যুহীন পথ) — Game Levels Developer Guide

> **Important**: All Bengali text in this module must be saved in clean UTF-8. Do not use PowerShell `Set-Content` (which causes mojibake); edit within the IDE or agent tools.

---

## Numbers on screen

Always show **Western / English digits 0–9**, even when the rest of the line is Bangla and even if the device language is Bengali.

* Clocks, scores, level numbers, and counts stay ASCII. Never convert them to `০–৯`.
* Shared helper: [`enDigits`](../../core/en_digits.dart). Run it on copy and JSON before the string appears on screen. Duty-slip `fill()`, pack `fromJson`, Life Skill `lsDigits`, and Identify `chartEnglishDigits` all go through it.
* Theme `bangla()` and `zlText` set `FontFeature.localeAware(enable: false)` plus a Latin fallback (`Roboto` / `Noto Sans`) so Noto Sans Bengali cannot draw ASCII `0–9` as Bengali glyphs.
* New UI copy: write `11 kV`, `23 ধাপ`, `0 লক্ষ্য` — never `১১` / `২৩` / `০`. Bangla words stay Bangla; only the digits change.

---

## 1. Vision & Core Philosophy

**Mrityuhin Poth (মৃত্যুহীন পথ)** is a life-saving simulation game for electrical distribution linemen. Linemen operate under severe physical hazards (11kV / 33kV lines, heights, bad weather, crowd pressure). The game is designed to build **unshakeable muscle memory and critical hazard identification** before touching live infrastructure.

The game follows a **3-Tier Progression** spanning 20 progressive levels:
* **Tier 1 (Levels 1–5)**: Foundational PPE selection and fitting basics.
* **Tier 2 (Levels 6–10)**: Dress-Up Pro — Deep inspections, micro-defects, and insidious field traps.
* **Tier 3 (Levels 11–20)**: Field Operations Mastery — Real-world electrical network maintenance, switching, earthing, step-potential, and pole-top rescue.

---

## 2. Master Level Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│ TIER 1 (Levels 1–5)   : Foundational PPE (Basic Selection & Fitting)   │
├────────────────────────────────────────────────────────────────────────┤
│ TIER 2 (Levels 6–10)  : Dress-Up Pro (Hidden Defects, Testing & Traps) │
├────────────────────────────────────────────────────────────────────────┤
│ TIER 3 (Levels 11–20) : Field Duty Mastery (Lines, Switches & Rescue)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tier 1: Foundational PPE (Levels 1–5)

*Implemented in [ds_dress_up.dart](file:///d:/Dipankar/MyCodes/AndroidProjects/SLMToolBox/slm_flutter/lib/features/duty_slip/ds_dress_up.dart)*

### Level 1: পোশাক (Clothing)
* **Goal**: Equip full-sleeve cotton shirt, full cotton trousers, and safety boots.
* **Traps**: Loose fatua, half-pant, synthetic polyester jersey, slippers, normal sneakers.
* **Pass Condition**: Shirt, trousers, and boots equipped.

### Level 2: মাথায় হেলমেট (Helmet)
* **Goal**: Fit the electrical safety helmet.
* **Traps**: Lineman starts with a *gamcha* (sweat cloth) on his head. Placing helmet over gamcha is blocked. Traffic helmet and vented helmet are rejected.
* **Pass Condition**: Gamcha dragged to shelf + Class E electrical helmet locked.

### Level 3: হাতে গ্লাভস (Gloves)
* **Goal**: Equip electrical rubber gloves.
* **Traps**: Cotton gloves (no dielectric strength), wet gloves (moisture conducts), punctured gloves, bike riding gloves.
* **Pass Condition**: Clean dry rubber gloves equipped.

### Level 4: হারনেস (Harness)
* **Goal**: Complete the 5-point harness checklist and buckle sequence.
* **Traps**: Waist-belt trap (snaps lumbar spine in a fall), buckling legs out of order, loose leg straps.
* **Pass Condition**: Dual leg buckles, waist straps, chest strap locked, and 2-finger fit verified.

### Level 5: পুরো কিট (Complete Kit)
* **Goal**: Integrate all personal protective equipment in logical order.
* **Traps**: Putting boots before trousers, wearing helmet before harness, keeping gamcha.
* **Pass Condition**: Full gear equipped in seamless sequence.

---

## 4. Tier 2: Dress-Up Pro (Levels 6–10)

*Builds directly on 1–5 by introducing rigorous physical inspection procedures.*

### Level 6: ভ্যান সাজান — *ACTIVE*
* **Core Risk**: A dressed lineman still dies if the van leaves without a way to prove the line dead, dump trapped charge, and hold the line at earth potential.
* **Scene**: Control-room yard. The lineman is packed into the van only after the tool choice is complete.
* **Briefing**: *কন্ট্রোল রুমের ভিতরে কাজের আদেশ এসেছে। দ্রুত তৈরি হতে হবে।*
* **Mechanics**:
  1. **Dress the lineman first**: Cotton shirt, cotton trousers, dielectric boots, electrical helmet, face shield, rubber gloves. No harness. Jewelry, steel-toe, polyester, fatua, and the other clothing traps from levels 1–5 still fail here. A harness is thrown off.
  2. **তৈরি opens the ready page**: Finishing the clothes does not change the screen. `তৈরি` with that dress set exact clears the shelf and cargo. He stands beside the van in the no-harness kit, the guide says the three tools must always be carried, and only then the shuffled tool pile rises. `তৈরি` does not pass the level without all three.
  3. **Choose from many**: The new shelf is a mixed pile, not a short list of the right answers.
     - **Must carry**: voltage detector (`tester`), discharge rod (`discharge`), portable earthing kit (`earth`).
     - **Traps** (each gets its own rejection): neon pen tester, multimeter, megger, clamp meter, plain pliers, wet cloth, bare jumper wire, fuse wire, hacksaw, torque wrench, sickle, screwdriver, earth-resistance tester (sounds like earthing, is not the kit), spanner.
  4. **Missing tool**: `তৈরি` names the missing piece. One missing tool gets the full reason; two missing tools are named together; all three missing repeats the insist line.
* **Pass Condition**: Dress set exact, plus `tester` + `discharge` + `earth`, and no trap left in the van. The loaded van shows only what was chosen — the three tools are not added for free.

### Level 7: মাথায় হেলমেট Pro (Helmet & Headgear Pro)
* **Core Risk**: UV sunlight degradation, shell stress cracks, unbuckled chin strap during wind/fall.
* **Mechanics**:
  1. **Gamcha Removal**: Must be taken off first.
  2. **UV Expiry Date Dial**: Inner shell inspected; shells older than 3 years outdoor service discarded.
  3. **Micro-Crack Inspection**: Inspect dome under magnifier for stress cracks.
  4. **Chin-Strap Tension Click**: Tap chin strap clasp until audible latch sound confirms lock.

### Level 8: হাতে গ্লাভস Pro (Electrical Rubber Gloves Pro)
* **Core Risk**: Invisible pinhole wire punctures; dielectric breakdown from voltage mismatch.
* **Mechanics**:
  1. **Roll-Air Leak Inflation Test**: Roll cuff down to trap air like a balloon, submerge/hold to ear to check for bubbling leaks.
  2. **Voltage Class Matching**: Select Class 2 (17kV rated) for 11kV duties over Class 0 (1,000V).
  3. **Dual-Layer Assembly**: Seamless rubber dielectric glove inside + leather mechanical outer protector.

### Level 9: ফুল বডি হারনেস Pro (Full Body Harness Pro)
* **Core Risk**: Lumbar spine dislocation from single waist belts; suspension trauma; unhooked lanyard during crossarm transitions.
* **Mechanics**:
  1. **Waist-Belt Rejection**: Single waist strap rejected with spine fracture warning.
  2. **Dorsal D-Ring Positioning**: Center ring must align between the shoulder blades (nape).
  3. **Two-Finger Thigh Tension**: Interactive tension slider (flat two fingers pass, fist blocked).
  4. **Dual-Lanyard 100% Tie-Off**: Verify two independent lanyards with scaffold hooks.

### Level 10: পুরো কিট প্রস্তুতি Pro (Complete Kit Integration Pro)
* **Core Risk**: Clumsiness and skipped steps under time pressure from dispatchers or crowds.
* **Mechanics**:
  1. **Strict 6-Step Order of Dress**: Base cotton → Boots → Harness → Helmet → Arc Visor → Gloves.
  2. **Dexterity Lock**: Wearing gloves before Step 5 locks hands into bulky mittens, preventing harness buckle manipulation until gloves are removed.

---

## 5. Tier 3: Field Duty Mastery (Levels 11–20)

*Directly derived from the 10 Training Chapters and 100+ Field Lessons.*

| Level | Title (Bengali) | Title (English) | Chapter & Core Field Risk Tested |
|:---:|:---|:---|:---|
| **11** | PTW ও পোল স্টেনসিল যাচাই | The Permit & Stencil Match | *Ch 8 & 10*: Flashlight inspection of double-circuit pole stencil against PTW before placing ladder. |
| **12** | মই স্থাপন ও টাই-অফ | The 4:1 FRP Ladder & Tie-Off | *Ch 2*: Pitch angle slider (75° / 4:1 ratio), non-conductive FRP ladder, top rung safety lashing. |
| **13** | ভোল্টেজ টেস্টার (Live-Dead-Live) | Phantom Voltage & Backfeed | *Ch 5 & 6*: 3-Step Live-Dead-Live probe protocol; identifying solar inverter / generator backfeed on Phase B. |
| **14** | দ্বিমুখী পোর্টেবল আর্থিং | Two-Point Portable Earthing | *Ch 5*: Earth clamp connected to ground FIRST before phase clamp; upstream & downstream Equipotential Zone boxing. |
| **15** | লোড অবস্থায় ব্রেকার ও LOTO | GOAB Isolator & LOTO | *Ch 4*: Opening LT MCCB to 0A before pulling 11kV GOAB handle; applying padlock and Danger Tag. |
| **16** | তারের টান ও বিপজ্জনক এলাকা | Recoil Triangle & Conductor Sag | *Ch 3*: Matching come-along clamp code name; clearing crew from red snap-back hazard cone. |
| **17** | ভাসমান নিউট্রাল পরীক্ষা | Floating Neutral Diagnosis | *Ch 4 & 6*: Multimeter testing between neutral and ground; discovering 200V+ on broken return line. |
| **18** | ছেঁড়া তার ও পদবিক্ষেপ | Step Potential in Mud & Water | *Ch 6 & 7*: 10m barrier setup; shuffle-walking (heels touching toes) through energized voltage gradient. |
| **19** | ফিডার পিলারে নিরাপদ অবস্থান | LT Feeder Pillar Flank Stance | *Ch 9*: Standing on hinge-side flank, wearing arc visor, using insulated fuse puller for HRC fuses. |
| **20** | পোল থেকে জরুরি উদ্ধার ও সিপিআর | Pole-Top Rescue & Ground CPR | *Ch 7*: Emergency trip call, non-conductive rope belay lowering, rhythm-accurate 100–120 bpm chest compressions. |

---

## 6. Code Structure & Architecture Guidelines

* **Engine Configuration**: [duty_slip_engine.dart](file:///d:/Dipankar/MyCodes/AndroidProjects/SLMToolBox/slm_flutter/lib/features/duty_slip/duty_slip_engine.dart)
  - `dsLevels`: List of `DsLevelSpec`. Defines level numbers, choices, and `darunSec` target times.
  - `dressLevel`: Returns `true` for Levels 1 through 10.
  - `dsBriefFor`: Returns level title and instructional briefing.
* **UI & Ladder Presentation**: [duty_slip_page.dart](file:///d:/Dipankar/MyCodes/AndroidProjects/SLMToolBox/slm_flutter/lib/features/duty_slip/duty_slip_page.dart)
  - `_dressIntroArt`: Returns showcase illustration for the level introduction card.
  - Ladder rungs display plate medal (দারুণ / মোটামুটি / আবার) and best time.
* **Dress Mechanics**: [ds_dress_up.dart](file:///d:/Dipankar/MyCodes/AndroidProjects/SLMToolBox/slm_flutter/lib/features/duty_slip/ds_dress_up.dart)
  - `_vanToolPieces` / `_vanTraps`: Level 6 shelf after the lineman is dressed. Pass needs `tester`, `discharge`, and `earth` chosen from that pile.
  - `_wear` and `_take`: Validates dependencies and state transitions.
  - `_Spot`: Precise coordinate hit-boxes mapped to the lineman sprite.
* **Sound Effects**:
  - `sounds/quiz_flip.wav`: Item pickup / release.
  - `sounds/quiz_pass.wav`: Successful placement.
  - `sounds/accident.wav`: Lethal violation / dangerous trap triggered.
