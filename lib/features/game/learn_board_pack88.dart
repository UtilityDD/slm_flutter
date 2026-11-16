import 'learn_board_models.dart';

/// Module 8 Lesson 8.8 (নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম),
/// the picture board (rung `8.8/learn`, pack `learn_8_8`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board88_art.py` (the labels a
/// worker reads, such as an LCD reading or a kW figure, are English digits
/// drawn as strokes; no words are drawn). Every round and trap comes from the
/// live lesson text (`tool/all_training_chapters_bn.json`, lesson 8.8) and the
/// Module 8 rulings (`docs/module_specs/module8_rulings.md`, item spec
/// `docs/module_specs/module8_items/board_88.json`):
///  * meter: a solar house needs a bi-directional net meter whose Import and
///    Export are read apart (lesson section 1). Traps: a single-register meter,
///    an old disc meter, an inverter wired to the house board with the meter
///    box empty;
///  * shutdown: on a shutdown in a solar area the transformer's AB switch is
///    opened and locked and tagged (ruling M8-19: WBSEDCL DTR = AB switch + HG
///    fuses), and the solar house's own fuse is pulled from the pole before
///    anyone climbs (pro tip 1; ruling M8-2: climbing with a solar fuse in is
///    deadly every time). Traps: the transformer OFF alone and a climb with
///    every fuse in (the deadly class, taught with the pro tip's own words),
///    a ladder wave at the roof, the wrong house's fuse pulled;
///  * inverter: after the line is switched OFF the solar house's inverter must
///    also be OFF (lesson section 2, anti-islanding and back-feed); a lit,
///    fanning or unchecked inverter is the trap;
///  * load: the solar capacity is at most 100 % of the sanctioned load
///    (lesson section 3). Traps: 167 %, 133 % and 300 %; the two safe cards are
///    3 kW on 3 kW and 4 kW on 5 kW;
///  * bill: net units are Import minus Export; the fixed charge is always
///    paid; a surplus can be banked (advanced facts). Traps: a zero bill, the
///    full Import with Export ignored, Export added to the units.
/// The rival's myth is the lesson's first myth, word for word (lesson 8.8
/// myth 1). Five rounds (ruling M8-21); 5 pictures per round, one safe picture
/// and every trap in each hand (4 cards); `youtubeId: null` (ruling M6-14).
///
/// The shutdown round's DTR has its AB switch open, padlocked and tagged, with
/// HG fuses, never a 'DO fuse' (M8-19). The inverter round's LT switch is drawn OFF. LT, HT, kW, kVA and 11 kV are English letters; switch
/// and line states are ON / OFF; closing an AB is «AB লাগানো» (never «AB বন্ধ»).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M8-14, M6-12).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack88 = LearnBoardPack(
  lessonId: '8.8',
  titleBn: 'নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'ছাদের সোলার বাড়ি গ্রিডে বিদ্যুৎ ফেরত পাঠায়। মিটার, শাটডাউন, ইনভার্টার আর বিল, সবটাই সাবধানে বাছুন।',
  earnedBn: 'নেট মিটার, সোলার ফিউজ খোলা, ইনভার্টার OFF আর অনুমোদিত লোডের সীমা, সবই মেলাতে হয়।',
  slots: [
    LearnBoardSlot(
      id: 'meter',
      promptBn: 'ছাদে সোলার বসেছে — এ বাড়িতে কোন মিটার চাই?',
      options: [
        LearnBoardOption(
          id: 'pages',
          labelBn: 'বাই-ডিরেকশনাল মিটার, Import আর Export আলাদা পাতায়',
          asset: 'assets/game/art/m8_board88/meter_pages.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'arrow',
          labelBn: 'বাই-ডিরেকশনাল মিটার, রোদে Export-এর তীর জ্বলছে',
          asset: 'assets/game/art/m8_board88/meter_arrow.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'single',
          labelBn: 'সাধারণ এক-রেজিস্টারের মিটার, ছাদে সোলার প্যানেল',
          asset: 'assets/game/art/m8_board88/meter_single.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ মিটারে সোলার লাগালে আপনি বিদ্যুৎ দিলেও সেটা খরচ হিসেবে দেখাবে — বিল বেড়ে যাবে।',
        ),
        LearnBoardOption(
          id: 'disc',
          labelBn: 'পুরনো ডিস্ক-টাইপ মিটার, সোলার বাড়িতে বসানো',
          asset: 'assets/game/art/m8_board88/meter_disc.svg',
          scene: true,
          correct: false,
          rejectBn: 'এ মিটার এক দিকেই মাপে — সোলারে বিশেষ নেট-মিটার লাগানো বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'empty',
          labelBn: 'ইনভার্টার সরাসরি বাড়ির বোর্ডে, মিটার বক্স খালি',
          asset: 'assets/game/art/m8_board88/meter_empty.svg',
          scene: true,
          correct: false,
          rejectBn: 'সোলার থাকলে নেট-মিটার বাধ্যতামূলক — Import আর Export আলাদা মাপতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নেট মিটার দুই দিকে মাপে: Import আর Export', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'Export আলাদা মাপে, তাই বাই-ডিরেকশনাল মিটার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সাধারণ মিটারে দেওয়া বিদ্যুৎও খরচ ধরা পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সোলার থাকলে নেট-মিটার লাগানো বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সাধারণ মিটারই যথেষ্ট, শুধু সংখ্যা বাড়লেই হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পুরনো ডিস্ক মিটার এখনো সবচেয়ে নির্ভুল', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ইনভার্টার সরাসরি বোর্ডে জুড়লে মিটার লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মিটার বক্স খালি রেখেও নেট-মিটারের হিসাব চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রোদ থাকলে মিটার লাগে না, শুধু প্যানেল দরকার', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'shut',
      promptBn: 'সোলার পাড়ায় শাটডাউন — কোন ছবিতে ব্যাক-ফিডের পথ বন্ধ?',
      options: [
        LearnBoardOption(
          id: 'pull',
          labelBn: 'ট্রান্সফরমার OFF, শাটডাউন ট্যাগ, পোলে ফিউজ খুলছেন',
          asset: 'assets/game/art/m8_board88/shut_pull.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'ট্রান্সফরমার OFF, সোলার বাড়ির ফিউজ আগেই খোলা, ট্যাগ ঝোলানো',
          asset: 'assets/game/art/m8_board88/shut_fuse.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dtr',
          labelBn: 'শুধু ট্রান্সফরমার OFF, রোদে প্যানেল, ফিউজ সব ঢোকানো',
          asset: 'assets/game/art/m8_board88/shut_dtr.svg',
          scene: true,
          correct: false,
          // Pro tip 1 (ruling M8-2: a climb with a solar fuse in is deadly).
          rejectBn: 'শুধু ট্রান্সফরমার OFF করবেন না। পোল থেকে ওই বাড়ির ফিউজও খুলে দিন।',
        ),
        LearnBoardOption(
          id: 'wave',
          labelBn: 'মইয়ে উঠে ছাদের দিকে তাকাচ্ছেন, ভাবছেন ইনভার্টার নিজেই OFF',
          asset: 'assets/game/art/m8_board88/shut_wave.svg',
          scene: true,
          correct: false,
          rejectBn: 'বিশ্বাসে মিলায় বস্তু, কিন্তু সোলারে মিলায় মৃত্যু! ফিউজ খুলে তবে উঠুন।',
        ),
        LearnBoardOption(
          id: 'wrong',
          labelBn: 'সাধারণ বাড়ির ফিউজ খোলা, সোলার বাড়ির ফিউজ ঢোকানো',
          asset: 'assets/game/art/m8_board88/shut_wrong.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছাদের সোলার ভোল্টেজ পাঠিয়ে লাইন সজীব রাখে — ফিউজ খুলতে হবে সোলার বাড়িরই।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সোলার বাড়ির ফিউজ পোল থেকে খুলে তবে ওঠা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডবল চেকিং: ট্রান্সফরমার আর বাড়ির ফিউজ দুটোই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শাটডাউনের পরেও সোলার বাড়ি ব্যাক-ফিড দিতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সোলার বাড়ির ফিউজ খুললে তবেই লাইন নিরাপদ', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'শুধু ট্রান্সফরমার OFF হলেই পোলে ওঠা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সোলার প্যানেল রোদে থাকলে লাইন নিরাপদ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ইনভার্টার নিজেই OFF হয়, ফিউজ লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সাধারণ বাড়ির ফিউজ খুললেই পোলে ওঠা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মইয়ে উঠে দূর থেকে দেখলেই লাইন নিরাপদ হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'inv',
      promptBn: 'লাইন OFF করেছেন — সোলার বাড়ির ইনভার্টার কেমন থাকা চাই?',
      options: [
        LearnBoardOption(
          id: 'dark',
          labelBn: 'লাইন OFF করার পরে বারান্দার ইনভার্টারও OFF',
          asset: 'assets/game/art/m8_board88/inv_dark.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wall',
          labelBn: 'লাইন OFF করে দেওয়ালের ইনভার্টার দেখছেন, OFF হয়েছে',
          asset: 'assets/game/art/m8_board88/inv_wall.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lit',
          labelBn: 'লাইন OFF, তবু ইনভার্টারের আলো জ্বলছে, আউটপুট চলছে',
          asset: 'assets/game/art/m8_board88/inv_lit.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রিডের কারেন্ট চলে গেলে ইনভার্টার অটোমেটিক OFF হতেই হবে — না হলে ব্যাক-ফিড।',
        ),
        LearnBoardOption(
          id: 'fan',
          labelBn: 'অন-গ্রিড বাড়ি, ব্যাটারি নেই, লোড শেডিংয়ে ফ্যান ঘোরে',
          asset: 'assets/game/art/m8_board88/inv_fan.svg',
          scene: true,
          correct: false,
          rejectBn: 'অন-গ্রিডে গ্রিড OFF হলে সোলারও OFF হয় — চললে লাইনম্যান ব্যাক-ফিডে মারা যাবে।',
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'লাইন OFF করে ইনভার্টার না দেখেই পোলের দিকে হাঁটা',
          asset: 'assets/game/art/m8_board88/inv_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'সোলার বাড়িতে লাইন OFF করে দেখুন ইনভার্টারও OFF হয়েছে কি না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইন OFF হলে সোলার ইনভার্টারও OFF হওয়া চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গ্রিড OFF হলে ইনভার্টার নিজে OFF হয়ে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লাইন OFF করে ইনভার্টারও OFF হয়েছে কি না দেখা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ইনভার্টার চললে ব্যাক-ফিডে লাইনম্যান মারা যাবে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'ইনভার্টার চললেও লাইনে কোনো ঝুঁকি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আউটপুট দেখাচ্ছে, তাই গ্রিড ঠিক আছে ধরে নিন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অন-গ্রিড বাড়িতে ব্যাটারি ছাড়াই ফ্যান চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লাইন OFF করলেই ইনভার্টার দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফ্যান ঘুরলে বুঝতে হবে লাইন সত্যিই OFF', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'load',
      promptBn: 'কার্ডে স্যাংশনড লোড দেখুন — কোন সোলার আবেদন চলে?',
      options: [
        LearnBoardOption(
          id: 'eq3',
          labelBn: 'স্যাংশনড লোড 3 kW, সোলার 3 kW',
          asset: 'assets/game/art/m8_board88/load_eq3.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lt5',
          labelBn: 'স্যাংশনড লোড 5 kW, সোলার 4 kW',
          asset: 'assets/game/art/m8_board88/load_lt5.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'over5',
          labelBn: 'স্যাংশনড লোড 3 kW, সোলার 5 kW',
          asset: 'assets/game/art/m8_board88/load_over5.svg',
          scene: true,
          correct: false,
          rejectBn: 'WBERC-এর নিয়ম অনুযায়ী, অনুমোদিত লোডের 100%-এর বেশি সোলার বসানো যায় না।',
        ),
        LearnBoardOption(
          id: 'over4',
          labelBn: 'স্যাংশনড লোড 3 kW, সোলার 4 kW',
          asset: 'assets/game/art/m8_board88/load_over4.svg',
          scene: true,
          correct: false,
          rejectBn: 'সীমা ছাড়ালে ট্রান্সফরমারের ওপর চাপ বাড়ে — তাই লোডের 100% পর্যন্তই।',
        ),
        LearnBoardOption(
          id: 'two6',
          labelBn: 'স্যাংশনড লোড 2 kW, সোলার 6 kW',
          asset: 'assets/game/art/m8_board88/load_two6.svg',
          scene: true,
          correct: false,
          rejectBn: 'বেশি সোলারে টেকনিক্যাল লস বাড়ে — অনুমোদিত লোডের ওপরে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অনুমোদিত লোডের 100% পর্যন্ত সোলার বসানো যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সীমা মেনে সোলার বসালে ট্রান্সফরমারে চাপ কম', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সোলার অনুমোদিত লোডের বেশি হলে আবেদন চলে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আবেদনের আগে কার্ডে স্যাংশনড লোড মিলিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'বেশি সোলার হলে নেট-মিটারে বিল আরও কমে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সোলার যত বড় হয়, আবেদনে তত সুবিধা মেলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অনুমোদিত লোড না দেখেও আবেদন করা চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সোলার ক্ষমতা আন্দাজে বাড়ালেও ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ছাদ বড় হলে যত ইচ্ছে সোলার বসানো যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bill',
      promptBn: 'নেট মিটারিং-এ গ্রাহকের বিল কেমন হবে?',
      options: [
        LearnBoardOption(
          id: 'net',
          labelBn: 'Import 300, Export 120: 180 ইউনিট, ফিক্সড চার্জ',
          asset: 'assets/game/art/m8_board88/bill_net.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'winter',
          labelBn: 'শীতে Export 260, Import 150: 110 জমা, ফিক্সড চার্জ',
          asset: 'assets/game/art/m8_board88/bill_winter.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'zero',
          labelBn: 'সোলার লাগালে বিল শূন্য, ফিক্সড চার্জও লাগে না',
          asset: 'assets/game/art/m8_board88/bill_zero.svg',
          scene: true,
          correct: false,
          rejectBn: 'সোলার লাগালে বিল শূন্য হয় না — ফিক্সড চার্জ তো দিতেই হবে।',
        ),
        LearnBoardOption(
          id: 'full',
          labelBn: 'Import 300-এর পুরো বিল, Export ধরা হয়নি',
          asset: 'assets/game/art/m8_board88/bill_full.svg',
          scene: true,
          correct: false,
          rejectBn: 'যতটা ব্যবহার আর যতটা তৈরি — তার পার্থক্যের বিল হবে।',
        ),
        LearnBoardOption(
          id: 'add',
          labelBn: 'Import 300 আর Export 120 যোগ করে 420 ইউনিট',
          asset: 'assets/game/art/m8_board88/bill_add.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রিডে দেওয়া বিদ্যুৎ খরচ নয় — নেট মিটারে পার্থক্যেরই বিল।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বিল হয় ব্যবহার আর উৎপাদনের পার্থক্যে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শীতে জমানো ইউনিট গরমে ব্যবহার করা যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সোলার থাকলেও ফিক্সড চার্জ তো দিতেই হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'Export গ্রিডে যায়, তাই খরচে যোগ হয় না', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সোলার লাগালে বিল একদম শূন্য হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'Import পুরোটাই বিল, Export ধরা হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'Export যোগ করলে মোট ইউনিট আরও বেড়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জমানো ইউনিট গরমেও কখনো কাজে লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বিল এলে বোঝা যায় সোলার মোটেই কাজ করছে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board88Lines.rivalTaunt,
    rivalLineBn: M8Board88Lines.rivalMyth,
    exitBn: M8Board88Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'গ্রিড OFF, তবু ফ্যান?',
      'ব্যাক-ফিড কারেন্ট',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'অন-গ্রিডে গ্রিড OFF হলে সোলারও OFF হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'লোড শেডিংয়ে চালাতে হাইব্রিড ইনভার্টার ও ব্যাটারি', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সোলার চললে লাইনম্যান ব্যাক-ফিডে মারা যাবে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'অ্যান্টি-আইলন্ডিং: গ্রিড OFF হলে ইনভার্টারও OFF', correct: true),
      LearnWhyChip(id: 'm5', textBn: 'ছাদের প্যানেল থাকলেই লোড শেডিংয়ে ফ্যান ঘোরে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অ্যান্টি-আইলন্ডিং ইনভার্টার নিজে বিদ্যুৎ দেয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'গ্রিড OFF থাকলেও অন-গ্রিড সোলার নিজেই চলে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'হাইব্রিড ইনভার্টার ছাড়াই লোড শেডিংয়ে সোলার চলে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ব্যাটারি না থাকলেও গ্রিড ছাড়া সোলার চলে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M8Board88Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'সোলার তো ছাদের ব্যাপার, মিটার নিয়ে এত ভাবনা কেন!';

  /// Lesson 8.8's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'সোলার বসালে লোড শেডিং-এও আমার বাড়িতে ফ্যান চলবে।';

  /// Already recorded (reused from Module 6).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// DRAFT wording — owner. The rival's lines on this board are the ones to record.
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack88;
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
