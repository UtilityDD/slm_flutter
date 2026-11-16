import 'learn_board_models.dart';

/// Module 8 Lesson 8.2 (সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার নিয়মাবলী),
/// the picture board (rung `8.2/learn`, pack `learn_8_2`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board82_art.py` (no words; no
/// logos, ruling M8-11; the only marks are a meter's LCD, a calendar's date
/// cells, a green stamp and a shop's sign plate). Every round and trap comes
/// from the live lesson text (`tool/all_training_chapters_bn.json`, lesson 8.2)
/// and the Module 8 rulings (`docs/module_specs/module8_rulings.md`, item spec
/// `docs/module_specs/module8_items/board_82.json`):
///  * wayleave (section 1): the landowner's written consent before a pole or
///    wire crosses private land (Consent); a route along a road edge. Traps:
///    a pit dug while the owner protests, the nod with no paper, a shoving
///    match with a neighbour (live: 'গায়ের জোর দেখাবেন না'), a line drawn
///    through three private plots;
///  * meter (section 1, pro tip 3, myth 1): the meter outside, read from the
///    doorstep; the spot marked from a company order while the consumer
///    watches. Traps: a bedroom meter, a roof meter room in a multi-storey
///    building, the consumer's pointing finger, a meter moved without an order
///    or fee (live 'মিটার শিফটিং-এর জন্য নির্দিষ্ট ফি');
///  * notice (section 2, Sec 56, myth 2): a dated written notice with well over
///    two weeks' clear days; the reading and seal state noted first. Traps: no
///    paper, a shouted warning at the door, a notice served a few days ago,
///    the notebook shut with the meter unread. Clear-day boundary cases are
///    avoided (M8-12: no deal at 13–17 or 175–185 days);
///  * hook (section 3, Sec 135, pro tip 1): the evidence first — a phone frame
///    with the pole top and the hooking wire in it; the seizure list (জব্দ
///    তালিকা) written at the site. Traps: the wire pulled down before any
///    evidence (slip, R17), a frame with only a house wall (slip), a bare hand
///    on the hook before the tester shows 0 V (deadly, N4 / X1 / M8-18: the
///    order is switch off, tester 0 V, earth, গ্লাভস, hook off), a notice form
///    handed over and the hook left on. Five cards in the hand, so the deadly
///    trap is dealt on every play (kit: no freeze on boards, see the test);
///  * sec126 (section 3, Sec 126, advanced facts): the গৃহস্থ meter card at a
///    shop; the provisional bill with an objection written on it. Traps: a
///    police van for an FIR (live: 'FIR হয় না'), a final bill on the spot
///    (live: provisional first, final after the hearing), a shoving match (pro
///    tip 2: no quarrel). Walking away from a blocked gate is no longer a trap
///    (spec: the lesson never calls it wrong).
///
/// Five rounds (ruling M8-21): round 4 of the spec (reconnection and
/// dismantling) left the board; do_8_2_a plays it in full.
///
/// Every new line here is a DRAFT for the owner's wording (ruling M8-14 /
/// M6-12); the rival's myth is the lesson's second myth word for word. No
/// YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack82 = LearnBoardPack(
  lessonId: '8.2',
  titleBn: 'সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার নিয়মাবলী',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: M8Board82Lines.intro,
  earnedBn: M8Board82Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'wayleave',
      promptBn: 'নতুন কানেকশনের তার পাশের জমির ওপর দিয়ে যাবে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'consent',
          labelBn: 'জমির মালিকের লিখিত সম্মতি আছে, গেটে',
          asset: 'assets/game/art/m8_board82/wayleave_consent.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'route',
          labelBn: 'সড়কের ধার ধরে, ব্যক্তিগত মাঠ বাদে',
          asset: 'assets/game/art/m8_board82/wayleave_route.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pit',
          labelBn: 'মালিকের প্রতিবাদে মাঠে পোল-গর্ত খোঁড়া',
          asset: 'assets/game/art/m8_board82/wayleave_pit.svg',
          scene: true,
          correct: false,
          rejectBn: 'জোর করে পোল বসালে আইনি মামলায় কাজ বন্ধ হয়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'nod',
          labelBn: 'কাগজ ছাড়াই মাথা নেড়ে তার টানা শুরু',
          asset: 'assets/game/art/m8_board82/wayleave_nod.svg',
          scene: true,
          correct: false,
          rejectBn: 'অন্যের জমির ওপর দিয়ে তার বা পোল নিতে হলে জমির মালিকের লিখিত সম্মতি বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: 'প্রতিবেশীর সাথে ধাক্কাধাক্কি আর চিৎকার',
          asset: 'assets/game/art/m8_board82/wayleave_shout.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিবেশীর বাধা থাকলে আগে অফিসে জানান, গায়ের জোর দেখাবেন না।',
        ),
        LearnBoardOption(
          id: 'diag',
          labelBn: 'তিনটে ব্যক্তিগত প্লটের ওপর দিয়ে সোজা লাইন',
          asset: 'assets/game/art/m8_board82/wayleave_diag.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন টানার সময় যতটা সম্ভব ব্যক্তিগত জমি এড়িয়ে চলতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লিখিত সম্মতি ছাড়া অন্যের জমিতে পোল বসে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ব্যক্তিগত জমি যতটা সম্ভব এড়িয়ে লাইন টানুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বাধা এলে অফিসে জানান, গায়ের জোর নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মালিক চুপ থাকলেই সম্মতি ধরে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আগে কাজ শুরু করে পরে কাগজ আনা চলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাধা পেলে জোর করে কাজ শেষ করতে হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মাঠ আর রাস্তার ধার, দুটোই প্রায় একই কথা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ব্যক্তিগত মাঠ দিয়ে লাইন টানাই সোজা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'meter',
      promptBn: 'মিটার কোথায় বসবে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'outside',
          labelBn: 'বাইরের দেয়ালে, দরজার পাশে মিটার বক্স',
          asset: 'assets/game/art/m8_board82/meter_outside.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'অর্ডার স্লিপ দেখে দেয়ালে দাগ, গ্রাহক সামনে',
          asset: 'assets/game/art/m8_board82/meter_slip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bed',
          labelBn: 'বেডরুমের ভেতরে, খাটের পাশে মিটার বক্স',
          asset: 'assets/game/art/m8_board82/meter_bed.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহকের বেডরুমের ভেতরে মিটার বসানো সাপ্লাই কোড বিরোধী।',
        ),
        LearnBoardOption(
          id: 'roof',
          labelBn: 'বহুতলের ছাদের ওপর মিটার ঘর বসানো হয়',
          asset: 'assets/game/art/m8_board82/meter_roof.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাল্টি-স্টোরিড বিল্ডিংয়ে মিটার ঘর সবসময় একতলায় বা গ্রাউন্ড ফ্লোরে হতে হবে।',
        ),
        LearnBoardOption(
          id: 'point',
          labelBn: 'গ্রাহক আঙুল দেখালেন, সেখানেই ড্রিল',
          asset: 'assets/game/art/m8_board82/meter_point.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটার কোথায় বসবে তা কোম্পানি ঠিক করে, গ্রাহক নয়।',
        ),
        LearnBoardOption(
          id: 'unscrew',
          labelBn: 'গ্রাহক বললেন, তাই মিটার খুলে সরানো',
          asset: 'assets/game/art/m8_board82/meter_unscrew.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটার শিফটিং-এর জন্য নির্দিষ্ট ফি জমা দিতে হয় এবং নতুন জায়গার টেকনিক্যাল ফিজিবিলিটি চেক করতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মিটার বাইরে বা একতলায়, ঘরের ভেতরে নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মিটার কোথায় বসবে তা কোম্পানি ঠিক করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অর্ডার ছাড়া মিটার সরানো কখনও যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্রাহক যেখানে বলেন সেখানেই মিটার বসে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বেডরুমে মিটার থাকলে রিডিং নেওয়া সহজ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বহুতলে ছাদই মিটারের সবচেয়ে ভালো জায়গা', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মিটার সরাতে কোনো ফি বা অর্ডার লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রাহক না বললেও মিটার যেকোনো জায়গায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'notice',
      promptBn: 'বিল বাকি — লাইন কাটার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'notice',
          labelBn: 'তারিখসহ লিখিত নোটিশ, ক্যালেন্ডারে দিন পার',
          asset: 'assets/game/art/m8_board82/notice_calendar.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'read',
          labelBn: 'লাইন ছোঁয়ার আগে রিডিং আর সীল লিখছেন',
          asset: 'assets/game/art/m8_board82/notice_read.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'কোনো নোটিশ-কাগজ ছাড়াই লাইন কেটে দেওয়া',
          asset: 'assets/game/art/m8_board82/notice_none.svg',
          scene: true,
          correct: false,
          rejectBn: '15 দিনের ক্লিয়ার নোটিশ পিরিয়ড ছাড়া সাধারণ বকেয়ার জন্য লাইন কাটা যায় না।',
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: 'দরজায় চিৎকার করে সতর্ক করে লাইন কাটা',
          asset: 'assets/game/art/m8_board82/notice_shout.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইলেকট্রিসিটি অ্যাক্ট 2003-এর সেকশন 56 অনুযায়ী, 15 দিনের লিখিত নোটিশ বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'recent',
          labelBn: 'কয়েক দিন আগের নোটিশ, তবু লাইন কাটা',
          asset: 'assets/game/art/m8_board82/notice_recent.svg',
          scene: true,
          correct: false,
          rejectBn: '15 দিনের ক্লিয়ার নোটিশ পিরিয়ড শেষ হওয়ার আগে সাধারণ বকেয়ার জন্য লাইন কাটা যায় না।',
        ),
        LearnBoardOption(
          id: 'shut',
          labelBn: 'নোটবুক পকেটে, মিটার না পড়েই লাইন কাটা',
          asset: 'assets/game/art/m8_board82/notice_shut.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন কাটার আগে মিটারের বর্তমান রিডিং এবং সীল-এর অবস্থা নোট করে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: '15 দিনের ক্লিয়ার নোটিশ পিরিয়ড শেষ হতে হবে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সেকশন 56 অনুযায়ী লিখিত নোটিশ বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাটার আগে রিডিং আর সীল-এর অবস্থা নোট করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মৌখিক নোটিশেও সরাসরি লাইন কাটা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দরজায় জোরে চিৎকারই যথেষ্ট সতর্কতা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কয়েক দিন আগের নোটিশেই লাইন কাটা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মিটার না পড়েও লাইন কাটা যেতে পারে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বকেয়া থাকলে নোটিশের কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'চুরির ক্ষেত্রেও 15 দিন অপেক্ষা করতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hook',
      promptBn: 'পোলে হুকিং ধরা পড়েছে — কোন কাজগুলো ঠিক?',
      // Five cards in the hand: the deadly trap is dealt on every play.
      cards: 5,
      options: [
        LearnBoardOption(
          id: 'film',
          labelBn: 'পোলের মাথা আর হুকিং তার, ফোনের ফ্রেমে দুটোই',
          asset: 'assets/game/art/m8_board82/hook_film.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'seize',
          labelBn: 'ক্লিপবোর্ডে জব্দ তালিকা, জায়গাতেই লেখা',
          asset: 'assets/game/art/m8_board82/hook_seize.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pull',
          labelBn: 'ফোন পকেটে, আগে হুকিং তারটা টেনে নামানো',
          asset: 'assets/game/art/m8_board82/hook_pull.svg',
          scene: true,
          correct: false,
          rejectBn: 'আপনার প্রথম কাজ প্রমাণ জোগাড় করা (ভিডিও/ছবি) এবং তারপর লাইন বিচ্ছিন্ন করা।',
        ),
        LearnBoardOption(
          id: 'wall',
          labelBn: 'ফ্রেমে শুধু বাড়ির দেয়াল আর ঝুলন্ত তার',
          asset: 'assets/game/art/m8_board82/hook_wall.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভিডিও করে নিন যেখানে পোল থেকে হুকিং তারটা দেখা যাচ্ছে।',
        ),
        LearnBoardOption(
          id: 'hand',
          labelBn: 'টেস্টারে 0 V না দেখে খালি হাতে হুকে হাত',
          asset: 'assets/game/art/m8_board82/hook_hand.svg',
          scene: true,
          correct: false,
          // Deadly class (N4 / X1): the order is switch off, tester 0 V, earth, গ্লাভস, hook off.
          rejectBn: 'টেস্টারে 0 V না দেখে হুকে হাত দেবেন না — আগে ডেড প্রমাণ, তারপর আর্থ, তারপর হুক।',
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'নোটিশ ফর্ম দিয়ে হুক রেখেই চলে যাওয়া',
          asset: 'assets/game/art/m8_board82/hook_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'চুরির ক্ষেত্রে (Sec 135) কোনো নোটিশ লাগে না — প্রমাণ নিয়ে লাইন বিচ্ছিন্ন করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে ভিডিও বা ছবি, তারপর লাইন বিচ্ছিন্ন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ছবিতে পোল আর হুকিং তার দুটোই থাকতে হবে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জব্দ তালিকা জায়গাতেই তৈরি করতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হুকিং তার আগে নামালে প্রমাণ আরও পাকা হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফোন পকেটে থাকলেও প্রমাণ জোগাড় হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাড়ির দেয়ালের ছবিই যথেষ্ট প্রমাণ হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নোটিশ ফর্ম দিয়ে হুক রেখেই চলে যাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টেস্টার ছাড়াই খালি হাতে হুকে হাত চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঝগড়া করে হুক খুললেই কাজ শেষ হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sec126',
      promptBn: 'দোকানে গৃহস্থের কানেকশন (Sec 126) — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'card',
          labelBn: 'গৃহস্থ মিটার কার্ড দেখিয়ে সাইন দেখানো',
          asset: 'assets/game/art/m8_board82/sec126_card.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'prov',
          labelBn: 'প্রভিশনাল বিল দেওয়া, গ্রাহক আপত্তি লিখছেন',
          asset: 'assets/game/art/m8_board82/sec126_prov.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fir',
          labelBn: 'দোকানিকে পুলিশের ভ্যানের দিকে নিয়ে যাওয়া',
          asset: 'assets/game/art/m8_board82/sec126_fir.svg',
          scene: true,
          correct: false,
          rejectBn: 'Sec 126-এ এফআইআর (FIR) হয় না, কিন্তু কড়া জরিমানা (Assessment) হয়।',
        ),
        LearnBoardOption(
          id: 'final',
          labelBn: 'শুনানি ছাড়াই হাতে ফাইনাল বিল ধরিয়ে দেওয়া',
          asset: 'assets/game/art/m8_board82/sec126_final.svg',
          scene: true,
          correct: false,
          rejectBn: 'Sec 126-এ প্রথমে প্রভিশনাল বিল; গ্রাহক আপত্তি জানালে শুনানির পর ফাইনাল অর্ডার।',
        ),
        LearnBoardOption(
          id: 'shove',
          labelBn: 'দোকানির সাথে গলা চড়িয়ে ধাক্কাধাক্কি',
          asset: 'assets/game/art/m8_board82/sec126_shove.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেউ বাধা দিলে বিনীতভাবে এই আইনের কথা বলুন, দরকার হলে পুলিশ ডাকুন, কিন্তু ঝগড়া করবেন না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'Sec 126-এ আগে প্রভিশনাল, পরে ফাইনাল বিল', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আপত্তি জানালে শুনানির পর ফাইনাল অর্ডার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বিনীতভাবে আইন বোঝান, গায়ের জোর নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'Sec 126-এ এফআইআর হয়, তাই থানায় নিয়ে যান', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দোকানিকে সাথে সাথে ফাইনাল বিল ধরিয়ে দিন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শুনানি লাগে না, বিল হাতে দিলেই হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ঝগড়া করলে গ্রাহক আর আপত্তি করে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'দোকানের সাইন দেখেই কানেকশনের ধরন বদলায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board82Lines.rivalTaunt,
    rivalLineBn: M8Board82Lines.rivalMyth,
    exitBn: M8Board82Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'নোটিশ কাগজ নেই',
      'ক্যালেন্ডারে কিছু লেখা নেই',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সেকশন 56: 15 দিনের লিখিত নোটিশ বাধ্যতামূলক', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'চুরি (Sec 135) আলাদা, সেখানে নোটিশ লাগে না', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ক্লিয়ার নোটিশ মেয়াদ না পেরোলে কাটা যায় না', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'বকেয়া বড় হলে নোটিশ ছাড়াই লাইন কাটা যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'গ্রাহক না শুনলে সরাসরি লাইন কাটা যায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'গ্রাহককে মুখে জানালেই যথেষ্ট নোটিশ', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'মিটার বাইরে থাকলে নোটিশের দরকার হয় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'লাইন কাটার পরেও নোটিশ দিলেই চলে যায়', correct: false),
    ],
  ),
);

/// The careless coworker's lines and the guide's new lines on this board.
/// [rivalExit] is the same line already recorded for the other boards (same
/// text, same clip). [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`.
abstract final class M8Board82Lines {
  /// DRAFT wording — owner (the coworker's taunt).
  static const rivalTaunt = 'বিল বাকি? লাইন কেটে দিলেই তো ঝামেলা শেষ!';

  /// Lesson 8.2's second myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'বিল বাকি থাকলে নোটিশ ছাড়াই লাইন কাটা যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// DRAFT wording — owner.
  static const intro = 'নতুন কানেকশন, মিটার, বিল আর হুকিং — প্রতিটা কাজ সাপ্লাই কোড মেনে। ঠিক নিয়মটা বেছে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'লিখিত সম্মতি, 15 দিনের ক্লিয়ার নোটিশ আর আগে প্রমাণ — সাপ্লাই কোড মেনেই আপনার কাজ।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every trap's
  /// reason, every right reason chip (spoken the first time it is chosen), the
  /// myth's right chips and the closing line. The sting is the kit's own.
  static List<String> get newGuideLines {
    final p = learnBoardPack82;
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
