import 'learn_board_models.dart';

/// Module 2 Lesson 2.10 (হাতিয়ারের যত্ন ও রক্ষণাবেক্ষণ), the picture board
/// (rung `2.10/learn`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m2_board210_art.py`. Every round
/// and every trap comes from the lesson text:
///  * daily: the 5-minute end-of-day routine — wipe dust, dirt, oil and grease
///    off with a dry cloth (never a wet tool in the box), inspect every tool
///    (insulated handles above all), every tool back in its own place;
///  * rust: keep tools dry, a thin layer of WD-40 / light machine oil in the
///    rains, brush light rust off with a steel brush, no oil on the
///    insulation; rust weakens the metal and makes a spanner slip; the
///    lesson's second myth (extra grease draws dirt and kills the grip);
///  * meter: switch off when not in use, battery out for long storage (a leak
///    ruins the meter), probe leads coiled gently, never twisted or folded;
///    yearly calibration at an approved lab;
///  * retire: a crack in an insulated handle, a bent screwdriver tip, a
///    widened spanner jaw, a leaking hydraulic tool — retire it at once,
///    label it unusable, and make a thrown-out tool useless first;
///  * bag (pro tip 1): on the pole a canvas or leather tool bag, not a
///    toolbox — tools close at hand, less risk of one falling from above.
/// The rival's myth is the lesson's first: "ভালো কোম্পানির টুল কিনলে আর যত্ন
/// করার দরকার নেই, ওগুলো সারাজীবন চলে।"
const learnBoardPack210 = LearnBoardPack(
  lessonId: '2.10',
  titleBn: 'হাতিয়ারের যত্ন ও রক্ষণাবেক্ষণ',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'টুলস আপনার সবচেয়ে বিশ্বস্ত সহকর্মী — সামান্য যত্নে ওরা কখনো নিরাশ করে না।',
  earnedBn: 'কাজ শেষে 5 মিনিট: পরিষ্কার, পরিদর্শন, গুছিয়ে রাখা — আর ক্ষতিগ্রস্ত টুল মায়া না করে বাতিল।',
  slots: [
    LearnBoardSlot(
      id: 'daily',
      promptBn: 'দিনের কাজ শেষ, টুলস তুলে রাখবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'wipe', labelBn: 'শুকনো কাপড়ে টুল মুছে নেওয়া', asset: 'assets/game/art/m2_board210/daily_wipe.svg', scene: true, correct: true),
        LearnBoardOption(id: 'place', labelBn: 'প্রতিটি টুল তার নিজের ঘরে', asset: 'assets/game/art/m2_board210/daily_place.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'ভেজা টুল সোজা বাক্সে রাখা',
          asset: 'assets/game/art/m2_board210/daily_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা বা স্যাঁতস্যাঁতে টুল কখনো টুলবক্সে নয় — মরিচা ধরে, ইনসুলেশন নষ্ট হয়।',
        ),
        LearnBoardOption(
          id: 'heap',
          labelBn: 'সব টুল এলোমেলো ছুড়ে ফেলা',
          asset: 'assets/game/art/m2_board210/daily_heap.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি টুলের একটা নির্দিষ্ট ঘর — গোছানো বাক্স পরের দিনের সময় বাঁচায়।',
        ),
        LearnBoardOption(
          id: 'greasy',
          labelBn: 'তেল-ময়লা মাখা টুল তুলে রাখা',
          asset: 'assets/game/art/m2_board210/daily_greasy.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধুলো, ময়লা, তেল বা গ্রিজ শুকনো কাপড়ে মুছে তবেই টুল তুলে রাখুন।',
        ),
        LearnBoardOption(
          id: 'unchecked',
          labelBn: 'ফাটা হাতল না দেখেই তুলে রাখা',
          asset: 'assets/game/art/m2_board210/daily_unchecked.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি টুল হাতে নিয়ে দেখুন — ইনসুলেটেড হাতলের ফাটল বিশেষভাবে পরীক্ষা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাজ শেষে 5 মিনিটের যত্ন টুলের আয়ু বাড়ায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রোজ পরিষ্কার, পরিদর্শন আর গুছিয়ে রাখা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রোজের যত্নে মরিচা আর ইনসুলেশনের ক্ষতি আটকায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভেজা টুল বাক্সে রাখলে নিজে থেকেই শুকোয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টুল মোছামুছি করা শুধুই সময়ের অপচয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেখানে খুশি রাখলেও পরদিন খুঁজে পাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তেল-ময়লা লেগে থাকলেই টুল ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টুল দেখতে ঠিক লাগলে পরীক্ষার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রোজ নয়, মাসে একবার মুছলেই যথেষ্ট হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rust',
      promptBn: 'বর্ষাকাল, ধাতব টুলে মরিচার ভয় — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'oil', labelBn: 'স্প্যানারে হালকা তেলের পাতলা স্তর', asset: 'assets/game/art/m2_board210/rust_oil.svg', scene: true, correct: true),
        LearnBoardOption(id: 'brush', labelBn: 'স্টিল ব্রাশে মরিচা ঘষে তোলা', asset: 'assets/game/art/m2_board210/rust_brush.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'oil_handle',
          labelBn: 'ইনসুলেটেড হাতলে তেল ঢালা',
          asset: 'assets/game/art/m2_board210/rust_oil_handle.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল শুধু ধাতব অংশে — খেয়াল রাখুন তেল যেন ইনসুলেশনের ওপর না লাগে।',
        ),
        LearnBoardOption(
          id: 'damp',
          labelBn: 'জলের মধ্যে টুল ফেলে রাখা',
          asset: 'assets/game/art/m2_board210/rust_damp.svg',
          scene: true,
          correct: false,
          rejectBn: 'টুলসকে জল আর আর্দ্রতা থেকে দূরে রাখুন — মরিচাই ধাতব টুলের প্রধান শত্রু।',
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'মরিচা ধরা স্প্যানারে নাট খোলা',
          asset: 'assets/game/art/m2_board210/rust_slip.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধাতুকে ভেতর থেকে দুর্বল করে — মরিচা ধরা স্প্যানার পিছলে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'grease',
          labelBn: 'পুরু গ্রিজে টুল মাখিয়ে রাখা',
          asset: 'assets/game/art/m2_board210/rust_grease.svg',
          scene: true,
          correct: false,
          rejectBn: 'অতিরিক্ত তেল-গ্রিজ ধুলো-ময়লা টানে, জয়েন্টের ক্ষতি করে, হাতের গ্রিপ কমায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মরিচা ধাতুকে ভেতর থেকে দুর্বল করে দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মরিচা ধরা স্প্যানার নাটে পিছলে যেতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বর্ষায় ধাতব টুলে পাতলা তেলই মরিচা ঠেকায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যত বেশি গ্রিজ মাখাবেন, তত ভালো থাকে টুল', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ইনসুলেটেড হাতলেও তেল দিলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মরিচা শুধু দেখতে খারাপ, কাজে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভেজা টুল ভেজা অবস্থাতেই রেখে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মরিচা ধরা স্প্যানার নাট আরও শক্ত ধরে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বর্ষায় টুলে তেল দেওয়ার কোনো দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'meter',
      promptBn: 'মাল্টিমিটার অনেকদিন তুলে রাখবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'coil', labelBn: 'মিটার বন্ধ, লিড আলতো করে গোটানো', asset: 'assets/game/art/m2_board210/meter_coil.svg', scene: true, correct: true),
        LearnBoardOption(id: 'battery', labelBn: 'লম্বা সময়ের জন্য ব্যাটারি খুলে রাখা', asset: 'assets/game/art/m2_board210/meter_battery.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'on',
          labelBn: 'চালু অবস্থাতেই মিটার রেখে দেওয়া',
          asset: 'assets/game/art/m2_board210/meter_on.svg',
          scene: true,
          correct: false,
          rejectBn: 'যখন ব্যবহার করছেন না, তখন যন্ত্রটি বন্ধ করুন — সূক্ষ্ম যন্ত্রের অতিরিক্ত যত্ন চাই।',
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'প্রোবের তার শক্ত করে পেঁচানো',
          asset: 'assets/game/art/m2_board210/meter_tight.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রোবের তার পেঁচিয়ে বা ভাঁজ করে নয় — আলতো করে গুটিয়ে রাখুন।',
        ),
        LearnBoardOption(
          id: 'leak',
          labelBn: 'ব্যাটারি ভেতরে রেখেই ফেলে রাখা',
          asset: 'assets/game/art/m2_board210/meter_leak.svg',
          scene: true,
          correct: false,
          rejectBn: 'দীর্ঘ সময় ব্যবহার না করলে ব্যাটারি খুলে রাখুন — লিক হয়ে যন্ত্রের ক্ষতি হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভুল রিডিংয়ের মিটার মারাত্মক ভুল পথে চালায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সূক্ষ্ম যন্ত্রের জন্য অতিরিক্ত যত্ন প্রয়োজন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মিটারের নির্ভুল রিডিংয়েই আপনার সুরক্ষা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চালু রাখলে পরের বার তাড়াতাড়ি কাজ শুরু হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ব্যাটারি ভেতরে থাকলেই মিটার ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তার শক্ত করে পেঁচালে কখনোই ছেঁড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্যালিব্রেশন শুধু নতুন মিটারে একবারই লাগে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ডিসপ্লে জ্বললেই রিডিং নির্ভুল ধরে নিন', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মিটার তো মজবুত, যেমন খুশি রাখলেই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'retire',
      promptBn: 'সকালের পরীক্ষায় খুঁতওয়ালা টুল ধরা পড়ল — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'tag', labelBn: "'ব্যবহারের অযোগ্য' লেবেল লাগানো", asset: 'assets/game/art/m2_board210/retire_tag.svg', scene: true, correct: true),
        LearnBoardOption(id: 'unusable', labelBn: 'ফেলার আগে টুলটা অকেজো করা', asset: 'assets/game/art/m2_board210/retire_unusable.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'tape',
          labelBn: 'ফাটা হাতলে টেপ জড়িয়ে চালানো',
          asset: 'assets/game/art/m2_board210/retire_tape.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটেড হাতলে ফাটল বা গভীর ক্ষতি মানে বাতিল — মায়া না করে, অবিলম্বে।',
        ),
        LearnBoardOption(
          id: 'wide_jaw',
          labelBn: 'চওড়া মুখের স্প্যানারে নাট খোলা',
          asset: 'assets/game/art/m2_board210/retire_wide_jaw.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্প্যানারের মুখ চওড়া হয়ে গেলে টুলটি বাতিলের সময় — আর ব্যবহার নয়।',
        ),
        LearnBoardOption(
          id: 'bent_tip',
          labelBn: 'বাঁকা ডগার স্ক্রুড্রাইভার চালানো',
          asset: 'assets/game/art/m2_board210/retire_bent_tip.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্ক্রুড্রাইভারের ডগা ভেঙে বা বেঁকে গেলে টুলটি বাতিল করুন।',
        ),
        LearnBoardOption(
          id: 'hyd_leak',
          labelBn: 'তেল চোঁয়ানো হাইড্রোলিক টুল চালানো',
          asset: 'assets/game/art/m2_board210/retire_hyd_leak.svg',
          scene: true,
          correct: false,
          rejectBn: 'হাইড্রোলিক টুল থেকে ক্রমাগত তেল লিক করলে সেটি বাতিলের সময় হয়েছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ক্ষতিগ্রস্ত টুল মানে নিজের-সহকর্মীর জীবন নিয়ে খেলা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অকেজো করে ফেলুন, যাতে কেউ ভুল করে আবার না নেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দুর্বল টুল মায়া না করে অবিলম্বে বাতিল করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফাটলে টেপ জড়ালে হাতল আবার নতুনের মতো হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দামি টুল, একটু খুঁত থাকলেও চালিয়ে যাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাঁকা ডগা দিয়েও সাবধানে স্ক্রু খোলা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অল্প তেল চোঁয়ালে হাইড্রোলিক টুলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভাঙা টুল যেমন আছে তেমনভাবেই ফেলে দিলেই হল', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'চওড়া মুখের স্প্যানারে জোরে চাপ দিলেই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bag',
      promptBn: 'পোলে উঠে কাজ — টুলস সঙ্গে নেবেন কীভাবে?',
      options: [
        LearnBoardOption(id: 'belt', labelBn: 'কোমরে টুলব্যাগ, দুই হাত মইয়ে', asset: 'assets/game/art/m2_board210/bag_belt.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ground', labelBn: 'ওঠার আগে টুলব্যাগ কোমরে আঁটা', asset: 'assets/game/art/m2_board210/bag_ground.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'toolbox',
          labelBn: 'এক হাতে টুলবক্স নিয়ে মইয়ে ওঠা',
          asset: 'assets/game/art/m2_board210/bag_toolbox.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলের ওপর টুলবক্স নয়, টুলব্যাগ — টুলস হাতের কাছে থাকে, পড়ার ঝুঁকি কমে।',
        ),
        LearnBoardOption(
          id: 'in_hand',
          labelBn: 'হাতে স্প্যানার নিয়ে মই বেয়ে ওঠা',
          asset: 'assets/game/art/m2_board210/bag_in_hand.svg',
          scene: true,
          correct: false,
          rejectBn: 'টুল হাতে নিয়ে ওঠা নয় — ভালো ক্যানভাস বা চামড়ার টুলব্যাগে টুলস নিন।',
        ),
        LearnBoardOption(
          id: 'loose_arm',
          labelBn: 'ক্রস-আর্মে টুল খোলা ফেলে রাখা',
          asset: 'assets/game/art/m2_board210/bag_loose_arm.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোলা ফেলে রাখা টুল ওপর থেকে পড়ে যেতে পারে — টুলব্যাগে রাখুন।',
        ),
        LearnBoardOption(
          id: 'tucked',
          labelBn: 'ব্যাগ ছাড়া কোমরে টুল গোঁজা',
          asset: 'assets/game/art/m2_board210/bag_tucked.svg',
          scene: true,
          correct: false,
          rejectBn: 'গোঁজা টুল খসে নিচে পড়ে — টুলব্যাগ ওপর থেকে টুল পড়ার ঝুঁকি কমায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টুলব্যাগ দরকারি টুলস হাতের কাছে রাখে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টুলব্যাগে ওপর থেকে টুল পড়ার ঝুঁকি কমে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পোলের কাজে টুলবক্স নয়, ভালো টুলব্যাগ চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হাতে টুল থাকলে কাজ তাড়াতাড়ি শুরু হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টুলবক্স ভারী হলেও এক হাতে মই চড়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ক্রস-আর্মে টুল রাখলেই হাতের কাছে থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ওপর থেকে টুল পড়লেও নিচে কারো লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কোমরে টুল গুঁজে রাখলে ব্যাগ লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'টুলব্যাগ শুধু নতুন কর্মীদের জন্য দরকার', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: ToolCareBoardLines.rivalTaunt,
    rivalLineBn: ToolCareBoardLines.rivalMyth,
    exitBn: ToolCareBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'অবহেলায় মরিচা ধরা টুল',
      'যত্ন ছাড়া দামি টুলে ভরসা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সবচেয়ে দামী টুলও অবহেলায় নষ্ট হয়ে যায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'যত্নই টুলের আয়ু আর নির্ভরযোগ্যতা বাড়ায়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ব্র্যান্ড যত ভালোই হোক, রক্ষণাবেক্ষণ চাই', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ভালো কোম্পানির টুলে মরিচা ধরে না কখনো', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'দামি টুল একবার কিনলে সারাজীবন চলে যায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'যত্ন শুধু সস্তা টুলের জন্যই দরকার হয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'নামী ব্র্যান্ডের হাতলে কখনো ফাটল ধরে না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ভালো টুল পরিষ্কার না করলেও ঠিক থাকে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. The exit line is already
/// recorded in his voice (`learnRivalVoice`); the taunt and the myth are new
/// and play through device TTS until they are recorded.
abstract final class ToolCareBoardLines {
  static const rivalTaunt = 'আরে! দামি কোম্পানির টুল — এর আবার মোছামুছির কী দরকার?';

  /// Lesson 2.10's first myth buster, word for word.
  static const rivalMyth = 'ভালো কোম্পানির টুল কিনলে আর যত্ন করার দরকার নেই, ওগুলো সারাজীবন চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines to record (`tool/make_learn_voice.py`).
  static const toRecord = [rivalTaunt, rivalMyth];
}
