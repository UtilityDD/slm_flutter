import 'learn_board_models.dart';

/// Module 6 Lesson 6.3 (ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব), the picture
/// board (rung `6.3/learn`, pack `learn_6_3`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board63_art.py` (the labels a
/// worker reads — nameplate kVA, reel tags, gauge slot numbers, meter
/// readings — drawn as stroke glyphs with English digits). Every round and
/// trap comes from the live lesson text and the Module 6 rulings
/// (`docs/module_specs/module6_rulings.md`, item spec
/// `docs/module_specs/module6_items/board_63.json`):
///  * hg: the WBSEDCL 11 kV DTR's horn gap fuse — tinned copper wire taut
///    between the arcing horns; the arc climbs the horns and dies in the air.
///    GI wire (melting point about 1535°), a slack wire and an ACSR strand
///    are the traps (lesson point 1, point 5);
///  * rating: HG fuse wire by the DTR's kVA — 25 kVA 2-3 A, 63 kVA 5 A,
///    100 kVA 8-10 A; a higher rating does not melt and the DTR burns;
///  * hrc: the LT box's HRC — a sealed cartridge with its dot (pro tip 1); the
///    draw only after the DTR LT switch is OFF, locked, tagged and proved dead
///    with the tester (live point 6, ruling X4), with gloves, goggles and the
///    insulated puller. Traps: a copper strip (pro tip 3), pliers, the supply
///    on, bare hands;
///  * gauge: the IS 9926 table (ruling X6) — 100 A = 2.00 mm, about 14 SWG; the
///    higher the gauge number the thinner the wire; bare conductor in the slot;
///    never by eye. No 29/22/18/12 SWG claim is left on the board. Five
///    rounds, as the Module 5 boards (ruling M5-11): the spare-wire round
///    left the board (owner 2026-11-15); the thick-wire point lives on in the
///    rating round's 'tthick' trap and the rival's myth;
///  * blow: discrimination (pro tip 2) — on a house fault the house fuse or MCB
///    goes first; never re-charge before the cause is found (point 6 tip);
///    HG wire renewed only with the AB open (all three blades seen), proved
///    dead and earthed — the trap's reject is live point 6 word for word
///    (ruling M6-2; Module 6 has no DO, so no rod or mat card).
/// The rival's myth is the lesson's first myth, word for word (ruling M6-8:
/// the thick-wire myth lives only on this board in Module 6).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack63 = LearnBoardPack(
  lessonId: '6.3',
  titleBn: 'ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব',
  badgeBn: 'যন্ত্র গুরু',
  introBn: 'ফিউজ নিজে গলে ট্রান্সফরমার বাঁচায়। ঠিক ফিউজ, ঠিক তার আর ঠিক নিয়ম চিনে নিন।',
  earnedBn: 'ঠিক রেটিংয়ের টিনড কপার তার মেপে বাঁধুন; ফিউজে হাত শুধু ডেড প্রমাণের পর, আর কারণ না খুঁজে চার্জ নয়।',
  slots: [
    LearnBoardSlot(
      id: 'hg',
      promptBn: 'পশ্চিমবঙ্গের 11 kV DTR পোলে হর্ন গ্যাপ ফিউজ — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'taut',
          labelBn: 'দুই হর্নের মাঝে টিনড কপার তার, টানটান',
          asset: 'assets/game/art/m6_board63/hg_taut.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'arc',
          labelBn: 'ফল্টে তার গলেছে, আর্ক হর্ন বেয়ে উঠে নিভছে',
          asset: 'assets/game/art/m6_board63/hg_arc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'gi',
          labelBn: 'হর্নের মাঝে জিআই বাইন্ডিং তার বাঁধা',
          asset: 'assets/game/art/m6_board63/hg_gi.svg',
          scene: true,
          correct: false,
          rejectBn: 'জিআই তারের গলনাঙ্ক প্রায় 1535° সেলসিয়াস — ফল্টেও গলে না, পুরো ফল্ট কারেন্ট ট্রান্সফরমারে আঘাত করে।',
        ),
        LearnBoardOption(
          id: 'slack',
          labelBn: 'হর্নের মাঝে ফিউজ তার ঢিলে হয়ে ঝুলছে',
          asset: 'assets/game/art/m6_board63/hg_slack.svg',
          scene: true,
          correct: false,
          rejectBn: 'হর্ন দুটোর মাঝে ফিউজ তার টানটান করে বাঁধতে হয় — ঢিলে করে নয়।',
        ),
        LearnBoardOption(
          id: 'alu',
          labelBn: 'হর্নের মাঝে ACSR-এর অ্যালুমিনিয়াম সুতো',
          asset: 'assets/game/art/m6_board63/hg_alu.svg',
          scene: true,
          correct: false,
          rejectBn: 'ACSR-এর অ্যালুমিনিয়াম সুতো ফিউজ তারের চেয়ে অনেক মোটা — সময়মতো গলে না, আর অক্সিডেশনে কানেকশন ঢিলে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্ক হর্ন বেয়ে উঠে লম্বা হয়ে বাতাসে নেভে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হর্নের মাঝে টিনড কপার তার টানটান বাঁধতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফল্টে ঠিক তার গলে গিয়ে ট্রান্সফরমার বাঁচায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জিআই তার মজবুত, তাই হর্নে সেটাই বেশি ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফিউজ তার ঢিলে থাকলে আর্ক সহজে নিভে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অ্যালুমিনিয়াম সুতো দিলে ফিউজ বারবার ওড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হর্ন দুটো শুধু দেখার জন্য, কোনো কাজে লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যে তার সহজে গলে না, সেটাই ভালো ফিউজ তার', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'HG-তে যেকোনো তার বাঁধলেই ফিউজের কাজ হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rating',
      promptBn: 'ট্রান্সফরমারের kVA দেখে HG-র ফিউজ তার — কোন জুটি ঠিক?',
      options: [
        LearnBoardOption(
          id: 'r25',
          labelBn: '25 kVA ট্রান্সফরমারে 3 A ফিউজ তার',
          asset: 'assets/game/art/m6_board63/rating_r25.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'r63',
          labelBn: '63 kVA ট্রান্সফরমারে 5 A ফিউজ তার',
          asset: 'assets/game/art/m6_board63/rating_r63.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'r100',
          labelBn: '100 kVA ট্রান্সফরমারে 10 A ফিউজ তার',
          asset: 'assets/game/art/m6_board63/rating_r100.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 't25',
          labelBn: '25 kVA ট্রান্সফরমারে 10 A ফিউজ তার',
          asset: 'assets/game/art/m6_board63/rating_t25.svg',
          scene: true,
          correct: false,
          rejectBn: '25 kVA-তে 2 A বা 3 A — বেশি রেটিংয়ের তার দিলে ফল্টে ফিউজ গলবে না, ট্রান্সফরমার পুড়বে।',
        ),
        LearnBoardOption(
          id: 't63',
          labelBn: '63 kVA ট্রান্সফরমারে 10 A ফিউজ তার',
          asset: 'assets/game/art/m6_board63/rating_t63.svg',
          scene: true,
          correct: false,
          rejectBn: '63 kVA-তে 5 A ফিউজ তার — বেশি রেটিংয়ে ফল্টের সময় ফিউজ গলবে না।',
        ),
        LearnBoardOption(
          id: 'tthick',
          labelBn: '100 kVA-তে ফিউজ তারের বদলে মোটা তার',
          asset: 'assets/game/art/m6_board63/rating_tthick.svg',
          scene: true,
          correct: false,
          rejectBn: '100 kVA-তে 8 A বা 10 A ফিউজ তার — মোটা তার গলবে না, ট্রান্সফরমার পুড়ে যাবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: '25 kVA-তে 2-3 A, 63-তে 5 A, 100-তে 8-10 A', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ট্রান্সফরমারের ক্ষমতা দেখে ফিউজ তারের রেটিং', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বেশি রেটিংয়ের তার ফল্টে গলে না, DTR পোড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বড় হোক বা ছোট, সব DTR-এ একই তার চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বেশি রেটিংয়ের তার দিলে ট্রান্সফরমার নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিউজ তার যত মোটা, ট্রান্সফরমার তত সুরক্ষিত', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রেটিং মেলানোর দরকার নেই, টানটান হলেই চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: '10 A তার সব ট্রান্সফরমারেই নিশ্চিন্তে চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নেমপ্লেট দেখার দরকার নেই, আন্দাজই যথেষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hrc',
      promptBn: 'LT বক্সে HRC ফিউজ — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'dot',
          labelBn: 'সিল করা HRC, গায়ের লাল ডটটা একদম ঠিক আছে',
          asset: 'assets/game/art/m6_board63/hrc_dot.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'iso',
          labelBn: 'LT বন্ধ, তালা-ট্যাগ, টেস্টারে 0, গ্লাভস-গগলস, পুলার',
          asset: 'assets/game/art/m6_board63/hrc_iso.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'strip',
          labelBn: 'কাটা HRC-র জায়গায় একটা তামার পাত লাগানো',
          asset: 'assets/game/art/m6_board63/hrc_strip.svg',
          scene: true,
          correct: false,
          rejectBn: 'HRC কেটে গেলে তামার পাত দিয়ে ডাইরেক্ট করা চরম বিপজ্জনক — ফিডার পিলার বা ট্রান্সফরমারে আগুন লাগতে পারে।',
        ),
        LearnBoardOption(
          id: 'pliers',
          labelBn: 'গ্লাভস আছে, কিন্তু সাধারণ প্লায়ার্সে টানা',
          asset: 'assets/game/art/m6_board63/hrc_pliers.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্লায়ার্স বা খালি হাতে নয় — HRC খোলা-লাগানোয় সবসময় ইনসুলেটেড ফিউজ পুলার।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'LT সুইচ চালু রেখেই পুলার দিয়ে HRC টেনে খোলা',
          asset: 'assets/game/art/m6_board63/hrc_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'চালু সাপ্লাইয়ে ফিউজ টানলে মারাত্মক আর্ক ফ্ল্যাশ হতে পারে — আগে LT সুইচ বন্ধ, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'পুলার আছে, কিন্তু খালি হাত, সেফটি গগলস নেই',
          asset: 'assets/game/art/m6_board63/hrc_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'LT/HT ইনসুলেটেড হ্যান্ড গ্লাভস আর সেফটি গগলস ছাড়া ফিউজে হাত একদম নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে LT বন্ধ, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'HRC খোলা-লাগানোয় সবসময় ইনসুলেটেড পুলার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লাল ডট উধাও বা কালো হলে ফিউজ কেটে গেছে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্লাভস আর সেফটি গগলস ছাড়া ফিউজে হাত নয়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'চালু অবস্থায় টানলে কাজ তাড়াতাড়ি শেষ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাটা HRC-তে তামার পাত দিলেই সাপ্লাই চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্লাভস থাকলে প্লায়ার্সেও HRC খোলা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'LT সুইচ বন্ধ করলেই হলো, টেস্টার লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লাল ডট থাকুক বা না থাকুক, ফিউজ ঠিকই আছে', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'গ্লাভস পরা থাকলে সুইচ বন্ধ না করলেও চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'gauge',
      promptBn: '100 A LT বক্সের ফিউজ তার মাপছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'slot',
          labelBn: 'খালি তার গেজ প্লেটের 14 খাঁজে ঠিক বসেছে',
          asset: 'assets/game/art/m6_board63/gauge_slot.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'micro',
          labelBn: 'মাইক্রোমিটারে তারের ব্যাস 2.00 মিমি',
          asset: 'assets/game/art/m6_board63/gauge_micro.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thin',
          labelBn: '25 খাঁজে ঠিক বসেছে, তাই মোটা ধরে নেওয়া',
          asset: 'assets/game/art/m6_board63/gauge_thin.svg',
          scene: true,
          correct: false,
          rejectBn: 'গেজ নম্বর যত বাড়ে, তার তত চিকন — প্রায় 25 SWG হলো 16 A-র 0.50 মিমি তার।',
        ),
        LearnBoardOption(
          id: 'insul',
          labelBn: 'ইনসুলেশন না ছাড়িয়েই তার খাঁজে ঢোকানো',
          asset: 'assets/game/art/m6_board63/gauge_insul.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশন ছাড়িয়ে খালি কন্ডাক্টর গেজের খাঁজে ঢুকিয়ে নম্বর দেখুন।',
        ),
        LearnBoardOption(
          id: 'eye',
          labelBn: 'দুটো রিল চোখে দেখে আন্দাজে বাছাই',
          asset: 'assets/game/art/m6_board63/gauge_eye.svg',
          scene: true,
          correct: false,
          rejectBn: 'আন্দাজে মোটা তার লাগালে ফিউজ তারের আসল উদ্দেশ্যই নষ্ট হয় — গেজে মাপুন।',
        ),
        LearnBoardOption(
          id: 'm150',
          labelBn: 'মাইক্রোমিটারে 1.50 মিমি, 100 A-তে লাগানো',
          asset: 'assets/game/art/m6_board63/gauge_m150.svg',
          scene: true,
          correct: false,
          rejectBn: '1.50 মিমি হলো 63 A-র তার — 100 A-তে লাগে 2.00 মিমি, প্রায় 14 SWG।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: '100 A ফিউজ তার 2.00 মিমি, প্রায় 14 SWG', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গেজ নম্বর যত বাড়ে, তার তত চিকন হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ইনসুলেশন ছাড়িয়ে খালি তার খাঁজে মাপুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: '100 A-র বেশি হলে তার নয়, HRC ফিউজ', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'গেজ নম্বর যত বড়, তার তত মোটা হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চোখে দেখে আন্দাজ করলেই মাপ ঠিক হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ইনসুলেশন সমেত মাপলেও নম্বর একই আসে', correct: false),
        LearnWhyChip(id: 'w8', textBn: '1.50 মিমি তারই 100 A-তে যথেষ্ট হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যত বড় লোড তত মোটা তার, মাপার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'মাইক্রোমিটারে মাপা শুধু অফিসের কাজ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'blow',
      promptBn: 'একটা বাড়িতে শর্ট সার্কিট হয়েছিল — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'house',
          labelBn: 'শুধু বাড়ির ফিউজ উড়েছে, LT বক্স আর HG ঠিক',
          asset: 'assets/game/art/m6_board63/blow_house.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'find',
          labelBn: 'HG উড়েছে — আগে নিচের ফিউজে ভুল তার খোঁজা',
          asset: 'assets/game/art/m6_board63/blow_find.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'iso',
          labelBn: 'LT বন্ধ, AB খুলে তিন ব্লেড দেখা, ডেড প্রমাণ, আর্থ',
          asset: 'assets/game/art/m6_board63/blow_iso.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'recharge',
          labelBn: 'HG উড়েছে, কারণ না খুঁজেই আবার চার্জ দেওয়া',
          asset: 'assets/game/art/m6_board63/blow_recharge.svg',
          scene: true,
          correct: false,
          rejectBn: 'আসল কারণ না খুঁজে বারবার ফিউজ চার্জ করবেন না — ফল্ট আরও বড় আকার নিতে পারে।',
        ),
        LearnBoardOption(
          id: 'tick',
          labelBn: 'LT বক্সের ফিউজ উড়েছে, বাড়িরটা অটুট — "সব ঠিক"',
          asset: 'assets/game/art/m6_board63/blow_tick.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাড়ির ফল্টে বাড়ির ফিউজ বা MCB সবার আগে উড়বে — না উড়লে কো-অর্ডিনেশন বা তারের সাইজ ভুল।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'AB সুইচ না খুলেই HG-র তার বদলানো হচ্ছে',
          asset: 'assets/game/art/m6_board63/blow_live.svg',
          scene: true,
          correct: false,
          // Live lesson 6.3 point 6, word for word (ruling M6-2).
          rejectBn: 'হর্ন গ্যাপ ফিউজের তার বদলানোর আগে AB সুইচ খুলে তিনটি ব্লেডই খুলেছে কি না দেখুন, টেস্টারে ডেড প্রমাণ করুন এবং আর্থিং দিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বাড়ির ফল্টে বাড়ির ফিউজ বা MCB আগে উড়বে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আসল কারণ না খুঁজে কখনো আবার চার্জ নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'HG-র তার বদলাতে AB খুলে, ডেড প্রমাণ করে আর্থ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো ফল্টে আগে ট্রান্সফরমারের ফিউজ উড়বে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফিউজ উড়লে নতুন তার বেঁধে সাথে সাথে চার্জ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'AB না খুলেও HG-র তার বদলানো যায়, ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাড়ির ফিউজ না উড়লে চিন্তার কিছুই নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বারবার চার্জ দিলে ফল্ট নিজেই সেরে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'HG উড়লে কারণ খোঁজা মানে শুধু সময় নষ্ট', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board63Lines.rivalTaunt,
    rivalLineBn: M6Board63Lines.rivalMyth,
    exitBn: M6Board63Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ফিউজ উড়বে না',
      'DTR পুড়ে ছাই',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ফিউজ তার নিজে গলে দামি সরঞ্জাম বাঁচায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'মোটা তার গলে না, ফল্ট সোজা ট্রান্সফরমারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'তার মোটা হলে টিভি-ফ্রিজ বা DTR পুড়ে ছাই', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মোটা তার দিলে ফিউজ আরও বেশি মজবুত হয়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ফিউজ না উড়লেই লাইন সবচেয়ে নিরাপদ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'বারবার ফিউজ ওড়া ঠেকাতে মোটা তারই ভালো', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'তার যত মোটা, ট্রান্সফরমার তত নিরাপদ', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ফিউজ ওড়া মানে শুধুই ফিউজ তারের দোষ', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'মোটা তারে ফল্ট কারেন্ট নিজেই কমে যায়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M6Board63Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'রোজ রোজ ফিউজ ওড়ে! এত মাপজোখের কী দরকার?';

  /// Lesson 6.3's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'কিট-ক্যাট ফিউজে যত মোটা তার বাঁধা যাবে, ফিউজ তত মজবুত হবে এবং বারবার ফিউজ ওড়ার ঝামেলা থাকবে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack63;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
