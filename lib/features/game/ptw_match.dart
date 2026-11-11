import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'pole_yard.dart';
import 'ptw_site.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 1.6, কাজ 1: "কাগজ মেলাও". Four jobs along a village road. Three
// times a permit-to-work arrives on a clipboard: hold it up beside the pole
// (drag it), put the lens on each field and compare it with the site — the
// feeder tag and the number plate on the pole, the team on your ID card (pro
// tip 3: a permit is issued in a person's or a team's name), the phone's clock
// and date (today's date on the device, so it never goes stale) and the
// signature. If everything matches, start; if not, stop on the field that does
// not match (lesson 1.6: a written permit for a named person, place, time and
// job; match the feeder name to the site; a permit expires).
// Once there is no paper at all: the phone rings — "লাইন বন্ধ, কাজ শুরু করো —
// কাগজ পরে পাঠাচ্ছি" — and the careless coworker (his recorded voice) pushes
// to start on the phone's word; the guide puts the choice on three cards.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" (the reasons fit what this
// permit had) → the next job by itself; the coworker once a play, on the
// dealt phone round.
//
// Deadly (owner-approved list): starting on the phone's word (listening to
// him); starting on a permit for another feeder; starting on an unsigned or
// an expired permit (lesson 1.6: "হাতে স্বাক্ষরিত PTW ছাড়া কাজ শুরু করবেন না").
// Slips: starting on a permit with the wrong pole range or another team's
// name (the play moves on); stopping on a field that matches — on a valid
// permit or on the wrong field of a faulty one — is a slip and the permit is
// still to judge (the rule pattern approved for the pole levels, 2026-11-08).
// Three slips strike the level out.
//
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Art: the site is drawn in code (ptw_site.dart over the pole levels'
// roadside); the mistake pictures are in assets/game/art/ptw/.

// ============================================================================
// Content
// ============================================================================

enum PtwField { number, feeder, place, job, name, date, time, signature }

/// The fields the lens compares with the site (the permit number and the
/// job have nothing on the site to compare with).
const ptwLensFields = [PtwField.feeder, PtwField.place, PtwField.name, PtwField.date, PtwField.time, PtwField.signature];

enum PtwFault { none, feeder, place, name, expiredDate, expiredTime, unsigned }

extension PtwFaultField on PtwFault {
  PtwField? get field => switch (this) {
        PtwFault.none => null,
        PtwFault.feeder => PtwField.feeder,
        PtwFault.place => PtwField.place,
        PtwFault.name => PtwField.name,
        PtwFault.expiredDate => PtwField.date,
        PtwFault.expiredTime => PtwField.time,
        PtwFault.unsigned => PtwField.signature,
      };
}

@immutable
class PtwSite {
  const PtwSite({required this.feederBn, required this.pole, required this.nameBn, required this.teamBn, required this.today, required this.nowBn});
  final String feederBn;
  final int pole;

  /// The trainee's own name (on his ID card).
  final String nameBn;

  /// His team (on his ID card): the name his team's permit is issued in.
  final String teamBn;
  final DateTime today;
  final String nowBn;
}

@immutable
class PtwForm {
  const PtwForm({
    required this.numberBn,
    required this.feederBn,
    required this.placeBn,
    required this.jobBn,
    required this.nameBn,
    required this.dateBn,
    required this.timeBn,
    required this.signed,
    required this.fault,
  });
  final String numberBn;
  final String feederBn;
  final String placeBn;
  final String jobBn;
  final String nameBn;
  final String dateBn;
  final String timeBn;
  final bool signed;
  final PtwFault fault;

  String valueOf(PtwField f) => switch (f) {
        PtwField.number => numberBn,
        PtwField.feeder => feederBn,
        PtwField.place => placeBn,
        PtwField.job => jobBn,
        PtwField.name => nameBn,
        PtwField.date => dateBn,
        PtwField.time => timeBn,
        PtwField.signature => '',
      };
}

@immutable
class PtwRound {
  const PtwRound({required this.site, this.form});
  final PtwSite site;

  /// Null: no paper, only the phone call.
  final PtwForm? form;
  bool get phone => form == null;
}

abstract final class PtwLines {
  static const title = 'কাগজ মেলাও';
  static const intro = 'সাইটে পারমিট এসেছে! প্রতিটা ঘর পোলের সঙ্গে মেলান — ভুল কাগজে লাইনে হাত নয়!';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];

  // The next task only (the corner guide; a tap says it another way).
  static const taskLift = 'পারমিটটা টেনে এনে পোলের পাশে তুলে ধরুন।';
  static const ask = 'পারমিটের প্রতিটা ঘর সাইটের সঙ্গে মেলান। কাজ শুরু করবেন?';
  static const taskLens = 'পারমিটে যা লেখা, সাইটে কি ঠিক তা-ই?';
  static const taskPhone = 'ফোন বাজছে — ধরুন।';
  static const taskCall = 'কন্ট্রোল রুম ফোনে কী বলল, পড়ে দেখুন।';
  static const tasks = [taskLift, ask, taskLens, taskPhone, taskCall];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The permit sheet (what is printed on it).
  static const formTitle = 'পারমিট-টু-ওয়ার্ক (PTW)';
  static const labels = {
    PtwField.number: 'পারমিট নং',
    PtwField.feeder: 'ফিডার',
    PtwField.place: 'স্থান',
    PtwField.job: 'কাজ',
    PtwField.name: 'কার নামে',
    PtwField.date: 'তারিখ',
    PtwField.time: 'সময়',
    PtwField.signature: 'স্বাক্ষর',
  };
  static const noSign = '— (ফাঁকা)';
  static const mismatch = 'মেলে না';
  static const stampValid = 'বৈধ';
  static const stampStop = 'কাজ বন্ধ';

  // The scene and the lens.
  static const sheetLabel = 'পারমিট';
  static const phoneLabel = 'ফোন';
  static const lensLabel = 'লেন্স';
  static const lensClose = 'বন্ধ';
  static const onPaper = 'পারমিটে';
  static const onSite = 'সাইটে';
  static const matchOk = 'মিলেছে';
  static const stop = 'মেলে না — বন্ধ';
  static const start = 'সব মিলেছে — কাজ শুরু';
  static const idTitle = 'পরিচয়পত্র';
  static const idName = 'নাম';
  static const idTeam = 'টিম';
  static const phoneWho = 'কন্ট্রোল রুম';
  static const phoneLine = 'লাইন বন্ধ করে দিয়েছি, তোমরা কাজ শুরু করো — কাগজ পরে পাঠাচ্ছি।';

  // The success beat: "কেন …?" — the right reasons fit what this permit had.
  static const whyStart = 'কেন কাজ শুরু করলেন?';
  static const whyStop = 'কেন কাজ থামালেন?';
  static const whyPhone = 'কেন কাজ শুরু করলেন না?';
  static const whyValid = ['ফিডার, পোল, টিম, সময়, স্বাক্ষর — সব মিলেছে', 'প্রতিটি ঘর সাইটের সঙ্গে মিলিয়ে পড়ে দেখেছি'];
  static const whyFeeder = ['পারমিটের ফিডার আর পোলের ট্যাগ আলাদা', 'অন্য ফিডার বন্ধ, এই লাইন চালু থাকতে পারে'];
  static const whyPlace = ['পারমিটের পোল নম্বর এই পোলের সঙ্গে মেলে না', 'পারমিট অন্য জায়গার, এই পোল তাতে পড়ে না'];
  static const whyName = ['পারমিট অন্য টিমের নামে, আমাদের নামে নয়', 'যে টিমের নামে পারমিট, আমরা সেই টিম নই'];
  static const whyExpired = ['পারমিটের মেয়াদ পেরিয়ে গেছে, নতুন লাগবে', 'সময় পেরোলে কাজ বন্ধ করে নতুন পারমিট নিই'];
  static const whyUnsigned = ['স্বাক্ষরের ঘর ফাঁকা, এটা বৈধ পারমিট নয়', 'স্বাক্ষর ছাড়া কাগজ কোনো বৈধ পারমিট নয়'];
  static const whyVerbal = ['ফোনের কথা পারমিট নয়, লিখিত কাগজ চাই', 'হাতে স্বাক্ষরিত পারমিট ছাড়া কাজ শুরু নয়'];

  /// Wrong reasons to start a valid permit: the lesson's myths and field excuses.
  static const mythsStart = [
    'সুপারভাইজার পারমিট নিয়েছেন, আমার ভাবনা নেই',
    'পারমিট হাতে মানেই লাইন পুরোপুরি নিরাপদ',
    'কন্ট্রোল রুম ফোনে বলেছে লাইন বন্ধ আছে',
    'কাগজে একটা পারমিট নম্বর তো লেখা আছেই',
    'সবাই তো পারমিট না পড়েই কাজে নেমে পড়ে',
  ];

  /// Wrong reasons not to start on the phone's word: field excuses that miss
  /// the rule (each would make the phone's word enough once it is out of the
  /// way). The paper faults are no reason here: there is no paper at all.
  static const phoneExcuses = [
    'ফোনের লাইনে কথাটা ঠিকমতো শোনা যায়নি',
    'যে ফোন করেছে, তার গলাটা আমি চিনি না',
    'আকাশ মেঘলা, বৃষ্টি নামলে কাজটা কঠিন হবে',
    'টিমের সবাই এখনও সাইটে এসে পৌঁছায়নি',
    'গাড়ি থেকে যন্ত্রপাতি এখনও নামানো হয়নি',
  ];

  /// The fault kinds a reason can name (an expired date or time is one reason).
  static const _whyKinds = [PtwFault.feeder, PtwFault.place, PtwFault.name, PtwFault.expiredDate, PtwFault.unsigned];

  static List<String> faultWhy(PtwFault f) => switch (f) {
        PtwFault.none => whyValid,
        PtwFault.feeder => whyFeeder,
        PtwFault.place => whyPlace,
        PtwFault.name => whyName,
        PtwFault.expiredDate || PtwFault.expiredTime => whyExpired,
        PtwFault.unsigned => whyUnsigned,
      };

  /// The right reasons for what [r] had.
  static List<String> whyRight(PtwRound r) => r.phone ? whyVerbal : faultWhy(r.form!.fault);

  /// The wrong cards for [r]'s deck, grouped by kind: a valid permit was
  /// started — the myths; a permit was stopped — the reasons of the faults
  /// this permit did not have (true in the lesson, wrong here), so the deck
  /// asks what the player actually found; the phone refused — field excuses.
  /// The phone's reasons never go on a stop deck ("হাতে স্বাক্ষরিত পারমিট
  /// ছাড়া কাজ শুরু নয়" is right for an unsigned permit too).
  static List<List<String>> _wrongKinds(PtwRound r) {
    if (r.phone) return [for (final w in phoneExcuses) [w]];
    final f = r.form!.fault;
    if (f == PtwFault.none) return [for (final w in mythsStart) [w]];
    final own = f == PtwFault.expiredTime ? PtwFault.expiredDate : f;
    return [
      for (final k in _whyKinds)
        if (k != own) faultWhy(k),
    ];
  }

  /// The wrong library for [r]'s deck (every phrasing).
  static List<String> whyWrong(PtwRound r) => [for (final k in _wrongKinds(r)) ...k];

  /// The wrong cards a deck is dealt from: one phrasing per kind, so a deck
  /// never shows two phrasings of the same fault.
  static List<String> whyWrongDeal(PtwRound r, math.Random rng) => [for (final k in _wrongKinds(r)) k[rng.nextInt(k.length)]];

  /// The careless coworker (his recorded voice) on the phone round.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAsks = [
    'ও বলছে ফোনের কথাতেই শুরু করতে। আপনি কী করবেন?',
    'কাগজ ছাড়াই কাজ শুরু করবেন?',
    'কার কথা শুনবেন — ফোনের, না কাগজের?',
  ];
  static const coworker = CoworkerScript(
    line: 'ফোনেই তো বলল লাইন বন্ধ! কাগজ পরে আসবে, কাজ শুরু করো।',
    exitLine: coworkerExit,
    right: ['না, হাতে লিখিত পারমিট এলে তবেই কাজ', 'ফোনের কথায় নয়, স্বাক্ষরিত কাগজ চাই', 'কাগজ না আসা পর্যন্ত লাইনে হাত নয়'],
    wrong: [
      'ঠিক, কন্ট্রোল রুম বলেছে, শুরু করি',
      'কাগজ তো পরে আসছেই, শুরু করে দিই',
      'ফোনেই তো বলল লাইন বন্ধ, চলো উঠি',
      'সময় নষ্ট না করে কাজটা সেরে ফেলি',
      'সুপারভাইজার জানেন, আমাদের ভাবনা কী',
    ],
    asks: coworkerAsks,
  );

  static const startOk = 'সব মিলেছে — কাজ শুরু, তবে আগে ডিসচার্জ আর টেস্ট।';
  static const allSet = 'কাগজ মেলাতে পাকা! লেখা পারমিট হাতে, তবে লাইনে হাত।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ফিডার, পোল, টিম, সময়, স্বাক্ষর।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtPhone = 'ফোনের কথায় “না”';
  static const caughtFeeder = 'ফিডারের অমিল ধরেছেন';
  static const caughtTime = 'মেয়াদ পেরোনো পারমিট ধরেছেন';
  static const caughtSign = 'স্বাক্ষরহীন পারমিট ধরেছেন';
  static const caughtOther = 'পোল / টিমের অমিল ধরেছেন';
  static const caughtValid = 'বৈধ পারমিট চিনেছেন';
  static const feeders = ['রামপুর 11 কেভি', 'হাটখোলা 11 কেভি', 'নদীপাড় 11 কেভি', 'স্টেশন রোড 11 কেভি', 'কলেজপাড়া 11 কেভি'];
  static const names = ['রফিক', 'সুজয়', 'আনোয়ার', 'বিকাশ', 'প্রদীপ', 'ইমরান'];
  static const jobs = ['ভাঙা ইনসুলেটর বদল', 'জাম্পার মেরামত', 'ক্রস-আর্ম বদল', 'ছেঁড়া তার জোড়া'];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// A team as the permit and the ID card name it: by its leader ("রফিকের টিম").
  static String teamOf(String leader) => '$leaderের টিম';

  /// A date as the permit and the phone show it (dd-mm-yyyy, English digits).
  static String dateOf(DateTime d) => enDigits('${_two(d.day)}-${_two(d.month)}-${d.year}');
}

