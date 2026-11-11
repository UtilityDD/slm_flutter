# GAME_PATH_CHECKLIST.md — the whole game path and its build status

One line per rung, in the order the player climbs. **Update the row in the same commit that changes a level.**
Rung ids, packs and statuses come from `assets/game/catalog/content_catalog.json` (`rungDefs`, `gamePacks`);
how to build a level is in [GAME_LEVEL_PLAYBOOK.md](GAME_LEVEL_PLAYBOOK.md), code details in
[GAME_DEVELOPER_GUIDE.md](GAME_DEVELOPER_GUIDE.md), Module 1's design notes in [MODULE1_LADDER.md](MODULE1_LADDER.md).

**Legend:** ✅ built to the playbook (level-1 concept, shared kit, tests green) · 🟡 built, owner decisions open ·
♻️ plays an older version (text deck or a legacy `dsLevels` screen) · ☐ not started (catalog `comingSoon`)

**Totals (2026-11-11):** 10 modules · 109 lessons · 327 rungs (109 শেখা, 208 কাজ, 10 rank gates).
Playable: **30 rungs**, all in Module 1. Module 1: **30 of 30 built** (rank gate included). Next work = Module 2.

---

## Module 1 — ট্রেইনি (30 rungs)

| Step | Rung | Level | Type · file | Status |
|---:|---|---|---|---|
| 1 | `1.1/learn` | পোশাক ও পিপিই চেনা | board · `learnBoardPack11` (`learn_board_models.dart`) | ✅ |
| 2 | `1.1/do/0` | কবচ যাচাই (clothes, boots) | Do · `kit_check.dart` + `store_room.dart` | 🟡 deadly: polyester, nail in the sole |
| 3 | `1.1/do/1` | গ্লাভস যাচাই + helmet station | Do · `glove_check.dart` + `helmet_check.dart` + `van_yard.dart` | 🟡 glove deadly not wired (ladder says deadly) |
| 4 | `1.2/learn` | লক্ষ্মণ রেখা | board · `learnBoardPack12` | ✅ |
| 5 | `1.2/do/0` | কতটা দূরে? | Do · `distance_spot.dart` | ✅ |
| 6 | `1.2/do/1` | লম্বা টুলের ডগা | Do · `tool_tip.dart` | ✅ |
| 7 | `1.3/learn` | পোলের ভাষা | board · `learn_board_pack13.dart` | ✅ |
| 8 | `1.3/do/0` | ৩৬০° পোল পাঠ (PCC) | Do · `pole_read.dart` + `pole_yard.dart` | 🟡 polymer insulator on PCC? |
| 9 | `1.3/do/1` | স্টিলের ক্যান্সার (tube, rail, H-beam) | Do · `pole_read.dart` (steel pack) | ✅ |
| 10 | `1.4/learn` | হারনেস: লাইফলাইন | board · `learn_board_pack14.dart` | ✅ |
| 11 | `1.4/do/0` | তিন মিনিটের পরীক্ষা | Do · `harness_check.dart` + `harness_store.dart` | 🟡 label maker name / service life |
| 12 | `1.4/do/1` | ফিটিং আর অ্যাঙ্কর | Do · `harness_fit.dart` | 🟡 strong anchor on your poles; loose bracket |
| 13 | `1.5/learn` | ডিসচার্জ রড | board · `learn_board_pack15.dart` | ✅ |
| 14 | `1.5/do/0` | সঠিক রড | Do · `rod_pick.dart` + `rod_van.dart` | ✅ |
| 15 | `1.5/do/1` | আগে মাটি, পরে লাইন | Do · `discharge_order.dart` | 🟡 chain with 0 phases: deadly or slip? |
| 16 | `1.6/learn` | পারমিট-টু-ওয়ার্ক | board · `learn_board_pack16.dart` | 🟡 feeder naming |
| 17 | `1.6/do/0` | কাগজ মেলাও | Do · `ptw_match.dart` + `ptw_site.dart` | ✅ |
| 18 | `1.6/do/1` | সোনালি ধাপ + লাইন ক্লিয়ার | Do · `ptw_steps.dart` + `ptw_yard.dart` | ✅ |
| 19 | `1.7/learn` | শক লাগলে ফার্স্ট এইড | board · `learn_board_pack17.dart` | 🟡 burns & water (lesson text) |
| 20 | `1.7/do/0` | ছোঁবেন না! | Do · `shock_rescue.dart` + `shock_scene.dart` | 🟡 phone-the-substation move |
| 21 | `1.7/do/1` | গোল্ডেন মিনিট (+ CPR rhythm) | Do · `golden_minute.dart` + `golden_field.dart` | 🟡 CPR pays 10 vs 5 |
| 22 | `1.8/learn` | মাঠে আগুন | board · `learn_board_pack18.dart` | 🟡 CO2 safe card |
| 23 | `1.8/do/0` | কোন আগুনে কী | Do · `fire_choose.dart` + `fire_world.dart` (reference level) | ✅ |
| 24 | `1.8/do/1` | PASS | Do · `fire_pass.dart` | ✅ |
| 25 | `1.9/learn` | ঝড়-বৃষ্টিতে 'না' | board · `learn_board_pack19.dart` | ✅ |
| 26 | `1.9/do/0` | আকাশ পড়ুন | Do · `sky_read.dart` + `sky_world.dart` (new) | 🟡 wind ≥ 45 km/h = stop |
| 27 | `1.9/do/1` | সুপারভাইজারের চাপ | Do · `storm_push.dart` (new) | 🟡 supervisor uses the rival's art/voice |
| 28 | `1.10/learn` | ১০ সেকেন্ডের মেন্টাল চেকলিস্ট | board · `learn_board_pack110.dart` | ✅ |
| 29 | `1.10/do/0` | ১০ সেকেন্ডের স্ক্যান | Do · `ten_sec_scan.dart` | ✅ |
| 30 | `m1/gate` | প্রথম ডকেট (rank gate) | gate · `gate_field.dart` (`engineType: gate_field`, pack `gate_m1`) | ✅ |

