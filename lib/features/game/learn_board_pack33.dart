import 'learn_board_models.dart';

/// Module 3 Lesson 3.3 (ক্রস-আর্ম ও ক্ল্যাম্প: লাইনের কঙ্কাল), the picture
/// board (rung `3.3/learn`, pack `learn_3_3`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board33_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * arm: before climbing, look from below — bent, twisted / tilted or rusty;
///    a bent arm cuts the phase clearance; a cross-arm that is not right upsets
///    the balance of the whole line; galvanising keeps rust off;
///  * clamp: a wrap-around clamp on a round PCC pole, a bolted clamp on a rail
///    / H-beam pole; the wrong clamp does not grip and slips; a clamp can slip
///    down the pole (wrong fitting or overload); a rattle in the wind warns;
///  * hold: on disc insulators a tension clamp takes the pull where the line
///    ends or turns a big angle, a suspension clamp hangs it on a straight run
///    and is never made for tension; pins, split-pins and nut-bolts are checked;
///  * bolt: a spring washer against vibration; the right torque (too tight
///    snaps the bolt, too loose stays loose); rust once the zinc layer is gone;
///  * climb: never stand on a rusty (or bent — film) cross-arm or hook the
///    harness to it; before opening hardware, you and your tools are secure.
///    The cards draw a portable earth set on the line (house rule; the lesson
///    does not say it — not put into words here).
/// The rival's myth is the lesson's first myth buster, word for word (the
/// second one — any clamp on any pole — is the clamp round).
const learnBoardPack33 = LearnBoardPack(
  lessonId: '3.3',
  titleBn: 'ক্রস-আর্ম ও ক্ল্যাম্প: লাইনের কঙ্কাল',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'ক্রস-আর্ম লাইনের মজবুত কাঁধ, ক্ল্যাম্প তাকে পোলে ধরে রাখে। চিনে নিন কোনটা সুস্থ।',
  earnedBn: 'নিচ থেকে দেখে ওঠা, পোল বুঝে ক্ল্যাম্প, স্প্রিং ওয়াশারে সঠিক টর্ক — মরিচায় কখনো ভর নয়।',
  slots: [
    LearnBoardSlot(
      id: 'arm',
      promptBn: 'পোলে ওঠার আগে নিচ থেকে দেখছেন — কোন ক্রস-আর্ম ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'pcc',
          labelBn: 'PCC পোলে সোজা, চকচকে ক্রস-আর্ম',
          asset: 'assets/game/art/m3_board33/arm_pcc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rail',
          labelBn: 'রেল পোলে সোজা, চকচকে ক্রস-আর্ম',
          asset: 'assets/game/art/m3_board33/arm_rail.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bent',
          labelBn: 'এক দিকে বেঁকে যাওয়া ক্রস-আর্ম',
          asset: 'assets/game/art/m3_board33/arm_bent.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাঁকা ক্রস-আর্ম ফেজ ক্লিয়ারেন্স কমিয়ে দেয় — অতিরিক্ত লোড বা দুর্ঘটনার চিহ্ন। এর ওপর ভর নয়।',
        ),
        LearnBoardOption(
          id: 'tilt',
          labelBn: 'পোলে হেলে পড়া ক্রস-আর্ম',
          asset: 'assets/game/art/m3_board33/arm_tilt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্রস-আর্ম ঠিকঠাক না থাকলে পুরো লাইনের ভারসাম্য নষ্ট হয় — বেঁকে, মুচড়ে বা হেলে গেছে কিনা নিচ থেকেই দেখুন।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'মরিচা ধরা ক্রস-আর্ম',
          asset: 'assets/game/art/m3_board33/arm_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্যালভানাইজিং নষ্ট হলে মরিচা ধরে, শক্তি কমে যায় — মরিচা ধরা ক্রস-আর্মে কাজ মানে জীবনের ঝুঁকি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ওঠার আগে নিচ থেকে বাঁকা, মোচড়ানো বা হেলা দেখুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বাঁকা ক্রস-আর্ম ফেজ ক্লিয়ারেন্স কমিয়ে দেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গ্যালভানাইজিং স্টিলকে মরিচা থেকে রক্ষা করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ক্রস-আর্ম একটু হেলে থাকলে লাইনের কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাঁকা ক্রস-আর্মে ফেজের দূরত্ব আরও বেড়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মরিচা ধরলেও স্টিলের শক্তি একই রকম থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্রস-আর্ম দেখার কাজ ওঠার পরে করলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ক্রস-আর্মের কাজ শুধু তার ধরে রাখা, আর কিছু নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মরিচা ধরা ক্রস-আর্ম শুধু দেখতে খারাপ লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'clamp',
      promptBn: 'ক্রস-আর্মকে পোলের সাথে জুড়েছে ক্ল্যাম্প — কোন জোড়া ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pcc',
          labelBn: 'গোল PCC পোলে র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/clamp_pcc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rail',
          labelBn: 'রেল পোলে নাট-বল্টুযুক্ত ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/clamp_rail.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wrap_rail',
          labelBn: 'রেল পোলে র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/clamp_wrap_rail.svg',
          scene: true,
          correct: false,
          rejectBn: 'র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প গোল PCC পোলের জন্য — I-সেকশনের রেল পোলে ঠিকমতো গ্রিপ দেবে না, পিছলে যাবে।',
        ),
        LearnBoardOption(
          id: 'bolt_pcc',
          labelBn: 'গোল PCC পোলে রেল পোলের ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/clamp_bolt_pcc.svg',
          scene: true,
          correct: false,
          rejectBn: 'যেকোনো ক্ল্যাম্প যেকোনো পোলে চলে না — গোল PCC পোলে লাগে র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প, নইলে পিছলে যায়।',
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'পোল বরাবর নিচে নেমে আসা ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/clamp_slip.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল ইনস্টলেশন বা অতিরিক্ত লোডে ক্ল্যাম্প পোল বরাবর পিছলে নামে — বাতাসে খটখট শব্দ তার আগাম সংকেত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'গোল PCC পোলে র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রেল বা এইচ-বিম পোলে নাট-বল্টুযুক্ত ক্ল্যাম্প', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল ক্ল্যাম্প ঠিকমতো গ্রিপ দেয় না, পিছলে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো ক্ল্যাম্প যেকোনো পোলে লাগানো যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'র‍্যাপ-অ্যারাউন্ড ক্ল্যাম্প রেল পোলেই সেরা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ক্ল্যাম্প একটু নিচে নামলে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাতাসে খটখট শব্দ হওয়া একেবারে স্বাভাবিক', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ব্রেস থাকলে ক্ল্যাম্প ঢিলা হলেও চলে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পোল যেমনই হোক, ক্ল্যাম্প একই ডিজাইনের', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hold',
      promptBn: 'ডিস্ক ইনসুলেটরের লাইনে — কোন হার্ডওয়্যার ঠিক জায়গায় আছে?',
      options: [
        LearnBoardOption(
          id: 'tension',
          labelBn: 'লাইনের শেষে টেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/hold_tension.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'susp',
          labelBn: 'সোজা লাইনে ঝুলন্ত সাসপেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/hold_susp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'susp_end',
          labelBn: 'লাইনের শেষে সাসপেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/hold_susp_end.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাসপেনশন ক্ল্যাম্প কখনো টেনশন সইতে তৈরি নয় — লাইনের শেষে বা বড় কোণে লাগে টেনশন ক্ল্যাম্প।',
        ),
        LearnBoardOption(
          id: 'pin',
          labelBn: 'স্প্লিট-পিন খুলে পড়া হার্ডওয়্যার',
          asset: 'assets/game/art/m3_board33/hold_pin.svg',
          scene: true,
          correct: false,
          rejectBn: 'পিন, স্প্লিট-পিন আর নাট-বল্টু সুরক্ষিতভাবে লাগানো আছে কিনা — রোজ পরীক্ষা করুন।',
        ),
        LearnBoardOption(
          id: 'nut',
          labelBn: 'নাট আলগা হওয়া সাসপেনশন ক্ল্যাম্প',
          asset: 'assets/game/art/m3_board33/hold_nut.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলা নাট-বল্টু পুরো সিস্টেমকে দুর্বল করে — কম্পনে ধীরে ধীরে আরও আলগা হয়ে যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইনের শেষে বা বড় কোণে টান সয় টেনশন ক্ল্যাম্প', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সোজা লাইনে তার ঝুলিয়ে রাখে সাসপেনশন ক্ল্যাম্প', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পিন, স্প্লিট-পিন আর নাট-বল্টু সুরক্ষিত কিনা দেখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সাসপেনশন ক্ল্যাম্প লাইনের শেষের টানও সইতে পারে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টেনশন আর সাসপেনশন ক্ল্যাম্পের কাজ একই রকম', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্প্লিট-পিন না থাকলেও পিন নিজেই আটকে থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভুল জায়গায় ভুল হার্ডওয়্যার ছোটখাটো ব্যাপার', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সাসপেনশন ক্ল্যাম্প তারকে একটুও দুলতে দেয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বড় কোণে বাঁক নেওয়া লাইনে সাসপেনশনই যথেষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bolt',
      promptBn: 'ক্রস-আর্মের নাট-বল্টু লাগাচ্ছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'washer',
          labelBn: 'নাটের নিচে স্প্রিং ওয়াশার',
          asset: 'assets/game/art/m3_board33/bolt_washer.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'torque',
          labelBn: 'টর্ক রেঞ্চে সঠিক টর্কে টাইট',
          asset: 'assets/game/art/m3_board33/bolt_torque.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'স্প্রিং ওয়াশার ছাড়াই নাট',
          asset: 'assets/game/art/m3_board33/bolt_none.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম্পনে নাট ধীরে ধীরে আলগা হয় — তা ঠেকাতে নাট-বল্টুর সাথে স্প্রিং ওয়াশার মাস্ট।',
        ),
        LearnBoardOption(
          id: 'snap',
          labelBn: 'পাইপ লাগিয়ে অতিরিক্ত টাইট',
          asset: 'assets/game/art/m3_board33/bolt_snap.svg',
          scene: true,
          correct: false,
          rejectBn: 'অতিরিক্ত টাইট দিলে বল্টু ছিঁড়ে যেতে পারে — টাইট দেওয়ার সময় সঠিক টর্ক দিন।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'আধা-টাইট করে ছেড়ে দেওয়া নাট',
          asset: 'assets/game/art/m3_board33/bolt_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম টাইট দিলে নাট আলগা থেকে যায় — একটি ঢিলা নাট-বল্টু আপনার জীবন ঝুঁকিতে ফেলতে পারে।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'মরিচা ধরা নাট-বল্টু',
          asset: 'assets/game/art/m3_board33/bolt_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'জিঙ্কের গ্যালভানাইজিং স্তর ক্ষয়ে গেলে মরিচা ধরে — মরিচা হার্ডওয়্যারের শক্তি কমিয়ে দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্প্রিং ওয়াশার কম্পনে নাট আলগা হওয়া ঠেকায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বেশি টাইটে বল্টু ছেঁড়ে, কম টাইটে আলগা থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নাট-বল্টুর জিঙ্কের স্তর মরিচা আটকে রাখে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যত বেশি টাইট, নাট-বল্টু তত বেশি নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্প্রিং ওয়াশার শুধু বাড়তি খরচ, কাজের নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হালকা মরিচা ধরা বল্টুর শক্তি একই থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হাতে যতটা হয় ততটা টাইট দিলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কম্পনে নাট-বল্টু কখনোই আলগা হয়ে যায় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেকোনো সাইজের বল্টু লাগালেই কাজ চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'climb',
      promptBn: 'পোলে উঠে হার্ডওয়্যার খুলবেন — কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'pcc',
          labelBn: 'PCC পোল ঘিরে হারনেস, যন্ত্র ব্যাগে',
          asset: 'assets/game/art/m3_board33/climb_pcc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rail',
          labelBn: 'রেল পোল ঘিরে হারনেস, যন্ত্র ব্যাগে',
          asset: 'assets/game/art/m3_board33/climb_rail.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rust_stand',
          labelBn: 'মরিচা ধরা ক্রস-আর্মে দাঁড়িয়ে কাজ',
          asset: 'assets/game/art/m3_board33/climb_rust_stand.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা ক্রস-আর্মের ওপর কখনো দাঁড়াবেন না — এতে কাজ করা মানে নিজের জীবনকে ঝুঁকির মুখে ফেলা।',
        ),
        LearnBoardOption(
          id: 'rust_hook',
          labelBn: 'মরিচা ধরা ক্রস-আর্মে হারনেস আটকানো',
          asset: 'assets/game/art/m3_board33/climb_rust_hook.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা ক্রস-আর্মকে অ্যাঙ্কর পয়েন্ট হিসেবে ব্যবহার নয় — মরিচা ভেতর থেকে তার শক্তি শেষ করে।',
        ),
        LearnBoardOption(
          id: 'bent_hook',
          labelBn: 'বাঁকা ক্রস-আর্মে হারনেস আটকানো',
          asset: 'assets/game/art/m3_board33/climb_bent_hook.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা বা বাঁকা ক্রস-আর্মে কখনো দাঁড়াবেন না, হারনেসও আটকাবেন না।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'যন্ত্র ক্রস-আর্মে খোলা রেখে কাজ',
          asset: 'assets/game/art/m3_board33/climb_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোনো হার্ডওয়্যার খোলার আগে নিশ্চিত করুন — আপনি আর আপনার সরঞ্জাম দুটোই সুরক্ষিত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মরিচা ধরা বা বাঁকা ক্রস-আর্মে হারনেস নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'খোলার আগে নিজে আর সরঞ্জাম দুটোই সুরক্ষিত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মরিচা ধরা ক্রস-আর্মের ওপর কখনো দাঁড়াবেন না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ক্রস-আর্ম লোহার, তাই হারনেসের সেরা জায়গা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হালকা মরিচা ধরা ক্রস-আর্মে দাঁড়ানো চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যন্ত্রপাতি ক্রস-আর্মের ওপর রাখাই সুবিধা', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাঁকা ক্রস-আর্মও একজনের ভার সইতে পারে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অল্প সময়ের কাজে হারনেস ছাড়াই চলে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নাট খোলার সময় যন্ত্র পড়লে কিছু হয় না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board33Lines.rivalTaunt,
    rivalLineBn: M3Board33Lines.rivalMyth,
    exitBn: M3Board33Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'হালকা মরিচা অবহেলা',
      'মরিচা ধরা ক্রস-আর্মে ওঠা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মরিচা ক্যান্সারের মতো, ভেতর থেকে শক্তি শেষ করে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'হালকা মরিচাও কখনো অবহেলা করা উচিত নয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'গ্যালভানাইজিং নষ্ট হলেই স্টিলে মরিচা ধরে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'হালকা মরিচা শুধু ওপরের স্তরে, ভেতরে যায় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'মরিচা ধরলেও ক্রস-আর্মের শক্তি কমে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মরিচা ধরা ক্রস-আর্মে দাঁড়ালেও বিপদ নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'মরিচা শুধু দেখতে খারাপ, কাজের ক্ষতি নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অভিজ্ঞ লাইনম্যান মরিচা নিয়ে মাথা ঘামায় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'মরিচা বড় হলে তখন ভাবলেই চলবে, আগে নয়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board33Lines {
  static const rivalTaunt = 'আরে, এ তো হালকা মরিচা! ওপরের দাগ, এর জন্য আবার ভয় কেন?';

  /// Lesson 3.3's first myth buster, word for word.
  static const rivalMyth = 'ক্রস-আর্মে হালকা মরিচা ধরলে কিছু হয় না, ওটা তো শুধু বাইরের স্তরে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