abstract final class PtwMistakes {
  static const verbal = DoMistake(
    key: '1.6/ptw/verbal',
    textBn: 'ফোনে ‘লাইন বন্ধ’ কোনো পারমিট নয় — হাতে স্বাক্ষরিত PTW ছাড়া লাইনে হাত নয়।',
    art: 'assets/game/art/ptw/verbal_vs_written.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const wrongFeeder = DoMistake(
    key: '1.6/ptw/wrong-feeder',
    textBn: 'পারমিটের ফিডার আর পোলের ফিডার আলাদা — অন্য লাইন বন্ধ হয়েছে, আপনার লাইন চালু থাকতে পারে।',
    art: 'assets/game/art/ptw/feeder_match.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const unsigned = DoMistake(
    key: '1.6/ptw/unsigned',
    textBn: 'স্বাক্ষরের ঘর ফাঁকা — এটা পারমিট নয়, শুধু একটা কাগজ। হাতে স্বাক্ষরিত PTW ছাড়া কাজ নয়।',
    art: 'assets/game/art/ptw/no_signature.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const expired = DoMistake(
    key: '1.6/ptw/expired',
    textBn: 'পারমিটের তারিখ বা সময় পেরিয়ে গেছে — মেয়াদ পেরোনো পারমিট আর বৈধ নয়। কাজ থামিয়ে নতুন পারমিট নিন।',
    art: 'assets/game/art/ptw/permit_time.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wrongPlace = DoMistake(
    key: '1.6/ptw/wrong-place',
    textBn: 'পারমিটের পোল নম্বর আর সাইটের পোল মেলে না — পারমিট নির্দিষ্ট জায়গার জন্যই।',
    art: 'assets/game/art/ptw/pole_match.svg',
    lessonPoint: 0,
  );
  static const wrongName = DoMistake(
    key: '1.6/ptw/wrong-name',
    textBn: 'পারমিট অন্য টিমের নামে — পারমিট নির্দিষ্ট ব্যক্তি বা টিমের জন্যই। যে নেয়, সে-ই ফেরত দেয়।',
    art: 'assets/game/art/ptw/team_match.svg',
    lessonPoint: 0,
  );
  static const falseStop = DoMistake(
    key: '1.6/ptw/false-stop',
    textBn: 'এই ঘরটা সাইটের সঙ্গে মিলেছিল। প্রতিটি শব্দ মন দিয়ে পড়ুন — তারপর শুরু, নয়তো বন্ধ।',
    art: 'assets/game/art/ptw/read_every_word.svg',
    lessonPoint: 0,
  );
  static const wrongField = DoMistake(
    key: '1.6/ptw/wrong-field',
    textBn: 'এই ঘরটা মেলে — অমিল অন্য কোনো ঘরে। প্রতিটি ঘর সাইটের সঙ্গে মিলিয়ে পড়ুন।',
    art: 'assets/game/art/ptw/read_every_word.svg',
    lessonPoint: 0,
  );
  static DoMistake started(PtwFault f) => switch (f) {
        PtwFault.feeder => wrongFeeder,
        PtwFault.unsigned => unsigned,
        PtwFault.expiredDate || PtwFault.expiredTime => expired,
        PtwFault.place => wrongPlace,
        PtwFault.name => wrongName,
        PtwFault.none => falseStop,
      };
  static const all = [verbal, wrongFeeder, unsigned, expired, wrongPlace, wrongName, falseStop, wrongField];
}

