import 'learn_board_models.dart';

/// Module 6 Lesson 6.6 (এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত আধুনিক লাইন), the
/// picture board (rung `6.6/learn`, pack `learn_6_6`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board66_art.py` (no words or
/// digits in the art). Every round and trap comes from the live lesson text
/// and the Module 6 rulings (`docs/module_specs/module6_rulings.md`, item spec
/// `docs/module_specs/module6_items/board_66.json`):
///  * bundle: what an AB cable is — three insulated phase cores and a bare or
///    insulated neutral-cum-messenger twisted together (point 1). Traps: open
///    bare wires on a cross-arm, insulated wires hung apart, cores twisted
///    with no messenger;
///  * grip: every clamp goes on the messenger (pro tip 1); the phase cores
///    carry ridges (pro tip 2). Traps: the jaw on a 1-ridge or a 3-ridge
///    core (point 2 importance), the whole bundle squeezed;
///  * pole: a suspension clamp on a straight run, a tension clamp where the
///    line ends or turns (point 2). Traps: an end or a turn on a suspension
///    clamp, an ordinary bare-line clamp biting the insulation (myth 2). Rule
///    R24 (slip class in the Do levels; boards are not scored by class);
///  * ipc: the IPC tightened until its shear head breaks off, its teeth
///    through the insulation (point 2, point 3). Traps: the shear head still
///    on (point 3 word for word), a service wire twisted round a bared core, a
///    bare-line bolted connector;
///  * care: pulled over rollers (point 3), a small nick sealed with
///    waterproof tape or heat-shrink (pro tip 4), with gloves — the cable is
///    always treated as live (safety tip, ruling X6). Traps: dragged over the
///    bracket and a stony road, the nick left open in the rain, bare hands
///    (R23 deadly class: its reason is myth 1's reality word for word).
/// Five rounds (owner, after Wave A): the spec's roller and nick rounds share
/// the one 'care' round; the spec's 'loose tension clamp' trap is left out
/// (the 'endsus' trap shows the same sag).
/// The rival's myth is the lesson's first myth, word for word.
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack66 = LearnBoardPack(
  lessonId: '6.6',
  titleBn: 'এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত আধুনিক লাইন',
  badgeBn: 'যন্ত্র গুরু',
  introBn: 'এবি কেবিল মানে মেসেঞ্জারে পেঁচানো ইনসুলেটেড তারের বান্ডিল। একে চিনুন, এর হার্ডওয়্যার আর যত্ন জেনে নিন।',
  earnedBn: 'ক্ল্যাম্প শুধু মেসেঞ্জারে, IPC শেয়ার-হেড ভাঙা পর্যন্ত টাইট; আর ইনসুলেটেড হলেও এবি কেবিল সবসময় লাইভ ধরে গ্লাভস পরে কাজ করুন।',
  slots: [
    LearnBoardSlot(
      id: 'bundle',
      promptBn: 'পোলের পাশ দিয়ে লাইন গেছে — কোনটা এবি কেবিল?',
      options: [
        LearnBoardOption(
          id: 'bare',
          labelBn: 'তিনটি ইনসুলেটেড ফেজ তার, বেয়ার মেসেঞ্জারে পেঁচানো',
          asset: 'assets/game/art/m6_board66/bundle_bare.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'insul',
          labelBn: 'তিনটি ইনসুলেটেড ফেজ তার, ইনসুলেটেড মেসেঞ্জারে পেঁচানো',
          asset: 'assets/game/art/m6_board66/bundle_insul.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'ক্রস-আর্মে চারটি খোলা বেয়ার তার, আলাদা আলাদা ঝুলছে',
          asset: 'assets/game/art/m6_board66/bundle_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'এটা খোলা বেয়ার লাইন — এবি কেবিলে ইনসুলেটেড ফেজ তার আর মেসেঞ্জার একসাথে পেঁচানো থাকে।',
        ),
        LearnBoardOption(
          id: 'apart',
          labelBn: 'ক্রস-আর্মে চারটি ইনসুলেটেড তার, আলাদা আলাদা ঝুলছে',
          asset: 'assets/game/art/m6_board66/bundle_apart.svg',
          scene: true,
          correct: false,
          rejectBn: 'এবি কেবিল একটি বান্ডিল — তারগুলো একসাথে পেঁচানো থাকে, আলাদা আলাদা ঝোলে না।',
        ),
        LearnBoardOption(
          id: 'nomsg',
          labelBn: 'তিনটি ইনসুলেটেড তার পেঁচানো, কিন্তু মেসেঞ্জার নেই',
          asset: 'assets/game/art/m6_board66/bundle_nomsg.svg',
          scene: true,
          correct: false,
          rejectBn: 'এবি কেবিলে নিউট্রাল-কাম-মেসেঞ্জার তার থাকে — সেটিই পুরো কেবিলের টান বা ওজন বহন করে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তিনটি ইনসুলেটেড ফেজ আর মেসেঞ্জার একসাথে পেঁচানো', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মেসেঞ্জার তারটিই পুরো কেবিলের টান বা ওজন বয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মেসেঞ্জার বেয়ার হতে পারে, ইনসুলেটেডও হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'এবি কেবিলের তারগুলো আলাদা আলাদা দূরে ঝোলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফেজ তারগুলোই এবি কেবিলের পুরো ওজন বহন করে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মেসেঞ্জার ছাড়া তিনটি তার পেঁচালেই এবি কেবিল', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্রস-আর্মে খোলা চারটি তারই আসল এবি কেবিল', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ইনসুলেটেড হলে আলাদা ঝোলা তারও এবি কেবিল', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মেসেঞ্জার শুধু দেখার জন্য, কোনো টান নেয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'grip',
      promptBn: 'পোলে ক্ল্যাম্প লাগছে — কোন তারে লাগলে ঠিক?',
      options: [
        LearnBoardOption(
          id: 'bare',
          labelBn: 'ক্ল্যাম্প ধরেছে মসৃণ বেয়ার মেসেঞ্জার তারটি',
          asset: 'assets/game/art/m6_board66/grip_bare.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mark',
          labelBn: 'ক্ল্যাম্প ধরেছে আলাদা মাপের ইনসুলেটেড মেসেঞ্জার',
          asset: 'assets/game/art/m6_board66/grip_mark.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'r1',
          labelBn: 'ক্ল্যাম্প ধরেছে এক রিজ দাগের একটা ফেজ তার',
          asset: 'assets/game/art/m6_board66/grip_r1.svg',
          scene: true,
          correct: false,
          // Live lesson 6.6 point 2 importance (its consequence clause).
          rejectBn: 'মেসেঞ্জার তারের বদলে ফেজ কন্ডাক্টরের ওপর ক্ল্যাম্প লাগালে কেবিলটি মারাত্মকভাবে ক্ষতিগ্রস্ত হবে এবং ছিঁড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'r3',
          labelBn: 'ক্ল্যাম্প ধরেছে তিন রিজ দাগের একটা ফেজ তার',
          asset: 'assets/game/art/m6_board66/grip_r3.svg',
          scene: true,
          correct: false,
          rejectBn: 'সব ক্ল্যাম্প মেসেঞ্জার তারের ওপরই লাগাতে হয় — টান বহন করে মেসেঞ্জার, ফেজ তার নয়।',
        ),
        LearnBoardOption(
          id: 'all',
          labelBn: 'একটা বড় ক্ল্যাম্পে পুরো বান্ডিলটা চেপে ধরা',
          asset: 'assets/game/art/m6_board66/grip_all.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ল্যাম্প ধরবে শুধু মেসেঞ্জার তারটিকে — এর ওপরই সমস্ত ক্ল্যাম্প লাগাতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সব ক্ল্যাম্প লাগে শুধু মেসেঞ্জার তারের ওপর', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফেজ তারে রিজ দাগ, মেসেঞ্জারের মাপ বা চিহ্ন আলাদা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কেবিলের টান বহন করে মেসেঞ্জার, ফেজ তার নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রিজ দাগওয়ালা ফেজ তারেই ক্ল্যাম্প বেশি টাইট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পুরো বান্ডিল চেপে ধরলে গ্রিপ সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো একটা তার ধরলেই ক্ল্যাম্পের কাজ হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফেজ তারে ক্ল্যাম্প দিলে কেবিলের ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মেসেঞ্জার ঢিলে থাকে, তাই ফেজ তার ধরতে হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রিজ দাগগুলো শুধু নকশা, এর কোনো মানে নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pole',
      promptBn: 'লাইনের পোলগুলো দেখুন — কোন পোলে ঠিক ক্ল্যাম্প?',
      options: [
        LearnBoardOption(
          id: 'straight',
          labelBn: 'লাইন যেখানে সোজা, সেই পোলে সাসপেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m6_board66/pole_straight.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'end',
          labelBn: 'লাইন যেখানে শেষ, সেই পোলে টেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m6_board66/pole_end.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'turn',
          labelBn: 'লাইন যেখানে মোড় নেয়, সেখানে টেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m6_board66/pole_turn.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'endsus',
          labelBn: 'লাইন যেখানে শেষ, সেই পোলে সাসপেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m6_board66/pole_endsus.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন যেখানে শেষ হচ্ছে, সেখানে টেনশন ক্ল্যাম্প পুরো টান সহ্য করে — নইলে কেবিল ঝুলে পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'turnsus',
          labelBn: 'লাইন যেখানে মোড় নেয়, সেখানে সাসপেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m6_board66/pole_turnsus.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন যেখানে মোড় নিচ্ছে, সেখানে টেনশন ক্ল্যাম্প মেসেঞ্জারকে শক্ত করে ধরে পুরো টান নেয়।',
        ),
        LearnBoardOption(
          id: 'bolt',
          labelBn: 'সোজা লাইনের পোলে বেয়ার তারের বোল্ট ক্ল্যাম্প',
          asset: 'assets/game/art/m6_board66/pole_bolt.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ বেয়ার কন্ডাক্টরের ক্ল্যাম্প এবি কেবিলের ইনসুলেশন কেটে দেবে, সঠিক গ্রিপও দেবে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সোজা লাইনে সাসপেনশন ক্ল্যাম্প কেবিল ঝোলায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাইনের শেষে বা মোড়ে টেনশন ক্ল্যাম্প টান নেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এবি কেবিলে লাগে এর নিজের বিশেষ হার্ডওয়্যার', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো ক্ল্যাম্প দিয়েই এবি কেবিল লাগানো যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মোড়ের পোলেও সাসপেনশন ক্ল্যাম্পই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাইনের শেষে শুধু ঝুলিয়ে রাখলেই টান সামলায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বেয়ার তারের ক্ল্যাম্প ইনসুলেশনের ওপরেও চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টেনশন ক্ল্যাম্প শুধু সোজা লাইনের জন্যই তৈরি', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ক্ল্যাম্পের ধরন বদলালে কাজে কোনো ফারাক নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ipc',
      promptBn: 'বাড়ির সার্ভিস সংযোগের জোড় — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'sheared',
          labelBn: 'টাইট দিতে দিতে IPC-র শেয়ার-হেড ভেঙে পড়েছে',
          asset: 'assets/game/art/m6_board66/ipc_sheared.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'teeth',
          labelBn: 'IPC-র ভেতরে: দাঁত ইনসুলেশন ভেদ করে তারে বসেছে',
          asset: 'assets/game/art/m6_board66/ipc_teeth.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'head',
          labelBn: 'IPC-র ভেতরে: শেয়ার-হেড না ভেঙেই টাইট থামানো',
          asset: 'assets/game/art/m6_board66/ipc_head.svg',
          scene: true,
          correct: false,
          // Live lesson 6.6 point 3, word for word.
          rejectBn: 'IPC কানেক্টরের শেয়ার-হেড না ভাঙা পর্যন্ত টাইট না দিলে কানেকশন লুজ থেকে যায়।',
        ),
        LearnBoardOption(
          id: 'twist',
          labelBn: 'কোরের আবরণ ছাড়িয়ে সার্ভিস তার পেঁচানো',
          asset: 'assets/game/art/m6_board66/ipc_twist.svg',
          scene: true,
          correct: false,
          rejectBn: 'সার্ভিস কানেকশনের জন্য IPC লাগে — এর ধারালো দাঁত ইনসুলেশন ভেদ করে সংযোগ দেয়।',
        ),
        LearnBoardOption(
          id: 'bolt',
          labelBn: 'কোরে বেয়ার লাইনের বোল্ট কানেক্টর লাগানো',
          asset: 'assets/game/art/m6_board66/ipc_bolt.svg',
          scene: true,
          correct: false,
          rejectBn: 'এবি কেবিলের জন্য সাধারণ হার্ডওয়্যার কাজ করে না — এর জন্য বিশেষ ধরনের ফিটিংস প্রয়োজন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শেয়ার-হেড ভাঙা পর্যন্ত টাইট দিলে IPC পোক্ত', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'IPC-র ধারালো দাঁত ইনসুলেশন ভেদ করে সংযোগ দেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সার্ভিস বা জাম্পার সংযোগে IPC লাগাতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শেয়ার-হেড না ভাঙলেও IPC-র কানেকশন পাকা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আবরণ ছাড়িয়ে তার পেঁচালেই সংযোগ মজবুত', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বেয়ার লাইনের কানেক্টর এবি কেবিলেও চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'IPC-র দাঁত আবরণে বসলেই সংযোগ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শেয়ার-হেড ভাঙা মানে IPC নষ্ট, বদলাতে হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'IPC লাগানোর আগে ইনসুলেশন ছাড়িয়ে নিতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'care',
      promptBn: 'কেবিল টানা আর আবরণের কাটা সারানো — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'roller',
          labelBn: 'পোলের রোলারের ওপর দিয়ে কেবিল টানা হচ্ছে',
          asset: 'assets/game/art/m6_board66/care_roller.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tape',
          labelBn: 'গ্লাভস পরে কাটার ওপর ওয়াটারপ্রুফ টেপ',
          asset: 'assets/game/art/m6_board66/care_tape.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shrink',
          labelBn: 'কাটা জায়গা জুড়ে হিট-স্রিঙ্ক টিউব বসানো',
          asset: 'assets/game/art/m6_board66/care_shrink.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'drag',
          labelBn: 'রোলার ছাড়া ব্র্যাকেট আর পাথুরে রাস্তায় টানা',
          asset: 'assets/game/art/m6_board66/care_drag.svg',
          scene: true,
          correct: false,
          rejectBn: 'এবি কেবিল টানার সময় বিশেষ রোলার লাগে, যাতে এর ইনসুলেশন ক্ষতিগ্রস্ত না হয়।',
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'আবরণের কাটা খোলা পড়ে আছে, বৃষ্টি পড়ছে',
          asset: 'assets/game/art/m6_board66/care_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশনে কাটা থাকলে সেখানে জল ঢুকে ফল্ট হতে পারে — ওয়াটারপ্রুফ টেপ বা হিট-স্রিঙ্ক টিউবে সারান।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে কাটার ওপর টেপ জড়ানো হচ্ছে',
          asset: 'assets/game/art/m6_board66/care_bare.svg',
          scene: true,
          correct: false,
          // Deadly class (R23). Myth 1's reality, word for word, then the
          // safety tip in short.
          rejectBn: M6Board66Lines.bareHandsReject,
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রোলারে টানলে ইনসুলেশনে কাটা বা নিক পড়ে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সামান্য কাটায় ওয়াটারপ্রুফ টেপ বা হিট-স্রিঙ্ক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ইনসুলেটেড হলেও লাইভ ধরে গ্লাভস পরে কাজ করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঘষে টানলেও মোটা আবরণের কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছোট কাটা খোলা থাকলেও ভেতরে জল ঢুকতে পারে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ইনসুলেটেড কেবিলে খালি হাতেই টেপ জড়ানো যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাটার পাশে টেপ দিলেই কাটাটা ঢাকা পড়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রোলার লাগানো মানে শুধু শুধু সময় নষ্ট করা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বৃষ্টিতে ভিজে কাটা জায়গা নিজেই জুড়ে যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board66Lines.rivalTaunt,
    rivalLineBn: M6Board66Lines.rivalMyth,
    exitBn: M6Board66Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'অদৃশ্য পিন-হোল',
      'হাতে মারাত্মক শক',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আবরণ শুধু আবহাওয়া আর হঠাৎ ছোঁয়া থেকে বাঁচায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'অদৃশ্য পিন-হোল বা ফাটলেই মারাত্মক শক লাগে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কাজের সময় এবি কেবিলকে সবসময় লাইভ ধরুন', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ইনসুলেটেড কেবিলে খালি হাতে কাজ পুরো নিরাপদ', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'এবি কেবিল তো লাইভ লাইন কাজের জন্যই তৈরি', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'কালো আবরণ থাকলে শক লাগার কোনো ভয়ই নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'গ্লাভস শুধু বেয়ার তারে লাগে, এবি কেবিলে নয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'পিন-হোল থাকলেও মোটা আবরণ কারেন্ট আটকায়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'আবরণ মোটা হলে PTW বা PPE-র দরকার নেই', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py` (ruling M6-12: the owner
/// gives the wording first).
abstract final class M6Board66Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, এ তো পুরো মোড়া তার! এতে আবার গ্লাভস কিসের?';

  /// Lesson 6.6's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'এবি কেবিল তো সম্পূর্ণ ইনসুলেটেড, তাই এটাতে খালি হাতে কাজ করা যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Same list under the Module 6 name (ruling M6-12).
  static const newRivalLines = toRecord;

  /// The bare-hands trap's reason (deadly class, R23): lesson 6.6 myth 1's
  /// reality, its last sentence word for word, then the safety tip in short
  /// (DRAFT wording — owner, for the second sentence).
  static const bareHandsReject =
      'যেকোনো ইনসুলেশনে একটি অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট। তাই সবসময় লাইভ ধরে, গ্লাভস পরে কাজ করুন।';

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen), the myth's right chips and the closing line. The sting is
  /// already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack66;
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
