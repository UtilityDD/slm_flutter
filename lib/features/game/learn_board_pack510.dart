import 'learn_board_models.dart';

/// Module 5 Lesson 5.10 (প্রিভেন্টিভ মেইনটেন্যান্স: গোয়েন্দা থেকে ডাক্তার), the
/// picture board (rung `5.10/learn`, pack `learn_5_10`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board510_art.py`. Every round
/// and every trap comes from the lesson text (item spec
/// `docs/module_specs/module5_items/board_510.json`, rulings M5-11, M5-15):
///  * checklist: the lineman's PM checklist — a visual check of pole,
///    conductor, insulators and hardware; every earthing connection checked;
///    branches near the line trimmed. Cleaning alone is not PM (myth 2). The
///    span carries portable earths on every card: the PM day is a planned
///    shutdown ('পরিকল্পিত শাটডাউন'; the earthing rule itself is Module 1's);
///  * hidden: loose connections cannot be seen from outside — every joint is
///    scanned with a thermal camera (the screen shows the three phase joints,
///    one hot: ruling M5-15 compares a joint with the same joint on the other
///    two phases) and the hot joint is tightened on the shutdown;
///  * fixnow (pro tip 1 and 3): a loose nut or a lightly rusted clamp is put
///    right then and there; a good torque wrench makes the work exact;
///  * record (pro tip 2): what was done AND what abnormalities were found go
///    in a logbook or a digital app;
///  * report (CBM pro tip): a lineman who notices and reports deterioration
///    (oil colour change, an odd sound) is part of CBM; maintenance is done
///    when the condition needs it, not at the next date.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack510 = LearnBoardPack(
  lessonId: '5.10',
  titleBn: 'প্রিভেন্টিভ মেইনটেন্যান্স: গোয়েন্দা থেকে ডাক্তার',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'আজ PM-এর দিন। ব্রেকডাউনের অপেক্ষা নয় — ছোট সমস্যা বড় রোগ হওয়ার আগেই ধরুন।',
  earnedBn: 'খুঁটিয়ে দেখা, থার্মাল স্ক্যান, তখনই মেরামত আর লগবুকে রেকর্ড — এই হলো PM।',
  slots: [
    LearnBoardSlot(
      id: 'checklist',
      promptBn: 'PM-এর দিন লাইনে এসেছেন — লাইনম্যানের চেকলিস্টের কাজ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'visual',
          labelBn: 'পোল, তার, ইনসুলেটর খুঁটিয়ে দেখা',
          asset: 'assets/game/art/m5_board510/checklist_visual.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'পোলের আর্থিং কানেকশন পরীক্ষা',
          asset: 'assets/game/art/m5_board510/checklist_earth.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'trim',
          labelBn: 'লাইনের কাছে আসা ডাল ছাঁটা',
          asset: 'assets/game/art/m5_board510/checklist_trim.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wipe',
          labelBn: 'একটা ইনসুলেটর মুছেই কাজ শেষ',
          asset: 'assets/game/art/m5_board510/checklist_wipe.svg',
          scene: true,
          correct: false,
          rejectBn: 'পরিষ্কার করা PM-এর একটি অংশ মাত্র। আসল কাজ পরিদর্শন, পরীক্ষা আর বিশ্লেষণ।',
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'তারে লাগা ডাল রেখেই চলে যাওয়া',
          asset: 'assets/game/art/m5_board510/checklist_branch.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইনের কাছে চলে আসা ডালপালা ছাঁটা PM চেকলিস্টেরই কাজ।',
        ),
        LearnBoardOption(
          id: 'earthlead',
          labelBn: 'ছেঁড়া আর্থ লিড ডিঙিয়ে চলে যাওয়া',
          asset: 'assets/game/art/m5_board510/checklist_earthlead.svg',
          scene: true,
          correct: false,
          rejectBn: 'PM-এ সমস্ত আর্থিং কানেকশন পরীক্ষা করতে হয় — দরকারে আর্থ পিটের রক্ষণাবেক্ষণও।',
        ),
      ],
      whyChips: [
        // One right chip is dealt whichever safe card was picked, so each one
        // holds for all three (visual check, earthing, trimming).
        LearnWhyChip(id: 'w1', textBn: 'এই কাজগুলো সাধারণ ফল্টের কারণ গোড়াতেই নষ্ট করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এগুলো সবই লাইনম্যানের PM চেকলিস্টের কাজ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'PM-এর আসল কাজ পরিদর্শন, পরীক্ষা আর বিশ্লেষণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট সমস্যা গোড়াতেই ধরলে বড় ব্রেকডাউন আটকায়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'ইনসুলেটর মুছলেই PM-এর সব কাজ শেষ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তারে ডাল লাগলেও ঝড় না এলে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং একবার বসালে আর দেখার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লাইনে ফল্ট না থাকলে PM করার কোনো মানে নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ডাল ছাঁটা অন্য দপ্তরের কাজ, লাইনম্যানের নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hidden',
      promptBn: 'সব সংযোগ বাইরে থেকে ঠিক দেখাচ্ছে। লুকানো লুজ কানেকশন ধরবেন কীভাবে?',
      options: [
        LearnBoardOption(
          id: 'scan',
          labelBn: 'থার্মাল ক্যামেরায় সব জয়েন্ট স্ক্যান',
          asset: 'assets/game/art/m5_board510/hidden_scan.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tighten',
          labelBn: 'গরম জয়েন্ট শাটডাউনে টাইট করা',
          asset: 'assets/game/art/m5_board510/hidden_tighten.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'eyes',
          labelBn: "খালি চোখে দেখেই 'সব ঠিক'",
          asset: 'assets/game/art/m5_board510/hidden_eyes.svg',
          scene: true,
          correct: false,
          rejectBn: 'লুজ কানেকশন বাইরে থেকে বোঝা যায় না — থার্মাল ক্যামেরায় স্ক্যান করুন।',
        ),
        LearnBoardOption(
          id: 'later',
          labelBn: 'গরম জয়েন্ট পরের PM-এর জন্য রাখা',
          asset: 'assets/game/art/m5_board510/hidden_later.svg',
          scene: true,
          correct: false,
          rejectBn: "'পরে করা যাবে' — এই মনোভাবই বড় ব্রেকডাউনের জন্ম দেয়।",
        ),
        LearnBoardOption(
          id: 'shine',
          labelBn: 'জয়েন্ট মুছে চকচকে করেই ছেড়ে দেওয়া',
          asset: 'assets/game/art/m5_board510/hidden_shine.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু ধুলো মোছা নয় — থার্মাল স্ক্যান আর টাইট করাই চেকলিস্টের কাজ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লুজ কানেকশন বাইরে থেকে চোখে বোঝা যায় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'থার্মাল ক্যামেরা হটস্পট দেখিয়ে লুজ জয়েন্ট ধরে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হটস্পট মানে লুজ কানেকশন বা ওভারলোডেড অংশ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাইরে চকচকে দেখালে জয়েন্ট ভেতরেও ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গরম জয়েন্ট নিজে নিজেই ঠান্ডা হয়ে ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'থার্মাল ক্যামেরা শুধু রাতের টহলে কাজে লাগে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জয়েন্ট মুছে দিলেই লুজ কানেকশন সেরে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একটা জয়েন্ট দেখলেই বাকি সবগুলোর খবর মেলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fixnow',
      promptBn: 'PM-এ চোখে পড়ল একটা লুজ নাট আর হালকা মরিচা ধরা ক্ল্যাম্প। কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'nut',
          labelBn: 'লুজ নাট তখনই টাইট করা',
          asset: 'assets/game/art/m5_board510/fixnow_nut.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clamp',
          labelBn: 'মরিচা ধরা ক্ল্যাম্প সেদিনই ঠিক করা',
          asset: 'assets/game/art/m5_board510/fixnow_clamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'torque',
          labelBn: 'টর্ক রেঞ্চে নাট মেপে টাইট',
          asset: 'assets/game/art/m5_board510/fixnow_torque.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: "'পরে করা যাবে' বলে চলে যাওয়া",
          asset: 'assets/game/art/m5_board510/fixnow_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'PM-এর সময় লুজ নাট বা হালকা মরিচা ধরা ক্ল্যাম্প দেখলে তখনই ঠিক করুন।',
        ),
        LearnBoardOption(
          id: 'pipe',
          labelBn: 'মরিচা-ধরা স্প্যানারে পাইপ লাগিয়ে টান',
          asset: 'assets/game/art/m5_board510/fixnow_pipe.svg',
          scene: true,
          correct: false,
          rejectBn: 'সঠিক টুলস ব্যবহার করুন — একটি ভালো টর্ক রেঞ্চ কাজকে অনেক বেশি নির্ভুল করে।',
        ),
        LearnBoardOption(
          id: 'half',
          labelBn: 'নাট টাইট, ক্ল্যাম্প পরের বারের জন্য',
          asset: 'assets/game/art/m5_board510/fixnow_half.svg',
          scene: true,
          correct: false,
          rejectBn: "লুজ নাট আর মরিচা ধরা ক্ল্যাম্প — দুটোই তখনই ঠিক করুন; 'পরে করা যাবে' নয়।",
        ),
      ],
      whyChips: [
        // Each right chip holds for nut, clamp and torque alike (the torque
        // wrench's own point is in the pipe trap's reject line).
        LearnWhyChip(id: 'w1', textBn: 'ছোট সমস্যা অবহেলা করলেই বড় ব্রেকডাউন আসে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লুজ নাট বা মরিচা ধরা ক্ল্যাম্প তখনই ঠিক করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: "'পরে করা যাবে' ভাবলেই ছোট সমস্যা বড় হয়", correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হালকা মরিচায় কিছু হয় না, পরে দেখা যাবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো স্প্যানারে পাইপ দিলেই টাইট নিখুঁত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লুজ নাট পরের PM পর্যন্ত নিরাপদে চলে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নাট যত জোরে টানবেন, কানেকশন তত ভালো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট মেরামত আলাদা দিনে করলেই সময় বাঁচে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'record',
      promptBn: 'PM-এর কাজ শেষ। এবার কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'logbook',
          labelBn: 'লগবুকে কাজ আর অস্বাভাবিকতা লেখা',
          asset: 'assets/game/art/m5_board510/record_logbook.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'app',
          labelBn: 'ফোনের অ্যাপে একই রেকর্ড তোলা',
          asset: 'assets/game/art/m5_board510/record_app.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'chat',
          labelBn: 'সুপারভাইজারকে শুধু মুখে বলে দেওয়া',
          asset: 'assets/game/art/m5_board510/record_chat.svg',
          scene: true,
          correct: false,
          rejectBn: 'কী কাজ করলেন আর কী অস্বাভাবিকতা পেলেন, লগবুকে বা অ্যাপে রেকর্ড করুন।',
        ),
        LearnBoardOption(
          id: 'blank',
          labelBn: 'অস্বাভাবিকতার পাতা ফাঁকা রাখা',
          asset: 'assets/game/art/m5_board510/record_blank.svg',
          scene: true,
          correct: false,
          rejectBn: 'রেকর্ডে দুটোই চাই — কী কাজ করলেন আর কী অস্বাভাবিকতা পেলেন।',
        ),
        LearnBoardOption(
          id: 'blind',
          labelBn: "না দেখেই 'সব ঠিক আছে' লেখা",
          asset: 'assets/game/art/m5_board510/record_blind.svg',
          scene: true,
          correct: false,
          rejectBn: 'যা অস্বাভাবিকতা পেলেন সেটাই লিখুন, না দেখে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কী কাজ হলো আর কী অস্বাভাবিকতা — দুটোই লিখুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'PM-এর রেকর্ড ভবিষ্যতের পরিকল্পনায় অমূল্য', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লগবুক বা ডিজিটাল অ্যাপে রেকর্ড রাখতেই হবে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মুখে বলে দিলেই রেকর্ডের কাজ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'খারাপ কিছু না পেলে কিছুই লেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অস্বাভাবিকতা লিখলে নিজের কাজেরই দোষ হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লগবুক শুধু অফিসের কাজের জিনিস, মাঠের নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আগের PM-এর পাতাটাই নকল করলে চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'report',
      promptBn: 'DTR-এর তেলের রং বদলেছে, ভেতর থেকে অস্বাভাবিক শব্দ আসছে। লাইনম্যান কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'phone',
          labelBn: 'অবনতি দেখে তখনই ফোনে রিপোর্ট',
          asset: 'assets/game/art/m5_board510/report_phone.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'note',
          labelBn: 'বদলটা লগবুকে লিখে রাখা',
          asset: 'assets/game/art/m5_board510/report_note.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shrug',
          labelBn: "'আগেও হতো' বলে চলে যাওয়া",
          asset: 'assets/game/art/m5_board510/report_shrug.svg',
          scene: true,
          correct: false,
          rejectBn: 'অবনতি লক্ষ্য করে রিপোর্ট করলে আপনিও CBM-এর অংশ।',
        ),
        LearnBoardOption(
          id: 'wait',
          labelBn: 'পরের নির্ধারিত PM-এর অপেক্ষা',
          asset: 'assets/game/art/m5_board510/report_wait.svg',
          scene: true,
          correct: false,
          rejectBn: 'CBM-এ কন্ডিশন দেখে যখন প্রয়োজন, তখনই রক্ষণাবেক্ষণ।',
        ),
        LearnBoardOption(
          id: 'polish',
          labelBn: 'বেড়ার প্লেট মুছে চকচকে করে দেওয়া',
          asset: 'assets/game/art/m5_board510/report_polish.svg',
          scene: true,
          correct: false,
          rejectBn: 'পরিষ্কার শুধু একটা অংশ — আসল কাজ স্বাস্থ্যের মূল্যায়ন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অবনতি দেখে রিপোর্ট করলে আপনিও CBM-এর অংশ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'CBM-এ কন্ডিশন দেখে প্রয়োজনমতো রক্ষণাবেক্ষণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তেলের রং বদল আর অস্বাভাবিক শব্দ অবনতির লক্ষণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নির্ধারিত PM-এর দিন না এলে কিছু করার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আগেও এমন শব্দ হতো, তাই এখনও চিন্তা নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ট্যাংক চকচকে থাকলে ভেতরটাও সুস্থ থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তেলের রং বদলানো পুরনো হওয়ার সাধারণ ছাপ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অবনতি রিপোর্ট করা শুধু ইঞ্জিনিয়ারের দায়িত্ব', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board510Lines.rivalTaunt,
    rivalLineBn: M5Board510Lines.rivalMyth,
    exitBn: M5Board510Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'লুকানো লুজ কানেকশন',
      'হঠাৎ ব্রেকডাউন',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'লুজ কানেকশন বাইরে থেকে বোঝা যায় না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'লুকানো সমস্যা ধীরে ধীরে বড় হতে থাকে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'PM লুকানো সমস্যা খুঁজে ব্রেকডাউন আটকায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'যা চলছে তাতে হাত দিলেই নতুন ফল্ট হয়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ব্রেকডাউন হলে তখন সারালেই যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'লুজ কানেকশন নিজে থেকেই শক্ত হয়ে যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'চালু লাইনের ভেতরে কোনো রোগ থাকে না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'PM মানে শুধু লাইনটা পরিষ্কার করা', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'পরিকল্পিত শাটডাউনের চেয়ে ব্ল্যাকআউট ভালো', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board, in his recorded voice.
/// [rivalExit] already has a clip; the two [recorded] lines are new — until
/// the director makes their clips with `tool/rival_clip.py` they stay silent
/// with the bubble held for a reading time (never the device voice).
abstract final class M5Board510Lines {
  static const rivalTaunt = 'আরে, লাইন তো দিব্যি চলছে! খুলে-নেড়ে দেখার ঝামেলা কেন?';

  /// Lesson 5.10's first myth buster, word for word.
  static const rivalMyth = 'যে জিনিসটা ঠিকঠাক চলছে, সেটাকে খোলার বা নাড়াচাড়া করার দরকার কী? এতে তো বরং সমস্যা তৈরি হতে পারে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// His new lines on this board, for `tool/dump_learn_voice_lines_test.dart`.
  static const recorded = [rivalTaunt, rivalMyth];
}
