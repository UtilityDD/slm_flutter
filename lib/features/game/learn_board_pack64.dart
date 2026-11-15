import 'learn_board_models.dart';

/// Module 6 Lesson 6.4 (AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার), the picture
/// board (rung `6.4/learn`, pack `learn_6_4`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board64_art.py`. Every round
/// and every trap comes from the lesson text (item spec
/// `docs/module_specs/module6_items/board_64.json`, Module 6 rulings M6-1,
/// M6-3, M6-12, M6-14, X3, X7):
///  * gap: an isolator's whole point is a gap the eye can see — a breaker's
///    can't be seen; all three phases must be open (pro tip 4: one phase can
///    stick);
///  * open: the golden rule — an isolator is an off-load device; the breaker
///    first, then the isolator. Even a little load current makes a dangerous
///    arc (myth 1 reality) — so a house still lit means load, whatever the
///    breaker's lamp says; only the breaker can interrupt a fault (myth 2);
///  * close: the order reversed — the isolator first, then the breaker ON; a
///    part-seated contact makes a hotspot (pro tip 2); the handle turned
///    'দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত … মাঝপথে থামবেন না' (ruling
///    M6-3: only a stalled stroke is wrong, speed never is);
///  * earth: the operating handle earthed before it is worked (the lesson's
///    safety tip); the AB is worked from the ground with its long rod or
///    handle — the climb-and-push trap names the danger (a hand on a live
///    blade is death, ruling X7/B4) and its worker wears a full-body harness;
///  * care: what a patrol looks for — contacts home, arcing marks, clean
///    insulators, a jammed mechanism lubricated; arcing horns (pro tip 3).
/// The breaker's lamps in rounds 2 and 3 (red lit = ON, green lit = OFF) are
/// never the giveaway, either way round: a safe card shows the red lamp too
/// (on the phone before the breaker is off; the breaker back ON once the AB is
/// fully home), and a trap shows the green lamp too (round 2: the lamp says
/// OFF but a house is still lit; round 3: the stalled stroke).
/// The rival's myth is the lesson's first myth, word for word. The danger
/// tags name the harm without repeating the right reason chips. No YouTube
/// explainer yet (ruling M6-14).
const learnBoardPack64 = LearnBoardPack(
  lessonId: '6.4',
  titleBn: 'AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার',
  badgeBn: 'যন্ত্র গুরু',
  introBn: M6Board64Lines.intro,
  earnedBn: M6Board64Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'gap',
      promptBn: 'কোন ছবিতে খালি চোখেই দেখা যায় লাইন বিচ্ছিন্ন?',
      options: [
        LearnBoardOption(
          id: 'tilt',
          labelBn: 'টিল্টিং AB: তিন ফেজেই পোস্ট হেলে গ্যাপ',
          asset: 'assets/game/art/m6_board64/gap_tilt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lift',
          labelBn: 'তিনটি ব্লেডই ওপরে তোলা, প্রতি ফেজে গ্যাপ',
          asset: 'assets/game/art/m6_board64/gap_lift.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'closed',
          labelBn: 'একই AB, তিনটি ব্লেডই কন্টাক্টে লাগানো',
          asset: 'assets/game/art/m6_board64/gap_closed.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্টাক্ট লেগে আছে — কোনো গ্যাপ নেই, সার্কিট এখনও জোড়া।',
        ),
        LearnBoardOption(
          id: 'breaker',
          labelBn: 'সার্কিট ব্রেকারের বন্ধ ট্যাঙ্ক, বাইরে শুধু ফ্ল্যাগ',
          asset: 'assets/game/art/m6_board64/gap_breaker.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্রেকার খোলা কিনা খালি চোখে বোঝা যায় না — দৃশ্যমান গ্যাপ দেয় আইসোলেটর।',
        ),
        LearnBoardOption(
          id: 'stuck',
          labelBn: 'দুটো ব্লেড খোলা, মাঝেরটা কন্টাক্টে আটকে',
          asset: 'assets/game/art/m6_board64/gap_stuck.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটি ফেজ আটকে আছে — তিনটি ফেজই সম্পূর্ণ খুলেছে কিনা নিশ্চিত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'খোলা আইসোলেটরে খালি চোখেই গ্যাপ দেখা যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তিনটি ফেজই খুলেছে কিনা নিজের চোখে দেখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ব্রেকার খোলা কিনা বাইরে থেকে বোঝা যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ব্রেকারের ফ্ল্যাগ দেখলেই লাইন বিচ্ছিন্ন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দুটো ফেজ খুললেই লাইন পুরো বিচ্ছিন্ন হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আইসোলেটর আর ব্রেকার আসলে একই যন্ত্র', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হ্যান্ডেল নামানো মানেই সব ব্লেড খুলে গেছে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্যাপ দেখার দরকার নেই, সুইচ তো নামানো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দূর থেকে একটা ফেজ খোলা দেখলেই যথেষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'open',
      promptBn: 'AB সুইচ খোলার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'brkoff',
          labelBn: 'ব্রেকার OFF, বাড়ি অন্ধকার — তবেই হ্যান্ডেলে হাত',
          asset: 'assets/game/art/m6_board64/open_brkoff.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'phone',
          labelBn: 'ব্রেকার এখনও ON — হ্যান্ডেল ছেড়ে আগে ফোন',
          asset: 'assets/game/art/m6_board64/open_phone.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'arc',
          labelBn: 'ব্রেকার ON রেখেই AB খোলা',
          asset: 'assets/game/art/m6_board64/open_arc.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোডে খুললে কন্টাক্টে প্রচণ্ড ও দীর্ঘস্থায়ী আর্ক — সুইচ, অপারেটর, পুরো সিস্টেমের মারাত্মক ক্ষতি।',
        ),
        LearnBoardOption(
          id: 'lamp',
          labelBn: 'ব্রেকার OFF দেখাচ্ছে, তবু একটা বাড়িতে বাতি — AB টানা',
          asset: 'assets/game/art/m6_board64/open_lamp.svg',
          scene: true,
          correct: false,
          // DRAFT lead-in (owner) + the lesson's myth-1 reality, word for word.
          rejectBn: 'বাতি জ্বলছে মানে লাইনে এখনও লোড — সামান্য লোড কারেন্টও একটি বিপজ্জনক আর্ক তৈরি করার জন্য যথেষ্ট।',
        ),
        LearnBoardOption(
          id: 'fault',
          labelBn: 'সামনে তার ছিঁড়ে স্পার্ক — থামাতে AB টানা',
          asset: 'assets/game/art/m6_board64/open_fault.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল্ট কারেন্টকে বাধা দেওয়ার ক্ষমতা শুধু সার্কিট ব্রেকারের — আইসোলেটরের নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে ব্রেকার খুলে লাইন OFF-লোড, তারপর আইসোলেটর', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আইসোলেটরে আর্ক নেভানোর কোনো ব্যবস্থা নেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সামান্য লোডেও AB খুললে বিপজ্জনক আর্ক হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অল্প লোডে AB খুললে আসলে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফল্ট হলে AB টেনে কারেন্ট থামানো যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ব্রেকার আর আইসোলেটর, যেকোনোটা আগে খোলা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আইসোলেটরও ব্রেকারের মতো আর্ক নিভিয়ে দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাড়িতে বাতি জ্বললেও AB খোলায় বাধা নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফোনে খবর নেওয়া মানে শুধু সময় নষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'close',
      promptBn: 'লাইন আবার চালু করার সময় কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'shut',
          labelBn: 'ব্রেকার OFF থাকতেই এক টানে AB লাগানো',
          asset: 'assets/game/art/m6_board64/close_shut.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'seated',
          labelBn: 'তিন ফেজই পুরো লেগেছে, তারপর ব্রেকার ON',
          asset: 'assets/game/art/m6_board64/close_seated.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'flash',
          labelBn: 'ব্রেকার ON রেখেই AB লাগানো',
          asset: 'assets/game/art/m6_board64/close_flash.svg',
          scene: true,
          correct: false,
          rejectBn: 'চালু করার ক্রম উল্টো: প্রথমে আইসোলেটর লাগান, তারপর সার্কিট ব্রেকার ON করুন।',
        ),
        LearnBoardOption(
          id: 'half',
          labelBn: 'একটা ব্লেড আধা লাগা, তবু ব্রেকার ON',
          asset: 'assets/game/art/m6_board64/close_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'আংশিকভাবে লাগা কন্টাক্ট হটস্পট তৈরি করবে — তিন ফেজই পুরো লেগেছে কিনা দেখুন।',
        ),
        LearnBoardOption(
          id: 'stall',
          labelBn: 'হ্যান্ডেল মাঝপথে থেমে, ব্লেড আধখোলা',
          asset: 'assets/game/art/m6_board64/close_stall.svg',
          scene: true,
          correct: false,
          rejectBn: 'দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত হ্যান্ডেলটি ঘোরান — মাঝপথে থামবেন না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'চালু করতে আগে আইসোলেটর, তারপর ব্রেকার ON', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আধা লাগা কন্টাক্ট গরম হয়ে হটস্পট হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হ্যান্ডেল এক টানে শেষ পর্যন্ত, মাঝপথে নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আগে ব্রেকার ON, তারপর AB লাগালেও চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটা ফেজ আধা লাগলেও কারেন্ট ঠিক চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হ্যান্ডেল থেমে থেমে আস্তে ঘোরানোই ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'AB লাগানোর পর তিন ফেজ দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ব্রেকার ON থাকলে AB লাগানো আরও সহজ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হটস্পট নিয়ে টহলে ভাবার কিছু নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'earth',
      promptBn: 'AB সুইচ চালানোর আগে কী ঠিক থাকা চাই?',
      options: [
        LearnBoardOption(
          id: 'lead',
          labelBn: 'হ্যান্ডেলের আর্থ লিড ক্ল্যাম্পে আঁটা, মাটি পর্যন্ত',
          asset: 'assets/game/art/m6_board64/earth_lead.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ground',
          labelBn: 'মাটিতে দাঁড়িয়ে দু-হাতে হ্যান্ডেল, লিড অটুট',
          asset: 'assets/game/art/m6_board64/earth_ground.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'হ্যান্ডেলের আর্থ লিড কেটে ঝুলছে',
          asset: 'assets/game/art/m6_board64/earth_cut.svg',
          scene: true,
          correct: false,
          rejectBn: 'হ্যান্ডেল ঠিকমতো আর্থিং করা না থাকলে অপারেটরের সুরক্ষা থাকে না।',
        ),
        LearnBoardOption(
          id: 'bolt',
          labelBn: 'আর্থ ক্ল্যাম্প খোলা, বোল্ট মাটিতে পড়ে',
          asset: 'assets/game/art/m6_board64/earth_bolt.svg',
          scene: true,
          correct: false,
          rejectBn: 'অপারেট করার আগে নিশ্চিত করুন যে অপারেটিং হ্যান্ডেলটি সঠিকভাবে আর্থিং করা আছে।',
        ),
        LearnBoardOption(
          id: 'head',
          labelBn: 'পোলে উঠে সুইচের মাথায় হাতে ব্লেড ঠেলা',
          asset: 'assets/game/art/m6_board64/earth_head.svg',
          scene: true,
          correct: false,
          // DRAFT danger clause (owner; ruling X7/B4: a hand on a live part is
          // deadly) + the lesson's own words.
          rejectBn: 'চালু সুইচের ব্লেডে হাত দিলেই মৃত্যু। AB সুইচ সাধারণত একটি লম্বা অপারেটিং রড বা হ্যান্ডেল দিয়ে মাটি থেকে অপারেট করা হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্থ করা হ্যান্ডেল অপারেটরের সুরক্ষা দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চালানোর আগে হ্যান্ডেলের আর্থিং দেখে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'AB চালানো হয় মাটি থেকে, লম্বা হ্যান্ডেলে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্থ লিড কাটা থাকলেও হ্যান্ডেল নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বোল্ট না থাকলেও ক্ল্যাম্প এমনিই লেগে থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পোলে উঠে হাতে ব্লেড ঠেলাই সবচেয়ে সহজ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হ্যান্ডেলের আর্থিং শুধু নতুন সুইচে লাগে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শুকনো দিনে আর্থ লিড না থাকলেও চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গ্লাভস পরা থাকলে আর্থিং দেখার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'care',
      promptBn: 'কোন AB সুইচ ভালো অবস্থায় আছে?',
      options: [
        LearnBoardOption(
          id: 'clean',
          labelBn: 'পরিষ্কার কন্টাক্ট, ব্লেড পুরো বসানো',
          asset: 'assets/game/art/m6_board64/care_clean.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'horns',
          labelBn: 'কন্টাক্টে ছোট আর্কিং হর্ন, ইনসুলেটর পরিষ্কার',
          asset: 'assets/game/art/m6_board64/care_horns.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'black',
          labelBn: 'কন্টাক্টে কালো আর্কিং-এর দাগ',
          asset: 'assets/game/art/m6_board64/care_black.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্টাক্টে আর্কিং-এর চিহ্ন — টহলে ঠিক এটাই খুঁজতে হয়।',
        ),
        LearnBoardOption(
          id: 'dirty',
          labelBn: 'ইনসুলেটরে পুরু ময়লার আস্তর',
          asset: 'assets/game/art/m6_board64/care_dirty.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটরগুলো পরিষ্কার রাখা রক্ষণাবেক্ষণের প্রধান কাজ।',
        ),
        LearnBoardOption(
          id: 'jam',
          labelBn: 'মরচে-ধরা জ্যাম মেকানিজম, নড়ছেই না',
          asset: 'assets/game/art/m6_board64/care_jam.svg',
          scene: true,
          correct: false,
          rejectBn: 'জ্যাম হয়ে যাওয়া মেকানিজমকে লুব্রিকেট করতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টহলে দেখুন কন্টাক্ট ঠিক লেগে আছে কিনা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কন্টাক্টে আর্কিং-এর চিহ্ন খুঁজতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কন্টাক্ট ও ইনসুলেটর পরিষ্কার রাখা জরুরি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্কিং হর্ন মূল কন্টাক্টকে আর্ক থেকে বাঁচায়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'কন্টাক্টে কালো দাগ মানে ভালো লেগেছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ইনসুলেটরের ময়লা নিজে থেকেই ধুয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জ্যাম হ্যান্ডেল জোরে টানলেই ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আর্কিং হর্ন থাকলে সুইচ লোডেও খোলা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সুইচ চললেই হলো, যত্ন নেওয়ার দরকার নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board64Lines.rivalTaunt,
    rivalLineBn: M6Board64Lines.rivalMyth,
    exitBn: M6Board64Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'প্রচণ্ড আর্ক',
      'অপারেটর ঝুঁকিতে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সামান্য লোড কারেন্টেও বিপজ্জনক আর্ক হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: "'নো-লোড' মানে কার্যত শূন্য কারেন্ট", correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আইসোলেটর লোড কারেন্ট ব্রেক করার জন্য নয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'অল্প লোডে আইসোলেটর নিরাপদে খোলা যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'শুধু বেশি লোড থাকলেই আর্ক তৈরি হয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'হাই-ভোল্টেজে সামান্য কারেন্টে আর্ক হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আইসোলেটরের ভেতরে আর্ক নেভানোর ব্যবস্থা আছে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'কয়েকটা বাড়ির লোড আসলে কোনো লোডই নয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ব্রেকার খোলার ফোন শুধু কাগজের নিয়ম', correct: false),
    ],
  ),
);

/// The board's fixed spoken lines. Every new line is a DRAFT for the owner's
/// wording (ruling M6-12); recording comes after. [rivalExit] is already in
/// the careless coworker's recorded voice; [toRecord] stay silent (caption
/// held for reading) until the director records them with
/// `tool/rival_clip.py`.
abstract final class M6Board64Lines {
  // DRAFT wording — owner
  static const intro = 'AB সুইচ লাইনের ট্র্যাফিক পুলিশ — কিন্তু লোডে চালালেই বিপদ। চিনে নিন।';

  // DRAFT wording — owner
  static const earned = 'খোলার সময় আগে ব্রেকার, পরে আইসোলেটর; চালুর সময় উল্টো — আর তিন ফেজের গ্যাপ নিজের চোখে দেখুন।';

  // DRAFT wording — owner
  static const rivalTaunt = 'আরে, ব্রেকারের জন্য আবার ফোন? লোড তো সামান্য!';

  /// Lesson 6.4's first myth, word for word.
  static const rivalMyth = 'সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// New guide lines (drafts) for the owner's wording and the voice session.
  static const newGuideLines = [intro, earned];
}
