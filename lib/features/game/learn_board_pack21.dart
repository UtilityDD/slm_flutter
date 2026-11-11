import 'learn_board_models.dart';

/// Module 2 Lesson 2.1 (লাইনম্যানের টুলবক্স পরিচিতি), the picture board
/// (rung `2.1/learn`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m2_board21_art.py`. Every round
/// and every trap comes from the lesson text:
///  * pliers: always VDE 1000V insulated combination pliers; non-insulated
///    pliers on an LT line = danger; a cracked / cut / burnt handle = not used;
///    "Pliers = Hammer নয়" (Right Tool for Right Job);
///  * strip: the wire stripper strips at its own size, the side cutter cuts,
///    both VDE 1000V; a knife or ordinary pliers nicks the conductor (a weak
///    point, hot spot / break); a blunt cutter is not used;
///  * screw: flat (-) and Phillips (+) of the right size, VDE insulated from
///    the handle to the blade root, metal tip only; the wrong size spoils the
///    head and the hand slips (short circuit / injury); a bent tip is checked
///    out; "Screwdriver = Chisel নয়";
///  * spanner: ring / double-ended of the right size; a wrong or loose spanner,
///    or a worn, widened mouth, spoils the nut and slips — worst on a pole;
///  * tester: says phase is there or not; first test it on a known live point
///    (the neon glows); not reliable on neutral / earth (a multimeter is
///    needed); LV only (~500V), not a measuring instrument.
/// The rival's myth is the lesson's first: gloves on, so non-insulated pliers
/// are fine. (The tester-on-neutral myth is the tester round's trap.)
const learnBoardPack21 = LearnBoardPack(
  lessonId: '2.1',
  titleBn: 'লাইনম্যানের টুলবক্স পরিচিতি',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'সঠিক হাতিয়ার জীবনও বাঁচায় — টুলবক্সের সদস্যদের চিনে নিন।',
  earnedBn: 'VDE 1000V টুল, সঠিক মাপ, সঠিক কাজ — আর গ্লাভস + VDE টুল, দুই স্তরই।',
  slots: [
    LearnBoardSlot(
      id: 'pliers',
      promptBn: 'LT লাইনের তারে কাজ — হাতে কোন প্লায়ার্স নেবেন?',
      options: [
        LearnBoardOption(id: 'vde', labelBn: 'অক্ষত VDE 1000V প্লায়ার্সে ধরা', asset: 'assets/game/art/m2_board21/pliers_vde.svg', scene: true, correct: true),
        LearnBoardOption(id: 'cut', labelBn: 'অক্ষত VDE প্লায়ার্সে তার কাটা', asset: 'assets/game/art/m2_board21/pliers_cut.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'নন-ইনসুলেটেড প্লায়ার্সে ধরা',
          asset: 'assets/game/art/m2_board21/pliers_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'Non-insulated Pliers LT Line-এ = বিপদ — সবসময় VDE 1000V Insulated Pliers।',
        ),
        LearnBoardOption(
          id: 'cracked',
          labelBn: 'ফাটা হ্যান্ডেলের প্লায়ার্স',
          asset: 'assets/game/art/m2_board21/pliers_cracked.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশন ফাটলে ব্যবহার নয় — রোজ হ্যান্ডেলে ফাটল বা কাট আছে কিনা দেখুন।',
        ),
        LearnBoardOption(
          id: 'burnt',
          labelBn: 'পোড়া দাগের প্লায়ার্স',
          asset: 'assets/game/art/m2_board21/pliers_burnt.svg',
          scene: true,
          correct: false,
          rejectBn: 'হ্যান্ডেলে পোড়া দাগ মানে ইনসুলেশনে ভরসা নেই — এমন প্লায়ার্স ব্যবহার নয়।',
        ),
        LearnBoardOption(
          id: 'hammer',
          labelBn: 'প্লায়ার্স দিয়ে বল্টুতে হাতুড়ি',
          asset: 'assets/game/art/m2_board21/pliers_hammer.svg',
          scene: true,
          correct: false,
          rejectBn: 'Right Tool for Right Job — Pliers = Hammer নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'LT লাইনে শুধু VDE 1000V ইনসুলেটেড প্লায়ার্স', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হ্যান্ডেলে ফাটল, কাট বা পোড়া দাগ থাকলে নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এক টুলেই ধরা, মোচড়ানো, কাটা আর ক্রিম্প', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্লাভস থাকলে যেকোনো প্লায়ার্সেই চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটু ফাটা হ্যান্ডেলে কিছু হয় না, চলবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হাতুড়ি না থাকলে প্লায়ার্স দিয়েই ঠোকা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সস্তা লোহার প্লায়ার্সও একই কাজ করে দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পোড়া দাগ শুধু দেখতে খারাপ, বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'তাড়া থাকলে হ্যান্ডেল দেখার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'strip',
      promptBn: 'তারের ইনসুলেশন ছাড়াবেন আর তার কাটবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'stripper', labelBn: 'VDE ওয়্যার স্ট্রিপারে ছাড়ানো', asset: 'assets/game/art/m2_board21/strip_stripper.svg', scene: true, correct: true),
        LearnBoardOption(id: 'cutter', labelBn: 'ধারালো VDE সাইড কাটারে কাটা', asset: 'assets/game/art/m2_board21/strip_cutter.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'knife',
          labelBn: 'ছুরি দিয়ে ইনসুলেশন চাঁছা',
          asset: 'assets/game/art/m2_board21/strip_knife.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছুরিতে Strip করলে Conductor-এ Nick — দুর্বল বিন্দু, Hot Spot আর ছিঁড়ার ঝুঁকি।',
        ),
        LearnBoardOption(
          id: 'pliers',
          labelBn: 'প্লায়ার্সে কামড়ে ইনসুলেশন ছেঁড়া',
          asset: 'assets/game/art/m2_board21/strip_pliers.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ Pliers দিয়ে Strip করলেও Nick পড়ে — Wire Stripper নির্দিষ্ট Size-এ ছাড়ায়।',
        ),
        LearnBoardOption(
          id: 'blunt',
          labelBn: 'ভোঁতা কাটারে তার থেঁতলানো',
          asset: 'assets/game/art/m2_board21/strip_blunt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভোঁতা Cutter ব্যবহার করবেন না — রোজ Cutter-এর ধার দেখে নিন।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি লোহার হাতলের স্ট্রিপার',
          asset: 'assets/game/art/m2_board21/strip_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'Wire Stripper আর Side Cutter — দুটোই VDE 1000V হতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্ট্রিপার নির্দিষ্ট মাপে ইনসুলেশন ছাড়ায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ছুরিতে তারে নিক পড়ে, সেখানে হট স্পট হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্ট্রিপার আর সাইড কাটার — দুটোই VDE 1000V', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছুরি দিয়ে চাঁছলে তাড়াতাড়ি কাজ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তারে একটু দাগ পড়লে কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভোঁতা কাটারে জোর দিলেই তার কেটে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দাঁত দিয়ে ইনসুলেশন ছাড়ানোই সবচেয়ে সোজা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্ট্রিপারের হাতল লোহার হলেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেকোনো প্লায়ার্সে ইনসুলেশন ছাড়ানো চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'screw',
      promptBn: 'টার্মিনালের স্ক্রু খুলবেন — কোন স্ক্রুড্রাইভার, কীভাবে?',
      options: [
        LearnBoardOption(id: 'flat', labelBn: 'খাঁজের মাপে VDE ফ্ল্যাট (-) টিপ', asset: 'assets/game/art/m2_board21/screw_flat.svg', scene: true, correct: true),
        LearnBoardOption(id: 'phillips', labelBn: 'ক্রস স্ক্রুতে VDE ফিলিপস (+) টিপ', asset: 'assets/game/art/m2_board21/screw_phillips.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'small',
          labelBn: 'বড় খাঁজে ছোট টিপ',
          asset: 'assets/game/art/m2_board21/screw_small.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল Size = Screw Head নষ্ট + Hand Slip — Short Circuit বা আঘাত।',
        ),
        LearnBoardOption(
          id: 'wrong',
          labelBn: 'ক্রস স্ক্রুতে ফ্ল্যাট টিপ',
          asset: 'assets/game/art/m2_board21/screw_wrong.svg',
          scene: true,
          correct: false,
          rejectBn: 'Phillips (+) স্ক্রুতে Flat (-) টিপ মানে ভুল টুল — Head নষ্ট, হাত পিছলায়।',
        ),
        LearnBoardOption(
          id: 'chisel',
          labelBn: 'স্ক্রুড্রাইভারে হাতুড়ির ঘা',
          asset: 'assets/game/art/m2_board21/screw_chisel.svg',
          scene: true,
          correct: false,
          rejectBn: 'Right Tool for Right Job — Screwdriver = Chisel নয়।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খোলা লোহার শ্যাফটের স্ক্রুড্রাইভার',
          asset: 'assets/game/art/m2_board21/screw_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'Handle থেকে Blade-এর গোড়া পর্যন্ত VDE 1000V Insulated — খোলা শুধু Metal Tip।',
        ),
        LearnBoardOption(
          id: 'bent',
          labelBn: 'বাঁকা টিপের স্ক্রুড্রাইভার',
          asset: 'assets/game/art/m2_board21/screw_bent.svg',
          scene: true,
          correct: false,
          rejectBn: 'রোজ দেখুন Tip বেঁকে বা ভেঙে গেছে কিনা — বাঁকা টিপ পিছলে যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভুল মাপে স্ক্রু নষ্ট হয়, হাত পিছলে শর্ট হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হাতল থেকে ব্লেডের গোড়া পর্যন্ত ইনসুলেটেড', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্ক্রুর মাপ আর খাঁজ মিলিয়ে টিপ বেছে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো টিপ জোরে চাপলেই স্ক্রু খুলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শক্ত স্ক্রুতে হাতুড়ি মারলে ঝামেলা কমে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শুধু হাতলটা ইনসুলেটেড হলেই যথেষ্ট হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাঁকা টিপও একটু ঘুরিয়ে ধরলে কাজ চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফ্ল্যাট টিপ দিয়েই সব রকম স্ক্রু খোলা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ছোট টিপ সব খাঁজেই ঢোকে, তাই সেটাই ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'spanner',
      promptBn: 'পোলের ক্রস-আর্মে নাট টাইট দেবেন — কোন স্প্যানার?',
      options: [
        LearnBoardOption(id: 'ring', labelBn: 'নাটের মাপের রিং স্প্যানার', asset: 'assets/game/art/m2_board21/spanner_ring.svg', scene: true, correct: true),
        LearnBoardOption(id: 'de', labelBn: 'নাটের মাপের DE স্প্যানার', asset: 'assets/game/art/m2_board21/spanner_de.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'বড় মাপের ঢিলা স্প্যানার',
          asset: 'assets/game/art/m2_board21/spanner_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল বা ঢিলা Spanner = Nut Head নষ্ট + Slip — Pole-এ বিশেষ বিপজ্জনক।',
        ),
        LearnBoardOption(
          id: 'worn',
          labelBn: 'ক্ষয়ে চওড়া মুখের স্প্যানার',
          asset: 'assets/game/art/m2_board21/spanner_worn.svg',
          scene: true,
          correct: false,
          rejectBn: 'Spanner-এর মুখ ক্ষয়ে চওড়া হলে নাট ধরে না, পিছলায় — রোজ মুখ পরীক্ষা করুন।',
        ),
        LearnBoardOption(
          id: 'pliers',
          labelBn: 'প্লায়ার্সে নাট ঘোরানো',
          asset: 'assets/game/art/m2_board21/spanner_pliers.svg',
          scene: true,
          correct: false,
          rejectBn: 'Right Tool for Right Job — নাট-বল্টুর জন্য সঠিক Size-এর Spanner, Pliers নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঢিলা স্প্যানার পিছলায়, নাটের মাথা নষ্ট হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পোলের ওপরে স্প্যানার পিছলানো বেশি বিপদের', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নাটের ঠিক মাপের রিং বা DE স্প্যানার নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটা বড় স্প্যানারেই সব মাপের নাট চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ক্ষয়ে যাওয়া মুখে আরও ভালো গ্রিপ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্লায়ার্সে চেপে ধরলেই নাট ঘুরে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নাটের মাথা গোল হয়ে গেলেও টাইট ঠিকই হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পোলে উঠে মাপ মেলানোর সময় কোথায় থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঢিলা স্প্যানারে জোর দিলেই কাজ হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tester',
      promptBn: 'লাইন টেস্টার হাতে — কোন ব্যবহারটা ঠিক?',
      options: [
        LearnBoardOption(id: 'known', labelBn: 'আগে জানা লাইভ পয়েন্টে টেস্টার যাচাই', asset: 'assets/game/art/m2_board21/tester_known.svg', scene: true, correct: true),
        LearnBoardOption(id: 'phase', labelBn: 'ফেজ টার্মিনালে লাইভ আছে কিনা দেখা', asset: 'assets/game/art/m2_board21/tester_phase.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'নিউট্রালে টেস্টার ছুঁইয়ে নিশ্চিন্ত',
          asset: 'assets/game/art/m2_board21/tester_neutral.svg',
          scene: true,
          correct: false,
          rejectBn: 'Line Tester Phase Indicator — Neutral-এ Reliable নয়, Multimeter দিয়ে পরীক্ষা করুন।',
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'আর্থ তারে টেস্টারে চেক',
          asset: 'assets/game/art/m2_board21/tester_earth.svg',
          scene: true,
          correct: false,
          rejectBn: 'Earth Check-এর জন্য Line Tester-এ নির্ভর করা যায় না — Multimeter লাগবে।',
        ),
        LearnBoardOption(
          id: 'ht',
          labelBn: 'HT লাইনে টেস্টার ঠেকানো',
          asset: 'assets/game/art/m2_board21/tester_ht.svg',
          scene: true,
          correct: false,
          rejectBn: 'Line Tester শুধু LV (~500V)-এর জন্য — HT লাইনে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টেস্টার শুধু বলে ফেজে লাইভ আছে কি নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জানা লাইভ পয়েন্টে আগে নিয়ন জ্বলে কি?', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিউট্রাল-আর্থে চাই মাল্টিমিটার', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টেস্টার দিয়ে ভোল্টেজও মাপা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নিউট্রালে আলো না জ্বললে লাইন নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো ভোল্টেজের লাইনে টেস্টার চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন টেস্টার আগে যাচাইয়ের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আর্থ তারে টেস্টারই যথেষ্ট পরীক্ষা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'টেস্টার না জ্বললে মানে কারেন্ট নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: ToolboxBoardLines.rivalTaunt,
    rivalLineBn: ToolboxBoardLines.rivalMyth,
    exitBn: ToolboxBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'নন-ইনসুলেটেড প্লায়ার্সে লাইনে কাজ',
      'শুধু গ্লাভসের ভরসা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'গ্লাভস বা টুল — যেকোনো একটা ফেল হলেই শক', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'দুই স্তরই সম্মান করুন: গ্লাভস + VDE টুল', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'নন-ইনসুলেটেড প্লায়ার্স LT লাইনে বিপদ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'গ্লাভস পরা থাকলে কোনো টুলেই শক লাগে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'গ্লাভস কখনো ফেল করে না, তাই টুল যেমন খুশি', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'VDE টুল শুধু দামি, কাজে কোনো তফাত নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'সস্তা লোহার প্লায়ার্সে টাকা বাঁচে, ঝুঁকি নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'গ্লাভস থাকলে প্লায়ার্সের হাতল দেখার দরকার নেই', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. [rivalExit] is already
/// recorded (`learnRivalVoice`); the taunt and the myth are new and play
/// through device TTS until they are recorded ([toRecord]).
abstract final class ToolboxBoardLines {
  static const rivalTaunt = 'আরে! হাতে গ্লাভস আছে তো, এত দামি টুলের কী দরকার?';

  /// Lesson 2.1's first myth buster, word for word.
  static const rivalMyth = 'আমার হাতে গ্লাভস পরা আছে, তাই নন-ইনসুলেটেড প্লায়ার্স ব্যবহার করলেও কিছু হবে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New clips this board needs recorded in the rival's voice.
  static const toRecord = [rivalTaunt, rivalMyth];
}