/// Four rounds: three forms (one valid, two with one fault each) and the
/// phone call (never first). Site, names, feeders and numbers vary. [today]
/// is the device's date: the permit's date and the phone's clock follow it.
List<PtwRound> dealPermits(math.Random rng, DateTime today) {
  final feeders = [...PtwLines.feeders]..shuffle(rng);
  final names = [...PtwLines.names]..shuffle(rng);
  final faults = [PtwFault.feeder, PtwFault.place, PtwFault.name, rng.nextBool() ? PtwFault.expiredDate : PtwFault.expiredTime, PtwFault.unsigned]..shuffle(rng);
  final kinds = <PtwFault?>[PtwFault.none, faults[0], faults[1]]..shuffle(rng);
  kinds.insert(1 + rng.nextInt(3), null); // the phone call
  String two(int n) => n.toString().padLeft(2, '0');
  final rounds = <PtwRound>[];
  for (var i = 0; i < kinds.length; i++) {
    final site = PtwSite(
      feederBn: feeders[i % feeders.length],
      pole: 40 + rng.nextInt(40),
      nameBn: names[0],
      teamBn: PtwLines.teamOf(names[1]),
      today: today,
      nowBn: enDigits('11:${two(10 + rng.nextInt(40))}'),
    );
    final k = kinds[i];
    if (k == null) {
      rounds.add(PtwRound(site: site));
      continue;
    }
    final lo = site.pole - 1 - rng.nextInt(3);
    final placeOk = 'পোল নং ${enDigits('$lo')} – ${enDigits('${lo + 5}')}';
    final placeBad = 'পোল নং ${enDigits('${site.pole + 6}')} – ${enDigits('${site.pole + 11}')}';
    rounds.add(PtwRound(
      site: site,
      form: PtwForm(
        numberBn: enDigits('PTW/${today.year}/0${100 + rng.nextInt(899)}'),
        feederBn: k == PtwFault.feeder ? feeders[(i + 1) % feeders.length] : site.feederBn,
        placeBn: k == PtwFault.place ? placeBad : placeOk,
        jobBn: PtwLines.jobs[rng.nextInt(PtwLines.jobs.length)],
        nameBn: k == PtwFault.name ? PtwLines.teamOf(names[2]) : site.teamBn,
        dateBn: PtwLines.dateOf(k == PtwFault.expiredDate ? today.subtract(const Duration(days: 1)) : today),
        timeBn: enDigits(k == PtwFault.expiredTime ? '07:00 – 10:30' : '09:00 – 14:00'),
        signed: k != PtwFault.unsigned,
        fault: k,
      ),
    ));
  }
  return rounds;
}

