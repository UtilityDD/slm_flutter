import 'learn_board_models.dart';

/// Module 7 Lesson 7.9 (গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব), the picture
/// board (rung `7.9/learn`, pack `learn_7_9`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board79_art.py` (no words in
/// the art; the meter's digits are stroke glyphs with English digits). Every
/// round and trap comes from the live lesson text
/// (`tool/all_training_chapters_bn.json`, 7.9) and the Module 7 rulings
/// (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_79.json`):
///  * arrive: section 3 — show the company ID card before the customer asks
///    (and her right to see it, section 1), and say in plain words what work
///    you came for and why. Traps: walking in with the card in the pocket,
///    showing it only when asked, a uniform instead of the card, opening the
///    meter in silence, laughing the question off (myth 2's reality);
///  * entry: section 2 — the company's man may enter to read, inspect, test or
///    repair, but only after reasonable notice (an emergency apart) and never
///    by force or without the customer's permission. Traps: over the wall of a
///    padlocked house, pushing in past a raised palm, no notice;
///  * zone: myth 1's reality — the right of entry stops at the places the
///    work needs (the meter box, the wiring route); the customer's privacy is
///    yours to respect. Traps: a bedroom, the almirah, a peek into a family
///    room;
///  * talk: pro tips 1 and 2 — no argument with an angry customer, listen
///    calmly; promise nothing that is not in your hands (the transformer),
///    give the true facts and tell your superior;
///  * finish: section 3 and pro tip 4 — leave the work place clean, damage
///    nothing of the customer's, and fill the job sheet with her signature
///    (the proof of your work).
/// Ruling X6 trims the item spec's six rounds to five: its ID round and its
/// explain-the-work round are one round, at the door.
/// No deadly act on this board (ruling M7-6): every trap is a slip (R26); boards
/// have no freeze (kit design), so a trap teaches with the lesson's words.
/// Pro tip 3 (a woman alone at home: take a colleague or a local person as
/// witness) is not played here; it is an open question for the owner.
/// The rival's myth is the lesson's first myth, word for word (ruling M7-10).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack79 = LearnBoardPack(
  lessonId: '7.9',
  titleBn: 'গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board79Lines.intro,
  earnedBn: M7Board79Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'arrive',
      promptBn: 'গ্রাহকের বাড়ির দরজায় পৌঁছেছেন — প্রথমে কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'id',
          labelBn: 'গ্রাহক চাওয়ার আগেই পরিচয়পত্র দেখাচ্ছেন',
          asset: 'assets/game/art/m7_board79/arrive_id.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'say',
          labelBn: 'পরিচয়পত্র দেখিয়ে সহজ কথায় কাজটা বোঝাচ্ছেন',
          asset: 'assets/game/art/m7_board79/arrive_say.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'পরিচয়পত্র পকেটে রেখে সোজা ভেতরে ঢুকছেন',
          asset: 'assets/game/art/m7_board79/arrive_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহক চাওয়ার আগেই পরিচয়পত্র দেখান — অনুমতি ছাড়া বাড়িতে ঢোকা যায় না।',
        ),
        LearnBoardOption(
          id: 'demand',
          labelBn: 'গ্রাহক চাইলে তবেই পরিচয়পত্র বের করছেন',
          asset: 'assets/game/art/m7_board79/arrive_demand.svg',
          scene: true,
          correct: false,
          rejectBn: 'পরিচয়পত্র গ্রাহক চাওয়ার আগেই দেখান — কাজের সময় এটা দেখার অধিকার গ্রাহকের।',
        ),
        LearnBoardOption(
          id: 'uniform',
          labelBn: 'শুধু ইউনিফর্ম দেখিয়ে পরিচয় দিচ্ছেন',
          asset: 'assets/game/art/m7_board79/arrive_uniform.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইউনিফর্ম পরিচয়পত্র নয় — কাজের সময় পরিচয়পত্র দেখার অধিকার গ্রাহকের আছে।',
        ),
        LearnBoardOption(
          id: 'silent',
          labelBn: 'কিছু না বলে মিটারের ঢাকনা খুলছেন',
          asset: 'assets/game/art/m7_board79/arrive_silent.svg',
          scene: true,
          correct: false,
          rejectBn: 'কী কাজ করতে এসেছেন এবং কেন, তা সহজ ভাষায় গ্রাহককে বোঝান।',
        ),
        LearnBoardOption(
          id: 'laugh',
          labelBn: 'প্রশ্ন শুনে হেসে বলছেন, আপনি বুঝবেন না',
          asset: 'assets/game/art/m7_board79/arrive_laugh.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহক কিছুই বোঝেন না — এই ভাবনা অপেশাদার ও ভুল; সঠিক তথ্য দিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পরিচয়পত্র গ্রাহক চাওয়ার আগেই দেখাতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের সময় পরিচয়পত্র দেখার অধিকার গ্রাহকের', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে নিজের পরিচয় দিন, তারপর কাজের কথা বলুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্রাহক না চাইলে পরিচয়পত্র দেখানোর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ইউনিফর্ম পরা থাকলে আলাদা পরিচয়পত্র লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্রাহক বোঝেন না, তাই কাজ বলার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কোম্পানির লোক হলে বলার আগেই ঢুকে পড়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পরিচয়পত্র শুধু অফিসের ভেতরে দেখাতে হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আগে কাজ শুরু করে পরে বললেও কোনো ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'entry',
      promptBn: 'মিটার পরীক্ষার জন্য গ্রাহকের বাড়িতে ঢুকবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'invited',
          labelBn: 'নোটিশ দেওয়া ছিল, গ্রাহক ভেতরে ডাকছেন',
          asset: 'assets/game/art/m7_board79/entry_invited.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'আগে থেকে জানাতে গেটে নোটিশ দিয়ে যাচ্ছেন',
          asset: 'assets/game/art/m7_board79/entry_slip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'তালা দেওয়া বাড়ির পাঁচিল টপকে ঢুকছেন',
          asset: 'assets/game/art/m7_board79/entry_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'জোর করে বা গ্রাহকের অনুমতি ছাড়া কারও বাড়িতে প্রবেশ করা যায় না।',
        ),
        LearnBoardOption(
          id: 'push',
          labelBn: 'গ্রাহক হাত তুলে মানা করছেন, তবু ঢুকছেন',
          asset: 'assets/game/art/m7_board79/entry_push.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহক অনুমতি না দিলে ঢোকা যায় না — জোর করে প্রবেশ করা যায় না।',
        ),
        LearnBoardOption(
          id: 'unannounced',
          labelBn: 'নোটিশ ছাড়াই উঠোনে ঢুকে পড়েছেন',
          asset: 'assets/game/art/m7_board79/entry_unannounced.svg',
          scene: true,
          correct: false,
          rejectBn: 'জরুরি অবস্থা ছাড়া, ঢোকার আগে গ্রাহককে যুক্তিসঙ্গত নোটিশ দিতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে নোটিশ দিন, তারপর গ্রাহকের অনুমতিতে ঢুকুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জোর করে বা অনুমতি ছাড়া ঢোকার অধিকার নেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জরুরি অবস্থা ছাড়া যুক্তিসঙ্গত নোটিশ দিতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মিটারের কাজ থাকলে পাঁচিল টপকানোও চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কোম্পানির লোক, তাই অনুমতি ছাড়াই ঢোকা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নোটিশ দেওয়া শুধু সময় নষ্ট, সোজা ঢুকে পড়ুন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্রাহক মানা করলেও কাজ আগে, ঢুকে যান', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গেটে তালা থাকলে জোরে ঠেলে খুললেই হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নোটিশ ছাড়া ঢুকলেও কোনো সমস্যা হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'zone',
      promptBn: 'বাড়ির ভেতরে কাজ করছেন — আপনার জায়গা কোথায়?',
      options: [
        LearnBoardOption(
          id: 'meter',
          labelBn: 'শুধু মিটার বক্সেই কাজ করছেন',
          asset: 'assets/game/art/m7_board79/zone_meter.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'route',
          labelBn: 'ওয়্যারিং-এর রুট ধরে লাইনটা দেখছেন',
          asset: 'assets/game/art/m7_board79/zone_route.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bedroom',
          labelBn: 'শোবার ঘরের পর্দা সরিয়ে ঢুকছেন',
          asset: 'assets/game/art/m7_board79/zone_bedroom.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রবেশের অধিকার শুধু কাজের জায়গায় — মিটার বক্স আর ওয়্যারিং-এর রুট।',
        ),
        LearnBoardOption(
          id: 'almirah',
          labelBn: 'গ্রাহকের স্টিলের আলমারি খুলছেন',
          asset: 'assets/game/art/m7_board79/zone_almirah.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহকের ব্যক্তিগত গোপনীয়তাকে সম্মান করা আপনার দায়িত্ব — কাজের বাইরে হাত নয়।',
        ),
        LearnBoardOption(
          id: 'peek',
          labelBn: 'পাশের ঘরের জানালায় উঁকি দিচ্ছেন',
          asset: 'assets/game/art/m7_board79/zone_peek.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজের সঙ্গে সম্পর্কহীন জায়গায় যাওয়া বা উঁকি দেওয়া — গোপনীয়তা ভঙ্গ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাজের জায়গা মানে মিটার বক্স, ওয়্যারিং-এর রুট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গ্রাহকের গোপনীয়তাকে সম্মান করা আপনার দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'প্রবেশের অধিকার শুধু কাজের জায়গায় সীমিত', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাড়িতে ঢুকলে সব ঘরেই যাওয়ার অধিকার থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আলমারি খুলে দেখলে কাজ আরও ভালো বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঘরের ভেতর একটু উঁকি দিলে কোনো দোষ নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্রাহক না দেখলে যেকোনো জায়গায় যাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কোম্পানির লোকের কাছে সব ঘরই কাজের জায়গা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'শোবার ঘরের পর্দা সরানো আইনেই অনুমোদিত', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'talk',
      promptBn: 'গ্রাহক রেগে বলছেন ট্রান্সফরমার বদলাতে হবে — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'listen',
          labelBn: 'শান্ত হয়ে গ্রাহকের সব কথা মন দিয়ে শুনছেন',
          asset: 'assets/game/art/m7_board79/talk_listen.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'report',
          labelBn: 'ফোনে ঊর্ধ্বতন কর্তৃপক্ষকে সব জানাচ্ছেন',
          asset: 'assets/game/art/m7_board79/talk_report.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'argue',
          labelBn: 'আঙুল তুলে রাগী গ্রাহকের সাথে তর্ক করছেন',
          asset: 'assets/game/art/m7_board79/talk_argue.svg',
          scene: true,
          correct: false,
          rejectBn: 'উত্তেজিত গ্রাহকের সাথে তর্কে জড়াবেন না — শান্তভাবে তাঁর কথা শুনুন।',
        ),
        LearnBoardOption(
          id: 'promise',
          labelBn: 'হাত মিলিয়ে বলছেন, কালই ট্রান্সফরমার বদলাব',
          asset: 'assets/game/art/m7_board79/talk_promise.svg',
          scene: true,
          correct: false,
          rejectBn: 'ট্রান্সফরমার বদলানো আপনার হাতে নেই — মিথ্যা প্রতিশ্রুতি নয়, সঠিক তথ্য দিন।',
        ),
        LearnBoardOption(
          id: 'wave',
          labelBn: 'গ্রাহকের দিকে পিঠ করে বলছেন, আমার কাজ নয়',
          asset: 'assets/game/art/m7_board79/talk_wave.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহককে বোঝান যে আপনি তাঁর সমস্যা সমাধানের জন্যই এসেছেন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রাগী গ্রাহকের সাথে তর্ক নয়, শান্ত থাকুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'যা আপনার হাতে নেই, তার প্রতিশ্রুতি দেবেন না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আপনি সমস্যা মেটাতেই এসেছেন, এটা গ্রাহককে বোঝান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্রাহক রেগে গেলে পাল্টা চেঁচিয়ে বোঝাতে হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রাহককে খুশি করতে বড় প্রতিশ্রুতিই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রাগী গ্রাহকের কথা শোনার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্রান্সফরমারের কথা ঊর্ধ্বতনকে জানানো অর্থহীন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রাহক না থামলে মুখ ঘুরিয়ে চলে যাওয়াই ঠিক', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মিথ্যে আশ্বাস দিলেই ঝামেলা মিটে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'finish',
      promptBn: 'মিটার বদলানো শেষ — বেরোনোর আগে কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'sweep',
          labelBn: 'ঝাঁট দিয়ে ছাঁট তার সরিয়ে পরিষ্কার করছেন',
          asset: 'assets/game/art/m7_board79/finish_sweep.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sheet',
          labelBn: 'জব শিট পূরণ করে গ্রাহকের সই নিচ্ছেন',
          asset: 'assets/game/art/m7_board79/finish_sheet.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mess',
          labelBn: 'ছাঁট তার ছড়িয়ে রেখেই বেরিয়ে যাচ্ছেন',
          asset: 'assets/game/art/m7_board79/finish_mess.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শেষে আপনার কাজের জায়গাটি পরিষ্কার করে দিন।',
        ),
        LearnBoardOption(
          id: 'pot',
          labelBn: 'মই রেখে টব ভেঙে রেখেই চলে যাচ্ছেন',
          asset: 'assets/game/art/m7_board79/finish_pot.svg',
          scene: true,
          correct: false,
          rejectBn: 'আপনার কাজের কারণে যেন গ্রাহকের সম্পত্তির কোনো ক্ষতি না হয়।',
        ),
        LearnBoardOption(
          id: 'nosheet',
          labelBn: 'পুরোনো মিটার নিয়ে কাগজ ছাড়াই বেরোচ্ছেন',
          asset: 'assets/game/art/m7_board79/finish_nosheet.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটার বদলের পর গ্রাহকের সই সহ জব শিট পূরণ করুন — এটাই কাজের প্রমাণ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাজ শেষে কাজের জায়গাটা পরিষ্কার করে যান', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সই করা জব শিট আপনার কাজের প্রমাণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আপনার কাজে গ্রাহকের কোনো ক্ষতি যেন না হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছাঁট তার পড়ে থাকলে গ্রাহক নিজেই সরাবেন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জব শিট শুধু বড় কাজে লাগে, মিটারে নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টব ভাঙলে সেটা গ্রাহকের নিজের দোষ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাজ হয়ে গেলে সই ছাড়াই চলে আসা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পরিষ্কার করা লাইনম্যানের কাজ নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মুখের কথায় কাজ শেষ বলাই যথেষ্ট প্রমাণ', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board79Lines.rivalTaunt,
    rivalLineBn: M7Board79Lines.rivalMyth,
    exitBn: M7Board79Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board79Lines.sting,
    flipStingBn: M7Board79Lines.flipSting,
    dangerHints: [
      'গোপনীয়তা ভঙ্গ',
      'আইন ভাঙা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'অধিকার কাজের সাথে জড়ানো জায়গাতেই সীমাবদ্ধ', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ব্যক্তিগত গোপনীয়তাকে সম্মান করাও কাজের অংশ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কাজের সাথে সম্পর্কিত জায়গার বাইরে যাওয়ার অধিকার নেই', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কোম্পানির লোক হলে সব ঘরে যাওয়ার অধিকার আছে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'কাজ করতে এসেছি, তাই যা খুশি করা যায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অনুমতি লাগে শুধু বাইরের গেটে ঢোকার সময়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'বিদ্যুতের কাজে গোপনীয়তা বলে কিছু নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'আলমারি, শোবার ঘর — সবই মিটারের কাজের অংশ', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অনুমতি ছাড়া ঘুরে দেখলে কাজ ভালো হয়', correct: false),
    ],
  ),
);

/// The board's spoken lines: the careless coworker's (his recorded voice) and
/// the guide's. [rivalExit] and [sting] are already recorded; the rest wait
/// for the voice session (ruling M7-10), silent with the caption held until
/// then (the rival never falls back to the device voice).
abstract final class M7Board79Lines {
  /// DRAFT wording — owner.
  static const intro = 'গ্রাহকের বাড়িতে আপনি কোম্পানির প্রতিনিধি। অধিকার আর দায়িত্ব দুটোই চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'আগে পরিচয়, ঢোকার আগে নোটিশ আর অনুমতি, কাজ শুধু কাজের জায়গায় — আর ফেরার আগে পরিষ্কার করে সই নিন।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'আমি তো কোম্পানির লোক! বাড়ির যেখানে খুশি যেতে পারি।';

  /// Lesson 7.9's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'গ্রাহকের বাড়িতে কাজ করতে এসেছি, তার মানে আমি যেকোনো জায়গায় যেতে পারি এবং যেকোনো কিছু করতে পারি।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

  /// Already recorded (reused by the other boards' flip question).
  static const flipSting = 'এই লোক যা বলছে… সেটা কি ভুল?';

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

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the myth's right reasons, the earned
  /// line).
  static List<String> get guideSpoken {
    final p = learnBoardPack79;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      p.myth.stingBn,
      p.myth.flipStingBn,
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
