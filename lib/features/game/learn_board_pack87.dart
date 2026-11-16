import 'learn_board_models.dart';

/// Module 8 Lesson 8.7 (ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব),
/// the picture board (rung `8.7/learn`, pack `learn_8_7`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board87_art.py` (no words in
/// the art; a meter card carries only an icon for its category, a bill only
/// highlighted rows). Every round and trap comes from the live lesson text
/// (`tool/all_training_chapters_bn.json`, lesson 8.7, version 5) and the
/// Module 8 rulings (`docs/module_specs/module8_rulings.md`; item spec
/// `docs/module_specs/module8_items/board_87.json`):
///  * closed: the fixed (demand) charge is due even when the house is shut —
///    it keeps the load allotted (lesson 8.7 section 1);
///  * slab: the energy charge is telescopic — the first 102 units are cheap,
///    the units above cost more (pro tip 1);
///  * cat: domestic and commercial are different categories on one meter; a
///    wrong category is a Section 126 case (section 2);
///  * farm: the agricultural (irrigation) rate is the lowest, subsidised; a
///    farm pump that washes cars or feeds a shop is a serious offence;
///  * extra: MVCA (fuel surcharge) is a government rule, not a reader's trick;
///    the meter rent covers replacing and maintaining a faulty meter (myth 2,
///    moved to this round so it does not overlap the myth beat);
///  * the rival's myth is the lesson's first myth, word for word; the
///    reality says a correct reading is not a crime.
/// The factory round (night machines, capacitor bank) left the board: five
/// rounds (ruling M8-21); do_8_7_b's factory stop plays it.
///
/// Rulings applied: slip-only level (M8-1, R7), no rupee amounts, no
/// category card for the factory, English digits and kVA in English letters
/// (term rule), no logos (M8-11), silent drawn figures (M8-10, the guide and
/// the coworker speak). Every new line here is a DRAFT for the owner's wording
/// (ruling M8-14 / M6-12). No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack87 = LearnBoardPack(
  lessonId: '8.7',
  titleBn: 'ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'বিলের কাগজ হাতে গ্রাহক। ফিক্সড চার্জ, স্ল্যাব আর ক্যাটাগরি ঠিকভাবে বুঝিয়ে দিন।',
  earnedBn: 'ফিক্সড চার্জ, স্ল্যাব আর ক্যাটাগরি মিলিয়ে বিল বোঝান — ট্যারিফ অর্ডার দেখে, অনুমানে নয়।',
  slots: [
    LearnBoardSlot(
      id: 'closed',
      promptBn: 'বাড়ি সারা মাস তালাবন্ধ, তবু বিল এসেছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'fixed',
          labelBn: 'তালাবন্ধ বাড়ি, বিলে ফিক্সড চার্জের লাইন',
          asset: 'assets/game/art/m8_board87/closed_fixed.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'load',
          labelBn: 'সংযোগ চালু, মিটার বাক্সে লোড · kVA ট্যাগ',
          asset: 'assets/game/art/m8_board87/closed_load.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'strike',
          labelBn: 'বিলের ফিক্সড চার্জের লাইন কলমে কাটা',
          asset: 'assets/game/art/m8_board87/closed_strike.svg',
          scene: true,
          correct: false,
          rejectBn: 'বিদ্যুৎ ব্যবহার করুক বা না করুক, বাড়ি বন্ধ থাকলেও লোড বরাদ্দ রাখার জন্য ফিক্সড চার্জ দিতে হয়।',
        ),
        LearnBoardOption(
          id: 'meter',
          labelBn: 'মিটারে টোকা দিয়ে ধরে নেওয়া মিটার খারাপ',
          asset: 'assets/game/art/m8_board87/closed_meter.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিক্সড চার্জ মিটারের দোষ নয় — এটা কোম্পানির পরিকাঠামো মেইনটেন্যান্সের খরচ, লোডের ভাড়ার মতো।',
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'বিল হাতে গ্রাহককে ফেলে পিঠ ফিরিয়ে চলে যাওয়া',
          asset: 'assets/game/art/m8_board87/closed_walk.svg',
          scene: true,
          correct: false,
          rejectBn: "গ্রাহক 'বাড়ি বন্ধ ছিল তাও বিল এসেছে' বললে ফিক্সড চার্জের কথা বুঝিয়ে বলুন।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বন্ধ বাড়িতেও লোড বরাদ্দের ভাড়া লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফিক্সড চার্জ কোম্পানির পরিকাঠামোর খরচ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বিদ্যুৎ না চললেও লোড রাখতে ফিক্সড চার্জ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাড়ি বন্ধ থাকলে বিল আসা মানেই ভুল', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফিক্সড চার্জ মিটার খারাপের জরিমানা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিক্সড চার্জ শুধু চালু বাড়িতেই লাগে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তালাবন্ধ বাড়িতে বিল দেওয়ার দায় নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মিটার খারাপ হলেই ফিক্সড চার্জ লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'slab',
      promptBn: 'আগে 100 ইউনিট, এখন 200 — বিল তিনগুণ কেন? কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'stairs',
          labelBn: 'দুই ধাপের সিঁড়ি, উপরের ধাপে বেশি কয়েন',
          asset: 'assets/game/art/m8_board87/slab_stairs.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bill',
          labelBn: 'এনার্জি চার্জের লাইন, 102 ইউনিটে ভাগ করা',
          asset: 'assets/game/art/m8_board87/slab_bill.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'flat',
          labelBn: 'সমান একটা দাগ, প্রতি ইউনিটে একই কয়েন',
          asset: 'assets/game/art/m8_board87/slab_flat.svg',
          scene: true,
          correct: false,
          rejectBn: 'এনার্জি চার্জ স্ল্যাব অনুযায়ী বাড়ে — প্রথম 102 ইউনিট সস্তা, পরেরগুলো দামী।',
        ),
        LearnBoardOption(
          id: 'upside',
          labelBn: 'সিঁড়িটা উল্টো, উপরের ধাপে কম কয়েন',
          asset: 'assets/game/art/m8_board87/slab_upside.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম ব্যবহার করলে কম রেট, বেশি করলে ধাপে ধাপে বাড়ে — উপরের দিকের ইউনিটগুলোর দাম বেশি।',
        ),
        LearnBoardOption(
          id: 'reader',
          labelBn: 'রিডারের খাতায় যা খুশি লেখা হয়েছে',
          asset: 'assets/game/art/m8_board87/slab_reader.svg',
          scene: true,
          correct: false,
          rejectBn: "বিলের প্রতিটি পয়সার হিসাব WBERC-এর 'ট্যারিফ অর্ডার'-এ লেখা থাকে — রিডার যা খুশি বসায় না।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'উপরের ইউনিটের দাম বেশি, ধাপে বাড়ে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্রথম 102 ইউনিট সস্তা, পরেরগুলো দামী', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এনার্জি চার্জ স্ল্যাব অনুযায়ী বাড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সব ইউনিটের দাম সমান, রেটও একই থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কম ব্যবহারে বেশি রেট, এটাই নিয়ম', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রিডার খাতায় যা লেখে সেটাই দাম হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্ল্যাব শুধু দোকানের বিলে থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'প্রথম 100 ইউনিটের পর দাম কমে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'cat',
      promptBn: 'বাড়িতে ফ্যান, দোকানে ফ্রিজ — কোন সংযোগটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'home',
          labelBn: 'বাড়িতে ফ্যান চলছে, কার্ডে বাড়ির চিহ্ন',
          asset: 'assets/game/art/m8_board87/cat_home.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shop',
          labelBn: 'দোকানে ফ্রিজ চলছে, কার্ডে দোকানের চিহ্ন',
          asset: 'assets/game/art/m8_board87/cat_shop.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shop_dom',
          labelBn: 'দোকানের ফ্রিজ, মিটার কার্ডে বাড়ির চিহ্ন',
          asset: 'assets/game/art/m8_board87/cat_shop_dom.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাড়ির রেট দোকানের রেটের চেয়ে কম — ভুল ক্যাটাগরিতে বিদ্যুৎ ব্যবহার করলে সেকশন 126 অনুযায়ী জরিমানা হয়।',
        ),
        LearnBoardOption(
          id: 'wire',
          labelBn: 'বাড়ির মিটার থেকে পাশের দোকানে তার',
          asset: 'assets/game/art/m8_board87/cat_wire.svg',
          scene: true,
          correct: false,
          rejectBn: 'একই মিটার থেকে বাড়িতে ফ্যান চালানো আর দোকানে ফ্রিজ চালানো আইনত আলাদা।',
        ),
        LearnBoardOption(
          id: 'nolook',
          labelBn: 'রিডার পিছন ফিরে মিটার কার্ড না দেখে লিখছে',
          asset: 'assets/game/art/m8_board87/cat_nolook.svg',
          scene: true,
          correct: false,
          rejectBn: "মিটার দেখার সময় 'Type of Consumer' কোড ঠিক আছে কি না লক্ষ্য করুন।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বাড়ির রেট কম, দোকানের রেট আলাদা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'একই মিটারে বাড়ি আর দোকান আইনত আলাদা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মিটার কার্ডে ক্যাটাগরি মিলিয়ে বিল হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দোকানের ফ্রিজ বাড়ির রেটে চললে দোষ নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একই মিটারে সব ব্যবহার আইনত একই হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রিডার পিছন ফিরে লিখলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কার্ড বদলানো দরকার নেই, রেট বাড়িতে আর দোকানে সমান', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মিটার কার্ড না দেখলেও বিল ঠিক হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'farm',
      promptBn: 'চাষের সংযোগের জল পাম্প — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'paddy',
          labelBn: 'ধানখেতে পাম্প জল দিচ্ছে, কার্ডে কৃষি',
          asset: 'assets/game/art/m8_board87/farm_paddy.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'veg',
          labelBn: 'সবজিখেতের পাশে পাম্পঘর, খালে জল, কৃষি',
          asset: 'assets/game/art/m8_board87/farm_veg.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'carwash',
          labelBn: 'একই পাম্পের পাইপে গাড়ি ধোয়ার গ্যারেজ',
          asset: 'assets/game/art/m8_board87/farm_carwash.svg',
          scene: true,
          correct: false,
          rejectBn: 'চাষের জল পাম্প দিয়ে কেউ গাড়ি ধোয়ার গ্যারেজ চালালে তা বড় অপরাধ।',
        ),
        LearnBoardOption(
          id: 'shop',
          labelBn: 'পাম্পের লাইন থেকে দোকানের ফ্রিজে সংযোগ',
          asset: 'assets/game/art/m8_board87/farm_shop.svg',
          scene: true,
          correct: false,
          rejectBn: 'কৃষির রেট সবচেয়ে কম, ভর্তুকি যুক্ত — অন্য কাজে ব্যবহার ভুল ক্যাটাগরি, সেকশন 126 অনুযায়ী জরিমানা।',
        ),
        LearnBoardOption(
          id: 'blind',
          labelBn: 'রিডার লিখছে, পিছনে গাড়ি ধোয়া চলছে',
          asset: 'assets/game/art/m8_board87/farm_blind.svg',
          scene: true,
          correct: false,
          rejectBn: "মিটার দেখার সময় 'Type of Consumer' কোড ঠিক আছে কি না লক্ষ্য করুন।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কৃষির রেট সবচেয়ে কম, শুধু চাষে ব্যবহার', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চাষের কাজেই চলে, ভর্তুকি যুক্ত রেট', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কৃষি কার্ড মানে শুধু জমির সেচের জল', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পাম্প দিয়ে গাড়ি ধুলে কোনো দোষ নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কৃষির জলে দোকানের ফ্রিজ চললে ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কৃষির রেট দোকানের চেয়ে বেশি হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জল পাম্পে ক্যাটাগরি দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভর্তুকি থাকায় অন্য কাজে চালানো যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'extra',
      promptBn: 'বিলে বাড়তি লাইন দেখে গ্রাহক রেগে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'mvca',
          labelBn: 'কয়লার স্তূপ, পাশে ওপরমুখী তীর দেওয়া MVCA',
          asset: 'assets/game/art/m8_board87/extra_mvca.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rent',
          labelBn: 'খারাপ মিটার বদলানো হচ্ছে, মিটার ভাড়ার লাইন',
          asset: 'assets/game/art/m8_board87/extra_rent.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fraud',
          labelBn: 'MVCA লাইন কেটে দিয়ে রিডারের কারচুপি',
          asset: 'assets/game/art/m8_board87/extra_fraud.svg',
          scene: true,
          correct: false,
          rejectBn: 'MVCA বা ফুয়েল সারচার্জ মিটার রিডারের কারচুপি নয় — এটা সরকারি নিয়ম।',
        ),
        LearnBoardOption(
          id: 'price',
          labelBn: 'মিটারের গায়ে দাম, ভাড়ার লাইন কাটা',
          asset: 'assets/game/art/m8_board87/extra_price.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওটা শুধু মিটারের দাম নয় — মিটার খারাপ হলে পাল্টানো আর রক্ষণাবেক্ষণের খরচ ওই ভাড়ার মধ্যেই ধরা থাকে।',
        ),
        LearnBoardOption(
          id: 'rentcut',
          labelBn: 'ভাড়ার লাইন কেটে "ভাড়া উঠে গেছে" বলা',
          asset: 'assets/game/art/m8_board87/extra_rentcut.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাড়ার লাইন কাটলেও ভাড়া যায় না — রক্ষণাবেক্ষণের খরচ ওই ভাড়ার মধ্যেই ধরা থাকে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কয়লার দাম বাড়লে MVCA, সরকারি নিয়ম', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মিটার বদল আর মেরামত ভাড়ার মধ্যে ধরা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'MVCA বা ভাড়া রিডারের কারচুপি নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'MVCA লাইন রিডার নিজে বসিয়ে দেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মিটার ভাড়ার দাম মিটারেই শোধ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভাড়ার লাইন কাটলে বিল কমে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভাড়া তো কবেই উঠে গেছে, তাই লাইন নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাড়তি লাইন মানেই রিডারের বড় চুরি', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board87Lines.rivalTaunt,
    rivalLineBn: M8Board87Lines.rivalMyth,
    exitBn: M8Board87Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'মিটার বেশি ঘোরে?',
      'বিল বেশি আসে?',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ডিজিটাল মিটার সঠিক মাপে, পুরনোটা স্লো', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'মোবাইল চার্জও ডিজিটাল মিটার রেকর্ড করে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সঠিক মাপা কোনো অপরাধ হতে পারে না', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মিটার বেশি ঘোরে, তাই ইউনিট বেশি', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ডিজিটাল মিটার নিজে থেকেই ইউনিট বাড়ায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মিটার রিডার যা খুশি বিল বসিয়ে দেয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'সঠিক মাপলে নিয়ম ভেঙে জরিমানা হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'মিটার বয়সে স্লো হলে বিল বেশি আসে', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay unrecorded (the on-device fallback plays)
/// until the director records them with `tool/rival_clip.py`.
abstract final class M8Board87Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'বিলের হিসাব নিয়ে এত কথা কেন! মিটার তো ঘুরেই চলেছে।';

  /// Lesson 8.7's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'ডিজিটাল মিটার বেশি ঘোরে, তাই বিল বেশি আসে।';

  /// Already recorded (reused from Module 6).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  // DRAFT wording — owner.
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip and the closing line, plus the
  /// myth's right reasons. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack87;
    return {
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
    }.toList();
  }
}
