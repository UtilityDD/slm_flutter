import 'learn_board_models.dart';

/// Module 3 Lesson 3.1 (কন্ডাক্টর পরিচিতি: ACSR, AAAC), the picture board
/// (rung `3.1/learn`, pack `learn_3_1`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board31_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * magnet: ACSR has a galvanised steel core — a magnet sticks to it; AAAC
///    is all alloy — a magnet does not; never pick by guesswork;
///  * coast: in salt air or factory smoke ACSR's steel rusts, so AAAC (no
///    steel) goes up there; copper is too heavy — light aluminium puts less
///    load on the poles and allows longer spans;
///  * sleeve: ACSR and AAAC joint sleeves are different — match the code on
///    the sleeve to the conductor's code, ask a senior when unsure; a wrong
///    sleeve makes a hotspot and the line falls; no forcing one into the other;
///  * strip: not one strand may be cut (the line weakens and later snaps
///    there); no ordinary cutter on ACSR (hard steel inside); no rust on the
///    steel core at a joint; AAAC is slippery — the clamp must not slip;
///  * old: sun and rain may have spoilt an old line's temper — inspect it
///    before a new pull; tension by the sag chart (too tight snaps in winter).
///    The line is drawn earthed (house rule, not put into words here).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack31 = LearnBoardPack(
  lessonId: '3.1',
  titleBn: 'কন্ডাক্টর পরিচিতি: ACSR, AAAC',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'কন্ডাক্টর হলো বিদ্যুতের হাইওয়ে। ACSR না AAAC — আন্দাজে নয়, চিনে নিয়ে কাজ।',
  earnedBn: 'চুম্বক আটকালে ACSR, না আটকালে AAAC — স্লিভের কোড মিলিয়ে জয়েন্ট।',
  slots: [
    LearnBoardSlot(
      id: 'magnet',
      promptBn: 'স্টোরে কন্ডাক্টরের নমুনা — কী দেখে নিশ্চিত হবেন এটা ACSR?',
      options: [
        LearnBoardOption(
          id: 'stick',
          labelBn: 'চুম্বক ধরতেই তারে আটকে গেল',
          asset: 'assets/game/art/m3_board31/magnet_stick.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'core',
          labelBn: 'কাটা মুখে ভেতরের স্টিলের কোর',
          asset: 'assets/game/art/m3_board31/magnet_core.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nostick',
          labelBn: 'চুম্বক আটকাল না, তবু ACSR ধরা',
          asset: 'assets/game/art/m3_board31/magnet_nostick.svg',
          scene: true,
          correct: false,
          rejectBn: 'চুম্বক না আটকালে ওটা AAAC — এতে কোনো স্টিল নেই। ACSR-এর স্টিল কোরে চুম্বক আটকে যায়।',
        ),
        LearnBoardOption(
          id: 'thick',
          labelBn: 'মোটা দেখে ACSR বলে ধরে নেওয়া',
          asset: 'assets/game/art/m3_board31/magnet_thick.svg',
          scene: true,
          correct: false,
          rejectBn: 'মোটা-সরু দেখে চেনা যায় না — চুম্বক ধরুন: ACSR আটকাবে, AAAC আটকাবে না।',
        ),
        LearnBoardOption(
          id: 'shine',
          labelBn: 'চকচকে দেখে আন্দাজে বেছে নেওয়া',
          asset: 'assets/game/art/m3_board31/magnet_shine.svg',
          scene: true,
          correct: false,
          rejectBn: 'আন্দাজে ঢিল নয় — চুম্বক সাথে রাখুন, কনফিউশন হলে সিনিয়রকে জিজ্ঞেস করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ACSR-এর ভেতরে স্টিল, চুম্বক আটকে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'AAAC পুরোটা অ্যালয়, এতে চুম্বক আটকায় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আন্দাজে নয়, চুম্বক ধরে তারটা চিনে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মোটা তার দেখলেই বুঝবেন ওটাই ACSR', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চকচকে তার মানেই ভেতরে স্টিলের কোর', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চুম্বক না আটকালেও ওটা ACSR হতে পারে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সব তার এক, চিনে নেওয়ার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'AAAC-তেই স্টিল থাকে, তাই চুম্বক আটকায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কনফিউশন হলে আন্দাজেই একটা তুলে নিন', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'coast',
      promptBn: 'নোনা হাওয়া বা কারখানার ধোঁয়ার এলাকায় নতুন লাইন — কোন কন্ডাক্টর?',
      options: [
        LearnBoardOption(
          id: 'sea',
          labelBn: 'উপকূলে AAAC তার টানা',
          asset: 'assets/game/art/m3_board31/coast_sea.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'smoke',
          labelBn: 'কারখানার পাশে AAAC তার টানা',
          asset: 'assets/game/art/m3_board31/coast_smoke.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'acsr',
          labelBn: 'উপকূলে ACSR তার টানা',
          asset: 'assets/game/art/m3_board31/coast_acsr.svg',
          scene: true,
          correct: false,
          rejectBn: 'নোনা হাওয়ায় ACSR-এর ভেতরের স্টিলে জং ধরে — উপকূলে AAAC চলে, এতে স্টিল নেই।',
        ),
        LearnBoardOption(
          id: 'rusty',
          labelBn: 'ধোঁয়ার পাশে ACSR তার টানা',
          asset: 'assets/game/art/m3_board31/coast_rusty.svg',
          scene: true,
          correct: false,
          rejectBn: 'কারখানার ধোঁয়াতেও ACSR-এর স্টিল কোরে জং ধরে — সেখানে জং-না-ধরা AAAC।',
        ),
        LearnBoardOption(
          id: 'copper',
          labelBn: 'ভারী তামার তার টানা',
          asset: 'assets/game/art/m3_board31/coast_copper.svg',
          scene: true,
          correct: false,
          rejectBn: 'তামা বড্ড ভারী — পোলের ওপর চাপ পড়ে। হালকা অ্যালুমিনিয়ামে স্প্যান বাড়ানো যায়, খরচও কম।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নোনা হাওয়ায় ACSR-এর স্টিলে জং ধরে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'AAAC-তে কোনো স্টিল নেই, তাই জং ধরে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অ্যালুমিনিয়াম হালকা, পোলে চাপ কম পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'উপকূলে ACSR-ই সবচেয়ে বেশি টেকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ধোঁয়ায় স্টিল কোরের কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভারী তামায় পোলের ওপর চাপ কম পড়ে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'AAAC-এর ভেতরের স্টিলেই জং ধরে বেশি', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জায়গা যা-ই হোক, যেকোনো তার চলে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'তামার তারে স্প্যান সবচেয়ে বেশি বাড়ে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sleeve',
      promptBn: 'AAAC লাইনের দুটো তার জুড়বেন — জয়েন্ট স্লিভ নিয়ে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'match',
          labelBn: 'স্লিভের কোড আর তারের কোড মেলানো',
          asset: 'assets/game/art/m3_board31/sleeve_match.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ask',
          labelBn: 'কনফিউশনে সিনিয়রকে স্লিভ দেখানো',
          asset: 'assets/game/art/m3_board31/sleeve_ask.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'force',
          labelBn: 'হাতুড়ি মেরে অন্য স্লিভ ঢোকানো',
          asset: 'assets/game/art/m3_board31/sleeve_force.svg',
          scene: true,
          correct: false,
          rejectBn: 'ACSR আর AAAC-এর জয়েন্ট স্লিভ আলাদা — গায়ের জোরে একটার মাল অন্যটায় ঢোকাবেন না।',
        ),
        LearnBoardOption(
          id: 'any',
          labelBn: 'বাক্স থেকে না দেখে স্লিভ তোলা',
          asset: 'assets/game/art/m3_board31/sleeve_any.svg',
          scene: true,
          correct: false,
          rejectBn: 'আন্দাজে ঢিল নয় — স্লিভের গায়ে লেখা কোড আর কন্ডাক্টরের কোড মিলিয়ে কাজ।',
        ),
        LearnBoardOption(
          id: 'hot',
          labelBn: 'ACSR স্লিভেই AAAC জুড়ে দেওয়া',
          asset: 'assets/game/art/m3_board31/sleeve_hot.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল স্লিভে জয়েন্ট ঢিলে হয়ে হটস্পট তৈরি হয় — ক\'দিন বাদেই লাইন কেটে মাটিতে পড়ে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ACSR আর AAAC-এর জয়েন্ট স্লিভ আলাদা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্লিভের কোড আর তারের কোড মিলিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল স্লিভে হটস্পট হয়, লাইন ছিঁড়ে পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সব অ্যালুমিনিয়াম, যেকোনো স্লিভেই চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জোরে চাপ দিলে যেকোনো স্লিভ বসে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্লিভের গায়ের কোড দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সিনিয়রকে জিজ্ঞেস করা মানে সময় নষ্ট', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভুল স্লিভে জয়েন্ট বরং আরও শক্ত হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঢিলে জয়েন্ট গরম হয় না, ভয় নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'strip',
      promptBn: 'জয়েন্টের আগে কন্ডাক্টরের মুখ তৈরি করছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'intact',
          labelBn: 'একটা স্ট্র্যান্ডও না কেটে ছোলা',
          asset: 'assets/game/art/m3_board31/strip_intact.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clean',
          labelBn: 'স্টিল কোরে জং আছে কি না দেখা',
          asset: 'assets/game/art/m3_board31/strip_clean.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nick',
          labelBn: 'ছোলার সময় একটা স্ট্র্যান্ড কাটা',
          asset: 'assets/game/art/m3_board31/strip_nick.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা স্ট্র্যান্ড কাটা মানে লাইনের শক্তি কমে যাওয়া — ওখান থেকেই পরে তার ছিঁড়বে।',
        ),
        LearnBoardOption(
          id: 'cutter',
          labelBn: 'সাধারণ কাটারে ACSR কাটা',
          asset: 'assets/game/art/m3_board31/strip_cutter.svg',
          scene: true,
          correct: false,
          rejectBn: 'ACSR-এর ভেতরে শক্ত স্টিল আছে — সাধারণ কাটার দিয়ে কাটতে যাবেন না।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'জং-ধরা স্টিল কোরেই জয়েন্ট',
          asset: 'assets/game/art/m3_board31/strip_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'জয়েন্ট করার সময় দেখুন ভেতরের স্টিলে যেন জং বা রাস্ট না থাকে।',
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'AAAC ক্ল্যাম্পে পিছলে যাচ্ছে',
          asset: 'assets/game/art/m3_board31/strip_slip.svg',
          scene: true,
          correct: false,
          rejectBn: 'AAAC খুব স্লিপারি — ক্ল্যাম্প লাগানোর সময় খেয়াল রাখুন যেন স্লিপ না কাটে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একটা স্ট্র্যান্ড কাটলেও লাইনের শক্তি কমে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জয়েন্টের আগে স্টিল কোরে জং দেখে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'AAAC স্লিপারি, ক্ল্যাম্প যেন পিছলে না যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটা-দুটো স্ট্র্যান্ড কাটলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সাধারণ কাটারেই ACSR সহজে কেটে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটু জং থাকলে জয়েন্ট আরও ভালো ধরে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'AAAC খসখসে, ক্ল্যাম্পে কখনো পিছলায় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাটা স্ট্র্যান্ড টানে আবার জুড়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'স্টিল কোর দেখার কোনো দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'old',
      promptBn: 'রোদ-বৃষ্টিতে পোড়া পুরনো লাইনে নতুন করে টান দেবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'inspect',
          labelBn: 'টানের আগে তার খুঁটিয়ে দেখা',
          asset: 'assets/game/art/m3_board31/old_inspect.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'chart',
          labelBn: 'স্যাগ চার্ট দেখে টান ঠিক করা',
          asset: 'assets/game/art/m3_board31/old_chart.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'yank',
          labelBn: 'পুরনো তারে হঠাৎ জোরে টান',
          asset: 'assets/game/art/m3_board31/old_yank.svg',
          scene: true,
          correct: false,
          rejectBn: 'রোদে পুড়ে পুরনো তারের টেম্পার নষ্ট হতে পারে — হঠাৎ টান নয়, আগে খুঁটিয়ে দেখুন।',
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'স্যাগ না রেখে টানটান করা',
          asset: 'assets/game/art/m3_board31/old_tight.svg',
          scene: true,
          correct: false,
          rejectBn: 'শীতে তার টানটান হয় — স্যাগ চার্ট দেখেই টান দিন, নইলে শীতে তার ছিঁড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'frayed',
          labelBn: 'ছেঁড়া স্ট্র্যান্ড দেখেও টান দেওয়া',
          asset: 'assets/game/art/m3_board31/old_frayed.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্ট্র্যান্ড কাটা মানেই শক্তি কম — মরা লাইনকে অবহেলা নয়, ওখান থেকেই তার ছিঁড়বে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রোদ-বৃষ্টিতে পুরনো তারের টেম্পার যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্যাগ চার্ট দেখে টান, নইলে শীতে ছিঁড়বে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নতুন টানের আগে পুরনো তার খুঁটিয়ে দেখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পুরনো তার আরও পোক্ত, যত খুশি টানুন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যত টানটান তার, শীতে ততই নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গরমে-শীতে তারের ঝুল একই রকম থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছেঁড়া স্ট্র্যান্ড টানে নিজেই বসে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মরা লাইনে খুঁটিয়ে দেখার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হঠাৎ জোরে টানলে কাজ তাড়াতাড়ি হয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board31Lines.rivalTaunt,
    rivalLineBn: M3Board31Lines.rivalMyth,
    exitBn: M3Board31Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'যেকোনো কানেক্টরে জয়েন্ট',
      'ভুল হার্ডওয়্যারে তার পচে যাওয়া',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ACSR আর AAAC-এর ব্যাস আর চরিত্র আলাদা', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ভুল হার্ডওয়্যারে গ্যালভানিক করোসন, তার পচে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'স্লিভের কোড আর তারের কোড মিলিয়ে জয়েন্ট', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'সব অ্যালুমিনিয়াম, তাই যেকোনো কানেক্টর চলে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ACSR আর AAAC-এর ব্যাস হুবহু এক মাপের', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ভুল কানেক্টরে বড়জোর জয়েন্টটা একটু ঢিলে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অ্যালুমিনিয়ামে কখনো কোনো করোসন হয় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'কানেক্টর যা-ই হোক, জোরে চাপলেই টেকে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ লোকের কোড মেলানোর দরকার পড়ে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board31Lines {
  static const rivalTaunt = 'আরে, ACSR না AAAC — অত বাছবিচার করে কী হবে?';

  /// Lesson 3.1's first myth buster, word for word.
  static const rivalMyth = 'সব তো অ্যালুমিনিয়ামই, যেকোনো কানেক্টর দিয়ে জয়েন্ট করে দিলেই চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
