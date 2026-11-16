import 'learn_board_models.dart';

/// Module 7 Lesson 7.3 (ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব?), the picture
/// board (rung `7.3/learn`, pack `learn_7_3`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board73_art.py`, drawn to
/// scale; the only marks on them are the pole plate (415 V / 11 kV / 33 kV)
/// and a measured tag in metres, in English digits. Every round and trap
/// comes from the live lesson text (`tool/all_training_chapters_bn.json`, 7.3)
/// and the Module 7 rulings (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_73.json`):
///  * road: section point 1 — across a road LT 5.8 m, 11 kV and 33 kV 6.5 m
///    (rulings X3/X5: the live text, not the spec's old 6.1 m); an old span
///    at 6.1 m is "below today's rule, report it", not "illegal" (X5); the
///    summer sag of pro tip 3;
///  * roof: point 2, vertical — LT 2.5 m, HT 3.7 m over a roof or a
///    চিলেকোঠা; new construction under the line goes to the supervisor (pro
///    tip 2);
///  * side: point 2, horizontal — LT 1.2 m, 33 kV 2.0 m. Ruling M7-7: HT side
///    cards are 33 kV only, and every 2.0 m text names 33 kV;
///  * section: point 3 — a minimum gap between circuits and phase to phase,
///    and a set vertical gap to a telephone or internet cable (no figures:
///    the lesson gives none);
///  * duty: point 4 — warn a person carrying a bamboo or an iron rod near the
///    line, report an old line not as the law wants (a sag), report new
///    construction; myth 1's wet clothes and roof bamboo.
/// Boards have no deadly freeze: a passer-by's rod reaching the line (R17,
/// ruling M7-3) is played in do_7_3_b; on the board every trap teaches. The
/// rival's myth is the lesson's second myth, word for word (ruling M7-10; the
/// first myth belongs to do_7_3_b).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack73 = LearnBoardPack(
  lessonId: '7.3',
  titleBn: 'ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব?',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board73Lines.intro,
  earnedBn: M7Board73Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'road',
      // Ruling X5 / M7-7: an old 6.1 m span may be lawfully existing, so the
      // round asks for today's rule, not "lawful".
      promptBn: 'রাস্তার ওপর দিয়ে লাইন — কোনটা আজকের নিয়মের উচ্চতায় আছে?',
      options: [
        LearnBoardOption(
          id: 'ok11',
          labelBn: '11 kV লাইন, রাস্তা থেকে 6.5 মিটার উঁচুতে',
          asset: 'assets/game/art/m7_board73/road_ok11.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'oklt',
          labelBn: '415 V লাইন, রাস্তা থেকে 5.8 মিটার উঁচুতে',
          asset: 'assets/game/art/m7_board73/road_oklt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ok33',
          labelBn: 'গরমের দুপুরে 33 kV লাইন, 6.5 মিটার উঁচুতে',
          asset: 'assets/game/art/m7_board73/road_ok33.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'low11',
          labelBn: '11 kV লাইন, রাস্তা থেকে 5.8 মিটার উঁচুতে',
          asset: 'assets/game/art/m7_board73/road_low11.svg',
          scene: true,
          correct: false,
          rejectBn: '11 kV লাইন রাস্তা পার হলে অন্তত 6.5 মিটার উঁচুতে চাই — 5.8 মিটার LT লাইনের মাপ।',
        ),
        LearnBoardOption(
          id: 'old33',
          labelBn: 'পুরনো 33 kV লাইন, রাস্তা থেকে 6.1 মিটার',
          asset: 'assets/game/art/m7_board73/road_old33.svg',
          scene: true,
          correct: false,
          // Ruling X5: an old span may be lawfully existing — "report it".
          rejectBn: 'আজকের নিয়মে 33 kV লাইন রাস্তা পার হলে 6.5 মিটার চাই — 6.1 মিটারের পুরনো লাইন রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'sag',
          labelBn: 'গরমে ঝুলে পড়া 11 kV লাইন, 5.6 মিটারে',
          asset: 'assets/game/art/m7_board73/road_sag.svg',
          scene: true,
          correct: false,
          rejectBn: 'গরমে তার প্রসারিত হয়ে ঝুলে পড়ে, গ্রাউন্ড ক্লিয়ারেন্স কমে যায় — এমন নিচু তার রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'lowlt',
          labelBn: '415 V লাইন, রাস্তা থেকে 5.0 মিটার উঁচুতে',
          asset: 'assets/game/art/m7_board73/road_lowlt.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাস্তা পার হলে LT লাইনও অন্তত 5.8 মিটার উঁচুতে চাই — নিচু তার উঁচু গাড়িতে লেগে দুর্ঘটনা ঘটায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রাস্তা পার হলে LT 5.8, HT 6.5 মিটার উঁচুতে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'উঁচু বাস-ট্রাক যেন নিরাপদে নিচ দিয়ে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মাপ ধরা হয় তারের সবচেয়ে নিচু জায়গা থেকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'HT লাইনও 5.8 মিটারে থাকলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গাড়ির মাথায় না লাগলেই আর কোনো ভয় নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মাপ ধরা হয় পোলের মাথা থেকে মাটি পর্যন্ত', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পুরনো লাইন নিচু হলেও রিপোর্টের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গরমে তার টানটান হয়, তাই আরও উঁচুতে ওঠে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাস্তার ওপর LT লাইনের কোনো মাপ নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'roof',
      promptBn: 'বাড়ির ছাদের ওপর দিয়ে লাইন — কোনটা নিয়ম মেনে?',
      options: [
        LearnBoardOption(
          id: 'lt',
          labelBn: '415 V লাইন, ছাদ থেকে 2.5 মিটার ওপরে',
          asset: 'assets/game/art/m7_board73/roof_lt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ht',
          labelBn: '11 kV লাইন, চিলেকোঠা থেকে 3.7 মিটার ওপরে',
          asset: 'assets/game/art/m7_board73/roof_ht.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'htlow',
          labelBn: '11 kV লাইন, ছাদ থেকে 2.5 মিটার ওপরে',
          asset: 'assets/game/art/m7_board73/roof_htlow.svg',
          scene: true,
          correct: false,
          rejectBn: 'HT লাইন ছাদের ওপর দিয়ে গেলে অন্তত 3.7 মিটার চাই — 2.5 মিটার LT লাইনের মাপ।',
        ),
        LearnBoardOption(
          id: 'stair',
          labelBn: '415 V লাইন, চিলেকোঠা থেকে 1.0 মিটার ওপরে',
          asset: 'assets/game/art/m7_board73/roof_stair.svg',
          scene: true,
          correct: false,
          rejectBn: 'চিলেকোঠার ওপর দিয়ে গেলেও LT লাইনে 2.5 মিটার চাই — এখানে তার খুব কাছে।',
        ),
        LearnBoardOption(
          id: 'newfloor',
          labelBn: '11 kV লাইনের নিচে ছাদে নতুন তলা উঠছে',
          asset: 'assets/game/art/m7_board73/roof_newfloor.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইনের নিচে নতুন নির্মাণ চললে অবিলম্বে সুপারভাইজারকে জানান — তার আর ছাদের ফাঁক কমছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ছাদের ওপর LT 2.5, HT 3.7 মিটার ফাঁক চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চিলেকোঠার ওপর দিয়ে গেলেও একই মাপ লাগে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বাড়ির বাসিন্দাদের সুরক্ষার জন্যই এই দূরত্ব', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছাদের ওপর HT লাইনেও 2.5 মিটারই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চিলেকোঠা ছোট ঘর, ওর মাপ ধরতে হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নতুন তলা উঠলে লাইনের কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছাদের ওপরে তার থাকলে কোনো মাপ লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মাপ ধরা হয় মাটি থেকে, ছাদ থেকে নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাড়ির মালিক রাজি থাকলে দূরত্ব লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'side',
      promptBn: 'বাড়ির পাশ দিয়ে লাইন — কোনটা ঠিক দূরত্বে?',
      options: [
        LearnBoardOption(
          id: 'lt',
          labelBn: '415 V লাইন, বারান্দা থেকে 1.2 মিটার দূরে',
          asset: 'assets/game/art/m7_board73/side_lt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ht33',
          labelBn: '33 kV লাইন, বারান্দা থেকে 2.0 মিটার দূরে',
          asset: 'assets/game/art/m7_board73/side_ht33.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'close33',
          labelBn: '33 kV লাইন, বারান্দা থেকে 1.2 মিটার দূরে',
          asset: 'assets/game/art/m7_board73/side_close33.svg',
          scene: true,
          correct: false,
          // Ruling M7-7: the 2.0 m text names 33 kV (11 kV at 1.2 m is legal).
          rejectBn: '33 kV লাইন বাড়ির পাশ দিয়ে গেলে অন্তত 2.0 মিটার দূরে চাই — 1.2 মিটারে চলবে না।',
        ),
        LearnBoardOption(
          id: 'grill',
          labelBn: '415 V লাইন, বারান্দার গ্রিল থেকে 0.3 মিটারে',
          asset: 'assets/game/art/m7_board73/side_grill.svg',
          scene: true,
          correct: false,
          // Live lesson point 2 (importance), word for word.
          rejectBn: 'বাড়ির খুব কাছ দিয়ে যাওয়া তার থেকে শক লাগা বা আগুন ধরার ঝুঁকি থাকে।',
        ),
        LearnBoardOption(
          id: 'slab',
          labelBn: 'নতুন স্ল্যাব 33 kV লাইনের 0.6 মিটারের মধ্যে',
          asset: 'assets/game/art/m7_board73/side_slab.svg',
          scene: true,
          correct: false,
          // Live lesson point 2 (importance), word for word.
          rejectBn: 'বাড়ির মালিক আইন লঙ্ঘন করে লাইনের নিচে বা পাশে নির্মাণ করলে সেটিও একটি বিপদ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পাশ দিয়ে গেলে LT 1.2, 33 kV 2.0 মিটার দূরে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মাপ ধরা হয় বারান্দা বা দেওয়াল থেকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'খুব কাছের তার থেকে শক বা আগুনের ঝুঁকি', correct: true),
        LearnWhyChip(id: 'w4', textBn: '33 kV লাইনও 1.2 মিটার দূরে থাকলেই চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রিলে না ছুঁলে তার যত কাছেই থাক, চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নতুন স্ল্যাব বাড়ালে মাপ আর দেখতে হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মাপ ধরা হয় বাড়ির পেছনের দেওয়াল থেকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পাশের তারে শুধু রাতে বিপদ, দিনে নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বারান্দায় লোক না থাকলে দূরত্ব লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'section',
      promptBn: 'একই পোলে কয়েকটা লাইন — কোনটা ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'twin',
          labelBn: 'দুটো সার্কিট, মাঝে চওড়া সমান ফাঁক',
          asset: 'assets/game/art/m7_board73/section_twin.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cable',
          labelBn: 'ইন্টারনেট কেবিল পাওয়ার লাইনের অনেক নিচে',
          asset: 'assets/game/art/m7_board73/section_cable.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'windtouch',
          labelBn: 'বাতাসে দুলে তার একে অপরকে ছুঁয়ে স্পার্ক',
          asset: 'assets/game/art/m7_board73/section_windtouch.svg',
          scene: true,
          correct: false,
          // Live lesson point 3 (importance), word for word.
          rejectBn: 'অপর্যাপ্ত ক্লিয়ারেন্সের কারণে বাতাসের সময় তারগুলো একে অপরকে স্পর্শ করে শর্ট সার্কিট ঘটাতে পারে।',
        ),
        LearnBoardOption(
          id: 'tied',
          labelBn: 'ইন্টারনেট কেবিল LT তারের সাথে বাঁধা',
          asset: 'assets/game/art/m7_board73/section_tied.svg',
          scene: true,
          correct: false,
          rejectBn: 'বিদ্যুৎ লাইন আর টেলিফোন বা ইন্টারনেট কেবিলের মধ্যে নির্দিষ্ট উল্লম্ব দূরত্ব রাখা বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'phases',
          labelBn: 'ছোট ক্রস-আর্মে ফেজগুলো গায়ে গায়ে',
          asset: 'assets/game/art/m7_board73/section_phases.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টরদের নিজেদের মধ্যে, ফেজ-টু-ফেজ, ন্যূনতম দূরত্ব রাখতেই হয় — এখানে তারগুলো গায়ে গায়ে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দুই সার্কিট ও ফেজের মাঝে ন্যূনতম ফাঁক চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কম ফাঁকে বাতাসে তার ছুঁয়ে শর্ট সার্কিট', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'টেলিফোন কেবিলের সাথেও উল্লম্ব দূরত্ব চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তারের মাঝে ফাঁক যত কম, লাইন তত মজবুত', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কেবিল পাওয়ার তারে বাঁধলে ঝোলে না, ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাতাসে তার ছুঁলেও কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একই পোলে থাকলে দূরত্বের নিয়ম নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফেজ একসাথে থাকলে বিদ্যুৎ ভালো চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ইন্টারনেট কেবিলে বিদ্যুৎ নেই, তাই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'duty',
      promptBn: 'লাইনের কাছে বিপদ — লাইনম্যানের কোন কাজটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'warnrod',
          labelBn: 'রড নিয়ে যাওয়া লোককে হাত তুলে থামানো',
          asset: 'assets/game/art/m7_board73/duty_warnrod.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'callbuild',
          labelBn: 'লাইনের নিচে নির্মাণ দেখে সুপারভাইজারকে ফোন',
          asset: 'assets/game/art/m7_board73/duty_callbuild.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'reportsag',
          labelBn: 'ঝুলে পড়া পুরনো তার দেখে রিপোর্টের ফোন',
          asset: 'assets/game/art/m7_board73/duty_reportsag.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ignorebamboo',
          labelBn: 'বাঁশ নিয়ে লোক যাচ্ছে, লাইনম্যান ফোনে গল্পে',
          asset: 'assets/game/art/m7_board73/duty_ignorebamboo.svg',
          scene: true,
          correct: false,
          // Live lesson point 4, nearly word for word.
          rejectBn: 'লাইনের নিচে কেউ বাঁশ বা লোহার রড নিয়ে গেলে তাঁকে বিপদের বিষয়ে সতর্ক করা উচিত।',
        ),
        LearnBoardOption(
          id: 'wetclothes',
          labelBn: 'তারের নিচে ভেজা কাপড় দেখেও চুপচাপ চলে যাওয়া',
          asset: 'assets/game/art/m7_board73/duty_wetclothes.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা কাপড় বিদ্যুৎ পরিবহন করতে পারে — তারের নিচে কাপড় শুকোতে দেখলে সতর্ক করুন।',
        ),
        LearnBoardOption(
          id: 'roofbamboo',
          labelBn: 'ছাদে তারের দিকে হেলানো বাঁশ, না দেখে চলে যাওয়া',
          asset: 'assets/game/art/m7_board73/duty_roofbamboo.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাতাসে তার দুলে দূর থেকেও আর্ক তৈরি হতে পারে — ছাদের বাঁশের কথা বাড়ির লোককে বলুন।',
        ),
        LearnBoardOption(
          id: 'walkpast',
          labelBn: 'নিচু ঝোলা তার দেখেও ফোনে কথা বলে চলে যাওয়া',
          asset: 'assets/game/art/m7_board73/duty_walkpast.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো লাইন আইন অনুযায়ী না থাকলে, যেমন তার ঝুলে পড়লে, সেটি রিপোর্ট করা আপনার দায়িত্ব।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বিপদ দেখলে সতর্ক করা বা রিপোর্ট করা দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাইনের কাছে বাঁশ, রড বা নির্মাণ মানেই বিপদ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিয়ম ভাঙা লাইন দেখলে সুপারভাইজারকে জানান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাইন তো কোম্পানির, লোককে বলার কী দরকার', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঝোলা তার নিজে থেকেই আবার টান হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শুকনো বাঁশ বা রড তারে লাগলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভেজা কাপড় বিদ্যুৎ টানে না, কোনো ভয় নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ডিউটির বাইরে দেখা বিপদ আমার কাজ নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রিপোর্ট করলে ঝামেলা, চুপ থাকাই ভালো', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board73Lines.rivalTaunt,
    rivalLineBn: M7Board73Lines.rivalMyth,
    exitBn: M7Board73Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board73Lines.sting,
    flipStingBn: M7Board73Lines.flipSting,
    dangerHints: [
      'দুর্ঘটনার পর তদন্ত',
      'কঠোর শাস্তি',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'দুর্ঘটনার পর তদন্তে সব মাপ নেওয়া হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'নিয়ম ভাঙলে কঠোর শাস্তির বিধান আছে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আইন মানা দায়িত্বশীল কর্মীর কর্তব্য', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কেউ না মাপলে নিয়ম না মানলেও চলে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'একটু কম দূরত্বে কারও কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'তদন্তে শুধু কাগজ দেখে, মাপ নেয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আইন শুধু ইঞ্জিনিয়ারদের, লাইনম্যানের নয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'দুর্ঘটনা হলে দোষ শুধু যে ছুঁয়েছে তার', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'শাস্তি শুধু কোম্পানির, কর্মীর নয়', correct: false),
    ],
  ),
);

/// The board's spoken lines: the careless coworker's (his recorded voice) and
/// the guide's. [rivalExit], [sting] and [flipSting] are already recorded;
/// the rest wait for the voice session (ruling M7-10), silent with the
/// caption held until then (the rival never falls back to the device voice).
abstract final class M7Board73Lines {
  /// DRAFT wording — owner.
  static const intro = 'রাস্তা, ছাদ, বাড়ির পাশ, অন্য লাইন — আইন কতটা দূরত্ব চায়, ছবি দেখে চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'রাস্তায় LT 5.8, HT 6.5; ছাদে LT 2.5, HT 3.7; পাশে LT 1.2, 33 kV 2.0 মিটার — কম দেখলে রিপোর্ট করুন।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, ফিতে নিয়ে কে আর তার মাপতে আসবে!';

  /// Lesson 7.3's second myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'ক্লিয়ারেন্স একটু কম হলে কিছু হয় না, কেউ তো আর মাপতে আসছে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

  /// Already recorded (boards 5.6–5.8, 7.2): the flipped believe question
  /// (the runner flips it on half of all plays), so the kit's default
  /// "shortcut / save your life" either/or line never plays on this board.
  static const flipSting = 'এই লোক যা বলছে… সেটা কি ভুল?';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12 / M7-10: the rival's new lines (the taunt is a draft; the
  /// myth is the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Ruling M6-12: every guide line on this board, for the owner's wording
  /// pass and the voice session (lesson quotes in the trap reasons included,
  /// since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting and its flipped form, the myth's
  /// right reasons, the earned line).
  static List<String> get guideSpoken {
    final p = learnBoardPack73;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      p.myth.stingBn,
      p.myth.flipStingBn,
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
