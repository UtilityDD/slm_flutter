import 'learn_board_models.dart';

/// Ladder step 22 — Module 1 Lesson 1.8 (মাঠে আগুন লাগলে করণীয়), the picture
/// board (mode like steps 7, 10 and 13).
///
/// Picture cards are vector scenes from `tool/fire_board_art.py`. Every round
/// and every trap comes from the lesson text:
///  * know the enemy — Class A (dry grass, wood, paper), Class B (flammable
///    liquid: transformer oil, diesel), Class C (live electrical equipment or
///    circuit); the wrong method makes a fire grow and puts lives at risk;
///  * water is strictly forbidden on Class B (oil floats on water, the fire
///    spreads) and Class C (water conducts — shock); the first job at an
///    electrical fire is to switch the power source off when it is safe; the
///    weapons: DCP (ABC), CO2 (B and C), sand / dry soil for a small oil fire;
///  * the pressure gauge in the green = ready; used once, the pressure is
///    gone and it must go for refill;
///  * PASS — pull the safety pin, aim at the base (not the flames), squeeze,
///    sweep side to side at the base until it is fully out;
///  * wind at your back (smoke and heat not towards you), the escape route
///    behind you open (never cornered), and beyond control call the Fire
///    Brigade — not a hero, smart.
/// The rival's myth is the lesson's own: "ছোট আগুন, একটু পরেই নিজে থেকে নিভে
/// যাবে।" (the refill myth is step 24's coworker push, not used here).
const learnBoardPack18 = LearnBoardPack(
  lessonId: '1.8',
  titleBn: 'মাঠে আগুন লাগলে করণীয়',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'বিদ্যুৎ আর আগুন — দুটোকেই সম্মান করুন। আগুন চিনুন, ঠিক অস্ত্র বাছুন।',
  earnedBn: 'আগুন চিনেছেন — তেলে আর বিদ্যুতে জল নয়, গোড়ায় লক্ষ্য, পথ খোলা।',
  slots: [
    LearnBoardSlot(
      id: 'class',
      promptBn: 'Class B-এর আগুন কোনটা?',
      options: [
        LearnBoardOption(id: 'jerry', labelBn: 'ডিজেলের ক্যানে আগুন', asset: 'assets/game/art/fire_board/class_jerry.svg', scene: true, correct: true),
        LearnBoardOption(id: 'puddle', labelBn: 'মাটিতে ছড়ানো ডিজেলে আগুন', asset: 'assets/game/art/fire_board/class_puddle.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'grass',
          labelBn: 'শুকনো ঘাসে আগুন',
          asset: 'assets/game/art/fire_board/class_grass.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুকনো ঘাস সাধারণ দাহ্য — এটা Class A, দাহ্য তরল নয়।',
        ),
        LearnBoardOption(
          id: 'wood',
          labelBn: 'কাঠ আর কাগজে আগুন',
          asset: 'assets/game/art/fire_board/class_wood.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাঠ আর কাগজ সাধারণ দাহ্য — এটা Class A।',
        ),
        LearnBoardOption(
          id: 'panel',
          labelBn: 'প্যানেলে আগুন, স্পার্ক',
          asset: 'assets/game/art/fire_board/class_panel.svg',
          scene: true,
          correct: false,
          rejectBn: 'Live বৈদ্যুতিক সরঞ্জাম বা Circuit-এর আগুন — এটা Class C।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'Class B মানে দাহ্য তরল, যেমন ডিজেল বা তেল', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'Class চিনলে তবেই নেভানোর ঠিক পদ্ধতি বাছা যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল পদ্ধতিতে আগুন বাড়ে, জীবন বিপন্ন হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আগুন তো আগুনই, Class দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঘাস আর কাঠের আগুনও দাহ্য তরলের আগুন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্পার্ক দেখা গেলেই সেটা তেলের আগুন হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'Class শুধু অফিসের খাতায় লেখার জন্য', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যে আগুন সবচেয়ে বড়, সেটাই Class B হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'water',
      promptBn: 'তেলে বা বিদ্যুতে আগুন — কোন কাজটা ঠিক?',
      options: [
        LearnBoardOption(id: 'panel_off', labelBn: 'আগে প্যানেলের Power OFF', asset: 'assets/game/art/fire_board/water_panel_off.svg', scene: true, correct: true),
        LearnBoardOption(id: 'oil_abc', labelBn: 'তেলের আগুনে ABC স্প্রে', asset: 'assets/game/art/fire_board/water_oil_abc.svg', scene: true, correct: true),
        LearnBoardOption(id: 'oil_sand', labelBn: 'ছোট তেলের আগুনে বালি', asset: 'assets/game/art/fire_board/water_oil_sand.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'oil_water',
          labelBn: 'তেলের আগুনে বালতির জল',
          asset: 'assets/game/art/fire_board/water_oil_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল জলে ভাসে — জল দিলে আগুন আরও ছড়ায়।',
        ),
        LearnBoardOption(
          id: 'panel_water',
          labelBn: 'প্যানেলের আগুনে জল',
          asset: 'assets/game/art/fire_board/water_panel_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'জল বিদ্যুৎ পরিবাহী — বৈদ্যুতিক আগুনে জল মানে শকের ঝুঁকি।',
        ),
        LearnBoardOption(
          id: 'tr_hose',
          labelBn: 'জ্বলন্ত ট্রান্সফরমারে পাইপের জল',
          asset: 'assets/game/art/fire_board/water_tr_hose.svg',
          scene: true,
          correct: false,
          rejectBn: 'জ্বলন্ত ট্রান্সফরমারে জল নয় — Class B ও C-তে জল কঠোরভাবে নিষিদ্ধ।',
        ),
      ],
      // One reason pool serves every safe card (power off, ABC, sand), so each
      // right chip says why the pick keeps water off an oil or power fire.
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'Class B ও C-তে জল কঠোরভাবে নিষিদ্ধ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তেল বা বিদ্যুতের আগুনে জল দিলে আগুন বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জলে তেলের আগুন ছড়ায়, বিদ্যুতে Shock লাগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জল দিলে যেকোনো আগুন তাড়াতাড়ি নেভে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বালতির জল ঢাললে তেলের আগুন চাপা পড়ে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'Power চালু থাকলেও আগুনে জল দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'প্যানেলে জল ঢাললে স্পার্ক থেমে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ট্রান্সফরমার তো লোহার, জলে কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'gauge',
      promptBn: 'সিলিন্ডার হাতে নিলেন — কোনটা ব্যবহারের জন্য Ready?',
      options: [
        LearnBoardOption(id: 'ok', labelBn: 'গেজের কাঁটা সবুজ দাগে', asset: 'assets/game/art/fire_board/gauge_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok_hand', labelBn: 'গেজের কাঁটা সবুজ দাগে', asset: 'assets/game/art/fire_board/gauge_ok_hand.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'low',
          labelBn: 'কাঁটা বাঁ দিকের লাল দাগে',
          asset: 'assets/game/art/fire_board/gauge_low.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাঁটা সবুজ দাগে নেই — এই যন্ত্র ব্যবহারের জন্য Ready নয়।',
        ),
        LearnBoardOption(
          id: 'high',
          labelBn: 'কাঁটা ডান দিকের লাল দাগে',
          asset: 'assets/game/art/fire_board/gauge_high.svg',
          scene: true,
          correct: false,
          rejectBn: 'Pressure Gauge সবুজ দাগে থাকলে তবেই Ready — এটা নয়।',
        ),
        LearnBoardOption(
          id: 'used',
          labelBn: 'একবার ব্যবহার করা, পিন নেই',
          asset: 'assets/game/art/fire_board/gauge_used.svg',
          scene: true,
          correct: false,
          rejectBn: 'একবার ব্যবহার হলে চাপ বেরিয়ে যায় — Refill-এর জন্য পাঠাতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'গেজের কাঁটা সবুজ দাগে থাকলেই যন্ত্র Ready', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হাতে নিয়েই আগে Pressure Gauge দেখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সিলিন্ডার লাল হলেই সেটা ভরা থাকে, দেখতে হয় না', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'গেজ দেখার দরকার নেই, ঝাঁকালেই সব বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কাঁটা যেখানেই থাকুক, লিভার চাপলেই চলবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাল দাগে কাঁটা মানে সবচেয়ে বেশি শক্তি', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন কেনা সিলিন্ডারের গেজ দেখা লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pass',
      promptBn: 'সিলিন্ডার হাতে, সামনে আগুন — কে PASS মানছেন?',
      options: [
        LearnBoardOption(id: 'base', labelBn: 'পিন টেনে গোড়ায় স্প্রে', asset: 'assets/game/art/fire_board/pass_base.svg', scene: true, correct: true),
        LearnBoardOption(id: 'sweep', labelBn: 'গোড়ায় এপাশ-ওপাশ স্প্রে', asset: 'assets/game/art/fire_board/pass_sweep.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'flame',
          labelBn: 'শিখার মাথায় স্প্রে',
          asset: 'assets/game/art/fire_board/pass_flame.svg',
          scene: true,
          correct: false,
          rejectBn: 'Aim: লক্ষ্য আগুনের গোড়ায় — শিখায় নয়।',
        ),
        LearnBoardOption(
          id: 'pin',
          labelBn: 'পিন না টেনেই চাপ',
          asset: 'assets/game/art/fire_board/pass_pin.svg',
          scene: true,
          correct: false,
          rejectBn: 'PASS-এর প্রথম ধাপ Pull — আগে Safety Pin টানুন।',
        ),
        LearnBoardOption(
          id: 'stop',
          labelBn: 'না নিভতেই থেমে যাওয়া',
          asset: 'assets/game/art/fire_board/pass_stop.svg',
          scene: true,
          correct: false,
          rejectBn: 'Sweep: গোড়ায় এক পাশ থেকে অন্য পাশে Spray — সম্পূর্ণ না নিভা পর্যন্ত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'Aim মানে আগুনের গোড়ায় লক্ষ্য, শিখায় নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সম্পূর্ণ না নেভা পর্যন্ত গোড়ায় Sweep চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে পিন, তারপর লক্ষ্য, চাপ আর Sweep', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শিখার মাথায় স্প্রে করলেই আগুন নেভে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পিন না টেনেও হ্যান্ডেল চাপলেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শিখা ছোট হলেই স্প্রে থামিয়ে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'এক জায়গায় ধরে রাখলেই সব নিভে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ধোঁয়ার দিকে স্প্রে করাই সবচেয়ে ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'stand',
      promptBn: 'আগুনের সামনে — কোথায়, কীভাবে দাঁড়াবেন?',
      options: [
        LearnBoardOption(id: 'wind_back', labelBn: 'বাতাস পেছনে, পথ খোলা', asset: 'assets/game/art/fire_board/stand_wind_back.svg', scene: true, correct: true),
        LearnBoardOption(id: 'call', labelBn: 'বড় আগুন — দূরে থেকে Fire Brigade-কে Call', asset: 'assets/game/art/fire_board/stand_call.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'wind_face',
          labelBn: 'ধোঁয়া মুখের দিকে',
          asset: 'assets/game/art/fire_board/stand_wind_face.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাতাস পেছনে রেখে দাঁড়ান — ধোঁয়া আর তাপ যেন আপনার দিকে না আসে।',
        ),
        LearnBoardOption(
          id: 'cornered',
          labelBn: 'দেয়ালে পিঠ, পথ বন্ধ',
          asset: 'assets/game/art/fire_board/stand_cornered.svg',
          scene: true,
          correct: false,
          rejectBn: 'পেছনে বেরোনোর পথ সবসময় পরিষ্কার রাখুন — কোণঠাসা হবেন না।',
        ),
        LearnBoardOption(
          id: 'hero',
          labelBn: 'বড় আগুনে একা লড়াই',
          asset: 'assets/game/art/fire_board/stand_hero.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিয়ন্ত্রণের বাইরে গেলে Fire Brigade-কে Call — Hero নয়, Smart থাকুন।',
        ),
      ],
      // Both safe cards (spraying a small fire, phoning from afar at a big one)
      // show the wind at his back and the way out open behind him, so the right
      // chips are about those two; the Fire Brigade rule is the hero trap's reject.
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বাতাস পেছনে থাকলে ধোঁয়া-তাপ গায়ে আসে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পেছনে বেরোনোর পথ সবসময় খোলা রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বাতাস আর বেরোনোর পথ দেখে দাঁড়াতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ধোঁয়ার দিকে দাঁড়ালে আগুন ভালো দেখা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দেয়ালে পিঠ দিলে ভারসাম্য ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বড় আগুনেও একাই লড়ে যাওয়া উচিত', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'Fire Brigade ডাকা মানেই হেরে যাওয়া', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাতাস কোন দিকে, তাতে কিছু যায় আসে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: FireBoardLines.rivalTaunt,
    rivalLineBn: FireBoardLines.rivalMyth,
    exitBn: FireBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'শুনলেন তো ওর কথা? সত্যি কি ওর এই বিপজ্জনক কথায় কান দেবেন?',
    dangerHints: [
      'ছোট Spark কয়েক মিনিটে বড় আগুন',
      'আগুন দ্রুত বাড়ে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আগুন দ্রুত বাড়ে, ছোট থাকতেই Action নিন', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ছোট Spark কয়েক মিনিটে বড় Fire হতে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আগুন ছোট থাকতেই নেভানোর কাজ শুরু করুন', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ছোট আগুন একটু পরে নিজে থেকেই নিভে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'স্পার্ক তো ক্ষণিকের, ওতে আগুন বাড়ে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'আগে দেখি বাড়ে কিনা, তারপর ভাবা যাবে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ছোট আগুনে সিলিন্ডার খরচ করা অপচয়', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`). The guide's lines stay in the pack
/// (device TTS until the owner records them).
abstract final class FireBoardLines {
  static const rivalTaunt = 'আরে! এইটুকু আগুন দেখে এত দৌড়ঝাঁপ কীসের?';

  /// Lesson 1.8's myth buster, word for word.
  static const rivalMyth = 'ছোট আগুন, একটু পরেই নিজে থেকে নিভে যাবে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board added.
  static const recorded = [rivalTaunt, rivalMyth];
}
