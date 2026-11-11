import 'learn_board_models.dart';

/// Module 2 Lesson 2.8 (ফেজ সিকোয়েন্স মিটার: সঠিক ঘূর্ণন), the picture board
/// (rung `2.8/learn`, pack `learn_2_8`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m2_board28_art.py`. Every round
/// and every trap comes from the lesson text:
///  * when: after any new three-phase connection or a big repair the phase
///    sequence test is mandatory; colours (R red, Y yellow, B blue) are not
///    always followed in the field; a reversed sequence turns a motor
///    backwards (a lift / conveyor), and one second backwards can ruin a pump,
///    compressor or gearbox;
///  * meter: the rotating-disc type turns clockwise on the right sequence and
///    the other way on the wrong one; the digital type shows FWD/Clockwise or
///    REV/Anti-Clockwise; the old two-lamp + capacitor test is less reliable,
///    slow and dangerous (open wires on a live circuit); India's standard is
///    R-Y-B;
///  * probe: a live-line test — full PPE, insulated gloves above all; the
///    probes must not touch each other or an earthing point; damaged probes or
///    leads are not used; a non-contact (clamp) meter gives extra safety;
///  * fix: a reversed reading (R-B-Y) is put right by swapping any two phases
///    (e.g. Y and B). The swap cards draw the isolator OFF (house rule; the
///    lesson does not say it — not put into words here);
///  * grid: test after a new transformer or work on its HT/LT side; a
///    generator is synchronised to the grid only when both sequences match —
///    a wrong one is a deadly explosion.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack28 = LearnBoardPack(
  lessonId: '2.8',
  titleBn: 'ফেজ সিকোয়েন্স মিটার: সঠিক ঘূর্ণন',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'থ্রি-ফেজ বিদ্যুৎ একটা নির্দিষ্ট ক্রমে ঘোরে — R-Y-B। রং দেখে নয়, মিটারে সেই দিক যাচাই করুন।',
  earnedBn: 'রং নয়, মিটার — নতুন কানেকশনে আগে পরীক্ষা, উল্টো হলে যেকোনো দুটি ফেজ বদল।',
  slots: [
    LearnBoardSlot(
      id: 'when',
      promptBn: 'নতুন থ্রি-ফেজ কানেকশন বা বড় মেরামতির পর — মোটর চালানোর আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'new',
          labelBn: 'নতুন কানেকশনে মিটারে পরীক্ষা',
          asset: 'assets/game/art/m2_board28/when_new.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'repair',
          labelBn: 'বড় মেরামতির পর মিটারে পরীক্ষা',
          asset: 'assets/game/art/m2_board28/when_repair.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'colour',
          labelBn: 'তারের রং দেখে ফেজ ধরে নেওয়া',
          asset: 'assets/game/art/m2_board28/when_colour.svg',
          scene: true,
          correct: false,
          rejectBn: 'R লাল, Y হলুদ, B নীল — ফিল্ডে সবসময় এই রং মানা হয় না। রং দেখে অনুমান নয়, মিটারে পরীক্ষা।',
        ),
        LearnBoardOption(
          id: 'run',
          labelBn: 'পরীক্ষা ছাড়াই কনভেয়র চালু করা',
          asset: 'assets/game/art/m2_board28/when_run.svg',
          scene: true,
          correct: false,
          rejectBn: 'সিকোয়েন্স উল্টে গেলে (R-B-Y) মোটরও উল্টো ঘোরে — লিফট বা কনভেয়র উল্টো চললে বড় বিপদ।',
        ),
        LearnBoardOption(
          id: 'pump',
          labelBn: 'পাম্প চালিয়ে ঘূর্ণন দেখে নেওয়া',
          asset: 'assets/game/art/m2_board28/when_pump.svg',
          scene: true,
          correct: false,
          rejectBn: 'পাম্প বা কম্প্রেসার এক সেকেন্ড উল্টো ঘুরলেও চিরতরে নষ্ট হতে পারে — পরীক্ষা সবসময়ই সস্তা।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নতুন কানেকশন বা বড় মেরামতির পর পরীক্ষা বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সিকোয়েন্স উল্টে গেলে থ্রি-ফেজ মোটরও উল্টো ঘোরে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তারের রং নয়, মিটারের রিডিংয়ের ওপর ভরসা রাখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাল-হলুদ-নীল রং মিললেই সিকোয়েন্স ঠিক ধরে নিন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মোটর চালিয়ে ঘূর্ণন দেখাই সবচেয়ে সহজ পরীক্ষা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বড় মেরামতির পরও আগের সিকোয়েন্সই থেকে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'এক সেকেন্ড উল্টো ঘুরলে পাম্পের কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লিফট বা কনভেয়র উল্টো চললেও তেমন বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পুরোনো লাইনের অভ্যাসে নতুন লাইনও ঠিক থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'meter',
      promptBn: 'তিনটে প্রোব R, Y, B-তে লাগানো — কোন রিডিং মানে সিকোয়েন্স ঠিক?',
      options: [
        LearnBoardOption(
          id: 'disc_cw',
          labelBn: 'ডিস্ক ঘড়ির কাঁটার দিকে ঘুরছে',
          asset: 'assets/game/art/m2_board28/meter_disc_cw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'led_fwd',
          labelBn: 'FWD সবুজ বাতি জ্বলছে',
          asset: 'assets/game/art/m2_board28/meter_led_fwd.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'disc_ccw',
          labelBn: 'ডিস্ক ঘড়ির উল্টো দিকে ঘুরছে',
          asset: 'assets/game/art/m2_board28/meter_disc_ccw.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডিস্ক উল্টো দিকে ঘুরলে সিকোয়েন্স ভুল (R-B-Y) — ঠিক হলে ঘোরে ঘড়ির কাঁটার দিকে।',
        ),
        LearnBoardOption(
          id: 'led_rev',
          labelBn: 'REV লাল বাতি জ্বলছে',
          asset: 'assets/game/art/m2_board28/meter_led_rev.svg',
          scene: true,
          correct: false,
          rejectBn: 'REV বা Anti-Clockwise মানে উল্টো সিকোয়েন্স — ঠিক হলে দেখায় FWD বা Clockwise।',
        ),
        LearnBoardOption(
          id: 'lamp',
          labelBn: 'দুটো ল্যাম্প আর ক্যাপাসিটরে মাপা',
          asset: 'assets/game/art/m2_board28/meter_lamp.svg',
          scene: true,
          correct: false,
          rejectBn: 'ল্যাম্প টেস্ট কম নির্ভরযোগ্য, সময়সাপেক্ষ — লাইভ সার্কিটে খোলা তার নিয়ে কাজ, অনেক বেশি বিপজ্জনক।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঠিক সিকোয়েন্সে ডিস্ক ঘড়ির কাঁটার দিকে ঘোরে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডিজিটাল মিটারে ঠিক মানে FWD বা Clockwise', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভারতে স্ট্যান্ডার্ড সিকোয়েন্স হলো R-Y-B', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ডিস্ক যেদিকেই ঘুরুক, ঘুরলেই সিকোয়েন্স ঠিক', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লাল REV বাতি জ্বললে বুঝবেন কাজ ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ল্যাম্প টেস্ট মিটারের চেয়ে নিরাপদ ও দ্রুত', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভারতে স্ট্যান্ডার্ড সিকোয়েন্স হলো R-B-Y', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'খোলা তারে ল্যাম্প জুড়ে মাপাই সেরা উপায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'উল্টো দিকে ঘোরা ডিস্ক মানে মিটার ঠিক আছে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'probe',
      promptBn: 'লাইভ সার্কিটে ফেজ সিকোয়েন্স মিটার লাগাবেন — কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'gloves',
          labelBn: 'PPE ও ইনসুলেটেড গ্লাভসে প্রোব লাগানো',
          asset: 'assets/game/art/m2_board28/probe_gloves.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clamp',
          labelBn: 'তারের ওপর ক্ল্যাম্প করা মিটার',
          asset: 'assets/game/art/m2_board28/probe_clamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে প্রোব লাগানো',
          asset: 'assets/game/art/m2_board28/probe_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'এটা লাইভ লাইন টেস্ট — পুরো PPE, বিশেষ করে ইনসুলেটেড গ্লাভস ছাড়া প্রোবে হাত নয়।',
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'দুটো ক্লিপ একে অপরকে ছুঁয়ে আছে',
          asset: 'assets/game/art/m2_board28/probe_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রোব একে অপরকে ছুঁলে দুই ফেজে শর্ট সার্কিট — ক্লিপগুলো সাবধানে আলাদা রাখুন।',
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'একটা ক্লিপ আর্থিং বারে লাগানো',
          asset: 'assets/game/art/m2_board28/probe_earth.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রোব যেন কোনো আর্থিং পয়েন্ট না ছোঁয় — ফেজ থেকে আর্থে শর্ট সার্কিট হয়।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'ছেঁড়া তারের প্রোবেই মাপা',
          asset: 'assets/game/art/m2_board28/probe_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে প্রোব আর তার দেখুন — কোনো ক্ষতি থাকলে সেই মিটার ব্যবহার করবেন না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইভ টেস্টে ইনসুলেটেড গ্লাভস সহ পুরো PPE চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্রোব যেন একে অপরকে বা আর্থকে না ছোঁয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ক্ল্যাম্প মিটারে তার না ছুঁয়েই মাপা যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কয়েক সেকেন্ডের টেস্টে গ্লাভস লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'প্রোব একে অপরকে ছুঁলেও রিডিং ঠিক আসে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্থিং বারে ক্লিপ রাখলে মিটার বেশি নিরাপদ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তার একটু ছেঁড়া হলেও মাপতে কোনো অসুবিধা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ক্ল্যাম্প মিটার শুধু দেখনদারি, কাজের নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্যবহারের আগে প্রোব দেখার দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fix',
      promptBn: 'মিটার উল্টো সিকোয়েন্স (R-B-Y) দেখাচ্ছে — এবার কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'yb',
          labelBn: 'Y আর B ফেজের তার বদল',
          asset: 'assets/game/art/m2_board28/fix_yb.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ry',
          labelBn: 'R আর Y ফেজের তার বদল',
          asset: 'assets/game/art/m2_board28/fix_ry.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'run',
          labelBn: 'রিডিং উপেক্ষা করে মোটর চালু',
          asset: 'assets/game/art/m2_board28/fix_run.svg',
          scene: true,
          correct: false,
          rejectBn: 'উল্টো সিকোয়েন্সে মোটর উল্টো ঘুরবে — কনভেয়র উল্টো চলে মাল ফেলে দেবে। আগে দুটি ফেজ বদল।',
        ),
        LearnBoardOption(
          id: 'colour',
          labelBn: 'রং ঠিক আছে বলে মিটার অগ্রাহ্য',
          asset: 'assets/game/art/m2_board28/fix_colour.svg',
          scene: true,
          correct: false,
          rejectBn: 'রঙের ওপর ভরসা নয় — ফিল্ডে রঙের নিয়ম সবসময় মানা হয় না। মিটার যা বলে, সেটাই সত্যি।',
        ),
        LearnBoardOption(
          id: 'pump',
          labelBn: 'একবার পাম্প চালিয়ে দেখা',
          asset: 'assets/game/art/m2_board28/fix_pump.svg',
          scene: true,
          correct: false,
          rejectBn: 'পাম্প, কম্প্রেসার বা গিয়ারবক্স এক সেকেন্ড উল্টো ঘুরলেও চিরতরে নষ্ট হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'যেকোনো দুটি ফেজ বদলালেই সিকোয়েন্স ঠিক হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'উল্টো রিডিংয়ে আগে সিকোয়েন্স ঠিক, পরে চালু', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মিটারের রিডিং তারের রঙের চেয়ে বিশ্বাসযোগ্য', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'উল্টো রিডিং মানে মিটারটাই খারাপ ধরে নিন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'R-B-Y দেখালেও মোটর চালিয়ে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রং মিলে গেলে মিটারের রিডিং না মানলেও চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'এক সেকেন্ড উল্টো ঘুরলে যন্ত্রের ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'উল্টো ঘুরলে পরে দেখা যাবে, আগে চালু করুন', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'R-B-Y হলো ভারতের স্ট্যান্ডার্ড সিকোয়েন্স', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'grid',
      promptBn: 'নতুন ট্রান্সফরমার বা জেনারেটর গ্রিডে জুড়বেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'tx',
          labelBn: 'নতুন ট্রান্সফরমারে সিকোয়েন্স পরীক্ষা',
          asset: 'assets/game/art/m2_board28/grid_tx.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'gen',
          labelBn: 'জেনারেটর ও গ্রিডের সিকোয়েন্স মেলানো',
          asset: 'assets/game/art/m2_board28/grid_gen.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sync',
          labelBn: 'উল্টো সিকোয়েন্সেই সিনক্রোনাইজ',
          asset: 'assets/game/art/m2_board28/grid_sync.svg',
          scene: true,
          correct: false,
          rejectBn: 'জেনারেটর আর গ্রিডের সিকোয়েন্স এক হওয়া বাধ্যতামূলক — ভুল সিকোয়েন্সে মারাত্মক বিস্ফোরণ।',
        ),
        LearnBoardOption(
          id: 'skip',
          labelBn: 'পরীক্ষা ছাড়াই LT সুইচ চালু',
          asset: 'assets/game/art/m2_board28/grid_skip.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন ট্রান্সফরমার বসানো বা তার HT/LT সাইডে কাজের পর ফেজ সিকোয়েন্স পরীক্ষা অপরিহার্য।',
        ),
        LearnBoardOption(
          id: 'colour',
          labelBn: 'বুশিংয়ের রং দেখে মিলিয়ে নেওয়া',
          asset: 'assets/game/art/m2_board28/grid_colour.svg',
          scene: true,
          correct: false,
          rejectBn: 'রং দেখে অনুমান নয় — ফিল্ডে R-Y-B রঙের নিয়ম সবসময় মানা হয় না, মিটারে পরীক্ষা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ট্রান্সফরমারের HT/LT সাইডে কাজের পর পরীক্ষা জরুরি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সিনক্রোনাইজের আগে দুই দিকের সিকোয়েন্স এক চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল সিকোয়েন্সে সিনক্রোনাইজ মানে মারাত্মক বিস্ফোরণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নতুন ট্রান্সফরমারে সিকোয়েন্স পরীক্ষা বাড়তি ঝামেলা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জেনারেটরের সিকোয়েন্স আলাদা হলেও গ্রিডে জোড়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বুশিংয়ের রং মিললেই সিকোয়েন্স নিশ্চিত মিলে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'HT/LT সাইডে কাজের পরেও আগের সিকোয়েন্স থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভুল সিকোয়েন্সে জুড়লে বড়জোর মোটর একটু গরম হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'জেনারেটর গ্রিডে জোড়ার আগে মিটার লাগে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M2Board28Lines.rivalTaunt,
    rivalLineBn: M2Board28Lines.rivalMyth,
    exitBn: M2Board28Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'পরীক্ষা ছাড়াই মোটর চালু',
      'এক সেকেন্ডের উল্টো ঘূর্ণন',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'পাম্প বা গিয়ারবক্স এক সেকেন্ড উল্টো ঘুরলেই নষ্ট হতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ছোট হোক বা বড়, থ্রি-ফেজ মোটরে আগে সিকোয়েন্স পরীক্ষা', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'যন্ত্র নষ্ট হওয়ার চেয়ে পরীক্ষা সবসময়ই অনেক সস্তা', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ছোট মোটর উল্টো ঘুরলে জোড়া যন্ত্রের কোনো ক্ষতি হয় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'উল্টো ঘুরলে পরে কানেকশন বদলালেই সব আগের মতো ঠিক', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ফেজ সিকোয়েন্স মিটার শুধু বড় মোটরের জন্যই দরকার', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'মোটর চালিয়ে দেখাই সিকোয়েন্স বোঝার সেরা উপায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'পাম্প যুক্ত থাকলেও এক সেকেন্ডের উল্টো ঘোরায় কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ লাইনম্যানের ছোট মোটরে কোনো পরীক্ষা লাগে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M2Board28Lines {
  static const rivalTaunt = 'আরে, ছোট মোটর তো! এর জন্য আবার মিটার লাগিয়ে সময় নষ্ট কেন?';

  /// Lesson 2.8's first myth buster, word for word.
  static const rivalMyth = 'একটা ছোট মোটরের জন্য ফেজ সিকোয়েন্স পরীক্ষা করার দরকার নেই, উল্টো ঘুরলে কানেকশন বদলে দিলেই হবে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
