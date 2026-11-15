import 'learn_board_models.dart';

/// Module 6 Lesson 6.1 (ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড), the
/// picture board (rung `6.1/learn`, pack `learn_6_1`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board61_art.py`: the WBSEDCL
/// pole-mounted DTR with an AB switch and HG fuses, no DO (ruling M6-2). Board
/// 3.6 (plinth DTR: side / gel / sign / tap / earth) is not repeated round for
/// round. Ruling M6-8 shortens the board to one recap round plus the new
/// material (item spec `docs/module_specs/module6_items/board_61.json`, Module 6
/// rulings; the live lesson text wins over spec quotes, X6):
///  * signs (recap of spec rounds 0–2): outside signs that the inside is at
///    risk — oil dripping with the gauge below MIN (point 6: low oil, the
///    coil cannot cool, the paper burns), pink silica gel (moisture in),
///    dark burnt-smelling drain-valve oil (an arc or overheating inside).
///    Traps: the soft steady hum (myth 2: normal), blue dry gel, oil between
///    MIN and MAX;
///  * inside (spec round 3): the laminated soft-iron core, the HT and LT
///    copper coils, kraft paper between the layers, everything sunk in
///    mineral oil (point 4). Traps: a rotor (a DTR is static, point 1), a wire
///    from the HT to the LT coil (induction, point 1), a tank of water;
///  * coil (spec round 4, shop photos — points 7 and 8): paper black at the
///    top of the coil, copper melted into lumps, a coil bent / bulged out of
///    place, turns burst at one spot. Traps: yellow-brown unburnt paper, a
///    straight coil in its place, smooth whole copper;
///  * act (spec round 5): report and ask for tests, change the pink gel, take
///    the DTR off the line for DGA / BDV (X6: 'লাইন থেকে বিচ্ছিন্ন করে').
///    Traps: the tank opened on the pole (myth 3: the lesson's own words
///    'ভুল ও মারাত্মক বিপজ্জনক'; boards are not scored for deadly, ruling
///    M6-4), the tank opened in roadside dust, a burnt DTR put back on charge
///    (point 8 safety tip), a small drip ignored (myth 1).
/// Hands on the DTR only once it is dead and earthed (rulings X1, X3): on the
/// platform cards the AB blades stand open, the handle is down with a red tag
/// and the earth leads are on the HT bushings; the recharge trap shows the
/// handle pushed up with the earth set left on the ground.
/// The rival's myth is the lesson's third myth, word for word (owner question
/// in the spec: board 3.6 used the oil-leak myth).
///
/// Reason chips: the runner deals a round's "কেন?" chips whatever card was
/// picked, so every right chip is a rule that holds for each safe card of its
/// round (GAME_LEVEL_PLAYBOOK §4: the right reason fits what the player did).
/// Rules that only explain a trap stay in that trap's reject line.
///
/// DRAFT wording — owner (ruling M6-12): every Bangla line written for this
/// board (prompts, reason chips, labels, the intro, the earned line, the
/// rival's taunt) is a draft for the owner's natural wording; lesson quotes
/// are marked where they are used.
const learnBoardPack61 = LearnBoardPack(
  lessonId: '6.1',
  titleBn: 'ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড',
  badgeBn: 'যন্ত্র গুরু',
  introBn: M6Board61Lines.intro,
  earnedBn: M6Board61Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'signs',
      promptBn: 'বাইরের কোন লক্ষণ বলছে, ভেতরে কয়েলের কাগজ বিপদে?',
      options: [
        LearnBoardOption(
          id: 'drip',
          labelBn: 'তেল চুঁইয়ে পড়ছে, গেজে তেল MIN-এর নিচে',
          asset: 'assets/game/art/m6_board61/signs_drip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pink',
          labelBn: 'ব্রিদারের সিলিকা জেল গোলাপি হয়ে গেছে',
          asset: 'assets/game/art/m6_board61/signs_pink.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'burnt',
          labelBn: 'ড্রেন ভালভের তেল কালচে, পোড়া গন্ধ',
          asset: 'assets/game/art/m6_board61/signs_burnt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hum',
          labelBn: 'হালকা, একটানা গুনগুন শব্দ',
          asset: 'assets/game/art/m6_board61/signs_hum.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোরে প্রতিনিয়ত চুম্বকত্ব তৈরি হয় বলে হালকা, একটানা গুনগুন আওয়াজ একদম স্বাভাবিক।',
        ),
        LearnBoardOption(
          id: 'blue',
          labelBn: 'ব্রিদারের জেল নীল, শুকনো',
          asset: 'assets/game/art/m6_board61/signs_blue.svg',
          scene: true,
          correct: false,
          rejectBn: 'একদম শুকনো সিলিকা জেল নীল বা কমলা রঙের হয়। এটা ঠিক আছে।',
        ),
        LearnBoardOption(
          id: 'midoil',
          labelBn: 'গেজে তেল MIN আর MAX-এর মাঝামাঝি',
          asset: 'assets/game/art/m6_board61/signs_midoil.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল MIN আর MAX চিহ্নের মাঝামাঝি থাকাটাই ঠিক লেভেল।',
        ),
      ],
      whyChips: [
        // DRAFT wording — owner. Right reasons hold for every safe picture in
        // the round (the runner deals them whatever was picked, playbook §4).
        LearnWhyChip(id: 'w1', textBn: 'এই লক্ষণ ভেতরের কাগজ আর তেলের বিপদ জানায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কয়েল পুড়ে যাওয়ার আগেই এই লক্ষণ সতর্ক করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্বাভাবিক DTR-এ এমন লক্ষণ দেখা যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গুনগুন শব্দ হলেই ভেতরে বড় গোলমাল আছে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জেলের রং বদলালেও ভেতরে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তেল একটু কমলে কয়েল আরও ঠান্ডা থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পুরনো DTR-এর তেল কালো হওয়াই নিয়ম', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সামান্য লিক হলে ভেতরের কোনো ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'inside',
      promptBn: 'ট্যাঙ্কের ভেতরে আসলে কী থাকে?',
      options: [
        LearnBoardOption(
          id: 'core',
          labelBn: 'নরম লোহার ল্যামিনেটেড পাতের কোর',
          asset: 'assets/game/art/m6_board61/inside_core.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'coils',
          labelBn: 'HT আর LT-র তামার কয়েল',
          asset: 'assets/game/art/m6_board61/inside_coils.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'paper',
          labelBn: 'কয়েলের স্তরের মাঝে ক্রাফট পেপার',
          asset: 'assets/game/art/m6_board61/inside_paper.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'oil',
          labelBn: 'খনিজ তেলে ডোবানো কোর আর কয়েল',
          asset: 'assets/game/art/m6_board61/inside_oil.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rotor',
          labelBn: 'ভেতরে ঘুরছে একটা পাখা বা রোটর',
          asset: 'assets/game/art/m6_board61/inside_rotor.svg',
          scene: true,
          correct: false,
          rejectBn: 'DTR একটা স্থির মেশিন। এর ভেতরে কোনো ঘূর্ণায়মান অংশ বা মুভিং পার্টস নেই।',
        ),
        LearnBoardOption(
          id: 'wire',
          labelBn: 'HT কয়েল থেকে LT কয়েলে সোজা তার',
          asset: 'assets/game/art/m6_board61/inside_wire.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুই ওয়াইন্ডিংয়ের মধ্যে সরাসরি কোনো তারের কানেকশন থাকে না। চৌম্বক আবেশে ভোল্টেজ বদলায়।',
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'জলে ভরা ট্যাঙ্ক',
          asset: 'assets/game/art/m6_board61/inside_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেতরে থাকে খনিজ তেল। তেলে জল ঢুকলে কারেন্ট সহ্য করার ক্ষমতা কমে যায়।',
        ),
      ],
      whyChips: [
        // DRAFT wording — owner. True of the core, the coils, the paper and the oil.
        LearnWhyChip(id: 'w1', textBn: 'কোর, কয়েল, কাগজ আর তেল নিয়েই ট্যাঙ্কের ভেতর', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'DTR স্থির যন্ত্র, ভেতরের সব অংশ তেলে ডোবানো', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এই অংশ ঠিক থাকলে তবেই ভোল্টেজ নিরাপদে নামে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভেতরের পাখা ঘুরে ঘুরে তেল ঠান্ডা রাখে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'HT আর LT কয়েল সরাসরি তারে জোড়া থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ট্যাঙ্কে জল থাকে বলে কয়েল ঠান্ডা থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাগজ শুধু কয়েল মোড়ার সাজ, কাজ নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কোর তামার, তাই কারেন্ট সোজা চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'coil',
      promptBn: 'শপে খোলা কয়েলের ছবি। কোনটা বড় ক্ষতির প্রমাণ?',
      options: [
        LearnBoardOption(
          id: 'black',
          labelBn: 'কয়েলের ওপরের দিকে কাগজ কালো',
          asset: 'assets/game/art/m6_board61/coil_black.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'melt',
          labelBn: 'তামা গলে দলা পাকিয়ে ছিটকে গেছে',
          asset: 'assets/game/art/m6_board61/coil_melt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bent',
          labelBn: 'কয়েল বেঁকে, ফুলে জায়গা থেকে সরে গেছে',
          asset: 'assets/game/art/m6_board61/coil_bent.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'burst',
          labelBn: 'এক জায়গায় তারের টার্ন পুড়ে ফেটে আছে',
          asset: 'assets/game/art/m6_board61/coil_burst.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'yellow',
          labelBn: 'হলুদ-বাদামি, না-পোড়া কাগজ',
          asset: 'assets/game/art/m6_board61/coil_yellow.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশন কাগজের স্বাভাবিক রং হলুদ-বাদামি। পুড়লে তবে কালো কার্বন হয়।',
        ),
        LearnBoardOption(
          id: 'straight',
          labelBn: 'সোজা কয়েল, নিজের জায়গাতেই আছে',
          asset: 'assets/game/art/m6_board61/coil_straight.svg',
          scene: true,
          correct: false,
          rejectBn: 'কয়েল বাঁকেনি, ফোলেনি, সরেনি। শর্ট-সার্কিটের ধাক্কার কোনো প্রমাণ নেই।',
        ),
        LearnBoardOption(
          id: 'smooth',
          labelBn: 'মসৃণ, আস্ত তামার তার',
          asset: 'assets/game/art/m6_board61/coil_smooth.svg',
          scene: true,
          correct: false,
          rejectBn: 'তামা গলেনি বা ছিটকে যায়নি। ভেতরে তীব্র আর্কের কোনো চিহ্ন নেই।',
        ),
      ],
      whyChips: [
        // DRAFT wording — owner. True of every damaged-coil photo.
        LearnWhyChip(id: 'w1', textBn: 'কয়েলের চেহারা বলে দেয় ভেতরে কী ঘটেছিল', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এ হলো তাপ, আর্ক বা শর্ট-সার্কিটের ছাপ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সুস্থ কয়েল সোজা, তামা আস্ত, কাগজ হলুদ-বাদামি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কালো কাগজই নতুন কয়েলের স্বাভাবিক রং', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তামা একটু গলে গেলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কয়েল একটু ফুলে থাকাই স্বাভাবিক নিয়ম', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কয়েলের নিচের ঠান্ডা অংশের কাগজ আগে পোড়ে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শপের ছবি দেখে ক্ষতির কিছুই বোঝা যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'act',
      promptBn: 'DTR-এ ভেতরের গোলমালের লক্ষণ দেখলেন। এখন আপনার কাজ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'report',
          labelBn: 'JE বা কন্ট্রোল রুমে দ্রুত রিপোর্ট, পরীক্ষার অনুরোধ',
          asset: 'assets/game/art/m6_board61/act_report.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'gel',
          labelBn: 'গোলাপি জেল দ্রুত বদলানো',
          asset: 'assets/game/art/m6_board61/act_gel.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dga',
          labelBn: 'লাইন থেকে বিচ্ছিন্ন করে DGA/BDV পরীক্ষা',
          asset: 'assets/game/art/m6_board61/act_dga.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'poletank',
          labelBn: 'পোলের ওপরেই ট্যাঙ্কের ঢাকনা খোলা',
          asset: 'assets/game/art/m6_board61/act_poletank.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল ও মারাত্মক বিপজ্জনক! ট্যাঙ্ক খোলার কাজ কেবল উপযুক্ত মেরামত শপে বা টেস্টিং ল্যাবের সুরক্ষিত পরিবেশেই করা সম্ভব।',
        ),
        LearnBoardOption(
          id: 'dust',
          labelBn: 'রাস্তার ধুলোয় ট্যাঙ্ক নামিয়ে খোলা',
          asset: 'assets/game/art/m6_board61/act_dust.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধুলোবালি ও খোলা বাতাসে ট্যাঙ্ক খোলা একেবারেই বারণ।',
        ),
        LearnBoardOption(
          id: 'recharge',
          labelBn: 'পোড়া DTR আবার চার্জ করে দেখা',
          asset: 'assets/game/art/m6_board61/act_recharge.svg',
          scene: true,
          correct: false,
          rejectBn: 'তামা গলা বা কাগজ পোড়া ধরা পড়লে আবার চার্জ করার ঝুঁকি নেবেন না। টেস্ট ল্যাবের রিপোর্টের ওপর ভরসা রাখুন।',
        ),
        LearnBoardOption(
          id: 'ignore',
          labelBn: 'সামান্য তেল চুঁইয়ে পড়া, পাত্তা না দেওয়া',
          asset: 'assets/game/art/m6_board61/act_ignore.svg',
          scene: true,
          correct: false,
          rejectBn: 'সামান্য লিক মানেও তেল কমছে আর কয়েল গরম হচ্ছে। ওই ফাঁক দিয়ে জলীয় বাষ্পও ঢুকতে পারে।',
        ),
      ],
      whyChips: [
        // DRAFT wording — owner. True of the report, the gel and the DGA/BDV
        // test; the trap rules (tank only in a shop, no
        // recharge without the lab) stay in the traps' own reject lines.
        LearnWhyChip(id: 'w1', textBn: 'ট্যাঙ্ক না খুলে বাইরে থেকে এটাই আপনার কাজ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লক্ষণ দেখে দ্রুত ব্যবস্থা নিলে বড় ক্ষতি আটকায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'খবর দেওয়া, পরীক্ষা করানো আর ছোট যত্নই আপনার কাজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পোলের ওপরেই ট্যাঙ্ক খুলে কয়েল সারা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একবার চার্জ করে দেখলেই ক্ষতি বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অল্প লিকে তেল কমে না, চিন্তার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিপোর্ট লেখা সময় নষ্ট, আগে নিজে সারুন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'খোলা বাতাসে ট্যাঙ্ক খুললে তেল ভালো থাকে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board61Lines.rivalTaunt,
    rivalLineBn: M6Board61Lines.rivalMyth,
    exitBn: M6Board61Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ধুলো আর আর্দ্রতা ঢোকে',
      'কয়েলের ইনসুলেশন নষ্ট',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ট্যাঙ্ক খোলা হয় শুধু মেরামত শপে বা ল্যাবে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ধুলো আর খোলা বাতাসে ট্যাঙ্ক খোলা বারণ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লাইনম্যানের কাজ বাইরে দেখে রিপোর্ট করা', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'পোলে বসেই কয়েল সারলে অনেক সময় বাঁচে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'অভিজ্ঞ লোক হলে মাঠেই ট্যাঙ্ক খোলা যায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ট্যাঙ্কে একটু ধুলো ঢুকলে কিছুই হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'খোলা বাতাস লাগলে তেল আরও ভালো থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'শপে পাঠানো মানেই শুধু সময় নষ্ট করা', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'আর্দ্রতায় কয়েলের কাগজের কিছু হয় না', correct: false),
    ],
  ),
);

/// The lines on this board. The careless coworker's [rivalExit] is already in
/// his recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`. The guide's lines
/// ([guideSpoken]) play on the device voice until the owner's clips exist.
abstract final class M6Board61Lines {
  /// DRAFT wording — owner.
  static const intro = 'DTR লাইনের হৃৎপিণ্ড। বাইরের লক্ষণ দেখে বুঝুন, ভেতরে কী ঘটছে।';

  /// DRAFT wording — owner.
  static const earned = 'বাইরের লক্ষণে ভেতরের বিপদ চিনুন। ট্যাঙ্ক খোলা শুধু শপে; আপনার কাজ রিপোর্ট আর পরীক্ষার অনুরোধ।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, শপে পাঠিয়ে মাসভর বসে থাকবে নাকি?';

  /// Lesson 6.1's third myth, word for word.
  static const rivalMyth = 'মাঠে পোলের ওপরে ঝুলন্ত অবস্থাতেই ট্রান্সফরমারের ট্যাঙ্ক খুলে কয়েল ঠিক করে ফেলা যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12: the rival's new lines (the taunt is a draft; the myth is
  /// the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Ruling M6-12: every guide line on this board, for the owner's wording
  /// pass and the voice session (lesson quotes in the trap reasons included,
  /// since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the earned line), for the owner's
  /// wording pass and the voice session.
  static List<String> get guideSpoken {
    final p = learnBoardPack61;
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
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
