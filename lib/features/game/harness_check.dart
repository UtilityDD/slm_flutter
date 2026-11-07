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
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'spoken_once.dart';

// Lesson 1.4, কাজ 1: "তিন মিনিটের পরীক্ষা". Four harnesses hang in the store,
// one at a time. One is a waist belt (work positioning only — never fall
// arrest). For a full body harness do the 3-minute check: run a finger along
// the webbing (the phone buzzes at a cut, burn or chemical stain), look at
// the stitching and the metal parts, and read the label's expiry date
// against today. Then পরব or বাতিল. Once, a co-worker says "পুরনো হলেও
// মজবুত লাগছে".
//
// Deadly (owner-approved list: waist belt for fall arrest; frayed / expired
// harness): wearing the waist belt, or a harness with damaged webbing,
// broken stitching, cracked / rusted metal parts or an expired label.
// Slips: wearing a sound harness without all four checks; rejecting a
// sound harness.
//
// Voice: device TTS only. Art: assets/game/art/harness/ (hand-made SVG, no
// text inside); the harness, webbing, stitches, metal parts and label are
// drawn in code.

// ============================================================================
// Content
// ============================================================================

enum HarnessKind { fullBody, waistBelt }

enum HarnessFlaw { none, cut, burn, chemical, stitch, hardware, expired }

extension HarnessFlawFacts on HarnessFlaw {
  bool get onWebbing => this == HarnessFlaw.cut || this == HarnessFlaw.burn || this == HarnessFlaw.chemical;
}

@immutable
class HarnessItem {
  const HarnessItem({required this.id, required this.kind, required this.flaw, required this.webbingAt, required this.made, required this.expiry});
  final String id;
  final HarnessKind kind;
  final HarnessFlaw flaw;

  /// Where along the webbing (0–1) a cut / burn / stain sits.
  final double webbingAt;
  final DateTime made;
  final DateTime expiry;
  bool get sound => kind == HarnessKind.fullBody && flaw == HarnessFlaw.none;
}

@immutable
class HarnessDeal {
  const HarnessDeal({required this.items, required this.today, required this.pushIndex});
  final List<HarnessItem> items;
  final DateTime today;

  /// The harness the co-worker vouches for ("পুরনো হলেও মজবুত").
  final int pushIndex;
}

enum HarnessCheck { webbing, stitch, hardware, label }

abstract final class HarnessLines {
  static const title = 'তিন মিনিটের পরীক্ষা';
  static const intro = 'হারনেস আপনার প্যারাশুট। পরার আগে তিন মিনিট — ফিতে, সেলাই, ধাতব অংশ, লেবেল।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const ask = 'এই হারনেস পরে পোলে উঠবেন?';
  static String scene(DateTime today) => 'স্টোর রুম · আজ ${_date(today)}';
  static const checks = ['ফিতে', 'সেলাই', 'ধাতু', 'লেবেল'];
  static const wear = 'পরব';
  static const reject = 'বাতিল';
  static const next = 'পরেরটা';
  static const finish = 'ফলাফল';
  static const close = 'বন্ধ';
  static const slideHint = 'আঙুল দিয়ে পুরো ফিতে টেনে দেখুন';
  static const webbingOk = 'ফিতে ঠিক — কাটা, পোড়া, দাগ নেই।';
  static const cut = 'এখানে কাটা!';
  static const burn = 'পোড়া দাগ!';
  static const chemical = 'রাসায়নিকের দাগ!';
  static const stitchTitle = 'সেলাই';
  static const hardwareTitle = 'ডি-রিং আর বকলস';
  static const labelTitle = 'লেবেল';
  static String today(DateTime d) => 'আজ: ${_date(d)}';
  static String made(DateTime d) => 'তৈরি: ${_month(d)}';
  static String expiry(DateTime d) => 'মেয়াদ: ${_month(d)}';
  static const fullBodyName = 'ফুল বডি হারনেস · IS 3521';
  static const beltName = 'ওয়ার্ক পজিশনিং বেল্ট (কোমরের বেল্ট)';
  static const pushWho = 'সাথী';
  static const pushLine = 'পুরনো হলেও মজবুত লাগছে — এত দেখার কী আছে, পরে নাও!';
  static const giveIn = 'ঠিক, পরি';
  static const holdOut = 'না, আগে দেখি';
  static const callHeld = 'ঠিক! বাইরে মজবুত দেখালেও ফিতে ভেতর থেকে দুর্বল হয়।';
  static const right = [FeedbackLine('ঠিক সিদ্ধান্ত!'), FeedbackLine('তিন মিনিট — জীবন বাঁচায়।'), FeedbackLine('নিখুঁত!')];
  static const wearOk = 'সব ঠিক — পরে নিন।';
  static const rejectOk = 'ঠিক — বাতিল। সন্দেহ মানেই বাতিল।';
  static const allSet = 'তিন মিনিটের পরীক্ষা পাকা! ফিতে, সেলাই, ধাতব অংশ, লেবেল।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চারটে দেখা না করে পরবেন না।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtBelt = 'কোমরের বেল্ট দিয়ে পতন-সুরক্ষা নয়';
  static const caughtWebbing = 'আঙুল টেনে ফিতের ক্ষতি ধরেছেন';
  static const caughtExpired = 'মেয়াদ পেরোনো হারনেস বাতিল';
  static const caughtStitch = 'খোলা সেলাই / ভাঙা ধাতু ধরেছেন';
  static const caughtHabit = 'চারটে দেখে তবে পরেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) => enDigits('${_two(d.day)}-${_two(d.month)}-${d.year}');
  static String _month(DateTime d) => enDigits('${_two(d.month)}-${d.year}');
}

