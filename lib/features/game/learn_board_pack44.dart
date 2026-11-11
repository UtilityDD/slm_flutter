import 'learn_board_models.dart';

/// Module 4 Lesson 4.4 (ডিও (DO) ফিউজ পরিচালনা করা), the picture board
/// (rung `4.4/learn`, pack `learn_4_4`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board44_art.py`. Every round
/// and every trap comes from the lesson text (and its reviewed film script):
///  * prep: an undamaged operating rod (hot stick) of the right length and
///    voltage rating; full PPE — helmet, insulated gloves and, above all, a
///    face shield or safety goggles; a dry, level standing place; enough
///    clearance around and overhead;
///  * link: clean the barrel and contacts with a dry cloth; seat the link's
///    top button in the top contact; wind the flexible tail round the bottom
///    contact and tighten the nut — not too tight, not too loose (a loose
///    joint heats and ruins the barrel); the leader wire must not block the
///    expulsion port;
///  * open: stand with the fuse to the side / at an angle, never straight
///    under or in front; hook the puller firmly in the ring; face aside, one
///    quick, firm, controlled pull — a slow pull draws the arc out;
///  * close: seat the barrel in the bottom hinge, then, face aside, one quick
///    confident push into the top contact and see it lock; a little spark on
///    closing is normal (load current, transformer inrush) — no opening and
///    closing again and again; it stops once the contact locks;
///  * field (the pro tips): a heavily loaded fuse is opened with a load break
///    tool on the stick; when a fault blows one fuse, open the other two too,
///    clear the fault, then close all three one by one; a top contact that
///    heats or sparks after closing is weak or worn — it is repaired.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack44 = LearnBoardPack(
  lessonId: '4.4',
  titleBn: 'ডিও (DO) ফিউজ পরিচালনা করা',
  badgeBn: 'কাজের কারিগর',
  introBn: 'ডিও ফিউজ খুলতে-লাগাতে আর্ক হবেই। হট স্টিক, ফেস শিল্ড, পাশে দাঁড়ানো — আর দ্রুত হাত।',
  earnedBn: 'পাশে দাঁড়িয়ে, মুখ সরিয়ে — এক টানে খোলা, এক ধাক্কায় লক। হট স্টিক ছাড়া ফিউজে হাত নয়।',
  slots: [
    LearnBoardSlot(
      id: 'prep',
      promptBn: 'ডিও ফিউজ অপারেট করতে পোলের নিচে এলেন — কোন প্রস্তুতি ঠিক?',
      options: [
        LearnBoardOption(
          id: 'shield',
          labelBn: 'অক্ষত হট স্টিক, ফেস শিল্ড পরে',
          asset: 'assets/game/art/m4_board44/prep_shield.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'goggles',
          labelBn: 'অক্ষত হট স্টিক, সেফটি গগলস পরে',
          asset: 'assets/game/art/m4_board44/prep_goggles.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'no_eyes',
          labelBn: 'ফেস শিল্ড বা গগলস ছাড়াই',
          asset: 'assets/game/art/m4_board44/prep_no_eyes.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ অপারেটে আর্ক বা স্পার্ক স্বাভাবিক — ফেস শিল্ড বা সেফটি গগলস মুখ আর চোখকে ফ্ল্যাশ থেকে বাঁচায়।',
        ),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'জল-কাদা, অসমান জমিতে দাঁড়িয়ে',
          asset: 'assets/game/art/m4_board44/prep_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'দাঁড়ানোর জায়গা শুকনো আর সমতল কিনা আগে দেখুন — জল-কাদায় দাঁড়িয়ে ফিউজ অপারেট নয়।',
        ),
        LearnBoardOption(
          id: 'cracked',
          labelBn: 'ফাটা হট স্টিক নিয়েই কাজে',
          asset: 'assets/game/art/m4_board44/prep_cracked.svg',
          scene: true,
          correct: false,
          rejectBn: 'অপারেটিং রড হতে হবে অক্ষত, সঠিক দৈর্ঘ্যের আর উপযুক্ত ভোল্টেজ রেটিং-এর — ফাটা রডে কাজ নয়।',
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'মাথার ওপরে ডালপালার নিচে দাঁড়িয়ে',
          asset: 'assets/game/art/m4_board44/prep_branch.svg',
          scene: true,
          correct: false,
          rejectBn: 'চারপাশে আর মাথার ওপরে পর্যাপ্ত নিরাপদ দূরত্ব (ক্লিয়ারেন্স) আছে কিনা আগে নিশ্চিত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফেস শিল্ড বা গগলস মুখ-চোখকে ফ্ল্যাশ থেকে বাঁচায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হট স্টিক অক্ষত, সঠিক দৈর্ঘ্য ও ভোল্টেজ রেটিং-এর', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দাঁড়ানোর জায়গা শুকনো, সমতল আর মাথার ওপর ফাঁকা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফিউজ খোলায় আর্ক হয় না, ফেস শিল্ড বাড়তি ঝামেলা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্টিকে ছোট ফাটল থাকলেও এক-আধবার চলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাদা-জলে দাঁড়ালেও গ্লাভস থাকলে কোনো ভয় নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ডালপালা থাকলেও স্টিক ঘুরিয়ে কাজ সেরে ফেলা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যেকোনো দৈর্ঘ্যের রড হলেই ফিউজ খোলা চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অভিজ্ঞ হাতে হেলমেট আর গ্লাভস থাকলেই যথেষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'link',
      promptBn: 'ব্যারেলে নতুন ফিউজ লিঙ্ক বাঁধছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'wrap',
          labelBn: 'নিচের তার পেঁচিয়ে নাট টাইট',
          asset: 'assets/game/art/m4_board44/link_wrap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wipe',
          labelBn: 'শুকনো কাপড়ে ব্যারেল-কন্টাক্ট মোছা',
          asset: 'assets/game/art/m4_board44/link_wipe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'port',
          labelBn: 'গ্যাস বেরোনোর মুখে তার জড়ানো',
          asset: 'assets/game/art/m4_board44/link_port.svg',
          scene: true,
          correct: false,
          rejectBn: 'লিঙ্কের leader wire যেন এক্সপেলশন পোর্ট বা গ্যাস বেরোনোর মুখ বন্ধ না করে — শেষে দেখে নিন।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'ঢিলা তার, নাট না লাগিয়েই',
          asset: 'assets/game/art/m4_board44/link_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'কানেকশন ঢিলা থাকলে গরম হয়ে ব্যারেলটিকেই নষ্ট করে দিতে পারে — নাট সঠিকভাবে টাইট দিন।',
        ),
        LearnBoardOption(
          id: 'taut',
          labelBn: 'প্লায়ার্সে টেনে তার টানটান',
          asset: 'assets/game/art/m4_board44/link_taut.svg',
          scene: true,
          correct: false,
          rejectBn: 'তার খুব বেশি টাইটও নয়, খুব বেশি ঢিলাও নয় — নিয়ম অনুযায়ী পেঁচিয়ে সঠিক টানে বাঁধুন।',
        ),
        LearnBoardOption(
          id: 'button',
          labelBn: 'ওপরের বোতাম বাঁকা, না বসিয়েই',
          asset: 'assets/game/art/m4_board44/link_button.svg',
          scene: true,
          correct: false,
          rejectBn: 'লিঙ্কের ওপরের বোতাম ব্যারেলের ওপরের কন্টাক্টে ঠিকমতো বসান — ভুল বাঁধা লিঙ্ক ফল্টে ড্রপ-আউট না-ও হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঢিলা কানেকশন গরম হয়ে ব্যারেল নষ্ট করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গ্যাস বেরোনোর মুখ সবসময় খোলা রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল বাঁধা লিঙ্ক ফল্টে ড্রপ-আউট না-ও হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তার যত টানটান, ফিউজ তত ভালো কাজ করে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নাট একটু ঢিলা থাকলে কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'এক্সপেলশন পোর্টে তার গুঁজলে লিঙ্ক শক্ত থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ময়লা কন্টাক্টেও ফিউজ ঠিকঠাক কাজ করে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বোতাম বাঁকা থাকলেও লাগালে ঠিক বসে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেকোনো রেটিং-এর ফিউজ লিঙ্ক বাঁধলেই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'open',
      promptBn: 'লোডযুক্ত ডিও ফিউজ খুলবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pull',
          labelBn: 'রিং-এ পুলার আটকে দ্রুত এক টান',
          asset: 'assets/game/art/m4_board44/open_pull.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'side',
          labelBn: 'কোণাকুণি দাঁড়িয়ে, মুখ সরিয়ে খোলা',
          asset: 'assets/game/art/m4_board44/open_side.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'under',
          labelBn: 'ফিউজের ঠিক নিচে দাঁড়িয়ে টান',
          asset: 'assets/game/art/m4_board44/open_under.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজের ঠিক নিচে বা সামনে নয় — পোলের নিচে এমনভাবে দাঁড়ান যাতে ফিউজ থাকে পাশে বা কোণাকুণি।',
        ),
        LearnBoardOption(
          id: 'slow',
          labelBn: 'দ্বিধায় ধীরে ধীরে টেনে খোলা',
          asset: 'assets/game/art/m4_board44/open_slow.svg',
          scene: true,
          correct: false,
          rejectBn: 'দ্বিধা করবেন না — ধীর গতিতে খুললে আর্ক দীর্ঘস্থায়ী হয়। দ্রুত, দৃঢ় আর নিয়ন্ত্রিত এক টান।',
        ),
        LearnBoardOption(
          id: 'stare',
          labelBn: 'ফিউজের দিকে মুখ তুলে টান',
          asset: 'assets/game/art/m4_board44/open_stare.svg',
          scene: true,
          correct: false,
          rejectBn: 'মুখ একপাশে সরিয়ে তবেই টান — খোলার সময় আর্ক ফ্ল্যাশের সম্ভাবনা সবসময় থাকে।',
        ),
        LearnBoardOption(
          id: 'miss',
          labelBn: 'রিং-এ না আটকে খোঁচা দেওয়া',
          asset: 'assets/game/art/m4_board44/open_miss.svg',
          scene: true,
          correct: false,
          rejectBn: 'হট স্টিকের পুলার আগে ফিউজের রিং-এ ভালোভাবে আটকান — তারপর দ্রুত, নিয়ন্ত্রিত টান।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দ্রুত, দৃঢ় টানে আর্কের সময় কমে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফিউজ পাশে বা কোণাকুণি, মাথার ওপরে নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আপনি লোডযুক্ত সুইচ খুলছেন, মুখ সরান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আস্তে টানলে আর্ক ছোট হয়, তাই ধীরে খুলুন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঠিক নিচে দাঁড়ালে টান সোজা পড়ে, ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিউজের দিকে চেয়ে থাকলে টান ঠিক হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিং-এ না আটকে খোঁচালেও ফিউজ খুলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফেস শিল্ড আছে, তাই মুখ সরানোর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দ্বিধা থাকলে মাঝপথে থেমে দেখে নিন', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'close',
      promptBn: 'ফিউজ আবার লাগাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'hinge',
          labelBn: 'আগে ব্যারেল নিচের কব্জায় বসানো',
          asset: 'assets/game/art/m4_board44/close_hinge.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lock',
          labelBn: 'মুখ সরিয়ে এক ধাক্কায় লক',
          asset: 'assets/game/art/m4_board44/close_lock.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'half',
          labelBn: 'আধখানা লাগিয়ে ছেড়ে দেওয়া',
          asset: 'assets/game/art/m4_board44/close_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ সঠিকভাবে লক হয়েছে কিনা নিশ্চিত করুন — কন্টাক্ট ঠিকমতো লক হলেই স্পার্ক থেমে যায়।',
        ),
        LearnBoardOption(
          id: 'reopen',
          labelBn: 'স্পার্ক দেখে আবার টেনে খোলা',
          asset: 'assets/game/art/m4_board44/close_reopen.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্থায়ী ফল্ট না থাকলে লাগানোর সময় সামান্য স্পার্ক স্বাভাবিক — বারবার খোলা-বন্ধে যন্ত্র আর ফিউজে চাপ পড়ে।',
        ),
        LearnBoardOption(
          id: 'slow',
          labelBn: 'ধীরে ধীরে ঠেলে তোলা',
          asset: 'assets/game/art/m4_board44/close_slow.svg',
          scene: true,
          correct: false,
          rejectBn: 'দ্রুত আর দৃঢ় পদক্ষেপে আর্কের সময় কমে — আত্মবিশ্বাসী এক ধাক্কায় ওপরের কন্টাক্টে লাগান।',
        ),
        LearnBoardOption(
          id: 'face',
          labelBn: 'মুখ তুলে ফিউজের দিকে চেয়ে ধাক্কা',
          asset: 'assets/game/art/m4_board44/close_face.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাগানোর সময়ও মুখ একপাশে রাখুন — সঠিক শারীরিক অবস্থান আপনাকে ফ্ল্যাশের বিপদ থেকে বাঁচায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাগানোর সময় সামান্য স্পার্ক স্বাভাবিক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঠিকমতো লক হলে কন্টাক্টের স্পার্ক থামে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে কব্জায় বসান, তারপর এক ধাক্কা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'স্পার্ক দেখলেই খুলে আবার লাগাতে হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আধখানা লাগলেও লাইন ঠিকই চলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ধীরে ঠেললে আর্ক কম হয়, সাবধানে তুলুন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বারবার খোলা-বন্ধে ফিউজের ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লক হলো কিনা দেখতে মুখ তুলে চেয়ে থাকুন', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কব্জা ছাড়াই সোজা ওপরে ঠেলে দেওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'field',
      promptBn: 'মাঠে ফিউজের কাজ — কোন অভ্যাসটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'lbt',
          labelBn: 'ভারী লোডে লোড ব্রেক টুলে খোলা',
          asset: 'assets/game/art/m4_board44/field_lbt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'three',
          labelBn: 'ফল্টে তিন ফেজের ফিউজই খোলা',
          asset: 'assets/game/art/m4_board44/field_three.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'plain',
          labelBn: 'ভারী লোডে শুধু পুলারে টান',
          asset: 'assets/game/art/m4_board44/field_plain.svg',
          scene: true,
          correct: false,
          rejectBn: 'খুব বেশি লোডযুক্ত ফিউজে হট স্টিকের মাথায় লোড ব্রেক টুল লাগান — এটি আর্ক নিরাপদে নিভিয়ে দেয়।',
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'উড়ে যাওয়া একটাই আবার লাগানো',
          asset: 'assets/game/art/m4_board44/field_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল্টে একটি ফিউজ উড়লে বাকি দুটিও খুলুন, ফল্ট সারিয়ে তারপর তিনটি ফিউজ একে একে লাগান।',
        ),
        LearnBoardOption(
          id: 'hot',
          labelBn: 'গরম কন্টাক্ট ফেলে রেখে চলে যাওয়া',
          asset: 'assets/game/art/m4_board44/field_hot.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাগানোর পর ওপরের কন্টাক্ট গরম হলে বা স্পার্ক করলে সেটি দুর্বল বা ক্ষয়ে গেছে — মেরামত করা প্রয়োজন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লোড ব্রেক টুল আর্ককে চেম্বারে নিরাপদে নেভায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফল্টে তিন ফেজ খুলে, সারিয়ে, একে একে লাগান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গরম বা স্পার্ক করা কন্টাক্ট মানে মেরামত চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভারী লোডেও সাধারণ পুলারে টানলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'উড়ে যাওয়া ফিউজটা লাগালেই ফল্ট মিটে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কন্টাক্ট একটু গরম হওয়া ভালো লক হওয়ার চিহ্ন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভেজা আবহাওয়ায় আর্ক ছোট হয়, চিন্তা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাকি দুটি ফেজ চালু রেখেই ফল্ট সারানো যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লোড ব্রেক টুল শুধু ঝামেলা, কাজে লাগে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board44Lines.rivalTaunt,
    rivalLineBn: M4Board44Lines.rivalMyth,
    exitBn: M4Board44Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'হট স্টিক ছাড়া হাতে ফিউজ খোলা',
      'গ্লাভসকেই একমাত্র সুরক্ষা ভাবা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'হট স্টিকের দৈর্ঘ্যই আপনাকে নিরাপদ দূরত্ব দেয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'গ্লাভস শুধু দ্বিতীয় স্তরের সুরক্ষা, প্রথম নয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ছোট হোক বা বড়, ফিউজ ধরতে হবে হট স্টিকেই', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'গ্লাভস পরা থাকলে হাতে ফিউজ খোলাই সবচেয়ে দ্রুত', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ছোট ফিউজে আর্ক হয় না, তাই স্টিক লাগে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ইনসুলেটেড গ্লাভসই হট স্টিকের পুরো কাজ করে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লাইনম্যান এমন শর্টকাট নিতেই পারেন', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'হট স্টিক শুধু বড় ফিউজের জন্যই দরকার', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'হাত দিয়ে খুললে ফিউজ বেশি নিয়ন্ত্রণে থাকে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board44Lines {
  static const rivalTaunt = 'আরে, এইটুকু ফিউজ! গ্লাভস তো পরাই আছে, স্টিক বয়ে আনার দরকার কী?';

  /// Lesson 4.4's first myth buster, word for word.
  static const rivalMyth = 'হাতে গ্লাভস পরা থাকলে হট স্টিক ছাড়াই ছোট ফিউজ খোলা যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