Cross-level items:

- [x] Brand: vector intro (`lib/features/startup/brand_intro.dart`), launcher icons, native splash, warm-up.
- [ ] Owner decisions open: see the 🟡 rows and the latest report (burns text in lesson 1.7, glove deadly, CPR points, quick-bonus times, CO2 card, phone-the-substation, feeder naming, polymer insulators, helmet stamp layout).
- [ ] The guide's new lines are on device TTS; the owner records them later (lists in each level's `*Lines` class).
- [ ] Release build size check (profile APK 82 MB vs 62 MB before this batch; new assets explain only 3.4 MB).
- [ ] Day cards exist for 1.1–1.5 only (`lesson_day_card.dart`); promises for 1.1–1.5 only (`lesson_promises.dart`).

---

## Modules 2–10 (not started)

Every rung below is `comingSoon` in the catalog: no picture board, no Do game, no gate. Each lesson's text exists in
`tool/all_training_chapters_bn.json`. Build them module by module with the playbook (board first, then the Do rungs, then the gate).

### Module 2 — জুনিয়র (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 2.1 | লাইনম্যানের টুলবক্স পরিচিতি | ☐ | 2 × ☐ |
| 2.2 | মাল্টিমিটারের জাদু | ☐ | 2 × ☐ |
| 2.3 | ল্যাগস ক্রিম্পিং: সঠিক চাপ, নিরাপদ কানেকশন | ☐ | 2 × ☐ |
| 2.4 | কাম-অ্যালং ক্ল্যাম্প (Come-Along Clamp): নিয়ন্ত্রিত শক্তি | ☐ | 2 × ☐ |
| 2.5 | অপারেটিং রড (হট স্টিক): দূরত্বের সুরক্ষা | ☐ | 2 × ☐ |
| 2.6 | কেবিল স্কিনিং-এর শিল্প | ☐ | 2 × ☐ |
| 2.7 | 'মেগার' (Megger) কী ও কেন? | ☐ | 2 × ☐ |
| 2.8 | ফেজ সিকোয়েন্স মিটার: সঠিক ঘূর্ণন | ☐ | 2 × ☐ |
| 2.9 | হাইড্রোলিক ক্রিম্পার ও কাটার: দানবীয় শক্তি | ☐ | 2 × ☐ |
| 2.10 | হাতিয়ারের যত্ন ও রক্ষণাবেক্ষণ | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (জুনিয়র) | — | ☐ |

