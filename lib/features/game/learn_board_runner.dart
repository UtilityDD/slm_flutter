import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../home/lesson_progress_store.dart';
import '../home/lesson_reader_page.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_board_deal.dart';
import 'learn_board_models.dart';
import 'learn_feedback_lines.dart';
import 'lesson_day_card.dart';
import 'lesson_promise_card.dart';
import 'spoken_once.dart';
import 'level_result_parts.dart';
import 'read_lesson_offer.dart';
import 'gesture_hint.dart';
import 'myth_rival_puppet.dart';

/// Learn choice-board: mission-first → PickGear → pending ◆ → Why → MythRival.
/// Never a fall. Premium chrome + staged scenes + score motion.
class LearnBoardRunnerPage extends StatefulWidget {
  final String rungId;
  final String lessonId;
  final int ladderIndex;
  final LearnBoardPack pack;
  final bool muted;

  const LearnBoardRunnerPage({
    super.key,
    required this.rungId,
    required this.lessonId,
    required this.ladderIndex,
    required this.pack,
    this.muted = false,
  });

  @override
  State<LearnBoardRunnerPage> createState() => _LearnBoardRunnerPageState();
}

/// "আবার খেলুন" after a fail starts a fresh run on the same route, so the
/// ladder keeps waiting for this level's real result.
class _LearnBoardRunnerPageState extends State<LearnBoardRunnerPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) {
    return _LearnBoardRun(
      key: ValueKey(_round),
      rungId: widget.rungId,
      ladderIndex: widget.ladderIndex,
      pack: widget.pack,
      muted: _muted,
      onRetry: (muted) => setState(() {
        _muted = muted;
        _round++;
      }),
    );
  }
}

class _LearnBoardRun extends ConsumerStatefulWidget {
  final String rungId;
  final int ladderIndex;
  final LearnBoardPack pack;
  final bool muted;
  final ValueChanged<bool> onRetry;

  const _LearnBoardRun({
    required this.ladderIndex,
    super.key,
    required this.rungId,
    required this.pack,
    required this.muted,
    required this.onRetry,
  });

  @override
  ConsumerState<_LearnBoardRun> createState() => _LearnBoardRunState();
}

enum _Beat { intro, pick, why, mythSay, mythBelieve, mythWhy, award, done }

/// A board card opened for a closer look: the item, its place on the board
/// (the reason's number) and where it was tapped (where the ◆ fly from).
class _Look {
  const _Look({required this.item, required this.index, required this.origin});
  final LearnPick item;
  final int index;
  final Offset origin;
}

/// Feedback for a confirmed card: the right/wrong word, the card's name (a
/// picture card) and the reason. It stays until "এগিয়ে যান".
class _Verdict {
  const _Verdict({required this.good, required this.headline, this.name = '', this.body = ''});
  final bool good;
  final String headline;
  final String name;
  final String body;
}

