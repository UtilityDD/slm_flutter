import 'learn_board_models.dart';

/// Module 5 Lesson 5.3 (সাধারণ ফল্ট: অপরাধীদের প্যারেড), the picture board
/// (rung `5.3/learn`, pack `learn_5_3`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board53_art.py`. Every round
/// and every trap comes from the lesson text (spec
/// `docs/module_specs/module5_items/board_53.json`, rulings
/// `docs/module_specs/module5_rulings.md`):
///  * type: a branch touching two or three wires at once is a phase-to-phase
///    fault; a branch down to the ground is phase-to-earth, an insulator
///    failure is an earth fault, a snapped wire touching nothing is open;
///  * branch: removing a branch is itself very risky — plan it first, call the
///    forest department or a special team when needed, then check the
///    conductor, insulators and pole for damage; a strike mark on the pole or
///    cross-arm is a clue too;
///  * insulator: a damaged insulator is changed by the rule (lesson 4.1) and
///    the cross-arm is checked before the swap; a carbon track will flash over
///    again, so it is never wiped clean;
///  * clamp: a damaged connector is replaced; a hotspot can anneal the
///    aluminium (soft and brittle), so the damaged length is cut away too
///    (ruling M5-15a: shown as discolouration and softness, no bend-test
///    claim); a snapped wire is jointed by the rule;
///  * evidence: a burnt bird or animal and a blood stain on the wire, a burst
///    LA with its earth lead hanging, metal manja touching two wires.
/// The lesson's rounds ask "which pictures"; one hand holds one safe card, so
/// the prompts ask for one ("কোনটা"). The rival's myth is the lesson's first
/// myth buster, word for word.
const learnBoardPack53 = LearnBoardPack(
  lessonId: '5.3',
  titleBn: 'সাধারণ ফল্ট: অপরাধীদের প্যারেড',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'ফল্টের জায়গায় পৌঁছে গেছেন। এবার অপরাধী চিনুন — সূত্র দেখে ধরন বুঝুন, নিয়ম মেনে সারান।',
  earnedBn: 'ধরন চিনে, সূত্র মিলিয়ে, ক্ষতিগ্রস্ত অংশ বদলে — তবেই ফল্ট সারানো।',
  slots: [
    LearnBoardSlot(
      id: 'type',
      promptBn: 'কোন ছবিটা ফেজ-টু-ফেজ ফল্ট দেখাচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'two',
          labelBn: 'ডাল দুটি তারকে একসাথে ছুঁয়েছে',
          asset: 'assets/game/art/m5_board53/type_two.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'three',
          labelBn: 'ডাল তিনটি তারকেই ছুঁয়েছে',
          asset: 'assets/game/art/m5_board53/type_three.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ground',
          labelBn: 'ডাল একটি তার থেকে মাটিতে ঠেকেছে',
          asset: 'assets/game/art/m5_board53/type_ground.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল মাটিতে ঠেকে থাকলে সেটা ফেজ-টু-আর্থ ফল্ট। দুটি বা তিনটি তার একসাথে ছুঁলে তবেই ফেজ-টু-ফেজ।',
        ),
        LearnBoardOption(
          id: 'track',
          labelBn: 'ইনসুলেটরে কালো কার্বন ট্র্যাক',
          asset: 'assets/game/art/m5_board53/type_track.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটর ফেলিওর একটা পরিষ্কার আর্থ ফল্ট তৈরি করে — ফেজ-টু-ফেজ নয়।',
        ),
        LearnBoardOption(
          id: 'snapped',
          labelBn: 'ছেঁড়া তার শূন্যে ঝুলছে',
          asset: 'assets/game/art/m5_board53/type_snapped.svg',
          scene: true,
          correct: false,
          rejectBn: 'তার ছিঁড়ে কিছু না ছুঁলে সেটা ওপেন সার্কিট — ফেজ-টু-ফেজ নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ডাল দুটি বা তিনটি তার একসাথে ছুঁলেই ফেজ-টু-ফেজ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডাল মাটিতে ঠেকলে সেটা ফেজ-টু-আর্থ ফল্ট হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অপরাধী ঠিক চিনলে তবেই সঠিক সমাধান করা যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ডাল একটা তারে ঠেকলেই সেটা ফেজ-টু-ফেজ ফল্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছেঁড়া তার ঝুললেই সবসময় ফেজ-টু-ফেজ ফল্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কালো ইনসুলেটর মানেই দুই ফেজের শর্ট সার্কিট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'শুকনো ডাল তারে পড়লে কোনো ফল্টই হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফল্টের ধরন জেনে লাভ নেই, ডাল সরালেই হলো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ডাল মাটিতে ঠেকলেও সেটা ফেজ-টু-ফেজ ফল্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'branch',
      promptBn: 'লাইনের ওপর বড় ডাল পড়েছে। ঠিক কাজ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'plan',
          labelBn: 'মাটিতে দাঁড়িয়ে দল মিলে সরানোর পরিকল্পনা',
          asset: 'assets/game/art/m5_board53/branch_plan.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'forest',
          labelBn: 'পুরো গাছে বন দপ্তর বা বিশেষ টিমের সাহায্য',
          asset: 'assets/game/art/m5_board53/branch_forest.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'check',
          labelBn: 'ডাল সরিয়ে তার, ইনসুলেটর ও পোল পরীক্ষা',
          asset: 'assets/game/art/m5_board53/branch_check.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'yank',
          labelBn: 'একা লাইনম্যান এক টানে ডাল নামাচ্ছেন',
          asset: 'assets/game/art/m5_board53/branch_yank.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল সরানোর কাজটাও অত্যন্ত ঝুঁকিপূর্ণ। আগে পরিকল্পনা করুন।',
        ),
        LearnBoardOption(
          id: 'charge',
          labelBn: 'ডাল সরতেই চার্জের জন্য ফোন',
          asset: 'assets/game/art/m5_board53/branch_charge.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল সরানোর পর কন্ডাক্টর, ইনসুলেটর আর পোলের ক্ষতি পরীক্ষা করে মেরামত করুন।',
        ),
        LearnBoardOption(
          id: 'mark',
          labelBn: 'পোলে আঘাতের দাগ দেখেও চলে যাওয়া',
          asset: 'assets/game/art/m5_board53/branch_mark.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলের গায়ে বা ক্রস-আর্মে আঘাতের চিহ্নও সূত্র — ক্ষতি পরীক্ষা করে মেরামত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ডাল সরানোও ঝুঁকির কাজ, তাই নিয়ম মেনে ধাপে ধাপে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আগে পরিকল্পনা, দরকারে বন দপ্তর, তারপর পরীক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঝুঁকির এই কাজে কোনো ধাপই বাদ দেওয়া চলে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ডাল যত তাড়াতাড়ি টেনে নামানো যায় ততই ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ডাল সরে গেলেই লাইন চার্জ করা যায় নিশ্চিন্তে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পোলের গায়ে আঘাতের দাগ কোনো সূত্রই নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বন দপ্তর ডাকলে সময় নষ্ট, নিজেই সেরে ফেলুন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একজন লাইনম্যান একাই বড় ডাল সরাতে যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঝড়ে পড়া ডাল লাইনের কোনো ক্ষতি করে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'insulator',
      promptBn: 'ফাটা ইনসুলেটর পাওয়া গেছে। ঠিক কাজ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'swap',
          labelBn: 'বন্ধ, আর্থ করা লাইনে নিয়মমতো নতুন ইনসুলেটর',
          asset: 'assets/game/art/m5_board53/insulator_swap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'arm',
          labelBn: 'বদলানোর আগে ক্রস-আর্ম পরীক্ষা',
          asset: 'assets/game/art/m5_board53/insulator_arm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tape',
          labelBn: 'ফাটা ইনসুলেটরে টেপ জড়ানো',
          asset: 'assets/game/art/m5_board53/insulator_tape.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ষতিগ্রস্ত ইনসুলেটর নিয়ম অনুযায়ী বদলাতে হবে — টেপ জড়িয়ে চলে না।',
        ),
        LearnBoardOption(
          id: 'wipe',
          labelBn: 'কার্বন ট্র্যাক মুছে পরিষ্কার',
          asset: 'assets/game/art/m5_board53/insulator_wipe.svg',
          scene: true,
          correct: false,
          rejectBn: 'কালো দাগটি কার্বন ট্র্যাক — যেকোনো মুহূর্তে আবার ফ্ল্যাশওভার ঘটাবে। বদলানোই একমাত্র উপায়।',
        ),
        LearnBoardOption(
          id: 'splitarm',
          labelBn: 'ফাটা ক্রস-আর্মেই নতুন ইনসুলেটর',
          asset: 'assets/game/art/m5_board53/insulator_splitarm.svg',
          scene: true,
          correct: false,
          rejectBn: 'বদলানোর আগে ক্রস-আর্মটাও পরীক্ষা করে নিন, কোনো ক্ষতি হয়েছে কিনা।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ক্ষতিগ্রস্ত ইনসুলেটর নিয়ম অনুযায়ী বদলাতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বদলানোর আগে ক্রস-আর্মের ক্ষতিও দেখে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভাঙা ইনসুলেটর উপেক্ষা করা যায় না, বদলান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফাটা ইনসুলেটরে টেপ জড়ালেই আবার চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কালো দাগ ভালো করে মুছলেই ইনসুলেটর নতুন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ক্রস-আর্ম লোহার, ওটা দেখার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটু ফাটা ইনসুলেটরও বছরের পর বছর চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ইনসুলেটর ভাঙলেও লাইনে কোনো ফল্ট হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভাঙা ইনসুলেটর পরের রুটিন কাজে বদলালেই হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'clamp',
      promptBn: 'PG ক্ল্যাম্প গলে গেছে। হটস্পট সারাতে ঠিক কাজ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'fresh',
          labelBn: 'পোড়া কানেক্টরের বদলে নতুন কানেক্টর',
          asset: 'assets/game/art/m5_board53/clamp_fresh.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'soft',
          labelBn: 'পোড়ার পাশে তার নরম হয়েছে কিনা দেখা',
          asset: 'assets/game/art/m5_board53/clamp_soft.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'বিবর্ণ, নরম অংশ কেটে বাদ দেওয়া',
          asset: 'assets/game/art/m5_board53/clamp_cut.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'retight',
          labelBn: 'গলে যাওয়া ক্ল্যাম্পই আবার টাইট',
          asset: 'assets/game/art/m5_board53/clamp_retight.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ষতিগ্রস্ত কানেক্টর বদলে দিতে হবে — গলা ক্ল্যাম্প টাইট দিয়ে চলে না।',
        ),
        LearnBoardOption(
          id: 'blackend',
          labelBn: 'কালো, নরম তারের মাথায় নতুন ক্ল্যাম্প',
          asset: 'assets/game/art/m5_board53/clamp_blackend.svg',
          scene: true,
          correct: false,
          rejectBn: 'বেশি গরমে অ্যালুমিনিয়াম তার নরম ও ভঙ্গুর হয় — ক্ষতিগ্রস্ত অংশও কেটে বাদ দিন।',
        ),
        LearnBoardOption(
          id: 'twist',
          labelBn: 'ছেঁড়া দুই মাথা হাতে পেঁচানো',
          asset: 'assets/game/art/m5_board53/clamp_twist.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছেঁড়া তার নিয়ম অনুযায়ী জয়েন্ট করতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'হটস্পটে কানেক্টর আর তার, দুটোরই ক্ষতি দেখতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বেশি গরমে কানেক্টর পোড়ে, তারও নরম ও ভঙ্গুর হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হটস্পটের পুরো ক্ষতি সারাতে হয়, জোড়াতালি নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গলা ক্ল্যাম্প জোরে টাইট দিলেই আবার চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নতুন ক্ল্যাম্প লাগালে তার দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গরমে অ্যালুমিনিয়াম তার আরও শক্ত হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছেঁড়া তার হাতে পেঁচিয়ে দিলেই জোড়া হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কালো হওয়া তার শুধু ময়লা, কাটার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হটস্পট নিজে থেকেই ঠান্ডা হয়ে সেরে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'evidence',
      promptBn: 'কোন ছবিটা ফল্টের স্পষ্ট প্রমাণ?',
      options: [
        LearnBoardOption(
          id: 'bird',
          labelBn: 'তারের নিচে পোড়া পাখি, তারে রক্তের দাগ',
          asset: 'assets/game/art/m5_board53/evidence_bird.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'la',
          labelBn: 'বিস্ফোরিত LA, আর্থিং সংযোগ ঝুলছে',
          asset: 'assets/game/art/m5_board53/evidence_la.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'manja',
          labelBn: 'ধাতব মাঞ্জা দুটি তারকে ছুঁয়ে আছে',
          asset: 'assets/game/art/m5_board53/evidence_manja.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'livebird',
          labelBn: 'দূরের গাছে জ্যান্ত পাখি',
          asset: 'assets/game/art/m5_board53/evidence_livebird.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রমাণ হলো পোড়া পাখি বা জন্তুর দেহ আর তারে রক্তের দাগ।',
        ),
        LearnBoardOption(
          id: 'intactla',
          labelBn: 'আস্ত LA, আর্থ লিড বোল্টে আঁটা',
          asset: 'assets/game/art/m5_board53/evidence_intactla.svg',
          scene: true,
          correct: false,
          rejectBn: 'বজ্রপাতের পর বিস্ফোরিত বা ভাঙা LA আর ঝুলে থাকা আর্থিং সংযোগই সূত্র।',
        ),
        LearnBoardOption(
          id: 'farkite',
          labelBn: 'তার থেকে দূরে গাছে আটকানো ঘুড়ি',
          asset: 'assets/game/art/m5_board53/evidence_farkite.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঘুড়ি তখনই অপরাধী, যখন ধাতব মাঞ্জা দুটি তারকে ছুঁইয়ে দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অপরাধী সবসময় কিছু না কিছু সূত্র রেখে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সূত্র মিলিয়েই অপরাধী চিনতে হয়, আন্দাজে নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্পষ্ট প্রমাণ ফল্টের সাথে সরাসরি জড়িয়ে থাকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আশেপাশে পাখি দেখলেই সে-ই ফল্টের অপরাধী', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গাছে আটকানো যেকোনো ঘুড়িই ফল্টের কারণ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'LA আস্ত থাকলেও ওটাকেই অপরাধী ধরা হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পোড়া দাগ দেখার দরকার নেই, আন্দাজই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তারে রক্তের দাগ থাকলেও ফল্টের সাথে যোগ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফল্টের জায়গায় কোনো সূত্র খোঁজার দরকার নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board53Lines.rivalTaunt,
    rivalLineBn: M5Board53Lines.rivalMyth,
    exitBn: M5Board53Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'মুছে দিলেই আবার চলবে — ওঁর এই কথা বিশ্বাস করেন?',
    flipStingBn: 'কালো দাগ মুছে দিলেই চলবে — ওঁর এই কথা কি ভুল?',
    dangerHints: [
      'কার্বন ট্র্যাক',
      'আবার ফ্ল্যাশওভার',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'কালো দাগটা কার্বন ট্র্যাক, দুর্বল আধা-পরিবাহী পথ', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ওই ট্র্যাক যেকোনো মুহূর্তে আবার ফ্ল্যাশওভার ঘটাবে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কার্বন ট্র্যাকের ইনসুলেটর বদলানোই একমাত্র উপায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কালো দাগ শুধু ধুলো-ময়লা, মুছলেই চলে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'পরিষ্কার করলে ইনসুলেটর আবার নতুনের মতো হয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'একটু কালো ইনসুলেটরে কারেন্ট কখনো লাফায় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'বৃষ্টিতে ধুয়ে গেলে কার্বন ট্র্যাক মিলিয়ে যায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ইনসুলেটর বদলানো শুধু ভেঙে গেলেই দরকার হয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ চোখে দেখলেই বোঝা যায় দাগটা নিরীহ', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for a reading time)
/// until the director records them with `tool/rival_clip.py`.
abstract final class M5Board53Lines {
  static const rivalTaunt = 'আরে, সামান্য একটু কালি তো! নতুন ইনসুলেটরের ঝামেলা কেন?';

  /// Lesson 5.3's first myth buster, word for word.
  static const rivalMyth = 'ইনসুলেটরটা তো শুধু একটু কালো হয়েছে, ওটা পরিষ্কার করে দিলেই আবার চলবে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যত সব ঝামেলা।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
