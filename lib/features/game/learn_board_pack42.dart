import 'learn_board_models.dart';

/// Module 4 Lesson 4.2 (জাম্পার কানেকশন ও টাইট করা), the picture board
/// (rung `4.2/learn`, pack `learn_4_2`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board42_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * bridge: at a dead-end / angle pole the jumper joins the line across the
///    tension strings; without it the current stops at the string; it carries
///    the whole line current, so it is the same size as the line conductor or
///    bigger — a thin one overloads and melts; a loose one is a
///    high-resistance point;
///  * connector: a PG (parallel groove) clamp or a compression connector
///    (hydraulic tool, right die); copper to aluminium only through a
///    bi-metallic connector (galvanic corrosion);
///  * fit: steel-brush both surfaces, anti-oxidant paste on aluminium; two
///    wrenches (one holds the bolt head, one turns the nut); nuts even and at
///    the right torque — a hurried connection breeds a hotspot;
///  * shape: a smooth U or C so that even swinging in a strong wind it
///    touches neither the cross-arm nor the next phase; a jumper support
///    insulator if needed; no sharp edge (corona: blue glow, hiss, TV/radio
///    noise);
///  * patrol: a loose jumper shows as a red hotspot at night, sparking, a
///    hiss or hum, TV/radio noise — and in the end the clamp melts and the
///    wire falls (fire). Tightening one needs PTW, PPE and the procedure.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack42 = LearnBoardPack(
  lessonId: '4.2',
  titleBn: 'জাম্পার কানেকশন ও টাইট করা',
  badgeBn: 'কাজের কারিগর',
  introBn: 'ডেড-এন্ড পোলে টেনশন স্ট্রিংয়ের দুই পাশের লাইন জোড়ে জাম্পার। এই সেতু ঠিকঠাক বাঁধতে শিখুন।',
  earnedBn: 'সঠিক সাইজ, পরিষ্কার পৃষ্ঠ, দুই রেঞ্চে টাইট, মসৃণ U — তবেই জাম্পার নিখুঁত সেতু।',
  slots: [
    LearnBoardSlot(
      id: 'bridge',
      promptBn: 'ডেড-এন্ড পোলে টেনশন স্ট্রিংয়ের দুই পাশের লাইন — কোন জাম্পার ঠিক?',
      options: [
        LearnBoardOption(
          id: 'same',
          labelBn: 'মূল তারের সমান মোটা জাম্পার',
          asset: 'assets/game/art/m4_board42/bridge_same.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thick',
          labelBn: 'মূল তারের চেয়ে মোটা জাম্পার',
          asset: 'assets/game/art/m4_board42/bridge_thick.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thin',
          labelBn: 'সরু তারের জাম্পার',
          asset: 'assets/game/art/m4_board42/bridge_thin.svg',
          scene: true,
          correct: false,
          rejectBn: 'জাম্পারের সাইজ মূল কন্ডাক্টরের সমান বা বেশি হতে হবে — সরু জাম্পার অতিরিক্ত লোডে গলে যাবে।',
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'দুই পাশ জাম্পার ছাড়াই খোলা',
          asset: 'assets/game/art/m4_board42/bridge_none.svg',
          scene: true,
          correct: false,
          rejectBn: 'জাম্পার ছাড়া কারেন্ট ইনসুলেটর স্ট্রিংয়ে এসে থেমে যায় — লাইনের ধারাবাহিকতা রাখে এই সেতুই।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'এক মাথা ঢিলা হয়ে ঝুলছে',
          asset: 'assets/game/art/m4_board42/bridge_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'জাম্পারে পুরো লাইনের কারেন্ট বয় — ঢিলা মানে উচ্চ রেজিস্ট্যান্স, গরম হয়ে বড় ফল্ট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জাম্পারের ভেতর দিয়ে পুরো লাইনের কারেন্ট যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জাম্পার মূল কন্ডাক্টরের সমান বা বেশি সাইজের', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জাম্পার না থাকলে কারেন্ট স্ট্রিংয়েই থেমে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জাম্পারে টান নেই, তাই সরু তারেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জাম্পার শুধু ঝোলে, তাই ঢিলা হলেও ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো সাইজের তারেই জাম্পার বানানো চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জাম্পার ছাড়াও কারেন্ট স্ট্রিং পেরিয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জাম্পারে লাইনের অর্ধেক কারেন্টও যায় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সরু জাম্পার যত গরমই হোক, কখনো গলে যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'connector',
      promptBn: 'জাম্পারকে মূল তারের সাথে জুড়বেন — কোন জোড়াটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pg',
          labelBn: 'PG ক্ল্যাম্পে দুই তার জোড়া',
          asset: 'assets/game/art/m4_board42/connector_pg.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'crimp',
          labelBn: 'হাইড্রোলিক টুলে কম্প্রেশন কানেক্টর',
          asset: 'assets/game/art/m4_board42/connector_crimp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bimetal',
          labelBn: 'তামা-অ্যালুমিনিয়ামে বাই-মেটালিক কানেক্টর',
          asset: 'assets/game/art/m4_board42/connector_bimetal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'plain_cu',
          labelBn: 'সাধারণ ক্ল্যাম্পে তামা-অ্যালুমিনিয়াম জোড়া',
          asset: 'assets/game/art/m4_board42/connector_plain_cu.svg',
          scene: true,
          correct: false,
          rejectBn: 'তামার সাথে অ্যালুমিনিয়াম জুড়তে বাই-মেটালিক কানেক্টর মাস্ট — নইলে গ্যালভানিক করোশন।',
        ),
        LearnBoardOption(
          id: 'twist',
          labelBn: 'কানেক্টর ছাড়া তার পেঁচিয়ে জোড়া',
          asset: 'assets/game/art/m4_board42/connector_twist.svg',
          scene: true,
          correct: false,
          rejectBn: 'জাম্পার বাঁধতে লাগে PG ক্ল্যাম্প বা কম্প্রেশন কানেক্টর — পেঁচানো জোড়া মানেই ঢিলা সংযোগ।',
        ),
        LearnBoardOption(
          id: 'pliers',
          labelBn: 'প্লায়ার দিয়ে কানেক্টর চেপে দেওয়া',
          asset: 'assets/game/art/m4_board42/connector_pliers.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম্প্রেশন কানেক্টরে সঠিক ডাই দিয়ে হাইড্রোলিক টুল ব্যবহার করুন — প্লায়ার নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জাম্পারে PG ক্ল্যাম্প বা কম্প্রেশন কানেক্টর লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কম্প্রেশনে সঠিক ডাই দিয়ে হাইড্রোলিক টুল চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তামা-অ্যালুমিনিয়ামে বাই-মেটালিক কানেক্টর মাস্ট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তার শক্ত করে পেঁচালে কানেক্টর লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো ক্ল্যাম্পে তামা-অ্যালুমিনিয়াম জোড়া চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্লায়ারে চাপলেও কানেক্টর ঠিকঠাক বসে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তামা-অ্যালুমিনিয়ামে সরাসরি জোড়ায় কোনো ভয় নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ACSR বা AAAC — কানেক্টর যেকোনো একটা হলেই হলো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ডাই যেকোনো মাপের হলেও কম্প্রেশন ঠিক থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fit',
      promptBn: 'PG ক্ল্যাম্প বসাবেন — হাতের কাজটা কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'brush',
          labelBn: 'স্টিল ব্রাশে তার ঘষে পরিষ্কার',
          asset: 'assets/game/art/m4_board42/fit_brush.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'paste',
          labelBn: 'অ্যালুমিনিয়ামে অ্যান্টি-অক্সিডেন্ট পেস্ট',
          asset: 'assets/game/art/m4_board42/fit_paste.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wrenches',
          labelBn: 'দুই রেঞ্চে বল্টু ধরে নাট ঘোরানো',
          asset: 'assets/game/art/m4_board42/fit_wrenches.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dirty',
          labelBn: 'ময়লা-অক্সাইড ধরা তারেই ক্ল্যাম্প',
          asset: 'assets/game/art/m4_board42/fit_dirty.svg',
          scene: true,
          correct: false,
          rejectBn: 'পৃষ্ঠ ভালোভাবে পরিষ্কার না করলে সবচেয়ে ভালো কানেক্টরও ব্যর্থ হবে — আগে স্টিল ব্রাশ।',
        ),
        LearnBoardOption(
          id: 'one_wrench',
          labelBn: 'এক রেঞ্চে নাট, বল্টুও ঘুরছে',
          asset: 'assets/game/art/m4_board42/fit_one_wrench.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটি রেঞ্চে বল্টুর মাথা ধরে অন্যটিতে নাট ঘোরান — তবেই কানেক্টর ঠিকমতো চেপে বসে।',
        ),
        LearnBoardOption(
          id: 'uneven',
          labelBn: 'এক বল্টু টাইট, অন্যটা ঢিলা',
          asset: 'assets/game/art/m4_board42/fit_uneven.svg',
          scene: true,
          correct: false,
          rejectBn: 'নাট-বল্টু সমানভাবে, সঠিক টর্কে টাইট দিন — তাড়াহুড়োর কানেকশন হটস্পটের জন্ম দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জোড়ার আগে স্টিল ব্রাশে ময়লা-অক্সাইড তুলুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অ্যালুমিনিয়ামে অ্যান্টি-অক্সিডেন্ট পেস্ট দিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এক রেঞ্চে বল্টু ধরে অন্যটিতে নাট ঘোরান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নতুন কানেক্টর হলে পরিষ্কারের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটা রেঞ্চেই নাট টাইট দেওয়া যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটা বল্টু টাইট থাকলেই ক্ল্যাম্প ধরে রাখে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ময়লা তারে ক্ল্যাম্প আরও শক্ত করে বসে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তাড়াতাড়ি সারা কানেকশনেই কাজ ভালো হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পেস্ট শুধু তামার তারেই লাগাতে হয়, অন্যে নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'shape',
      promptBn: 'প্রবল বাতাসে জাম্পার দুলছে — কোন আকৃতি নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'u',
          labelBn: 'মসৃণ U আকৃতির জাম্পার',
          asset: 'assets/game/art/m4_board42/shape_u.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'support',
          labelBn: 'সাপোর্ট ইনসুলেটরে ধরা জাম্পার',
          asset: 'assets/game/art/m4_board42/shape_support.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'arm',
          labelBn: 'টানটান জাম্পার ক্রস-আর্মে ঠেকছে',
          asset: 'assets/game/art/m4_board42/shape_arm.svg',
          scene: true,
          correct: false,
          rejectBn: 'জাম্পারকে মসৃণ U বা C আকৃতি দিন — বাতাসে দুললেও যেন ক্রস-আর্মে না ঠেকে।',
        ),
        LearnBoardOption(
          id: 'phase',
          labelBn: 'লম্বা জাম্পার পাশের ফেজে ঠেকছে',
          asset: 'assets/game/art/m4_board42/shape_phase.svg',
          scene: true,
          correct: false,
          rejectBn: 'দৈর্ঘ্য এমন হবে যাতে প্রবল বাতাসে দুললেও জাম্পার পাশের ফেজকে স্পর্শ না করে।',
        ),
        LearnBoardOption(
          id: 'kink',
          labelBn: 'ধারালো কোণে ভাঁজ করা জাম্পার',
          asset: 'assets/game/art/m4_board42/shape_kink.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধারালো প্রান্তে করোনা — হালকা নীল আভা, হিসহিস শব্দ, টিভি-রেডিওতে নয়েজ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মসৃণ U বা C আকৃতি বাতাসেও নিরাপদ দূরত্ব রাখে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দরকারে জাম্পার সাপোর্ট ইনসুলেটর দোলা আটকায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ধারালো প্রান্ত রাখলে করোনা ডিসচার্জ হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জাম্পার যত টানটান, বাতাসে তত নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ক্রস-আর্মে একটু ঠেকলে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লম্বা জাম্পার পাশের ফেজ ছুঁলেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ধারালো ভাঁজে জাম্পারে কারেন্ট আরও ভালো চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জাম্পারের আকৃতি নিয়ে ভাবার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাতাসে দোলা জাম্পারের স্বাভাবিক, চিন্তা নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'patrol',
      promptBn: 'রাতে লাইন পেট্রোলিং — কোন জাম্পারে বিপদের লক্ষণ নেই?',
      options: [
        LearnBoardOption(
          id: 'calm',
          labelBn: 'অন্ধকারে শান্ত, মসৃণ জাম্পার',
          asset: 'assets/game/art/m4_board42/patrol_calm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'calm_support',
          labelBn: 'সাপোর্টে ধরা শান্ত জাম্পার',
          asset: 'assets/game/art/m4_board42/patrol_calm_support.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hot',
          labelBn: 'কানেকশন লাল হয়ে জ্বলছে',
          asset: 'assets/game/art/m4_board42/patrol_hot.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলা কানেকশনে উচ্চ রেজিস্ট্যান্স, I²R লসে প্রচণ্ড তাপ — রাতে হটস্পট লাল হয়ে জ্বলে।',
        ),
        LearnBoardOption(
          id: 'spark',
          labelBn: 'কানেকশন থেকে ফুলকি ঝরছে',
          asset: 'assets/game/art/m4_board42/patrol_spark.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্রমাগত স্পার্কিং বিপদের লক্ষণ — কাছের রেডিও-টিভিতেও নয়েজ আসে। জানিয়ে দিন।',
        ),
        LearnBoardOption(
          id: 'corona',
          labelBn: 'ক্ল্যাম্পে হালকা নীল আভা',
          asset: 'assets/game/art/m4_board42/patrol_corona.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধারালো বা অমসৃণ প্রান্তে করোনা — নীল আভা আর হিসহিস শব্দ, রেডিও-টিভিতে নয়েজ।',
        ),
        LearnBoardOption(
          id: 'fallen',
          labelBn: 'ক্ল্যাম্প গলে তার মাটিতে',
          asset: 'assets/game/art/m4_board42/patrol_fallen.svg',
          scene: true,
          correct: false,
          rejectBn: 'লক্ষণ উপেক্ষা করলে কানেক্টর গলে তার ছিঁড়ে পড়ে — আগুন লাগার কারণ হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রাতে লাল আভা মানে ঢিলা জাম্পারের হটস্পট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্পার্ক বা হিসহিস শব্দ ঢিলা কানেকশনের লক্ষণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লুজ জাম্পার টাইটে পারমিট, PPE আর সঠিক পদ্ধতি চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রাতে লাল আভা তো জাম্পারের স্বাভাবিক রং', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছোট্ট স্পার্ক হলে লাইনের কোনো বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টিভিতে নয়েজের সাথে লাইনের কোনো সম্পর্ক নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রাতে নীল আভা মানে জাম্পার একদম ঠিকঠাক আছে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হিসহিস শব্দ হলে পরের মাসে এসে দেখলেই চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গরম জাম্পার নিজে থেকেই ঠান্ডা হয়ে যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board42Lines.rivalTaunt,
    rivalLineBn: M4Board42Lines.rivalMyth,
    exitBn: M4Board42Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ঢিলা জাম্পারে হটস্পট',
      'গলে পড়া ক্ল্যাম্প',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'জাম্পারের ভেতর দিয়ে পুরো লাইনের কারেন্ট যায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ঢিলা মানেই উচ্চ রেজিস্ট্যান্সের গরম পয়েন্ট', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সময়ের সাথে সেই তাপ বড় ফল্টে পরিণত হয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'জাম্পারে টান নেই, তাই ঢিলা থাকলেও চলে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ঢিলা জাম্পারে কারেন্ট কম যায়, তাই নিরাপদ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ঝুলন্ত তার একটু ঢিলা হওয়াই স্বাভাবিক', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'গরম হলে জাম্পার নিজেই আবার টাইট হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ঢিলা কানেকশনে আগুন লাগার কোনো ভয় নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ফল্ট হলে তখন টাইট দিলেই যথেষ্ট, আগে নয়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board42Lines {
  static const rivalTaunt = 'আরে, জাম্পার নিয়ে এত মাথাব্যথা কেন? ওটায় তো কোনো টানই নেই!';

  /// Lesson 4.2's first myth buster, word for word.
  static const rivalMyth = 'জাম্পারটা তো শুধু ঝুলছে, ওটা একটু লুজ থাকলেও চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
