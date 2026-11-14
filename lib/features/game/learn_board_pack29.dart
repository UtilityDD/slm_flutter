import 'learn_board_models.dart';

/// Module 2 Lesson 2.9 (হাইড্রোলিক ক্রিম্পার ও কাটার: দানবীয় শক্তি), the
/// picture board (rung `2.9/learn`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m2_board29_art.py`. Every round
/// and every trap comes from the lesson text:
///  * check: before use, look at the body for an oil leak, the pumping action
///    must be smooth; a battery tool's battery must be charged (pro tip 3);
///    a weak or leaking tool lets you down in the field;
///  * die: the die selection chart says which die for which cable — a pro
///    never guesses (pro tip 1); every die is made for one pressure and shape;
///  * crimp: no finger or body part between the die and the lug (a serious
///    injury in a moment); seat the die on the right place of the lug; pump
///    to full pressure until the pressure release valve clicks open; a big
///    crimp is impossible with a plain hand tool;
///  * cut: the cable steady; think first where the two cut parts will fall,
///    so not on your feet; safety lock closed, then pump; a hacksaw is slow
///    and leaves an uneven cut, bad for the joint;
///  * care: top up with the maker's approved oil only — water or another oil
///    damages the seals; dies and blades clean and lightly oiled (no rust);
///    an oil leak means damaged seals — send it for servicing at once.
/// Not drawn: Pascal's law and shear strength (engineering facts, no act),
/// and the posture tip (no clear right/wrong picture).
/// The rival's myth is the lesson's first: "হাইড্রোলিক টুলের ডাই হারিয়ে গেলে,
/// কাছাকাছি সাইজের অন্য কোনো ডাই দিয়ে কাজ চালিয়ে নেওয়া যায়।" (The second
/// myth — water or other oil — is a trap of the care round.)
const learnBoardPack29 = LearnBoardPack(
  lessonId: '2.9',
  titleBn: 'হাইড্রোলিক ক্রিম্পার ও কাটার',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'তরলের চাপে নিখুঁত চাপ ও শক্তি — বুঝুন, সম্মান করুন, নিরাপদে কাজে লাগান।',
  earnedBn: 'চার্ট দেখে ডাই, ভাল্ভ ক্লিক পর্যন্ত চাপ, আঙুল দূরে — নিখুঁত চাপ ও শক্তি এবার আপনার বশে।',
  slots: [
    LearnBoardSlot(
      id: 'check',
      promptBn: 'বড় কাজে বেরোনোর আগে হাইড্রোলিক টুল — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'look', labelBn: 'বডিতে তেল লিক খুঁজে দেখা', asset: 'assets/game/art/m2_board29/check_look.svg', scene: true, correct: true),
        LearnBoardOption(id: 'battery', labelBn: 'ব্যাটারি চার্জড কিনা দেখা', asset: 'assets/game/art/m2_board29/check_battery.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'drip',
          labelBn: 'তেল চোঁয়ানো টুল নিয়েই রওনা',
          asset: 'assets/game/art/m2_board29/check_drip.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে বডিতে তেল লিক দেখুন — লিক করা টুল মাঠে আপনাকে হতাশ করবে।',
        ),
        LearnBoardOption(
          id: 'flat',
          labelBn: 'ব্যাটারি না দেখেই টুল ব্যাগে',
          asset: 'assets/game/art/m2_board29/check_flat.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যাটারি চালিত টুলে আগে দেখে নিন ব্যাটারি চার্জড আছে কিনা।',
        ),
        LearnBoardOption(
          id: 'stiff',
          labelBn: 'আটকে যাওয়া পাম্প জোরে চালানো',
          asset: 'assets/game/art/m2_board29/check_stiff.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে নিশ্চিত করুন পাম্পিং অ্যাকশন মসৃণ — আটকালে সে টুলে কাজ নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ব্যবহারের আগে টুলটা একবার পরীক্ষা করে নিই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দুর্বল বা লিক করা টুল মাঠে হতাশ করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বড় কাজের আগে টুল তৈরি কিনা দেখা দরকার', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটু তেল চুঁইয়ে পড়লে টুলের কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পাম্প আটকালে জোরে চাপলেই ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ব্যাটারির চার্জ মাঠে গিয়ে দেখলেই চলবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দামী টুল কখনো খারাপ হয় না, দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পরীক্ষা করতে গেলে কাজে দেরি হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'die',
      promptBn: 'মোটা কেবিলে ল্যাগ ক্রিম্প করবেন — ডাই কীভাবে বাছবেন?',
      options: [
        LearnBoardOption(id: 'chart', labelBn: 'ডাই সিলেকশন চার্ট দেখে বাছা', asset: 'assets/game/art/m2_board29/die_chart.svg', scene: true, correct: true),
        LearnBoardOption(id: 'match', labelBn: 'ল্যাগের মাপে মেলানো ডাই বসানো', asset: 'assets/game/art/m2_board29/die_match.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'guess',
          labelBn: 'আন্দাজে একটা ডাই তুলে নেওয়া',
          asset: 'assets/game/art/m2_board29/die_guess.svg',
          scene: true,
          correct: false,
          rejectBn: 'পেশাদাররা অনুমানে চলেন না — চার্ট বলে দেয় কোন কেবিলে কোন ডাই।',
        ),
        LearnBoardOption(
          id: 'big',
          labelBn: 'ঢিলে, বড় মাপের ডাই বসানো',
          asset: 'assets/game/art/m2_board29/die_big.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি ডাই নির্দিষ্ট মাপের জন্য — ভুল ডাইয়ে দুর্বল, বিপজ্জনক ক্রিম্প।',
        ),
        LearnBoardOption(
          id: 'small',
          labelBn: 'ছোট মাপের ডাইয়ে চেপে বসানো',
          asset: 'assets/game/art/m2_board29/die_small.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি ডাই নির্দিষ্ট চাপ আর আকৃতির জন্য তৈরি — ছোট ডাইয়ে ক্রিম্প নষ্ট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'চার্ট বলে দেয় কোন কেবিলে কোন সাইজের ডাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্রতিটি ডাই একটি নির্দিষ্ট মাপের জন্য তৈরি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পেশাদাররা ডাই বাছতে অনুমানে নির্ভর করেন না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কাছাকাছি সাইজের ডাই হলেই কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চোখের আন্দাজই চার্টের চেয়ে বেশি ভরসার', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বড় ডাইয়ে বেশি চাপ দিলেই ক্রিম্প মজবুত', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছোট ডাইয়ে চাপলে ল্যাগ আরও শক্ত করে বসে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যেকোনো ডাই দিলেই হাইড্রোলিক চাপ সামলে নেয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'crimp',
      promptBn: 'ডাই বসানো হয়েছে, এবার পাম্প করে ক্রিম্প — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'click', labelBn: 'ভাল্ভ ক্লিক না করা পর্যন্ত পাম্প', asset: 'assets/game/art/m2_board29/crimp_click.svg', scene: true, correct: true),
        LearnBoardOption(id: 'clear', labelBn: 'দুই হাত হ্যান্ডেলে, ডাই থেকে দূরে', asset: 'assets/game/art/m2_board29/crimp_clear.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'finger',
          labelBn: 'ডাই আর ল্যাগের মাঝে আঙুল',
          asset: 'assets/game/art/m2_board29/crimp_finger.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাই আর ল্যাগের মাঝে আঙুল বা শরীরের অংশ — মুহূর্তে মারাত্মক আঘাত।',
        ),
        LearnBoardOption(
          id: 'half',
          labelBn: 'অর্ধেক চাপ দিয়েই থেমে যাওয়া',
          asset: 'assets/game/art/m2_board29/crimp_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'সম্পূর্ণ চাপ দিন, যতক্ষণ না প্রেসার রিলিজ ভাল্ভ নিজে থেকে খুলে যায়।',
        ),
        LearnBoardOption(
          id: 'offset',
          labelBn: 'ল্যাগের ভুল জায়গায় ডাই বসানো',
          asset: 'assets/game/art/m2_board29/crimp_offset.svg',
          scene: true,
          correct: false,
          rejectBn: 'ল্যাগের ওপর ডাই সঠিক জায়গায় বসিয়ে তবেই পাম্প — নইলে ক্রিম্প নিখুঁত হয় না।',
        ),
        LearnBoardOption(
          id: 'plier',
          labelBn: 'মোটা ল্যাগে সাধারণ হ্যান্ড টুল',
          asset: 'assets/game/art/m2_board29/crimp_plier.svg',
          scene: true,
          correct: false,
          rejectBn: 'মোটা কেবিলে নিখুঁত ক্রিম্প সাধারণ হ্যান্ড টুলে অসম্ভব — চাই হাইড্রোলিক চাপ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভাল্ভের ক্লিক মানে সঠিক পরিমাণ চাপ পড়েছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডাই আর ল্যাগের মাঝে আঙুল মারাত্মক আঘাত করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিখুঁত কোল্ড-ওয়েল্ডে হটস্পটের ভয় থাকে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অর্ধেক চাপেই ল্যাগ যথেষ্ট শক্ত হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আঙুলে ল্যাগ ধরে রাখলে ক্রিম্প সোজা হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ল্যাগের যেখানে খুশি ডাই বসালেই চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জোর থাকলে হ্যান্ড টুলেই মোটা ল্যাগ বসে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভাল্ভের ক্লিক শুনে থামার কোনো দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'cut',
      promptBn: 'আর্মার্ড কেবিল কাটবেন হাইড্রোলিক কাটারে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'steady', labelBn: 'কেবিল স্থির, পা কাটা প্রান্ত থেকে দূরে', asset: 'assets/game/art/m2_board29/cut_steady.svg', scene: true, correct: true),
        LearnBoardOption(id: 'lock', labelBn: 'সেফটি লক বন্ধ করে তবে পাম্প', asset: 'assets/game/art/m2_board29/cut_lock.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'foot',
          labelBn: 'কাটা প্রান্তের ঠিক নিচে পা',
          asset: 'assets/game/art/m2_board29/cut_foot.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাটার পর কেবিলের দুই অংশ কোথায় পড়বে আগে ভাবুন — যেন পায়ের ওপর না পড়ে।',
        ),
        LearnBoardOption(
          id: 'swing',
          labelBn: 'ঝুলন্ত, দুলন্ত কেবিলে কাটার',
          asset: 'assets/game/art/m2_board29/cut_swing.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাটার সময় নিশ্চিত করুন কেবিলটি স্থির আছে — দুলন্ত কেবিলে কাটা নয়।',
        ),
        LearnBoardOption(
          id: 'saw',
          labelBn: 'হ্যাকস দিয়ে মোটা কেবিল কাটা',
          asset: 'assets/game/art/m2_board29/cut_saw.svg',
          scene: true,
          correct: false,
          rejectBn: 'হ্যাকসে মোটা কেবিলে সময়-পরিশ্রম বেশি, কাট অমসৃণ — জয়েন্টের জন্য খারাপ।',
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'সেফটি লক খোলা রেখেই পাম্প',
          asset: 'assets/game/art/m2_board29/cut_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেবিল ব্লেডের মধ্যে ঠিকভাবে রেখে, সেফটি লক বন্ধ করে তবেই পাম্প।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাটা অংশ কোথায় পড়বে, আগে থেকে ভাবি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কেবিল স্থির আর লক বন্ধ — তবেই পাম্প', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাটা প্রান্ত যেন পায়ের ওপর না পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কেবিল দুললে ব্লেড আরও সহজে কাটে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সেফটি লক খোলা থাকলে কাট দ্রুত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সেফটি বুট পরা থাকলে পায়ে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হ্যাকসের কাটই জয়েন্টের জন্য সেরা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাটা অংশ কোথায় পড়ে, ভেবে লাভ নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'care',
      promptBn: 'বড় কাজ শেষ, এবার টুলের যত্ন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'oil', labelBn: 'অনুমোদিত তেলে লেভেল টপ-আপ', asset: 'assets/game/art/m2_board29/care_oil.svg', scene: true, correct: true),
        LearnBoardOption(id: 'wipe', labelBn: 'ডাই মুছে সামান্য তেল দেওয়া', asset: 'assets/game/art/m2_board29/care_wipe.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'water',
          labelBn: 'তেল কম, তাই একটু জল ঢালা',
          asset: 'assets/game/art/m2_board29/care_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'জল হাইড্রোলিক সিস্টেমের ভেতরের সিল নষ্ট করে, কার্যকারিতা কমায়।',
        ),
        LearnBoardOption(
          id: 'any_oil',
          labelBn: 'হাতের কাছের অন্য তেল ঢালা',
          asset: 'assets/game/art/m2_board29/care_any_oil.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল তেল ভেতরের সিল নষ্ট করে — সবসময় প্রস্তুতকারকের অনুমোদিত তেল।',
        ),
        LearnBoardOption(
          id: 'tape',
          labelBn: 'লিকে টেপ জড়িয়ে চালানো',
          asset: 'assets/game/art/m2_board29/care_tape.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল লিক মানে ভেতরের রাবার সিল ক্ষতিগ্রস্ত — অবিলম্বে সার্ভিসিং-এ পাঠান।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'ভেজা, নোংরা ডাই ফেলে রাখা',
          asset: 'assets/game/art/m2_board29/care_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাই আর ব্লেড পরিষ্কার রেখে সামান্য তেল দিন — নইলে মরিচা ধরে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'যত্নে দামী টুলের আয়ু বাড়ে, ভরসা থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অনুমোদিত তেল, পরিষ্কার ডাই — টুল তৈরি থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিয়মিত তেল আর ডাইয়ের যত্নই টুলের শক্তি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হাইড্রোলিক তেলে একটু জল মিশলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো তেলেই হাইড্রোলিক টুল চলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টেপ জড়ালে লিক বন্ধ, সার্ভিসিং লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্টিলের ডাইয়ে কখনোই মরিচা ধরতে পারে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাজ শেষে টুল মোছা শুধুই সময়ের অপচয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: HydraulicBoardLines.rivalTaunt,
    rivalLineBn: HydraulicBoardLines.rivalMyth,
    exitBn: HydraulicBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'কাছাকাছি সাইজের ডাইয়ে ক্রিম্প',
      'দুর্বল ক্রিম্পে পুরো সিস্টেম ঝুঁকিতে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'প্রতিটি ডাই নির্দিষ্ট চাপ আর আকৃতির জন্য', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ভুল ডাইয়ে ক্রিম্প দুর্বল আর বিপজ্জনক হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'দুর্বল ক্রিম্প পুরো সিস্টেমের জন্য ঝুঁকি', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কাছাকাছি সাইজ হলেই ক্রিম্প ঠিক বসে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'হাইড্রোলিক চাপ ডাইয়ের ভুল ঢেকে দেয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ডাই হারালে চালিয়ে নেওয়াই আসল দক্ষতা', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ডাইয়ের চার্ট দেখা শুধু নতুন লোকের কাজ', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'একটু ঢিলে ক্রিম্পে কোনো ক্ষতি হয় না', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. The exit is already recorded
/// in his voice (`learnRivalVoice`); the taunt and the myth are new and go
/// through device TTS until the owner records them.
abstract final class HydraulicBoardLines {
  static const rivalTaunt = 'আরে! ডাই খুঁজতে খুঁজতে তো বেলা গড়িয়ে যাবে!';

  /// Lesson 2.9's first myth buster, word for word.
  static const rivalMyth = 'হাইড্রোলিক টুলের ডাই হারিয়ে গেলে, কাছাকাছি সাইজের অন্য কোনো ডাই দিয়ে কাজ চালিয়ে নেওয়া যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New lines to record in the rival's voice.
  static const toRecord = [rivalTaunt, rivalMyth];
}