abstract final class HarnessMistakes {
  static const waistBelt = DoMistake(
    key: '1.4/harness/waist-belt',
    textBn: 'কোমরের বেল্ট শুধু ওয়ার্ক পজিশনিং-এর জন্য — পড়লে সব চাপ পেটে আর শিরদাঁড়ায়। পতন-সুরক্ষায় ফুল বডি হারনেস চাই।',
    art: 'assets/game/art/harness/belt_vs_harness.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const webbing = DoMistake(
    key: '1.4/harness/webbing',
    textBn: 'ফিতেয় কাটা / পোড়া / রাসায়নিকের দাগ — ছোট্ট ক্ষতিও হারনেসের শক্তি অর্ধেক করে দেয়। এমন হারনেস বাতিল।',
    art: 'assets/game/art/harness/webbing_damage.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const stitch = DoMistake(
    key: '1.4/harness/stitch',
    textBn: 'সেলাই খুলে গেছে — ভার পড়লে ওখান থেকেই ছিঁড়বে। খোলা সেলাই মানে হারনেস বাতিল।',
    art: 'assets/game/art/harness/stitch_hardware.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const hardware = DoMistake(
    key: '1.4/harness/hardware',
    textBn: 'ডি-রিং / বকলসে ফাটল আর মরিচা — পতনের ঝাঁকুনিতে ভেঙে যেতে পারে। এমন হারনেস বাতিল।',
    art: 'assets/game/art/harness/stitch_hardware.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const expired = DoMistake(
    key: '1.4/harness/expired',
    textBn: 'লেবেলের মেয়াদ পেরিয়ে গেছে — রোদে ফিতে ভেতর থেকে দুর্বল হয়, বাইরে বোঝা যায় না। মেয়াদ উত্তীর্ণ হারনেস নয়।',
    art: 'assets/game/art/harness/harness_label.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const skipped = DoMistake(
    key: '1.4/harness/skipped-check',
    textBn: 'হারনেস ঠিক ছিল — কিন্তু চারটে দেখা না করেই পরলেন। ফিতে, সেলাই, ধাতব অংশ, লেবেল — প্রতিবার।',
    art: 'assets/game/art/harness/three_minute.svg',
    lessonPoint: 1,
  );
  static const goodRejected = DoMistake(
    key: '1.4/harness/good-rejected',
    textBn: 'এই হারনেসটা ঠিক ছিল — ফিতে, সেলাই, ধাতু, মেয়াদ সব ঠিক। দেখে-শুনে সিদ্ধান্ত নিন।',
    art: 'assets/game/art/harness/three_minute.svg',
    lessonPoint: 1,
  );
  static DoMistake forFlaw(HarnessItem h) => h.kind == HarnessKind.waistBelt
      ? waistBelt
      : switch (h.flaw) {
          HarnessFlaw.cut || HarnessFlaw.burn || HarnessFlaw.chemical => webbing,
          HarnessFlaw.stitch => stitch,
          HarnessFlaw.hardware => hardware,
          HarnessFlaw.expired => expired,
          HarnessFlaw.none => skipped,
        };
  static const all = [waistBelt, webbing, stitch, hardware, expired, skipped, goodRejected];
}