/// The play state (pure logic).
class PtwRun {
  PtwRun(this.rounds);
  final List<PtwRound> rounds;
  int index = 0;
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= rounds.length;
  bool get ended => done || deadly != null;
  PtwRound get current => rounds[index.clamp(0, rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Start the work (true) or stop it on [flagged], the field that does not
  /// match. Stopping on a field that matches is a slip and the permit is
  /// still to judge.
  DoMistake? decide({required bool start, PtwField? flagged}) {
    final f = current.form;
    if (ended || shown || f == null) return null;
    if (start) {
      shown = true;
      if (f.fault == PtwFault.none) {
        _tag(PtwLines.caughtValid);
        return null;
      }
      final m = PtwMistakes.started(f.fault);
      if (m.deadly) return deadly = m;
      slips++;
      return m;
    }
    if (f.fault == PtwFault.none) {
      slips++;
      return PtwMistakes.falseStop;
    }
    if (flagged != f.fault.field) {
      slips++;
      return PtwMistakes.wrongField;
    }
    shown = true;
    _tag(switch (f.fault) {
      PtwFault.feeder => PtwLines.caughtFeeder,
      PtwFault.expiredDate || PtwFault.expiredTime => PtwLines.caughtTime,
      PtwFault.unsigned => PtwLines.caughtSign,
      _ => PtwLines.caughtOther,
    });
    return null;
  }

  /// The phone round: held out for paper (true) or started on the word.
  DoMistake? answerPhone({required bool held}) {
    if (ended || shown || !current.phone) return null;
    shown = true;
    if (!held) return deadly = PtwMistakes.verbal;
    _tag(PtwLines.caughtPhone);
    return null;
  }

  void next() {
    index++;
    shown = false;
  }
}

@immutable
class PtwPack {
  const PtwPack({required this.id, required this.titleBn, this.quickMs = kPtwQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

/// The quick bonus: about 85 % of a careful play (rounded to 10 s), from the
/// end of the guide's intro to the last paid reason. Per paper round (ms;
/// ~1500 per human action): drive to the job 1200, hold the permit up 1500,
/// the lens on six fields 6 × 3000, decide 1500, the reason ~8200 → ~30400,
/// × 3 = 91200; the phone round: drive 1200, answer 2000, his line ~3000,
/// deck and pick ~4400, his snarl 1500, the reason ~8200 → ~20300.
/// ≈ 111500; 85 % ≈ 95000 → 100 s (the value the level had before the kit).
const kPtwQuickMs = 100000;

const ptwPack16 = PtwPack(id: 'do_1_6_a', titleBn: PtwLines.title);
const ptwPacks = {'do_1_6_a': ptwPack16};

// ============================================================================
// Page
// ============================================================================

class PtwMatchPage extends StatefulWidget {
  const PtwMatchPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.today});

  final LevelContext ctx;
  final PtwPack pack;
  final bool muted;
  final int? seed;

  /// The date the permits are checked against (default: the device's today).
  final DateTime? today;

  @override
  State<PtwMatchPage> createState() => _PtwMatchPageState();
}

class _PtwMatchPageState extends State<PtwMatchPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) {
    final now = widget.today ?? DateTime.now();
    return _PtwRunPage(
      key: ValueKey(_round),
      ctx: widget.ctx,
      pack: widget.pack,
      muted: _muted,
      today: DateTime(now.year, now.month, now.day),
      rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
      onRetry: (m) => setState(() {
        _muted = m;
        _round++;
      }),
    );
  }
}

class _PtwRunPage extends ConsumerStatefulWidget {
  const _PtwRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.today, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final PtwPack pack;
  final bool muted;
  final DateTime today;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PtwRunPage> createState() => _PtwRunPageState();
}

enum _Verdict { started, stopped }

/// The crewmate by the van.
const _crewLook = LinemanLook(
  helmet: Color(0xFFF4F4F0),
  shirt: Color(0xFF3F6E4A),
  vest: Color(0xFFE8C21A),
  pants: Color(0xFF3A3F4A),
  skin: Color(0xFF8E5B3A),
  moustache: true,
);

/// The permit sheet's own layout size (design px; it is scaled to its place).
const double _sheetW = 200;
const double _sheetH = 300;

class _PtwRunPageState extends ConsumerState<_PtwRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final PtwRun _run = PtwRun(dealPermits(widget.rng, widget.today));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// Driving to the next job: 0 → 1 (the pole slides in; travel = 1 − value).
  late final AnimationController _walkIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200), value: 1)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _arrived();
    });

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  // --- this round ---------------------------------------------------------------
  /// The site is in place and the round has begun.
  var _here = false;

  /// The permit is held up beside the pole.
  var _held = false;

  /// The permit's centre while it is dragged up (design px).
  Offset? _dragAt;

  /// The field under the lens.
  PtwField? _lens;

  /// Fields the player marked "মিলেছে" (his own ticks; they score nothing).
  final Set<PtwField> _checked = {};
  _Verdict? _verdict;
  var _ringing = false;
  var _callUp = false;
  int _wake = 0;

  /// A deadly start: the site freezes grey while the line flashes, in colour.
  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Where the permit sits (design px), from the last layout.
  PtwGeo? _geo;
  Rect _trayR = Rect.zero;
  Rect _heldR = Rect.zero;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  bool get _driving => _walkIn.isAnimating;

  @override
  void dispose() {
    disposeCoworker();
    _walkIn.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty || !mounted) return;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted);
  }

  Future<void> _sayChain(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final l in lines) {
      if (!mounted || chain != _chain) return;
      await _say(l, mood: mood);
    }
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  /// After the guide's intro: the clock runs; the first job is already here.
  Future<void> _start() async {
    _clock.start();
    _arrived();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _here && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && !_driving;

  // --- the round ---------------------------------------------------------------
  void _arrived() {
    if (!mounted || _ended) return;
    setState(() {
      _here = true;
      _wake++;
      _ringing = _run.current.phone;
    });
    if (_run.current.phone) {
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
      unawaited(_sayChain([PtwLines.taskPhone]));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
      unawaited(_sayChain([PtwLines.taskLift]));
    }
  }

  // --- the permit: drag it up beside the pole ------------------------------------
  void _dragStart(DragStartDetails _) {
    if (!_canPlay || _held || _run.current.phone) return;
    HapticFeedback.selectionClick();
    setState(() => _dragAt = _trayR.center);
  }

  void _dragUpdate(DragUpdateDetails d) {
    final at = _dragAt;
    if (at == null) return;
    setState(() => _dragAt = at + d.delta);
  }

  void _dragEnd() {
    final at = _dragAt;
    if (at == null) return;
    final up = at.dy < (_geo?.groundY ?? 400) - 20;
    setState(() {
      _dragAt = null;
      if (up) _held = true;
    });
    if (up) {
      _lifted();
    } else if (!_muted) {
      unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
    }
  }

  /// A tap on the clipboard lifts it too (for those who cannot drag).
  void _tapTray() {
    if (!_canPlay || _held || _run.current.phone) return;
    setState(() => _held = true);
    _lifted();
  }

  void _lifted() {
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
    setState(() => _wake++);
    unawaited(_sayChain([PtwLines.ask]));
  }

  // --- the lens --------------------------------------------------------------------
  void _openLens(PtwField f) {
    if (!_canPlay || !_held || _lens != null || !ptwLensFields.contains(f)) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.4, muted: false));
    setState(() => _lens = f);
    unawaited(_sayChain([PtwLines.taskLens]));
  }

  /// Close the lens; [tick]: he marked the field as matching.
  void _closeLens({bool tick = false}) {
    final f = _lens;
    if (f == null) return;
    if (tick) {
      HapticFeedback.selectionClick();
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    }
    setState(() {
      _lens = null;
      if (tick) _checked.add(f);
    });
  }

  Future<void> _stopOnLens(Offset origin) async {
    final f = _lens;
    if (f == null || !_canPlay) return;
    setState(() => _lens = null);
    await _decide(false, origin, field: f);
  }

  // --- the decision ------------------------------------------------------------------
  Future<void> _decide(bool start, Offset origin, {PtwField? field}) async {
    if (!_canPlay || !_held) return;
    _hush();
    final m = _run.decide(start: start, flagged: field);
    HapticFeedback.mediumImpact();
    if (m == null) {
      // Right: the stamp, the ◆ wait on the table, then "কেন …?".
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.7, muted: false));
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      }
      setState(() {
        _verdict = start ? _Verdict.started : _Verdict.stopped;
        _wake++;
      });
      _askWhy(start ? PtwLines.whyStart : PtwLines.whyStop);
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() => _wake++);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _askWhy(String question) {
    putOnTable(15);
    final r = _run.current;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(PtwLines.whyRight(r), PtwLines.whyWrongDeal(r, widget.rng), widget.rng),
      question: question,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  // --- the phone round -----------------------------------------------------------------
  void _answerPhone() {
    if (!_canPlay || !_run.current.phone || !_ringing) return;
    _hush();
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.6, muted: false));
    setState(() {
      _ringing = false;
      _callUp = true;
      _wake++;
    });
    // He comes in on the phone's word, a moment after the call.
    scheduleCoworker();
  }

  /// Next job (or the result) — by itself, after the reason or the slip card.
  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _here = false;
      _held = false;
      _dragAt = null;
      _lens = null;
      _checked.clear();
      _verdict = null;
      _ringing = false;
      _callUp = false;
    });
    if (_quiet) {
      _walkIn.value = 1;
      _arrived();
    } else {
      unawaited(_walkIn.forward(from: 0));
    }
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() => _hush();
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() {
    final idx = _run.index;
    final started = _verdict == _Verdict.started;
    bool still() => mounted && !_ended && _run.index == idx;
    unawaited(() async {
      final hold = Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 1200));
      // A valid permit: the work starts — but the lesson's step 4 first.
      if (started) await _sayChain([PtwLines.startOk], mood: GuideMood.glad);
      await hold;
      if (still()) _next();
    }());
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => PtwLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.current.phone || _run.shown) return null;
    if (_intro || _busy || _card != null || reasonOpen || !_callUp) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final m = _run.answerPhone(held: held);
    if (m != null) {
      // Started on the phone's word: deadly.
      await _deadly(m);
      return;
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
    setState(() {
      _verdict = _Verdict.stopped;
      _wake++;
    });
    final idx = _run.index;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || _ended || _run.index != idx) return;
      _askWhy(PtwLines.whyPhone);
    }());
  }

  /// What the player is to do now (the guide says it another way on a tap).
  String get _task {
    if (_run.current.phone) return _callUp ? PtwLines.taskCall : PtwLines.taskPhone;
    if (!_held) return PtwLines.taskLift;
    if (_lens != null) return PtwLines.taskLens;
    return PtwLines.ask;
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? PtwLines.tapWhy[_nudgeN++ % PtwLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('ptw/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly start: the site freezes grey and the live line flashes in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _lens = null;
      _dragAt = null;
    });
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('ptw/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? PtwLines.deadlyWord : PtwLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_run.shown) {
          _next();
        } else {
          // Stopped on a field that matches: this permit is still to judge.
          unawaited(_sayChain([PtwLines.ask]));
        }
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? PtwLines.fail : (_quickBonus ? PtwLines.quick : PtwLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (deathPending) {
      if (_popped) return;
      _popped = true;
      await dieAndLeave();
      return;
    }
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the scene ---------------------------------------------------------------
  /// The trainee's pose now.
  LinemanMode get _mode {
    if (_driving) return LinemanMode.walk;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_verdict == _Verdict.started && _run.shown) return LinemanMode.cheer;
    if (_held || _dragAt != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The permit held up beside the pole: right of it, under the header, above
  /// the corner guide's bubble (design px).
  Rect _heldRectFor(SceneMetrics m, PtwGeo geo) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final k = 360 / math.max(1.0, size.width);
    final top = (pad.top + 96) * k;
    final guideTop = (size.height - pad.bottom - 72 - 116 - 96) * k;
    final bottom = math.min(guideTop - 2, geo.groundY + 20);
    final avail = math.max(150.0, bottom - top);
    final w = (avail * _sheetW / _sheetH).clamp(170.0, 214.0);
    final h = w * _sheetH / _sheetW;
    return Rect.fromLTWH(352 - w, top + math.max(0.0, avail - h) * 0.3, w, h);
  }

  /// The clipboard as it arrives, bottom left (design px).
  Rect _trayRectFor(SceneMetrics m) {
    const w = 64.0;
    const h = w * _sheetH / _sheetW;
    return Rect.fromLTWH(12, m.height - m.inset - 18 - h, w, h);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = PtwGeo.forScene(m.height, m.inset);
    _heldR = _heldRectFor(m, geo);
    _trayR = _trayRectFor(m);
    final r = _run.current;
    final travel = 1 - _walkIn.value;
    final dx = travel * 300;
    final prev = _run.index > 0 && travel > 0 ? _run.rounds[_run.index - 1] : null;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final world = <Widget>[
      Positioned.fill(
        key: const ValueKey('yard'),
        child: RepaintBoundary(child: CustomPaint(painter: PoleYardPainter(geo: geo.pole, orbit: 0, travel: travel))),
      ),
      Positioned.fill(
        key: const ValueKey('site'),
        child: CustomPaint(painter: PtwSitePainter(geo: geo, dx: dx, prevDx: prev == null ? null : dx - 300)),
      ),
      // The feeder tag and the number plate on the pole (and the last one, leaving).
      for (final (k, x, off) in [('now', r, dx), if (prev != null) ('prev', prev, dx - 300)]) ...[
        Positioned.fromRect(key: ValueKey('tag-$k'), rect: geo.tagRect.shift(Offset(off, 0)), child: PtwTag(feederBn: x.site.feederBn)),
        Positioned.fromRect(key: ValueKey('plate-$k'), rect: geo.plateRect.shift(Offset(off, 0)), child: PtwPlate(pole: x.site.pole)),
      ],
      Positioned.fromRect(
        key: const ValueKey('crew'),
        rect: geo.crewRect,
        child: LinemanFigure(look: _crewLook, mode: _driving ? LinemanMode.walk : LinemanMode.idle, quiet: quiet),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.traineeRect,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The phone on the bonnet (it rings on the phone round).
      Positioned.fromRect(
        key: const ValueKey('phone'),
        rect: geo.phoneRect.inflate(18),
        child: Semantics(
          label: PtwLines.phoneLabel,
          button: true,
          child: PtwScenePhone(
            ringing: _ringing && !_freeze,
            calling: _callUp,
            quiet: quiet,
            wake: _wake,
            onTap: r.phone ? _answerPhone : null,
          ),
        ),
      ),
      if (!r.phone && _here) _sheetLayer(r.form!),
    ];
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(colorFilter: grey, child: Stack(children: world)),
      ),
      // The live line, in colour over the grey site.
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(child: PtwLiveFlash(geo: geo, quiet: quiet)),
        ),
    ];
  }

  /// The control room's words from the phone (a page layer, screen px), where
  /// neither the coworker's words nor the corner guide's bubble hide them: in
  /// the sky under his words; on a short screen with a deck up, low between
  /// him and the guide (beside the mascot, over the deck).
  Widget _callLayer(EdgeInsets pad, {required bool deckUp}) {
    final size = MediaQuery.sizeOf(context);
    final w = math.max(1.0, size.width);
    // His words start at 15 % of the height (about 124 tall with the tag).
    final skyTop = size.height * 0.15 + 124;
    // The corner guide's top: the mascot (116) and his bubble (up to ~100).
    final guideTop = size.height - pad.bottom - (deckUp ? 236 : 72) - 116 - 100;
    const callH = 84.0;
    if (!deckUp || skyTop + callH <= guideTop - 8) {
      return Positioned(
        key: const ValueKey('call'),
        left: 118 * w / 360,
        right: 10 * w / 360,
        top: skyTop,
        child: _CallBubble(quiet: _quiet),
      );
    }
    // The guide stands on the side the coworker does not come from; his
    // mascot is at the inner end of his 232-wide corner (cornerGuide). The
    // free gap is beside the mascot, away from the coworker: left of the
    // mascot when the guide is left, between the coworker and the mascot when
    // the guide is right.
    final guideLeft = coworkerFromRight;
    return Positioned(
      key: const ValueKey('call'),
      left: guideLeft ? 4 : 102,
      width: guideLeft ? 130 : math.min(140.0, w - 220),
      bottom: pad.bottom + 240,
      child: _CallBubble(quiet: _quiet, compact: true),
    );
  }

  Widget _sheetLayer(PtwForm form) {
    final drag = _dragAt;
    final Rect rect;
    if (drag != null) {
      final span = _trayR.center.dy - _heldR.center.dy;
      final t = span <= 0 ? 1.0 : ((_trayR.center.dy - drag.dy) / span).clamp(0.0, 1.0);
      final w = lerpDouble(_trayR.width, _heldR.width, t)!;
      rect = Rect.fromCenter(center: drag, width: w, height: w * _sheetH / _sheetW);
    } else {
      rect = _held ? _heldR : _trayR;
    }
    final decided = _run.shown && !_freeze;
    final sheet = _PermitSheet(
      form: form,
      checked: _checked,
      decided: decided,
      stamp: !decided || _verdict == null
          ? null
          : (_verdict == _Verdict.stopped ? PtwLines.stampStop : (form.fault == PtwFault.none ? PtwLines.stampValid : null)),
      quiet: _quiet,
      onTap: _held && _canPlay && _lens == null ? _openLens : null,
    );
    return AnimatedPositioned.fromRect(
      key: ValueKey('sheet-${_run.index}'),
      rect: rect,
      duration: drag != null || _quiet ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: _held
          ? sheet
          : Semantics(
              label: PtwLines.sheetLabel,
              button: true,
              child: GestureDetector(
                key: const ValueKey('sheet-drag'),
                behavior: HitTestBehavior.opaque,
                onTap: _tapTray,
                onPanStart: _dragStart,
                onPanUpdate: _dragUpdate,
                onPanEnd: (_) => _dragEnd(),
                onPanCancel: _dragEnd,
                child: ExcludeSemantics(child: sheet),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && _here && !_run.shown && !deckUp && !coworkerOpen && _card == null;
    final r = _run.current;
    final lens = _lens;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: FullSceneFrame(
            ctx: widget.ctx,
            titleBn: widget.pack.titleBn,
            scoreKey: _scoreKey,
            levelScore: _runScore,
            muted: _muted,
            onClose: () => unawaited(_leave()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: PtwLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            animation: _walkIn,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(58, pad.top + 128), quiet: quiet),
              if (handsOn && _held && lens == null && !r.phone)
                Positioned(
                  key: const ValueKey('hud-start'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(label: PtwLines.start, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition))),
                ),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (lens != null && playing && !r.phone) ...[
                Positioned.fill(
                  key: const ValueKey('lens-dim'),
                  child: GestureDetector(onTap: _closeLens, child: const ColoredBox(color: Color(0x80050A16))),
                ),
                Positioned(
                  key: const ValueKey('lens'),
                  left: 12,
                  right: 12,
                  top: pad.top + 112,
                  child: _FieldLens(
                    field: lens,
                    form: r.form!,
                    site: r.site,
                    quiet: quiet,
                    onMatch: () => _closeLens(tick: true),
                    onStop: (o) => unawaited(_stopOnLens(o)),
                    onClose: _closeLens,
                  ),
                ),
              ],
              if (playing && _card == null && lens == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 72),
                  // While a permit's reason deck is up he stands left, off the decided sheet.
                  onLeft: coworkerFromRight || (reasonOpen && !r.phone),
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // The control room's words, over his dim so they stay readable.
              if (_callUp && r.phone && playing && _card == null) _callLayer(pad, deckUp: deckUp),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _hush();
                          unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2400,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: PtwLines.intro,
                  alarm: 'sounds/van_arrive.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: _run.caught,
                                quickBonus: _quickBonus,
                                stars: _stars,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Pieces
// ============================================================================

/// The permit on its clipboard (laid out at 200 × 300 and scaled to its
/// place). Fields the lens can compare carry a small magnifier; the player's
/// own ticks show; once decided, the field that did not match is marked.
class _PermitSheet extends StatelessWidget {
  const _PermitSheet({required this.form, required this.checked, required this.decided, required this.stamp, required this.quiet, required this.onTap});
  final PtwForm form;
  final Set<PtwField> checked;
  final bool decided;
  final String? stamp;
  final bool quiet;
  final ValueChanged<PtwField>? onTap;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: _sheetW,
        height: _sheetH,
        child: Stack(
          children: [
            // The clipboard.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA9773F), Color(0xFF7E5428)]),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
              ),
            ),
            // The paper.
            Positioned(
              left: 6,
              right: 6,
              top: 16,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                decoration: BoxDecoration(color: const Color(0xFFFFFDF6), borderRadius: BorderRadius.circular(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_rounded, size: 13, color: Color(0xFF8C6A2A)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(PtwLines.formTitle, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.2))),
                      ],
                    ),
                    const Divider(height: 8, thickness: 1, color: Color(0xFFCFC6B2)),
                    for (final f in PtwField.values) _row(f),
                  ],
                ),
              ),
            ),
            // The clip.
            Positioned(
              left: _sheetW / 2 - 30,
              top: 2,
              width: 60,
              height: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE3E6EA), Color(0xFF8E959C)]),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF5F676F)),
                ),
              ),
            ),
            if (stamp != null)
              Positioned.fill(
                key: ValueKey('stamp-$stamp'),
                child: IgnorePointer(
                  child: Align(
                    // On the right half (the corner guide stands left while
                    // the reason deck is up), clear of the row marked "মেলে না".
                    alignment: Alignment(0.3, (form.fault.field?.index ?? 0) <= PtwField.job.index ? 0.55 : -0.45),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      builder: (_, t, child) => Transform.scale(scale: 1.6 - 0.6 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                      child: Transform.rotate(angle: -0.2, child: DoStamp(text: stamp!, good: true)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(PtwField f) {
    final bad = decided && form.fault.field == f;
    final ticked = checked.contains(f);
    final lensable = ptwLensFields.contains(f);
    final value = f == PtwField.signature
        ? (form.signed
            ? const SizedBox(height: 16, width: 64, child: CustomPaint(painter: _SignaturePainter()))
            : Text(PtwLines.noSign, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF9AA3AB), height: 1.2)))
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(form.valueOf(f), maxLines: 1, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.2)),
          );
    final row = Container(
      height: 27,
      margin: const EdgeInsets.only(bottom: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bad ? const Color(0x1FC0392B) : null,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: bad ? SlmColors.danger : const Color(0x00000000), width: 1.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(PtwLines.labels[f]!, style: bangla(fontSize: 7.8, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.1)),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: value)),
          if (bad)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(6)),
              child: Text(PtwLines.mismatch, style: bangla(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
            )
          else if (ticked)
            const Icon(Icons.check_circle_rounded, size: 12, color: SlmColors.emerald500)
          else if (lensable)
            const Icon(Icons.search_rounded, size: 11, color: Color(0xFFB0A68E)),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null || !lensable) return row;
    return Semantics(
      button: true,
      label: PtwLines.labels[f],
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => tap(f), child: row),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter();

  @override
  void paint(Canvas c, Size s) {
    final h = s.height;
    final w = s.width / 74;
    final p = Path()
      ..moveTo(0, h * 0.7)
      ..quadraticBezierTo(10 * w, 0, 18 * w, h * 0.6)
      ..quadraticBezierTo(26 * w, h, 34 * w, h * 0.3)
      ..quadraticBezierTo(42 * w, 0, 52 * w, h * 0.65)
      ..quadraticBezierTo(60 * w, h * 0.9, 74 * w, h * 0.4);
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF2F6FD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * math.max(1.0, h / 16)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => false;
}

/// The control room's words from the phone.
class _CallBubble extends StatelessWidget {
  const _CallBubble({required this.quiet, this.compact = false});
  final bool quiet;

  /// Narrow and small, for the gap beside the mascot on a short screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, alignment: Alignment.bottomLeft, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
          decoration: BoxDecoration(
            color: const Color(0xF2FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E7A4A), width: 1.6),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFF1E7A4A)),
                  const SizedBox(width: 4),
                  Text(PtwLines.phoneWho, style: bangla(fontSize: compact ? 9.5 : 10, fontWeight: FontWeight.w900, color: const Color(0xFF1E7A4A), height: 1.2)),
                ],
              ),
              const SizedBox(height: 2),
              Text('“${PtwLines.phoneLine}”', style: bangla(fontSize: compact ? 10.5 : 11.5, fontWeight: FontWeight.w800, color: SlmColors.ink, height: compact ? 1.3 : 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lens on one field: what the permit says beside what the site shows.
/// It never says which: the player compares, then marks it or stops.
class _FieldLens extends StatelessWidget {
  const _FieldLens({
    required this.field,
    required this.form,
    required this.site,
    required this.quiet,
    required this.onMatch,
    required this.onStop,
    required this.onClose,
  });

  final PtwField field;
  final PtwForm form;
  final PtwSite site;
  final bool quiet;
  final VoidCallback onMatch;
  final ValueChanged<Offset> onStop;
  final VoidCallback onClose;

  Widget _panel(String head, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(head, textAlign: TextAlign.center, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.gold300, height: 1.3)),
          const SizedBox(height: 4),
          SizedBox(height: 150, child: Center(child: child)),
        ],
      );

  Widget _paper() {
    final Widget value = field == PtwField.signature
        ? (form.signed
            ? const SizedBox(width: 150, height: 44, child: CustomPaint(painter: _SignaturePainter()))
            : Text(PtwLines.noSign, style: bangla(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF9AA3AB))))
        : Text(form.valueOf(field), textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.3));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(color: const Color(0xFFFFFDF6), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8C7D5E), width: 1.4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(PtwLines.labels[field]!, textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.2)),
          const SizedBox(height: 6),
          value,
        ],
      ),
    );
  }

  Widget? _site() => switch (field) {
        PtwField.feeder => SizedBox(width: 150, height: 84, child: PtwTag(feederBn: site.feederBn, big: true)),
        PtwField.place => SizedBox(width: 104, height: 80, child: PtwPlate(pole: site.pole, big: true)),
        PtwField.name => PtwIdCard(
            titleBn: PtwLines.idTitle,
            nameLabelBn: PtwLines.idName,
            nameBn: site.nameBn,
            teamLabelBn: PtwLines.idTeam,
            teamBn: site.teamBn,
          ),
        PtwField.date || PtwField.time => SizedBox(width: 100, height: 146, child: PtwPhone(timeBn: site.nowBn, dateBn: PtwLines.dateOf(site.today), big: true)),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final siteView = _site();
    return Semantics(
      label: PtwLines.lensLabel,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.scale(scale: 0.88 + 0.12 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF14233F), Color(0xFF0B1528)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.6),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.search_rounded, color: SlmColors.gold300, size: 22),
                  const SizedBox(width: 6),
                  Expanded(child: Text(PtwLines.labels[field]!, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3))),
                  Semantics(
                    label: PtwLines.lensClose,
                    button: true,
                    child: InkResponse(
                      onTap: onClose,
                      radius: 26,
                      child: const SizedBox(width: 48, height: 48, child: Icon(Icons.close_rounded, color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _panel(PtwLines.onPaper, _paper())),
                  if (siteView != null) ...[
                    const SizedBox(width: 10),
                    Expanded(child: _panel(PtwLines.onSite, siteView)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _LensButton(icon: Icons.check_rounded, label: PtwLines.matchOk, color: SlmColors.emerald500, onTapUp: (_) => onMatch())),
                  const SizedBox(width: 10),
                  Expanded(child: _LensButton(icon: Icons.back_hand_rounded, label: PtwLines.stop, color: SlmColors.danger, onTapUp: (d) => onStop(d.globalPosition))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LensButton extends StatelessWidget {
  const _LensButton({required this.icon, required this.label, required this.color, required this.onTapUp});
  final IconData icon;
  final String label;
  final Color color;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color, width: 1.8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Flexible(child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2))),
            ],
          ),
        ),
      ),
    );
  }
}