### Module 3 — টেকনিশিয়ান (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 3.1 | কন্ডাক্টর পরিচিতি: ACSR, AAAC | ☐ | 2 × ☐ |
| 3.2 | ইনসুলেটর পরিচিতি: পিন, ডিস্ক, শ্যাকল | ☐ | 2 × ☐ |
| 3.3 | ক্রস-আর্ম ও ক্ল্যাম্প: লাইনের কঙ্কাল | ☐ | 2 × ☐ |
| 3.4 | ডিও (DO) ফিউজ ও হর্ন গ্যাপ ফিউজ: নীরব প্রহরী | ☐ | 2 × ☐ |
| 3.5 | লাইটনিং অ্যারেস্টার (LA): বজ্রপাতের কবচ | ☐ | 2 × ☐ |
| 3.6 | ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড | ☐ | 2 × ☐ |
| 3.7 | এলটি (LT) ডিস্ট্রিবিউশন বক্স/ফিডার পিলার: শেষ প্রবেশদ্বার | ☐ | 2 × ☐ |
| 3.8 | সার্ভিস কেবিল ও এনার্জি মিটার: শেষ সংযোগ | ☐ | 2 × ☐ |
| 3.9 | গার্ড ওয়্যার ও ক্রেডল গার্ডিং: অতিরিক্ত সুরক্ষা জাল | ☐ | 2 × ☐ |
| 3.10 | লাইন ডায়াগ্রাম পড়া: কাগজের ওপর জাদুর নকশা | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (টেকনিশিয়ান) | — | ☐ |

### Module 4 — স্কিলড (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 4.1 | পিন বা ডিস্ক ইনসুলেটর বদলানো | ☐ | 2 × ☐ |
| 4.2 | জাম্পার কানেকশন ও টাইট করা | ☐ | 2 × ☐ |
| 4.3 | নতুন সার্ভিস কানেকশন দেওয়া | ☐ | 2 × ☐ |
| 4.4 | ডিও (DO) ফিউজ পরিচালনা করা | ☐ | 2 × ☐ |
| 4.5 | ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা | ☐ | 2 × ☐ |
| 4.6 | সঠিক আর্থিং (Earthing) পরীক্ষা ও রক্ষণাবেক্ষণ | ☐ | 2 × ☐ |
| 4.7 | ডিপি (DP) স্ট্রাকচার ড্রেসিং: পরিচ্ছন্নতার শিল্প | ☐ | 2 × ☐ |
| 4.8 | গাছের ডালপালা ছাঁটা (Tree Trimming) | ☐ | 2 × ☐ |
| 4.9 | রাস্তার আলো (Street Light) মেরামত: রাতের প্রহরীকে বাঁচান | ☐ | 2 × ☐ |
| 4.10 | এলটি (LT) লাইনের ফেজ ব্যালেন্সিং | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (স্কিলড) | — | ☐ |

### Module 5 — অ্যাডভান্সড (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 5.1 | 'লাইন ট্রিপ করেছে'—প্রথম কাজ কী? | ☐ | 2 × ☐ |
| 5.2 | লাইন পেট্রোলিং-এর সঠিক নিয়ম | ☐ | 2 × ☐ |
| 5.3 | সাধারণ ফল্ট: অপরাধীদের প্যারেড | ☐ | 2 × ☐ |
| 5.4 | ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী ফল্ট | ☐ | 2 × ☐ |
| 5.5 | 'লো-ভোল্টেজ' সমস্যার সমাধান | ☐ | 2 × ☐ |
| 5.6 | শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু | ☐ | 2 × ☐ |
| 5.7 | রাতের বেলা ফল্ট খোঁজার কৌশল | ☐ | 2 × ☐ |
| 5.8 | ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয় | ☐ | 2 × ☐ |
| 5.9 | কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা | ☐ | 2 × ☐ |
| 5.10 | প্রিভেন্টিভ মেইনটেন্যান্স: গোয়েন্দা থেকে ডাক্তার | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (অ্যাডভান্সড) | — | ☐ |

