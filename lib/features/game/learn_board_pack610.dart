import 'learn_board_models.dart';

/// Module 6 Lesson 6.10 (এনার্জি মিটার: ক্যাশ রেজিস্টার), the picture board
/// (rung `6.10/learn`, pack `learn_6_10`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board610_art.py` (the only
/// marks drawn are what a worker reads: a meter's LCD and a tester's reading,
/// as stroke glyphs with English digits; LCD numbers are game data). Every
/// round and trap comes from the live lesson text and the Module 6 rulings
/// (`docs/module_specs/module6_rulings.md`, item spec
/// `docs/module_specs/module6_items/board_610.json`). Five rounds (owner
/// answers after Wave A: boards are 5 rounds): the spec's LED round and its
/// fast-meter round are one round here, since the CAL LED is read inside the
/// fast-meter check (section 3, complaint 1):
///  * modern (section 1): the electronic meter — LCD and microprocessor, no
///    moving part; the push-button that steps the LCD through its readings
///    (section 2); the smart meter that sends its reading to the office.
///    Traps: a disc meter ticked as modern, only the kWh read on a fault
///    call, a disc meter put back as 'more accurate';
///  * fast (section 3, complaint 1; pro tip 1; myth 2): every load off, then
///    the CAL LED; the LED still, a known 100 W bulb run for an hour; the
///    customer shown how his old fridge and pump use power. Traps: every
///    load off yet the LED races, ticked 'all fine' (earth leakage or theft);
///    a verdict with the fan and bulb still on; the weather blamed (myth 2's
///    reality word for word);
///  * blank (section 3, complaints 2 and 3): a blank LCD — the incoming
///    terminals tested first; no voltage there — the service cable and the
///    pole; the meter alive, the house dark — the neutral. Traps: a new meter
///    fitted with nothing measured, voltage present yet off to the pole, the
///    neutral case written up as 'meter bad';
///  * theft (section 4 and its safety tip): a broken seal, a bypass wire seen
///    from a distance, a magnet on the meter — each reported. Traps: walking
///    off from the broken seal, the bypass pulled bare-handed while phoning
///    it in (a deadly-class act, R30; the phone is on a trap too), the magnet
///    pocketed;
///  * swap (pro tips 2 and 3, ruling X5): the incoming cut-out out with
///    gloves and the tester proving dead before hands go in; the photos of
///    the old meter's final reading and the new meter's first. Traps: a
///    screwdriver on the terminals with the cut-out in (its reason is pro tip
///    2 word for word, «মৃত» → «ডেড» by the owner's term rule), the old meter
///    bagged with no photo, the cut-out out but no tester (N4/N9).
/// Boards are not scored for deadly (kit design): a deadly-class trap costs
/// the round and teaches with the lesson's words.
/// The rival's myth is the lesson's first myth, word for word; the second
/// myth (weather) is a trap in the fast round.
///
/// Reason chips: the runner deals a round's "কেন?" chips whatever safe card
/// was picked, so every right chip is a rule that holds for each safe card of
/// its round. Rules that only explain a trap stay in that trap's reject line.
///
/// DRAFT wording — owner (ruling M6-12): every Bangla line written for this
/// board (prompts, labels, reason chips, the intro, the earned line, the
/// rival's taunt, the danger tags) is a draft for the owner's natural
/// wording; lesson quotes are marked in the test. No YouTube explainer id
/// (ruling M6-14).
const learnBoardPack610 = LearnBoardPack(
  lessonId: '6.10',
  titleBn: 'এনার্জি মিটার: ক্যাশ রেজিস্টার',
  badgeBn: 'যন্ত্র গুরু',
  introBn: M6Board610Lines.intro,
  earnedBn: M6Board610Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'modern',
      promptBn: 'গ্রাহকের বাড়ির মিটার — আধুনিক মিটারের কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'lcd',
          labelBn: 'ইলেকট্রনিক মিটার: LCD আর চিপ, ঘোরা চাকতি নেই',
          asset: 'assets/game/art/m6_board610/modern_lcd.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'button',
          labelBn: 'পুশ-বাটন টিপে LCD-তে একে একে বাকি রিডিং দেখা',
          asset: 'assets/game/art/m6_board610/modern_button.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'smart',
          labelBn: 'স্মার্ট মিটার নিজে থেকেই অফিসে রিডিং পাঠাচ্ছে',
          asset: 'assets/game/art/m6_board610/modern_smart.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'disc',
          labelBn: 'ঘোরা চাকতির মিটারকে আধুনিক বলে খাতায় টিক',
          asset: 'assets/game/art/m6_board610/modern_disc.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঘোরা অ্যালুমিনিয়ামের চাকতি পুরনো ইলেক্ট্রো-মেকানিক্যাল মিটারের চিহ্ন। আধুনিক ইলেকট্রনিক মিটারের ভেতরে কোনো চলমান অংশ নেই।',
        ),
        LearnBoardOption(
          id: 'kwh',
          labelBn: 'ফল্টের খোঁজে এসে শুধু kWh দেখে খাতায় টিক',
          asset: 'assets/game/art/m6_board610/modern_kwh.svg',
          scene: true,
          correct: false,
          rejectBn: 'আধুনিক মিটার শুধু kWh নয় — ভোল্টেজ, কারেন্ট, পাওয়ার ফ্যাক্টর আর সর্বোচ্চ চাহিদাও রেকর্ড করে, যা ফল্ট নির্ণয়ে সাহায্য করে।',
        ),
        LearnBoardOption(
          id: 'putback',
          labelBn: '"বেশি নির্ভুল" ভেবে চাকতির মিটার আবার লাগানো',
          asset: 'assets/game/art/m6_board610/modern_putback.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইলেকট্রনিক মিটার মাইক্রোপ্রসেসর দিয়ে হিসাব করে — অনেক বেশি নির্ভুল আর ট্যাম্পার-প্রুফ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আধুনিক মিটারে চলমান অংশ নেই, হিসাব চিপে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ইলেকট্রনিক মিটার নির্ভুল আর ট্যাম্পার-প্রুফ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আধুনিক মিটার kWh ছাড়াও অনেক তথ্য রাখে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চাকতি যত জোরে ঘোরে, মিটার তত নির্ভুল', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফল্ট খুঁজতে মিটারের শুধু kWh দেখলেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পুরনো চাকতির মিটারই সবচেয়ে নির্ভুল', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'LCD মিটার শুধু দেখতে সুন্দর, কাজ একই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মিটারের পুশ-বাটন শুধু অফিসের লোকের জন্য', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'স্মার্ট মিটারেও রোজ হাতে রিডিং পাঠাতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fast',
      promptBn: 'গ্রাহক বলছেন "মিটার দ্রুত চলছে" — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'off',
          labelBn: 'বাড়ির সব লোড বন্ধ করে তারপর CAL LED দেখা',
          asset: 'assets/game/art/m6_board610/fast_off.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bulb',
          labelBn: 'LED থেমে আছে, এবার 100 ওয়াট বাল্ব এক ঘণ্টা',
          asset: 'assets/game/art/m6_board610/fast_bulb.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'explain',
          labelBn: 'গ্রাহককে পুরনো ফ্রিজ আর পাম্পের খরচ বোঝানো',
          asset: 'assets/game/art/m6_board610/fast_explain.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leak',
          labelBn: 'সব লোড বন্ধ, তবু LED দ্রুত — খাতায় "সব ঠিক"',
          asset: 'assets/game/art/m6_board610/fast_leak.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোড বন্ধ থাকা সত্ত্বেও যদি CAL LED খুব দ্রুত ব্লিঙ্ক করে, তবে বাড়িতে আর্থ লিকেজ বা বিদ্যুৎ চুরির সম্ভাবনা থাকে।',
        ),
        LearnBoardOption(
          id: 'fan',
          labelBn: 'পাখা আর বাল্ব চালু রেখেই মিটারের রায় লেখা',
          asset: 'assets/game/art/m6_board610/fast_fan.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথমে, গ্রাহকের বাড়ির সমস্ত লোড বন্ধ করুন। এবার দেখুন CAL LED ব্লিঙ্ক করছে কিনা।',
        ),
        LearnBoardOption(
          id: 'weather',
          labelBn: '"ঠান্ডায় মিটার এমনই চলে" বলে কাজ শেষ',
          asset: 'assets/game/art/m6_board610/fast_weather.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল। এনার্জি মিটারের কার্যকারিতা আবহাওয়ার ওপর নির্ভর করে না। এটি শুধুমাত্র ব্যবহৃত শক্তির পরিমাণ পরিমাপ করে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ধাপে ধাপে পরীক্ষা করলেই মূল কারণ বেরোয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মিটার শুধু ব্যবহার করা বিদ্যুৎই মাপে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গ্রাহককে সঠিক তথ্য দেওয়াই আসল কাজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঠান্ডা আবহাওয়ায় মিটার আস্তে বা জোরে চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লোড চালু রেখেও মিটারের বিচার করা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'LED ব্লিঙ্ক করা মানেই মিটার খারাপ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অভিযোগ এলেই মিটার বদলে দেওয়া সহজ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লোড বন্ধে LED চললেও চিন্তার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দুই মিনিট দেখলেই মিটারের বিচার হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'blank',
      promptBn: 'ডিসপ্লে ফাঁকা, বা বাড়িতে আলো নেই — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'tester',
          labelBn: 'ফাঁকা ডিসপ্লে: আগে ইনকামিং টার্মিনালে ভোল্টেজ মাপা',
          asset: 'assets/game/art/m6_board610/blank_tester.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cable',
          labelBn: 'ইনকামিংয়ে ভোল্টেজ নেই: সার্ভিস কেবিল ধরে পোলের দিকে',
          asset: 'assets/game/art/m6_board610/blank_cable.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'মিটার চালু, বাড়ি অন্ধকার: নিউট্রাল কাটা কি না দেখা',
          asset: 'assets/game/art/m6_board610/blank_neutral.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'newmeter',
          labelBn: 'কিছু না মেপেই ফাঁকা মিটার খুলে নতুন মিটার লাগানো',
          asset: 'assets/game/art/m6_board610/blank_newmeter.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথমে মিটারের ইনকামিং টার্মিনালে ভোল্টেজ পরীক্ষা করুন। ভোল্টেজ না থাকলে সমস্যাটি সার্ভিস কেবিল বা পোলের কানেকশনে।',
        ),
        LearnBoardOption(
          id: 'pole',
          labelBn: 'ইনকামিংয়ে ভোল্টেজ আছে, তবু মই নিয়ে পোলের দিকে',
          asset: 'assets/game/art/m6_board610/blank_pole.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভোল্টেজ ঠিক থাকলে মিটারের ভেতরের ফিউজ বা সার্কিট খারাপ হতে পারে।',
        ),
        LearnBoardOption(
          id: 'bad',
          labelBn: 'মিটার চালু, বাড়ি অন্ধকার — খাতায় "মিটার খারাপ"',
          asset: 'assets/game/art/m6_board610/blank_bad.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাড়িতে পাওয়ার নেই অথচ মিটার চালু — এটি সাধারণত নিউট্রাল কেটে যাওয়ার লক্ষণ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে মেপে দেখুন, তারপর বলুন দোষ কোথায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মিটারের লক্ষণ পড়ে আসল কারণের দিকে এগোনো', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আন্দাজে মিটার বদলালে আসল দোষ থেকে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ডিসপ্লে ফাঁকা মানেই মিটার নষ্ট, বদলে দিন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাড়ি অন্ধকার হলে দোষ সবসময় মিটারের', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভোল্টেজ মাপা সময় নষ্ট, সোজা পোলে চলুন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নিউট্রাল কাটলে মিটারও সাথে সাথে নেভে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নতুন মিটার লাগালেই সব সমস্যা মিটে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ইনকামিংয়ে ভোল্টেজ থাকলেও দোষ পোলেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'theft',
      promptBn: 'মিটার বক্সে চুরির লক্ষণ — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'seal',
          labelBn: 'টার্মিনাল কভারের সিল ভাঙা — ফোনে রিপোর্ট',
          asset: 'assets/game/art/m6_board610/theft_seal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bypass',
          labelBn: 'মিটার এড়িয়ে বাইপাস তার — দূর থেকে রিপোর্ট',
          asset: 'assets/game/art/m6_board610/theft_bypass.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'magnet',
          labelBn: 'মিটারের গায়ে চুম্বক লাগানো — ফোনে রিপোর্ট',
          asset: 'assets/game/art/m6_board610/theft_magnet.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'সিল ভাঙা দেখেও কিছু না বলে চলে যাওয়া',
          asset: 'assets/game/art/m6_board610/theft_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটারের বডি বা টার্মিনাল কভারের সিল ভাঙা বা না থাকাটা ট্যাম্পারিং-এর প্রথম এবং প্রধান লক্ষণ — অবিলম্বে কর্তৃপক্ষকে রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'pull',
          // DRAFT wording — owner: he reports it, and yet pulls the wire bare-handed
          // (the phone and the word রিপোর্ট sit on a trap too, so neither marks the
          // safe cards).
          labelBn: 'ফোনে রিপোর্ট দিতে দিতে খালি হাতে বাইপাস টানা',
          asset: 'assets/game/art/m6_board610/theft_pull.svg',
          scene: true,
          correct: false,
          // First sentence: the lesson's safety tip, word for word.
          // DRAFT wording — owner (second sentence).
          rejectBn: 'বিদ্যুৎ চোরেরা প্রায়ই বিপজ্জনক এবং অপেশাদার পদ্ধতিতে ওয়্যারিং করে, যা আপনার জন্যও ঝুঁকি তৈরি করতে পারে। খালি হাতে ছোঁবেন না — দূর থেকে দেখে রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'pocket',
          labelBn: 'চুম্বকটা খুলে নিজের পকেটে রেখে চুপ থাকা',
          asset: 'assets/game/art/m6_board610/theft_pocket.svg',
          scene: true,
          correct: false,
          rejectBn: 'বিদ্যুৎ চুরি একটি দণ্ডনীয় অপরাধ — যেকোনো সন্দেহজনক কার্যকলাপ দেখলে অবিলম্বে আপনার কর্তৃপক্ষকে রিপোর্ট করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সন্দেহজনক কিছু দেখলেই কর্তৃপক্ষকে রিপোর্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বিদ্যুৎ চুরি দণ্ডনীয় অপরাধ, চেপে যাওয়া নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চোরের ওয়্যারিং বিপজ্জনক, তাই বাড়তি সতর্কতা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সিল ভাঙা ছোট ব্যাপার, কাউকে বলার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাইপাস তার নিজেই টেনে খুললে ঝামেলা শেষ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চুম্বক সরিয়ে দিলেই হলো, রিপোর্ট লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চুরি দেখা লাইনম্যানের কাজ নয়, এড়িয়ে যান', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রাহক চেনা হলে চুরি দেখেও চুপ থাকা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'চোরের তার সাধারণ তারের মতোই নিরাপদ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'swap',
      promptBn: 'পুরনো মিটার খুলে নতুন বসাবেন — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'cutout',
          labelBn: 'গ্লাভস পরে কাটআউট খোলা, টেস্টারে ডেড প্রমাণ',
          asset: 'assets/game/art/m6_board610/swap_cutout.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'oldphoto',
          labelBn: 'পুরনো মিটারের ফাইনাল রিডিংয়ের ছবি তোলা',
          asset: 'assets/game/art/m6_board610/swap_oldphoto.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'newphoto',
          labelBn: 'নতুন মিটারের প্রাথমিক রিডিংয়ের ছবি তোলা',
          asset: 'assets/game/art/m6_board610/swap_newphoto.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'কাটআউট না খুলেই টার্মিনালে স্ক্রু-ড্রাইভার',
          asset: 'assets/game/art/m6_board610/swap_live.svg',
          scene: true,
          correct: false,
          // Live lesson 6.10 pro tip 2, word for word (ruling X5), with the
          // owner's term rule «ডেড» for «মৃত».
          rejectBn: 'মিটার বক্সে কাজ করার আগে পোলের ফিউজ বা মিটারের আগের (ইনকামিং) কাটআউট খুলে লাইনটিকে সম্পূর্ণ বিচ্ছিন্ন করুন, তারপর টেস্টারে ডেড প্রমাণ করুন।',
        ),
        LearnBoardOption(
          id: 'bag',
          labelBn: 'কোনো রিডিং না তুলেই পুরনো মিটার ব্যাগে',
          asset: 'assets/game/art/m6_board610/swap_bag.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো মিটারের ফাইনাল রিডিং এবং নতুন মিটারের প্রাথমিক রিডিং-এর ছবি তুলে রাখুন। এটি বিলিং সংক্রান্ত সমস্যা এড়াতে সাহায্য করে।',
        ),
        LearnBoardOption(
          id: 'notest',
          labelBn: 'কাটআউট খুলেছেন, টেস্টার ছাড়াই টার্মিনালে হাত',
          asset: 'assets/game/art/m6_board610/swap_notest.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাটআউট খুলেই কাজ নয় — আগে চালু লাইনে টেস্টার যাচাই, তারপর টেস্টারে ডেড প্রমাণ, তবেই মিটারে হাত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মিটার বদলে নিরাপত্তা আর হিসাবের প্রমাণ দুটোই চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাটআউট খুলে ডেড প্রমাণ, আর দুই রিডিংয়ের ছবি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিয়ম মেনে বদলালে শক আর বিলিংয়ের ঝামেলা নেই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ইনসুলেটেড স্ক্রু-ড্রাইভারে লাইন চালু রাখা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রিডিং মনে রাখলেই যথেষ্ট, ছবির দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাটআউট খুললেই লাইন ডেড, টেস্টার লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পুরনো মিটারের রিডিং আর কারও কাজে লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্লাভস পরা থাকলে কাটআউট খোলার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন মিটারের প্রথম রিডিংয়ের ছবি তো বৃথা', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board610Lines.rivalTaunt,
    rivalLineBn: M6Board610Lines.rivalMyth,
    exitBn: M6Board610Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M6Board610Lines.sting,
    dangerHints: [
      'মিটার সব রেকর্ড করে',
      'চুরির মামলা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আধুনিক মিটার চুম্বক-প্রতিরোধী, ট্যাম্পার-প্রুফ', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ট্যাম্পারের চেষ্টা মিটার নিজেই রেকর্ড করে রাখে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'বিদ্যুৎ চুরি দণ্ডনীয় অপরাধ, দেখলেই রিপোর্ট', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'চুম্বকে সব মিটারই আস্তে চলে, বিলও কমে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'চুম্বক লাগালে কেউ কোনোদিন ধরতে পারে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ডিজিটাল মিটারও চুম্বকে একদম থেমে যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'মিটারে চুম্বক লাগানো কোনো অপরাধই নয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'চুম্বক সরালে আর কোনো প্রমাণই থাকে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'বড় চুম্বক হলে মিটার পুরো বন্ধ হয়ে যায়', correct: false),
    ],
  ),
);

/// The lines of this board for the owner's wording pass and the voice
/// session. [rivalExit] and [sting] are already recorded (reused); the rest
/// play silent (caption held for reading) or on the on-device fallback until
/// the director records them.
abstract final class M6Board610Lines {
  /// DRAFT wording — owner.
  static const intro = 'এনার্জি মিটার হলো বিদ্যুতের ক্যাশ রেজিস্টার। মিটারের ভাষা পড়ুন, অভিযোগের কারণ খুঁজুন, চুরির লক্ষণ চিনুন।';

  /// DRAFT wording — owner.
  static const earned = 'মিটারের ভাষা পড়ে ধাপে ধাপে খুঁজুন; চুরি দেখলে রিপোর্ট; মিটারে হাত শুধু কাটআউট খুলে ডেড প্রমাণের পর।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, মিটার নিয়ে এত মাথা ঘামানোর কী আছে?';

  /// Lesson 6.10's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'মিটারের ওপর চুম্বক রাখলে মিটার স্লো হয়ে যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12: the rival's new lines (the taunt is a draft; the myth is
  /// the lesson's own, still to be recorded).
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
    final p = learnBoardPack610;
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
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
