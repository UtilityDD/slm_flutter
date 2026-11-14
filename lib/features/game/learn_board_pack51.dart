import 'learn_board_models.dart';

/// Module 5 Lesson 5.1 ('লাইন ট্রিপ করেছে'—প্রথম কাজ কী?), the picture board
/// (rung `5.1/learn`, pack `learn_5_1`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board51_art.py`. Every round
/// and every trap comes from the lesson text (and the Module 5 rulings,
/// `docs/module_specs/module5_rulings.md`):
///  * call: before going out, collect what the control-room operator knows —
///    the trip (instant? overcurrent or earth fault?), the weather at the
///    time, the feeder's old logbook; never race out blind, never wave the
///    operator off, never ask for a charge after the breaker would not hold
///    (ruling M5-1: deadly class R8, its card text word for word);
///  * treat: a tripped line is not dead — treat it as live; valid PTW,
///    isolate and earth; PTW and personal earth before any hand on it; the recloser
///    tries more than once on a permanent fault;
///  * van: torch, binoculars, discharge rod and PPE in the van; the crew
///    briefed on the facts and the plan before leaving;
///  * storm: wind + rain + earth-fault relay = a broken branch or punctured
///    insulator, so the patrol starts on the wooded section (lesson example 1;
///    a melted jumper is example 2's clear-day overcurrent clue);
///  * lockout: repeated recloses then a final trip = probably a temporary
///    fault (e.g. wires clashing in the wind) turned permanent (example 3 +
///    the recloser fact); inform control before the hunt, no touch without
///    PTW and personal earth (ruling M5-3); no more charges.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack51 = LearnBoardPack(
  lessonId: '5.1',
  titleBn: "'লাইন ট্রিপ করেছে'—প্রথম কাজ কী?",
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'ফিডার ট্রিপ করেছে, চারিদিক অন্ধকার। ফল্ট ফাইন্ডার শান্ত থাকেন — আগে তথ্য, তারপর সুরক্ষা।',
  earnedBn: 'আগে তথ্য, তারপর অনুমান ধরে খোঁজা; ট্রিপ লাইন মানেই লাইভ — হাত দেওয়ার আগে পারমিট (PTW) আর আর্থিং।',
  slots: [
    LearnBoardSlot(
      id: 'call',
      promptBn: 'ফোন এল: ফিডার ট্রিপ করেছে। মাঠে নামার আগে কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'trip',
          labelBn: 'তৎক্ষণাৎ ট্রিপ? ওভারকারেন্ট না আর্থ ফল্ট — জেনে নেওয়া',
          asset: 'assets/game/art/m5_board51/call_trip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'weather',
          labelBn: 'ট্রিপের সময়ের আবহাওয়া জেনে নেওয়া',
          asset: 'assets/game/art/m5_board51/call_weather.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'logbook',
          labelBn: 'কন্ট্রোল রুমকে ফিডারের পুরনো লগবুক দেখতে বলা',
          asset: 'assets/game/art/m5_board51/call_logbook.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'blind',
          labelBn: 'ফোন বাজতেই তথ্য না নিয়ে গাড়ি ছোটানো',
          asset: 'assets/game/art/m5_board51/call_blind.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিল্ডে যাওয়ার আগে কন্ট্রোল রুমের অপারেটরের কাছ থেকে যতটা সম্ভব তথ্য সংগ্রহ করুন — প্রতিটি তথ্যই সূত্র।',
        ),
        LearnBoardOption(
          id: 'charge',
          labelBn: 'ব্রেকার না টেকার পরও আবার চার্জ করতে বলা',
          asset: 'assets/game/art/m5_board51/call_charge.svg',
          scene: true,
          correct: false,
          rejectBn: 'একবার টেস্ট চার্জ সাবস্টেশন ইন-চার্জের সিদ্ধান্ত; ব্রেকার না টিকলে লাইন ব্রেকডাউন — ফল্ট না পেয়ে আর চার্জ নয়',
        ),
        LearnBoardOption(
          id: 'ignore',
          labelBn: 'অপারেটরের কথা না শুনেই ফোন সরিয়ে দেওয়া',
          asset: 'assets/game/art/m5_board51/call_ignore.svg',
          scene: true,
          correct: false,
          rejectBn: 'অভিজ্ঞ অপারেটর অনেক সময় ফল্টের ধরন দেখেই উৎসের ভালো ধারণা দিতে পারেন — তাঁর অভিজ্ঞতাকে বিশ্বাস করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মাঠে যাওয়ার আগে অপারেটরের কাছে তথ্য নিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঝড়ে তৎক্ষণাৎ ট্রিপ মানে সম্ভবত গাছ বা ডাল', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'একই সেকশনে বারবার ফল্ট হলে সমস্যা সেখানেই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অপারেটর ফল্টের ধরন দেখে উৎস আঁচ করতে পারেন', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'ঝড়ের ট্রিপ মানে সম্ভবত সাবস্টেশনের দোষ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একবার চার্জ করে দেখলেই ফল্টের জায়গা মেলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিলের ধরন মাঠে গিয়ে নিজেই বুঝে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আবহাওয়ার খবর ফল্ট খোঁজায় কাজে আসে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পুরনো লগবুক ঘাঁটা মানে সময় নষ্ট করা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'treat',
      promptBn: 'লাইন ট্রিপ করে বন্ধ আছে — এখন লাইনটাকে কী ধরবেন?',
      options: [
        LearnBoardOption(
          id: 'live',
          labelBn: 'ট্রিপ হওয়া লাইনকে লাইভ ধরে দূরে থাকা',
          asset: 'assets/game/art/m5_board51/treat_live.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ptw',
          labelBn: 'বৈধ পারমিট (PTW) নিয়ে লাইন আইসোলেট আর আর্থিং',
          asset: 'assets/game/art/m5_board51/treat_ptw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'personal',
          labelBn: 'পারমিট (PTW) আর ব্যক্তিগত আর্থিং — তবেই লাইনে হাত',
          asset: 'assets/game/art/m5_board51/treat_personal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'অন্ধকার ট্রিপ লাইনে খালি হাত দেওয়া',
          asset: 'assets/game/art/m5_board51/treat_bare.svg',
          scene: true,
          correct: false,
          rejectBn: "লাইন ট্রিপ করেছে মানে 'ডেড' নয় — যেকোনো মুহূর্তে আবার চালু হতে পারে, বিশেষ করে অটো-রিক্লোজার থাকলে।",
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'রিক্লোজার আর চেষ্টা করবে না ভেবে ওঠা',
          asset: 'assets/game/art/m5_board51/treat_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্থায়ী ফল্টে রিক্লোজার কয়েকবার চেষ্টা করে — অনুমান নয়, নিশ্চিতকরণ।',
        ),
        LearnBoardOption(
          id: 'guess',
          labelBn: "'লাইন তো বন্ধই' বলে কাজ শুরু",
          asset: 'assets/game/art/m5_board51/treat_guess.svg',
          scene: true,
          correct: false,
          rejectBn: "ট্রিপ হওয়া লাইনকে 'লাইভ' হিসেবে গণ্য করাই সবচেয়ে বড় সুরক্ষা নীতি — অনুমান করে কাজ মানেই মৃত্যুকে আমন্ত্রণ।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ট্রিপ লাইন যেকোনো মুহূর্তে চালু হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রিক্লোজার থাকলে লাইন নিজেই আবার চালু হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পারমিট (PTW) আর ব্যক্তিগত আর্থিং ছাড়া লাইনে হাত নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ট্রিপ হওয়া লাইন পুরোপুরি ডেড হয়ে থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রিক্লোজার একবার চেষ্টা করেই থেমে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাড়ির আলো নিভে থাকলে লাইনও নিরাপদ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তাড়াতাড়ি সারলে পারমিট ছাড়াও কাজ চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বন্ধ লাইনে আর্থিং লাগানো বাড়তি ঝামেলা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ট্রিপ লাইনে খালি হাতে কাজ করলেও ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'van',
      promptBn: 'রওনার আগে গাড়ি আর টিম তৈরি — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'torch',
          labelBn: 'গাড়িতে টর্চলাইট আর বাইনোকুলার তোলা',
          asset: 'assets/game/art/m5_board51/van_torch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rod',
          labelBn: 'ডিসচার্জ রড আর PPE গাড়িতে তোলা',
          asset: 'assets/game/art/m5_board51/van_rod.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'brief',
          labelBn: 'টিমকে তথ্য আর কাজের পরিকল্পনা বলা',
          asset: 'assets/game/art/m5_board51/van_brief.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'torch_left',
          labelBn: 'টর্চ-বাইনোকুলার তাকে রেখেই রওনা',
          asset: 'assets/game/art/m5_board51/van_torch_left.svg',
          scene: true,
          correct: false,
          rejectBn: 'গাড়িতে টর্চলাইট, বাইনোকুলার, ডিসচার্জ রড আর PPE আছে কিনা — বেরোনোর আগেই নিশ্চিত করুন।',
        ),
        LearnBoardOption(
          id: 'rod_left',
          labelBn: 'ডিসচার্জ রড ডিপোতে ফেলে রওনা',
          asset: 'assets/game/art/m5_board51/van_rod_left.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল্ট খোঁজার সরঞ্জামে ডিসচার্জ রড আর PPE থাকতেই হবে।',
        ),
        LearnBoardOption(
          id: 'solo',
          labelBn: 'পরিকল্পনা মাথায় রেখে একাই রওনা',
          asset: 'assets/game/art/m5_board51/van_solo.svg',
          scene: true,
          correct: false,
          rejectBn: 'টিম ব্রিফিং: প্রাপ্ত তথ্য আর কাজের পরিকল্পনা নিয়ে টিমের সাথে আলোচনা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বেরোনোর আগে টর্চ, বাইনোকুলার, রড দেখে নিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফল্ট খোঁজার সরঞ্জামে ডিসচার্জ রড আর PPE চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'প্রাপ্ত তথ্য আর পরিকল্পনা টিমকে জানাতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অন্ধকারে মোবাইলের আলোতেই টহল দিলে চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লাইনের কাজে ডিসচার্জ রড নেওয়া বাড়তি বোঝা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পরিকল্পনা এক জনের মাথায় থাকলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'PPE দরকার হলে মাঠে গিয়েই জোগাড় করা যাবে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'খালি চোখেই দূরের তারের ক্ষতি দেখা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্রিফিং মানে সময় নষ্ট, আগে বেরিয়ে পড়ুন', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'storm',
      promptBn: 'প্রবল বাতাস আর বৃষ্টি, রিলে বলছে আর্থ ফল্ট — কোথা থেকে খুঁজবেন?',
      options: [
        LearnBoardOption(
          id: 'trees',
          labelBn: 'গাছের জঙ্গলযুক্ত এলাকা দিয়ে টহল শুরু',
          asset: 'assets/game/art/m5_board51/storm_trees.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'ভাঙা ডাল বা পাংচার ইনসুলেটর খোঁজা',
          asset: 'assets/game/art/m5_board51/storm_branch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'field',
          labelBn: 'খোলা মাঠের অংশ দিয়ে খোঁজা শুরু',
          asset: 'assets/game/art/m5_board51/storm_field.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাতাস-বৃষ্টি আর আর্থ ফল্ট মানে সম্ভবত ডাল ভেঙেছে বা ইনসুলেটর পাংচার — শুরু হোক গাছের জঙ্গলযুক্ত এলাকা দিয়ে।',
        ),
        LearnBoardOption(
          id: 'jumper',
          labelBn: 'ঝড়ের রাতে গলা জাম্পার খোঁজা',
          asset: 'assets/game/art/m5_board51/storm_jumper.svg',
          scene: true,
          correct: false,
          rejectBn: 'গলা জাম্পার বা পাখি-জন্তু সাধারণত পরিষ্কার দিনে ওভারকারেন্টের সূত্র।',
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'পুরো ফিডার পোল ধরে ধরে হাঁটা',
          asset: 'assets/game/art/m5_board51/storm_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটি ভালো অনুমান খোঁজার এলাকা ছোট করে আর সময় বাঁচায় — অন্ধের মতো পুরো লাইন নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঝড়-বৃষ্টি আর আর্থ ফল্টে সম্ভবত ডাল ভেঙেছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভালো অনুমান খোঁজার এলাকা ছোট করে দেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঝড়ে আর্থ ফল্টে ইনসুলেটর পাংচারও হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঝড়ের রাতে আগে গলা জাম্পার খুঁজতে হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অনুমান না করে পুরো লাইন হাঁটাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝড়ে খোলা মাঠের অংশেই বেশি ফল্ট হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিলের খবর দিয়ে ফল্টের এলাকা বোঝা যায় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ঝড়ে সম্ভবত পাখি-জন্তুর শর্ট সার্কিট হয়েছে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেদিক থেকেই শুরু করুন, খুঁজতে সময় একই লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'lockout',
      promptBn: 'জোর বাতাসে রিক্লোজার কয়েকবার লাইন চালু করল, শেষে ফাইনাল ট্রিপ — কী বুঝবেন?',
      options: [
        LearnBoardOption(
          id: 'clash',
          labelBn: 'সম্ভবত অস্থায়ী ফল্ট (যেমন তারের টক্কর) স্থায়ী হয়েছে',
          asset: 'assets/game/art/m5_board51/lockout_clash.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ptw',
          labelBn: 'লক-আউট মানে স্থায়ী ফল্ট — কন্ট্রোলকে জানিয়ে খোঁজা, হাত দেওয়ার আগে পারমিট (PTW)',
          asset: 'assets/game/art/m5_board51/lockout_ptw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'পারমিট ছাড়া লক-আউট লাইনে হাত দেওয়া',
          asset: 'assets/game/art/m5_board51/lockout_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ট্রোল রুম ভুল করেও লাইন চালু করতে পারে — পারমিট (PTW) আর ব্যক্তিগত আর্থিং ছাড়া ট্রিপ হওয়া লাইন স্পর্শ নয়।',
        ),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'ফল্ট নিজে থেকেই সরে গেছে ভেবে বসে থাকা',
          asset: 'assets/game/art/m5_board51/lockout_tea.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল্ট চলে গেলে লাইন চালু থাকে; স্থায়ী হলে কয়েকবার চেষ্টার পর লক-আউট হয়।',
        ),
        LearnBoardOption(
          id: 'charge',
          labelBn: 'লক-আউটের পর আরেকবার চার্জ চাওয়া',
          asset: 'assets/game/art/m5_board51/lockout_charge.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্থায়ী ফল্টে বারবার লাইন চালু করলে যন্ত্রপাতি আরও ক্ষতিগ্রস্ত হয়, আগুন লাগতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্থায়ী ফল্টে কয়েকবার চেষ্টার পর লক-আউট হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফল্ট চলে গেলে লাইন চালু থাকে, বন্ধ হয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অস্থায়ী টক্কর পরে স্থায়ী ফল্ট হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লক-আউট মানে ফল্টটা নিজে থেকেই সরে গেছে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আরেকবার চার্জ দিলে ফল্ট পুড়ে সাফ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লক-আউটের পর লাইন আবার চালু হওয়ার ভয় নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিক্লোজার যত চেষ্টা করে, লাইন তত নিরাপদ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাতাসে তারের টক্কর খাওয়া লাইনের জন্য নিরীহ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফাইনাল ট্রিপের পর পারমিট ছাড়াই কাজ চলে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board51Lines.rivalTaunt,
    rivalLineBn: M5Board51Lines.rivalMyth,
    exitBn: M5Board51Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'রিক্লোজারে আবার চালু',
      'পারমিট (PTW) ছাড়া হাত',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'কন্ট্রোল রুম ভুল করে লাইন আবার চালু করতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'অটো-রিক্লোজার যেকোনো মুহূর্তে লাইন চালু করে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'পারমিট (PTW) আর ব্যক্তিগত আর্থিং ছাড়া লাইন স্পর্শ নয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ট্রিপ হওয়া লাইনে কারেন্ট ফেরার ভয় নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'তাড়াতাড়ি কাজ সারলে পারমিটের দরকার পড়ে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অন্ধকার লাইন দেখলেই বোঝা যায় ওটা পুরো ডেড', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'কন্ট্রোল রুম নিজেই খেয়াল রাখে, ভয়ের কিছু নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অটো-রিক্লোজার রাতের বেলায় বন্ধ রাখা হয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'মেরামতের ছোট কাজে পারমিট নেওয়ার দরকার নেই', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`.
abstract final class M5Board51Lines {
  static const rivalTaunt = 'আরে, লাইন তো ট্রিপ করেই আছে! কাগজের ঝামেলা কেন?';

  /// Lesson 5.1's first myth buster, word for word.
  static const rivalMyth = 'লাইন তো ট্রিপ করেই আছে, তার মানে ওটা ডেড। তাড়াতাড়ি কাজ সারার জন্য পারমিটের দরকার নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