/// Four harnesses: the waist belt, one sound harness, two damaged ones (one
/// of them often expired); dates are real dates around [today].
HarnessDeal dealHarnesses(math.Random rng, DateTime today) {
  DateTime months(int m) => DateTime(today.year, today.month + m, 1);
  var n = 0;
  HarnessItem item(HarnessKind k, HarnessFlaw f) {
    final expired = f == HarnessFlaw.expired;
    final exp = expired ? months(-(1 + rng.nextInt(18))) : months(6 + rng.nextInt(30));
    return HarnessItem(
      id: 'h${n++}',
      kind: k,
      flaw: f,
      webbingAt: 0.2 + rng.nextDouble() * 0.6,
      made: DateTime(exp.year - 5, exp.month, 1),
      expiry: exp,
    );
  }

  final flaws = [HarnessFlaw.cut, HarnessFlaw.burn, HarnessFlaw.chemical, HarnessFlaw.stitch, HarnessFlaw.hardware]..shuffle(rng);
  final second = rng.nextInt(3) < 2 ? HarnessFlaw.expired : flaws[1];
  final items = [
    item(HarnessKind.waistBelt, HarnessFlaw.none),
    item(HarnessKind.fullBody, HarnessFlaw.none),
    item(HarnessKind.fullBody, flaws[0]),
    item(HarnessKind.fullBody, second),
  ]..shuffle(rng);
  final pushed = items.indexWhere((h) => h.flaw == HarnessFlaw.expired);
  return HarnessDeal(
    items: items,
    today: today,
    pushIndex: pushed >= 0 ? pushed : items.indexWhere((h) => h.kind == HarnessKind.fullBody && h.flaw != HarnessFlaw.none),
  );
}

