import 'learn_board_models.dart';

/// Module 7 Lesson 7.4 (পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি চুক্তি), the
/// picture board (rung `7.4/learn`, pack `learn_7_4`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board74_art.py` (no words in
/// the art; the PTW number and the logbook times are stroke glyphs with
/// English digits). Every round and trap comes from the live lesson text
/// (`tool/all_training_chapters_bn.json`, 7.4) and the Module 7 rulings
/// (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_74.json`):
///  * sign: section point 2 — the issuer (usually the control-room operator)
///    signs that the line is isolated and locked; the receiver (usually the
///    field supervisor) signs that he knows the danger, will keep his team
///    safe and will hand the line back safe when the work is done. Traps: a
///    signature as a formality, the receiver leaving his team, the issuer's
///    box blank, the return signed with a man still on the pole;
///  * copies: pro tip 1 — every copy (control room, field team) filled and
///    signed. The field copy with no issuer signature is the module's deadly
///    act (ruling M7-2, row R1); boards have no freeze (kit design), so it
///    teaches with the myth's reality ('লিখিত, স্বাক্ষরিত PTW ছাড়া কাজ শুরু
///    করা মানেই আইন এবং সুরক্ষা—দুটোই লঙ্ঘন করা'). Two numbers and a blank
///    control-room copy are slips (R3);
///  * log: pro tip 3 — issue and cancellation times and dates in the formal
///    logbook, a legal document (a loose chit is R6);
///  * talk: pro tips 2 and 4 — clear talk at issue and return, ask again on
///    any doubt ('আমি ভেবেছিলাম...' has no place), a condition not understood
///    is explained before signing;
///  * crew: myth 2's reality — every team member knows the permit the work
///    runs under; joining work known to have no valid PTW makes you equally
///    liable; and the live safety tip: HT or LT, every shutdown job needs the
///    written permit (rulings X3, O1 — the field memo appears only in the
///    lesson's own words, in that trap's reason).
/// Ruling X6 trims the item spec's six rounds to five: round 6 (which
/// consequences are true) leaves the board.
/// The rival's myth is the lesson's first myth, word for word (ruling M7-10).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack74 = LearnBoardPack(
  lessonId: '7.4',
  titleBn: 'পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি চুক্তি',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board74Lines.intro,
  earnedBn: M7Board74Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'sign',
      promptBn: 'PTW-র সই — কোন সইটা ঠিকভাবে দায়িত্ব নিচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'issuer',
          labelBn: 'লাইন বিচ্ছিন্ন ও লক করে অপারেটরের সই',
          asset: 'assets/game/art/m7_board74/sign_issuer.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'receiver',
          labelBn: 'সুপারভাইজার টিমকে বিপদ বুঝিয়ে সই করছেন',
          asset: 'assets/game/art/m7_board74/sign_receiver.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ret',
          labelBn: 'সবাই নিচে নামার পরেই PTW ফেরতের সই',
          asset: 'assets/game/art/m7_board74/sign_ret.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'phone',
          labelBn: 'ফোনে চোখ রেখে না পড়েই সই করে দিলেন',
          asset: 'assets/game/art/m7_board74/sign_phone.svg',
          scene: true,
          correct: false,
          rejectBn: 'PTW-এর প্রতিটি স্বাক্ষর একটি আইনি দায়িত্বের প্রমাণ। এটি কোনো সাধারণ ফর্মালিটি নয়।',
        ),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'সই করে চায়ের দোকানে, টিম একা পোলে',
          asset: 'assets/game/art/m7_board74/sign_tea.svg',
          scene: true,
          correct: false,
          rejectBn: 'সই করে গ্রহণকারী আইনত দায়িত্ব নেন — তিনি তাঁর টিমের সুরক্ষা নিশ্চিত করবেন।',
        ),
        LearnBoardOption(
          id: 'blank',
          labelBn: 'ইস্যুকারীর ঘর ফাঁকা, শুধু গ্রহণকারীর সই',
          asset: 'assets/game/art/m7_board74/sign_blank.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইস্যুকারীর সই-ই আইনত নিশ্চিত করে যে লাইনটি বিচ্ছিন্ন এবং লক করা হয়েছে — সেই সই নেই।',
        ),
        LearnBoardOption(
          id: 'early',
          labelBn: 'পোলে এখনও লোক, তবু PTW ফেরতের সই দিলেন',
          asset: 'assets/game/art/m7_board74/sign_early.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শেষে লাইনটিকে নিরাপদ অবস্থায় ফেরত দেওয়া গ্রহণকারীর আইনি দায়িত্ব — পোলে লোক থাকতে নয়।',
        ),
      ],
      // The right reasons are rules for every signature of the round (the
      // issuer's, the receiver's, the return), since the runner deals them
      // whichever safe card was picked.
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিটি সই একটা আইনি দায়িত্বের প্রমাণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সই মানে দায় নেওয়া, শুধু ফর্মালিটি নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'যে সই করেন, তিনিই আইনত দায়ী থাকেন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সই তো একটা ফর্মালিটি, পড়ার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একজনের সই থাকলেই PTW পুরো বৈধ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সই করার পরে টিমের দায় আর তাঁর নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পোলে লোক থাকলেও PTW ফেরত দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ইস্যুকারীর সই ছাড়াও কাজ শুরু করা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যে কেউ সই করে দিলেই PTW চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'copies',
      promptBn: 'PTW-র কপি — কোনটা ঠিকভাবে তৈরি?',
      options: [
        LearnBoardOption(
          id: 'both',
          labelBn: 'দুই কপিতেই এক নম্বর, সব পূরণ, দুটো সই',
          asset: 'assets/game/art/m7_board74/copies_both.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'field',
          labelBn: 'দুই সই-সহ ফিল্ড কপি টিমের হাতেই আছে',
          asset: 'assets/game/art/m7_board74/copies_field.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nosign',
          labelBn: 'টিমের ফিল্ড কপিতে ইস্যুকারীর সই নেই',
          asset: 'assets/game/art/m7_board74/copies_nosign.svg',
          scene: true,
          correct: false,
          // The module's deadly act (M7-2, R1); myth 1's reality, word for word.
          rejectBn: 'লিখিত, স্বাক্ষরিত PTW ছাড়া কাজ শুরু করা মানেই আইন এবং সুরক্ষা—দুটোই লঙ্ঘন করা।',
        ),
        LearnBoardOption(
          id: 'twonum',
          labelBn: 'দুই কপিতে দুটো আলাদা PTW নম্বর লেখা',
          asset: 'assets/game/art/m7_board74/copies_twonum.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুই কপিতে দুই নম্বর মানে কপি ঠিকভাবে পূরণ হয়নি — প্রতিটি কপি সঠিকভাবে পূরণ ও সই করা চাই।',
        ),
        LearnBoardOption(
          id: 'blank',
          labelBn: 'কন্ট্রোল রুমের কপিতে তারিখ-সময় ফাঁকা',
          asset: 'assets/game/art/m7_board74/copies_blank.svg',
          scene: true,
          correct: false,
          // Pro tip 1, word for word.
          rejectBn: 'প্রতিটি কপি (কন্ট্রোল রুম, ফিল্ড টিম) সঠিকভাবে পূরণ করা এবং স্বাক্ষর করা হয়েছে কিনা তা নিশ্চিত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিটি কপি ঠিকভাবে পূরণ আর সই করা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কন্ট্রোল রুম আর ফিল্ডের কপি সমান জরুরি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সই ছাড়া ফিল্ড কপি নিয়ে কাজে নামা নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটা কপিতে সই থাকলেই বাকিগুলো চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফিল্ড কপি শুধু দেখানোর, সই না হলেও চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কপির নম্বর আলাদা হলেও কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অফিসের কপি অর্ধেক ফাঁকা থাকলেও চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সময়টা পরে মনে করে লিখে দিলেই হলো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মুখে বলে দিলে কপিতে সই না হলেও চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'log',
      promptBn: 'PTW-র লগবুক — কোন রেকর্ডটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'issue',
          labelBn: 'লগবুকে PTW ইস্যুর তারিখ ও সময় লেখা',
          asset: 'assets/game/art/m7_board74/log_issue.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cancel',
          labelBn: 'লগবুকে PTW বাতিলের তারিখ ও সময় লেখা',
          asset: 'assets/game/art/m7_board74/log_cancel.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'notime',
          labelBn: 'PTW ইস্যু হয়েছে, লগবুকে সময় ফাঁকা',
          asset: 'assets/game/art/m7_board74/log_notime.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি PTW ইস্যুর সময় এবং তারিখ আনুষ্ঠানিক লগবুকে নথিভুক্ত করা হয়।',
        ),
        LearnBoardOption(
          id: 'nocancel',
          labelBn: 'PTW ফেরত এসেছে, বাতিলের ঘর ফাঁকা',
          asset: 'assets/game/art/m7_board74/log_nocancel.svg',
          scene: true,
          correct: false,
          rejectBn: 'PTW বাতিলের সময় এবং তারিখও আনুষ্ঠানিক লগবুকে নথিভুক্ত করতে হয়।',
        ),
        LearnBoardOption(
          id: 'chit',
          labelBn: 'সময়টা লেখা হলো একটা খোলা চিরকুটে',
          asset: 'assets/game/art/m7_board74/log_chit.svg',
          scene: true,
          correct: false,
          rejectBn: 'সময় লিখতে হয় আনুষ্ঠানিক লগবুকে — এটি একটি গুরুত্বপূর্ণ আইনি নথি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ইস্যু-বাতিল দুটোরই সময়-তারিখ লগবুকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লগবুক একটা গুরুত্বপূর্ণ আইনি নথি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আনুষ্ঠানিক লগবুকে লেখা, চিরকুটে নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শুধু ইস্যুর সময়টা লিখলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাতিলের সময় লেখা শুধু অফিসের ঝামেলা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চিরকুটে লিখে রাখলেও একই কাজ হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সময় মনে থাকলে খাতায় লেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লগবুক শুধু হিসাবের খাতা, আইনি কিছু নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কাজ শেষ হলে লগবুক আর কেউ দেখে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'talk',
      promptBn: 'PTW ইস্যু বা ফেরতের সময় — কোন কথাবার্তাটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'ask',
          labelBn: 'সন্দেহ হতেই ইস্যুকারীকে আবার জিজ্ঞাসা',
          asset: 'assets/game/art/m7_board74/talk_ask.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'learn',
          labelBn: 'না-বোঝা শর্ত আগে বুঝে নিয়ে, তারপর সই',
          asset: 'assets/game/art/m7_board74/talk_learn.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thought',
          labelBn: 'কর্মী বলছেন, আমি ভেবেছিলাম লাইন বন্ধ',
          asset: 'assets/game/art/m7_board74/talk_thought.svg',
          scene: true,
          correct: false,
          // Pro tip 2, word for word.
          rejectBn: "কোনো সন্দেহ থাকলে, বারবার জিজ্ঞাসা করুন। 'আমি ভেবেছিলাম...'—এই কথাটির কোনো জায়গা এখানে নেই।",
        ),
        LearnBoardOption(
          id: 'blind',
          labelBn: 'শর্তটা বোঝেননি, তবু সই করে দিলেন',
          asset: 'assets/game/art/m7_board74/talk_blind.svg',
          scene: true,
          correct: false,
          rejectBn: 'যে শর্ত বুঝতে পারছেন না, স্বাক্ষর করার আগে সুপারভাইজারের কাছ থেকে তা বুঝে নিন।',
        ),
        LearnBoardOption(
          id: 'noisy',
          labelBn: 'ফোনে আধা শুনেই বললেন, হ্যাঁ ঠিক আছে',
          asset: 'assets/game/art/m7_board74/talk_noisy.svg',
          scene: true,
          correct: false,
          rejectBn: 'PTW ইস্যু আর ফেরতের কথা পরিষ্কার ও দ্ব্যর্থহীন হতে হবে — সন্দেহ থাকলে আবার জিজ্ঞাসা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'PTW-র কথা হবে পরিষ্কার আর দ্ব্যর্থহীন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সন্দেহ থাকলে বারবার জিজ্ঞাসা করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'না-বোঝা শর্ত সই করার আগে বুঝে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বারবার জিজ্ঞাসা করলে লোকে বোকা ভাবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আন্দাজে বুঝে নিলেও কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শর্ত না বুঝলেও সই করলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফোনে আধা শুনলেও মোটামুটি বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভেবেছিলাম বললেই দায় থেকে ছাড় মেলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সুপারভাইজারকে প্রশ্ন করা ঠিক নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'crew',
      promptBn: 'কাজে নামার আগে — টিমের সদস্য হিসেবে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'read',
          labelBn: 'ফিল্ড কপিতে PTW নম্বর দেখে জেনে নেওয়া',
          asset: 'assets/game/art/m7_board74/crew_read.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'stand',
          labelBn: 'বৈধ PTW নেই, তাই কাজে হাত দিচ্ছেন না',
          asset: 'assets/game/art/m7_board74/crew_stand.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dontknow',
          labelBn: 'PTW সুপারভাইজারের ব্যাপার, জেনে কী হবে',
          asset: 'assets/game/art/m7_board74/crew_dontknow.svg',
          scene: true,
          correct: false,
          // Myth 2's reality, word for word.
          rejectBn: 'টিমের প্রত্যেক সদস্যের জানা উচিত কোন পারমিটের অধীনে কাজ চলছে।',
        ),
        LearnBoardOption(
          id: 'ladder',
          labelBn: 'PTW নেই জেনেও মই ধরে সাহায্য করছেন',
          asset: 'assets/game/art/m7_board74/crew_ladder.svg',
          scene: true,
          correct: false,
          rejectBn: 'বৈধ PTW ছাড়া কাজ হচ্ছে জেনেও তাতে অংশ নিলে, দুর্ঘটনায় আপনিও সমানভাবে দায়ী হতে পারেন।',
        ),
        LearnBoardOption(
          id: 'lt',
          labelBn: 'LT লাইন বলে PTW ছাড়াই কাজ শুরু',
          asset: 'assets/game/art/m7_board74/crew_lt.svg',
          scene: true,
          correct: false,
          // The live safety tip (ruling X3), LT / HT in English letters.
          rejectBn: 'HT হোক বা LT—শাটডাউন নিয়ে যেকোনো লাইনে কাজের আগে লিখিত অনুমতি (PTW, বা কোম্পানির নিয়মে যেখানে চলে সেখানে ফিল্ড মেমো) নিতেই হবে।',
        ),
      ],
      // Rules for both safe acts (reading the permit, standing back with no
      // valid permit); the LT tip and the liability line stay in the traps'
      // reasons.
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কোন পারমিটে কাজ, টিমের সবার জানা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বৈধ PTW আছে জেনে তবেই কাজে হাত দিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'PTW-র দায় শুধু সুপারভাইজারের নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পারমিট শুধু সুপারভাইজারের মাথাব্যথা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অন্যরা কাজ করলে আমার কোনো দায় নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'LT লাইনের শাটডাউনে PTW লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মই ধরা তো কাজ নয়, তাই দায়ও নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পারমিট নম্বর জানা শুধু অফিসের কাজ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সবাই কাজে নামলে আমারও নামা উচিত', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board74Lines.rivalTaunt,
    rivalLineBn: M7Board74Lines.rivalMyth,
    exitBn: M7Board74Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board74Lines.sting,
    dangerHints: [
      'ভুল বোঝাবুঝি',
      'আইন ও সুরক্ষা লঙ্ঘন',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মৌখিক নির্দেশের কোনো আইনি ভিত্তি নেই', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'মুখের কথাতেই ভুল বোঝাবুঝি বেশি হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লিখিত, সই করা PTW ছাড়া কাজ শুরু নয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'সুপারভাইজার বললে কাগজ লাগে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ফোনে বলা আর লিখিত PTW একই জিনিস', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'চেনা লোকের কথায় ভরসাই যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'কাগজের পারমিট শুধু সময় নষ্ট করে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'লাইন বন্ধ শুনলেই কাজে নামা যায়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'কাগজ পরে করে নিলেও কোনো ক্ষতি নেই', correct: false),
    ],
  ),
);