### Module 6 — সিনিয়র (11 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 6.1 | ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড | ☐ | 2 × ☐ |
| 6.2 | সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা | ☐ | 2 × ☐ |
| 6.3 | ফিউজ: নীরব প্রহরী | ☐ | 2 × ☐ |
| 6.4 | AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার | ☐ | 2 × ☐ |
| 6.5 | আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক | ☐ | 2 × ☐ |
| 6.6 | এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত আধুনিক লাইন | ☐ | 2 × ☐ |
| 6.7 | ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার | ☐ | 2 × ☐ |
| 6.8 | অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন | ☐ | 2 × ☐ |
| 6.9 | এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার | ☐ | 2 × ☐ |
| 6.10 | এনার্জি মিটার: ক্যাশ রেজিস্টার | ☐ | 2 × ☐ |
| 6.11 | আর্থিং সিস্টেম: অদৃশ্য অভিভাবক | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (সিনিয়র) | — | ☐ |

### Module 7 — সুপারভাইজার (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 7.1 | ইন্ডিয়ান ইলেকট্রিসিটি অ্যাক্ট ও রুলস: আপনার বাইবেল | ☐ | 2 × ☐ |
| 7.2 | ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার পর আপনার অধিকার | ☐ | 2 × ☐ |
| 7.3 | ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব? | ☐ | 2 × ☐ |
| 7.4 | পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি চুক্তি | ☐ | 2 × ☐ |
| 7.5 | বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ | ☐ | 2 × ☐ |
| 7.6 | ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন | ☐ | 2 × ☐ |
| 7.7 | দুর্ঘটনার রিপোর্ট (Accident Reporting): আপনার দায়িত্ব | ☐ | 2 × ☐ |
| 7.8 | পরিবেশগত আইন: আমাদের দায়িত্ব | ☐ | 2 × ☐ |
| 7.9 | গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব | ☐ | 2 × ☐ |
| 7.10 | একজন 'সার্টিফায়েড' লাইনম্যান: লাইসেন্স ও যোগ্যতার গুরুত্ব | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (সুপারভাইজার) | — | ☐ |

### Module 8 — স্পেশালিস্ট (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 8.1 | WBERC পরিচিতি: রাজ্যের পাওয়ার বস | ☐ | 2 × ☐ |
| 8.2 | সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার নিয়মাবলী | ☐ | 2 × ☐ |
| 8.3 | স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য | ☐ | 2 × ☐ |
| 8.4 | গ্রিড কোড (Grid Code): সিস্টেম শৃঙ্খলার নিয়ম | ☐ | 2 × ☐ |
| 8.5 | সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন | ☐ | 2 × ☐ |
| 8.6 | গ্রাহক অভিযোগ নিষ্পত্তি (Grievance Redressal): আপনার কাজের পর্যালোচনা | ☐ | 2 × ☐ |
| 8.7 | ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব | ☐ | 2 × ☐ |
| 8.8 | নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম | ☐ | 2 × ☐ |
| 8.9 | পরিবেশগত নিয়মাবলী: রাজ্যের দৃষ্টিকোণ | ☐ | 2 × ☐ |
| 8.10 | রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (স্পেশালিস্ট) | — | ☐ |

