import 'learn_board_models.dart';

/// Module 7 Lesson 7.5 (বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ), the picture
/// board (rung `7.5/learn`, pack `learn_7_5`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board75_art.py` (the only
/// marks drawn are what a worker reads: the OFF tag on the AB handle and a
/// tester's reading, as stroke glyphs). Every round and trap comes from the
/// live lesson text and the Module 7 rulings
/// (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_75.json`). Five rounds (ruling X6):
/// the spec's evidence round left the board (do_7_5_b plays the evidence
/// shot; the far-off photo stays as a safe card of the act round):
///  * legal (section 1, Electricity Act s.135): the lawful supply through a
///    sealed meter, on a bare LT line or an AB cable with its service
///    connector. Traps: a hook, a magnet on the meter, an upstream joint, a
///    loop round the meter with the seal broken;
///  * danger (section 2), asked as "which picture shows the theft wire doing
///    harm right now?": a loose hook sparking over thatch that catches fire,
///    the lane DTR's HG fuse wire blown under the hooks' load and the lane
///    dark (ruling M7-9: an AB switch + HG fuses, no DO). The traps show no
///    harm happening yet, so they are wrong by what they show (labels only
///    appear after a tap): a taped joint, no spark or fire; hooks running and
///    the neighbours' lights on; a cool DTR, every fuse whole. Each trap's
///    reason says "nothing yet — but" and then the lesson's own words;
///  * signs (pro tip 1): few houses, yet the DTR is overloaded or the bulbs
///    burn dim. Traps: many houses and a hot DTR, many or few houses with
///    bright bulbs and a calm DTR;
///  * act (section 3): photograph from a distance; phone the supervisor and
///    vigilance. Traps: arguing at the door, pulling the hook yourself,
///    walking off, a close-up photo while the man glares;
///  * remove (pro tip 4 + ruling M7-8): on the authority's order — the AB
///    open and tagged OFF, the tester at 0, the earth on, gloves on. Traps:
///    the AB still closed (the tester reads 230), no tester, no earth, alone
///    at night with no order.
/// Boards are not scored for deadly (kit design): a deadly-class trap (a
/// live hook, a hand before 0 V, no earth — rows R13, N1, N2) costs the round
/// and teaches with the lesson's words.
/// The rival's myth is the lesson's second myth, word for word (the item
/// spec's mythBn); the first myth's reality is a trap reason in the danger
/// round.
///
/// Reason chips: the runner deals a round's "কেন?" chips whatever safe card
/// was picked, so every right chip is a rule that holds for each safe card of
/// its round.
///
/// DRAFT wording — owner (ruling M6-12 / M7-10): every Bangla line written
/// for this board (prompts, labels, reason chips, the intro, the earned line,
/// the rival's taunt, the danger tags) is a draft for the owner's natural
/// wording; lesson quotes are marked in the test. No YouTube explainer id
/// (ruling M6-14).
const learnBoardPack75 = LearnBoardPack(
  lessonId: '7.5',
  titleBn: 'বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board75Lines.intro,
  earnedBn: M7Board75Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'legal',
      promptBn: 'কোন সংযোগটা বৈধ? মিটার হয়ে আসা ঠিক সংযোগ বাছুন।',
      options: [
        LearnBoardOption(
          id: 'sealed',
          labelBn: 'খুঁটি থেকে সার্ভিস কেবিল, সিল করা মিটার হয়ে ঘরে',
          asset: 'assets/game/art/m7_board75/legal_sealed.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ab',
          labelBn: 'AB কেবিলে সার্ভিস কানেক্টর, সিল করা মিটার হয়ে ঘরে',
          asset: 'assets/game/art/m7_board75/legal_ab.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hook',
          labelBn: 'খোলা LT তারে হুক, সরু তার সোজা জানালা দিয়ে ঘরে',
          asset: 'assets/game/art/m7_board75/legal_hook.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোম্পানির লাইন থেকে অবৈধভাবে হুকিং করে বিদ্যুৎ ব্যবহার করা — ধারা 135 অনুযায়ী এটা বিদ্যুৎ চুরি।',
        ),
        LearnBoardOption(
          id: 'magnet',
          labelBn: 'সিল করা মিটার, কিন্তু মিটারের গায়ে চুম্বক লাগানো',
          asset: 'assets/game/art/m7_board75/legal_magnet.svg',
          scene: true,
          correct: false,
          rejectBn: 'চুম্বক লাগিয়ে মিটারের রিডিং-কে প্রভাবিত করা মানে মিটার ট্যাম্পারিং — এটাও বিদ্যুৎ চুরি।',
        ),
        LearnBoardOption(
          id: 'upstream',
          labelBn: 'মিটারের আগেই সার্ভিস কেবিলে আরেকটা তার জোড়া',
          asset: 'assets/game/art/m7_board75/legal_upstream.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটারের আগে থেকে (Upstream) সংযোগ নিয়ে বিদ্যুৎ ব্যবহার করা — ধারা 135 অনুযায়ী চুরি।',
        ),
        LearnBoardOption(
          id: 'bypass',
          labelBn: 'মিটারের সিল ভাঙা, তার মিটারকে ঘুরে পাশ কাটিয়ে',
          asset: 'assets/game/art/m7_board75/legal_bypass.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটারের সিল ভেঙে মিটারকে বাইপাস করা মানে মিটার ট্যাম্পারিং — এটা বিদ্যুৎ চুরি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সব বিদ্যুৎ সিল করা মিটার হয়ে ঘরে ঢুকছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মিটারের আগে কোথাও অবৈধ জোড়া বা হুক নেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মিটারের সিল অটুট, রিডিং-এ কারচুপি নেই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হুকে নেওয়া বিদ্যুৎ অল্প হলে চুরি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মিটারে চুম্বক রাখা শুধু বিল কমানোর কৌশল', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মিটারের আগে জোড়া দিলে আইনে কিছু বলে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সিল ভাঙা মিটারও চলছে, তাই সেটাও বৈধ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'AB কেবিল থেকে হুক নিলে সেটা চুরি নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'খুঁটি থেকে সোজা তার নিলেই ঝামেলা কম', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'danger',
      promptBn: 'কোন ছবিতে চুরির তারের জন্য এখনই ক্ষতি হচ্ছে? ঠিক ছবি বাছুন।',
      options: [
        LearnBoardOption(
          id: 'fire',
          labelBn: 'ঢিলে হুকে স্পার্ক, নিচের খড়ের চালে আগুন ধরেছে',
          asset: 'assets/game/art/m7_board75/danger_fire.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hg',
          labelBn: 'হুকের বাড়তি লোডে HG ফিউজ তার গলে পাড়া অন্ধকার',
          asset: 'assets/game/art/m7_board75/danger_hg.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tape',
          labelBn: 'হুকের জোড়ে কালো টেপ, এখনও স্পার্ক বা আগুন নেই',
          asset: 'assets/game/art/m7_board75/danger_tape.svg',
          scene: true,
          correct: false,
          // DRAFT wording — owner (first part); then live lesson 7.5
          // section 2, word for word.
          rejectBn: 'এখানে এখনও স্পার্ক বা আগুন নেই। তবে টেপ মুড়লেও তার নিরাপদ হয় না — চুরির জন্য ব্যবহৃত তার বা সরঞ্জামগুলো সাধারণত নিম্নমানের এবং অসুরক্ষিত হয়। এগুলো লুজ কানেকশন, শর্ট সার্কিট এবং আগুন লাগার একটি বড় কারণ।',
        ),
        LearnBoardOption(
          id: 'bright',
          labelBn: 'লাইনে হুক চলছে, পাশের বাড়িগুলোতে আলো জ্বলছে',
          asset: 'assets/game/art/m7_board75/danger_bright.svg',
          scene: true,
          correct: false,
          // DRAFT wording — owner (first part); then live lesson 7.5 myth
          // 1's reality, word for word.
          rejectBn: 'এখন আলো জ্বলছে, ক্ষতি চোখে পড়ছে না। তবে বেশিদিন নয় — এই চুরির কারণে হওয়া ওভারলোডিং এবং ব্রেকডাউনের ফলে সৎ গ্রাহকরাই নিরবচ্ছিন্ন বিদ্যুৎ পরিষেবা থেকে বঞ্চিত হন।',
        ),
        LearnBoardOption(
          id: 'calm',
          labelBn: 'হুকের লোড চলছে, তবু DTR ঠান্ডা, সব ফিউজ অটুট',
          asset: 'assets/game/art/m7_board75/danger_calm.svg',
          scene: true,
          correct: false,
          // DRAFT wording — owner (first part); then live lesson 7.5
          // section 2, word for word.
          rejectBn: 'DTR এখনও ঠান্ডা, ফিউজ অটুট। তবে চাপ জমছে — এই অবৈধ সংযোগগুলো ট্রান্সফরমারের ওপর অতিরিক্ত এবং অজানা লোড চাপায়, যা ওভারলোডিং এবং ব্রেকডাউনের কারণ হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'চুরি শুধু টাকার অপরাধ নয়, সুরক্ষার ঝুঁকিও', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চুরির তারে লুজ কানেকশন আর অজানা বাড়তি লোড', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চোর, লাইনম্যান, সাধারণ মানুষ — সবার বিপদ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টেপ মোড়া থাকলে চুরির তার একদম নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চুরির লোড ট্রান্সফরমার টেরই পায় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চুরিতে ক্ষতি হয় শুধু কোম্পানির টাকার', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হুকের তার মোটা হলে আগুনের ভয় থাকে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আলো জ্বললে বুঝবেন চুরিতে কারও ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'স্পার্ক হওয়া মানে হুকটা ভালো লেগেছে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'signs',
      promptBn: 'কোন এলাকায় বড় চুরির সম্ভাবনা? লক্ষণ মিলিয়ে বাছুন।',
      options: [
        LearnBoardOption(
          id: 'fewhot',
          labelBn: 'মাত্র 2টা বাড়ি, তবু DTR গরম, HG ফিউজ তার গলেছে',
          asset: 'assets/game/art/m7_board75/signs_fewhot.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fewdim',
          labelBn: 'মাত্র 2টা বাড়ি, তবু সন্ধ্যায় সব বাল্ব টিমটিমে',
          asset: 'assets/game/art/m7_board75/signs_fewdim.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'crowdhot',
          labelBn: 'অনেক বাড়ি, DTR গরম, HG ফিউজ তার গলেছে',
          asset: 'assets/game/art/m7_board75/signs_crowdhot.svg',
          scene: true,
          correct: false,
          // DRAFT wording — owner (the lesson gives no numbers for "few").
          rejectBn: 'এখানে গ্রাহকের সংখ্যা লোডের তুলনায় কম নয়, তাই এটা চুরির লক্ষণ নয়। লক্ষণ হলো গ্রাহক কম, অথচ বারবার ওভারলোড।',
        ),
        LearnBoardOption(
          id: 'crowdbright',
          labelBn: 'অনেক বাড়ি, সব বাল্ব উজ্জ্বল, DTR ঠান্ডা',
          asset: 'assets/game/art/m7_board75/signs_crowdbright.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওভারলোড বা লো-ভোল্টেজ কিছুই নেই — বড় চুরির লক্ষণ মেলে না।',
        ),
        LearnBoardOption(
          id: 'fewbright',
          labelBn: 'মাত্র 2টা বাড়ি, বাল্ব উজ্জ্বল, DTR ঠান্ডা',
          asset: 'assets/game/art/m7_board75/signs_fewbright.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহক কম, কিন্তু ওভারলোড বা লো-ভোল্টেজ নেই — লক্ষণ মেলে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'গ্রাহক কম, অথচ লোডের সমস্যা — হিসাব মেলে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গ্রাহকের সংখ্যার সঙ্গে লোড মিলিয়ে দেখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অল্প গ্রাহকে এত চাপ মানে অজানা সংযোগ আছে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাড়ি যত বেশি, চুরির সম্ভাবনা তত বেশি', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাল্ব উজ্জ্বল জ্বললেই সেখানে চুরি চলছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'DTR ঠান্ডা থাকলেই বুঝবেন চুরি হচ্ছে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অনেক বাড়িতে ওভারলোড হলেই সেটা চুরি', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লো-ভোল্টেজ শুধু আবহাওয়ার জন্য হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গ্রাহকের সংখ্যা দেখার কোনো দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'act',
      promptBn: 'চুরির সংযোগ চোখে পড়ল, লোকটা দরজায় দাঁড়িয়ে। আপনি কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'photo',
          labelBn: 'রাস্তার ওপারে দূরে দাঁড়িয়ে হুকটার ছবি তোলা',
          asset: 'assets/game/art/m7_board75/act_photo.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'call',
          labelBn: 'গাড়ির কাছে গিয়ে সুপারভাইজার ও ভিজিল্যান্সকে ফোন',
          asset: 'assets/game/art/m7_board75/act_call.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'argue',
          labelBn: 'দরজায় গিয়ে লোকটার সঙ্গে সরাসরি তর্ক জুড়ে দেওয়া',
          asset: 'assets/game/art/m7_board75/act_argue.svg',
          scene: true,
          correct: false,
          // Live lesson 7.5 section 3, word for word.
          rejectBn: 'বিদ্যুৎ চোরেরা প্রায়ই আক্রমণাত্মক হতে পারে। সরাসরি তাদের সাথে বিবাদে জড়াবেন না।',
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'নিজেই খুঁটিতে উঠে খালি হাতে হুকটা টেনে খোলা',
          asset: 'assets/game/art/m7_board75/act_climb.svg',
          scene: true,
          correct: false,
          // Live lesson 7.5 section 3, word for word.
          rejectBn: 'আইন নিজের হাতে তুলে নেবেন না। শুধুমাত্র কর্তৃপক্ষের নির্দেশে এবং পুলিশি সহায়তায় (যদি প্রয়োজন হয়) অবৈধ সংযোগটি বিচ্ছিন্ন করুন।',
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'ঝামেলা কে করে — ফোনে গল্প করতে করতে চলে যাওয়া',
          asset: 'assets/game/art/m7_board75/act_walk.svg',
          scene: true,
          correct: false,
          // Live lesson 7.5 myth 2's reality, word for word.
          rejectBn: 'বিদ্যুৎ চুরির প্রযুক্তিগত দিকটি শনাক্ত করা এবং রিপোর্ট করার প্রধান দায়িত্ব বিদ্যুৎ কোম্পানির কর্মীদের, যার মধ্যে আপনিও একজন।',
        ),
        LearnBoardOption(
          id: 'close',
          labelBn: 'লোকটা রেগে তাকিয়ে, জানালার নিচে গিয়ে ছবি তোলা',
          asset: 'assets/game/art/m7_board75/act_close.svg',
          scene: true,
          correct: false,
          // Live lesson 7.5 section 3, word for word: the bullet's heading
          // and its evidence line, joined with a dash.
          rejectBn: 'নিজেকে বিপদে ফেলবেন না — যদি নিরাপদে সম্ভব হয়, তবে দূর থেকে অবৈধ সংযোগের ছবি বা ভিডিও তুলুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিজে নিরাপদ থেকে চুরিটা কর্তৃপক্ষকে জানানো', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চোরের সঙ্গে বিবাদ নয়, আগে নিজের সুরক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চুরি শনাক্ত করে জানানো আমাদেরই দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চোরকে হাতেনাতে ধরাই লাইনম্যানের কাজ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হুক নিজে খুলে দিলে রিপোর্টের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চুরি ধরা পুলিশের কাজ, আমাদের কিছু নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাছে গিয়ে ছবি না তুললে প্রমাণ হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লোকটাকে ধমক দিলেই চুরি বন্ধ হয়ে যাবে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'চেনা লোক হলে চুপ করে থাকাই সবচেয়ে ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'remove',
      promptBn: 'কর্তৃপক্ষের নির্দেশ এসেছে। হুক খোলার ঠিক ছবি কোনগুলো?',
      options: [
        LearnBoardOption(
          id: 'safe',
          labelBn: 'AB খোলা, OFF ট্যাগ, টেস্টারে 0, আর্থ দিয়ে, গ্লাভস পরে হুক খোলা',
          asset: 'assets/game/art/m7_board75/remove_safe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'order',
          labelBn: 'অফিসার ও পুলিশ পাশে; টেস্টারে 0, আর্থ দিয়ে হুক খোলা',
          asset: 'assets/game/art/m7_board75/remove_order.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'নির্দেশ আছে, AB লাগানো, টেস্টারে 230 — তবু হুকে হাত',
          asset: 'assets/game/art/m7_board75/remove_live.svg',
          scene: true,
          correct: false,
          // Live lesson 7.5 pro tip 4, word for word (ruling M7-8).
          rejectBn: 'তারগুলো কীভাবে লাগানো আছে তা আপনি জানেন না। কাজটি করার আগে লাইনটি বন্ধ করে টেস্টার দিয়ে ডেড প্রমাণ করা, আর্থ লাগানো এবং সম্পূর্ণ PPE ব্যবহার করা অপরিহার্য।',
        ),
        LearnBoardOption(
          id: 'notest',
          labelBn: 'AB খোলা, OFF ট্যাগ, কিন্তু টেস্টার না লাগিয়েই হুকে হাত',
          asset: 'assets/game/art/m7_board75/remove_notest.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন বন্ধ করলেই হলো না — আগে চালু লাইনে টেস্টার যাচাই, তারপর হুকের লাইনে ডেড প্রমাণ, তবেই হাত।',
        ),
        LearnBoardOption(
          id: 'noearth',
          labelBn: 'AB খোলা, OFF ট্যাগ, টেস্টারে 0, কিন্তু আর্থ মাটিতে পড়ে',
          asset: 'assets/game/art/m7_board75/remove_noearth.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেস্টারে 0 দেখেও আর্থ ছাড়া হুকে হাত নয় — ডেড প্রমাণের পর আর্থ লাগানো অপরিহার্য।',
        ),
        LearnBoardOption(
          id: 'alone',
          labelBn: 'রাতে একা, কোনো নির্দেশ ছাড়াই খুঁটিতে উঠে হুক খোলা',
          asset: 'assets/game/art/m7_board75/remove_alone.svg',
          scene: true,
          correct: false,
          // Live lesson 7.5 section 3, word for word.
          rejectBn: 'শুধুমাত্র কর্তৃপক্ষের নির্দেশে এবং পুলিশি সহায়তায় (যদি প্রয়োজন হয়) অবৈধ সংযোগটি বিচ্ছিন্ন করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইন বন্ধ, ডেড প্রমাণ, আর্থ — তারপর হাত', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চোরের তার কীভাবে লাগানো, আমরা কেউ জানি না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কর্তৃপক্ষের নির্দেশে, পুরো PPE পরে তবেই কাজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্লাভস পরা থাকলে চালু লাইনেও হুক খোলা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'AB খুললেই লাইন ডেড, টেস্টার লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টেস্টারে 0 দেখলে আর্থের আর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নির্দেশের অপেক্ষা না করে নিজেই খুলে ফেলুন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রাতে একা গেলে চোরের সঙ্গে ঝামেলা কম', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হুক তো ছোট জিনিস, টান দিলেই খুলে আসে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board75Lines.rivalTaunt,
    rivalLineBn: M7Board75Lines.rivalMyth,
    exitBn: M7Board75Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board75Lines.sting,
    dangerHints: [
      'চুরি বাড়তেই থাকে',
      'সৎ গ্রাহকের ক্ষতি',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'পুলিশ শুধু আইন-শৃঙ্খলা রক্ষায় সাহায্য করে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'চুরির প্রযুক্তিগত দিক চেনা আমাদের কাজ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আমাদের সচেতনতাই এই অপরাধ কমাতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'চুরি দেখলেও চুপ থাকাই লাইনম্যানের নিয়ম', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'চুরির খবর দেওয়া পুরোপুরি পুলিশের দায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'বিদ্যুৎ চুরি আসলে কোনো অপরাধই নয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'কোম্পানির অনেক টাকা, একটু চুরিতে কী হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'রিপোর্ট করলে শুধু নিজের ঝামেলা বাড়ে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'পুলিশ না এলে লাইনম্যানের কিছু করার নেই', correct: false),
    ],
  ),
);

/// The lines of this board for the owner's wording pass and the voice
/// session. [rivalExit] and [sting] are already recorded (reused); the rest
/// play silent (caption held for reading) or on the on-device fallback until
/// the director records them.
abstract final class M7Board75Lines {
  /// DRAFT wording — owner.
  static const intro = 'বিদ্যুৎ চুরি একটা অপরাধ, আর ভীষণ বিপজ্জনক। চুরি চিনুন, বিপদ বুঝুন, আর নিয়ম মেনে মোকাবিলা করুন।';

  /// DRAFT wording — owner.
  static const earned = 'চুরি দেখলে দূর থেকে ছবি তুলে রিপোর্ট; হুক খোলা শুধু নির্দেশে, লাইন বন্ধ, টেস্টারে ডেড প্রমাণ আর আর্থ দিয়ে।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'চুরি-টুরি দেখে আমাদের কী লাভ? চলো, কাজ সারি!';

  /// Lesson 7.5's second myth, word for word (the item spec's mythBn; not new
  /// text, needs a clip — ruling M7-10).
  static const rivalMyth = 'বিদ্যুৎ চোরকে ধরা আমার কাজ নয়, ওটা পুলিশের কাজ।';

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

  /// Ruling M6-12 / M7-10: every guide line on this board, for the owner's
  /// wording pass and the voice session (lesson quotes in the trap reasons
  /// included, since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the myth's right reasons, the earned
  /// line).
  static List<String> get guideSpoken {
    final p = learnBoardPack75;
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
