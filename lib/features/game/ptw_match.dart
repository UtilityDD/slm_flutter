import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'do_parts.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'spoken_once.dart';

// Lesson 1.6, কাজ 1: "কাগজ মেলাও". Four rounds at the site. Three times a
// permit-to-work arrives: read it against the site — the pole's feeder tag
// and number, your own name, today's date and the time now, and the control
// room's signature. If everything matches, start; if not, tap the field that
// does not match and stop the work. Once there is no paper at all, only a
// phone call: "লাইন বন্ধ, কাজ শুরু করো — কাগজ পরে পাঠাচ্ছি".
//
// Deadly (owner-approved list: working on a verbal permit / the wrong
// feeder): starting on the phone's word; starting on a permit for another
// feeder. Also deadly here, as "no valid written permit": an unsigned or an
// expired permit. Slips: starting on a permit with the wrong pole range or
// another person's name; stopping a valid permit; stopping but flagging the
// wrong field.
//
// Voice: device TTS only. Art: assets/game/art/ptw/ (hand-made SVG, no text
// inside); the form is built from widgets so its fields can vary.

// ============================================================================
// Content
// ============================================================================

enum PtwField { number, feeder, place, job, name, date, time, signature }

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
  const PtwSite({required this.feederBn, required this.pole, required this.nameBn, required this.today, required this.nowBn});
  final String feederBn;
  final int pole;
  final String nameBn;
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
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'কাগজ মেলাও';
  static const intro = 'পারমিট মানে লিখিত চুক্তি — নির্দিষ্ট লোক, নির্দিষ্ট জায়গা, নির্দিষ্ট সময়। প্রতিটা ঘর সাইটের সঙ্গে মিলিয়ে পড়ুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const ask = 'পারমিট মিলিয়ে দেখুন। কাজ শুরু করবেন?';
  static const formTitle = 'পারমিট-টু-ওয়ার্ক (PTW)';
  static const labels = {
    PtwField.number: 'পারমিট নং',
    PtwField.feeder: 'ফিডার',
    PtwField.place: 'স্থান',
    PtwField.job: 'কাজ',
    PtwField.name: 'কার নামে',
    PtwField.date: 'তারিখ',
    PtwField.time: 'সময়',
    PtwField.signature: 'স্বাক্ষর (কন্ট্রোল রুম)',
  };
  static String siteFeeder(PtwSite s) => 'পোলের ট্যাগ: ${s.feederBn}';
  static String sitePole(PtwSite s) => 'পোল নং ${enDigits('${s.pole}')}';
  static String you(PtwSite s) => 'আপনি: ${s.nameBn}';
  static String now(PtwSite s) => 'এখন ${s.nowBn} · ${_date(s.today)}';
  static const noSign = '— (ফাঁকা)';
  static const mismatch = 'মেলে না';
  static const stop = 'মেলে না — বন্ধ';
  static const start = 'মিলেছে — শুরু';
  static const flagFirst = 'যে ঘর মেলে না, আগে সেটায় ট্যাপ করুন।';
  static const next = 'পরেরটা';
  static const finish = 'ফলাফল';
  static const valid = 'বৈধ';
  static const phoneWho = 'কন্ট্রোল রুম (ফোনে)';
  static const phoneLine = 'লাইন বন্ধ করে দিয়েছি, তোমরা কাজ শুরু করো — কাগজ পরে পাঠাচ্ছি।';
  static const giveIn = 'ঠিক আছে, শুরু করি';
  static const holdOut = 'লিখিত পারমিট ছাড়া নয়';
  static const phoneHeld = 'ঠিক! মুখের কথায় লাইন বন্ধ নয় — কাগজ হাতে, তবে কাজ।';
  static const startOk = 'সব মিলেছে — কাজ শুরু, তবে আগে ডিসচার্জ আর টেস্ট।';
  static const stopOk = [FeedbackLine('ঠিক ধরেছেন — কাজ বন্ধ!'), FeedbackLine('চোখ এড়ায়নি!'), FeedbackLine('নিখুঁত মিলিয়েছেন।')];
  static const allSet = 'কাগজ মেলাতে পাকা! লেখা পারমিট হাতে, তবে লাইনে হাত।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ফিডার, পোল, নাম, সময়, স্বাক্ষর।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtPhone = 'ফোনের কথায় “না”';
  static const caughtFeeder = 'ফিডারের অমিল ধরেছেন';
  static const caughtTime = 'মেয়াদ পেরোনো পারমিট ধরেছেন';
  static const caughtSign = 'স্বাক্ষরহীন পারমিট ধরেছেন';
  static const caughtOther = 'পোল / নামের অমিল ধরেছেন';
  static const caughtValid = 'বৈধ পারমিট চিনেছেন';
  static const feeders = ['রামপুর 11 কেভি', 'হাটখোলা 11 কেভি', 'নদীপাড় 11 কেভি', 'স্টেশন রোড 11 কেভি', 'কলেজপাড়া 33 কেভি'];
  static const names = ['রফিক', 'সুজয়', 'আনোয়ার', 'বিকাশ', 'প্রদীপ', 'ইমরান'];
  static const jobs = ['ভাঙা ইনসুলেটর বদল', 'জাম্পার মেরামত', 'ক্রস-আর্ম বদল', 'ছেঁড়া তার জোড়া'];

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) => enDigits('${_two(d.day)}-${_two(d.month)}-${d.year}');
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
    textBn: 'কন্ট্রোল রুমের স্বাক্ষর নেই — এটা পারমিট নয়, শুধু একটা কাগজ।',
    art: 'assets/game/art/ptw/verbal_vs_written.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const expired = DoMistake(
    key: '1.6/ptw/expired',
    textBn: 'পারমিটের তারিখ বা সময় পেরিয়ে গেছে — মেয়াদ শেষে লাইন আবার চালু হতে পারে। কাজ থামিয়ে নতুন পারমিট নিন।',
    art: 'assets/game/art/ptw/permit_time.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wrongPlace = DoMistake(
    key: '1.6/ptw/wrong-place',
    textBn: 'পারমিটের পোল নম্বর আর সাইটের পোল মেলে না — পারমিট নির্দিষ্ট জায়গার জন্যই।',
    art: 'assets/game/art/ptw/feeder_match.svg',
    lessonPoint: 0,
  );
  static const wrongName = DoMistake(
    key: '1.6/ptw/wrong-name',
    textBn: 'পারমিট অন্যের নামে — নির্দিষ্ট লোকের জন্যই পারমিট। যে নেয়, সে-ই ফেরত দেয়।',
    art: 'assets/game/art/ptw/verbal_vs_written.svg',
    lessonPoint: 0,
  );
  static const falseStop = DoMistake(
    key: '1.6/ptw/false-stop',
    textBn: 'সব মিলেছিল — ফিডার, পোল, নাম, সময়, স্বাক্ষর। বৈধ পারমিটে কাজ আটকাবেন না।',
    art: 'assets/game/art/ptw/feeder_match.svg',
    lessonPoint: 1,
  );
  static const wrongField = DoMistake(
    key: '1.6/ptw/wrong-field',
    textBn: 'কাজ থামানো ঠিক ছিল — কিন্তু আসল অমিল অন্য ঘরে। প্রতিটি ঘর সাইটের সঙ্গে মিলিয়ে পড়ুন।',
    art: 'assets/game/art/ptw/feeder_match.svg',
    lessonPoint: 1,
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
/// phone call (never first). Site, names, feeders and numbers vary.
List<PtwRound> dealPermits(math.Random rng, DateTime today) {
  final feeders = [...PtwLines.feeders]..shuffle(rng);
  final names = [...PtwLines.names]..shuffle(rng);
  final faults = [PtwFault.feeder, PtwFault.place, PtwFault.name, rng.nextBool() ? PtwFault.expiredDate : PtwFault.expiredTime, PtwFault.unsigned]..shuffle(rng);
  final kinds = <PtwFault?>[PtwFault.none, faults[0], faults[1]]..shuffle(rng);
  kinds.insert(1 + rng.nextInt(3), null); // the phone call
  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) => enDigits('${two(d.day)}-${two(d.month)}-${d.year}');
  final rounds = <PtwRound>[];
  for (var i = 0; i < kinds.length; i++) {
    final site = PtwSite(
      feederBn: feeders[i % feeders.length],
      pole: 40 + rng.nextInt(40),
      nameBn: names[0],
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
        nameBn: k == PtwFault.name ? names[1] : site.nameBn,
        dateBn: k == PtwFault.expiredDate ? date(today.subtract(const Duration(days: 1))) : date(today),
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

  /// Start the work (true) or stop it with [flagged] as the mismatch.
  DoMistake? decide({required bool start, PtwField? flagged}) {
    final f = current.form;
    if (ended || shown || f == null) return null;
    shown = true;
    if (start) {
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
  const PtwPack({required this.id, required this.titleBn, this.quickMs = 100000});
  final String id;
  final String titleBn;
  final int quickMs;
}

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

class _PtwRunPageState extends ConsumerState<_PtwRunPage> with DoDeathGuard, DoStrikeOut {
  final _scoreKey = GlobalKey();
  late final PtwRun _run = PtwRun(dealPermits(widget.rng, widget.today));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _stopBag = LineBag(PtwLines.stopOk);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  PtwField? _flag;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk, bool other = false}) async {
    if (line.trim().isEmpty || !mounted) return;
    if (!other) ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted, rival: other);
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

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
  }

  void _roundStarted() {
    if (_run.current.phone) {
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
      unawaited(_say(PtwLines.phoneLine, other: true));
    } else {
      unawaited(_sayChain([PtwLines.ask]));
    }
  }

  bool get _idle => !_busy && !_ended && _card == null && !_run.shown;

  void _toggleFlag(PtwField f) {
    if (!_idle) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.45, muted: false));
    setState(() => _flag = _flag == f ? null : f);
  }

  Future<void> _decide(bool start, Offset origin) async {
    if (!_idle) return;
    if (!start && _flag == null) {
      HapticFeedback.selectionClick();
      ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: PtwLines.flagFirst);
      return;
    }
    _hush();
    final m = _run.decide(start: start, flagged: _flag);
    HapticFeedback.mediumImpact();
    setState(() {});
    await _after(m, origin, okLine: start ? PtwLines.startOk : _stopBag.next().shownBn);
  }

  Future<void> _answerPhone(bool held, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.answerPhone(held: held);
    setState(() {});
    await _after(m, origin, okLine: PtwLines.phoneHeld);
  }

  Future<void> _after(DoMistake? m, Offset origin, {required String okLine}) async {
    if (m == null) {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      unawaited(_levelDelta(15, origin, mood: GuideMood.glad));
      unawaited(_sayChain([okLine], mood: GuideMood.glad));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
    } else {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  void _next() {
    if (_busy || _card != null || !_run.shown) return;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _flag = null);
    _roundStarted();
  }

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
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('ptw/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    HapticFeedback.heavyImpact();
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
    if (!mounted) return;
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final r = _run.current;
    final shown = _run.shown;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Column(
                  children: [
                    LevelShellBar(
                      context_: widget.ctx,
                      titleBn: widget.pack.titleBn,
                      scoreKey: _scoreKey,
                      levelScore: _runScore,
                      muted: _muted,
                      onClose: () => unawaited(_leave()),
                      onToggleMute: () {
                        unawaited(MascotSpeechLibrary.stop());
                        setState(() => _muted = !_muted);
                      },
                    ),
                    DoProgress(
                      labels: PtwLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
                      current: _run.done ? null : _run.index,
                      quiet: quiet,
                    ),
                    const SizedBox(height: 8),
                    _SiteStrip(site: r.site),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: quiet ? Duration.zero : const Duration(milliseconds: 380),
                        transitionBuilder: (child, a) => SlideTransition(
                          position: Tween(begin: const Offset(0.25, 0), end: Offset.zero).animate(a),
                          child: FadeTransition(opacity: a, child: child),
                        ),
                        child: r.phone
                            ? _PhoneCard(
                                key: ValueKey('phone-${_run.index}'),
                                answered: shown,
                                onAnswer: (held, o) => unawaited(_answerPhone(held, o)),
                              )
                            : SingleChildScrollView(
                                key: ValueKey('form-${_run.index}'),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: _FormCard(form: r.form!, flag: _flag, reveal: shown, onTap: _toggleFlag),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: shown
                          ? SizedBox(
                              width: double.infinity,
                              child: DoBigButton(
                                label: _run.index >= _run.rounds.length - 1 ? PtwLines.finish : PtwLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                            )
                          : r.phone
                              ? const SizedBox(height: 52)
                              : Row(
                                  children: [
                                    Expanded(child: DoBigButton(label: PtwLines.stop, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                                    const SizedBox(width: 10),
                                    Expanded(child: DoBigButton(label: PtwLines.start, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                                  ],
                                ),
                    ),
                    Opacity(opacity: _card == null ? 1 : 0, child: DoCoachStrip(tasks: PtwLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
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
                          unawaited(openLessonPoint(context, ref,
                              lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                LevelIntro(
                  lines: [PtwLines.intro, PtwLines.ask],
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
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
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref,
                                    lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

/// The site: pole tag, who you are, the time now.
class _SiteStrip extends StatelessWidget {
  const _SiteStrip({required this.site});
  final PtwSite site;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92, minWidth: double.infinity),
          child: Stack(
            children: [
              Positioned.fill(child: SvgPicture.asset('assets/game/art/ptw/site_desk.svg', fit: BoxFit.cover)),
              const Positioned.fill(child: ColoredBox(color: Color(0x55050A16))),
              // Every fact the permit is checked against, never cut short.
              Padding(
                padding: const EdgeInsets.fromLTRB(70, 8, 10, 8),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _chip(Icons.sell_rounded, PtwLines.siteFeeder(site)),
                    _chip(Icons.location_on_rounded, PtwLines.sitePole(site)),
                    _chip(Icons.badge_rounded, PtwLines.you(site)),
                    _chip(Icons.schedule_rounded, PtwLines.now(site)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xE6FFF8E6), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF8C6A2A)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: SlmColors.ink)),
            ),
          ],
        ),
      );
}

/// The permit form; each row can be flagged as the mismatch.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.form, required this.flag, required this.reveal, required this.onTap});
  final PtwForm form;
  final PtwField? flag;
  final bool reveal;
  final ValueChanged<PtwField> onTap;

  @override
  Widget build(BuildContext context) {
    final bad = form.fault.field;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C7D5E), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_rounded, size: 18, color: Color(0xFF8C6A2A)),
              const SizedBox(width: 6),
              Expanded(child: Text(PtwLines.formTitle, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ink))),
              if (reveal && bad == null) const DoStamp(text: PtwLines.valid, good: true),
            ],
          ),
          const Divider(height: 14),
          for (final f in PtwField.values)
            _row(
              f,
              flagged: flag == f,
              wrong: reveal && bad == f,
            ),
        ],
      ),
    );
  }

  Widget _row(PtwField f, {required bool flagged, required bool wrong}) {
    final border = wrong ? SlmColors.danger : (flagged ? SlmColors.warning : Colors.transparent);
    return Semantics(
      button: true,
      label: PtwLines.labels[f],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(f),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: wrong ? const Color(0x1FC0392B) : (flagged ? const Color(0x1FE67E22) : null),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 112,
                child: Text(PtwLines.labels[f]!, style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
              ),
              Expanded(
                child: f == PtwField.signature
                    ? (form.signed
                        ? const SizedBox(height: 22, child: CustomPaint(painter: _SignaturePainter()))
                        : Text(PtwLines.noSign, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF9AA3AB))))
                    : Text(form.valueOf(f), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.ink)),
              ),
              if (flagged || wrong)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: wrong ? SlmColors.danger : SlmColors.warning, borderRadius: BorderRadius.circular(8)),
                  child: Text(PtwLines.mismatch, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter();

  @override
  void paint(Canvas c, Size s) {
    final h = s.height;
    final p = Path()
      ..moveTo(0, h * 0.7)
      ..quadraticBezierTo(10, 0, 18, h * 0.6)
      ..quadraticBezierTo(26, h, 34, h * 0.3)
      ..quadraticBezierTo(42, 0, 52, h * 0.65)
      ..quadraticBezierTo(60, h * 0.9, 74, h * 0.4);
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF2F6FD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => false;
}

/// No paper: only the control room's voice on the phone.
class _PhoneCard extends StatelessWidget {
  const _PhoneCard({super.key, required this.answered, required this.onAnswer});
  final bool answered;
  final void Function(bool held, Offset origin) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: SlmColors.danger, size: 38),
            const SizedBox(height: 6),
            Text(PtwLines.phoneWho, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
            const SizedBox(height: 8),
            Text(
              '“${PtwLines.phoneLine}”',
              textAlign: TextAlign.center,
              style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (!answered)
              Row(
                children: [
                  Expanded(child: DoBigButton(label: PtwLines.giveIn, filled: false, onTapUp: (d) => onAnswer(false, d.globalPosition))),
                  const SizedBox(width: 10),
                  Expanded(child: DoBigButton(label: PtwLines.holdOut, filled: true, onTapUp: (d) => onAnswer(true, d.globalPosition))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
