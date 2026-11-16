import 'learn_board_models.dart';

/// Module 8 Lesson 8.6 (গ্রাহক অভিযোগ নিষ্পত্তি (Grievance Redressal): আপনার
/// কাজের পর্যালোচনা), the picture board (rung `8.6/learn`, pack `learn_8_6`,
/// engineType `learn_cards`). Five rounds: the spec's six, minus the false
/// complaint round (ruling M8-21; `do_8_6_b` plays it).
///
/// Every round and trap comes from the live lesson text (ruling X3; the
/// lesson's own sentences are quoted in the reasons) and the Module 8 rulings
/// (`docs/module_specs/module8_rulings.md`, item spec
/// `docs/module_specs/module8_items/board_86.json`):
///  * docket: a complaint is a legal record only with a docket number (1912 toll
///    free, or the CCC counter); a spoken complaint has no value (lesson section 1);
///  * calm: pro tip 1 (no argument; the CGRF right and the form) and pro tip 3
///    (no promise the lineman cannot keep);
///  * close: the docket closes only after the report at the office; an open
///    docket adds to the SoP penalty (section 1, 'আপনার সুরক্ষা');
///  * cgrf: after the call centre fails, the CGRF (a company special court per
///    region or zone, with one neutral member) decides within 45 days (section 2);
///  * order: a CGRF order copy gets the top priority; the Ombudsman's ruling binds
///    the MD too (section 3, the Ombudsman tile);
///  * the rival's myth is the lesson's first myth, word for word (myth buster).
/// Compensation carries no amount on any card (ruling 'Lesson numbers': 8.6 has no
/// rupee figure). The 45-day and 60–90-day limits are reason-card content only.
///
/// Slip-only board (ruling M8-1, X1): the board has no deadly class and no freeze;
/// a trap costs the round's ◆ or a slip, and its reason is the lesson's own words.
/// Hand size 4 (one right, three wrong; ruling M8-21 and the board default), so
/// every round shows all three traps and a different safe picture. No YouTube explainer id (ruling M6-14).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
// DRAFT wording — owner (prompts, labels, reasons, intro, earned line, taunt).
const learnBoardPack86 = LearnBoardPack(
  lessonId: '8.6',
  titleBn: 'গ্রাহক অভিযোগ নিষ্পত্তি (Grievance Redressal): আপনার কাজের পর্যালোচনা',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'নালিশের আইনি রেকর্ড হলো ডকেট নম্বর। তর্ক নয়, ঠিক ধাপটা চিনুন।',
  earnedBn: 'ডকেট নম্বর ছাড়া আইনে নালিশ নেই; কাজ শেষে অফিসে রিপোর্ট করে ডকেট ক্লোজ করুন; CGRF-এর অর্ডার সবার আগে।',
  slots: [
    LearnBoardSlot(
      id: 'docket',
      promptBn: 'কোন ছবিতে নালিশটা আইনের রেকর্ড হলো?',
      options: [
        LearnBoardOption(
          id: 'call1912',
          labelBn: 'ফোনে 1912 নম্বর, আর ডকেটের SMS',
          asset: 'assets/game/art/m8_board86/docket_call1912.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ccc',
          labelBn: 'CCC কাউন্টারে ডকেট-স্লিপ, আইডি সহ',
          asset: 'assets/game/art/m8_board86/docket_ccc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: 'রাস্তায় চেঁচিয়ে বলা, হাতে কাগজ নেই',
          asset: 'assets/game/art/m8_board86/docket_shout.svg',
          scene: true,
          correct: false,
          // Lesson section 1: a spoken complaint has no value; the docket number is the record.
          rejectBn: 'মুখে বলা অভিযোগের কোনো দাম নেই — ডকেট নম্বর চাই।',
        ),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'চায়ের দোকানে প্রতিবেশীর মুখে খবর',
          asset: 'assets/game/art/m8_board86/docket_tea.svg',
          scene: true,
          correct: false,
          // Lesson section 1: without a docket number or complaint ID, no problem exists in law.
          rejectBn: 'ডকেট নম্বর বা কমপ্লেইন আইডি না হলে আইনের চোখে কোনো সমস্যাই নেই।',
        ),
        LearnBoardOption(
          id: 'palm',
          labelBn: 'তালুতে কলম দিয়ে অভিযোগ লেখা',
          asset: 'assets/game/art/m8_board86/docket_palm.svg',
          scene: true,
          correct: false,
          // Lesson section 1 (1912 or CCC is how a docket is made).
          rejectBn: 'নিজের হাতে লেখা নয় — 1912 বা CCC-তে অভিযোগ জানালে তবেই ডকেট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফোনে 1912 বা CCC-তে জানালে ডকেট হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডকেট নম্বরই আইনি রেকর্ড, মুখের কথা নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মুখে বলা অভিযোগের আইনে কোনো দাম নেই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জোরে চেঁচালে কোম্পানি তাড়াতাড়ি শোনে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নিজের হাতে লেখা নোটই সবচেয়ে পাকা প্রমাণ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্রতিবেশীর কথাই আইনে সবচেয়ে বড় সাক্ষী', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লাইনম্যানের মুখের কথায় ডকেট খোলা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রাস্তায় বললেই সেটা আইনি নথি হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফোন না করে অফিসে বলে গেলেই হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'calm',
      promptBn: 'গ্রাহক রেগে চেঁচাচ্ছেন। কোন লাইনম্যান ঠিক করছেন?',
      options: [
        LearnBoardOption(
          id: 'ask',
          labelBn: 'গ্রাহকের ফোনে ডকেট নম্বর দেখছেন',
          asset: 'assets/game/art/m8_board86/calm_ask.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'form',
          labelBn: 'গ্রাহকের হাতে CGRF-এর ফর্ম দিচ্ছেন',
          asset: 'assets/game/art/m8_board86/calm_form.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'argue',
          labelBn: 'দুজনেই রেগে, লাইনম্যান আঙুল তুলছেন',
          asset: 'assets/game/art/m8_board86/calm_argue.svg',
          scene: true,
          correct: false,
          // Pro tip 1 (no argument).
          rejectBn: 'আপনি তর্কের জায়গা নন — বিনয়ের সাথে জিজ্ঞাসা করুন, ডকেট করেছেন?',
        ),
        LearnBoardOption(
          id: 'promise',
          labelBn: 'থাম্বস-আপ, ক্যালেন্ডারে কাল গোল করা',
          asset: 'assets/game/art/m8_board86/calm_promise.svg',
          scene: true,
          correct: false,
          // Pro tip 3 (no promise the lineman cannot keep).
          rejectBn: 'নিশ্চিত না হলে "কালই হয়ে যাবে" বলবেন না — কথা না রাখলে অভিযোগ বড় হয়।',
        ),
        LearnBoardOption(
          id: 'brush',
          labelBn: 'হাত নেড়ে গ্রাহককে সরিয়ে দেওয়া',
          asset: 'assets/game/art/m8_board86/calm_brush.svg',
          scene: true,
          correct: false,
          // Myth buster reality: WBERC and the Ombudsman are consumer-friendly.
          rejectBn: 'WBERC আর অম্বুডসম্যান গ্রাহক-বান্ধব — গাফিলতি থাকলে রায় গ্রাহকের পক্ষে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রাগী গ্রাহকের সাথে তর্ক নয়, শান্ত থাকুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বিনয়ে কথা বললে গ্রাহকের রাগ কমে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আপনি তর্কের জায়গা নন, পথ দেখিয়ে দিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জোরে কথা বললে গ্রাহক ভয় পেয়ে চুপ করেন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কাল হয়ে যাবে বললে সমস্যা নিজে মেটে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রেগে থাকলে গ্রাহককে চুপ করিয়ে দিতে হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রাগী গ্রাহককে এড়িয়ে যাওয়াই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তর্ক করে নিজের ঠিকটা প্রমাণ করা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গ্রাহক চুপ করলে সমস্যা নিজেই মিটে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'close',
      promptBn: 'কাজ শেষ। এবার ডকেটের জন্য কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'office',
          labelBn: 'অফিসের ডেস্কে স্লিপে CLOSED ছাপ',
          asset: 'assets/game/art/m8_board86/close_office.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'phone',
          labelBn: 'ভ্যানের পাশে ফোনে অফিসে স্লিপ পড়া',
          asset: 'assets/game/art/m8_board86/close_phone.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'van',
          labelBn: 'সন্ধ্যায় ভ্যান চলে যায়, স্লিপে ছাপ নেই',
          asset: 'assets/game/art/m8_board86/close_van.svg',
          scene: true,
          correct: false,
          // Section 1 'আপনার সুরক্ষা': the docket closes only after the office report.
          rejectBn: 'কাজ শেষ করে অফিসে রিপোর্ট না করা পর্যন্ত ডকেট ক্লোজ হয় না।',
        ),
        LearnBoardOption(
          id: 'board',
          labelBn: 'দেয়ালে খোলা ডকেটের তালিকা, দাগ বাড়ছে',
          asset: 'assets/game/art/m8_board86/close_board.svg',
          scene: true,
          correct: false,
          // Section 1 'আপনার সুরক্ষা': the SoP penalty grows while a docket is open.
          rejectBn: 'ডকেট ওপেন থাকলে SoP-এর জরিমানা বাড়তে থাকে।',
        ),
        LearnBoardOption(
          id: 'customer',
          labelBn: 'গ্রাহককে বলে কাজ শেষ, চলে যাওয়া',
          asset: 'assets/game/art/m8_board86/close_customer.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহককে বলা নয় — অফিসে রিপোর্ট করলে তবেই ডকেট ক্লোজ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাজ শেষে অফিসে রিপোর্ট করলেই ডকেট ক্লোজ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডকেট খোলা থাকলে SoP-এর জরিমানা বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাজ শেষ মানেই ডকেট ক্লোজ নয়, রিপোর্ট চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কাজ শেষ, তাই ডকেট নিজেই ক্লোজ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রাহককে বললেই ডকেট ক্লোজ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডকেট খোলা থাকলে তেমন ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'SoP-এর জরিমানা শুধু বড় ফল্টে লাগে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্লিপ বাড়িতে নিয়ে গেলেও ডকেট ঠিক থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভ্যান ফিরলে কাল রিপোর্ট করলেই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'cgrf',
      promptBn: 'কল সেন্টারে সমাধান হয়নি। গ্রাহক এবার কোথায় যাবেন?',
      options: [
        LearnBoardOption(
          id: 'bench',
          labelBn: 'ফোরাম ঘর, অফিসার আর নিরপেক্ষ সদস্য',
          asset: 'assets/game/art/m8_board86/cgrf_bench.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'form',
          labelBn: 'CGRF-এর ফর্ম ভরছেন গ্রাহক, পাশে লাইনম্যান',
          asset: 'assets/game/art/m8_board86/cgrf_form.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'street',
          labelBn: 'রাস্তায় ঝগড়া, চারদিকে ভিড় জমছে',
          asset: 'assets/game/art/m8_board86/cgrf_street.svg',
          scene: true,
          correct: false,
          // Myth buster / pro tip: complain at the right place, not in a quarrel.
          rejectBn: 'ঝগড়া না করে সঠিক জায়গায় কমপ্লেইন করুন — কাজ হবে।',
        ),
        LearnBoardOption(
          id: 'home',
          labelBn: 'রাতে লাইনম্যানের বাড়ির দরজায় ধাক্কা',
          asset: 'assets/game/art/m8_board86/cgrf_home.svg',
          scene: true,
          correct: false,
          // Section 2: the CGRF is a company special court per region or zone.
          rejectBn: 'জায়গাটা CGRF — প্রতিটি রিজিয়ন বা জোনে কোম্পানির তৈরি একটি বিশেষ আদালত।',
        ),
        LearnBoardOption(
          id: 'giveup',
          labelBn: 'স্লিপ ছিঁড়ে অন্ধকারে একা বসে থাকা',
          asset: 'assets/game/art/m8_board86/cgrf_giveup.svg',
          scene: true,
          correct: false,
          // Section 2: after the call centre, the consumer applies to the CGRF.
          rejectBn: 'কল সেন্টারে সমস্যার সমাধান না হলে গ্রাহক CGRF-এ আবেদন করে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কল সেন্টারে না মিটলে CGRF-এ আবেদন হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'CGRF-এ একজন নিরপেক্ষ সদস্যও থাকেন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'CGRF প্রতি রিজিয়নে কোম্পানির বিশেষ আদালত', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রাস্তায় চেঁচালে CGRF তাড়াতাড়ি রায় দেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লাইনম্যানের বাড়িতে গেলে নালিশ জোরালো হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'CGRF শুধু কোম্পানির অফিসারদের নিয়ে গড়া', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কল সেন্টারে না মিটলেও অভিযোগ থেমে থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্লিপ ছিঁড়লে অভিযোগ আপনিই মিটে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঝগড়া করলে CGRF-এর রায় দ্রুত হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'order',
      promptBn: 'রায় এসেছে। কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'top',
          labelBn: 'অর্ডারের কপি সবার ওপরে, সেই কাজ আগে',
          asset: 'assets/game/art/m8_board86/order_top.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'md',
          labelBn: 'MD অম্বুডসম্যানের রায় চালু করতে বলছেন',
          asset: 'assets/game/art/m8_board86/order_md.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'drawer',
          labelBn: 'CGRF-এর অর্ডারের কপি ড্রয়ারে ঠেলে রাখা',
          asset: 'assets/game/art/m8_board86/order_drawer.svg',
          scene: true,
          correct: false,
          // Section 2 'daily check': a CGRF order copy gets the top priority.
          rejectBn: 'CGRF-এর অর্ডারের কপি এলে সর্বোচ্চ গুরুত্ব দিয়ে কাজ করতে হয়।',
        ),
        LearnBoardOption(
          id: 'tears',
          labelBn: 'এক অফিসার অম্বুডসম্যানের রায় ছিঁড়ছেন',
          asset: 'assets/game/art/m8_board86/order_tears.svg',
          scene: true,
          correct: false,
          // Section 3: the Ombudsman's ruling binds the MD too.
          rejectBn: 'অম্বুডসম্যানের রায় কোম্পানির এমডি (MD)-কেও মানতে হয়।',
        ),
        LearnBoardOption(
          id: 'later',
          labelBn: 'অর্ডার টেবিলে, তারিখ অনেক দূরে, চা খাওয়া',
          asset: 'assets/game/art/m8_board86/order_later.svg',
          scene: true,
          correct: false,
          rejectBn: 'অর্ডার এলে সবার আগে সেই কাজ — CGRF-এর অর্ডারের কপি সর্বোচ্চ গুরুত্ব পায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রায় বা অর্ডার এলে সেই কাজই সবার আগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'CGRF বা অম্বুডসম্যানের রায় মানতেই হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রায়ের কাজ ফেলে রাখা কোনোভাবেই চলে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অর্ডার পরে দেখলেও চলে, কাজ আগে হয়েছে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অম্বুডসম্যানের রায় কোম্পানি ইচ্ছেমতো বদলায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'MD রায় না মানলেও তেমন ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অর্ডারের কপি ড্রয়ারে রাখলে ফাইলে থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'CGRF-এর অর্ডার শুধু নথির জন্য, কাজের নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দিনের কাজের তালিকায় অর্ডার না তুললেও চলে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board86Lines.rivalTaunt,
    rivalLineBn: M8Board86Lines.rivalMyth,
    exitBn: M8Board86Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    flipStingBn: 'এই লোক যা বলছে… সেটা কি ভুল?',
    dangerHints: [
      'কেস করা যায় না',
      'গ্রাহকের কোনো উপায় নেই',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'WBERC আর অম্বুডসম্যান গ্রাহকের পক্ষে রায় দেয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'গাফিলতি থাকলে কোম্পানিকেই ক্ষতিপূরণ দিতে হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সরকারি হোক বা প্রাইভেট, রায় মানতেই হয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'সরকারি কোম্পানির নামে কেস করা আইনে বারণ', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'বড় কোম্পানির বিরুদ্ধে গ্রাহকের কোনো উপায় নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অম্বুডসম্যানের রায় কোম্পানি ইচ্ছে হলে মানে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'কেস করলে গ্রাহকের বিদ্যুৎ কেটে দেওয়া হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'গাফিলতি থাকলেও কোম্পানি কখনো দায়ী হয় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিযোগ শুধু বিল নিয়ে হয়, অন্য কিছুতে নয়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M8Board86Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, আমাদের নামে কেস? ওসব কিছু হয় না!';

  /// Lesson 8.6's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'আমাদের কোম্পানি সরকারি (বা বড় প্রাইভেট), আমাদের নামে কেস করে গ্রাহক কিছু করতে পারবে না।';

  /// Already recorded (the same clip Module 6 uses).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// The same two lines, as the rival's new lines for the voice session (DRAFT wording — owner).
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack86;
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
