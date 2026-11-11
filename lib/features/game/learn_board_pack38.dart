import 'learn_board_models.dart';

/// Module 3 Lesson 3.8 (সার্ভিস কেবিল ও এনার্জি মিটার: শেষ সংযোগ), the picture
/// board (rung `3.8/learn`, pack `learn_3_8`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board38_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * cable: the service cable is pulled from the pole to the house on a
///    supporting (bearer / GI) wire so the cable itself carries no strain;
///    check the insulation for cuts on a new connection; single-phase uses
///    twin-core, three-phase four-core;
///  * drip: a U-shaped drip loop before the cable enters the meter box stops
///    rain water running down the cable into the meter;
///  * box: the meter box is a live panel — insulated tools, the incoming
///    supply made sure OFF; the meter seal is not broken (broken = suspected
///    tampering);
///  * fault: a loose connection makes the lights flicker and the voltage drop,
///    and can heat up and start a fire; a cut neutral gives a dangerous voltage
///    fluctuation that burns appliances; a cable rubbing on a branch loses its
///    insulation (short circuit / leakage current);
///  * fast: a meter rarely is the fault when it runs fast — a faulty appliance
///    (an old fridge) or earth leakage is; check the house load before the
///    meter; be patient and polite, explain in simple words.
/// The rival's myth is the lesson's second myth buster (the neutral one, a
/// life-safety myth), word for word; the first (a fast meter) is round `fast`.
const learnBoardPack38 = LearnBoardPack(
  lessonId: '3.8',
  titleBn: 'সার্ভিস কেবিল ও এনার্জি মিটার: শেষ সংযোগ',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'শেষ মাইল: কেবিল আনে বিদ্যুৎ, মিটার রাখে প্রতি ইউনিটের হিসাব।',
  earnedBn: 'টান বিয়ারার তারে, মুখে ড্রিপ লুপ, বক্সে সাপ্লাই বন্ধ — আর নিউট্রালও খালি হাতে নয়।',
  slots: [
    LearnBoardSlot(
      id: 'cable',
      promptBn: 'পোল থেকে বাড়িতে সার্ভিস কেবিল টানবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'span',
          labelBn: 'বিয়ারার তারের সাথে বাঁধা কেবিল',
          asset: 'assets/game/art/m3_board38/cable_span.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'anchor',
          labelBn: 'বাড়ির হুকে বিয়ারার, কেবিল ঢিলা',
          asset: 'assets/game/art/m3_board38/cable_anchor.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'বিয়ারার ছাড়াই টানটান কেবিল',
          asset: 'assets/game/art/m3_board38/cable_tight.svg',
          scene: true,
          correct: false,
          rejectBn: 'সার্ভিস কেবিলের নিজের ওপর যেন কোনো টান না থাকে — সমস্ত টান নেবে সাপোর্টিং বা বিয়ারার তার।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'কাটা ইনসুলেশনের কেবিলেই কানেকশন',
          asset: 'assets/game/art/m3_board38/cable_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন কানেকশনে দেখুন ইনসুলেশনে কাটা বা ক্ষতি আছে কিনা — কাটা কেবিলে শর্ট সার্কিট বা লিকেজ।',
        ),
        LearnBoardOption(
          id: 'hook',
          labelBn: 'কেবিল নিজেই হুকে কষে বাঁধা',
          asset: 'assets/game/art/m3_board38/cable_hook.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেবিল হুকে কষে বাঁধলে সব টান কেবিলের ওপর — ছিঁড়ে যেতে পারে। টান থাকবে বিয়ারার তারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সমস্ত টান নেবে সাপোর্টিং বা বিয়ারার তার', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কানেকশনের আগে ইনসুলেশনে কাটা খুঁজুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সিঙ্গেল-ফেজে টুইন-কোর, থ্রি-ফেজে ফোর-কোর', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টানটান কেবিলই সবচেয়ে মজবুত সংযোগ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বিয়ারার তার শুধু দেখনদারি, কাজের নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ইনসুলেশনে ছোট কাটা থাকলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কেবিল হুকে কষে বাঁধলেই টান সামলায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সিঙ্গেল-ফেজেও ফোর-কোর কেবিল লাগে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'থ্রি-ফেজেও টুইন-কোর কেবিলই যথেষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'drip',
      promptBn: 'বৃষ্টির দিনে মিটার বক্সে সার্ভিস কেবিল ঢোকাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'loop',
          labelBn: 'বক্সের নিচে U আকারের ড্রিপ লুপ',
          asset: 'assets/game/art/m3_board38/drip_loop.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'side',
          labelBn: 'নিচ থেকে উঠে বক্সে ঢোকা কেবিল',
          asset: 'assets/game/art/m3_board38/drip_side.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'top',
          labelBn: 'ওপর থেকে সোজা বক্সে নামা কেবিল',
          asset: 'assets/game/art/m3_board38/drip_top.svg',
          scene: true,
          correct: false,
          rejectBn: 'সোজা ওপর থেকে ঢোকালে বৃষ্টির জল কেবিল বেয়ে মিটারের ভেতরে ঢোকে — আগে U আকারের ড্রিপ লুপ।',
        ),
        LearnBoardOption(
          id: 'taut',
          labelBn: 'টানটান কেবিল সোজা বক্সের পাশে',
          asset: 'assets/game/art/m3_board38/drip_taut.svg',
          scene: true,
          correct: false,
          rejectBn: 'লুপ ছাড়া টানটান কেবিল বেয়ে জল বক্সে গড়ায়, টানও পড়ে কেবিলের ওপর — ড্রিপ লুপ মাস্ট।',
        ),
        LearnBoardOption(
          id: 'hump',
          labelBn: 'উল্টো বাঁক দিয়ে বক্সের মাথায় কেবিল',
          asset: 'assets/game/art/m3_board38/drip_hump.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওপরের উঁচু বাঁক জল আটকায় না — বক্সের নিচে U আকারের ড্রিপ লুপই জলকে মিটারে ঢুকতে দেয় না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ড্রিপ লুপ জলকে মিটারে ঢুকতে দেয় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বক্সে ঢোকার আগে কেবিলে U আকারের বাঁক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জল লুপের নিচ থেকে ঝরে, বক্সে যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কেবিল সোজা ঢোকালে জল ঢোকার ভয় নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ড্রিপ লুপ শুধু শুকনো মরসুমে লাগে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বৃষ্টির জল কেবিল বেয়ে কখনো নামে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মিটার বক্সে একটু জল ঢুকলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ওপরে উঁচু বাঁকেও জল বক্সে যায় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লুপ না রেখে কেবিল টানটান রাখাই ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'box',
      promptBn: 'মিটার বক্সের টার্মিনালে কাজ করতে হবে — কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'off',
          labelBn: 'আগে মিটারের ইনকামিং সাপ্লাই বন্ধ',
          asset: 'assets/game/art/m3_board38/box_off.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tools',
          labelBn: 'সাপ্লাই বন্ধে ইনসুলেটেড টুলে কাজ',
          asset: 'assets/game/art/m3_board38/box_tools.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'metal',
          labelBn: 'খোলা লোহার স্ক্রু-ড্রাইভারে কাজ',
          asset: 'assets/game/art/m3_board38/box_metal.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটার বক্স একটি লাইভ প্যানেল — ইনসুলেটেড টুলস ছাড়া টার্মিনালে হাত দেবেন না।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'সাপ্লাই চালু রেখেই টার্মিনালে কাজ',
          asset: 'assets/game/art/m3_board38/box_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটার বক্স লাইভ প্যানেল — কাজের আগে নিশ্চিত করুন মিটারের ইনকামিং সাপ্লাই বন্ধ আছে।',
        ),
        LearnBoardOption(
          id: 'seal',
          labelBn: 'সিল ভেঙে মিটারের কভার খোলা',
          asset: 'assets/game/art/m3_board38/box_seal.svg',
          scene: true,
          correct: false,
          rejectBn: 'সিল ভাঙা মানেই মিটার ট্যাম্পারিংয়ের সন্দেহ — সিল না ভেঙে কাজ করুন, দরকারে নতুন সিলের ব্যবস্থা।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মিটার বক্সে কাজ মানে লাইভ প্যানেলে কাজ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের আগে ইনকামিং সাপ্লাই বন্ধ নিশ্চিত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মিটারের সিল অক্ষত রেখে কাজ করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মিটার বক্সে সাধারণ টুলেই কাজ চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সিল ভাঙলে কারও কোনো সন্দেহ হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চালু সাপ্লাইয়ে কাজ করলে সময় বাঁচে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছোট কাজে ইনসুলেটেড টুলস লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মিটার বক্সে কখনো বিদ্যুৎ থাকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সিল ভেঙে খুললে মিটার ভালো দেখা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fault',
      promptBn: 'গ্রাহকের ঘরে আলো কাঁপছে, ভোল্টেজ কম — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'tighten',
          labelBn: 'সাপ্লাই বন্ধে ঢিলা টার্মিনাল টাইট',
          asset: 'assets/game/art/m3_board38/fault_tighten.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'inspect',
          labelBn: 'কেবিলের ইনসুলেশন খুঁটিয়ে দেখা',
          asset: 'assets/game/art/m3_board38/fault_inspect.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hot',
          labelBn: 'গরম ঢিলা জোড় যেমন আছে রাখা',
          asset: 'assets/game/art/m3_board38/fault_hot.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলা কানেকশনে আলো কাঁপে, ভোল্টেজ নামে — আর জোড় গরম হয়ে আগুনও লাগতে পারে।',
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'কাটা নিউট্রাল ফেলে রেখে চলে যাওয়া',
          asset: 'assets/game/art/m3_board38/fault_neutral.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিউট্রাল কেটে গেলে বিপজ্জনক ভোল্টেজ ফ্ল্যাকচুয়েশন — গ্রাহকের যন্ত্রপাতি পুড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'rub',
          labelBn: 'ডালে ঘষা কেবিল যেমন আছে রাখা',
          asset: 'assets/game/art/m3_board38/fault_rub.svg',
          scene: true,
          correct: false,
          rejectBn: 'গাছের ডালে ঘষা লেগে ইনসুলেশন নষ্ট হয় — তাতে শর্ট সার্কিট বা লিকেজ কারেন্ট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঢিলা কানেকশনে আলো কাঁপে, ভোল্টেজ নামে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঢিলা জোড় গরম হয়ে আগুন লাগতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বেশিরভাগ অভিযোগ সার্ভিস কানেকশনের দোষে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আলো কাঁপলে সবসময় মিটারটাই খারাপ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নিউট্রাল কাটলে যন্ত্রপাতির ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডালে ঘষা কেবিলে কোনো বিপদ হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গরম জোড় নিজে থেকেই ঠান্ডা হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লো-ভোল্টেজ গ্রাহকের নিজের সমস্যা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঢিলা জোড়ে শুধু বিল একটু বেশি আসে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fast',
      promptBn: 'গ্রাহক বলছেন মিটার খুব দ্রুত চলছে — আগে কী দেখবেন?',
      options: [
        LearnBoardOption(
          id: 'fridge',
          labelBn: 'পুরোনো ফ্রিজের মতো বাড়ির লোড পরীক্ষা',
          asset: 'assets/game/art/m3_board38/fast_fridge.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leak',
          labelBn: 'বাড়িতে আর্থ লিকেজ আছে কিনা পরীক্ষা',
          asset: 'assets/game/art/m3_board38/fast_leak.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'swap',
          labelBn: 'লোড না দেখেই মিটার বদলে দেওয়া',
          asset: 'assets/game/art/m3_board38/fast_swap.svg',
          scene: true,
          correct: false,
          rejectBn: 'খুব কম ক্ষেত্রেই মিটার খারাপ থাকে — মিটার পরীক্ষার আগে গ্রাহকের বাড়ির লোড পরীক্ষা করুন।',
        ),
        LearnBoardOption(
          id: 'rude',
          labelBn: 'গ্রাহকের সাথে রাগারাগি করা',
          asset: 'assets/game/art/m3_board38/fast_rude.svg',
          scene: true,
          correct: false,
          rejectBn: 'আপনিই বিদ্যুৎ সংস্থার মুখ — ধৈর্য আর ভদ্রতা রাখুন, সমস্যাটা সহজ ভাষায় বোঝান।',
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'কিছু না বুঝিয়ে চলে যাওয়া',
          asset: 'assets/game/art/m3_board38/fast_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহককে সমস্যাটা সহজ ভাষায় বোঝান — ভালো ব্যবহার করলে তাঁরা আপনার কাজে সহযোগিতা করবেন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বেশিরভাগ দোষ ঘরের যন্ত্র বা আর্থ লিকেজে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মিটার পরীক্ষার আগে বাড়ির লোড পরীক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গ্রাহককে সমস্যা সহজ ভাষায় বুঝিয়ে বলুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মিটার দ্রুত চললে মিটারটাই নিশ্চয় খারাপ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আধুনিক মিটার প্রায়ই ভুল রিডিং দেখায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্থ লিকেজে মিটারের রিডিং বাড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পুরোনো ফ্রিজ কখনো বেশি বিদ্যুৎ খায় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রাহক অভিযোগ করলে কড়া কথাই ঠিক', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মিটার বদলালেই সব অভিযোগ মিটে যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board38Lines.rivalTaunt,
    rivalLineBn: M3Board38Lines.rivalMyth,
    exitBn: M3Board38Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'খালি হাতে নিউট্রাল তার',
      'আনব্যালেন্সে নিউট্রালে ভোল্টেজ',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সাধারণ অবস্থাতেও নিউট্রালে ভোল্টেজ থাকতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'আনব্যালেন্স বা ফল্টে নিউট্রালও ফেজের মতো প্রাণঘাতী', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'নিউট্রাল তারও খালি হাতে নয়, গ্লাভস পরে ধরুন', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'নিউট্রাল তারে কখনো কোনো ভোল্টেজই থাকে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'নিউট্রাল ধরতে গ্লাভস লাগে না, খালি হাতই যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ফল্ট হলেও নিউট্রাল তার সবসময় নিরাপদ থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'শুধু ফেজ তারই বিপজ্জনক, নিউট্রাল একেবারে নিরীহ', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'আনব্যালেন্সে নিউট্রালের ভোল্টেজ আরও কমে যায়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ লাইনম্যান নিউট্রাল খালি হাতেই ধরেন', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board38Lines {
  static const rivalTaunt = 'আরে, ওটা তো নিউট্রাল! ওর জন্য আবার গ্লাভস কেন?';

  /// Lesson 3.8's second myth buster, word for word.
  static const rivalMyth = 'সার্ভিস কেবিলের নিউট্রাল তারে কোনো বিদ্যুৎ থাকে না, তাই ওটা খালি হাতে ধরলেও চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