/// The board's spoken lines: the careless coworker's (his recorded voice) and
/// the guide's. [rivalExit] and [sting] are already recorded (so neither is
/// in [toRecord] or [guideSpoken]); the rest wait
/// for the voice session (ruling M7-10), silent with the caption held until
/// then (the rival never falls back to the device voice).
abstract final class M7Board74Lines {
  /// DRAFT wording — owner.
  static const intro = 'PTW শুধু অফিসের নিয়ম নয়, এটা আইনি নথি। সই, কপি, লগবুক আর কথাবার্তা — ঠিকটা চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'লিখিত, সই করা PTW ছাড়া কাজ নয়; প্রতিটি সই একটা আইনি দায়িত্ব — সন্দেহ হলে আবার জিজ্ঞাসা করুন।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'সাহেব তো মুখেই বলে দিয়েছেন! কাগজ-টাগজ পরে হবে।';

  /// Lesson 7.4's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'সুপারভাইজার মুখে মুখে বলে দিয়েছেন লাইন বন্ধ আছে, তাই আর কাগজের পারমিটের দরকার নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

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

  /// Every new line the guide speaks on this board (intro, round prompts,
  /// trap reasons, right reasons, the myth's right reasons, the earned line).
  /// The sting is already recorded and left out, as in M6Board63Lines.
  static List<String> get guideSpoken {
    final p = learnBoardPack74;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
