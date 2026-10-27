# Duty slip — মৃত্যুহীন পথ

Field duty companion. Home card **মৃত্যুহীন পথ** opens `DutySlipPage`. Pack: `assets/data/duty_slip_job.json`. Photos: `assets/duty_slip/`. Applicable for any field breakdown or maintenance job (day or night).

Do not use PowerShell `Set-Content` on Bangla in this folder — it mojibakes. Edit in the IDE.

## Testing unlock

`dsAllLevelsOpen` in `duty_slip_engine.dart` is **`true`**. All 19 live plates are tappable. Ladder opens on level 1. Rank still records; আবার still does not bank score.

Set it **`false`** before a real release. Then only `unlocked` plates open, a pass opens the next one, and the ladder pins to that next plate.

## Files

| File | Role |
|---|---|
| `duty_slip_engine.dart` | Level specs, SAFE HOME deck, briefs, scoring, living rebuild, field night |
| `duty_slip_page.dart` | Cover, bamboo ladder, briefing, quiz, result medal, field docket |
| `ds_dress_up.dart` | Levels 1–6 (Dress-Up & Dress-Up Pro): shelf, drag, harness checklist, coach |
| `duty_slip_models.dart` | Plan items, sites, PTW/kit/match steps, pack loader |
| `GAME_LEVELS_GUIDE.md` | Master 20-level developer guide (Tier 1 Foundational, Tier 2 Pro, Tier 3 Field Operations) |

## Flow

`cover` → `road` (ladder) → briefing → `play` or field night → `result`.

**1–6** are the interactive dress game (`ds_dress_up.dart`):
* Levels 1–5: Foundational PPE (পোশাক, মাথায় হেলমেট, হাতে গ্লাভস, হারনেস, পুরো কিট)
* Level 6: পোশাক ও জুতো Pro (ধাতুর বালা-চেইন অপসারণ, স্টিল-টো ট্র্যাপ, ডাই-ইলেকট্রিক বুট ও খাঁটি সুতি পোশাক)

| # | Name | Play |
|---|---|---|
| 1 | পোশাক | Cotton full shirt, full pant, safety shoes |
| 2 | মাথায় হেলমেট | Electrical helmet. গামছা starts on and comes off first |
| 3 | হাতে গ্লাভস | Rubber electrical gloves |
| 4 | হারনেস | Gloves off, one drag into the hand, then the checklist. Last step: two fingers. Brown belt is the trap |
| 5 | পুরো কিট | Shirt, pant, shoe, harness, helmet, shield, gloves. গামছা is refused |
| 6 | পোশাক ও জুতো Pro | Metallic bracelet/chain starts on wrist and must come off first. Steel-toe boot is a fatal trap; certified dielectric boot + 100% cotton required |

**6–8 briefing** is the SAFE HOME list (title, then body). **9–18 briefing** (job): different site photo (torn wire). Page 1 title **আসল কাজ**, lead **২৩ ধাপ। মাঠে তার ছিঁড়ে পড়ে আছে।**, caption **শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।** Five tappable group plates (`dsJobGroups`). Tap a group → same **আসল কাজ** header, that group’s steps fill the list (no serials). Bottom ring turns back and returns to the five plates. Tap a step for why; the plate has prev / next (and swipe) to walk the group. Next → clean 23 list, still **আসল কাজ**. Next → full-page level hint (`dsJobHint`). Next starts the quiz.

Dress titles are fixed: পোশাক, মাথায় হেলমেট, হাতে গ্লাভস, হারনেস, পুরো কিট. Levels 6–8 use the SAFE HOME briefing list.

## 19 levels (`dsLevels`)

| # | Deck | On-screen choices | Living | দারুণ time |
|---|---|---|---|---|
| 1–5 | Dress the lineman | shelf | no | 150 / 80 / 100 / 180 / 200 s |
| 6–8 | SAFE HOME 8 | 4 / 6 / 8 | yes | 70 / 85 / 100 s |
| 9–13 | 23-step job | 2 / 4 / 6 / 10 / 23 | no | 75 / 105 / 150 / 180 / 240 s |
| 14–18 | 23-step job | 2 / 4 / 6 / 10 / 23 | yes | 70 / 95 / 135 / 160 / 210 s |
| 19 | field night | docket / PTW / PPE / tools / calls | — | — |

