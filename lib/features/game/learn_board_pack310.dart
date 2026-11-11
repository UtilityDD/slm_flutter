import 'learn_board_models.dart';

/// Module 3 Lesson 3.10 (লাইন ডায়াগ্রাম পড়া: কাগজের ওপর জাদুর নকশা), the
/// picture board (rung `3.10/learn`, pack `learn_3_10`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board310_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * one: a single line diagram (SLD) shows the three wires (R, Y, B) of a
///    three-phase system as one line — in the field that line is three wires;
///  * tx: the symbols are the SLD's alphabet — the transformer is two coils
///    that do not touch; the circuit breaker a small box; the isolator / AB
///    switch a broken line on a straight line; the lightning arrester an
///    arrow-head on a box going to earth; earthing a few parallel lines;
///  * iso: the isolator's symbol, and the difference from the breaker — an
///    isolator is never opened on load; the DO fuse is a fuse symbol with an
///    arrow-like mark; a plain straight line is just the line;
///  * ring: on a ring / interconnected feeder power may come from the other
///    side too; before work, mark the work area and the isolation points on
///    the diagram (the cards circle both ends of the work section — inferred
///    from "power may come from the opposite side"; flagged in REGISTER.md);
///  * field: an old diagram may not match the field (a new line not on it) —
///    always match the diagram with the field; mark the work area and the
///    isolation points before starting; memory can be wrong.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack310 = LearnBoardPack(
  lessonId: '3.10',
  titleBn: 'লাইন ডায়াগ্রাম পড়া: কাগজের ওপর জাদুর নকশা',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'SLD হলো পুরো নেটওয়ার্কের রোডম্যাপ। প্রতীক চিনুন, ম্যাপ দেখে কাজ করুন।',
  earnedBn: 'একটি লাইন মানে তিন ফেজ; প্রতীক চিনে, মাঠের সাথে মিলিয়ে, আইসোলেশন পয়েন্ট চিহ্নিত করে তবে কাজ।',
  slots: [
    LearnBoardSlot(
      id: 'one',
      promptBn: 'ডায়াগ্রামের এই একটিমাত্র লাইন — মাঠে আসলে সেটা কী?',
      options: [
        LearnBoardOption(
          id: 'three',
          labelBn: 'ক্রসআর্মে তিনটে তার',
          asset: 'assets/game/art/m3_board310/one_three.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cable3',
          labelBn: 'তিন কোরের কেবিল',
          asset: 'assets/game/art/m3_board310/one_cable3.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'single',
          labelBn: 'পোলে একটিমাত্র তার',
          asset: 'assets/game/art/m3_board310/one_single.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটি লাইন মানে একটি তার নয় — নকশা পরিষ্কার রাখতে R, Y, B তিনটি ফেজকেই একটি লাইনে দেখানো হয়।',
        ),
        LearnBoardOption(
          id: 'two',
          labelBn: 'পোলে দুটো তার',
          asset: 'assets/game/art/m3_board310/one_two.svg',
          scene: true,
          correct: false,
          rejectBn: 'থ্রি-ফেজের তিনটে তারকে আলাদা না দেখিয়ে একটি লাইনে আঁকা হয় — মাঠে তিনটে ফেজই আছে।',
        ),
        LearnBoardOption(
          id: 'core',
          labelBn: 'এক কোরের কেবিল',
          asset: 'assets/game/art/m3_board310/one_core.svg',
          scene: true,
          correct: false,
          rejectBn: 'SLD সরলীকৃত ছবি — একটি লাইন দিয়ে আসলে তিনটি ফেজকেই বোঝানো হয়, একটি তার নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একটি লাইনেই R, Y, B তিন ফেজ বোঝানো হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নকশা পরিষ্কার রাখতে তিন তার এক লাইনে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'SLD হলো সার্কিটের সরলীকৃত গ্রাফিকাল ছবি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ডায়াগ্রামে একটি লাইন মানে মাঠেও একটি তার', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাকি দুটো তার ডায়াগ্রামে ভুলে বাদ পড়েছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'SLD শুধু সিঙ্গেল-ফেজ লাইনের জন্য আঁকা হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটি লাইন মানে শুধু R ফেজের একটি তার', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'থ্রি-ফেজ লাইন SLD-তে দেখানোই যায় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যত তার, ডায়াগ্রামে ঠিক ততগুলো লাইন', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tx',
      promptBn: 'ডায়াগ্রামে ট্রান্সফরমার খুঁজছেন — কোন প্রতীকটা?',
      options: [
        LearnBoardOption(
          id: 'coils',
          labelBn: 'না-ছোঁয়া দুটি কুণ্ডলী',
          asset: 'assets/game/art/m3_board310/tx_coils.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'coils_turned',
          labelBn: 'আড়াআড়ি লাইনে দুটি কুণ্ডলী',
          asset: 'assets/game/art/m3_board310/tx_coils_turned.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'box',
          labelBn: 'লাইনের ওপর ছোট বক্স',
          asset: 'assets/game/art/m3_board310/tx_box.svg',
          scene: true,
          correct: false,
          rejectBn: 'চারকোনা ছোট বক্স হলো সার্কিট ব্রেকার। ট্রান্সফরমার মানে দুটি কুণ্ডলী, যারা একে অপরকে ছোঁয় না।',
        ),
        LearnBoardOption(
          id: 'break',
          labelBn: 'সরলরেখায় ভাঙা লাইন',
          asset: 'assets/game/art/m3_board310/tx_break.svg',
          scene: true,
          correct: false,
          rejectBn: 'সরলরেখার ওপর ভাঙা লাইন হলো আইসোলেটর বা AB সুইচ — ট্রান্সফরমার নয়।',
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'কয়েকটি সমান্তরাল দাগ',
          asset: 'assets/game/art/m3_board310/tx_earth.svg',
          scene: true,
          correct: false,
          rejectBn: 'কয়েকটি সমান্তরাল ছোট-বড় লাইন মানে আর্থিং। ট্রান্সফরমার হলো দুটি না-ছোঁয়া কুণ্ডলী।',
        ),
        LearnBoardOption(
          id: 'arrester',
          labelBn: 'বক্সে তীরের মাথা, নিচে মাটি',
          asset: 'assets/game/art/m3_board310/tx_arrester.svg',
          scene: true,
          correct: false,
          rejectBn: 'বক্সের সাথে অ্যারো-হেড, মাটিতে যাচ্ছে — এটা লাইটনিং অ্যারেস্টার, ট্রান্সফরমার নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ট্রান্সফরমার মানে না-ছোঁয়া দুটি কুণ্ডলী', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্রতীকগুলোই হলো SLD পড়ার বর্ণমালা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চারকোনা ছোট বক্স মানে সার্কিট ব্রেকার', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ট্রান্সফরমার মানে লাইনের ওপর ছোট বক্স', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সমান্তরাল দাগগুলো ট্রান্সফরমার বোঝায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্রতীক না চিনেও ডায়াগ্রাম পড়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দুটি কুণ্ডলী জোড়া লাগলে তবে ট্রান্সফরমার', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তীরের মাথা আঁকা বক্সই হলো ট্রান্সফরমার', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যন্ত্রের প্রতীক যে-কেউ নিজের মতো আঁকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'iso',
      promptBn: 'আইসোলেটর বা AB সুইচ — ডায়াগ্রামে কোন প্রতীকটা?',
      options: [
        LearnBoardOption(
          id: 'break',
          labelBn: 'সরলরেখায় ভাঙা লাইন',
          asset: 'assets/game/art/m3_board310/iso_break.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'break_turned',
          labelBn: 'আড়াআড়ি লাইনে ভাঙা অংশ',
          asset: 'assets/game/art/m3_board310/iso_break_turned.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'box',
          labelBn: 'লাইনের ওপর ছোট বক্স',
          asset: 'assets/game/art/m3_board310/iso_box.svg',
          scene: true,
          correct: false,
          rejectBn: 'চারকোনা বক্স হলো সার্কিট ব্রেকার। আইসোলেটর অন-লোডে খোলা যায় না — তাই দুটোর পার্থক্য চেনা জরুরি।',
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'ফিউজের পাশে তীরের দাগ',
          asset: 'assets/game/art/m3_board310/iso_fuse.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজের সাধারণ প্রতীকের সাথে তীরের মতো চিহ্ন মানে ডিও ফিউজ — আইসোলেটর নয়।',
        ),
        LearnBoardOption(
          id: 'coils',
          labelBn: 'না-ছোঁয়া দুটি কুণ্ডলী',
          asset: 'assets/game/art/m3_board310/iso_coils.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুটি না-ছোঁয়া কুণ্ডলী হলো ট্রান্সফরমার। আইসোলেটর মানে সরলরেখার ওপর ভাঙা লাইন।',
        ),
        LearnBoardOption(
          id: 'line',
          labelBn: 'শুধু একটা সরলরেখা',
          asset: 'assets/game/art/m3_board310/iso_line.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু সরলরেখা মানে লাইন। আইসোলেটরের প্রতীকে সরলরেখার ওপর একটি ভাঙা লাইন থাকে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আইসোলেটর কখনো অন-লোডে খোলা যায় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আইসোলেটর আর ব্রেকারের পার্থক্য জরুরি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সরলরেখার ওপর ভাঙা লাইন মানে AB সুইচ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আইসোলেটর আর ব্রেকার একই জিনিস, একই কাজ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লোড চলার সময়ও AB সুইচ খুলে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাইনের ছোট বক্সটাই আইসোলেটরের প্রতীক', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ডিও ফিউজ আর আইসোলেটরের প্রতীক একই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শুধু সরলরেখা মানে সেখানে সুইচ আছে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'প্রতীক গুলিয়ে গেলেও কাজে বিপদ হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ring',
      promptBn: 'রিং ফিডারের এক অংশে কাজ — ডায়াগ্রামে কোন চিহ্ন দেওয়া ঠিক?',
      options: [
        LearnBoardOption(
          id: 'bottom',
          labelBn: 'কাজের অংশের দুই পাশের সুইচ চিহ্নিত',
          asset: 'assets/game/art/m3_board310/ring_bottom.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'left',
          labelBn: 'পাশের অংশের দুই প্রান্তে চিহ্ন',
          asset: 'assets/game/art/m3_board310/ring_left.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one_left',
          labelBn: 'শুধু এক পাশের সুইচ চিহ্নিত',
          asset: 'assets/game/art/m3_board310/ring_one_left.svg',
          scene: true,
          correct: false,
          rejectBn: 'রিং ফিডারে বিদ্যুৎ উল্টো দিক থেকেও আসতে পারে — শুধু এক পাশ ধরলে অন্য পাশ থেকে ব্যাকফিড।',
        ),
        LearnBoardOption(
          id: 'one_side',
          labelBn: 'নিচের সুইচটাই শুধু চিহ্নিত',
          asset: 'assets/game/art/m3_board310/ring_one_side.svg',
          scene: true,
          correct: false,
          rejectBn: 'আপনি যা ভাবছেন, বিদ্যুৎ তার উল্টো দিক থেকেও আসতে পারে — ডায়াগ্রাম পুরো চিত্রটা দেখায়।',
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'কোনো সুইচেই চিহ্ন নেই',
          asset: 'assets/game/art/m3_board310/ring_none.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শুরুর আগে ডায়াগ্রাম দেখে কাজের এলাকা আর আইসোলেশন পয়েন্টগুলো চিহ্নিত করুন।',
        ),
        LearnBoardOption(
          id: 'far',
          labelBn: 'দূরের অন্য অংশের সুইচ চিহ্নিত',
          asset: 'assets/game/art/m3_board310/ring_far.svg',
          scene: true,
          correct: false,
          rejectBn: 'দূরের সুইচ নয় — নিজের কাজের এলাকার আইসোলেশন পয়েন্টগুলোই ডায়াগ্রামে খুঁজে চিহ্নিত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রিং ফিডারে উল্টো দিক থেকেও ব্যাকফিড হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের আগে আইসোলেশন পয়েন্টগুলো চিহ্নিত করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ব্যাকফিড মুখস্থে নয়, ডায়াগ্রামেই ধরা পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রিং ফিডারে বিদ্যুৎ সবসময় একদিক থেকেই আসে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'এক পাশের সুইচ খুললেই পুরো রিং ডেড হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আইসোলেশন পয়েন্ট মাঠে গিয়ে আন্দাজ করলেই হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'যেকোনো দূরের সুইচ খুললেই কাজের অংশ নিরাপদ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রিং ফিডারের ডায়াগ্রাম দেখার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্যাকফিড শুধু বইয়ের কথা, মাঠে হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'field',
      promptBn: 'পুরনো ডায়াগ্রাম হাতে মাঠে এলেন, পাশে নতুন একটা লাইন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'compare',
          labelBn: 'ডায়াগ্রাম মাঠের লাইনের সাথে মেলানো',
          asset: 'assets/game/art/m3_board310/field_compare.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mark',
          labelBn: 'গাড়িতে ডায়াগ্রাম খুলে চিহ্ন দেওয়া',
          asset: 'assets/game/art/m3_board310/field_mark.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'memory',
          labelBn: 'ডায়াগ্রাম ফেলে স্মৃতিতে ভরসা',
          asset: 'assets/game/art/m3_board310/field_memory.svg',
          scene: true,
          correct: false,
          rejectBn: 'মানুষের স্মৃতি ভুল করতে পারে, কিন্তু একটি আপ-টু-ডেট ডায়াগ্রাম ভুল করে না।',
        ),
        LearnBoardOption(
          id: 'ladder',
          labelBn: 'ডায়াগ্রাম না দেখেই মই লাগানো',
          asset: 'assets/game/art/m3_board310/field_ladder.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শুরুর আগে ডায়াগ্রাম দেখে কাজের এলাকা আর আইসোলেশন পয়েন্ট চিহ্নিত করুন — না দেখলে বড় দুর্ঘটনা।',
        ),
        LearnBoardOption(
          id: 'trust',
          labelBn: 'শুধু কাগজ দেখা, লাইনে পিঠ',
          asset: 'assets/game/art/m3_board310/field_trust.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো ডায়াগ্রামে নতুন টানা লাইন না-ও থাকতে পারে — ডায়াগ্রামকে সবসময় মাঠের লাইনের সাথে মিলিয়ে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পুরনো ডায়াগ্রাম মাঠের লাইনের সাথে মিলিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের এলাকার SLD-র কপি গাড়িতে রাখা উচিত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নতুন টানা লাইন পুরনো ডায়াগ্রামে না-ও থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পুরনো ডায়াগ্রাম সবসময় মাঠের সাথে হুবহু মেলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চেনা এলাকায় ডায়াগ্রাম অফিসে রেখে আসাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডায়াগ্রামে যা নেই, মাঠেও তা থাকতে পারে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন লাইন দেখলে ডায়াগ্রাম না দেখেই কাজ শুরু', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্মৃতি কখনো ভুল করে না, কাগজ দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মাঠে এসে আর ডায়াগ্রাম খোলার কোনো মানে নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board310Lines.rivalTaunt,
    rivalLineBn: M3Board310Lines.rivalMyth,
    exitBn: M3Board310Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ডায়াগ্রাম ছাড়া স্মৃতিতে কাজ',
      'রিং ফিডারে উল্টো দিকের ব্যাকফিড',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মানুষের স্মৃতি ভুল করে, আপ-টু-ডেট ডায়াগ্রাম করে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'রিং ফিডারে বিদ্যুৎ উল্টো দিক থেকেও আসতে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ডায়াগ্রাম পুরো নেটওয়ার্কের সম্পূর্ণ চিত্রটা দেখায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'এলাকা হাতের তালুর মতো চিনলে ডায়াগ্রাম লাগে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'অভিজ্ঞ লাইনম্যানের স্মৃতি কখনো ভুল করে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'রিং ফিডারেও বিদ্যুৎ সবসময় এক দিক থেকেই আসে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ডায়াগ্রাম শুধু ইঞ্জিনিয়ারদের জন্য, লাইনম্যানের নয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'চেনা এলাকায় নতুন লাইন টানা হলে নিজেই টের পাবেন', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ডায়াগ্রাম দেখতে গেলে শুধু সময়ই নষ্ট হয়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board310Lines {
  static const rivalTaunt = 'আরে, ম্যাপ খুলে বসে আছেন কেন? চলুন, কাজে লাগি!';

  /// Lesson 3.10's first myth buster, word for word.
  static const rivalMyth = 'আমি তো এই এলাকা হাতের তালুর মতো চিনি, আমার আবার ডায়াগ্রাম দেখার কী দরকার!';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
