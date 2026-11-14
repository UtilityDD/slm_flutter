import 'learn_board_models.dart';

/// Module 3 Lesson 3.6 (ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড),
/// the picture board (rung `3.6/learn`, pack `learn_3_6`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board36_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * side: HT (11kV) bushings are much bigger than LT (415V) ones and have
///    more creepage — that is how the HT side is told; the conservator (room
///    for the oil to expand) and the breather (silica gel) are not bushings;
///  * gel: good, dry silica gel is blue or orange; after soaking up moisture
///    it turns pink or white — time to change it. The empty breather is an
///    inferred trap (the gel is what absorbs the moisture);
///  * sign: a mild, steady humming is normal (magnetostriction); knocking or
///    growling means a serious fault inside; oil leaks at the bushing gasket
///    or the drain valve; a very low oil level overheats the transformer;
///  * tap: the off-load tap changer is turned only with the transformer off
///    from both sides, HT and LT (film script);
///  * earth: body, neutral and LA earthing — all three vital; one weak and the
///    whole system's protection is compromised; before work on the body or
///    tank make sure it is earthed.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack36 = LearnBoardPack(
  lessonId: '3.6',
  titleBn: 'ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'DTR লাইনের হৃৎপিণ্ড — 11kV নামিয়ে আনে 415/240V-এ। চোখ-কান দিয়ে এর স্বাস্থ্য বুঝুন।',
  earnedBn: 'বড় বুশিং HT, নীল বা কমলা জেল ঠিক, মৃদু হামিং স্বাভাবিক — ট্যাপ দুদিক বন্ধ করে, তিন আর্থিং নিখুঁত।',
  slots: [
    LearnBoardSlot(
      id: 'side',
      promptBn: 'DTR-এর সামনে দাঁড়িয়ে — কোনটা HT (11kV) বুশিং দেখাচ্ছেন?',
      options: [
        LearnBoardOption(
          id: 'ht',
          labelBn: 'লম্বা, বড় পোর্সেলিন বুশিং',
          asset: 'assets/game/art/m3_board36/side_ht.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'htr',
          labelBn: 'বেশি ক্রিপেজের বড় বুশিং',
          asset: 'assets/game/art/m3_board36/side_htr.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lt',
          labelBn: 'ছোট, বেঁটে বুশিংগুলো',
          asset: 'assets/game/art/m3_board36/side_lt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছোটগুলো LT (415V) বুশিং — HT বুশিং আকারে অনেক বড়, ক্রিপেজ ডিসটেন্সও বেশি।',
        ),
        LearnBoardOption(
          id: 'cons',
          labelBn: 'ওপরের তেলের ড্রাম',
          asset: 'assets/game/art/m3_board36/side_cons.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওটা কনজারভেটর ট্যাঙ্ক — তেলের প্রসারণ-সংকোচনের জায়গা, বুশিং নয়।',
        ),
        LearnBoardOption(
          id: 'breather',
          labelBn: 'ড্রামের পাশের ছোট পাত্র',
          asset: 'assets/game/art/m3_board36/side_breather.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওটা ব্রিদার — ভেতরের সিলিকা জেল বাতাসের জলীয় বাষ্প শোষণ করে, বুশিং নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'HT বুশিং LT বুশিংয়ের চেয়ে আকারে অনেক বড়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'HT বুশিংয়ের ক্রিপেজ ডিসটেন্স বেশি হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বুশিংয়ের মাপ দেখেই HT আর LT সাইড চেনা যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট বুশিং দিয়েই 11kV ঢোকে ট্রান্সফরমারে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কনজারভেটর ট্যাঙ্কটাই আসলে HT বুশিং', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ব্রিদারের পাত্র দিয়েই HT লাইন ঢোকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সব বুশিং একই মাপের, চেনার উপায় নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'LT বুশিংয়ের ক্রিপেজ ডিসটেন্স বেশি হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বুশিং লোহার তৈরি, ওটা ইনসুলেটর নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'gel',
      promptBn: 'ব্রিদারের কাচে সিলিকা জেল দেখছেন — কোনটা মানে জেল ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'blue',
          labelBn: 'নীল, শুকনো সিলিকা জেল',
          asset: 'assets/game/art/m3_board36/gel_blue.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'orange',
          labelBn: 'কমলা, শুকনো সিলিকা জেল',
          asset: 'assets/game/art/m3_board36/gel_orange.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pink',
          labelBn: 'গোলাপি হয়ে যাওয়া জেল',
          asset: 'assets/game/art/m3_board36/gel_pink.svg',
          scene: true,
          correct: false,
          rejectBn: 'জলীয় বাষ্প শুষে জেল গোলাপি হয়েছে — মানে এটা বদলানোর সময়।',
        ),
        LearnBoardOption(
          id: 'white',
          labelBn: 'সাদা হয়ে যাওয়া জেল',
          asset: 'assets/game/art/m3_board36/gel_white.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাষ্প শুষে জেল সাদা হয়ে গেছে — বদলানোর সময় হয়েছে, ফেলে রাখবেন না।',
        ),
        LearnBoardOption(
          id: 'empty',
          labelBn: 'জেল ছাড়া খালি ব্রিদার',
          asset: 'assets/game/art/m3_board36/gel_empty.svg',
          scene: true,
          correct: false,
          rejectBn: 'সিলিকা জেলই ঢোকা বাতাস থেকে জলীয় বাষ্প শোষণ করে — খালি ব্রিদার কাজের নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভালো, শুকনো সিলিকা জেলের রং নীল বা কমলা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সিলিকা জেল বাতাসের জলীয় বাষ্প শোষণ করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জেল গোলাপি বা সাদা হলে বদলানোর সময়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গোলাপি জেল মানে জেল একদম নতুন আর শুকনো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জেলের রং বদলালেও কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সাদা জেলই সবচেয়ে বেশি বাষ্প শুষতে পারে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্রিদার লাগানো হয় তেল ঠান্ডা রাখতে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জেল ছাড়াও ব্রিদার একইভাবে কাজ করে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নীল জেল দেখলেই সঙ্গে সঙ্গে বদলাতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sign',
      promptBn: 'পেট্রোলিংয়ে দূর থেকে DTR দেখছেন, শুনছেন — কোনটা সুস্থতার লক্ষণ?',
      options: [
        LearnBoardOption(
          id: 'hum',
          labelBn: 'মৃদু, একটানা হামিং শব্দ',
          asset: 'assets/game/art/m3_board36/sign_hum.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'তেলের লেভেল ঠিক, ট্যাঙ্ক শুকনো',
          asset: 'assets/game/art/m3_board36/sign_dry.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'knock',
          labelBn: 'খটখট আর গরগর শব্দ',
          asset: 'assets/game/art/m3_board36/sign_knock.svg',
          scene: true,
          correct: false,
          rejectBn: 'খটখট বা গরগর শব্দ মানে ভেতরে গুরুতর সমস্যা — যেমন লুজ কানেকশন বা শর্ট সার্কিট।',
        ),
        LearnBoardOption(
          id: 'drain',
          labelBn: 'ড্রেন ভাল্ভ থেকে তেল চুঁইছে',
          asset: 'assets/game/art/m3_board36/sign_drain.svg',
          scene: true,
          correct: false,
          rejectBn: 'ড্রেন ভাল্ভ, ওয়েল্ডিং জয়েন্ট বা গ্যাসকেট — যেখান থেকেই হোক, তেল লিক বিপদের লক্ষণ।',
        ),
        LearnBoardOption(
          id: 'gasket',
          labelBn: 'বুশিংয়ের গ্যাসকেটে তেল লিক',
          asset: 'assets/game/art/m3_board36/sign_gasket.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্যাসকেট দিয়ে তেল লিক — তেল কমলে কুলিং আর ইনসুলেশন দুটোই দুর্বল হয়।',
        ),
        LearnBoardOption(
          id: 'low',
          labelBn: 'ইন্ডিকেটরে তেল প্রায় নেই',
          asset: 'assets/game/art/m3_board36/sign_low.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেলের লেভেল খুব কমে গেলে ট্রান্সফরমার অতিরিক্ত গরম হয়ে যাবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মৃদু, স্থির হামিং কোরের স্বাভাবিক শব্দ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তেলের লেভেল খুব কমলে ট্রান্সফরমার গরম হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'খটখট বা গরগর শব্দ মানে ভেতরে গুরুতর ফল্ট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো হামিং শব্দ মানেই ভেতরে বড় সমস্যা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'খটখট শব্দ ট্রান্সফরমারের স্বাভাবিক গান', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অল্প তেল চুঁইয়ে পড়লে চিন্তার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তেলের লেভেল কমলে ট্রান্সফরমার ঠান্ডা থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ড্রেন ভাল্ভ দিয়ে তেল পড়াটা স্বাভাবিক', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'শব্দ শুনে ট্রান্সফরমারের কিছুই বোঝা যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tap',
      promptBn: 'আউটপুট ভোল্টেজ ঠিক করতে ট্যাপ চেঞ্জার ঘোরাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'turn',
          labelBn: 'HT ও LT বন্ধ করে ট্যাপ ঘোরানো',
          asset: 'assets/game/art/m3_board36/tap_turn.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'check',
          labelBn: 'আগে দেখে নেওয়া HT ও LT দুদিক বন্ধ',
          asset: 'assets/game/art/m3_board36/tap_check.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'চালু ট্রান্সফরমারেই ট্যাপ ঘোরানো',
          asset: 'assets/game/art/m3_board36/tap_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'এটা অফ-লোড ট্যাপ চেঞ্জার — চালু অবস্থায় নয়, HT ও LT দুদিক বন্ধ করে তবেই।',
        ),
        LearnBoardOption(
          id: 'lt',
          labelBn: 'শুধু LT বন্ধ করে ট্যাপ ঘোরানো',
          asset: 'assets/game/art/m3_board36/tap_lt.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু LT বন্ধ যথেষ্ট নয় — HT দিকে 11kV রয়ে গেছে। দুদিকই বন্ধ চাই।',
        ),
        LearnBoardOption(
          id: 'ht',
          labelBn: 'শুধু HT খুলে, LT চালু রেখে',
          asset: 'assets/game/art/m3_board36/tap_ht.svg',
          scene: true,
          correct: false,
          rejectBn: 'LT চালু রেখে নয় — ট্যাপ ঘোরাবেন শুধু HT ও LT দুদিক থেকে বন্ধ করে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অফ-লোড ট্যাপ চেঞ্জার ঘোরে শুধু বন্ধ অবস্থায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ট্যাপ ঘোরানোর আগে HT ও LT দুদিকই বন্ধ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ট্যাপ চেঞ্জারে আউটপুট ভোল্টেজ অ্যাডজাস্ট হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লোড চলাকালীন ট্যাপ ঘোরানোই আসল নিয়ম', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শুধু LT বন্ধ করলেই ট্যাপ ঘোরানো যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'HT খোলা থাকলে LT চালু রাখলেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্যাপ ঘোরালে ট্রান্সফরমারের kVA বাড়ে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চালু ট্রান্সফরমারের ট্যাপে হাত দিলে বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ট্যাপ ঘোরাতে কোনো সুইচ বন্ধের দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'earth',
      promptBn: 'ট্যাঙ্কে কাজের আগে DTR-এর আর্থিং দেখছেন — কোনটা ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'all',
          labelBn: 'বডি, নিউট্রাল, LA — তিনটেই জোড়া',
          asset: 'assets/game/art/m3_board36/earth_all.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pits',
          labelBn: 'তিনটে আর্থ পিটেই তার মজবুত',
          asset: 'assets/game/art/m3_board36/earth_pits.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'body',
          labelBn: 'বডির আর্থের তার কাটা',
          asset: 'assets/game/art/m3_board36/earth_body.svg',
          scene: true,
          correct: false,
          rejectBn: 'বডি ঠিকমতো আর্থ না থাকলে ট্যাঙ্কে কাজ নয় — বডি, নিউট্রাল, LA তিনটেই জরুরি।',
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'নিউট্রালের আর্থ খোলা',
          asset: 'assets/game/art/m3_board36/earth_neutral.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিউট্রালের আর্থ খোলা — যেকোনো একটা দুর্বল হলেই পুরো সিস্টেমের সুরক্ষা বিঘ্নিত।',
        ),
        LearnBoardOption(
          id: 'arrester',
          labelBn: 'LA-র আর্থের তার ছেঁড়া',
          asset: 'assets/game/art/m3_board36/earth_arrester.svg',
          scene: true,
          correct: false,
          rejectBn: 'LA-র আর্থও তিন আর্থিংয়ের একটা — একটা দুর্বল হলেই সুরক্ষা বিঘ্নিত হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বডি, নিউট্রাল আর LA — তিন আর্থিংই জরুরি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'একটা আর্থ দুর্বল হলেই পুরো সুরক্ষা বিঘ্নিত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ট্যাঙ্কে কাজের আগে বডির আর্থিং নিশ্চিত করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তিনটের মধ্যে দুটো আর্থ ঠিক থাকলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নিউট্রালের আর্থ খোলা থাকলেও কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'LA-র আর্থ ছাড়াও LA একই কাজ করে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বডির আর্থ শুধু দেখানোর জন্য লাগানো থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নতুন ট্রান্সফরমারে কোনো আর্থিং লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আর্থের তার ছিঁড়ে গেলেও পরে দেখলেই হবে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board36Lines.rivalTaunt,
    rivalLineBn: M3Board36Lines.rivalMyth,
    exitBn: M3Board36Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'চুঁইয়ে পড়া তেল',
      'কমতে থাকা তেলের লেভেল',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'তেল লিক মানে লেভেল কমা, কুলিং দুর্বল হওয়া', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'লিক দিয়ে ঢোকা বাষ্প তেলের ডাই-ইলেকট্রিক নষ্ট করে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ইনসুলেশন দুর্বল হয়ে ট্রান্সফরমার জ্বলে যেতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'তেল শেষ না হওয়া পর্যন্ত লিকে কোনো ক্ষতি নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'তেল কমলেও কুলিং আর ইনসুলেশন একদম একই থাকে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'লিক দিয়ে বাতাস ঢুকলে তেল আরও ভালো হয়ে যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'সামান্য লিক তো ট্রান্সফরমারের স্বাভাবিক ঘাম', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'তেল শুধু রং, ট্রান্সফরমারে তার কোনো কাজ নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'লিক হলে শুধু পরিবেশের ক্ষতি, যন্ত্রের কিছু নয়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board36Lines {
  static const rivalTaunt = 'আরে, দু-চার ফোঁটা তেল লিক করছে তো কী! ট্যাঙ্ক তো এখনও ভরা।';

  /// Lesson 3.6's first myth buster, word for word.
  static const rivalMyth = 'ট্রান্সফরমার থেকে তেল লিক করলে কিছু হয় না, যতক্ষণ না তেল শেষ হচ্ছে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
