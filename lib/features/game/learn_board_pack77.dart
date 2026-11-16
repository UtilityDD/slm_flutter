import 'learn_board_models.dart';

/// Module 7 Lesson 7.7 (দুর্ঘটনার রিপোর্ট: আপনার দায়িত্ব), the picture board
/// (rung `7.7/learn`, pack `learn_7_7`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board77_art.py` (no words in
/// the art; a note's lines are icons and stroke digits; the dead cow is drawn
/// without gore). Every round and trap comes from the live lesson text
/// (`tool/all_training_chapters_bn.json`, 7.7) and the Module 7 rulings
/// (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_77.json`):
///  * must: point 1 (Electricity Act 2003, section 161) — a death of a person
///    or an animal, any injury or an accident that could have hurt someone,
///    and big events like a fire or an explosion are reportable. The live
///    text has no '24 hours off work' condition (ruling X3), so the card with
///    a colleague in bed teaches the injury rule instead;
///  * duty: point 2 and myth 2 — the company reports formally, the lineman
///    tells his supervisor or the control room at once, with no delay; a
///    small shock still needs the doctor AND the report. The spec's separate
///    shock round folds into this round (ruling X6: five rounds, not six);
///  * note: point 3 and pro tips 2 and 3 — date, time and exact place, the
///    injured man's name, age and address, how it happened, the injury and
///    the witnesses; honest and exact, nothing hidden or blown up; a short
///    written note next to the call;
///  * scene: point 4 — nothing moved or changed without the Electrical
///    Inspector's or the police's permission, unless another danger must be
///    stopped (the sand on the oil ember);
///  * near: pro tip 1 and the RCA fact — a near miss with nobody hurt still
///    goes to the safety department; the aim is 'why did it happen', not 'who
///    erred'.
/// The rival's myth is the lesson's first myth, word for word (ruling M7-10).
/// Myth 2 (the 'small shock') lives in the duty round and its reasons. A
/// board has no freeze (kit design) and no deadly act: letting a coworker
/// coil a fallen wire and entering its zone are deadly only in the Do level.
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack77 = LearnBoardPack(
  lessonId: '7.7',
  titleBn: 'দুর্ঘটনার রিপোর্ট (Accident Reporting): আপনার দায়িত্ব',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board77Lines.intro,
  earnedBn: M7Board77Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'must',
      promptBn: 'কোন দুর্ঘটনার রিপোর্ট বাধ্যতামূলক — আর কোথায় ঠিকমতো খবর যাচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'cow',
          labelBn: 'ছেঁড়া তারের পাশে গরু মরেছে, লাইনম্যান দূর থেকে ফোন করছে',
          asset: 'assets/game/art/m7_board77/must_cow.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dtr',
          labelBn: 'পোড়া কালো DTR, ক্রু কন্ট্রোল রুমে ফোন করে জানাচ্ছে',
          asset: 'assets/game/art/m7_board77/must_dtr.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bed',
          labelBn: 'সাথী 3 দিন হাসপাতালে, রিপোর্ট লেখা হচ্ছে সুপারভাইজারের',
          asset: 'assets/game/art/m7_board77/must_bed.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'গরু মরে পড়ে আছে, ক্রু কাউকে না জানিয়ে সরে যাচ্ছে',
          asset: 'assets/game/art/m7_board77/must_walk.svg',
          scene: true,
          correct: false,
          rejectBn: 'মানুষ হোক বা পশু — বৈদ্যুতিক দুর্ঘটনায় মৃত্যু হলেই রিপোর্ট বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'gate',
          labelBn: 'DTR-এর আগুন নিভেছে, ক্রু কাউকে না বলে গেটে তালা দিচ্ছে',
          asset: 'assets/game/art/m7_board77/must_gate.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগুন লাগা বা বিস্ফোরণের মতো বড় ঘটনাও রিপোর্ট করতে হয়।',
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'সাথী 3 দিন বিছানায়, তবু রেজিস্টারে লেখা আছে "ছুটিতে"',
          asset: 'assets/game/art/m7_board77/must_leave.svg',
          scene: true,
          correct: false,
          // Live point 1, second bullet (the old '24 hours' condition is gone).
          rejectBn: 'যেকোনো দুর্ঘটনা যাতে কোনো মানুষ বা পশু আহত হয়েছে, বা মৃত্যু বা আঘাত হতে পারত — রিপোর্ট করতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মানুষ বা পশু, মৃত্যু হলেই রিপোর্ট বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কেউ আহত হলে বা আঘাত হতে পারত, রিপোর্ট করতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগুন বা বিস্ফোরণের মতো বড় ঘটনাও রিপোর্ট করতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অ্যাক্টের 161 ধারায় ইন্সপেক্টরকে জানানো বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'গরুর মৃত্যু হলে রিপোর্ট লাগে না, শুধু মানুষের হলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আগুন নিভে গেলে আর রিপোর্ট করার দরকার থাকে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আহত হলে নয়, রিপোর্ট শুধু মারা গেলেই করতে হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট ঘটনা চেপে গেলে কোনো আইনি ঝামেলায় পড়তে হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'শুধু কোম্পানির নিজের খাতায় লিখে রাখলেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'রিপোর্ট করলে ইন্সপেক্টর শুধু ঝামেলাই বাড়িয়ে দেয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'duty',
      promptBn: 'দুর্ঘটনা বা শক হয়ে গেছে — লাইনম্যান হিসেবে আপনার প্রথম কাজ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'call',
          labelBn: 'দুর্ঘটনা ঘটতেই লাইনম্যান সুপারভাইজারকে ফোন করছে',
          asset: 'assets/game/art/m7_board77/duty_call.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'doc',
          labelBn: 'শক খাওয়া সাথীকে ডাক্তারের কাছে নিচ্ছে, ফোনে জানাচ্ছে',
          asset: 'assets/game/art/m7_board77/duty_doc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'home',
          labelBn: 'সব গুটিয়ে বাড়ি যাচ্ছে, "কাল অফিসে গিয়ে বলব"',
          asset: 'assets/game/art/m7_board77/duty_home.svg',
          scene: true,
          correct: false,
          rejectBn: 'নির্ধারিত সময়ের (সাধারণত 24-48 ঘণ্টা) মধ্যে রিপোর্ট না হলে তা দণ্ডনীয় অপরাধ — খবর দিন সাথে সাথে।',
        ),
        LearnBoardOption(
          id: 'comp',
          labelBn: 'কাঁধ ঝাঁকিয়ে বলছে, "রিপোর্ট তো কোম্পানির কাজ"',
          asset: 'assets/game/art/m7_board77/duty_comp.svg',
          scene: true,
          correct: false,
          rejectBn: 'আনুষ্ঠানিক রিপোর্ট কোম্পানির দায়িত্ব — কিন্তু আপনি সাথে সাথে না জানালে তারা সময়মতো রিপোর্ট করবে কীভাবে?',
        ),
        LearnBoardOption(
          id: 'huddle',
          labelBn: 'ক্রু গোল হয়ে বলছে, "নিজেদের মধ্যেই মিটিয়ে নিই"',
          asset: 'assets/game/art/m7_board77/duty_huddle.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুর্ঘটনা লুকিয়ে রাখা একটি বড় আইনি অপরাধ — তাতে পরিস্থিতি আরও জটিল হয়।',
        ),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'ছোট শকের পর চা খেয়ে আবার মই বেয়ে উঠছে সাথী',
          asset: 'assets/game/art/m7_board77/duty_tea.svg',
          scene: true,
          correct: false,
          rejectBn: 'শকে শরীরের ভেতরের ক্ষতি অনেক সময় বাইরে থেকে বোঝা যায় না, পরে প্রকাশ পেতে পারে — ডাক্তার দেখান আর রিপোর্ট করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সাথে সাথে সুপারভাইজারকে জানানো লাইনম্যানের দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দেরি হলে কোম্পানি সময়মতো রিপোর্ট করতে পারে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঘটনা ছোট মনে হলেও সাথে সাথে খবর দেওয়াই নিয়ম', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দুর্ঘটনা লুকিয়ে রাখা বড় আইনি অপরাধ, জটিলতা বাড়ে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'রিপোর্ট শুধু কোম্পানির দায়িত্ব, লাইনম্যানের কিছু নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পরের দিন অফিসে জানালেও আইনে কোনো অসুবিধা হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছোট শকে ডাক্তারের কাছে যাওয়ার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ক্রুর মধ্যে মিটিয়ে নিলে দুর্ঘটনা হয়নি বলে ধরা হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হাতে দাগ না থাকলে শরীর ঠিক আছে ধরে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'ডাক্তার দেখালেই আর রিপোর্ট করার দরকার হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'note',
      promptBn: 'সুপারভাইজারকে পাঠানো কোন নোটটা ঠিকঠাক?',
      options: [
        LearnBoardOption(
          id: 'when',
          labelBn: 'নোটে তারিখ, সময়, পোল নম্বর, আহতের নাম-বয়স-ঠিকানা',
          asset: 'assets/game/art/m7_board77/note_when.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'how',
          labelBn: 'নোটে কীভাবে ঘটল, কী আঘাত লেগেছে, কে কে দেখেছে',
          asset: 'assets/game/art/m7_board77/note_how.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'vague',
          labelBn: 'নোটে শুধু "আজ সকালে লাইনের কাছে একটা ঘটনা"',
          asset: 'assets/game/art/m7_board77/note_vague.svg',
          scene: true,
          correct: false,
          rejectBn: 'রিপোর্টে চাই দুর্ঘটনার তারিখ, সময় আর সঠিক স্থান — ভাসা-ভাসা কথায় তদন্ত চলে না।',
        ),
        LearnBoardOption(
          id: 'hide',
          labelBn: 'নোটে লেখা "কেউ আহত হয়নি", অথচ সাথীর হাতে ব্যান্ডেজ',
          asset: 'assets/game/art/m7_board77/note_hide.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোনো তথ্য লুকোবেন না — সৎ এবং নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি।',
        ),
        LearnBoardOption(
          id: 'over',
          labelBn: 'নোটে "পুরো ফিডার ফেটে গেছে", আসলে একটা গ্লাভস পুড়েছে',
          asset: 'assets/game/art/m7_board77/note_over.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাড়িয়ে বলবেন না — সৎ এবং নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রিপোর্টে তারিখ, সময়, জায়গা আর আহতের পরিচয় লিখতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রিপোর্টে ঘটনা কীভাবে ঘটল আর কী আঘাত লাগল, তাও থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সৎ আর নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মুখে বলার পাশে ছোট লিখিত নোট দায়িত্ব পালনের প্রমাণ', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'ভাসা-ভাসা কথা লিখলেও তদন্তের জন্য যথেষ্ট হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আঘাত লুকিয়ে সব ঠিক লিখলে সুপারভাইজার খুশি থাকেন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ঘটনা বড় করে লিখলে বেশি গুরুত্ব দিয়ে দেখা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সময় আর জায়গা লেখা শুধু ঝামেলাই বাড়িয়ে দেয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কার দোষ ছিল শুধু সেটুকু লিখলেই রিপোর্ট সম্পূর্ণ', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'নাম আর ঠিকানা না লিখলেও নোট ঠিকই থাকে, চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'scene',
      promptBn: 'দুর্ঘটনার পর ঘটনাস্থল — কোথায় ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'asis',
          labelBn: 'সব যেমন ছিল তেমনই আছে, ক্রু ভ্যানের পাশে অপেক্ষায়',
          asset: 'assets/game/art/m7_board77/scene_asis.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sand',
          labelBn: 'তেলের পাশে জ্বলন্ত ফুলকিটুকু শুধু বালি দিয়ে ঢাকা হচ্ছে',
          asset: 'assets/game/art/m7_board77/scene_sand.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ladder',
          labelBn: 'মই দাঁড় করানো হয়েছে, যন্ত্রপাতি ব্যাগে ভরা হচ্ছে',
          asset: 'assets/game/art/m7_board77/scene_ladder.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইন্সপেক্টর বা পুলিশের অনুমতি ছাড়া ঘটনাস্থল থেকে কিছু সরানো বা পরিবর্তন করা উচিত নয়।',
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'পোড়া ফিডার পিলারে নতুন একটা ফিউজ লাগানো হচ্ছে',
          asset: 'assets/game/art/m7_board77/scene_fuse.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঘটনাস্থল পরিবর্তন করলে তদন্ত প্রক্রিয়া ব্যাহত হতে পারে।',
        ),
        LearnBoardOption(
          id: 'sweep',
          labelBn: 'পোড়া টুকরোগুলো ঝাঁট দিয়ে তুলে বস্তায় ভরা হচ্ছে',
          asset: 'assets/game/art/m7_board77/scene_sweep.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঘটনাস্থল সংরক্ষণ প্রমাণের জন্য অত্যন্ত জরুরি — ঝাড়পোঁছ মানে প্রমাণ নষ্ট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ইন্সপেক্টর বা পুলিশের অনুমতি ছাড়া কিছু সরানো নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঘটনাস্থল যেমন আছে তেমন থাকলে প্রমাণ নষ্ট হয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অন্য কোনো বিপদ আটকাতে হলেই শুধু কিছু বদলানো চলে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কাজ তাড়াতাড়ি শুরু করতে সব সরিয়ে ফেলা ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নতুন ফিউজ লাগালে প্রমাণ আরও পরিষ্কার হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝাড়পোঁছ করলে ঘটনাস্থল সাজানো-গোছানো থাকে বলে ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মই আর যন্ত্রপাতি গুছিয়ে রাখা সবসময়ই ঠিক কাজ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আগুনের ফুলকি জ্বললেও দূর থেকে শুধু দেখে যাওয়া ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঘটনাস্থল বদলালে তদন্তে কোনো অসুবিধা কখনোই হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'near',
      promptBn: 'কেউ আহত হয়নি — একটুর জন্য বেঁচে গেছেন। তারপর?',
      options: [
        LearnBoardOption(
          id: 'tell',
          labelBn: 'স্প্যানার পড়ল সাথীর পাশে, সেফটি ডিপার্টমেন্টে ফোন',
          asset: 'assets/game/art/m7_board77/near_tell.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'write',
          labelBn: 'Near Miss নিয়ে ছোট একটা লিখিত নোট পাঠানো হচ্ছে',
          asset: 'assets/game/art/m7_board77/near_write.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'laugh',
          labelBn: 'ক্রু হেসে বলছে, "বেঁচে গেছি, ভুলে যাও এসব কথা"',
          asset: 'assets/game/art/m7_board77/near_laugh.svg',
          scene: true,
          correct: false,
          rejectBn: 'Near Miss জানালে ভবিষ্যতের বড় দুর্ঘটনা প্রতিরোধ করা যায়।',
        ),
        LearnBoardOption(
          id: 'sign',
          labelBn: 'ভ্যানের বোর্ডে লেখা, "শুধু বড় দুর্ঘটনাই লিখি"',
          asset: 'assets/game/art/m7_board77/near_sign.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেউ আহত না হলেও ছোট দুর্ঘটনা কোম্পানির সেফটি ডিপার্টমেন্টকে জানানো উচিত।',
        ),
        LearnBoardOption(
          id: 'blame',
          labelBn: 'মিটিং-এ কাকে দোষ দেওয়া যায় সেটাই খোঁজা হচ্ছে',
          asset: 'assets/game/art/m7_board77/near_blame.svg',
          scene: true,
          correct: false,
          rejectBn: 'তদন্তের লক্ষ্য "কে ভুল করেছে" নয়, "কেন ভুলটি হলো" — যাতে পুরো সিস্টেমের উন্নতি হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'Near Miss জানালে বড় দুর্ঘটনা আটকানো যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কেউ আহত না হলেও সেফটি ডিপার্টমেন্টকে জানাতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'Near Miss থেকে শিখলে পুরো সিস্টেমের উন্নতি হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আহত না হলে সেটা দুর্ঘটনা বলেই গণ্য হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বড় ঘটনা না হলে সেফটি ডিপার্টমেন্টের সময় নষ্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একজনকে দোষ দিয়ে দিলেই একই ভুল আর কখনো হবে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বেঁচে গেলে ঘটনাটা ভুলে যাওয়াই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট ঘটনা লিখলে শুধু কাগজের বোঝাই বেড়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'Near Miss মানে কারও না কারও চাকরি যাওয়া নিশ্চিত', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board77Lines.rivalTaunt,
    rivalLineBn: M7Board77Lines.rivalMyth,
    exitBn: M7Board77Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board77Lines.sting,
    dangerHints: [
      'দুর্ঘটনা লুকোনো',
      'বড় আইনি অপরাধ',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'দুর্ঘটনা চেপে যাওয়া বড় আইনি অপরাধ, ঝামেলা আরও বাড়ে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'সৎ রিপোর্ট ভালো সুরক্ষা সংস্কৃতির একটা লক্ষণ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কোম্পানি দুর্ঘটনা আটকাতে চায়, শাস্তি দিতে নয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'রিপোর্ট করলে সুপারভাইজারের চাকরি যাবেই যাবে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'চুপ থাকলে কেউ কিছু জানতে পারবে না, ঝামেলাও শেষ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'দুর্ঘটনা লুকোনো কর্মীকে কোম্পানি পুরস্কার দেয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'রিপোর্ট শুধু দোষীকে শাস্তি দিতে লেখা হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'দুর্ঘটনা চাপা দিলে আইন নিজে থেকে মাফ করে দেয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'রিপোর্ট না করা ভালো সুরক্ষা সংস্কৃতির লক্ষণ', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] and [sting] are
/// already in recorded voices; [toRecord] stay silent (caption held for
/// reading) until the director records them with `tool/rival_clip.py`.
abstract final class M7Board77Lines {
  /// DRAFT wording — owner.
  static const intro = 'দুর্ঘটনার পর কী জানাবেন, কাকে আর কখন — আইন বলে দিয়েছে। ঠিকটা চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'যেকোনো দুর্ঘটনা বা Near Miss সাথে সাথে জানান, সবটা সত্যি আর ঠিকঠাক লিখুন, ঘটনাস্থল যেমন আছে তেমন রাখুন।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'রিপোর্ট করলেই ঝামেলা, বুঝলেন? সব চেপে যান!';

  /// Lesson 7.7's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'দুর্ঘটনা রিপোর্ট করলে আমার বা আমার সুপারভাইজারের চাকরি চলে যেতে পারে, তাই চুপ করে থাকাই ভালো।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

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

  /// Every line the guide speaks on this board: the intro, each round's
  /// question, every trap's reason, every right reason (spoken the first time
  /// it is chosen), the myth's right reasons and the closing line.
  static List<String> get guideSpoken {
    final p = learnBoardPack77;
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
