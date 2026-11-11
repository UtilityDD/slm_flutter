import 'learn_board_models.dart';

/// Module 4 Lesson 4.6 (সঠিক আর্থিং (Earthing) পরীক্ষা ও রক্ষণাবেক্ষণ), the
/// picture board (rung `4.6/learn`, pack `learn_4_6`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board46_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * patrol: on line patrolling every pole's earthing is checked by eye — the
///    earth strip is not cut, stolen or badly rusted, its connections tight;
///  * measure: looking is not enough — an Earth Resistance Tester or Earth
///    Megger, Fall of Potential method with two spikes in the ground; a good
///    value is under 1 ohm at a substation and under 5–8 ohm on a distribution
///    line;
///  * tx: a transformer has double earthing (two separate pits) for its
///    neutral (system earthing) and its body (equipment earthing); earth
///    connections use brass or stainless-steel nuts and bolts;
///  * care: loose connections are cleaned, greased and tightened; in dry
///    weather water goes into the pit; the pit is kept clean and covered;
///  * soil: rocky or sandy soil — several electrodes, or charcoal and salt;
///    not just any iron rod (right material, right length).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack46 = LearnBoardPack(
  lessonId: '4.6',
  titleBn: 'সঠিক আর্থিং (Earthing) পরীক্ষা ও রক্ষণাবেক্ষণ',
  badgeBn: 'কাজের কারিগর',
  introBn: 'আর্থিং অদৃশ্য রক্ষক — ও ছাড়া ফিউজ, ব্রেকার, LA কিছুই কাজ করে না।',
  earnedBn: 'চোখে দেখে, ওহম মেপে, যত্ন নিয়ে — মজবুত আর্থিং-ই সুরক্ষার আসল শিকড়।',
  slots: [
    LearnBoardSlot(
      id: 'patrol',
      promptBn: 'লাইন পেট্রোলিং-এ পোলের আর্থিং দেখছেন — কোনটা ঠিক অবস্থা?',
      options: [
        LearnBoardOption(
          id: 'ok',
          labelBn: 'আস্ত আর্থ স্ট্রিপ, শক্ত করে লাগানো',
          asset: 'assets/game/art/m4_board46/patrol_ok.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'close_ok',
          labelBn: 'মরিচাহীন, টাইট আর্থ কানেকশন',
          asset: 'assets/game/art/m4_board46/patrol_close_ok.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'মাঝখানে কাটা আর্থ স্ট্রিপ',
          asset: 'assets/game/art/m4_board46/patrol_cut.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাটা স্ট্রিপে ফল্ট কারেন্ট মাটিতে নামার পথ পায় না — ব্রেকার ট্রিপ করবে না।',
        ),
        LearnBoardOption(
          id: 'stolen',
          labelBn: 'আর্থ স্ট্রিপ চুরি হয়ে গেছে',
          asset: 'assets/game/art/m4_board46/patrol_stolen.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্থিং তার চুরি একটা বড় সমস্যা — পেট্রোলিং-এ প্রতিটি পোলে চোখ রাখুন, সঙ্গে সঙ্গে জানান।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'মরিচা ধরা আর্থ কানেকশন',
          asset: 'assets/game/art/m4_board46/patrol_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা কানেকশন আর্থিং-এর রেজিস্ট্যান্স বহুগুণ বাড়িয়ে পুরো সিস্টেম অকেজো করে দেয়।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'বল্টু খুলে ঝুলে থাকা স্ট্রিপ',
          asset: 'assets/game/art/m4_board46/patrol_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'লুজ কানেকশনেই বেশিরভাগ আর্থিং সমস্যা — রেজিস্ট্যান্স বেড়ে সুরক্ষা অকেজো হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পেট্রোলিং-এ প্রতিটি পোলের আর্থিং দেখা আবশ্যক রুটিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লুজ বা মরিচা ধরা কানেকশনে রেজিস্ট্যান্স বহুগুণ বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাটা বা চুরি যাওয়া স্ট্রিপে ফল্টে ব্রেকার ট্রিপ করে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাইন চলছে মানেই আর্থিং ঠিক আছে, দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটু মরিচা আর্থ কানেকশনকে আরও মজবুত করে তোলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্থ স্ট্রিপ চুরি গেলে পোলের কোনো বিপদ থাকে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আলগা বল্টু থাকলেও ফল্ট কারেন্ট ঠিকই মাটিতে যাবে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আর্থিং দেখা শুধু সাবস্টেশন টিমের কাজ, লাইনের নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কাটা স্ট্রিপ বর্ষাকালে নিজে থেকেই জুড়ে যায় আবার', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'measure',
      promptBn: 'আর্থিং-এর আসল শক্তি জানবেন — কোনটা ঠিক পরীক্ষা?',
      options: [
        LearnBoardOption(
          id: 'tester',
          labelBn: 'আর্থ টেস্টার, দুটি স্পাইক মাটিতে পোঁতা',
          asset: 'assets/game/art/m4_board46/measure_tester.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'megger',
          labelBn: 'আর্থ মেগার, দুটি স্পাইক মাটিতে পোঁতা',
          asset: 'assets/game/art/m4_board46/measure_megger.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'eye',
          labelBn: 'শুধু চোখে দেখেই ঠিক বলে দেওয়া',
          asset: 'assets/game/art/m4_board46/measure_eye.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু চাক্ষুষ পরিদর্শন যথেষ্ট নয় — আর্থ রেজিস্ট্যান্স মেপেই আসল কার্যকারিতা বোঝা যায়।',
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'মাত্র একটা স্পাইক পুঁতে মাপা',
          asset: 'assets/game/art/m4_board46/measure_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল অব পটেনশিয়াল পদ্ধতিতে ইলেক্ট্রোড ছাড়াও দুটি অস্থায়ী স্পাইক মাটিতে পুঁততে হয়।',
        ),
        LearnBoardOption(
          id: 'lying',
          labelBn: 'স্পাইক মাটির ওপর ফেলে রেখে মাপা',
          asset: 'assets/game/art/m4_board46/measure_lying.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্পাইক দুটি মাটিতে পুঁতেই সার্কিট তৈরি হয় — তবেই যন্ত্র ওহমে রেজিস্ট্যান্স দেখায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্থ রেজিস্ট্যান্স টেস্টার বা মেগারে ওহম মাপতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সাবস্টেশনে 1 ওহমের কম মান ভালো বলে ধরা হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সাধারণ লাইনে 5-8 ওহমের কম মান ভালো বলে ধরা হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্থিং-এর রেজিস্ট্যান্স যত বেশি, সুরক্ষা তত ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চোখে দেখে ঠিক লাগলে ওহম মাপার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সাবস্টেশনে 50 ওহম পর্যন্ত রেজিস্ট্যান্স চলতে পারে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটা স্পাইক পুঁতলেই ফল অব পটেনশিয়াল পূর্ণ হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্পাইক মাটিতে না পুঁতলেও রিডিং ঠিকঠাক আসে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আর্থ মেগার শুধু ট্রান্সফরমারের তেল মাপার যন্ত্র', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tx',
      promptBn: 'ট্রান্সফরমারের আর্থিং দেখছেন — কোনটা ঠিক ব্যবস্থা?',
      options: [
        LearnBoardOption(
          id: 'double',
          labelBn: 'নিউট্রাল ও বডি, দুটোরই দুটি আলাদা পিট',
          asset: 'assets/game/art/m4_board46/tx_double.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'brass',
          labelBn: 'আর্থ সংযোগে পিতলের নাট-বল্টু টাইট',
          asset: 'assets/game/art/m4_board46/tx_brass.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'নিউট্রাল ও বডি একটাই পিটে',
          asset: 'assets/game/art/m4_board46/tx_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'ট্রান্সফরমারে চাই ডাবল আর্থিং — দুটি আলাদা পিট, যাতে একটি ব্যর্থ হলেও অন্যটি সুরক্ষা দেয়।',
        ),
        LearnBoardOption(
          id: 'nobody',
          labelBn: 'শুধু নিউট্রাল আর্থ, বডি আর্থ নেই',
          asset: 'assets/game/art/m4_board46/tx_nobody.svg',
          scene: true,
          correct: false,
          rejectBn: 'বডি আর্থিং মানুষকে শক থেকে বাঁচায় — ফল্টে বডি যেন বিপজ্জনক ভোল্টেজে না পৌঁছায়।',
        ),
        LearnBoardOption(
          id: 'noneutral',
          labelBn: 'শুধু বডি আর্থ, নিউট্রাল আর্থ নেই',
          asset: 'assets/game/art/m4_board46/tx_noneutral.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিউট্রাল আর্থিং সিস্টেমের ভোল্টেজ স্থির রাখে — নিউট্রাল ও বডি, দুটোই সমান জরুরি।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'সাধারণ লোহার নাটে মরিচা ধরা',
          asset: 'assets/game/art/m4_board46/tx_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ নাট-বল্টুতে মরিচা ধরে — আর্থিং-এ পিতল বা স্টেইনলেস স্টিলের নাট-বল্টু দিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দুটি আলাদা পিট — একটি ব্যর্থ হলেও অন্যটি সুরক্ষা দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নিউট্রাল আর্থ ভোল্টেজ স্থির রাখে, বডি আর্থ শক রোখে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পিতল বা স্টেইনলেস স্টিলের নাট-বল্টুতে মরিচা ধরে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটা ভালো পিটই ট্রান্সফরমারের জন্য যথেষ্ট সুরক্ষা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নিউট্রাল আর্থ থাকলে বডি আর্থ না দিলেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সাধারণ লোহার নাট-বল্টুই আর্থিং-এ সবচেয়ে টেকসই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বডি আর্থ থাকলে নিউট্রাল আর্থ শুধু বাড়তি খরচ মাত্র', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মরিচা ধরা নাট আর্থিং-এর রেজিস্ট্যান্স কমিয়ে দেয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নিউট্রাল আর বডি আর্থিং আসলে একই জিনিস, আলাদা নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'care',
      promptBn: 'পুরোনো আর্থিং দুর্বল হয়ে গেছে — রক্ষণাবেক্ষণে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'water',
          labelBn: 'শুকনো দিনে পিটে জল ঢালা',
          asset: 'assets/game/art/m4_board46/care_water.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tighten',
          labelBn: 'কানেকশন পরিষ্কার, গ্রিজ দিয়ে টাইট',
          asset: 'assets/game/art/m4_board46/care_tighten.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'ফাটা শুকনো পিট যেমন আছে থাক',
          asset: 'assets/game/art/m4_board46/care_dry.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুকনো আবহাওয়ায় পিটে জল দিলে মাটির আর্দ্রতা বাড়ে, আর্থ রেজিস্ট্যান্স কমে।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'আলগা কানেকশন ফেলে চলে যাওয়া',
          asset: 'assets/game/art/m4_board46/care_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'সমস্ত লুজ কানেকশন পরিষ্কার করে, গ্রিজ লাগিয়ে টাইট দিন — নইলে আর্থিং অকেজো।',
        ),
        LearnBoardOption(
          id: 'rubbish',
          labelBn: 'ঢাকনা নেই, পিট আবর্জনায় ভরা',
          asset: 'assets/game/art/m4_board46/care_rubbish.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্থ পিটের চারপাশ পরিষ্কার রাখুন, কভারটি ঠিকমতো লাগানো আছে কিনা দেখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শুকনো দিনে পিটে জল দিলে আর্থ রেজিস্ট্যান্স কমে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লুজ কানেকশন পরিষ্কার করে গ্রিজ দিয়ে টাইট দিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পিটের চারপাশ পরিষ্কার, কভার ঠিকমতো লাগানো চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পিট যত শুকনো থাকে, আর্থিং তত বেশি ভালো কাজ করে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একবার বসানো আর্থিং আর কোনোদিন দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্রিজ লাগালে আর্থ কানেকশনে কারেন্ট আটকে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পিটের ঢাকনা না থাকলেও আর্থিং-এ কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আলগা কানেকশন পরের বর্ষায় নিজেই এঁটে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পুরোনো দুর্বল আর্থিং আর কখনো কার্যকর করা যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'soil',
      promptBn: 'পাথুরে বা বালির মাটিতে আর্থিং দেবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'multi',
          labelBn: 'একাধিক ইলেক্ট্রোড জুড়ে আর্থিং',
          asset: 'assets/game/art/m4_board46/soil_multi.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'salt',
          labelBn: 'ইলেক্ট্রোড ঘিরে কাঠকয়লা ও লবণ',
          asset: 'assets/game/art/m4_board46/soil_salt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'পাথুরে মাটিতে একটাই ইলেক্ট্রোড',
          asset: 'assets/game/art/m4_board46/soil_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'পাথুরে বা বালির মাটির রেজিস্ট্যান্স বেশি — সেখানে একাধিক ইলেক্ট্রোড বা মাটির ট্রিটমেন্ট চাই।',
        ),
        LearnBoardOption(
          id: 'iron',
          labelBn: 'যেকোনো বাঁকা লোহার রড পোঁতা',
          asset: 'assets/game/art/m4_board46/soil_iron.svg',
          scene: true,
          correct: false,
          rejectBn: 'যেকোনো লোহার রড পুঁতলেই আর্থিং হয় না — সঠিক উপাদান (GI বা কপার) আর সঠিক পদ্ধতি চাই।',
        ),
        LearnBoardOption(
          id: 'short',
          labelBn: 'ছোট্ট রড মাটির ওপরে ওপরে',
          asset: 'assets/game/art/m4_board46/soil_short.svg',
          scene: true,
          correct: false,
          rejectBn: 'কার্যকর আর্থিং-এ সঠিক দৈর্ঘ্য আর সঠিক ইনস্টলেশন জরুরি — এটা বিজ্ঞান, শুধু রড পোঁতা নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পাথুরে বা বালির মাটিতে আর্থ রেজিস্ট্যান্স বেশি হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাঠকয়লা ও লবণ মাটির পরিবাহিতা বাড়াতে সাহায্য করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্থিং-এ সঠিক উপাদান, দৈর্ঘ্য ও পদ্ধতি সবই জরুরি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো লোহার রড মাটিতে পুঁতলেই ভালো আর্থিং হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পাথুরে মাটিতে আর্থ রেজিস্ট্যান্স সবচেয়ে কম থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রড যত ছোট, আর্থিং তত মজবুত আর নির্ভরযোগ্য', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লবণ আর কাঠকয়লা মাটির পরিবাহিতা কমিয়ে দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মাটি যেমনই হোক, একটা ইলেক্ট্রোডই সবখানে যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মরিচা ধরা বাঁকা রডেও আর্থিং-এর কোনো ক্ষতি নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board46Lines.rivalTaunt,
    rivalLineBn: M4Board46Lines.rivalMyth,
    exitBn: M4Board46Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'কাটা আর্থ স্ট্রিপ',
      'আলগা আর্থ কানেকশন',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ফল্টের সময় আর্থিং না থাকলে ব্রেকার ট্রিপ করবে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'আর্থিং ছাড়া ফিউজ, ব্রেকার বা LA ঠিকমতো কাজ করে না', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ছোট একটা ফল্টই তখন বিপর্যয় বা প্রাণহানি ঘটাতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লাইন চললেই বোঝা যায় আর্থিং পুরোপুরি ঠিক আছে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'কাটা আর্থ তারেও ফল্ট কারেন্ট ঠিক মাটিতে নামে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'আলগা আর্থ কানেকশনে সুরক্ষার কোনো ঘাটতি হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আর্থিং শুধু কাগজের নিয়ম, মাঠে ওর কোনো কাজ নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ফল্ট হলে ব্রেকার আর্থিং ছাড়াও নিজে থেকেই ট্রিপ করে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'একটু কাটা আর্থিং তারে মানুষের শকের ভয় থাকে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board46Lines {
  static const rivalTaunt = 'আরে, লাইন তো দিব্যি চলছে! আর্থিং-এর তার নিয়ে এত মাথাব্যথা কেন?';

  /// Lesson 4.6's first myth buster, word for word.
  static const rivalMyth = 'আর্থিং তারটা তো শুধু সুরক্ষার জন্য, ওটা একটু কাটা বা আলগা থাকলেও লাইন চলতে কোনো অসুবিধা হয় না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
