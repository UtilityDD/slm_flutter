import 'learn_board_models.dart';

/// Module 8 Lesson 8.5 (সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন), the
/// picture board (rung `8.5/learn`, pack `learn_8_5`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board85_art.py` (no words in
/// the art; the labels a worker reads are drawn as strokes with English digits).
/// Every round and trap comes from the live lesson text (tool/all_training_chapters_bn.json,
/// lesson 8.5, version 7) and the Module 8 rulings (docs/module_specs/module8_rulings.md):
///  * ptw: the written PTW before the pole (pro tip 1, live text); the permit
///    slip must match the permit book, and the book is read before signing.
///    A phone 'line OFF' with no paper, a signature without a read and a climb
///    with no permit are the traps (M8-1 / N1 family, see the class map below);
///  * loto: the breaker at OFF with the lineman's padlock and the 'কাজ চলছে'
///    board; the key stays in his own pocket (pro tip 2). Slips (M8-5);
///  * road: an 11 kV span across a road at 6.5 m (about 21 ft, ruling A2 / X3),
///    a covered conductor is still bare-conductor rules (myth 2), a sagging
///    span must be tightened (the lesson's legal duty). Slips (M8-12, M8-8);
///  * earth: the temporary earth at both ends of the work pole, the discharge
///    rod first and then the brass chain over the phases (pro tip 4, point
///    'রড + চেইন'), the tester proves 0 V before any earth (M8-17 / X1). The
///    deadly acts are the one-sided earth, the chain with no rod and the bare
///    hand on an unearthed line (M8-1 / M8-5); a rusty chain is a slip (M8-5);
///  * ppe: whole rubber gloves and whole boots (the lesson's pro tip 3 and
///    'খালি হাতে কাজের মতোই'), the own rod and chain (myth 3 and the mate's word).
///
/// The rival's myth is the lesson's first myth, word for word (ruling M8-14).
/// The board runs five rounds (ruling M8-21: the LT house-gap round left the
/// board; it lives on in the 8.5a card). Boards have no freeze (kit design);
/// each class below is documented for the reviewer.
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12, M8-14).
/// No YouTube explainer id (ruling M8-6 / M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack85 = LearnBoardPack(
  lessonId: '8.5',
  titleBn: 'সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'সেফটি কোড আপনার সুরক্ষার আইন। কোন কাগজ, কোন তালা, কোন আর্থিং আর কোন দূরত্ব ঠিক—চিনে নিন।',
  earnedBn: 'লিখিত পারমিট, দুই প্রান্তে রড আর্থ, নিজের তালা আর নিজের চাবি—সেফটি কোডের এই নিয়মই আপনার কবচ।',
  slots: [
    // Round 1: the permit before the pole.
    LearnBoardSlot(
      id: 'ptw',
      promptBn: 'পোলে ওঠার আগে আপনার হাতে কোন কাগজ থাকবে?',
      options: [
        LearnBoardOption(
          id: 'slip',
          labelBn: 'পারমিট স্লিপ, বই আর সময় মিলিয়ে দেখা',
          asset: 'assets/game/art/m8_board85/ptw_slip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'read',
          labelBn: 'বইয়ের পাতা পড়া হয়েছে, কলম ঢাকনাসহ',
          asset: 'assets/game/art/m8_board85/ptw_read.svg',
          scene: true,
          correct: true,
        ),
        // Deadly class (M8-1 / R1): a climb or a start on a verbal 'line OFF'.
        LearnBoardOption(
          id: 'phone',
          labelBn: 'ফোনে মুখের কথায় লাইন OFF, কাগজ নেই',
          asset: 'assets/game/art/m8_board85/ptw_phone.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফোনে মুখের কথায় লাইন OFF আছে বিশ্বাস করবেন না—লিখিত পারমিট চাই।',
        ),
        // Deadly class (M1 step 17 / B7): work on a signed PTW never read.
        LearnBoardOption(
          id: 'sign',
          labelBn: 'না পড়েই পারমিট বইয়ে সই, চোখ খুঁটিতে',
          asset: 'assets/game/art/m8_board85/ptw_sign.svg',
          scene: true,
          correct: false,
          rejectBn: 'সই করার আগে পড়ে নিন কোন ফিডার, কোন সময় আর কী কাজের জন্য পারমিট।',
        ),
        // Deadly class (M8-1 / R1): a climb with no permit at all.
        LearnBoardOption(
          id: 'none',
          labelBn: 'পারমিট ছাড়াই 11 kV খুঁটিতে উঠে পড়া',
          asset: 'assets/game/art/m8_board85/ptw_none.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট ছাড়া উঠে দুর্ঘটনা ঘটলে কোম্পানি কোনো দায়িত্ব নেয় না; CEI তদন্তে জেল পর্যন্ত হতে পারে।',
        ),
        // Deadly class (M1 step 17): a slip that does not match the book.
        LearnBoardOption(
          id: 'mismatch',
          labelBn: 'স্লিপের নম্বর আর সময় বইয়ের সাথে মেলে না',
          asset: 'assets/game/art/m8_board85/ptw_mismatch.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট বইয়ের নম্বর এবং সময় মিলিয়ে দেখুন—না মিললে কাজ নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মুখের কথায় লাইন OFF ধরা যায় না, পারমিট লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বইয়ের নম্বর ও সময় স্লিপের সাথে মেলাতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সই করার আগে পড়তে হয় কোন ফিডার ও কী কাজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বন্ধুর ফোন পেলেই পোলে ওঠা যায়, দেরি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সই আগে, পড়া পরে—সময় বাঁচাতে এটাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পারমিট ছাড়াও খুঁটিতে ওঠা যায়, সবাই ওঠে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বইয়ের নম্বর না মিললেও কাজ চলতে পারে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হাতে কাগজ না থাকলেও জানা থাকলে কাজ চলে', correct: false),
      ],
    ),
    // Round 2: the LOTO on the breaker.
    LearnBoardSlot(
      id: 'loto',
      promptBn: 'ব্রেকার OFF করার পর কোনটা আইন মানছে?',
      options: [
        LearnBoardOption(
          id: 'lock',
          labelBn: 'ব্রেকার OFF, তালা আর কাজ চলছে বোর্ড',
          asset: 'assets/game/art/m8_board85/loto_lock.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pocket',
          labelBn: 'তালার চাবি লাইনম্যানের নিজের শার্ট-পকেটে',
          asset: 'assets/game/art/m8_board85/loto_pocket.svg',
          scene: true,
          correct: true,
        ),
        // Slip (M8-5 / R12): no padlock and no board on the OFF handle.
        LearnBoardOption(
          id: 'nolock',
          labelBn: 'ব্রেকার OFF, তালা নেই, বোর্ডও নেই',
          asset: 'assets/game/art/m8_board85/loto_nolock.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল করে কেউ যেন ব্রেকার ON না করে দেয়—হ্যান্ডেলে তালা আর কাজ চলছে বোর্ড চাই।',
        ),
        // Slip (M8-5 / R11): the key left in the lock.
        LearnBoardOption(
          id: 'keyin',
          labelBn: 'তালা লাগানো, কিন্তু চাবি তালায় ঝুলছে',
          asset: 'assets/game/art/m8_board85/loto_keyin.svg',
          scene: true,
          correct: false,
          rejectBn: 'চাবিটা নিজের পকেটে রাখুন—আপনার জীবন আপনার পকেটে।',
        ),
        // Slip (M8-5 / R11): the key handed to another person at the panel.
        LearnBoardOption(
          id: 'handkey',
          labelBn: 'চাবি প্যানেলে অন্য একজনের হাতে দেওয়া',
          asset: 'assets/game/art/m8_board85/loto_handkey.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিজের তালা, নিজের চাবি—চাবি অন্যের হাতে মানে জীবন অন্যের হাতে।',
        ),
        // Slip (M8-5 / R12): the board alone, no padlock.
        LearnBoardOption(
          id: 'boardonly',
          labelBn: 'শুধু কাজ চলছে বোর্ড ঝোলানো, তালা নেই',
          asset: 'assets/game/art/m8_board85/loto_boardonly.svg',
          scene: true,
          correct: false,
          rejectBn: 'বোর্ড একা যথেষ্ট নয়—ব্রেকার OFF করে হ্যান্ডেলে তালাও লাগাতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তালা আর কাজ চলছে বোর্ড, দুটোই লাগবে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চাবি নিজের পকেটে, জীবনও নিজের হাতে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল করে ব্রেকার ON না হয়, তাই তালা লাগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বোর্ড ঝুললেই ব্রেকার নিরাপদ, তালা লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চাবি অন্যের হাতে দিলে কাজ দ্রুত শেষ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তালা থাকলে চাবি যেখানে খুশি রাখা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্রেকার OFF থাকলে তালার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অন্যের তালা দিয়েও কাজ চলে, তাতে ক্ষতি নেই', correct: false),
      ],
    ),
    // Round 3: the 11 kV span across the road (6.5 m, live text).
    LearnBoardSlot(
      id: 'road',
      promptBn: 'রাস্তার ওপর 11 kV লাইন—কোন ছবিটা আইন মানছে?',
      options: [
        LearnBoardOption(
          id: 'high',
          labelBn: '11 kV তার রাস্তার ওপর উঁচুতে, ট্রাক নিচে',
          asset: 'assets/game/art/m8_board85/road_high.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'patrol',
          labelBn: 'টহলে লাইনম্যান তারের দিকে, হাতে লগবুক',
          asset: 'assets/game/art/m8_board85/road_patrol.svg',
          scene: true,
          correct: true,
        ),
        // Slip (M8-12 / R10): the span below the 6.5 m road height.
        LearnBoardOption(
          id: 'low',
          labelBn: '11 kV তার ঝুলে, ট্রাকের মাথার কাছে',
          asset: 'assets/game/art/m8_board85/road_low.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাস্তা পার হওয়া 11 kV লাইন মাটি থেকে অন্তত 6.5 মিটার, মানে প্রায় 21 ফুট উঁচুতে থাকবে।',
        ),
        // Slip (M8-12 / myth 2): a covered conductor is handled as bare.
        LearnBoardOption(
          id: 'covered',
          labelBn: 'কভার্ড তার ঝুলে, লোকজন ট্রাক থেকে ধরছে',
          asset: 'assets/game/art/m8_board85/road_covered.svg',
          scene: true,
          correct: false,
          rejectBn: 'কভার্ড কন্ডাক্টরকেও বেয়ার ধরার আইন—পিন-হোল বা ফাটল থাকতে পারে।',
        ),
        // Slip (R10 / legal duty): a sagging span walked past without a note.
        LearnBoardOption(
          id: 'walk',
          labelBn: 'ঝোলা লাইন দেখেও লাইনম্যান না লিখে হাঁটছে',
          asset: 'assets/game/art/m8_board85/road_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন ঝুলে গেলে তা টাইট করা আপনার আইনি দায়িত্ব।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: '11 kV রাস্তায় মাটি থেকে 6.5 মিটার উঁচুতে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঝোলা লাইন দেখলে টাইট করা আইনি দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কভার্ড তারও বেয়ার, পিন-হোল থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কভার্ড তার থাকলে লোকজন হাত বাড়াতে পারে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ট্রাক সরে গেলে তার কতটা নিচে, ভেবে লাভ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝোলা লাইন থাকলেও টহলে লেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রাস্তার তার যত নিচু, ততই নিরাপদ থাকা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লাইন ঝুললে নিজে টাইট না করে ছেড়ে দিন', correct: false),
      ],
    ),
    // Round 4: the temporary earth at both ends of the work pole.
    LearnBoardSlot(
      id: 'earth',
      promptBn: 'লাইন OFF করার পর—অস্থায়ী আর্থিং কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'both',
          labelBn: 'কাজের খুঁটির আগে-পরে দুই প্রান্তে রড আর চেইন',
          asset: 'assets/game/art/m8_board85/earth_both.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tester',
          labelBn: 'টেস্টারে 0 V দেখে তবে রড লাইনে, চেইন কাঁধে',
          asset: 'assets/game/art/m8_board85/earth_tester.svg',
          scene: true,
          correct: true,
        ),
        // Deadly class (M8-1 / R3): an earth on one side of the work pole only.
        LearnBoardOption(
          id: 'oneside',
          labelBn: 'কাজের খুঁটির শুধু এক দিকে আর্থ করা',
          asset: 'assets/game/art/m8_board85/earth_oneside.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজের জায়গার আগে ও পরে—দুই প্রান্তে অস্থায়ী আর্থিং বাধ্যতামূলক।',
        ),
        // Deadly class (M8-1 / R4): the chain as the earth, no rod.
        LearnBoardOption(
          id: 'ball',
          labelBn: 'শুধু ব্রাস চেইন লাইনের ওপর, কোনো রড নেই',
          asset: 'assets/game/art/m8_board85/earth_ball.svg',
          scene: true,
          correct: false,
          rejectBn: 'চেইন শুধু ফেজ শর্ট করে; রড চার্জ নামায়—শর্ট সার্কিট ≠ আর্থিং।',
        ),
        // Slip (M8-5 / R13): a rusty or broken-link iron chain.
        LearnBoardOption(
          id: 'jugaad',
          labelBn: 'মরচে ধরা লোহার জুগাড় চেইন, একটা লিংক ভাঙা',
          asset: 'assets/game/art/m8_board85/earth_jugaad.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা, ভাঙা বা লোহার জুগাড় চেইন বারণ—সন্দেহ হলে পোলে ওঠার আগেই বদলান।',
        ),
        // Deadly class (M8-1 / N1): a bare hand on a line not yet earthed.
        LearnBoardOption(
          id: 'bare',
          labelBn: 'আর্থ না করা ডেড লাইনে খালি হাত দিয়ে ধরা',
          asset: 'assets/game/art/m8_board85/earth_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডেড লাইনকেও Live মনে করতে হবে, যতক্ষণ না সেটা আর্থ করা হচ্ছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে ডেড প্রমাণ, তারপর রড, সবশেষে চেইন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের খুঁটির আগে ও পরে, দুই প্রান্তে আর্থ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রড চার্জ নামায়, চেইন শুধু ফেজ শর্ট করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চেইন ছুঁড়লেই আর্থিং হয়ে যায়, রড লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একদিকে আর্থ করলেই কাজের জায়গা নিরাপদ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মরচে ধরা চেইন হলেও ক্ষতি নেই, ছুঁড়ে দিন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ডেড লাইন হলে খালি হাতে ধরতে আপত্তি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টেস্টার না দেখেই রড লাইনে তুলে দেওয়া যায়', correct: false),
      ],
    ),
    // Round 5: the whole gloves and boots, and the own rod and chain.
    LearnBoardSlot(
      id: 'ppe',
      promptBn: 'অভিজ্ঞতা নয়, আইন—কোন হাত কাজের জন্য তৈরি?',
      options: [
        LearnBoardOption(
          id: 'full',
          labelBn: 'পুরো রাবার গ্লাভস আর পুরো জুতো, ভ্যানের পাশে',
          asset: 'assets/game/art/m8_board85/ppe_full.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rod',
          labelBn: 'নিজের ডিসচার্জ রড আর চেইন হাতে, ওঠার আগে',
          asset: 'assets/game/art/m8_board85/ppe_rod.svg',
          scene: true,
          correct: true,
        ),
        // Slip (M8-6 / A5 family): torn gloves are as bad as bare hands.
        LearnBoardOption(
          id: 'torn',
          labelBn: 'ছেঁড়া গ্লাভসের আঙুল দিয়ে যন্ত্র ধরা',
          asset: 'assets/game/art/m8_board85/ppe_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছেঁড়া গ্লাভস পরে কাজ আর খালি হাতে কাজ একই ব্যাপার—দুটোই বেআইনি এবং বিপজ্জনক।',
        ),
        // Slip (pro tip 3): a torn boot.
        LearnBoardOption(
          id: 'sole',
          labelBn: 'জুতোর তলা ছেঁড়া, পায়ের আঙুল বেরিয়ে',
          asset: 'assets/game/art/m8_board85/ppe_sole.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছেঁড়া জুতো পরে কাজ করাও খালি হাতে কাজের মতোই বেআইনি আর বিপজ্জনক।',
        ),
        // Deadly class (M8-1 / N1): a hand on a live part with no proof.
        LearnBoardOption(
          id: 'veteran',
          labelBn: 'পাকা চুলের লাইনম্যান তারে পিঠের হাত ঠেকাচ্ছে',
          asset: 'assets/game/art/m8_board85/ppe_veteran.svg',
          scene: true,
          correct: false,
          rejectBn: 'বিদ্যুৎ কাউকে চেনে না—অতি-আত্মবিশ্বাসী অভিজ্ঞরাই বেশি দুর্ঘটনার শিকার।',
        ),
        // Deadly class (M8-1 / R3, B1): a mate's word that the earth is on.
        LearnBoardOption(
          id: 'mate',
          labelBn: 'সহকর্মীর কথায় বিশ্বাস, আর্থ হয়েছে ধরে ওঠা',
          asset: 'assets/game/art/m8_board85/ppe_mate.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে ওঠার আগে নিজের হাতে রড ও চেইন নিন; অন্যকে বিশ্বাস করবেন না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ছেঁড়া গ্লাভস আর খালি হাত একই রকম বিপজ্জনক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পুরো রাবার গ্লাভস আর পুরো জুতো আইনের দাবি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিজের রড আর চেইন নিজে হাতে নিয়ে তবে ওঠা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অভিজ্ঞ হলে গ্লাভস ছাড়াও কাজ চলে, ভয় কম', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছেঁড়া জুতো হলেও কাজ তাড়াতাড়ি শেষ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বিদ্যুৎ অভিজ্ঞদের চেনে, নতুনদের চেনে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সহকর্মী বলেছে আর্থ আছে, তাই ওঠা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হাতের পিঠ দিয়ে ছুঁলে বিদ্যুৎ লাগে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board85Lines.rivalTaunt,
    rivalLineBn: M8Board85Lines.rivalMyth,
    exitBn: M8Board85Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'পারমিট ছাড়া বিপদ',
      'আর্থিং ছাড়া কাজ নয়',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বিদ্যুৎ কাউকে চেনে না, আত্মবিশ্বাসীরাই ঝুঁকিতে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'পারমিট-আর্থিং আইনের দাবি, অভিজ্ঞতার বদলি নয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'হাত দিয়ে বোঝা যায় না, টেস্টারে 0 V দেখে কাজ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'অনেক বছরের কাজে পারমিট লাগে না, চলে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'আর্থিং শুধু নতুনদের জন্য, পুরনো কর্মীর লাগে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'হাত দিয়ে ভোল্টেজ বুঝলে আর্থ করার দরকার নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আইন মানলে কাজ ধীর হয়, তাই বাদ দেওয়া ভালো', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'পুরনো কর্মীরা নিজের বিচারে চলেন, নিয়ম লাগে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M8Board85Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'রোজ রোজ পারমিট আর আর্থিং! এত ঝামেলা কিসের?';

  /// Lesson 8.5's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'এত বছর ধরে কাজ করছি, আমার পারমিট বা আর্থিং লাগে না, আমি হাত দিয়েই ভোল্টেজ বুঝি।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Deadly or slip class of every trap, for the reviewer (boards carry no
  /// class in the model; the kit treats every trap alike). Key: 'round/option'.
  /// Deadly rows: R1 (phone, none), M1 step 17 (sign, mismatch), R3 (oneside,
  /// mate), R4 (ball), N1 (bare, veteran). Everything else is a slip.
  static const trapClass = <String, String>{
    'ptw/phone': 'deadly',
    'ptw/sign': 'deadly',
    'ptw/none': 'deadly',
    'ptw/mismatch': 'deadly',
    'loto/nolock': 'slip',
    'loto/keyin': 'slip',
    'loto/handkey': 'slip',
    'loto/boardonly': 'slip',
    'road/low': 'slip',
    'road/covered': 'slip',
    'road/walk': 'slip',
    'earth/oneside': 'deadly',
    'earth/ball': 'deadly',
    'earth/jugaad': 'slip',
    'earth/bare': 'deadly',
    'ppe/torn': 'slip',
    'ppe/sole': 'slip',
    'ppe/veteran': 'deadly',
    'ppe/mate': 'deadly',
  };

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack85;
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
