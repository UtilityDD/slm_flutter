import 'learn_board_models.dart';

/// Module 6 Lesson 6.8 (অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন),
/// the picture board (rung `6.8/learn`, pack `learn_6_8`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board68_art.py` (no words in
/// the art; the only labels are the ones a worker reads on the equipment — the
/// recloser's plate 'R', the sectionalizers' plates 'S-1'…'S-3', ON / OFF and
/// the counter digits — drawn as stroke glyphs with English digits). Every
/// round and trap comes from the live lesson text and the Module 6 rulings
/// (`docs/module_specs/module6_rulings.md`, item spec
/// `docs/module_specs/module6_items/board_68.json`):
///  * temp: a temporary fault (a branch touches and falls clear, wind swings
///    two wires together) — the recloser trips, waits a few seconds and closes
///    again by itself; the line stays on and nobody patrols (point 1 and its
///    importance). Traps: the crew patrolling a dark feeder for a gone fault,
///    lock-out after the first trip, a sectionalizer open after a brief touch;
///  * perm: a permanent fault on one branch — the sectionalizer of that branch
///    opens and, on the recloser's last close, every healthy branch is lit
///    (point 2). Traps: close-trip without end (the lesson's 3-4 tries), a
///    healthy branch cut off, the faulty branch cut off and still all dark;
///  * count: the sectionalizer counts while the recloser is open, stays as it
///    was when the recloser closes, and opens on a dead line just before the
///    lock-out (point 2). It cannot find a fault by itself, never breaks fault
///    current and does not melt (myth 2). The count at which it opens (3) is
///    staged art (spec unsupported: 'counting semantics');
///  * nonrec: before work on a recloser line — PTW with Non-Reclose asked for
///    and confirmed with the control room (safety protocol), the Non-Reclose /
///    Hot Line Tag switch ON (point 3), then tester and earths before the
///    climb (ruling X1; full-body harness, X7). Traps: climbing because the
///    houses went dark, climbing on handle-down with no PTW and no
///    Non-Reclose (myth 1's reality word for word), working with the switch
///    OFF (auto reclose live);
///  * pro: reading the operation counter (pro tip 1), lock-out read from a
///    distance by the hanging handle (point 3), the control box's setting (pro
///    tip 2). Traps: the manual handle pulled on a live line (pro tip 3), lock-
///    out written only because the houses are dark, waiting under a
///    sectionalizer for it to blow like a fuse (myth 2).
/// The rival's myth is the lesson's first myth, word for word (deadly class in
/// the Do levels, R3; boards are not scored for deadly: kit design).
///
/// Term rules (owner, after Wave A): ডেড never মৃত; ON / OFF in English letters;
/// a closed blade is 'লাগানো'; English digits.
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack68 = LearnBoardPack(
  lessonId: '6.8',
  titleBn: 'অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন',
  badgeBn: 'যন্ত্র গুরু',
  introBn: 'রিক্লোজার নিজেই লাইন আবার চালু করে, সেকশনালাইজার ফল্টি শাখা আলাদা করে। এদের চিনে নিরাপদে কাজ শিখুন।',
  earnedBn: 'রিক্লোজারযুক্ত লাইনে PTW-র সময় Non-Reclose চালু ও নিশ্চিত করুন, তবেই কাজ। ঝোলা হ্যান্ডেলে লক-আউট চেনা যায়, তবু PTW আর Non-Reclose ছাড়া ওঠা নয়।',
  slots: [
    LearnBoardSlot(
      id: 'temp',
      promptBn: 'ক্ষণিকের ফল্ট — ডাল ছুঁয়ে সরে গেল বা বাতাসে তার ছুঁল। এরপর কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'trip',
          labelBn: 'ডাল সরে গেল, রিক্লোজার ট্রিপ করে আবার চালু, আলো জ্বলছে',
          asset: 'assets/game/art/m6_board68/temp_trip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wind',
          labelBn: 'বাতাসে তার ছুঁল, একবার ট্রিপ, লাইন চালু, গাড়ি দাঁড়িয়ে',
          asset: 'assets/game/art/m6_board68/temp_wind.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'patrol',
          labelBn: 'সব অন্ধকার, চলে যাওয়া ফল্ট খুঁজতে টর্চ হাতে পেট্রোলিং',
          asset: 'assets/game/art/m6_board68/temp_patrol.svg',
          scene: true,
          correct: false,
          rejectBn: 'অস্থায়ী ফল্টে রিক্লোজার নিজেই লাইন আবার চালু করে — অপ্রয়োজনীয় পেট্রোলিং লাগে না।',
        ),
        LearnBoardOption(
          id: 'lock1',
          labelBn: 'একবার ট্রিপ করেই হ্যান্ডেল নিচে ঝুলছে, সব অন্ধকার',
          asset: 'assets/game/art/m6_board68/temp_lock1.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথম ট্রিপেই লক-আউট নয় — স্থায়ী ফল্টে সাধারণত 3-4 বার চেষ্টার পরে লক-আউট হয়।',
        ),
        LearnBoardOption(
          id: 'sopen',
          labelBn: 'ক্ষণিকের ছোঁয়াতেই S-1 খুলে গেছে, ওই শাখা অন্ধকার',
          asset: 'assets/game/art/m6_board68/temp_sopen.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেকশনালাইজার খোলে রিক্লোজার লক-আউট হওয়ার ঠিক আগে — অস্থায়ী ফল্টে লাইন চালু থাকে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অস্থায়ী ফল্টে রিক্লোজার নিজেই লাইন আবার চালু করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফল্ট সরে গেলে আবার চালু হয়ে লাইন চালুই থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রিক্লোজার অপ্রয়োজনীয় পেট্রোলিং থেকে মুক্তি দেয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'প্রথম ট্রিপেই রিক্লোজার স্থায়ী লক-আউট হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো ছোঁয়াতেই সেকশনালাইজার শাখা কেটে দেয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডাল সরে গেলেও লাইন সারাদিন অন্ধকার থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্রিপ হলেই পুরো লাইন হেঁটে পেট্রোলিং করতে হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রিক্লোজার শুধু ট্রিপ করে, আবার চালু করতে পারে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'perm',
      promptBn: 'একটা শাখায় গাছ পড়েছে — স্থায়ী ফল্ট। শেষে লাইনের কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 's1',
          labelBn: 'গাছ S-1 শাখায়, S-1 খোলা, বাকি দুই শাখায় আলো',
          asset: 'assets/game/art/m6_board68/perm_s1.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 's3',
          labelBn: 'গাছ S-3 শাখায়, শুধু S-3 খোলা, মেইন লাইন চালু',
          asset: 'assets/game/art/m6_board68/perm_s3.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'endless',
          labelBn: 'রিক্লোজার থামছেই না, বারবার চালু-ট্রিপ, আলো দপদপ',
          asset: 'assets/game/art/m6_board68/perm_endless.svg',
          scene: true,
          correct: false,
          rejectBn: 'রিক্লোজার সাধারণত 3-4 বার চেষ্টার পর স্থায়ীভাবে লক-আউট হয়ে যায় — অবিরাম চেষ্টা চালায় না।',
        ),
        LearnBoardOption(
          id: 'wrongs',
          labelBn: 'গাছ S-1 শাখায়, কিন্তু খুলেছে সুস্থ S-3, সব অন্ধকার',
          asset: 'assets/game/art/m6_board68/perm_wrongs.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেকশনালাইজার ফল্টি শাখাটিকেই বাকি সিস্টেম থেকে বিচ্ছিন্ন করে — সুস্থ শাখাকে নয়।',
        ),
        LearnBoardOption(
          id: 'alldark',
          labelBn: 'ফল্টি শাখা S-2 আলাদা হলো, তবু সব শাখা অন্ধকার',
          asset: 'assets/game/art/m6_board68/perm_alldark.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল্টি শাখা বিচ্ছিন্ন হলে রিক্লোজার শেষবার চালু হয় — সুস্থ শাখাগুলো বিদ্যুৎ পায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সেকশনালাইজার শুধু ফল্টি শাখাটিকে আলাদা করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শেষবার চালু হলে সুস্থ শাখাগুলো বিদ্যুৎ পায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রিক্লোজার 3-4 বার চেষ্টার পর লক-আউট হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'স্থায়ী ফল্টে রিক্লোজার অবিরাম চেষ্টা চালায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো একটা শাখা খুললেই ফল্ট মিটে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফল্টি শাখা কাটলেও পুরো লাইন অন্ধকার থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্থায়ী ফল্টে সব সেকশনালাইজার একসাথে খোলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সুস্থ শাখা কেটে দিলেই ফল্টি শাখা সেরে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'count',
      promptBn: 'শাখায় স্থায়ী ফল্ট, সেকশনালাইজার গুনছে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'one',
          labelBn: 'রিক্লোজার OFF, S-1 গুনল 1, ব্লেড লাগানোই আছে',
          asset: 'assets/game/art/m6_board68/count_one.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dead',
          labelBn: 'লাইন ডেড, শেষ চেষ্টার আগে আর্ক ছাড়াই ব্লেড খুলল',
          asset: 'assets/game/art/m6_board68/count_dead.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'arc',
          labelBn: 'ফল্ট কারেন্ট চলছে, বড় আর্ক তুলে ব্লেড খুলছে',
          asset: 'assets/game/art/m6_board68/count_arc.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেকশনালাইজার ফল্ট কারেন্টকে বাধা দেয় না — শুধু লাইন \'ডেড\' থাকলে খোলে।',
        ),
        LearnBoardOption(
          id: 'self',
          labelBn: 'রিক্লোজার ON, গোনা 0, তবু S-1 নিজেই খুলে গেছে',
          asset: 'assets/game/art/m6_board68/count_self.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেকশনালাইজারের নিজের ফল্ট সনাক্ত করার ক্ষমতা নেই — রিক্লোজার খুললে তবেই গোনে।',
        ),
        LearnBoardOption(
          id: 'first',
          labelBn: 'রিক্লোজার OFF, প্রথম গোনাতেই S-1 খুলে গেছে',
          asset: 'assets/game/art/m6_board68/count_first.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথম গোনায় সেকশনালাইজার আগের মতোই থাকে — খোলে রিক্লোজার লক-আউটের ঠিক আগে।',
        ),
        LearnBoardOption(
          id: 'melt',
          labelBn: 'ফিউজের মতো S-1-এর ব্লেড গলে ঝুলছে, ধোঁয়া',
          asset: 'assets/game/art/m6_board68/count_melt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ ফল্ট কারেন্টে গলে যায়; সেকশনালাইজার একটি \'লোড ব্রেক\' সুইচ, গলে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রিক্লোজার খুললে তবেই সেকশনালাইজার গোনে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রিক্লোজার আবার চালু হলে S-1 আগের মতোই থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লক-আউটের ঠিক আগে ডেড লাইনে সেকশনালাইজার খোলে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সেকশনালাইজার নিজেই ফল্ট ধরে লাইন কেটে দেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সেকশনালাইজার ফল্ট কারেন্টের মধ্যেই খুলে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্রথম গোনাতেই সেকশনালাইজার খুলে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফিউজের মতো সেকশনালাইজারও গলে লাইন কাটে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রিক্লোজারের সাথে সেকশনালাইজারের কোনো যোগ নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'nonrec',
      promptBn: 'রিক্লোজারযুক্ত লাইনে কাজ শুরুর আগে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'radio',
          labelBn: 'PTW নেওয়ার সময় রেডিওতে Non-Reclose চাওয়া হচ্ছে',
          asset: 'assets/game/art/m6_board68/nonrec_radio.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'switch',
          labelBn: 'কন্ট্রোল বক্সে Non-Reclose সুইচ ON, Hot Line Tag',
          asset: 'assets/game/art/m6_board68/nonrec_switch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'PTW, Non-Reclose নিশ্চিত, টেস্টারে 0, দুই দিকে আর্থ, ওঠা',
          asset: 'assets/game/art/m6_board68/nonrec_earth.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dark',
          labelBn: 'বাড়ির আলো নিভে গেছে, তাই আর্থ ছাড়াই খুঁটিতে ওঠা',
          asset: 'assets/game/art/m6_board68/nonrec_dark.svg',
          scene: true,
          correct: false,
          rejectBn: 'রিক্লোজার হয়তো চেষ্টার মাঝখানে — কয়েক সেকেন্ড পরেই আবার লাইন চালু করবে।',
        ),
        LearnBoardOption(
          id: 'handle',
          labelBn: 'হ্যান্ডেল নিচে দেখে ওঠা — PTW নেই, Non-Reclose নেই',
          asset: 'assets/game/art/m6_board68/nonrec_handle.svg',
          scene: true,
          correct: false,
          // Lesson 6.8 myth 1's reality, its last sentence word for word.
          rejectBn: '\'Non-Reclose\' মোড নিশ্চিত না করে এবং PTW না নিয়ে কোনো রিক্লোজারযুক্ত লাইনকে নিরাপদ ভাবা যাবে না।',
        ),
        LearnBoardOption(
          id: 'auto',
          labelBn: 'Non-Reclose সুইচ OFF রেখেই খুঁটিতে উঠে কাজ চলছে',
          asset: 'assets/game/art/m6_board68/nonrec_auto.svg',
          scene: true,
          correct: false,
          rejectBn: 'Non-Reclose চালু না থাকলে রিক্লোজার কোনো সতর্কবার্তা ছাড়াই লাইন আবার চালু করতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'PTW-র সময় অপারেটরকে Non-Reclose চালু করতে বলুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'Non-Reclose চালু আর নিশ্চিত করে তবেই কাজ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'টেস্টারে ডেড প্রমাণ, দুই দিকে আর্থ, তারপর ওঠা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আলো নিভে গেলেই লাইন নিরাপদ, উঠে পড়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হ্যান্ডেল নিচে ঝুলে থাকলে আর PTW লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'Non-Reclose শুধু কাগজের নিয়ম, দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিক্লোজার একবার ট্রিপ করলে আর চালু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তাড়াতাড়ি কাজ সারলে Non-Reclose লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pro',
      promptBn: 'রিক্লোজারের সামনে দাঁড়িয়ে — প্রো লাইনম্যান কোনটা করেন?',
      options: [
        LearnBoardOption(
          id: 'counter',
          labelBn: 'রিক্লোজারের অপারেশন কাউন্টার পড়ে খাতায় লেখা',
          asset: 'assets/game/art/m6_board68/pro_counter.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'handle',
          labelBn: 'দূর থেকে দেখা, হ্যান্ডেল নিচে ঝুলছে: লক-আউট',
          asset: 'assets/game/art/m6_board68/pro_handle.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'setting',
          labelBn: 'কন্ট্রোল বক্স খুলে রিক্লোজারের সেটিং পড়া',
          asset: 'assets/game/art/m6_board68/pro_setting.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'manual',
          labelBn: 'লাইন চালু, হুক স্টিকে ম্যানুয়াল হ্যান্ডেল টানা',
          asset: 'assets/game/art/m6_board68/pro_manual.svg',
          scene: true,
          correct: false,
          rejectBn: 'ম্যানুয়াল হ্যান্ডেল দিয়ে খোলা বা লাগানো অবশ্যই \'ডেড\' লাইনে করতে হবে।',
        ),
        LearnBoardOption(
          id: 'deadonly',
          labelBn: 'হ্যান্ডেল ওপরে, আলো নেই দেখেই "লক-আউট" লেখা',
          asset: 'assets/game/art/m6_board68/pro_deadonly.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু আলো নেই দেখে লক-আউট ধরা যায় না — লক-আউটে হ্যান্ডেল সাধারণত নিচে ঝোলে।',
        ),
        LearnBoardOption(
          id: 'wait',
          labelBn: 'সেকশনালাইজারের নিচে দাঁড়িয়ে উড়ে যাওয়ার অপেক্ষা',
          asset: 'assets/game/art/m6_board68/pro_wait.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেকশনালাইজার ফল্ট ব্রেকিং ডিভাইস নয় — শুধু \'ডেড\' লাইনে খোলে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাউন্টার বলে সম্প্রতি লাইনে কতগুলো ফল্ট হয়েছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লক-আউটে হ্যান্ডেল নিচে ঝোলে, দূর থেকে বোঝা যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কন্ট্রোল বক্সে লেখা কতবার চেষ্টা, কতক্ষণ অপেক্ষা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ম্যানুয়াল হ্যান্ডেলে খোলা-লাগানো শুধু ডেড লাইনে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'চালু লাইনেও ম্যানুয়াল হ্যান্ডেল টেনে খোলা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আলো না থাকলেই রিক্লোজার লক-আউট হয়েছে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সেকশনালাইজার ফিউজের মতো ফল্টে উড়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাউন্টার দেখে কিছুই বোঝা যায় না, শুধু সাজানো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সেটিং জানার দরকার নেই, ওটা অফিসের ব্যাপার', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board68Lines.rivalTaunt,
    rivalLineBn: M6Board68Lines.rivalMyth,
    exitBn: M6Board68Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // DRAFT wording — owner. Shown, not spoken.
    dangerHints: [
      'লাইন হঠাৎ আবার চালু',
      'খুঁটির ওপরে শক',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'রিক্লোজার হয়তো চেষ্টার মাঝখানে, আবার চালু করবে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'Non-Reclose নিশ্চিত আর PTW ছাড়া লাইন নিরাপদ নয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ট্রিপ মানেই লক-আউট নয়, লাইন আবার চালু হতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লাইন ট্রিপ করে থাকলে আর কখনো চালু হয় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ট্রিপ মানেই লক-আউট, তাই ভয়ের কিছু নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'আলো নিভে গেলে লাইন সবসময়ই নিরাপদ থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'রিক্লোজার কখনো একবারের বেশি চেষ্টা করে না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'Non-Reclose শুধু বড় লাইনের জন্য দরকার', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ট্রিপের পর লাইন নিজে থেকে চালু হতে পারে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M6Board68Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'বাড়িগুলোর আলো তো নিভে গেছে! এত নিয়মের কী দরকার?';

  /// Lesson 6.8's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'লাইনটা তো ট্রিপ করে আছে, রিক্লোজার নিশ্চয়ই লক-আউট হয়ে গেছে। কাজ করতে কোনো ভয় নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Same list under the Module 6 name (ruling M6-12).
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen), the myth's right chips and the closing line. The sting is
  /// already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack68;
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