/// The play state (pure logic).
class HarnessRun {
  HarnessRun(this.deal);
  final HarnessDeal deal;
  int index = 0;
  final Set<HarnessCheck> checks = {};
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.items.length;
  bool get ended => done || deadly != null;
  HarnessItem get current => deal.items[index.clamp(0, deal.items.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void check(HarnessCheck c) {
    if (!ended && !shown) checks.add(c);
  }

  DoMistake? decide({required bool wear}) {
    if (ended || shown) return null;
    shown = true;
    final h = current;
    void tag(String t) {
      if (!caught.contains(t)) caught.add(t);
    }

    if (wear) {
      if (!h.sound) return deadly = HarnessMistakes.forFlaw(h);
      if (!checks.containsAll(HarnessCheck.values)) {
        slips++;
        return HarnessMistakes.skipped;
      }
      tag(HarnessLines.caughtHabit);
      return null;
    }
    if (h.sound) {
      slips++;
      return HarnessMistakes.goodRejected;
    }
    if (h.kind == HarnessKind.waistBelt) {
      tag(HarnessLines.caughtBelt);
    } else if (h.flaw.onWebbing) {
      tag(HarnessLines.caughtWebbing);
    } else if (h.flaw == HarnessFlaw.expired) {
      tag(HarnessLines.caughtExpired);
    } else {
      tag(HarnessLines.caughtStitch);
    }
    return null;
  }

  void next() {
    index++;
    checks.clear();
    shown = false;
  }
}

@immutable
class HarnessPack {
  const HarnessPack({required this.id, required this.titleBn, this.quickMs = 120000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const harnessPack14 = HarnessPack(id: 'do_1_4_a', titleBn: HarnessLines.title);
const harnessPacks = {'do_1_4_a': harnessPack14};

// ============================================================================
// Page
// ============================================================================

class HarnessCheckPage extends StatefulWidget {
  const HarnessCheckPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.today});

  final LevelContext ctx;
  final HarnessPack pack;
  final bool muted;
  final int? seed;

  /// Tests: a fixed "today" for the label dates.
  final DateTime? today;

  @override
  State<HarnessCheckPage> createState() => _HarnessCheckPageState();
}

class _HarnessCheckPageState extends State<HarnessCheckPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) {
    final now = widget.today ?? DateTime.now();
    return _HarnessRunPage(
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

class _HarnessRunPage extends ConsumerStatefulWidget {
  const _HarnessRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.today, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final HarnessPack pack;
  final bool muted;
  final DateTime today;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HarnessRunPage> createState() => _HarnessRunPageState();
}

enum _Panel { none, webbing, stitch, hardware, label }

class _HarnessRunPageState extends ConsumerState<_HarnessRunPage> with DoDeathGuard {
  final _scoreKey = GlobalKey();
  late final HarnessRun _run = HarnessRun(dealHarnesses(widget.rng, widget.today));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _rightBag = LineBag(HarnessLines.right);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  int _chain = 0;
  _Panel _panel = _Panel.none;
  var _callOpen = false;
  var _callDone = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
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

  Future<void> _start() async {
    _clock.start();
    await _sayChain([HarnessLines.intro, HarnessLines.ask]);
  }

  bool get _idle => !_busy && !_ended && !_callOpen && _card == null && !_run.shown && _panel == _Panel.none;

  void _open(_Panel p) {
    if (!_idle) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.4, muted: false));
    _hush();
    setState(() => _panel = p);
    switch (p) {
      case _Panel.stitch:
        _run.check(HarnessCheck.stitch);
      case _Panel.hardware:
        _run.check(HarnessCheck.hardware);
      case _Panel.label:
        _run.check(HarnessCheck.label);
      case _Panel.webbing || _Panel.none:
        break;
    }
  }

  void _closePanel() {
    if (_panel == _Panel.none) return;
    setState(() => _panel = _Panel.none);
    // After the first look at the vouched-for harness, the push comes.
    if (!_callDone && _run.index == _run.deal.pushIndex && _run.checks.isNotEmpty && !_run.shown) {
      _hush();
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
      setState(() => _callOpen = true);
      unawaited(_say(HarnessLines.pushLine, other: true));
    }
  }

  void _webbingDone() {
    _run.check(HarnessCheck.webbing);
    setState(() {});
  }

  Future<void> _answerCall(bool held, Offset origin) async {
    if (!_callOpen) return;
    _hush();
    setState(() {
      _callOpen = false;
      _callDone = true;
    });
    if (!held) {
      await _decide(true, origin);
      return;
    }
    _run.caught.add(HarnessLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([HarnessLines.callHeld], mood: GuideMood.glad));
  }

  Future<void> _decide(bool wear, Offset origin) async {
    if (_busy || _ended || _card != null || _run.shown) return;
    _hush();
    final m = _run.decide(wear: wear);
    HapticFeedback.mediumImpact();
    setState(() => _panel = _Panel.none);
    if (m == null) {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      final bonus = _run.checks.length == 4 ? 5 : 0;
      unawaited(_levelDelta(15 + bonus, origin, mood: GuideMood.glad));
      unawaited(_sayChain([wear ? HarnessLines.wearOk : HarnessLines.rejectOk, _rightBag.next().shownBn], mood: GuideMood.glad));
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
    setState(() => _panel = _Panel.none);
    unawaited(_sayChain([HarnessLines.ask]));
  }

  Future<void> _slip(DoMistake m) async {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('harness/${m.key}');
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
    final speak = await SpokenOnce.first('harness/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? HarnessLines.deadlyWord : HarnessLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? HarnessLines.fail : (_quickBonus ? HarnessLines.quick : HarnessLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_panel != _Panel.none) {
      _closePanel();
      return;
    }
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
    final h = _run.current;
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
                      labels: HarnessLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
                      current: _run.done ? null : _run.index,
                      quiet: quiet,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Text(HarnessLines.scene(widget.today),
                          style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold200)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 360,
                              height: 480,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: SvgPicture.asset('assets/game/art/harness/store_wall.svg', fit: BoxFit.fill)),
                                  Positioned.fill(
                                    child: AnimatedSwitcher(
                                      duration: quiet ? Duration.zero : const Duration(milliseconds: 360),
                                      transitionBuilder: (child, a) => SlideTransition(
                                        position: Tween(begin: const Offset(0, -0.3), end: Offset.zero).animate(a),
                                        child: FadeTransition(opacity: a, child: child),
                                      ),
                                      child: CustomPaint(key: ValueKey(h.id), painter: HarnessPainter(h), size: const Size(360, 480)),
                                    ),
                                  ),
                                  if (shown && !h.sound)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 60,
                                      child: Center(child: DoStamp(text: HarnessLines.reject, good: false)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!shown)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
                          children: [
                            for (final (i, p) in const [(0, _Panel.webbing), (1, _Panel.stitch), (2, _Panel.hardware), (3, _Panel.label)])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: _CheckButton(
                                    label: HarnessLines.checks[i],
                                    done: _run.checks.contains(HarnessCheck.values[i]),
                                    onTap: () => _open(p),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: shown
                          ? SizedBox(
                              width: double.infinity,
                              child: DoBigButton(
                                label: _run.index >= _run.deal.items.length - 1 ? HarnessLines.finish : HarnessLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(child: DoBigButton(label: HarnessLines.reject, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                                const SizedBox(width: 10),
                                Expanded(child: DoBigButton(label: HarnessLines.wear, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                              ],
                            ),
                    ),
                    Opacity(opacity: _card == null && !_callOpen && _panel == _Panel.none ? 1 : 0, child: const DoCoachStrip()),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_panel != _Panel.none)
                _InspectPanel(
                  key: ValueKey('panel-$_panel-${h.id}'),
                  panel: _panel,
                  item: h,
                  today: widget.today,
                  quiet: quiet,
                  muted: _muted,
                  onWebbingDone: _webbingDone,
                  onClose: _closePanel,
                ),
              if (_callOpen)
                DoCallCard(
                  caller: const DoCaller(id: 'push', whoBn: HarnessLines.pushWho, lineBn: HarnessLines.pushLine, icon: Icons.record_voice_over_rounded),
                  quiet: quiet,
                  rushBn: HarnessLines.giveIn,
                  holdBn: HarnessLines.holdOut,
                  onAnswer: (held, o) => unawaited(_answerCall(held, o)),
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

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.label, required this.done, required this.onTap});
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: done ? const Color(0xFF2E8B45) : const Color(0x22FFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: done ? 0 : 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(done ? Icons.check_rounded : Icons.search_rounded, size: 14, color: SlmColors.ivory),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four close looks: finger along the webbing, stitches, metal parts, label.
class _InspectPanel extends StatefulWidget {
  const _InspectPanel({
    super.key,
    required this.panel,
    required this.item,
    required this.today,
    required this.quiet,
    required this.muted,
    required this.onWebbingDone,
    required this.onClose,
  });
  final _Panel panel;
  final HarnessItem item;
  final DateTime today;
  final bool quiet;
  final bool muted;
  final VoidCallback onWebbingDone;
  final VoidCallback onClose;

  @override
  State<_InspectPanel> createState() => _InspectPanelState();
}

class _InspectPanelState extends State<_InspectPanel> {
  double? _finger;
  double _lo = 1;
  double _hi = 0;
  var _found = false;
  var _covered = false;

  void _slide(double u) {
    final v = u.clamp(0.0, 1.0);
    // A fast finger jumps between touch points: the fault is felt if it lies
    // anywhere between the last point and this one.
    final from = _finger ?? v;
    setState(() {
      _finger = v;
      _lo = math.min(_lo, v);
      _hi = math.max(_hi, v);
    });
    final h = widget.item;
    final passed = h.webbingAt >= math.min(from, v) - 0.045 && h.webbingAt <= math.max(from, v) + 0.045;
    if (!_found && h.flaw.onWebbing && passed) {
      HapticFeedback.heavyImpact();
      if (!widget.muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.5, muted: false));
      setState(() => _found = true);
    } else if ((v * 20).floor() != (from * 20).floor()) {
      HapticFeedback.selectionClick();
    }
    if (!_covered && _hi - _lo > 0.85) {
      _covered = true;
      widget.onWebbingDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.item;
    final (title, body) = switch (widget.panel) {
      _Panel.webbing => (HarnessLines.slideHint, _webbing(h)),
      _Panel.stitch => (HarnessLines.stitchTitle, SizedBox(height: 160, child: CustomPaint(painter: _StitchPainter(broken: h.flaw == HarnessFlaw.stitch, belt: h.kind == HarnessKind.waistBelt)))),
      _Panel.hardware => (HarnessLines.hardwareTitle, SizedBox(height: 160, child: CustomPaint(painter: _HardwarePainter(broken: h.flaw == HarnessFlaw.hardware)))),
      _Panel.label => (HarnessLines.labelTitle, _label(h)),
      _Panel.none => ('', const SizedBox()),
    };
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: ColoredBox(
          color: const Color(0xC0050A16),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Transform.scale(scale: 0.9 + 0.1 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ink)),
                      const SizedBox(height: 10),
                      body,
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: DoBigButton(label: HarnessLines.close, filled: true, onTapUp: (_) => widget.onClose()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webbing(HarnessItem h) {
    final word = switch (h.flaw) {
      HarnessFlaw.cut => HarnessLines.cut,
      HarnessFlaw.burn => HarnessLines.burn,
      _ => HarnessLines.chemical,
    };
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) => Semantics(
            label: 'ফিতে',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _slide(d.localPosition.dx / c.maxWidth),
              onPanUpdate: (d) => _slide(d.localPosition.dx / c.maxWidth),
              child: SizedBox(
                height: 96,
                width: c.maxWidth,
                child: CustomPaint(painter: _WebbingPainter(item: h, finger: _finger, found: _found, lo: _lo, hi: _hi)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 22,
          child: Text(
            _found ? word : (_covered ? HarnessLines.webbingOk : ''),
            style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: _found ? SlmColors.danger : const Color(0xFF2E8B45)),
          ),
        ),
      ],
    );
  }

  Widget _label(HarnessItem h) {
    final belt = h.kind == HarnessKind.waistBelt;
    return Column(
      children: [
        Text(HarnessLines.today(widget.today), style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF5A6478))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF31363C), width: 1.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(belt ? HarnessLines.beltName : HarnessLines.fullBodyName,
                  style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ink)),
              const SizedBox(height: 6),
              Text(HarnessLines.made(h.made), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ink)),
              Text(HarnessLines.expiry(h.expiry), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ink)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The harness hanging from the store hook (or the waist belt).
class HarnessPainter extends CustomPainter {
  HarnessPainter(this.item);
  final HarnessItem item;

  static const _web = Color(0xFFE67E22);
  static const _webDark = Color(0xFFB85C12);
  static const _metal = Color(0xFF8D949B);

  @override
  void paint(Canvas c, Size s) {
    final strap = Paint()
      ..color = _web
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = _webDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final metal = Paint()
      ..color = _metal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    const hook = Offset(190, 74);
    if (item.kind == HarnessKind.waistBelt) {
      // A wide belt hanging as a loop, buckle in front, short lanyard.
      final loop = Path()
        ..moveTo(hook.dx, hook.dy)
        ..cubicTo(90, 140, 100, 300, 180, 300)
        ..cubicTo(260, 300, 290, 140, hook.dx, hook.dy);
      c.drawPath(loop, strap..strokeWidth = 26);
      c.drawPath(loop, edge);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(180, 300), width: 40, height: 30), const Radius.circular(5)), metal);
      c.drawPath(
        Path()
          ..moveTo(150, 296)
          ..quadraticBezierTo(140, 360, 168, 392),
        Paint()
          ..color = const Color(0xFF3B6EA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
      c.drawPath(
        Path()
          ..moveTo(168, 392)
          ..lineTo(168, 410)
          ..quadraticBezierTo(168, 424, 180, 424)
          ..quadraticBezierTo(192, 424, 192, 412),
        metal,
      );
      return;
    }
    // Full body harness: back D-ring at the hook, two shoulder straps down to
    // the chest strap, waist, leg loops.
    final l = Path()
      ..moveTo(hook.dx - 4, hook.dy + 18)
      ..quadraticBezierTo(140, 160, 150, 240)
      ..lineTo(156, 310);
    final r = Path()
      ..moveTo(hook.dx + 4, hook.dy + 18)
      ..quadraticBezierTo(240, 160, 230, 240)
      ..lineTo(224, 310);
    for (final p in [l, r]) {
      c.drawPath(p, strap..strokeWidth = 12);
      c.drawPath(p, edge);
    }
    // Chest strap with buckle.
    c.drawLine(const Offset(146, 200), const Offset(234, 200), strap);
    c.drawRect(Rect.fromCenter(center: const Offset(190, 200), width: 22, height: 16), Paint()..color = const Color(0xFF2B2F35));
    // Waist / sub-pelvic.
    c.drawLine(const Offset(150, 310), const Offset(230, 310), strap);
    // Leg loops.
    for (final x in const [160.0, 220.0]) {
      final loop = Path()
        ..moveTo(x - 4, 312)
        ..quadraticBezierTo(x - 30, 370, x, 396)
        ..quadraticBezierTo(x + 30, 370, x + 4, 312);
      c.drawPath(loop, strap..strokeWidth = 10);
      c.drawRect(Rect.fromCenter(center: Offset(x, 396), width: 16, height: 12), Paint()..color = const Color(0xFF2B2F35));
    }
    // Back D-ring.
    c.drawPath(
      Path()
        ..moveTo(hook.dx - 12, hook.dy + 22)
        ..quadraticBezierTo(hook.dx - 12, hook.dy - 4, hook.dx, hook.dy - 4)
        ..quadraticBezierTo(hook.dx + 12, hook.dy - 4, hook.dx + 12, hook.dy + 22)
        ..close(),
      metal,
    );
    // Label tag on the left strap.
    c.drawRect(const Rect.fromLTWH(128, 236, 18, 26), Paint()..color = Colors.white);
    c.drawRect(
      const Rect.fromLTWH(128, 236, 18, 26),
      Paint()
        ..color = const Color(0xFF31363C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(HarnessPainter old) => old.item != item;
}

/// A long strip of webbing, the fingertip on it, and (if any) the damage.
class _WebbingPainter extends CustomPainter {
  _WebbingPainter({required this.item, required this.finger, required this.found, required this.lo, required this.hi});
  final HarnessItem item;
  final double? finger;
  final bool found;
  final double lo;
  final double hi;

  @override
  void paint(Canvas c, Size s) {
    final top = s.height * 0.3;
    final h = s.height * 0.42;
    final strip = Rect.fromLTWH(0, top, s.width, h);
    final belt = item.kind == HarnessKind.waistBelt;
    c.drawRect(strip, Paint()..color = belt ? const Color(0xFF3B6EA8) : const Color(0xFFE67E22));
    final weave = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var y = top + 4; y < top + h; y += 5) {
      c.drawLine(Offset(0, y), Offset(s.width, y), weave);
    }
    // Already felt: a faint trace.
    if (hi > lo) {
      c.drawRect(Rect.fromLTRB(lo * s.width, top + h + 4, hi * s.width, top + h + 7), Paint()..color = const Color(0x882E8B45));
    }
    if (item.flaw.onWebbing) {
      final x = item.webbingAt * s.width;
      switch (item.flaw) {
        case HarnessFlaw.cut:
          c.drawPath(
            Path()
              ..moveTo(x - 5, top)
              ..lineTo(x, top + h * 0.45)
              ..lineTo(x + 5, top)
              ..close(),
            Paint()..color = SlmColors.ivory,
          );
          final fray = Paint()
            ..color = const Color(0xFFB85C12)
            ..strokeWidth = 1;
          c.drawLine(Offset(x - 1, top + h * 0.4), Offset(x - 6, top + h * 0.6), fray);
          c.drawLine(Offset(x + 2, top + h * 0.38), Offset(x + 7, top + h * 0.55), fray);
        case HarnessFlaw.burn:
          c.drawOval(Rect.fromCenter(center: Offset(x, top + h / 2), width: 16, height: 11), Paint()..color = const Color(0xFF4A2C12));
          c.drawOval(Rect.fromCenter(center: Offset(x, top + h / 2), width: 7, height: 5), Paint()..color = const Color(0xFF1F130A));
        default:
          c.drawOval(Rect.fromCenter(center: Offset(x, top + h / 2), width: 30, height: h * 0.8), Paint()..color = const Color(0x99C9B04A));
      }
      if (found) {
        c.drawCircle(
          Offset(x, top + h / 2),
          h * 0.9,
          Paint()
            ..color = SlmColors.danger
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
    final f = finger;
    if (f != null) {
      final fx = f * s.width;
      c.drawCircle(Offset(fx, top + h / 2), 15, Paint()..color = const Color(0xCCF0C9A0));
      c.drawCircle(
        Offset(fx, top + h / 2),
        15,
        Paint()
          ..color = found && (f - item.webbingAt).abs() < 0.06 ? SlmColors.danger : const Color(0xFF5A4636)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_WebbingPainter old) => old.finger != finger || old.found != found || old.lo != lo || old.hi != hi;
}

class _StitchPainter extends CustomPainter {
  _StitchPainter({required this.broken, required this.belt});
  final bool broken;
  final bool belt;

  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.8, height: s.height * 0.7);
    c.drawRect(r, Paint()..color = belt ? const Color(0xFF3B6EA8) : const Color(0xFFE67E22));
    c.drawRect(Rect.fromLTWH(r.left, r.center.dy - 2, r.width, 4), Paint()..color = const Color(0x33000000));
    final thread = Paint()
      ..color = const Color(0xFF2B2015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    const n = 8;
    final step = r.width / n;
    for (var i = 0; i < n; i++) {
      final x0 = r.left + i * step;
      final gap = broken && (i == 4 || i == 5);
      if (gap) {
        // Pulled, broken loops hanging loose.
        c.drawPath(
          Path()
            ..moveTo(x0, r.top + 10)
            ..quadraticBezierTo(x0 + step * 0.3, r.top - 8, x0 + step * 0.5, r.top + 14),
          thread,
        );
        c.drawLine(Offset(x0 + step * 0.7, r.bottom - 10), Offset(x0 + step * 0.9, r.bottom + 10), thread);
        continue;
      }
      c.drawLine(Offset(x0, r.top + 10), Offset(x0 + step / 2, r.bottom - 10), thread);
      c.drawLine(Offset(x0 + step / 2, r.bottom - 10), Offset(x0 + step, r.top + 10), thread);
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) => old.broken != broken || old.belt != belt;
}

class _HardwarePainter extends CustomPainter {
  _HardwarePainter({required this.broken});
  final bool broken;

  @override
  void paint(Canvas c, Size s) {
    final metal = Paint()
      ..color = broken ? const Color(0xFF8A7A6A) : const Color(0xFF9AA3AB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final cx = s.width * 0.32;
    final ring = Path()
      ..moveTo(cx - 34, s.height * 0.72)
      ..lineTo(cx - 34, s.height * 0.42)
      ..quadraticBezierTo(cx - 34, s.height * 0.12, cx, s.height * 0.12)
      ..quadraticBezierTo(cx + 34, s.height * 0.12, cx + 34, s.height * 0.42)
      ..lineTo(cx + 34, s.height * 0.72)
      ..close();
    c.drawPath(ring, metal);
    // Buckle.
    final bx = s.width * 0.72;
    final b = Rect.fromCenter(center: Offset(bx, s.height * 0.45), width: 70, height: 46);
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(6)), metal..strokeWidth = 8);
    c.drawLine(Offset(b.center.dx, b.top + 4), Offset(b.center.dx, b.bottom - 4), metal..strokeWidth = 6);
    if (broken) {
      c.drawPath(
        Path()
          ..moveTo(cx + 18, s.height * 0.12)
          ..lineTo(cx + 26, s.height * 0.2)
          ..lineTo(cx + 22, s.height * 0.27)
          ..lineTo(cx + 32, s.height * 0.32),
        Paint()
          ..color = const Color(0xFF2B2015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      final rust = Paint()..color = const Color(0xFFA0522D);
      for (final o in [Offset(cx - 34, s.height * 0.55), Offset(cx + 34, s.height * 0.62), Offset(bx - 30, s.height * 0.4), Offset(bx + 28, s.height * 0.55)]) {
        c.drawCircle(o, 5, rust);
      }
    }
  }

  @override
  bool shouldRepaint(_HardwarePainter old) => old.broken != broken;
}