class _LearnBoardRunState extends ConsumerState<_LearnBoardRun>
    with TickerProviderStateMixin {
  final _scoreKey = GlobalKey();
  final _pendingDockKey = GlobalKey();

  late final AnimationController _celebrate;
  late final AnimationController _burn;
  late final AnimationController _rivalEnter;
  late final AnimationController _rivalBob;
  late final AnimationController _rivalExit;
  late final AnimationController _rivalJab;
  late final AnimationController _stageShake;
  late final AnimationController _scorePunch;

  /// "Read the lesson" card: 0 = tucked into the পাঠ pill, 1 = open over the board.
  late final AnimationController _readFly;
  late final CurvedAnimation _readCurve;
  final _readPillKey = GlobalKey();
  final _boardKey = GlobalKey();

  /// Reason chips on the why board, for the sweep hint. Keyed by
  /// beat-slot-wave-chip so an outgoing board (still fading in the stage
  /// switcher) never shares a key with the incoming one.
  final _whyKeys = <String, GlobalKey>{};
  Offset _readFrom = Offset.zero;
  var _readOpen = false;
  var _readAtStart = false;
  ReadNudge? _readNudge;
  Completer<void>? _endOfferDone;

  /// An answer is being handled: a second tap (double tap, yes-then-no) is ignored.
  var _busy = false;

  /// This run asks the reversed myth question ("সেটা কি ভুল?").
  final bool _askFlipped = math.Random().nextBool();
  String get _sting => _askFlipped ? _pack.myth.flipStingBn : _pack.myth.stingBn;

  /// Set once the clear is saved: leaving now still counts as a pass.
  var _passed = false;
  var _popped = false;

  _Beat _beat = _Beat.intro;
  int _slot = 0;
  int _pending = 0;
  int _pendingFxToken = 0;
  String? _pickedWhy;
  bool _muted = false;

  /// True while a scripted moment plays (feedback, transitions, the rival
  /// cutscene). Choices and mascot taps are ignored; prompts never lock.
  bool _locked = false;
  int _voiceRun = 0;
  var _whyRetry = false;
  var _burning = false;
  int _rivalLayers = 0;
  var _rivalDefeated = false;
  var _rivalOnStage = false;

  /// Rival owns the voice: [RivalTalk] drives his snarl instead of the coach.
  var _rivalVoice = false;
  String _rivalBubbleBn = '';
  var _askReady = false;
  int _rivalLandToken = 0;
  var _tagsShown = false;
  int _cardWave = 0;

  /// Last tapped card: it shakes (wrong) or pops (right) on each new token.
  String? _hitId;
  var _hitGood = false;
  int _hitToken = 0;

  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _againBag = LineBag(LearnFeedbackLines.wrongAgain);
  final _rightBag = LineBag(LearnFeedbackLines.right);
  final _pickAskBag = LineBag(LearnFeedbackLines.pickAsk);
  final _whyAskBag = LineBag(LearnFeedbackLines.whyAsk);
  final _mythAskBag = LineBag(LearnFeedbackLines.mythWhyAsk);

  /// The question last asked on this board (repeated when the coach is tapped).
  String _ask = '';
  int _missStreak = 0;
  var _readHot = false;
  var _openingLesson = false;

  /// First-try mark for the pass line, and whether the read card came up this run.
  final _marks = LessonMarks();
  var _readShown = false;
  var _failed = false;
  int? _runMark;
  late final ({int plays, int? best, int? ms}) _history;

  /// This play's level score. Every ◆ won or lost flies into it; when the
  /// level ends it replaces this level's last score in the main ◆.
  int _runScore = 0;

  /// Decision clock: runs only while the player can answer (never during
  /// scripted beats or with the app hidden). Counts up; it never ends a level.
  final _levelClock = Stopwatch();
  final _choiceClock = Stopwatch();
  final _clockSec = ValueNotifier<int>(0);
  Timer? _clockTimer;
  var _clockWanted = false;
  late final AppLifecycleListener _life;
  int? _finalMs;
  int? _bestMs;
  var _newRecord = false;
  List<LearnBoardOption> _pickOpts = const [];
  List<LearnWhyChip> _whyOpts = const [];
  final _dealer = LearnDealer();

  /// Ids already on the table for the current question (never swapped back in).
  final Set<String> _seen = {};

  /// The card opened for a closer look (null = none). A tap on a card only
  /// opens it; ✓ (বেছে নিন) runs the pick, ✕ (বাদ দিন) sets it aside.
  _Look? _look;

  /// One-shot opening pop of the look; its buttons wait until it has landed.
  late final AnimationController _lookIn;

  /// One-shot pop (right) or shake (wrong) of the look once confirmed.
  late final AnimationController _lookHit;
  var _lookReady = false;

  /// Cards set aside with ✕ on the board on screen ('beat-wave-id').
  final Set<String> _aside = {};

  /// What the confirmed pick earned: shown under the card until Continue.
  _Verdict? _verdict;
  Completer<void>? _verdictDone;
  Timer? _continueArm;
  var _continueArmed = false;
  final _confirmKey = GlobalKey();
  final _rejectKey = GlobalKey();

  LearnBoardPack get _pack => widget.pack;
  LearnBoardSlot get _cur => _pack.slots[_slot];

  bool get _missionHero => _beat == _Beat.intro || _beat == _Beat.award || _beat == _Beat.done;

  /// Card boards reserve a top lane for step pips and the pending ◆ chip.
  bool get _boardBeat => _beat == _Beat.pick || _beat == _Beat.why || _beat == _Beat.mythWhy;

  static const _laneHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    final save = ref.read(gameSaveProvider);
    _history = (
      plays: save.playsByRung[widget.rungId] ?? 0,
      best: save.bestMarkByRung[widget.rungId],
      ms: save.bestTimeMsByRung[widget.rungId],
    );
    _celebrate = AnimationController(vsync: this, duration: const Duration(milliseconds: 920));
    _burn = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _rivalEnter = AnimationController(vsync: this, duration: _rivalEnterTime);
    // Loops only while the rival is on stage (started/stopped in the cutscene).
    _rivalBob = AnimationController(vsync: this, duration: const Duration(milliseconds: 920));
    _rivalExit = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    _rivalJab = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _stageShake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scorePunch = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    _readFly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      reverseDuration: const Duration(milliseconds: 460),
    );
    _readCurve = CurvedAnimation(parent: _readFly, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    _lookIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _lookIn.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted && _look != null && !_lookReady) {
        setState(() => _lookReady = true);
      }
    });
    _lookHit = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _life = AppLifecycleListener(
      onHide: () => _clockHold(keepWanted: true),
      onShow: _clockResume,
    );
    _burn.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _burning = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startIntro());
    });
  }

  /// The rival's idle bob loops only while he is on stage, and never under
  /// "remove animations" or while the route is hidden (AGENTS §1).
  void _syncRivalBob() => slmSyncLoop(context, _rivalBob, enabled: _rivalOnStage, reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRivalBob();
  }

  @override
  void dispose() {
    _voiceRun++;
    unawaited(MascotSpeechLibrary.stop());
    _endOfferFinish();
    _clockHold();
    _life.dispose();
    _clockSec.dispose();
    _celebrate.dispose();
    _burn.dispose();
    _rivalEnter.dispose();
    _rivalBob.dispose();
    _rivalExit.dispose();
    _rivalJab.dispose();
    _stageShake.dispose();
    _scorePunch.dispose();
    _readCurve.dispose();
    _readFly.dispose();
    _lookIn.dispose();
    _lookHit.dispose();
    _continueArm?.cancel();
    final gate = _verdictDone;
    _verdictDone = null;
    if (gate != null && !gate.isCompleted) gate.complete();
    super.dispose();
  }

  String _promptForBeat() {
    return switch (_beat) {
      _Beat.intro => _pack.introBn,
      _Beat.pick || _Beat.why || _Beat.mythWhy => _ask,
      _Beat.mythSay => '',
      _Beat.mythBelieve => _sting,
      _Beat.award || _Beat.done =>
        _failed ? LearnFeedbackLines.failed.first.shownBn : '${_pack.badgeBn} পেয়েছেন।',
    };
  }

  Future<void> _onMascotTap() async {
    if (_locked) return;
    final line = _promptForBeat().trim();
    if (line.isEmpty) return;
    HapticFeedback.selectionClick();
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    }
    await _say(line, mood: GuideMood.talk);
  }

  /// Start (or keep) the clock for the question on screen; [reset] for a new one.
  void _clockGo({bool reset = false}) {
    if (reset) {
      _choiceClock.reset();
      _clockSec.value = 0;
    }
    _clockWanted = true;
    _clockResume();
  }

  void _clockResume() {
    // The app coming back must not restart the clock behind the পাঠ card or the reader.
    // Nor while the player reads a pick's feedback (only thinking time counts).
    if (!_clockWanted || _clockTimer != null || !mounted || _readOpen || _openingLesson || _verdict != null) return;
    _levelClock.start();
    _choiceClock.start();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 250), (_) => _clockPoll());
  }

  void _clockPoll() {
    final s = _choiceClock.elapsed.inSeconds;
    if (s == _clockSec.value) return;
    _clockSec.value = s;
    // Tick-tock under the player's thinking, never over coach or rival voice.
    if (_muted || MascotTalk.active.value || RivalTalk.active.value) return;
    final file = s.isEven ? 'sounds/learn/tick.ogg' : 'sounds/learn/tock.ogg';
    unawaited(ZlFx.cue(file, volume: 0.3, muted: false));
  }

  void _clockHold({bool keepWanted = false}) {
    if (!keepWanted) _clockWanted = false;
    _clockTimer?.cancel();
    _clockTimer = null;
    _levelClock.stop();
    _choiceClock.stop();
  }

  static const _rivalEnterTime = Duration(milliseconds: 760);

  /// Fraction of [_rivalEnterTime] at which his boots hit the floor.
  static const _rivalLandAt = 0.72;

  /// One flick per card, fired by the card itself as it leaves the deck.
  void _dealCue(int i) {
    if (_muted) return;
    final file = i.isEven ? 'sounds/learn/card_deal_a.ogg' : 'sounds/learn/card_deal_b.ogg';
    unawaited(ZlFx.cue(file, volume: 0.62, muted: false));
  }

  void _markHit(String id, bool good) {
    setState(() {
      _hitId = id;
      _hitGood = good;
      _hitToken++;
    });
  }

  int _hitFor(String id) => _hitId == id ? _hitToken : 0;

  String _dealKey(String question) => '${_pack.lessonId}/$question';

  List<LearnWhyChip> _dealWhy(String key, List<LearnWhyChip> pool, int count) {
    final hand = _dealer.deal(key, pool, count: count);
    _seen
      ..clear()
      ..addAll(hand.map((c) => c.id));
    return hand;
  }

  /// Once the player has read why the card was wrong: an unseen trap takes its
  /// place and the whole board is dealt again in a new order, so positions
  /// can't be learnt.
  void _redealAfterMiss(LearnPick missed) {
    if (!mounted) return;
    final beat = _beat;
    setState(() {
      if (missed is LearnBoardOption) {
        _pickOpts = _dealer.afterMiss(_pickOpts, missed, _cur.options, _seen);
        _seen.addAll(_pickOpts.map((o) => o.id));
      } else if (missed is LearnWhyChip) {
        final pool = beat == _Beat.mythWhy ? _pack.myth.whyChips : _cur.whyChips;
        _whyOpts = _dealer.afterMiss(_whyOpts, missed, pool, _seen);
        _seen.addAll(_whyOpts.map((c) => c.id));
      }
      _hitId = null;
      _pickedWhy = null;
      _cardWave++;
    });
  }

  Future<void> _stopVoice() async {
    _voiceRun++;
    await MascotSpeechLibrary.stop();
  }

  /// Time a player needs to read [line] in the bubble (also the floor when the
  /// voice is muted or fails, so beats never collapse to zero length).
  Duration _readTime(String line) {
    final ms = (700 + line.trim().length * 48).clamp(1100, 3800);
    return Duration(milliseconds: ms);
  }

  /// Coach line: bubble + voice + lips. Completes when the line has been heard
  /// (or read, when muted). Returns false if a newer line interrupted it.
  Future<bool> _say(
    String line, {
    GuideMood mood = GuideMood.talk,
    String? spoken,
    String? voiceKey,
  }) async {
    if (line.trim().isEmpty) return true;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    return _voiceLine(line, rival: false, spoken: spoken, voiceKey: voiceKey);
  }

  /// Bubble text without voice, held long enough to read.
  Future<bool> _show(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty) return true;
    final run = ++_voiceRun;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await Future<void>.delayed(_readTime(line) * 0.7);
    return mounted && run == _voiceRun;
  }

  Future<bool> _sayLine(FeedbackLine l, GuideMood mood) =>
      _say(l.shownBn, mood: mood, spoken: l.spokenBn, voiceKey: l.voiceKey);

  /// Asks a fresh wording of the board's question and remembers it.
  Future<bool> _askFrom(LineBag bag) {
    final l = bag.next();
    _ask = l.shownBn;
    return _sayLine(l, GuideMood.inspire);
  }

  /// Varied reaction to a wrong answer; a second miss in a row sounds different.
  /// A short spoken word, then the reason: spoken in full the first time this
  /// mistake ([key]) is made, afterwards only shown in the bubble.
  Future<bool> _sayMistake({String reason = '', String key = ''}) async {
    _missStreak++;
    // Counted before any speech, so a quick next tap can't skip the offer.
    final offer = LessonMissTally.miss(_pack.lessonId);
    final opener = _missStreak >= 2 ? _againBag.next() : _wrongBag.next();
    final heard = await _speakMiss(opener, reason: reason, key: key);
    if (offer && mounted && _boardBeat) {
      if (heard) await _say(LearnCoachLines.threeMisses, mood: GuideMood.inspire);
      await _showReadCard();
    }
    return heard;
  }

  Future<bool> _speakMiss(FeedbackLine opener, {String reason = '', String key = ''}) async {
    var heard = await _sayLine(opener, GuideMood.warn);
    if (heard && reason.trim().isNotEmpty) {
      final speak = key.isEmpty || await SpokenOnce.first('board/${_pack.lessonId}/$key');
      if (!mounted) return false;
      heard = speak ? await _say(reason, mood: GuideMood.warn) : await _show(reason, mood: GuideMood.warn);
    }
    return heard;
  }

  /// A confirmed wrong card: the short word and the reason are said and stay
  /// written under the card until the player presses Continue; then the board
  /// is dealt again (and, after three misses, the lesson is offered).
  Future<void> _missOnCard(LearnPick missed, {String name = '', required String reason, required String key}) async {
    _missStreak++;
    // Counted before any speech, so a quick Continue can't skip the offer.
    final offer = LessonMissTally.miss(_pack.lessonId);
    final opener = _missStreak >= 2 ? _againBag.next() : _wrongBag.next();
    unawaited(_speakMiss(opener, reason: reason, key: key));
    await _awaitContinue(_Verdict(good: false, headline: opener.shownBn, name: name, body: reason));
    if (!mounted) return;
    await _stopVoice();
    if (!mounted) return;
    _busy = false;
    _closeLook();
    _redealAfterMiss(missed);
    _clockResume();
    if (offer && mounted && _boardBeat) {
      await _say(LearnCoachLines.threeMisses, mood: GuideMood.inspire);
      if (mounted && _look == null) await _showReadCard();
    }
  }

  /// Shows [v] under the open card and waits for Continue (never advances on
  /// its own: the player reads at their own pace). The decision clock waits too.
  Future<void> _awaitContinue(_Verdict v) async {
    if (!mounted) return;
    _clockHold(keepWanted: true);
    final done = Completer<void>();
    _verdictDone = done;
    _continueArmed = false;
    _continueArm?.cancel();
    // Only arms the button (no rebuild, no frame): a double tap on ✓ can't skip the feedback.
    _continueArm = Timer(const Duration(milliseconds: 350), () => _continueArmed = true);
    setState(() => _verdict = v);
    if (!_quietMotion) _lookHit.forward(from: 0);
    await done.future;
  }

  /// "এগিয়ে যান".
  void _onContinue() {
    final done = _verdictDone;
    if (_verdict == null || done == null || done.isCompleted || !_continueArmed) return;
    HapticFeedback.selectionClick();
    _verdictDone = null;
    done.complete();
  }

  void _closeLook() {
    if (!mounted) return;
    _lookIn.value = 0;
    _lookHit.value = 0;
    setState(() {
      _look = null;
      _verdict = null;
      _lookReady = false;
    });
  }

  String _asideId(String id) => '$_beat-$_cardWave-$id';

  bool _isAside(String id) => _aside.contains(_asideId(id));

  /// A tap on a board card: open it large to read; nothing is judged yet.
  void _openLook(LearnPick item, int index, Offset global) {
    if (!_boardBeat || _locked || _busy || _look != null || _readOpen || _openingLesson) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.55, muted: false));
    final quiet = _quietMotion;
    setState(() {
      _look = _Look(item: item, index: index, origin: global);
      _verdict = null;
      _lookReady = quiet;
    });
    _lookHit.value = 0;
    if (quiet) {
      _lookIn.value = 1;
    } else {
      _lookIn.forward(from: 0);
    }
  }

  /// ✕ বাদ দিন: the card goes back to the board marked as set aside (not
  /// wrong — nothing was judged); it can be opened again.
  void _rejectLook() {
    final look = _look;
    if (look == null || !_lookReady || _verdict != null || _busy) return;
    HapticFeedback.selectionClick();
    _aside.add(_asideId(look.item.id));
    _closeLook();
  }

  /// ✓ বেছে নিন: the card is chosen; the board's usual pick logic runs.
  void _confirmLook() {
    final look = _look;
    if (look == null || !_lookReady || _verdict != null || _busy || _locked) return;
    _aside.remove(_asideId(look.item.id));
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.55, muted: false));
    switch (look.item) {
      case LearnBoardOption o:
        unawaited(_onPick(o, look.origin));
      case LearnWhyChip c when _beat == _Beat.mythWhy:
        unawaited(_onMythWhy(c, look.origin));
      case LearnWhyChip c:
        unawaited(_onWhy(c, look.origin));
    }
  }

  bool get _quietMotion => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  /// Pill centre relative to the board centre (where the card sits when open).
  void _measureReadFrom() {
    _readFrom = readLessonFrom(_readPillKey, _boardKey) ?? _readFrom;
  }

  /// After a passed level with no offer so far: a varied nudge to read, then leave.
  Future<void> _endOffer() async {
    final done = Completer<void>();
    _endOfferDone = done;
    final nudge = ReadLessonNudges.next(_pack.lessonId);
    await _showReadCard(nudge: nudge);
    if (!mounted || !_readOpen) return;
    unawaited(_say(nudge.title, mood: GuideMood.inspire));
    await done.future;
  }

  void _endOfferFinish() {
    final done = _endOfferDone;
    _endOfferDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  /// The card flies out of the পাঠ pill and lands over the items.
  Future<void> _showReadCard({bool atStart = false, ReadNudge? nudge}) async {
    if (_readOpen || _openingLesson || !mounted || (!_boardBeat && nudge == null)) return;
    await _stopVoice();
    if (!mounted) return;
    _clockHold(keepWanted: true);
    _measureReadFrom();
    setState(() {
      _readOpen = true;
      _readAtStart = atStart;
      _readNudge = nudge;
      _readShown = true;
    });
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.ogg', volume: 0.32, muted: false));
    if (_quietMotion) {
      _readFly.value = 1;
    } else {
      await _readFly.forward(from: 0);
    }
  }

  /// "এখন না": the card shrinks back into the pill, which stays lit.
  Future<void> _tuckReadCard() async {
    if (!_readOpen || _readFly.isAnimating) return;
    _measureReadFrom();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.ogg', volume: 0.3, muted: false));
    if (_quietMotion) {
      _readFly.value = 0;
    } else {
      await _readFly.reverse();
    }
    if (!mounted) return;
    if (_readNudge != null) {
      setState(() {
        _readOpen = false;
        _readNudge = null;
      });
      _endOfferFinish();
      return;
    }
    setState(() {
      _readOpen = false;
      _readHot = true;
    });
    _clockResume();
    if (_readAtStart) {
      _readAtStart = false;
      await _say(_promptForBeat(), mood: GuideMood.talk);
    }
  }

  Future<void> _startReadCard() async {
    if (!_readOpen) return;
    _readFly.value = 0;
    final atStart = _readAtStart;
    final atEnd = _readNudge != null;
    setState(() {
      _readOpen = false;
      _readAtStart = false;
      _readNudge = null;
    });
    await _openLesson(anyTime: atEnd);
    if (atEnd) {
      _endOfferFinish();
      return;
    }
    if (mounted && atStart) await _say(_promptForBeat(), mood: GuideMood.talk);
  }

  /// Opens this level's lesson in the reader; the clock and voice wait.
  /// [anyTime] also opens it during a scripted moment (the end-of-level offer).
  Future<void> _openLesson({bool anyTime = false}) async {
    if ((_locked && !anyTime) || _openingLesson) return;
    _openingLesson = true;
    HapticFeedback.selectionClick();
    await _stopVoice();
    _clockHold(keepWanted: true);
    final lesson = await _findLesson();
    if (!mounted) return;
    if (lesson == null) {
      _openingLesson = false;
      _clockResume();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SlmColors.navy900,
          content: Text(
            'পাঠটা এখন খোলা যাচ্ছে না। ইন্টারনেট চালু করে আবার চেষ্টা করুন।',
            style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory),
          ),
        ),
      );
      return;
    }
    LessonMissTally.read(_pack.lessonId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonReaderPage(lesson: lesson, bn: true, muted: _muted)),
    );
    // The reader hands over to its seal page; wait until the level is on top again.
    while (mounted && !(ModalRoute.of(context)?.isCurrent ?? true)) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _openingLesson = false;
    if (!mounted) return;
    setState(() => _readHot = false);
    _clockResume();
  }

  /// The real lesson (live or the saved copy); null when it can't be loaded.
  Future<LessonCardItem?> _findLesson() async {
    final parts = _pack.lessonId.split('.');
    final module = int.tryParse(parts.first) ?? 1;
    final chapter = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
    try {
      final lessons = await ref
          .read(moduleLessonsProvider(module).future)
          .timeout(const Duration(seconds: 12));
      for (final l in lessons) {
        if (l.chapterNumber == chapter && l.points.isNotEmpty) return l;
      }
    } catch (_) {}
    return null;
  }

  /// Ends the question on screen and remembers it as a weak spot when it was
  /// not answered right on the first try (or clears it after a clean answer).
  void _settle(String question, {bool right = true}) {
    final clean = right && !_marks.missedCurrent;
    _marks.settle(right: right);
    unawaited(ref.read(gameSaveProvider.notifier).markWeak(_pack.lessonId, question, weak: !clean));
  }

  /// A right "why": the first time, the coach says the rule itself; after
  /// that one short word (the card already shows the rule). Says nothing if
  /// the player has moved on meanwhile.
  Future<void> _speakRule(String rule, FeedbackLine praise, {required String key}) async {
    final run = _voiceRun;
    final first = await SpokenOnce.first('board/${_pack.lessonId}/rule/$key');
    if (!mounted || run != _voiceRun) return;
    if (first) {
      await _say(rule, mood: GuideMood.glad);
    } else {
      await _sayLine(praise, GuideMood.glad);
    }
  }

  Future<bool> _sayRight() => _sayLine(_rightLine(), GuideMood.glad);

  /// A right answer: the miss streak ends; the next praise wording.
  FeedbackLine _rightLine() {
    _missStreak = 0;
    LessonMissTally.hit(_pack.lessonId);
    return _rightBag.next();
  }

  /// Adds [delta] to this play's level score and flies the chip into it.
  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood, bool playSound = true}) async {
    if (delta == 0 || !mounted) return;
    setState(() => _runScore = math.max(0, _runScore + delta));
    await BeatFx.levelDelta(
      ref,
      delta,
      mood: mood,
      originGlobal: origin,
      playSound: playSound,
      muted: _muted,
    );
  }

  /// A mistake costs: first the unsaved ◆ on the table, else −5 from the
  /// level score — which never goes below 0.
  Future<void> _penalize(Offset origin) async {
    if (_pending > 0) {
      await _burnPending();
      return;
    }
    if (_runScore < 5) return;
    setState(() => _runScore -= 5);
    await BeatFx.levelDelta(
      ref,
      -5,
      mood: GuideMood.warn,
      originGlobal: origin,
      playSound: false,
      muted: _muted,
    );
  }

  /// Rival line: his bubble + his gruff voice; the coach stays silent.
  Future<bool> _rivalSay(String line) async {
    _rivalJab.forward(from: 0);
    setState(() {
      _rivalBubbleBn = line;
      _rivalVoice = true;
    });
    final heard = await _voiceLine(line, rival: true);
    if (mounted) setState(() => _rivalVoice = false);
    return heard;
  }

  Future<bool> _voiceLine(
    String line, {
    required bool rival,
    String? spoken,
    String? voiceKey,
  }) async {
    final run = ++_voiceRun;
    final clock = Stopwatch()..start();
    // The rival speaks only in his recorded voice; a line with no clip stays
    // silent with its bubble held for reading (as in the Do levels).
    await MascotSpeechLibrary.speak(spoken ?? line, voiceKey: voiceKey, muted: _muted, rival: rival);
    if (!mounted) return false;
    // Muting mid-line still leaves the bubble up long enough to read.
    final floor = (_muted || run != _voiceRun) ? _readTime(line) : _readTime(line) * 0.55;
    final rest = floor - clock.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
    return mounted && run == _voiceRun;
  }

  /// Small breath between beats so scenes read as separate moments.
  Future<bool> _pause(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    return mounted;
  }

  Offset _pendingOrigin() {
    final box = _pendingDockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    }
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width * 0.82, size.height * 0.18);
  }

  /// Runs a scripted moment with input locked. Prompts that follow should be
  /// spoken after this returns so the player can answer while they play.
  Future<void> _scripted(Future<void> Function() body) async {
    _locked = true;
    try {
      await body();
    } finally {
      _locked = false;
    }
  }

  Future<void> _startIntro() async {
    // First play of the lesson: the day card sets the scene before the board.
    await showLessonDayCard(context, ref, lessonId: _pack.lessonId, rungId: widget.rungId, muted: _muted);
    if (!mounted) return;
    setState(() => _beat = _Beat.intro);
    await _scripted(() async {
      if (!await _pause(420)) return;
      await _say(_pack.introBn, mood: GuideMood.inspire);
      await _pause(320);
    });
    if (!mounted) return;
    await _enterSlot(0);
  }

  Future<void> _enterSlot(int i) async {
    await _stopVoice();
    if (!mounted) return;
    final slot = widget.pack.slots[i];
    final opts = _dealer.deal(_dealKey(slot.id), slot.options, count: slot.cards);
    _seen
      ..clear()
      ..addAll(opts.map((o) => o.id));
    setState(() {
      _slot = i;
      _beat = _Beat.pick;
      _pending = 0;
      _pickedWhy = null;
      _whyRetry = false;
      _burning = false;
      _pickOpts = opts;
      _hitId = null;
      _cardWave++;
    });
    _clockGo(reset: true);
    // A round with its own situation ("11 kV লাইন — কোথায় দাঁড়াবেন?") says it;
    // a generic one ("সঠিক জিনিস বেছে নিন", lesson 1.1) rotates the usual wordings.
    final own = _pack.slots[i].promptBn;
    final generic = own.trim().isEmpty || LearnFeedbackLines.pickAsk.any((l) => l.shownBn == own);
    final ask = generic ? _pickAskBag.next() : FeedbackLine(own);
    _ask = ask.shownBn;
    if (i == 0 && _offerLessonFirst()) {
      // New player: once the cards have landed, offer the lesson over them.
      if (!await _pause(_quietMotion ? 200 : 1150)) return;
      await _showReadCard(atStart: true);
      return;
    }
    await _sayLine(ask, GuideMood.talk);
  }

  bool _offerLessonFirst() {
    if (ref.read(gameSaveProvider).rungProgress[widget.rungId] == 'cleared') return false;
    final done = ref.read(allCompletedLessonsProvider);
    return !done.contains(_pack.lessonId.replaceAll('.', '_')) && !done.contains(_pack.lessonId);
  }

  Future<void> _onPick(LearnBoardOption opt, Offset global) async {
    if (_beat != _Beat.pick || _locked || _busy) return;
    _busy = true;
    _markHit(opt.id, opt.correct);
    await _stopVoice();
    if (!opt.correct) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.72, muted: false));
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
      _marks.miss();
      await _penalize(global);
      if (!mounted) return;
      await _missOnCard(opt, name: opt.labelBn, reason: opt.rejectBn, key: 'pick/${opt.id}');
      return;
    }

    _settle(_cur.id);
    final why = _dealWhy(_dealKey('${_cur.id}/why'), _cur.whyChips, _cur.whyCards);
    _clockHold();
    await _scripted(() async {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.78, muted: false));
      setState(() {
        // A slot paid on an earlier play puts nothing on the table.
        _pending = _cur.pendingPoints;
        _pendingFxToken++;
      });
      _celebrate.forward(from: 0);
      _scorePunch.forward(from: 0);
      final praise = _rightLine();
      unawaited(_sayLine(praise, GuideMood.glad));
      // The praise and the card's name stay under the card until Continue.
      await _awaitContinue(_Verdict(good: true, headline: praise.shownBn, name: opt.labelBn));
      if (!mounted) return;
      await _stopVoice();
      if (!mounted) return;
      _closeLook();
      setState(() {
        _beat = _Beat.why;
        _pickedWhy = null;
        _hitId = null;
        _whyOpts = why;
        _cardWave++;
      });
      await _pause(320);
    });
    _busy = false;
    if (!mounted) return;
    // Rebuild once unlocked so the reason board's idle hint can arm.
    setState(() {});
    _clockGo(reset: true);
    await _askFrom(_whyAskBag);
  }

  /// The ◆ on the table fly into the level score.
  Future<void> _bankPending(int bank, Offset global) async {
    if (bank <= 0 || !mounted) return;
    final origin = _pending > 0 ? _pendingOrigin() : global;
    setState(() => _pending = 0);
    _celebrate.forward(from: 0);
    _scorePunch.forward(from: 0);
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.7, muted: false));
    }
    await _levelDelta(bank, origin, mood: GuideMood.celebrate);
  }

  Future<void> _burnPending() async {
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.7, muted: false));
    setState(() {
      _burning = true;
      _pending = 0;
      _whyRetry = true;
      _pickedWhy = null;
    });
    _burn.forward(from: 0);
  }

  Future<void> _onWhy(LearnWhyChip chip, Offset global) async {
    if (_beat != _Beat.why || _locked || _busy) return;
    _busy = true;
    await _stopVoice();
    if (!mounted) return;
    setState(() => _pickedWhy = chip.id);
    _markHit(chip.id, chip.correct);

    if (!chip.correct) {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.72, muted: false));
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
      setState(() => _whyRetry = true);
      _marks.miss();
      await _penalize(global);
      if (!mounted) return;
      await _missOnCard(chip, reason: LearnCoachLines.notThisReason, key: 'why');
      return;
    }

    _settle('${_cur.id}/why');
    _clockHold();
    await _scripted(() async {
      final bank = _pending > 0 ? _pending : (_whyRetry ? 5 : 0);
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.8, muted: false));
      final banked = _bankPending(bank, global);
      final praise = _rightLine();
      unawaited(_speakRule(chip.textBn, praise, key: '${_cur.id}/${chip.id}'));
      await _awaitContinue(_Verdict(good: true, headline: praise.shownBn));
      await banked;
      if (!mounted) return;
      await _stopVoice();
      _closeLook();
      await _pause(240);
    });
    _busy = false;
    if (!mounted) return;
    if (_slot < _pack.slots.length - 1) {
      await _enterSlot(_slot + 1);
    } else {
      await _enterMyth();
    }
  }

  /// Myth cutscene: coach warns → rival storms in, taunts, claims, gets tagged
  /// with dangers, sneers and leaves → coach returns and asks. Input is locked
  /// until the question has been asked.
  Future<void> _enterMyth() async {
    await _stopVoice();
    if (!mounted) return;
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final myth = _pack.myth;
    await _scripted(() async {
      setState(() {
        _beat = _Beat.mythSay;
        _pending = 0;
        _pickedWhy = null;
        _whyRetry = false;
        _burning = false;
        _rivalLayers = 0;
        _tagsShown = false;
        _rivalBubbleBn = '';
        _rivalDefeated = false;
        _rivalOnStage = false;
        _rivalVoice = false;
        _askReady = false;
      });
      _rivalExit.value = 0;
      _rivalEnter.value = 0;
      if (!await _pause(360)) return;
      await _say(LearnCoachLines.rivalComing, mood: GuideMood.warn);
      if (!mounted) return;

      // Rival rushes in from the right and stomps down.
      ref.read(guideDirectorProvider.notifier).clearLine();
      setState(() => _rivalOnStage = true);
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.ogg', volume: 0.75, muted: false));
      if (quiet) {
        _rivalEnter.value = 1;
        _rivalLand();
      } else {
        _syncRivalBob();
        final landIn = _rivalEnterTime * _rivalLandAt;
        Future<void>.delayed(landIn, () {
          if (mounted && _rivalOnStage) _rivalLand();
        });
        await _rivalEnter.forward(from: 0);
      }
      if (!await _pause(260)) return;

      await _rivalSay(myth.tauntBn);
      if (!await _pause(180)) return;
      await _rivalSay(myth.rivalLineBn);
      if (!mounted) return;

      // Slap a warning tag on each bad bit, one beat at a time.
      setState(() {
        _rivalBubbleBn = '';
        _tagsShown = true;
      });
      for (var i = 0; i < myth.dangerHints.length; i++) {
        if (!await _pause(i == 0 ? 300 : 520)) return;
        HapticFeedback.mediumImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.ogg', volume: 0.7, muted: false));
        setState(() => _rivalLayers = i + 1);
      }
      if (!await _pause(1100)) return;

      setState(() => _tagsShown = false);
      await _rivalSay(myth.exitBn);
      if (!mounted) return;
      setState(() => _rivalBubbleBn = '');
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.ogg', volume: 0.7, muted: false));
      if (quiet) {
        _rivalExit.value = 1;
      } else {
        await _rivalExit.forward(from: 0);
      }
      if (!mounted) return;
      _rivalBob.stop();

      // Coach reclaims the stage, then asks.
      setState(() {
        _rivalOnStage = false;
        _beat = _Beat.mythBelieve;
      });
      if (!await _pause(380)) return;
      await _say(_sting, mood: GuideMood.inspire);
      if (!mounted) return;
      setState(() => _askReady = true);
      _clockGo(reset: true);
    });
  }

  /// Boots hit the floor: thud, rumble, dust.
  void _rivalLand() {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.ogg', volume: 0.9, muted: false));
    _stageShake.forward(from: 0);
    setState(() => _rivalLandToken++);
  }

  Future<void> _onBelieve(bool yes, Offset global) async {
    if (_beat != _Beat.mythBelieve || _locked || !_askReady || _busy) return;
    _busy = true;
    await _stopVoice();
    if (!mounted) return;
    // "বিশ্বাস করেন?" হ্যাঁ = believes him; "সেটা কি ভুল?" হ্যাঁ = does not.
    final believes = _askFlipped ? !yes : yes;
    final correct = _pack.myth.believeNoIsCorrect ? !believes : believes;
    final why = _dealWhy(_dealKey('myth/why'), _pack.myth.whyChips, 3);
    _settle('myth', right: correct);
    if (correct) {
      _clockHold();
      await _scripted(() async {
        setState(() {
          _rivalDefeated = true;
          _pending = _pack.myth.pendingPoints;
          _pendingFxToken++;
          _whyOpts = why;
          _cardWave++;
        });
        _celebrate.forward(from: 0);
        _scorePunch.forward(from: 0);
        if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.78, muted: false));
        HapticFeedback.lightImpact();
        await _sayRight();
        if (!mounted) return;
        setState(() {
          _beat = _Beat.mythWhy;
          _hitId = null;
        });
        await _pause(320);
      });
      _busy = false;
      if (!mounted) return;
      // Rebuild once unlocked so the reason board's idle hint can arm.
      setState(() {});
      _clockGo(reset: true);
      await _askFrom(_mythAskBag);
      return;
    }

    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.78, muted: false));
    setState(() {
      _whyRetry = true;
      _whyOpts = why;
      _cardWave++;
    });
    await _penalize(global);
    _busy = false;
    if (!mounted) return;
    setState(() {
      _beat = _Beat.mythWhy;
      _hitId = null;
    });
    _clockGo(reset: true);
    _ask = _mythAskBag.next().shownBn;
    await _sayMistake(reason: LearnCoachLines.wrongBelief, key: 'myth/believe');
  }

  Future<void> _onMythWhy(LearnWhyChip chip, Offset global) async {
    if (_beat != _Beat.mythWhy || _locked || _busy) return;
    _busy = true;
    await _stopVoice();
    if (!mounted) return;
    setState(() => _pickedWhy = chip.id);
    _markHit(chip.id, chip.correct);
    if (!chip.correct) {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.72, muted: false));
      setState(() => _whyRetry = true);
      _marks.miss();
      await _penalize(global);
      if (!mounted) return;
      await _missOnCard(chip, reason: LearnCoachLines.notThisReason, key: 'why');
      return;
    }
    _settle('myth/why');
    LessonMissTally.hit(_pack.lessonId);
    _clockHold();
    await _scripted(() async {
      final bank = _pending > 0 ? _pending : (_whyRetry ? 5 : 0);
      final banked = _bankPending(bank, global);
      unawaited(() async {
        if (!await _say(LearnCoachLines.realPoint, mood: GuideMood.celebrate) || _popped) return;
        // The first time, the reason is spoken too; after that the card shows it.
        final run = _voiceRun;
        if (await SpokenOnce.first('board/${_pack.lessonId}/rule/myth') && mounted && run == _voiceRun) {
          await _say(chip.textBn, mood: GuideMood.glad);
        }
      }());
      await _awaitContinue(const _Verdict(good: true, headline: LearnCoachLines.realPoint));
      await banked;
      if (!mounted) return;
      await _stopVoice();
      _closeLook();
      if (!await _pause(260)) return;
      await _award();
    });
  }

  Future<void> _award() async {
    await _stopVoice();
    if (!mounted) return;
    _clockHold();
    final save = ref.read(gameSaveProvider.notifier);
    final mark = _marks.percent;
    await save.recordLevelResult(widget.rungId, mark);
    GameSaveController.onPlayResult?.call(widget.rungId, mark: mark, ms: _levelClock.elapsedMilliseconds);
    if (!mounted) return;
    if (!_marks.passed) {
      await _fail(mark);
      return;
    }
    setState(() {
      _beat = _Beat.award;
      _runMark = mark;
    });
    final already = ref.read(gameSaveProvider).rungProgress[widget.rungId] == 'cleared';
    await save.markRungCleared(widget.rungId);
    if (!already) {
      await markLessonCompletedLocally(ref, _pack.lessonId.replaceAll('.', '_'));
      await markLessonCompletedLocally(ref, _pack.lessonId);
    }
    _passed = true;
    final bonus = _pack.clearBonus;
    if (!await _pause(420) || _popped || !mounted) {
      // Left during the award: the clear and this play's score are saved (no animation).
      await save.commitLevelScore(widget.rungId, _runScore + bonus);
      return;
    }
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width * 0.5, size.height * 0.42);
    await _levelDelta(bonus, centre, mood: GuideMood.celebrate);
    // The latest play's score replaces this level's last one in the main ◆.
    await save.commitLevelScore(widget.rungId, _runScore);
    final ms = _levelClock.elapsedMilliseconds;
    final best = await save.recordBestTime(widget.rungId, ms);
    if (!mounted) return;
    setState(() {
      _finalMs = ms;
      _newRecord = best.record && best.previous != null;
      _bestMs = best.record ? ms : best.previous;
    });
    if (_newRecord) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_complete.ogg', volume: 0.75, muted: false));
      await _say(LearnCoachLines.newRecord, mood: GuideMood.celebrate);
      if (!mounted) return;
    }
    await _say(
      _pack.earnedBn.isEmpty ? LearnCoachLines.badgeEarned(_pack.badgeBn) : _pack.earnedBn,
      mood: GuideMood.celebrate,
    );
    if (!mounted || _popped) return;
    setState(() => _beat = _Beat.done);
    if (!await _pause(1100) || _popped) return;
    await _stopVoice();
    if (!mounted) return;
    final promised = await askLessonPromise(
      context,
      ref,
      lessonId: _pack.lessonId,
      rungId: widget.rungId,
      muted: _muted,
    );
    if (!mounted || _popped) return;
    if (!promised && !_readShown) {
      await _endOffer();
      if (!mounted || _popped) return;
    }
    _popOnce(true);
  }

  /// Below the pass line: nothing is cleared or awarded; the fail panel offers
  /// another go, the lesson, or the way back.
  Future<void> _fail(int mark) async {
    setState(() {
      _beat = _Beat.award;
      _failed = true;
      _runMark = mark;
    });
    // A finished play counts even below the pass line: the latest score stands.
    await ref.read(gameSaveProvider.notifier).commitLevelScore(widget.rungId, _runScore);
    if (!mounted) return;
    if (!await _pause(900)) return;
    await _sayLine(LearnFeedbackLines.failed[math.Random().nextInt(LearnFeedbackLines.failed.length)], GuideMood.warn);
  }

  Widget _failStage() {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 36)),
          child: Center(
            child: LevelFailPanel(
              percent: _runMark ?? 0,
              muted: _muted,
              history: _historyChip(),
              onRetry: () async {
                await _stopVoice();
                widget.onRetry(_muted);
              },
              onRead: () => unawaited(_openLesson(anyTime: true)),
              onLeave: () async {
                await _stopVoice();
                _popOnce(false);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _historyChip() {
    if (_history.plays <= 0) return null;
    return LevelHistoryChip(plays: _history.plays, bestMark: _history.best, bestMs: _history.ms);
  }

  Future<bool> _confirmExit() async {
    final leave = await showGameExitSheet(
      context,
      scope: GameExitScope.level,
      bn: ref.read(languageProvider),
    );
    return leave == true;
  }

  /// Every exit goes through here, so the level never pops twice.
  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    _endOfferFinish();
    Navigator.of(context).pop(cleared);
  }

  /// Back / close. After a pass the clear is already saved, so leave with it.
  Future<void> _leave() async {
    if (_passed) {
      await _stopVoice();
      _popOnce(true);
      return;
    }
    if (!await _confirmExit()) return;
    await _stopVoice();
    _popOnce(false);
  }

  /// Beat tint over the shared night-world backdrop: myth leans danger,
  /// award leans gold.
  Color _washFor(_Beat beat) {
    return switch (beat) {
      _Beat.mythSay || _Beat.mythBelieve || _Beat.mythWhy => const Color(0x66420A16),
      _Beat.award || _Beat.done => _failed ? const Color(0x553A0A14) : const Color(0x4D4A3406),
      _Beat.why => const Color(0x220A1E3A),
      _ => const Color(0x00000000),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Theme(
          data: SlmTheme.night(),
          child: Builder(
            builder: (context) {
              final palette = context.slm.palette;
              return Scaffold(
                backgroundColor: SlmColors.navy950,
                body: ScoreFlyHost(
                  scoreKey: _scoreKey,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _LearnBackdrop(tint: _washFor(_beat), quiet: quiet),
                      ),
                      SafeArea(
                        child: Column(
                          children: [
                            _LearnBoardChrome(
                              scoreKey: _scoreKey,
                              step: widget.ladderIndex + 1,
                              title: _pack.titleBn,
                              levelScore: _runScore,
                              dimmed: _beat == _Beat.intro,
                              onClose: _leave,
                              onReadLesson: () {
                                if (_readOpen) {
                                  unawaited(_tuckReadCard());
                                } else if (_boardBeat && !_locked) {
                                  unawaited(_showReadCard());
                                } else {
                                  unawaited(_openLesson());
                                }
                              },
                              readHot: _readHot,
                              readPillKey: _readPillKey,
                            ),
                            Expanded(
                              child: Stack(
                                key: _boardKey,
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(child: _stage(quiet, palette)),
                                  // Corner coach steps aside while the rival owns the
                                  // stage, and while he stands center to ask.
                                  if (!_missionHero && !_rivalOnStage && _beat != _Beat.mythBelieve)
                                    Positioned(
                                      left: 4,
                                      bottom: 4,
                                      child: AiLinemanGuide(
                                        keepBubble: true,
                                        sprite: 148,
                                        bubbleWidth: 210,
                                        showBubble: true,
                                        large: true,
                                        centered: false,
                                        onTap: () => unawaited(_onMascotTap()),
                                      ),
                                    ),
                                  // The opened card sits under the top lane, so the
                                  // step pips and the pending ◆ stay in view.
                                  if (_look case final look?) Positioned.fill(child: _lookLayer(look, quiet)),
                                  if (_boardBeat) _stepPips(palette),
                                  if (_pending > 0 || _burning) _pendingDock(quiet, palette),
                                  if (_readOpen) Positioned.fill(child: _readCardLayer()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Dimmed board + the lesson card, flying between the pill and the centre.
  Widget _readCardLayer() {
    return ReadLessonFlyLayer(
      fly: _readFly,
      curve: _readCurve,
      from: _readFrom,
      onScrimTap: () => unawaited(_tuckReadCard()),
      card: ReadLessonCard(
        atStart: _readAtStart,
        nudge: _readNudge,
        lessonLine: enDigits('পাঠ ${_pack.lessonId} · ${_pack.titleBn}'),
        onStart: () => unawaited(_startReadCard()),
        onLater: () => unawaited(_tuckReadCard()),
      ),
    );
  }

  /// The opened card, large and readable over the dimmed board. ✕ and ✓ look
  /// the same for every card; after ✓ the feedback stays under the card until
  /// the player presses "এগিয়ে যান".
  Widget _lookLayer(_Look look, bool quiet) {
    final v = _verdict;
    return Stack(
      children: [
        // Taps on the dimmed board do nothing: the card is decided by its buttons.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: const ColoredBox(color: Color(0xD9050C1C)),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, _laneHeight - 6, 12, 10),
            // Idle on the open card: the hand sweeps over ✕ and ✓ as a pair.
            child: IdleHint(
              waiting: v == null && _lookReady && !_readOpen,
              waitKey: 'look-${_asideId(look.item.id)}',
              spec: (_) => HintSpec.sweepOver([_rejectKey, _confirmKey]),
              child: LayoutBuilder(
                builder: (context, box) => Center(child: _lookCard(look, v, box, quiet)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lookCard(_Look look, _Verdict? v, BoxConstraints box, bool quiet) {
    final item = look.item;
    final opt = item is LearnBoardOption ? item : null;
    final chip = item is LearnWhyChip ? item : null;
    // Landscape: the picture beside the words and buttons.
    final wide = opt != null && box.maxWidth > box.maxHeight * 1.25;
    final width = math.min(box.maxWidth, wide ? 760.0 : 460.0);
    final small = width < 340;
    final pad = small ? 12.0 : 14.0;
    const buttonsH = 52.0;
    final border = v == null ? SlmColors.gold400.withValues(alpha: 0.7) : (v.good ? SlmColors.emerald400 : SlmColors.danger);
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFA1B2A48), Color(0xFA0D1630)],
      ),
      border: Border.all(color: border, width: 1.6),
      boxShadow: const [BoxShadow(color: Color(0xA6000000), blurRadius: 24, offset: Offset(0, 10))],
    );

    final ask = _ask.trim().isEmpty
        ? null
        : Text(
            enDigits(_ask),
            textAlign: TextAlign.center,
            style: bangla(fontSize: small ? 13.5 : 14.5, fontWeight: FontWeight.w800, height: 1.3, color: SlmColors.gold200),
          );
    final words = <Widget>[
      if (chip != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SlmColors.navy950.withValues(alpha: 0.7),
                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7)),
              ),
              child: Text(
                enDigits('${look.index + 1}'),
                style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.gold200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                enDigits(chip.textBn),
                style: bangla(fontSize: small ? 17.5 : 19, fontWeight: FontWeight.w800, height: 1.4, color: SlmColors.ivory),
              ),
            ),
          ],
        ),
      if (v != null) ...[
        const SizedBox(height: 12),
        _verdictPanel(v, small),
      ],
    ];

    Widget scroll(List<Widget> children) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );

    final Widget card;
    if (wide) {
      final h = math.min(box.maxHeight, 360.0);
      final artW = math.min((h - 2 * pad) * 0.92, width * 0.46);
      card = Container(
        width: width,
        height: h,
        padding: EdgeInsets.all(pad),
        decoration: decoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: artW, child: _lookArt(opt)),
            SizedBox(width: pad),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: scroll([?ask, ...words])),
                  const SizedBox(height: 10),
                  SizedBox(height: buttonsH, child: _lookButtons(v)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final avail = math.max(0.0, box.maxHeight - 2 * pad - buttonsH - 12 - (ask == null ? 0 : 44));
      Widget? art;
      if (opt != null) {
        // With the feedback up, the picture gives it room.
        final cap = v == null ? avail : avail * 0.42;
        final artH = math.max(96.0, math.min((width - 2 * pad) / 0.92, cap));
        art = AnimatedContainer(
          duration: quiet ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: artH,
          child: _lookArt(opt),
        );
      }
      card = Container(
        width: width,
        constraints: BoxConstraints(maxHeight: box.maxHeight),
        padding: EdgeInsets.all(pad),
        decoration: decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: scroll([
                if (ask != null) ...[ask, const SizedBox(height: 10)],
                ?art,
                ...words,
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(height: buttonsH, child: _lookButtons(v)),
          ],
        ),
      );
    }

    final framed = Semantics(
      container: true,
      label: chip != null ? enDigits(chip.textBn) : 'ছবিটা বড় করে দেখুন',
      child: KeyedSubtree(
        key: const ValueKey('board-choice-preview'),
        // Taps wait until the card has landed (no accidental ✓ on the way in).
        child: IgnorePointer(ignoring: !_lookReady, child: card),
      ),
    );
    if (quiet) return framed;
    return AnimatedBuilder(
      animation: Listenable.merge([_lookIn, _lookHit]),
      child: framed,
      builder: (_, child) {
        final t = _lookIn.value;
        var scale = 0.86 + 0.14 * Curves.easeOutBack.transform(t);
        var dx = 0.0;
        final h = _lookHit.value;
        if (v != null && h > 0 && h < 1) {
          if (v.good) {
            scale *= 1 + 0.04 * math.sin(h * math.pi);
          } else {
            dx = math.sin(h * math.pi * 7) * 9 * (1 - h);
          }
        }
        return Opacity(
          opacity: (t * 2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }

  /// The card's picture, whole (the board crops scene cards to fill a tile).
  Widget _lookArt(LearnBoardOption opt) {
    if (!opt.scene) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x660A1226),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
          child: _ItemPedestal(asset: opt.asset, accent: SlmColors.gold300),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final px = (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 1024);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: const Color(0xFF0A1226),
            child: opt.asset.endsWith('.svg')
                ? SvgPicture.asset(opt.asset, fit: BoxFit.contain)
                : Image.asset(
                    opt.asset,
                    fit: BoxFit.contain,
                    cacheWidth: px,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded, color: SlmColors.gold300),
                  ),
          ),
        );
      },
    );
  }

  /// The correct / incorrect word, the card's name and the reason.
  Widget _verdictPanel(_Verdict v, bool small) {
    final c = v.good ? SlmColors.emerald400 : SlmColors.danger;
    return Container(
      key: const ValueKey('board-choice-feedback'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.8), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                child: Icon(v.good ? Icons.check_rounded : Icons.close_rounded, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  enDigits(v.headline),
                  style: bangla(
                    fontSize: small ? 15.5 : 16.5,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    color: v.good ? SlmColors.emerald300 : SoftDanger.ink,
                  ),
                ),
              ),
            ],
          ),
          if (v.name.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              enDigits(v.name),
              style: bangla(fontSize: small ? 14.5 : 15.5, fontWeight: FontWeight.w900, height: 1.3, color: SlmColors.ivory),
            ),
          ],
          if (v.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              enDigits(v.body),
              style: bangla(fontSize: small ? 14.5 : 15.5, fontWeight: FontWeight.w700, height: 1.4, color: SlmColors.ivory),
            ),
          ],
        ],
      ),
    );
  }

  /// Before the choice: ✕ বাদ দিন · ✓ বেছে নিন (the same for every card).
  /// After it: one clear "এগিয়ে যান".
  Widget _lookButtons(_Verdict? v) {
    if (v != null) {
      return _LookButton(
        key: const ValueKey('board-choice-continue'),
        icon: Icons.arrow_forward_rounded,
        label: 'এগিয়ে যান',
        primary: true,
        iconAfter: true,
        onTap: _onContinue,
      );
    }
    return Row(
      children: [
        Expanded(
          child: KeyedSubtree(
            key: _rejectKey,
            child: _LookButton(
              key: const ValueKey('board-choice-reject'),
              icon: Icons.close_rounded,
              label: 'বাদ দিন',
              primary: false,
              onTap: _rejectLook,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KeyedSubtree(
            key: _confirmKey,
            child: _LookButton(
              key: const ValueKey('board-choice-confirm'),
              icon: Icons.check_rounded,
              label: 'বেছে নিন',
              primary: true,
              onTap: _confirmLook,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stage(bool quiet, SlmPalette palette) {
    return AnimatedSwitcher(
      duration: quiet ? Duration.zero : SlmMotion.page,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(begin: const Offset(0.04, 0.06), end: Offset.zero).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(
          (_beat == _Beat.mythSay || _beat == _Beat.mythBelieve)
              ? 'myth-encounter'
              : '$_beat-$_slot',
        ),
        child: switch (_beat) {
          _Beat.intro => _missionStage(palette, quiet),
          _Beat.pick => _pickBoard(palette, quiet),
          _Beat.why => _whyBoard(_whyOpts, palette, quiet),
          _Beat.mythSay || _Beat.mythBelieve => _rivalEncounter(palette, quiet),
          _Beat.mythWhy => _whyBoard(_whyOpts, palette, quiet),
          _Beat.award || _Beat.done => _failed ? _failStage() : _awardStage(palette, quiet),
        },
      ),
    );
  }

  Widget _missionStage(SlmPalette palette, bool quiet) {
    // A short (landscape) stage shows the same scene scaled down, never overflowing.
    return LayoutBuilder(
      builder: (context, box) {
        const minH = 460.0;
        final stage = _missionColumn(palette, quiet);
        if (box.maxHeight >= minH) return stage;
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: math.min(box.maxWidth, 520), height: minH, child: stage),
        );
      },
    );
  }

  Widget _missionColumn(SlmPalette palette, bool quiet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          SlmReveal(
            index: 0,
            child: Text(
              enDigits(_pack.badgeBn),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.gold300),
            ),
          ),
          if (_historyChip() case final chip?) ...[
            const SizedBox(height: 8),
            SlmReveal(index: 1, child: chip),
          ],
          const Spacer(flex: 1),
          SlmReveal(
            index: 1,
            rise: 22,
            child: AiLinemanGuide(
              keepBubble: true,
              sprite: 196,
              bubbleWidth: 280,
              showBubble: true,
              large: true,
              centered: true,
              onTap: () => unawaited(_onMascotTap()),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _pickBoard(SlmPalette palette, bool quiet) {
    final opts = _pickOpts.isEmpty ? _cur.options : _pickOpts;
    return Padding(
      padding: _boardPad(14),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
            // Portrait: two columns. Landscape: one row beside the coach, sized to fit.
            final wide = _landscape;
            final cols = wide ? opts.length.clamp(2, 4) : 2;
            final rows = (opts.length / cols).ceil();
            final cellW = (box.maxWidth - 14 * (cols - 1)) / cols;
            final cellH = (box.maxHeight - 14 * (rows - 1)) / rows;
            final aspect = wide && cellH > 0 ? (cellW / cellH).clamp(0.7, 1.8).toDouble() : 0.9;
            // Stuck on the pick: a hand sweeps over the cards, pressing none.
            return IdleHint(
              waiting: _beat == _Beat.pick && !_locked && !_busy && _look == null,
              waitKey: 'pick-$_slot-$_cardWave',
              spec: (size) => HintSpec.sweep(
                [
                  for (final r in HintSpec.gridCells(size: size, count: opts.length, columns: cols, aspect: aspect))
                    if (r.top < size.height - 40) r,
                ],
                space: HintSpace.local,
              ),
              child: GridView.builder(
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: aspect,
              ),
              itemCount: opts.length,
              itemBuilder: (_, i) {
                final o = opts[i];
                return _AnimatedChoiceCard(
                  key: ValueKey('pick-$_cardWave-${o.id}'),
                  index: i,
                  quiet: quiet,
                  style: _DealStyle.deal,
                  hitToken: _hitFor(o.id),
                  hitGood: _hitGood,
                  onLaunch: () => _dealCue(i),
                  child: _AsideMark(
                    aside: _isAside(o.id),
                    quiet: quiet,
                    child: _optionTile(
                      asset: o.asset,
                      scene: o.scene,
                      // The picture must carry the cue; the name shows only on the card chosen.
                      label: _hitId == o.id ? o.labelBn : '',
                      palette: palette,
                      // A tap only opens the card large; ✓ there chooses it.
                      onTapUp: (d) => _openLook(o, i, d.globalPosition),
                    ),
                  ),
                );
              },
            ),
            );
            }),
          ),
        ],
      ),
    );
  }

  bool get _landscape {
    final s = MediaQuery.sizeOf(context);
    return s.width > s.height;
  }

  /// Board padding: in portrait the cards keep clear of the coach's corner
  /// below them; on a landscape phone they stand beside him instead.
  EdgeInsets _boardPad(double side) =>
      _landscape ? EdgeInsets.fromLTRB(190, _laneHeight, side, 10) : EdgeInsets.fromLTRB(side, _laneHeight, side, 168);

  /// A scene card: the picture edge to edge (the gap to the wire must read at
  /// card size); the name slides up over it only on the card tapped.
  Widget _sceneTile({required String asset, required String label, required GestureTapUpCallback onTapUp}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTapUp: onTapUp,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55), width: 1.4),
            boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                asset.endsWith('.svg') ? SvgPicture.asset(asset, fit: BoxFit.cover) : Image.asset(asset, fit: BoxFit.cover),
                if (label.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      color: const Color(0xD90A1226),
                      child: Text(
                        enDigits(label),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bangla(fontSize: 13, fontWeight: FontWeight.w800, height: 1.2, color: SlmColors.ivory),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _whyBoard(List<LearnWhyChip> chips, SlmPalette palette, bool quiet) {
    final list = chips;
    final wave = 'why-$_beat-$_slot-$_cardWave';
    String keyId(LearnWhyChip c) => '$wave-${c.id}';
    _whyKeys.removeWhere((id, _) => !id.startsWith('$wave-'));
    return Padding(
      padding: _boardPad(16),
      child: Column(
        children: [
          Expanded(
            // Stuck on the reason: a hand sweeps over the chips, pressing none.
            child: IdleHint(
              waiting: (_beat == _Beat.why || _beat == _Beat.mythWhy) && !_locked && !_busy && _look == null,
              waitKey: wave,
              spec: (_) => HintSpec.sweepOver([
                for (final c in list) ?_whyKeys[keyId(c)],
              ]),
              child: ListView.separated(
              clipBehavior: Clip.none,
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final c = list[i];
                final hot = _pickedWhy == c.id;
                return _AnimatedChoiceCard(
                  key: ValueKey('why-$_cardWave-${c.id}'),
                  index: i,
                  quiet: quiet,
                  style: _DealStyle.slide,
                  hitToken: _hitFor(c.id),
                  hitGood: _hitGood,
                  onLaunch: () => _dealCue(i),
                  child: _AsideMark(
                    aside: _isAside(c.id),
                    quiet: quiet,
                    child: Material(
                    key: _whyKeys.putIfAbsent(keyId(c), GlobalKey.new),
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      // A tap only opens the reason large; ✓ there chooses it.
                      onTapUp: (d) => _openLook(c, i, d.globalPosition),
                      child: AnimatedContainer(
                        duration: quiet ? Duration.zero : SlmMotion.fast,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hot
                                ? (c.correct
                                    ? [
                                        SlmColors.emerald500.withValues(alpha: 0.32),
                                        SlmColors.navy800,
                                      ]
                                    : [
                                        SlmColors.danger.withValues(alpha: 0.32),
                                        SlmColors.navy800,
                                      ])
                                : [
                                    SlmColors.navy800,
                                    SlmColors.navy900,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hot
                                ? (c.correct ? SlmColors.emerald400 : SlmColors.danger)
                                : SlmColors.gold400.withValues(alpha: 0.45),
                            width: hot ? 1.8 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SlmColors.gold400.withValues(alpha: hot ? 0.28 : 0.12),
                              blurRadius: hot ? 22 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SlmColors.navy950.withValues(alpha: 0.7),
                                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7)),
                              ),
                              child: Text(
                                enDigits('${i + 1}'),
                                style: bangla(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: SlmColors.gold200,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                enDigits(c.textBn),
                                textAlign: TextAlign.left,
                                style: bangla(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  color: SlmColors.ivory,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rivalEncounter(SlmPalette palette, bool quiet) {
    final believe = _beat == _Beat.mythBelieve;
    final Widget scene;
    if (_rivalOnStage) {
      // Bubble lane sits above him and never moves with his body, so lines
      // stay readable while he lunges.
      final stage = Column(
        children: [
          SizedBox(
            height: 150,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: quiet ? Duration.zero : const Duration(milliseconds: 280),
                reverseDuration: quiet ? Duration.zero : const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.72, end: 1).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
                child: _rivalBubbleBn.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('rival-quiet'))
                    : _rivalMythBubble(palette),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: _rivalStage(palette, quiet),
            ),
          ),
        ],
      );
      scene = quiet
          ? stage
          : AnimatedBuilder(
              animation: _stageShake,
              child: stage,
              builder: (_, child) {
                final s = _stageShake.value;
                final fade = 1 - s;
                return Transform.translate(
                  offset: Offset(
                    math.sin(s * math.pi * 9) * 8 * fade,
                    math.cos(s * math.pi * 7) * 4 * fade,
                  ),
                  child: child,
                );
              },
            );
    } else if (believe) {
      // Rival gone: coach steps to center for the belief ask.
      scene = Align(
        alignment: Alignment.bottomCenter,
        child: SlmReveal(
          index: 0,
          rise: 18,
          child: AiLinemanGuide(
            keepBubble: true,
            sprite: 168,
            bubbleWidth: 240,
            showBubble: true,
            large: true,
            centered: true,
            onTap: () => unawaited(_onMascotTap()),
          ),
        ),
      );
    } else {
      scene = const SizedBox.expand();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      child: Column(
        children: [
          Expanded(child: scene),
          if (believe && !_rivalDefeated && _askReady) ...[
            const SizedBox(height: 8),
            Text(
              // On a flipped ask the bubble asks "…সেটা কি ভুল?"; the heading matches it.
              _askFlipped ? 'সেটা কি ভুল?' : 'বিশ্বাস করেন?',
              style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: palette.accent),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SlmReveal(
                    index: 0,
                    child: _bigChoice(
                      label: 'হ্যাঁ',
                      color: palette.primary,
                      onTapUp: (d) => _onBelieve(true, d.globalPosition),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SlmReveal(
                    index: 1,
                    child: _bigChoice(
                      label: 'না',
                      color: palette.primary,
                      onTapUp: (d) => _onBelieve(false, d.globalPosition),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  static const _rivalBox = Size(340, 300);
  static const _rivalSize = 210.0;

  /// Rival on his spot, with dust on landing and the warning tags around him.
  Widget _rivalStage(SlmPalette palette, bool quiet) {
    final hints = _pack.myth.dangerHints;
    return SizedBox(
      width: _rivalBox.width,
      height: _rivalBox.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _rivalBody(quiet)),
          if (!quiet)
            Positioned(
              left: 0,
              right: 0,
              bottom: -20,
              height: 90,
              child: IgnorePointer(
                child: SlmSparkBurst(
                  trigger: _rivalLandToken,
                  radius: 120,
                  count: 18,
                  colors: const [
                    Color(0xFFB8A58C),
                    Color(0xFF8C7B66),
                    Color(0xFFD6C7B0),
                    Color(0xFFFF8A65),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < hints.length && i < _rivalLayers; i++)
            _dangerCallout(i, hints[i], palette, quiet),
        ],
      ),
    );
  }

  /// Rush in (lean + stretch) → stomp squash → idle bob with a lunge per line
  /// → turn on the spot → storm off. Only this subtree rebuilds per frame.
  Widget _rivalBody(bool quiet) {
    final myth = _pack.myth;
    if (quiet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: MythRivalPuppet(
          size: _rivalSize,
          bodyAsset: myth.bodyAsset,
          phase: 0,
          speaking: false,
          reduce: true,
        ),
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_rivalEnter, _rivalBob, _rivalExit, _rivalJab]),
      builder: (_, _) {
        final e = _rivalEnter.value;
        final x = _rivalExit.value;
        final travel = Curves.easeOutCubic.transform((e / _rivalLandAt).clamp(0.0, 1.0));
        final rush = 1 - travel;
        final land = e < _rivalLandAt ? 0.0 : (e - _rivalLandAt) / (1 - _rivalLandAt);
        final squash = math.sin(land * math.pi) * 0.13 * (1 - 0.4 * land);

        final turn = Curves.easeInOutCubic.transform((x / 0.32).clamp(0.0, 1.0));
        final dash = Curves.easeInCubic.transform(((x - 0.26) / 0.74).clamp(0.0, 1.0));
        final facing = 1 - 2 * turn;

        final jab = math.sin(_rivalJab.value * math.pi);
        final bobT = _rivalBob.value * math.pi * 2;
        final bob = math.sin(bobT) * 4.0;

        final dx = rush * 430 + dash * 470 - jab * 12;
        final dy = bob - rush * 26 + squash * 10 - jab * 4;
        final angle = -0.24 * rush + 0.20 * dash - 0.07 * jab + math.sin(bobT * 0.5) * 0.03;
        final sx = (1 + 0.10 * rush + 0.65 * squash + 0.05 * jab) * facing;
        final sy = 1 - 0.06 * rush - squash + 0.04 * jab;
        final alpha = ((e * 5).clamp(0.0, 1.0) * (1 - dash)).clamp(0.0, 1.0);

        return Opacity(
          opacity: alpha,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Floor shadow stays on the ground while he bobs.
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 120 * (1 + squash * 1.6 + 0.06 * jab),
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomCenter,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(sx, sy, 1),
                      child: MythRivalPuppet(
                        size: _rivalSize,
                        bodyAsset: myth.bodyAsset,
                        phase: _rivalBob.value,
                        speaking: _rivalVoice && RivalTalk.active.value,
                        reduce: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tag i points at the matching body part: helmet, hands, feet.
  Widget _dangerCallout(int i, String text, SlmPalette palette, bool quiet) {
    const tops = [44.0, 150.0, 246.0];
    final left = i.isEven;
    final top = i < tops.length ? tops[i] : 44.0 + i * 96;
    final tag = Container(
      constraints: const BoxConstraints(maxWidth: 128),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A0D12), Color(0xFF1C070A)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.danger, width: 1.4),
        boxShadow: [
          BoxShadow(color: palette.danger.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.danger, shape: BoxShape.circle),
            child: const Text(
              '!',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              enDigits(text),
              style: bangla(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: SoftDanger.ink,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    final tilt = left ? -0.05 : 0.05;
    return Positioned(
      top: top,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: AnimatedOpacity(
        opacity: _tagsShown ? 1 : 0,
        duration: quiet ? Duration.zero : const Duration(milliseconds: 220),
        child: quiet
            ? Transform.rotate(angle: tilt, child: tag)
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                child: tag,
                builder: (_, t, child) => Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: tilt + (1 - t) * (left ? -0.35 : 0.35),
                    child: Transform.scale(scale: 1.7 - 0.7 * t, child: child),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _rivalMythBubble(SlmPalette palette) {
    return ConstrainedBox(
      key: ValueKey(_rivalBubbleBn),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B0C14), Color(0xFF22070C)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.danger, width: 1.8),
              boxShadow: [
                BoxShadow(color: palette.danger.withValues(alpha: 0.40), blurRadius: 20, spreadRadius: 1),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'অসাবধান লাইনম্যান',
                    style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enDigits(_rivalBubbleBn),
                  textAlign: TextAlign.center,
                  style: bangla(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: SlmColors.ivory,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(26, 14),
            painter: _BubbleTailPainter(
              fill: const Color(0xFF22070C),
              stroke: palette.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigChoice({
    required String label,
    required Color color,
    required GestureTapUpCallback onTapUp,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTapUp: onTapUp,
        child: Container(
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: color, width: 1.8),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Text(label, style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ),
      ),
    );
  }

  /// This run's decision time, the saved best, and a record ribbon when beaten.
  Widget _timeSummary(SlmPalette palette) {
    final best = _bestMs;
    return Column(
      children: [
        if (_newRecord)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Color(0x99F59E0B), blurRadius: 16)],
            ),
            child: Text(
              'নতুন রেকর্ড!',
              style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF1A1408)),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_runMark != null) ...[
              _markStat(_runMark!),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: SlmColors.gold400.withValues(alpha: 0.4),
              ),
            ],
            _timeStat('সময়', _finalMs!, SlmColors.ivory),
            if (best != null) ...[
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: SlmColors.gold400.withValues(alpha: 0.4),
              ),
              _timeStat('সেরা', best, SlmColors.gold300),
            ],
          ],
        ),
      ],
    );
  }

  Widget _markStat(int mark) {
    return Column(
      children: [
        Text('নম্বর', style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.mist)),
        const SizedBox(height: 2),
        Text(
          enDigits('$mark%'),
          style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: SlmColors.emerald300),
        ),
      ],
    );
  }

  Widget _timeStat(String label, int ms, Color color) {
    return Column(
      children: [
        Text(label, style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.mist)),
        const SizedBox(height: 2),
        Text(
          _fmtClock(ms ~/ 1000),
          style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _awardStage(SlmPalette palette, bool quiet) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 36)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 84, color: palette.accent),
              Positioned.fill(
                child: OverflowBox(
                  maxWidth: 220,
                  maxHeight: 220,
                  child: SlmSparkBurst(trigger: _beat, playOnMount: true, radius: 110, count: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            enDigits(_pack.badgeBn),
            textAlign: TextAlign.center,
            style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: palette.accent),
          ),
          if (_finalMs != null) ...[
            const SizedBox(height: 14),
            SlmReveal(index: 0, child: _timeSummary(palette)),
          ],
          if (_history.plays > 0) ...[
            const SizedBox(height: 10),
            SlmReveal(
              index: 1,
              child: LevelHistoryChip(plays: _history.plays, bestMark: _history.best),
            ),
          ],
          const SizedBox(height: 20),
          AiLinemanGuide(
            keepBubble: true,
            sprite: 168,
            bubbleWidth: 220,
            showBubble: true,
            large: true,
            centered: true,
            onTap: () => unawaited(_onMascotTap()),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String asset,
    required String label,
    required SlmPalette palette,
    required GestureTapUpCallback onTapUp,
    bool scene = false,
  }) {
    if (scene) return _sceneTile(asset: asset, label: label, onTapUp: onTapUp);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTapUp: onTapUp,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF01B2A48), Color(0xF00D1630)],
            ),
            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x8C000000), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: _ItemPedestal(asset: asset, accent: SlmColors.gold300),
                ),
              ),
              // Fixed two-line label band so every tile's art shares one baseline.
              Container(
                height: 46,
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: Color(0x660A1226),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                  border: Border(top: BorderSide(color: Color(0x33F5D27A))),
                ),
                child: Text(
                  enDigits(label),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step progress, top-left of the reserved lane.
  Widget _stepPips(SlmPalette palette) {
    final total = _pack.slots.length + 1;
    final current = _beat == _Beat.mythWhy ? total - 1 : _slot;
    return Positioned(
      top: 14,
      left: 18,
      child: IgnorePointer(
        child: Row(
          children: [
            Text(
              'ধাপ ${enDigits('${current + 1}')}/${enDigits('$total')}',
              style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.gold200),
            ),
            const SizedBox(width: 10),
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: SlmMotion.base,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 5),
                width: i == current ? 22 : 9,
                height: 9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i < current
                      ? SlmColors.emerald400
                      : i == current
                          ? SlmColors.gold300
                          : SlmColors.navy700,
                ),
              ),
            const SizedBox(width: 8),
            _ClockChip(seconds: _clockSec),
          ],
        ),
      ),
    );
  }

  /// Pending ◆ chip: lives in the top lane, right side, never over the cards.
  Widget _pendingDock(bool quiet, SlmPalette palette) {
    return Positioned(
      top: 4,
      right: 12,
      child: IgnorePointer(
        child: SizedBox(
          key: _pendingDockKey,
          width: 112,
          height: 46,
          child: _PendingChip(
            pending: _pending,
            burning: _burning,
            fxToken: _pendingFxToken,
            quiet: quiet,
            celebrate: _celebrate,
            burn: _burn,
          ),
        ),
      ),
    );
  }
}

class _PendingChip extends StatefulWidget {
  const _PendingChip({
    required this.pending,
    required this.burning,
    required this.fxToken,
    required this.quiet,
    required this.celebrate,
    required this.burn,
  });

  final int pending;
  final bool burning;
  final int fxToken;
  final bool quiet;
  final Animation<double> celebrate;
  final Animation<double> burn;

  @override
  State<_PendingChip> createState() => _PendingChipState();
}

class _PendingChipState extends State<_PendingChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760));

  void _sync() => slmSyncLoop(
        context,
        _pulse,
        enabled: !widget.quiet && widget.pending > 0 && !widget.burning,
        reverse: true,
        restAt: 0.5,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_PendingChip old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final burning = widget.burning;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: burning
              ? const [Color(0xFFF87171), Color(0xFFB91C1C)]
              : const [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: burning ? const Color(0xFFFFB4B4) : const Color(0xFFFFF7D6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: burning ? const Color(0x99EF4444) : const Color(0x99F59E0B),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(
        burning ? 'নষ্ট' : '+${enDigits('${widget.pending}')} ◆',
        style: bangla(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1A1408),
          height: 1.05,
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.pending > 0 && !widget.quiet)
          SlmSparkBurst(trigger: widget.fxToken, radius: 70, count: 16),
        if (widget.quiet)
          chip
        else
          AnimatedBuilder(
            animation: Listenable.merge([_pulse, widget.celebrate, widget.burn]),
            child: chip,
            builder: (_, child) {
              final pulse = 0.96 + 0.08 * _pulse.value;
              final pop = Curves.easeOutBack.transform(widget.celebrate.value.clamp(0.0, 1.0));
              final burnT = burning ? widget.burn.value : 0.0;
              return Opacity(
                opacity: (1 - burnT).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 22 * burnT),
                  child: Transform.rotate(
                    angle: 0.35 * burnT,
                    child: Transform.scale(
                      scale: pulse * (0.7 + 0.3 * pop) * (1 - 0.25 * burnT),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

enum _DealStyle {
  /// Grid tiles flicked off a deck below the board, spinning into place.
  deal,

  /// List rows swept in from the right edge.
  slide,
}

/// Choice card motion: dealt in with a landing squash and a glint, presses
/// down under the finger, shakes on a wrong hit and pops on a right one.
/// All one-shot; nothing loops.
class _AnimatedChoiceCard extends StatefulWidget {
  final int index;
  final bool quiet;
  final _DealStyle style;
  final int hitToken;
  final bool hitGood;
  final VoidCallback? onLaunch;
  final Widget child;

  const _AnimatedChoiceCard({
    super.key,
    required this.index,
    required this.quiet,
    required this.child,
    this.style = _DealStyle.deal,
    this.hitToken = 0,
    this.hitGood = false,
    this.onLaunch,
  });

  @override
  State<_AnimatedChoiceCard> createState() => _AnimatedChoiceCardState();
}

class _AnimatedChoiceCardState extends State<_AnimatedChoiceCard> with TickerProviderStateMixin {
  static const _landAt = 0.74;

  late final AnimationController _deal = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.style == _DealStyle.deal ? 680 : 560),
  );
  late final AnimationController _hit =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  Timer? _delay;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _deal.value = 1;
      if (widget.index == 0) widget.onLaunch?.call();
      return;
    }
    final stagger = widget.style == _DealStyle.deal ? 110 : 120;
    _delay = Timer(Duration(milliseconds: 80 + widget.index * stagger), () {
      if (!mounted) return;
      widget.onLaunch?.call();
      _deal.forward();
    });
  }

  @override
  void didUpdateWidget(_AnimatedChoiceCard old) {
    super.didUpdateWidget(old);
    if (widget.hitToken != old.hitToken && widget.hitToken != 0 && !widget.quiet) {
      _hit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _deal.dispose();
    _hit.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final card = Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    if (widget.quiet) return card;

    final width = MediaQuery.sizeOf(context).width;
    final deal = widget.style == _DealStyle.deal;
    final leftCol = widget.index.isEven;

    return AnimatedBuilder(
      animation: Listenable.merge([_deal, _hit]),
      child: card,
      builder: (_, child) {
        final t = _deal.value;
        final travel = Curves.easeOutCubic.transform((t / _landAt).clamp(0.0, 1.0));
        final rest = 1 - travel;
        final land = t < _landAt ? 0.0 : (t - _landAt) / (1 - _landAt);
        final squash = math.sin(land * math.pi) * 0.07;

        double dx, dy, angle, scale;
        if (deal) {
          dx = rest * (leftCol ? 110 : -110);
          dy = rest * 320;
          angle = rest * (leftCol ? -0.7 : 0.7);
          scale = 0.5 + 0.5 * travel;
        } else {
          dx = rest * width * 0.85;
          dy = rest * 18;
          angle = rest * 0.14;
          scale = 0.92 + 0.08 * travel;
        }

        final h = _hit.value;
        if (h > 0 && h < 1) {
          if (widget.hitGood) {
            scale *= 1 + 0.09 * math.sin(h * math.pi);
            dy -= 8 * math.sin(h * math.pi);
          } else {
            final fade = 1 - h;
            dx += math.sin(h * math.pi * 7) * 11 * fade;
            angle += math.sin(h * math.pi * 7) * 0.035 * fade;
          }
        }

        final glint = t <= _landAt ? -1.0 : land;
        return Opacity(
          opacity: (t * 4).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(scale * (1 + squash), scale * (1 - squash), 1),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Picture cards light up with a soft halo behind the card, not
                    // the crisp outline of a text chip.
                    if (deal && h > 0 && h < 1)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.hitGood ? SlmColors.emerald400 : SlmColors.danger)
                                      .withValues(alpha: 0.7 * math.sin(h * math.pi)),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    child!,
                    if (glint > 0 && glint < 1)
                      Positioned.fill(child: IgnorePointer(child: _Glint(t: glint))),
                    if (!deal && h > 0 && h < 1)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (widget.hitGood ? SlmColors.emerald400 : SlmColors.danger)
                                    .withValues(alpha: math.sin(h * math.pi)),
                                width: 2.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One diagonal light sweep across a card as it lands.
class _Glint extends StatelessWidget {
  const _Glint({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Align(
        alignment: Alignment(-1.8 + 3.6 * t, 0),
        child: FractionallySizedBox(
          widthFactor: 0.32,
          heightFactor: 1.6,
          child: Transform.rotate(
            angle: 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.26),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Downward speech tail under the rival's bubble.
class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -1);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.fill != fill || old.stroke != stroke;
}

String _fmtClock(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return enDigits('$m:${s.toString().padLeft(2, '0')}');
}

/// Count-up decision clock. Only this chip rebuilds, once a second.
class _ClockChip extends StatelessWidget {
  const _ClockChip({required this.seconds});

  final ValueListenable<int> seconds;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: seconds,
      builder: (_, s, _) {
        final slow = s >= 15;
        final color = slow ? const Color(0xFFFBBF24) : SlmColors.ivory;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xB30A1226),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                _fmtClock(s),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Same world as the ladder (pole line, river, hills) graded to night so the
/// cards read on top. Static: no clocks, its own layer.
class _LearnBackdrop extends StatelessWidget {
  const _LearnBackdrop({required this.tint, required this.quiet});

  final Color tint;
  final bool quiet;

  static const _plate = 'assets/duty_slip/world3d/depth_mid_river.webp';
  static const _frame = 'assets/duty_slip/world3d/depth_near_a.webp';

  @override
  Widget build(BuildContext context) {
    final px = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 720);
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: SlmColors.navy950),
            Image.asset(
              _plate,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.35),
              cacheWidth: px,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8C07122A), Color(0xD907112A), Color(0xF5050C1C)],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
            Opacity(
              opacity: 0.75,
              child: Image.asset(
                _frame,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                cacheWidth: px,
                color: const Color(0xFF26343A),
                colorBlendMode: BlendMode.modulate,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            AnimatedContainer(
              duration: quiet ? Duration.zero : SlmMotion.page,
              curve: Curves.easeInOutCubic,
              color: tint,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.15,
                  colors: [Color(0x00000000), Color(0x99000000)],
                  stops: [0.55, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item art on a lit pedestal: every item stands on the same baseline at the
/// same visual weight, whatever its aspect ratio.
class _ItemPedestal extends StatelessWidget {
  const _ItemPedestal({required this.asset, required this.accent});

  final String asset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final floor = h * 0.86;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Warm spotlight behind the item.
            Positioned(
              left: w * 0.06,
              right: w * 0.06,
              top: h * 0.02,
              height: h * 0.9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.6, 1],
                  ),
                ),
              ),
            ),
            // Pedestal disc + contact shadow on one shared floor line.
            Positioned(
              left: w * 0.16,
              right: w * 0.16,
              top: floor - 9,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.12,
              right: w * 0.12,
              top: floor - 2,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0),
                      accent.withValues(alpha: 0.55),
                      accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: w * 0.1,
              right: w * 0.1,
              top: h * 0.08,
              height: floor - h * 0.08,
              // Scene cards (lesson 1.2 on) are vector art; photos keep the decode cap.
              child: asset.endsWith('.svg')
                  ? SvgPicture.asset(asset, fit: BoxFit.contain, alignment: Alignment.bottomCenter)
                  : Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      cacheWidth: (w * 0.8 * dpr).round().clamp(1, 512),
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Icon(Icons.image_not_supported_rounded, color: accent),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A card set aside with ✕: dimmed with a grey "বাদ" tag — not red, since
/// nothing was judged. Tapping it opens it again.
class _AsideMark extends StatelessWidget {
  const _AsideMark({required this.aside, required this.quiet, required this.child});

  final bool aside;
  final bool quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        AnimatedOpacity(
          opacity: aside ? 0.42 : 1,
          duration: quiet ? Duration.zero : SlmMotion.fast,
          child: child,
        ),
        if (aside)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: Container(
                key: const ValueKey('board-card-aside'),
                padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
                decoration: BoxDecoration(
                  color: const Color(0xE6202A3C),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SlmColors.mist.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded, size: 13, color: SlmColors.mist),
                    const SizedBox(width: 3),
                    Text('বাদ', style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: SlmColors.mist, height: 1.1)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ✕ / ✓ / এগিয়ে যান on the opened card: 52 dp tall, one look for every card.
class _LookButton extends StatelessWidget {
  const _LookButton({
    super.key,
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.iconAfter = false,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final bool iconAfter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = primary ? SlmColors.navy950 : SlmColors.ivory;
    final glyph = Icon(icon, size: 22, color: ink);
    final text = Text(label, maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: ink, height: 1.1));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: primary ? SlmGradients.gold : null,
              color: primary ? null : SlmColors.navy900,
              border: Border.all(
                color: primary ? SlmColors.gold200 : SlmColors.ivory.withValues(alpha: 0.55),
                width: 1.4,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: iconAfter
                        ? [text, const SizedBox(width: 8), glyph]
                        : [glyph, const SizedBox(width: 6), text],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim Learn chrome: close · `L<n>` · live ◆ · 💀 · পাঠ. The level's name is
/// for screen readers only; sound is not toggled here. Everything scales with
/// the width (320 dp phones to landscape) and never overflows.
class _LearnBoardChrome extends ConsumerStatefulWidget {
  final GlobalKey scoreKey;

  /// The ladder step, shown as `L<n>` (the same number on every level).
  final int step;

  /// The level's name: read out by screen readers, never drawn.
  final String title;

  /// This play's score: the pill shows it; the main total sits beside it.
  final int levelScore;
  final bool dimmed;
  final VoidCallback onClose;
  final VoidCallback onReadLesson;

  /// The coach has suggested reading: the পাঠ button lights up.
  final bool readHot;

  const _LearnBoardChrome({
    required this.scoreKey,
    required this.step,
    required this.title,
    required this.levelScore,
    required this.dimmed,
    required this.onClose,
    required this.onReadLesson,
    required this.readPillKey,
    this.readHot = false,
  });

  final GlobalKey readPillKey;

  @override
  ConsumerState<_LearnBoardChrome> createState() => _LearnBoardChromeState();
}

class _LearnBoardChromeState extends ConsumerState<_LearnBoardChrome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump;
  int? _lastPoints;

  /// Last change was a loss: the pill dips and flashes red instead of popping.
  var _down = false;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameSaveProvider);
    final shown = widget.levelScore;
    if (_lastPoints != null && _lastPoints != shown) {
      _down = shown < _lastPoints!;
      _bump.forward(from: 0);
    }
    _lastPoints = shown;

    return AnimatedOpacity(
      duration: SlmMotion.base,
      opacity: widget.dimmed ? 0.45 : 1,
      child: LayoutBuilder(
        builder: (context, box) {
          // 400 dp and wider: full size; a 320 dp phone: 82 %.
          final f = UnifiedGameTopHud.scaleFor(box.maxWidth);
          final target = math.max(40.0, 44 * f);
          return SizedBox(
            height: math.max(48.0, 52 * f),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * f),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    tooltip: 'বন্ধ করুন',
                    icon: Icon(Icons.close_rounded, color: SlmColors.ivory, size: 24 * f),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: target, height: target),
                  ),
                  SizedBox(width: 4 * f),
                  LadderStepBadge(key: const ValueKey('board-level-tag'), step: widget.step, title: widget.title, scale: f),
                  SizedBox(width: 8 * f),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      // Last resort on a very narrow screen: the cluster shrinks, never overflows.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _scorePill(shown, f),
                            SizedBox(width: 6 * f),
                            DeathCountChip(deaths: save.deaths, scale: f),
                            SizedBox(width: 2 * f),
                            // Icon-only, with its own 44 dp touch target.
                            ReadLessonPill(key: widget.readPillKey, hot: widget.readHot, onTap: widget.onReadLesson),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scorePill(int shown, double f) {
    return AnimatedBuilder(
                animation: _bump,
                builder: (_, child) {
                  final wave = math.sin(_bump.value * math.pi);
                  if (!_down) {
                    return Transform.scale(scale: 1.0 + 0.55 * wave, child: child);
                  }
                  final fade = 1 - _bump.value;
                  return Transform.translate(
                    offset: Offset(math.sin(_bump.value * math.pi * 8) * 6 * fade, 0),
                    child: Transform.scale(
                      scale: 1.0 - 0.12 * wave,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: SlmColors.danger.withValues(alpha: 0.8 * wave),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Container(
                  key: widget.scoreKey,
                  padding: EdgeInsets.symmetric(horizontal: 12 * f, vertical: 6 * f),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2B45), Color(0xFF111A2E)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.7), width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: SlmColors.gold400.withValues(alpha: 0.55),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('◆', style: TextStyle(color: SlmColors.gold300, fontSize: 13 * f)),
                      SizedBox(width: 5 * f),
                      Text(
                        enDigits('$shown'),
                        style: bangla(
                          fontSize: 15 * f,
                          fontWeight: FontWeight.w900,
                          color: SlmColors.ivory,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}