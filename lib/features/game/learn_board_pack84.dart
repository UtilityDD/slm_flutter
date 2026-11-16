import 'learn_board_models.dart';

/// Module 8 Lesson 8.4 (গ্রিড কোড (Grid Code): সিস্টেম শৃঙ্খলার নিয়ম), the
/// picture board (rung `8.4/learn`, pack `learn_8_4`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board84_art.py` (the readings a
/// worker reads — a meter's Hz, a bus voltmeter's kV, an OLTC tap number — drawn
/// as stroke glyphs with English digits; no words in the art). Every round and
/// trap comes from the live lesson 8.4 text and the Module 8 rulings
/// (`docs/module_specs/module8_rulings.md`, item spec
/// `docs/module_specs/module8_items/board_84.json`):
///  * freq: the wall frequency meter — the target band 49.90 to 50.05 Hz; below
///    49.0 is the alarm. Traps: 49.70 (load up), 50.20 (load down), 48.90;
///  * hotline: an SLDC order on the hotline — pick the hotline up at once and
///    put the 11 kV feeder OFF; the order is not for questions (pro tip 1).
///    Traps: the black phone chatted on while the hotline rings; arguing with
///    the feeder ON; the tea and the order slip on the desk with the feeder ON;
///  * register: rotational load shedding — a different area dark each day, the
///    area map where today's dark area was lit before (the lesson's rotation).
///    Traps: the same area dark three days running; one village dark again while
///    the rest were never cut; no feeder cut though the order is pinned;
///  * bus: the bus voltmeters against the band, out above +6 % or below -9 %
///    (live lesson, ruling M8-12; the spec's '±6-9 %' is withdrawn). Traps:
///    12.1 kV (+10 %), 9.9 kV (-10 %), 36.5 kV (+10.6 %). Safe: 11.0, 11.3 and
///    32.0 kV (-3 %), so the lower side of the band is shown too. Every bus card
///    carries the same OLTC tap box and the names give no verdict; the OLTC daily
///    check sits in the 9.9 kV reject. Six pictures per round (ruling X6);
///  * drawal: the drawal gauge — the 'টানা' bar at or under the 'ভাগ' line; a
///    low 11 kV voltmeter with the capacitor bank ON (pro tip 2). Traps: the
///    bar well above the line at 49.80 Hz; the capacitor OFF with a pump
///    smoking; an operator shouting at a consumer (pro tip 3's lesson words).
/// Five rounds (ruling M8-21); every round deals one safe picture and three
/// traps. This board carries no deadly class: every row of the deadly/slip
/// table is a slip (rulings M8-1, M8-4, M8-12), so no card freezes the board.
///
/// The rival's myth is the lesson's first myth, word for word (ruling M8-14).
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack84 = LearnBoardPack(
  lessonId: '8.4',
  titleBn: 'গ্রিড কোড (Grid Code): সিস্টেম শৃঙ্খলার নিয়ম',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'গ্রিড কোড মানে সবার একই সুরে চলা। ফ্রিকোয়েন্সি, লোড শেডিং, ভোল্টেজ — ঠিক ছবিটা চিনে নিন।',
  earnedBn: 'নির্দেশ এলে প্রশ্ন নয়, আগে ফিডার OFF; ফ্রিকোয়েন্সির লক্ষ্য 49.90 থেকে 50.05 Hz',
  slots: [
    LearnBoardSlot(
      id: 'freq',
      promptBn: 'কন্ট্রোল রুমের ফ্রিকোয়েন্সি মিটার — কোনটায় গ্রিডের হার্টবিট ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'f50',
          labelBn: 'মিটারে 50.00 Hz',
          asset: 'assets/game/art/m8_board84/freq_ok50.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'f4995',
          labelBn: 'মিটারে 49.95 Hz',
          asset: 'assets/game/art/m8_board84/freq_ok4995.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'f5003',
          labelBn: 'মিটারে 50.03 Hz',
          asset: 'assets/game/art/m8_board84/freq_ok5003.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'f4970',
          labelBn: 'মিটারে 49.70 Hz',
          asset: 'assets/game/art/m8_board84/freq_low4970.svg',
          scene: true,
          correct: false,
          rejectBn: 'লক্ষ্য 49.90 থেকে 50.05 Hz — কম মানে লোড বেড়ে গেছে, সাপ্লাই কম।',
        ),
        LearnBoardOption(
          id: 'f5020',
          labelBn: 'মিটারে 50.20 Hz',
          asset: 'assets/game/art/m8_board84/freq_high5020.svg',
          scene: true,
          correct: false,
          rejectBn: '50.05 Hz-এর ওপরে — লোড কমে গেছে, ব্যালেন্স নষ্ট হচ্ছে।',
        ),
        LearnBoardOption(
          id: 'f4890',
          labelBn: 'মিটারে 48.90 Hz',
          asset: 'assets/game/art/m8_board84/freq_low4890.svg',
          scene: true,
          correct: false,
          rejectBn: '49.0-এর নিচে নামলে বিপদ আসন্ন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লক্ষ্য 49.90 থেকে 50.05 Hz-এর মধ্যে রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কম ফ্রিকোয়েন্সি মানে লোড বেশি, সাপ্লাই কম', correct: true),
        LearnWhyChip(id: 'w3', textBn: '49.0-এর নিচে নামলে গ্রিড ধসে পড়তে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফ্রিকোয়েন্সি 48 Hz হলেও গ্রিড একদম ঠিক থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মিটারের কাঁটা নড়লেই কোনো সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: '50.20 Hz মানে গ্রিড আরও ভালো চলছে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফ্রিকোয়েন্সি যাই হোক, লাইন নিজে থেকেই ঠিক হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফ্রিকোয়েন্সি দেখে কিছু করার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভোল্টেজ ঠিক থাকলে ফ্রিকোয়েন্সি ভাবতে হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hotline',
      promptBn: 'SLDC-র হটলাইন বাজছে — ঠিক কাজটা কোন ছবিতে?',
      options: [
        LearnBoardOption(
          id: 'lift',
          labelBn: 'লাল হটলাইন তুলেছেন, কালো ফোন অপেক্ষায়',
          asset: 'assets/game/art/m8_board84/hotline_lift.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'feeder',
          labelBn: 'হটলাইন কানে, 11 kV ফিডার OFF করছেন',
          asset: 'assets/game/art/m8_board84/hotline_feeder.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lamp',
          labelBn: 'ফিডারের ল্যাম্প OFF, হটলাইন এখনও হাতে',
          asset: 'assets/game/art/m8_board84/hotline_lamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'chat',
          labelBn: 'কালো ফোনে গল্প করছেন, হটলাইন বাজছে',
          asset: 'assets/game/art/m8_board84/hotline_chat.svg',
          scene: true,
          correct: false,
          rejectBn: 'হটলাইন বা ইমার্জেন্সি ফোনের রিং হলে সবার আগে ধরুন।',
        ),
        LearnBoardOption(
          id: 'argue',
          labelBn: 'হটলাইনে তর্ক, ফিডার ON',
          asset: 'assets/game/art/m8_board84/hotline_argue.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোড শেডিং-এর অর্ডার এলে প্রশ্ন নয় — আগে লাইন কাটুন, গ্রিড সেকেন্ডে ধসে পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'কাপে চা, স্লিপ টেবিলে, ফিডার ON',
          asset: 'assets/game/art/m8_board84/hotline_tea.svg',
          scene: true,
          correct: false,
          rejectBn: 'SLDC থেকে নির্দেশ আসা মাত্রই ফিডার OFF করতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'SLDC-র নির্দেশ এলে প্রশ্ন নয়, আগে ফিডার OFF', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গ্রিড সেকেন্ডে ধসে পড়তে পারে, দেরির সময় নেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হটলাইন বাজলে সবার আগে এখনই ধরতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্রাহকের সঙ্গে ফোনে তর্ক করে বোঝাতে হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চা শেষ করে তারপর ফিডার OFF করা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্লিপ দেখে পরে ফিডার OFF করলেই চলবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কালো ফোনে গল্প করাও কাজেরই একটা অংশ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফিডার ON রাখলে গ্রিড আরও মজবুত থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অর্ডার এলেও আগে কারণটা ভালো করে খুঁজতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'register',
      promptBn: 'আজ সন্ধ্যার লোড শেডিং — কোন খাতার পাতা গ্রিড কোড মানছে?',
      options: [
        LearnBoardOption(
          id: 'rot',
          labelBn: 'খাতা: রোজ আলাদা এলাকায় কালো দাগ',
          asset: 'assets/game/art/m8_board84/register_rot.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'map',
          labelBn: 'খাতা: আজকের এলাকা আগে আলো ছিল',
          asset: 'assets/game/art/m8_board84/register_map.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'same',
          labelBn: 'খাতা: তিন দিন একই এলাকায় কালো দাগ',
          asset: 'assets/game/art/m8_board84/register_same.svg',
          scene: true,
          correct: false,
          rejectBn: 'একই এলাকায় বারবার নয় — ঘুরিয়ে ঘুরিয়ে লোড শেডিং করতে হয়।',
        ),
        LearnBoardOption(
          id: 'village',
          labelBn: 'খাতা: একটা গ্রাম বারবার অন্ধকার',
          asset: 'assets/game/art/m8_board84/register_village.svg',
          scene: true,
          correct: false,
          rejectBn: 'রোটেশনাল লোড শেডিং গ্রাহকের ভোগান্তি কমায় — পালা করে কাটুন।',
        ),
        LearnBoardOption(
          id: 'nocut',
          labelBn: 'খাতা: স্লিপ পিন, কোনো ফিডার কাটা নেই',
          asset: 'assets/game/art/m8_board84/register_nocut.svg',
          scene: true,
          correct: false,
          rejectBn: 'নির্দেশ এলে ফিডার OFF — গ্রিড বাঁচাতে কিছু এলাকা সাময়িক বন্ধ রাখতেই হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একই এলাকায় বারবার নয়, পালা করে লোড শেডিং', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রোটেশনাল লোড শেডিং গ্রাহকের ভোগান্তি কমায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নির্দেশ এলে ফিডার OFF, গ্রিড আগে বাঁচে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একই গ্রাম বারবার কাটলে কারও ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'খাতায় না লিখলেও লোড শেডিং ঠিক থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্লিপ পিন করা থাকলেই কাজ শেষ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফ্রিকোয়েন্সি কমলেও কিছু করতে হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লোড শেডিং শুধু গরমের মাসেই দরকার হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মানচিত্র না দেখলেও এলাকা ঠিক বাছা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bus',
      promptBn: 'বাসবারের ভোল্টমিটার — কোনটা গ্রিড কোডের সীমার মধ্যে?',
      options: [
        LearnBoardOption(
          id: 'b11',
          labelBn: 'বাসবার 11.0 kV, OLTC ট্যাপ পাশেই',
          asset: 'assets/game/art/m8_board84/bus_b11.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'b113',
          labelBn: 'বাসবার 11.3 kV, OLTC ট্যাপ পাশেই',
          asset: 'assets/game/art/m8_board84/bus_b113.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'b32',
          labelBn: 'বাসবার 32.0 kV, OLTC ট্যাপ পাশেই',
          asset: 'assets/game/art/m8_board84/bus_b32.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'b121',
          labelBn: 'বাসবার 12.1 kV, OLTC ট্যাপ পাশেই',
          asset: 'assets/game/art/m8_board84/bus_b121.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভোল্টেজ ঘোষিত মানের চেয়ে 6%-এর বেশি বাড়া চলবে না — হাই ভোল্টেজে ইনসুলেটর বা লাইটনিং অ্যারেস্টার ফেটে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'b99',
          labelBn: 'বাসবার 9.9 kV, OLTC ট্যাপ পাশেই',
          asset: 'assets/game/art/m8_board84/bus_b99.svg',
          scene: true,
          correct: false,
          rejectBn: 'সীমার নিচে — 9%-এর বেশি কমা চলবে না, লো ভোল্টেজে গ্রাহকের পাম্প বা মোটর জ্বলে যেতে পারে। ট্যাপ চেঞ্জার (OLTC) সঠিক পজিশনে আছে কি না দেখুন।',
        ),
        LearnBoardOption(
          id: 'b365',
          labelBn: 'বাসবার 36.5 kV, OLTC ট্যাপ পাশেই',
          asset: 'assets/game/art/m8_board84/bus_b365.svg',
          scene: true,
          correct: false,
          rejectBn: '33 kV বা 11 kV সিস্টেমে ভোল্টেজ 6%-এর বেশি বাড়া বা 9%-এর বেশি কমা চলবে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভোল্টেজ +6% / -9%-এর সীমার মধ্যে রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হাই ভোল্টেজে ইনসুলেটর বা অ্যারেস্টার ফেটে যেতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লো ভোল্টেজে গ্রাহকের পাম্প বা মোটর জ্বলে যেতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভোল্টেজ 12% বাড়লেও কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লো ভোল্টেজে ট্যাপ চেঞ্জার ছুঁয়ে দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভোল্টেজ যত বেশি, গ্রাহক তত খুশি থাকেন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মিটার না দেখেই ভোল্টেজ লিখে দিলেই চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভোল্টেজ সীমার বাইরে গেলেও খাতায় লিখতে হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'উঁচু ভোল্টেজে যন্ত্র নিরাপদ, কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'drawal',
      promptBn: 'ফ্রিকোয়েন্সি বা ভোল্টেজ কম — কোন ছবিতে গ্রিড কোড মানা হচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'ok',
          labelBn: 'টানা ভাগের নিচে, 49.85 Hz',
          asset: 'assets/game/art/m8_board84/drawal_ok.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cap',
          labelBn: 'লো 11 kV, ক্যাপাসিটর ব্যাংক ON',
          asset: 'assets/game/art/m8_board84/drawal_cap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'over',
          labelBn: 'টানা ভাগের ওপরে, 49.80 Hz',
          asset: 'assets/game/art/m8_board84/drawal_over.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফ্রিকোয়েন্সি কম থাকলে ভাগের চেয়ে বেশি টানা নিষেধ — জরিমানা (UI/DSM Charges) গুনতে হয়।',
        ),
        LearnBoardOption(
          id: 'capoff',
          labelBn: 'লো 11 kV, ক্যাপাসিটর ব্যাংক OFF',
          asset: 'assets/game/art/m8_board84/drawal_capoff.svg',
          scene: true,
          correct: false,
          rejectBn: 'লো ভোল্টেজে ক্যাপাসিটর ব্যাংক ON করলে ভোল্টেজ কিছুটা বাড়ে, পাওয়ার ফ্যাক্টর ঠিক থাকে।',
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: 'কর্মী চেঁচাচ্ছেন, 49.90 Hz',
          asset: 'assets/game/art/m8_board84/drawal_shout.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহককে বুঝিয়ে বলুন — এটা লোকাল ফল্ট নয়, ওপর থেকে গ্রিড বাঁচাতে লাইন OFF করা হয়েছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফ্রিকোয়েন্সি বা ভোল্টেজ কম হলে গ্রিড কোড মেনেই চলতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এই নিয়ম মানলে গ্রিড আর গ্রাহক দুজনেই বাঁচে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গ্রিড কোড মানতে এটাই সাহায্য করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফ্রিকোয়েন্সি কম থাকলেও বেশি টানা চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লো ভোল্টেজে ক্যাপাসিটর OFF রাখাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্রাহকের সঙ্গে চেঁচিয়ে তর্ক করলে কাজ হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জরিমানার ভয় না থাকলে টানা বাড়ানো যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ক্যাপাসিটর OFF করলে পাম্প ঠিক চলবে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লোড শেডিংয়ে গ্রাহককে কিছু বলার দরকার নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board84Lines.rivalTaunt,
    rivalLineBn: M8Board84Lines.rivalMyth,
    exitBn: M8Board84Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    flipStingBn: M8Board84Lines.flipSting,
    dangerHints: [
      'গ্রিড ধসে পড়তে পারে',
      'সারা রাজ্য অন্ধকার',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সব সময় নয়, ঝড়ে লাইন বন্ধ হলেও লোড শেডিং হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ফ্রিকোয়েন্সি খুব কমলে গ্রিড বাঁচাতে লোড শেডিং', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লোড শেডিং গ্রিড বাঁচানোর কড়ক দাওয়াই', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লোড শেডিং মানেই কোম্পানি বিদ্যুৎ লুকিয়ে রাখছে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'লোড শেডিং হলে গ্রিড আরও মজবুত হয়ে যায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ফ্রিকোয়েন্সি কমলে ভোল্টেজ নিজেই ঠিক হয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'লোড শেডিং শুধু বিল বাড়ানোর একটা কৌশল', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'একটা ফিডার বন্ধ না করলে কারও কিছু আসে যায় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ঝড় এলে লাইন ট্রিপ করলে কিছু আসে যায় না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M8Board84Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'লোড শেডিং তো রোজকার ব্যাপার, এত নিয়ম-কানুনের কী দরকার?';

  /// Lesson 8.4's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'লোড শেডিং মানেই বিদ্যুতের অভাব বা কোম্পানি বিদ্যুৎ তৈরি করছে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (boards 5.6–5.8): the flipped believe question, which
  /// the runner plays on half of all plays instead of the kit's default.
  static const flipSting = 'এই লোক যা বলছে… সেটা কি ভুল?';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12 / M8-14: the rival's new lines (the taunt is a draft; the
  /// myth is the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack84;
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
