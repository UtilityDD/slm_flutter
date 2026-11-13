import 'learn_board_models.dart';

/// Module 5 Lesson 5.7 (রাতের বেলা ফল্ট খোঁজার কৌশল), the picture board
/// (rung `5.7/learn`, pack `learn_5_7`, engineType `learn_cards`).
///
/// Picture cards are night scenes from `tool/m5_board57_art.py`. Every round
/// and every trap comes from the lesson text (spec
/// `docs/module_specs/module5_items/board_57.json`, trimmed to 5 rounds):
///  * prep: torch, headlamp and phone fully charged before leaving (pro tip
///    3); never alone at night (pro tip 4); a reflective jacket at the
///    roadside so drivers see you (pro tip 2);
///  * drive: slow, two people — one drives, the other watches both sides
///    (section 4); a strong, turnable searchlight for the pole top — the
///    headlights only light the road (myth 2); binoculars work at night too
///    (section 2); known, safe roads where possible (section 4);
///  * eyes: after the bright torch, lights off and wait a while so the eyes
///    adapt — a faint corona or spark may show (pro tip 1); corona is
///    invisible by day (section 3);
///  * clue: corona is a faint blue / purple glow round a damaged insulator;
///    bluish tracking lines prove the insulator has gone bad; a flash seen by
///    a resident or the patrol can mark the fault's exact place (section 3);
///  * sense: unusual hissing or rattling carries far in the night quiet;
///    residents are often awake — ask them (section 4); stumbling, holes and
///    no hurry or shortcuts at night (section 1).
/// Every worker stays on the ground or seated in the van: ground patrol of a
/// line needs no climb or touch (ruling M5-3), so no PTW is shown as a must.
/// Each round's right reasons hold for every safe card in it, since the
/// runner deals reasons whatever safe card was picked.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack57 = LearnBoardPack(
  lessonId: '5.7',
  titleBn: 'রাতের বেলা ফল্ট খোঁজার কৌশল',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'মাঝরাতে ফল্ট! অন্ধকার শত্রু, আবার বন্ধুও — ঠিক কৌশলে খুঁজে বের করুন।',
  earnedBn: 'চার্জ করা আলো, সঙ্গী আর প্রতিফলক জ্যাকেট; ধীরে চলুন, আলো নিভিয়ে দেখুন, শুনুন, জিজ্ঞেস করুন।',
  slots: [
    LearnBoardSlot(
      id: 'prep',
      promptBn: 'রাতের টহলে বেরোনোর আগে কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'charged',
          labelBn: 'টর্চ, হেডল্যাম্প, ফোনের চার্জ দেখে নেওয়া',
          asset: 'assets/game/art/m5_board57/prep_charged.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pair',
          labelBn: 'প্রতিফলক জ্যাকেটে দুজন একসাথে',
          asset: 'assets/game/art/m5_board57/prep_pair.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'alone',
          labelBn: 'একাই রাতের টহলে বেরিয়ে পড়া',
          asset: 'assets/game/art/m5_board57/prep_alone.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাতে ফল্ট খুঁজতে কখনোই একা নয় — সুরক্ষা আর সাহায্যের জন্য একজন সঙ্গী জরুরি।',
        ),
        LearnBoardOption(
          id: 'dark',
          labelBn: 'রাস্তার পাশে কালো জ্যাকেটে দাঁড়ানো',
          asset: 'assets/game/art/m5_board57/prep_dark.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাস্তার পাশে প্রতিফলক জ্যাকেট অপরিহার্য — যাতে চালকরা দূর থেকে আপনাকে দেখতে পান।',
        ),
        LearnBoardOption(
          id: 'flicker',
          labelBn: 'নিভু নিভু টর্চ নিয়েই বেরিয়ে পড়া',
          asset: 'assets/game/art/m5_board57/prep_flicker.svg',
          scene: true,
          correct: false,
          rejectBn: 'বেরোনোর আগে টর্চ, হেডল্যাম্প আর ফোনের ব্যাটারি সম্পূর্ণ চার্জড কিনা দেখে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টর্চ, হেডল্যাম্প ও ফোনের চার্জ আগেই দেখে নিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রাতে ফল্ট খুঁজতে কখনো একা নয়, সঙ্গী লাগবে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'প্রতিফলক জ্যাকেটে চালকরা দূর থেকে দেখতে পান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টর্চের চার্জ পথে ফুরিয়ে গেলে তখন ভাবলেই হবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রাতে রাস্তা ফাঁকা, তাই জ্যাকেটের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একা গেলে তাড়াতাড়ি ফল্ট খুঁজে ফেরা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গাড়ির হেডলাইট থাকলে আলাদা টর্চ না নিলেও চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কালো জ্যাকেটে রাতে ঠান্ডা কম, সেটাই ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফোনের চার্জ রাতের টহলে কোনো কাজে আসে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'drive',
      promptBn: 'গাড়ি নিয়ে রাতের টহল — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'slow',
          labelBn: 'ধীরে গাড়ি: একজন চালান, অন্যজন সার্চলাইটে',
          asset: 'assets/game/art/m5_board57/drive_slow.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'binoc',
          labelBn: 'সার্চলাইটের আলোয় বাইনোকুলারে পোলের মাথা',
          asset: 'assets/game/art/m5_board57/drive_binoc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'headlights',
          labelBn: 'শুধু গাড়ির হেডলাইটে লাইন দেখা',
          asset: 'assets/game/art/m5_board57/drive_headlights.svg',
          scene: true,
          correct: false,
          rejectBn: 'গাড়ির হেডলাইট শুধু রাস্তা আলোকিত করে — পোলের ওপরে দেখতে ঘোরানো যায় এমন সার্চলাইট লাগে।',
        ),
        LearnBoardOption(
          id: 'crane',
          labelBn: 'চালক নিজেই গলা বাড়িয়ে লাইন দেখছেন',
          asset: 'assets/game/art/m5_board57/drive_crane.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুজন একসাথে টহল দিন: একজন গাড়ি চালাবেন, অন্যজন দুই পাশের লাইন দেখবেন।',
        ),
        LearnBoardOption(
          id: 'speed',
          labelBn: 'জোরে গাড়ি ছুটিয়ে টহল দেওয়া',
          asset: 'assets/game/art/m5_board57/drive_speed.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাতের টহল ধৈর্য আর পদ্ধতির কাজ, গতির নয় — গাড়ির গতি কম রাখুন।',
        ),
        LearnBoardOption(
          id: 'track',
          labelBn: 'অচেনা কাদা রাস্তায় শর্টকাট',
          asset: 'assets/game/art/m5_board57/drive_track.svg',
          scene: true,
          correct: false,
          rejectBn: 'সম্ভব হলে পরিচিত ও নিরাপদ রাস্তা দিয়ে টহল দিন — রাতে শর্টকাট নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একজন গাড়ি চালাবেন, অন্যজন লাইন দেখবেন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পোলের মাথা দেখতে ঘোরানো সার্চলাইট লাগে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সঠিক সরঞ্জাম ছাড়া রাতে ফল্ট খোঁজা প্রায় অসম্ভব', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'গাড়ির হেডলাইটেই পোলের মাথা ভালো দেখা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চালক নিজেই গলা বাড়িয়ে লাইন দেখে নিতে পারেন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জোরে চালালে কম সময়ে বেশি লাইন দেখা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অচেনা কাঁচা রাস্তায় শর্টকাটে সময় বাঁচে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাতের অন্ধকারে বাইনোকুলার কাজে লাগে না', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'সার্চলাইট শুধু রাস্তা দেখার জন্যই রাখা হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'eyes',
      promptBn: 'দূরের হালকা আভা দেখতে কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'dark',
          labelBn: 'আলো নিভিয়ে স্থির দাঁড়িয়ে অপেক্ষা',
          asset: 'assets/game/art/m5_board57/eyes_dark.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'glow',
          labelBn: 'অপেক্ষার পর হালকা নীল আভা চোখে পড়া',
          asset: 'assets/game/art/m5_board57/eyes_glow.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'beam',
          labelBn: 'ইনসুলেটরে টর্চ ধরে রাখা',
          asset: 'assets/game/art/m5_board57/eyes_beam.svg',
          scene: true,
          correct: false,
          rejectBn: 'উজ্জ্বল টর্চের পর আলো নিভিয়ে কিছুক্ষণ অপেক্ষা করুন — চোখ অভ্যস্ত হলে হালকা করোনা দেখা যায়।',
        ),
        LearnBoardOption(
          id: 'flick',
          labelBn: 'টর্চ বারবার জ্বালানো-নেভানো',
          asset: 'assets/game/art/m5_board57/eyes_flick.svg',
          scene: true,
          correct: false,
          rejectBn: 'আলো নিভিয়ে কিছুক্ষণ অপেক্ষা করুন, যাতে চোখ আবার অন্ধকারের সাথে অভ্যস্ত হয়।',
        ),
        LearnBoardOption(
          id: 'midday',
          labelBn: 'দুপুরের রোদে করোনা খোঁজা',
          asset: 'assets/game/art/m5_board57/eyes_midday.svg',
          scene: true,
          correct: false,
          rejectBn: 'করোনা দিনের বেলায় অদৃশ্য থাকে — রাতের অন্ধকারে অনেক দূর থেকে দেখা যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আলো নিভিয়ে অপেক্ষা করলে চোখ অন্ধকারে সয়ে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চোখ সয়ে গেলে হালকা করোনা বা স্পার্ক চোখে পড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'করোনা দিনে অদৃশ্য, রাতে অনেক দূর থেকে দেখা যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টর্চ ইনসুলেটরে ধরে রাখলেই করোনা ভালো দেখা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টর্চ বারবার জ্বালালে-নেভালে চোখ দ্রুত সয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুপুরের কড়া রোদেই করোনা সবচেয়ে স্পষ্ট দেখা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অন্ধকারে চোখ সয়ে নিতে কোনো সময়ই লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'উজ্জ্বল আলোর ঠিক পরেই হালকা আভা ভালো দেখায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'করোনা দেখতে টর্চ সবসময় জ্বালিয়ে রাখতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'clue',
      promptBn: 'কোন ছবিতে ফল্টের সূত্র ঠিক চেনা হয়েছে?',
      options: [
        LearnBoardOption(
          id: 'corona',
          labelBn: 'ভাঙা ইনসুলেটরে নীল-বেগুনি আভা দেখানো',
          asset: 'assets/game/art/m5_board57/clue_corona.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tracking',
          labelBn: 'নীলচে ট্র্যাকিং দেখে খারাপ ধরা',
          asset: 'assets/game/art/m5_board57/clue_tracking.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'flash',
          labelBn: 'বাসিন্দার দেখা ঝলকানির পোলে আলো ফেলা',
          asset: 'assets/game/art/m5_board57/clue_flash.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'glint',
          labelBn: 'টর্চের ঝিলিককে করোনা ভাবা',
          asset: 'assets/game/art/m5_board57/clue_glint.svg',
          scene: true,
          correct: false,
          rejectBn: 'করোনা হলো ক্ষতিগ্রস্ত ইনসুলেটরের চারপাশে হালকা নীল বা বেগুনি আভা — টর্চের প্রতিফলন নয়।',
        ),
        LearnBoardOption(
          id: 'fine',
          labelBn: 'ট্র্যাকিং দেখেও ঠিক আছে ভেবে চলে যাওয়া',
          asset: 'assets/game/art/m5_board57/clue_fine.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটরের গায়ে নীলচে ট্র্যাকিং প্রমাণ করে যে ইনসুলেটরটি খারাপ হয়ে গেছে।',
        ),
        LearnBoardOption(
          id: 'ignored',
          labelBn: 'ঝলকানি দেখেও পাশ কাটিয়ে যাওয়া',
          asset: 'assets/game/art/m5_board57/clue_ignored.svg',
          scene: true,
          correct: false,
          rejectBn: 'আলোর ঝলকানি বা ফ্ল্যাশ ফল্টের সঠিক অবস্থান নির্দেশ করতে পারে — সেখানেই খুঁজুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দিনে যা চোখে পড়ে না, রাতে সেই সূত্র দেখা যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অন্ধকারকে ডায়াগনস্টিক টুল হিসেবে কাজে লাগানো যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল পথের বিদ্যুৎ আলো বা স্পার্কের মতো সূত্র রেখে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টর্চের আলোয় চকচকে ঝিলিকই আসল করোনার চিহ্ন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ট্র্যাকিং দেখা গেলেও ইনসুলেটর ঠিকঠাকই থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাসিন্দার দেখা ঝলকানি ফল্ট খোঁজায় কাজে আসে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নীলচে আভা রাতে চোখের ভুল, তাতে মন দেবেন না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ঝলকানি একবার দেখা দিয়ে গেলে আর ফল্ট থাকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ইনসুলেটরের ট্র্যাকিং শুধু দিনের আলোতেই দেখা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sense',
      promptBn: 'রাতের নিস্তব্ধতায় আর কী কাজে আসে?',
      options: [
        LearnBoardOption(
          id: 'listen',
          labelBn: 'পোলের হিসহিস শব্দ কান পেতে শোনা',
          asset: 'assets/game/art/m5_board57/sense_listen.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ask',
          labelBn: 'জেগে থাকা বাসিন্দাকে জিজ্ঞেস করা',
          asset: 'assets/game/art/m5_board57/sense_ask.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pass',
          labelBn: 'ডাকা বাসিন্দার দিকে পিঠ ফিরিয়ে থাকা',
          asset: 'assets/game/art/m5_board57/sense_pass.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্থানীয় বাসিন্দারা প্রায়ই জেগে থাকেন — জিজ্ঞাসা করুন তারা কোনো শব্দ বা আলো দেখেছেন কিনা।',
        ),
        LearnBoardOption(
          id: 'field',
          labelBn: 'আলো ছাড়া অন্ধকার মাঠ পার হওয়া',
          asset: 'assets/game/art/m5_board57/sense_field.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাতে হোঁচট খাওয়া বা গর্তে পড়ার ঝুঁকি বেড়ে যায় — তাড়াহুড়ো বা শর্টকাট নয়।',
        ),
        LearnBoardOption(
          id: 'run',
          labelBn: 'তাড়াতাড়ি শেষ করতে দৌড়ানো',
          asset: 'assets/game/art/m5_board57/sense_run.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাতে সুরক্ষার নিয়ম দ্বিগুণ কঠোরভাবে মানুন — তাড়াহুড়ো বা শর্টকাট চলবে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিস্তব্ধ রাতে হিসহিস শব্দ আর বাসিন্দার খবর দুটোই সূত্র', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অস্বাভাবিক শব্দ বা আলো ফল্টের জায়গা চিনিয়ে দিতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রাতের টহল ধৈর্য আর পদ্ধতির ওপর নির্ভর করে, গতির নয়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'পোলের হিসহিস শব্দ রাতে সবসময়ই স্বাভাবিক ব্যাপার', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাসিন্দাদের কথায় সময় নষ্ট, নিজেই খুঁজে নিন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চেনা মাঠ হলে অন্ধকারেও আলো ছাড়া পার হওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'দৌড়ে তাড়াতাড়ি কাজ সেরে ফেললে রাতের ঝুঁকি কমে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাতে শব্দ শুনে ফল্টের জায়গা খুঁজে বের করা যায় না', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'ক্লান্ত শরীরেও রাতে ঝটপট সিদ্ধান্ত নিয়ে ফেলুন', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board57Lines.rivalTaunt,
    rivalLineBn: M5Board57Lines.rivalMyth,
    exitBn: M5Board57Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    flipStingBn: 'এই লোক যা বলছে… সেটা কি ভুল?',
    dangerHints: [
      'রাতের স্পার্ক-করোনা সূত্র হাতছাড়া',
      'জরুরি পরিষেবায় দেরি',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'স্পার্ক বা করোনার সূত্র রাতেই সবচেয়ে ভালো দেখা যায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'বিদ্যুৎ ফেরানো জরুরি পরিষেবা, তাই দ্রুত ফল্ট খুঁজুন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'অন্ধকারকে কাজে লাগিয়েই রাতে ফল্ট খুঁজে বের করা যায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'রাতে তো কিছুই দেখা যায় না, সকালেই সব খোঁজা ভালো', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'বিদ্যুৎ ফেরানোর কাজ সকাল পর্যন্ত অপেক্ষা করতে পারে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'করোনা আর স্পার্ক দিনের আলোতেই বেশি স্পষ্ট দেখা যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'রাতের টহলে শুধু শুধু সময় আর গাড়ির তেল নষ্ট হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'রাতের অন্ধকারে ফল্টের কোনো সূত্রই চোখে পড়ে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'গ্রাহকরা রাতে ঘুমিয়ে থাকেন, তাই তাড়ার কিছু নেই', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board, in his recorded voice only
/// ([rivalExit] is already recorded; [toRecord] stay silent with the bubble
/// held for reading until the director records them with tool/rival_clip.py).
abstract final class M5Board57Lines {
  static const rivalTaunt = 'এই অন্ধকারে টহল? বাড়ি যান, সকালে দেখা যাবে!';

  /// Lesson 5.7's first myth buster, word for word.
  static const rivalMyth = 'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