### Module 9 — এক্সপার্ট (10 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 9.1 | ট্রান্সফরমার টেস্টিং (পার্ট ১): মৌলিক পরীক্ষা | ☐ | 2 × ☐ |
| 9.2 | ট্রান্সফরমার টেস্টিং (পার্ট ২): তেল পরীক্ষা | ☐ | 2 × ☐ |
| 9.3 | সার্কিট ব্রেকার টেস্টিং: কমান্ডোর ফিটনেস টেস্ট | ☐ | 2 × ☐ |
| 9.4 | কেবিল টেস্টিং: লুকানো নেটওয়ার্কের স্বাস্থ্য | ☐ | 2 × ☐ |
| 9.5 | আর্থিং সিস্টেম টেস্টিং: অদৃশ্য রক্ষকের শক্তি পরীক্ষা | ☐ | 2 × ☐ |
| 9.6 | ইনসুলেটর টেস্টিং: প্রহরীর শক্তি পরীক্ষা | ☐ | 2 × ☐ |
| 9.7 | রিলে টেস্টিং: মস্তিষ্কের কার্যকারিতা পরীক্ষা | ☐ | 2 × ☐ |
| 9.8 | ব্যাটারি এবং চার্জার টেস্টিং: জরুরি শক্তির উৎস | ☐ | 2 × ☐ |
| 9.9 | ক্যাপাসিটর ব্যাংক টেস্টিং: পাওয়ার বুস্টারের কার্যকারিতা | ☐ | 2 × ☐ |
| 9.10 | টেস্টিং রিপোর্ট তৈরি: ডাক্তারের প্রেসক্রিপশন | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (এক্সপার্ট) | — | ☐ |

### Module 10 — সেফটি প্রো (18 lessons + rank gate)

| Lesson | Title | শেখা | কাজ rungs |
|---|---|---|---|
| 10.1 | ম্যানুয়ালের ভূমিকা ও সারকথা: এক নজরে সব পাঠ | ☐ | 2 × ☐ |
| 10.2 | সেফটি শপথ ও নীতি: আগে জান, তারপর কাম | ☐ | 2 × ☐ |
| 10.3 | সাধারণ শর্ত ও তদারকি: কাজের শুরু | ☐ | 2 × ☐ |
| 10.4 | সিইএ ২০২৩ ক্লিয়ারেন্স: তার থেকে নিরাপদ দূরত্ব | ☐ | 2 × ☐ |
| 10.5 | পারমিট ও শাটডাউন: কাগজের সই, প্রাণের গ্যারান্টি | ☐ | 2 × ☐ |
| 10.6 | লাইন চেক ও আর্থিং: চার্জমুক্ত করার সঠিক কায়দা | ☐ | 2 × ☐ |
| 10.7 | সেফ জোন ও ব্যাকফিড: লুকানো বিপদ থেকে বাঁচা | ☐ | 2 × ☐ |
| 10.8 | সাবস্টেশন ও সুইচিং: ইয়ার্ডের নিয়মকানুন | ☐ | 2 × ☐ |
| 10.9 | মাঠের কী করবেন, আর কী কক্ষনো নয় | ☐ | 2 × ☐ |
| 10.10 | আন্ডারগ্রাউন্ড কেবল: মাটির নিচের বিপদ | ☐ | 2 × ☐ |
| 10.11 | গ্রাহক প্রাঙ্গণে কাজ: দুয়ারে সুরক্ষা | ☐ | 2 × ☐ |
| 10.12 | কমিউনিকেশন লাইন: বিদ্যুৎ লাইনের সঙ্গী | ☐ | 2 × ☐ |
| 10.13 | পাবলিক সেফটি: সাধারণ মানুষের সুরক্ষা | ☐ | 2 × ☐ |
| 10.14 | সেফটি কমিটি ও অডিট: নজরদারি | ☐ | 2 × ☐ |
| 10.15 | ঠিকাদার ও কনস্ট্রাকশন: সাইটের কড়া নিয়ম | ☐ | 2 × ☐ |
| 10.16 | অগ্নিনির্বাপণ: আগুনের মোকাবিলা | ☐ | 2 × ☐ |
| 10.17 | প্রাথমিক চিকিৎসা: জীবন বাঁচানোর প্রথম ধাপ | ☐ | 2 × ☐ |
| 10.18 | সেফটি চেকলিস্ট: ভ্যান থেকে সাবস্টেশন | ☐ | 1 × ☐ |
| gate | র‍্যাঙ্ক গেট (সেফটি প্রো) | — | ☐ |