**Living:** wrong tap rebuilds far distractors (avoid last decoy set) and re-deals. Clock never fails a level.

Quiz cards: Bangla `labelBn` only. Letters only on the 6–8 briefing list. Two-choice prefers **far** distractors.

## SAFE HOME (1–8)

| Letter | id | Bangla | Why (tap the plate) |
|---|---|---|---|
| S | stop | থামো ও বিপদ খুঁজো | তাড়াহুড়ো করলে বিপদ দেখা যায় না |
| A | armour | কবচ পরো | PPE ছাড়া শক / পোড়া / পড়ে যাওয়া |
| F | form | পারমিট নাও | PTW ছাড়া কেউ জানে না আপনি লাইনে |
| E | end | দুদিক কাটো | লাইন কাটা না হলে কারেন্ট আছে |
| H | hold | আর্থ করো | ভোল্টেজ ফিরতে পারে |
| O | ok | ফিতে ঘেরো | ব্যারিকেড না দিলে মানুষ ঢোকে |
| M | mend | কাজ সারো | আগের ধাপ শেষ, এবার কাজ |
| E | exit | গুনে ফিরো | সবাইকে গুনে নামান |

## 23-step job (9–18)

Spine in `duty_slip_job.json`: ডকেট পড়ুন → PTW নিন → PPE দেখে নিন → টুল বেছে নিন → সাইটে চলে যান → সব PPE পরে নিন → নিজেদের মধ্যে আলোচনা → বিপদ খুঁজে দেখুন → PTW মিলিয়ে দেখুন → ব্যারিকেড করে নিন → শাটডাউন নিন → ডিসচার্জ করুন → দুই মাথায় আর্থ → LOTO → কাজ শুরু করুন → সঠিক টুল → কাজ শেষ → টুল ও PPE নামিয়ে নিন → সবাই এক জায়গায় আসুন → শাটডাউন তুলে নিন → বিদ্যুৎ ফিরল কিনা দেখুন → PTW ফেরত দিন → মিশন কমপ্লিট.

Sites: রাস্তায় / পুকুর পাড়ে / ধানক্ষেতে. Clock 20:10. Water copy **জল**. Shutdown **শাটডাউন**.

## Scoring and ranks

- Correct **+5**, wrong **−5**. Streak gift **+5** every 6 correct.
- Clock counts. Never auto-fails.
- HUD: time + this-level score large + night total small.
- Ranks from wrongs + দারুণ time, not streak: **দারুণ / মোটামুটি / আবার**.
- 8-step deck: দারুণ ≤1 wrong and in time; মোটামুটি ≤2; আবার 3+.
- 23-step deck: দারুণ ≤3 wrong and in time; মোটামুটি ≤7; আবার 8+.
- আবার does not add `levelScore` to `nightTotal`. Best time on a plate is the lowest pass (any rank except আবার).
- Result medal: number only, seated in the well, scales for bigger totals. Pass: celebration sting + sparks. Fail: accident sting + shake.

## Field night (level 19)

Docket, PTW feeder/pole/shift, PPE kit, tools, site calls (বস / নেতা / দোকানি / কৃষক / কন্ট্রোল). Lethal → `accident.wav`. Grade **সেফ / ঝুঁকি ছিল / আনসেফ**, separate from দারুণ/মোটামুটি/আবার.

## Ladder UI

Reverse `ListView`. Ground, 19 live plates, grey sky plates 20+. Bamboo rungs, city-light parallax, clouds. Best `mm:ss` stamped on a passed plate. Rank lives in metal colour. Next arrow is a floating ring, not a glass bar.

Device for installs: CPH2467 / `f6650cdf`. Gradle 9.3.1 offline.
