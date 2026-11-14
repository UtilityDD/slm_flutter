import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/services/neural_tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../home/bangla_read_aloud.dart';
import '../home/lesson_progress_store.dart';
import '../home/lesson_quiz_page.dart';
import '../home/lesson_quiz_store.dart';
import '../home/lesson_reader_page.dart';
import '../identify/fit_image.dart';
import '../shell/shell_providers.dart';
import '../training/training_models.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../training/training_provider.dart';
import 'beat_fx.dart';
import 'choice_deck.dart' show CardAside, CardPreviewOverlay;
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'lesson_day_card.dart';
import 'lesson_promise_card.dart';
import 'level_result_parts.dart';
import 'read_lesson_offer.dart';

/// Two questions built from the lesson's own points, for a lesson whose server
/// copy has no quiz file: "which check belongs to this item?". Empty when fewer
/// than 3 points carry a daily check; the deck then clears on its cards, as the
/// reader does for a lesson without a quiz. Never invents content.
List<LessonQuizQuestion> learnQuizFromPoints(List<LessonSectionPoint> points, [math.Random? rng]) {
  final checks = <String, String>{}; // item name → its check, one per distinct check
  for (final p in points) {
    final name = p.itemName.trim();
    final check = MascotSpeechLibrary.conciseFieldRule(p.dailyCheck ?? '', maxChars: 110);
    if (name.isEmpty || check.isEmpty || checks.containsValue(check)) continue;
    checks[name] = check;
  }
  if (checks.length < 3) return const [];
  final r = rng ?? math.Random();
  final names = checks.keys.toList()..shuffle(r);
  return [
    for (final name in names.take(2))
      () {
        final others = [for (final n in names) if (n != name) checks[n]!]..shuffle(r);
        final options = [checks[name]!, ...others.take(2)]..shuffle(r);
        return LessonQuizQuestion(
          questionText: '$name — কাজের আগে কোন চেকটা করবেন?',
          options: options,
          correctIndex: options.indexOf(checks[name]!),
        );
      }(),
  ];
}

/// Interactive Ladder Learn Deck — visual-first field flash-cards with
/// 1-tap pre-work checks (+5 ◆), unified Mascot lip-sync coaching, and
/// 2 quick-fire field decisions (+10 ◆ / -5 ◆) + 20 ◆ completion burst.
class LearnRunnerPage extends StatefulWidget {
  final String rungId;
  final String lessonId;
  final int ladderIndex;
  final bool muted;

  const LearnRunnerPage({
    super.key,
    required this.rungId,
    required this.lessonId,
    required this.ladderIndex,
    this.muted = false,
  });

  @override
  State<LearnRunnerPage> createState() => _LearnRunnerPageState();
}

/// "আবার খেলুন" after a fail starts a fresh run on the same route, so the
/// ladder keeps waiting for this level's real result.
class _LearnRunnerPageState extends State<LearnRunnerPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) {
    return _LearnRun(
      key: ValueKey(_round),
      rungId: widget.rungId,
      ladderIndex: widget.ladderIndex,
      lessonId: widget.lessonId,
      muted: _muted,
      onRetry: (muted) => setState(() {
        _muted = muted;
        _round++;
      }),
    );
  }
}

class _LearnRun extends ConsumerStatefulWidget {
  final String rungId;
  final int ladderIndex;
  final String lessonId;
  final bool muted;
  final ValueChanged<bool> onRetry;

  const _LearnRun({
    required this.ladderIndex,
    super.key,
    required this.rungId,
    required this.lessonId,
    required this.muted,
    required this.onRetry,
  });

  @override
  ConsumerState<_LearnRun> createState() => _LearnRunState();
}

enum _Phase { load, cards, quiz, done }

class _LearnRunState extends ConsumerState<_LearnRun> with SingleTickerProviderStateMixin {
  final _scoreKey = GlobalKey();
  final _deathKey = GlobalKey();

  /// Time from opening the level to its result, for the league's speed check.
  final _playClock = Stopwatch()..start();

  /// "Read the lesson" card: 0 = tucked into the পাঠ pill, 1 = open over the quiz.
  late final AnimationController _readFly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    reverseDuration: const Duration(milliseconds: 460),
  );
  late final CurvedAnimation _readCurve =
      CurvedAnimation(parent: _readFly, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
  final _readPillKey = GlobalKey();
  final _layerKey = GlobalKey();
  Offset _readFrom = Offset.zero;
  var _readOpen = false;
  var _readHot = false;
  var _readShown = false;
  ReadNudge? _readNudge;
  Completer<void>? _endOfferDone;

  /// First-try mark for the pass line; earlier plays of this level.
  final _marks = LessonMarks();
  var _failed = false;
  int? _runMark;
  late final ({int plays, int? best}) _history;

  late final PageController _pages;
  late final BanglaReadAloud _voice;
  late final NeuralTtsService _neural;

  _Phase _phase = _Phase.load;
  LessonCardItem? _lesson;
  List<LessonSectionPoint> _points = const [];
  List<LessonQuizQuestion> _quiz = const [];
  final Set<int> _checkedCards = <int>{};

  /// This play's level score: every ◆ won or lost flies into it; when the
  /// level ends it replaces this level's last score in the main ◆.
  int _runScore = 0;
  int _card = 0;
  int _q = 0;
  int? _picked;
  bool _revealed = false;

  /// The option open big (two steps: its preview, then ✓ answers), where it
  /// was tapped, and the options set aside with ✕ on this question.
  int? _preview;
  Offset _previewAt = Offset.zero;
  final Set<int> _aside = {};
  bool _speaking = false;
  bool _voiceBusy = false;
  bool _muted = false;
  bool _finishing = false;

  /// Set once the clear is saved: leaving now still counts as a pass.
  bool _passed = false;
  bool _popped = false;
  int _listenRun = 0;
  bool _neuralRun = false;

  bool get _bn => ref.read(languageProvider);

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    final save = ref.read(gameSaveProvider);
    _history = (plays: save.playsByRung[widget.rungId] ?? 0, best: save.bestMarkByRung[widget.rungId]);
    _pages = PageController();
    _voice = BanglaReadAloud();
    _neural = NeuralTtsService();
    _voice.onSpeakingChanged = (v) {
      if (!mounted || _neuralRun) return;
      if (v) {
        MascotTalk.begin();
      } else {
        MascotTalk.end();
      }
      setState(() => _speaking = v);
    };
    _neural.onSpeakingChanged = (v) {
      if (!mounted) return;
      if (v) {
        MascotTalk.begin();
      } else {
        MascotTalk.end();
      }
      setState(() {
        _speaking = v;
        if (v) _voiceBusy = false;
      });
    };
    _voice.init();
    unawaited(_boot());
  }

  @override
  void dispose() {
    unawaited(_stopVoice());
    _endOfferFinish();
    MascotTalk.reset();
    _readCurve.dispose();
    _readFly.dispose();
    _pages.dispose();
    _neural.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final parts = widget.lessonId.split('.');
    final module = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 1;
    final chapter = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;

    LessonCardItem? hit;
    var quizLoad = LessonQuizLoad.unavailable;

    try {
      // A dead connection must reach the offline dialog, not spin forever
      // (a failed provider is retried, so its future may never complete).
      final lessons = await ref
          .read(moduleLessonsProvider(module).future)
          .timeout(const Duration(seconds: 12));
      for (final l in lessons) {
        if (l.chapterNumber == chapter) {
          hit = l;
          break;
        }
      }
      quizLoad = await LessonQuizStore.instance.load(module, chapter);
    } catch (_) {
      // Offline with nothing saved: handled below, never with made-up content.
    }

    // Never play (or pass) a lesson without its own points and quiz (AGENTS §4).
    if (hit == null || hit.points.isEmpty || quizLoad.status == LessonQuizStatus.unavailable) {
      if (!mounted) return;
      final retry = await showLessonQuizOfflineDialog(context, bn: _bn);
      if (!mounted) return;
      if (retry == true) {
        await _boot();
      } else {
        _popOnce(false);
      }
      return;
    }

    final quiz = quizLoad.isReady
        ? selectLearnExitQuestions(quizLoad.questions)
        : learnQuizFromPoints(hit.points);

    if (!mounted) return;
    setState(() {
      _lesson = hit;
      _points = hit!.points;
      _quiz = quiz;
      _phase = _Phase.cards;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // First play of the lesson: the day card sets the scene before the cards.
      await showLessonDayCard(context, ref, lessonId: widget.lessonId, rungId: widget.rungId, muted: _muted);
      if (!mounted) return;
      ref.read(guideDirectorProvider.notifier).sayCue(
            MascotCueId.learnDeckStart,
            speakVoice: false,
            muted: _muted,
          );
      unawaited(_speakCard(0));
    });
  }

  Future<void> _stopVoice() async {
    _listenRun++;
    _neuralRun = false;
    // Coach lines from the director (fail, nudge, praise) must not outlive the run.
    unawaited(MascotSpeechLibrary.stop());
    await _neural.stop();
    await _voice.stop();
    MascotTalk.reset();
    if (mounted) {
      setState(() {
        _speaking = false;
        _voiceBusy = false;
      });
    }
  }

  Future<void> _speakCard(int index) async {
    if (_muted || index < 0 || index >= _points.length) return;
    final p = _points[index];
    final head = MascotSpeechLibrary.toNaturalFieldBangla(p.itemName);
    final why = MascotSpeechLibrary.conciseFieldRule(p.importance ?? '');
    final clips = <NeuralClip>[
      NeuralClip(head, pauseMs: 380),
      if (why.isNotEmpty) ...lessonBodyClips(why),
    ];
    ref.read(guideDirectorProvider.notifier).say(
          mood: GuideMood.talk,
          line: why.isNotEmpty ? why : head,
        );
    await _say(clips);
  }

  Future<void> _speakQuiz() async {
    if (_muted || _q >= _quiz.length) return;
    final q = _quiz[_q];
    final cleanQ = MascotSpeechLibrary.toNaturalFieldBangla(q.questionText);
    ref.read(guideDirectorProvider.notifier).say(
          mood: GuideMood.inspire,
          line: MascotSpeechLibrary.conciseFieldRule(cleanQ, maxChars: 110),
        );
    await _say(
      quizQuestionClips(
        question: cleanQ,
        options: q.options.map(MascotSpeechLibrary.toNaturalFieldBangla).toList(),
        index: _q,
        total: _quiz.length,
        hasImage: q.image != null,
        isImage: isQuizImageOption,
      ),
    );
  }

  Future<void> _say(List<NeuralClip> clips) async {
    if (_muted || clips.isEmpty) return;
    final run = ++_listenRun;
    setState(() => _voiceBusy = true);
    _neuralRun = true;
    try {
      await _neural.play(
        clips,
        fallback: (text) => _voice.speak(text),
      );
    } catch (_) {
      if (run != _listenRun) return;
      await _voice.speak(clips.map((c) => c.text).join(' '));
    } finally {
      if (run == _listenRun) {
        _neuralRun = false;
        MascotTalk.reset();
        if (mounted) setState(() => _voiceBusy = false);
      }
    }
  }

  Future<void> _toggleListen() async {
    if (_speaking || _voiceBusy) {
      await _stopVoice();
      return;
    }
    if (_phase == _Phase.cards) {
      await _speakCard(_card);
    } else if (_phase == _Phase.quiz) {
      await _speakQuiz();
    }
  }

  Future<bool> _confirmExit() async {
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: _bn);
    if (leave) await _stopVoice();
    return leave;
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
    _popOnce(false);
  }

  /// Adds [delta] to this play's level score (never below 0) and flies it in.
  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = (_runScore + delta).clamp(0, 1 << 30);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _onCheckCard(int index, Offset globalOrigin, {bool speak = true}) async {
    if (_checkedCards.contains(index)) return;
    setState(() => _checkedCards.add(index));
    await _stopVoice();
    final p = _points[index];
    await _levelDelta(5, globalOrigin, mood: GuideMood.glad);
    if (!speak || !mounted) return;
    final checkLine = _extractCheckRule(p);
    ref.read(guideDirectorProvider.notifier).say(
          mood: GuideMood.glad,
          line: checkLine,
          voiceKey: 'ds_exp_right_1',
          speakVoice: true,
          muted: _muted,
        );
  }

  String _extractCheckRule(LessonSectionPoint p) {
    final daily = (p.dailyCheck ?? '').trim();
    if (daily.isNotEmpty) {
      return MascotSpeechLibrary.conciseFieldRule(daily, maxChars: 120);
    }
    final spec = (p.specifications ?? '').trim();
    if (spec.isNotEmpty) {
      return MascotSpeechLibrary.conciseFieldRule(spec, maxChars: 120);
    }
    return MascotSpeechLibrary.cueFor(MascotCueId.learnCardCheckOk).displayBn;
  }

  void _nextCard(Offset globalOrigin) {
    // If the user hasn't tapped the card check yet, reward them right now so no learning beat is missed!
    if (!_checkedCards.contains(_card)) {
      // Moving on: no check line, the next card speaks.
      unawaited(_onCheckCard(_card, globalOrigin, speak: false));
    }
    if (_card >= _points.length - 1) {
      unawaited(_enterQuiz());
      return;
    }
    final next = _card + 1;
    setState(() => _card = next);
    _pages.animateToPage(
      next,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    unawaited(_stopVoice().then((_) => _speakCard(next)));
  }

  Future<void> _enterQuiz() async {
    await _stopVoice();
    if (_quiz.isEmpty) {
      await _finish(cleared: true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _phase = _Phase.quiz;
      _q = 0;
      _picked = null;
      _revealed = false;
      _preview = null;
      _aside.clear();
    });
    ref.read(guideDirectorProvider.notifier).sayCue(
          MascotCueId.learnQuizStart,
          speakVoice: false,
          muted: _muted,
        );
    unawaited(_speakQuiz());
  }

  /// A tap on an option opens it big; nothing is answered yet.
  void _openOption(int i, Offset globalOrigin) {
    if (_revealed || _finishing || _preview != null) return;
    setState(() {
      _preview = i;
      _previewAt = globalOrigin;
    });
  }

  /// ✓ on the option's preview: the answer (as one tap was before).
  void _confirmOption() {
    final i = _preview;
    if (i == null) return;
    setState(() {
      _preview = null;
      _aside.clear();
    });
    unawaited(_pickOption(i, _previewAt));
  }

  /// ✕: the option is set aside (dimmed); nothing is answered.
  void _rejectOption() {
    final i = _preview;
    if (i == null) return;
    setState(() {
      _preview = null;
      _aside.add(i);
    });
  }

  Future<void> _pickOption(int i, Offset globalOrigin) async {
    if (_revealed || _finishing) return;
    final q = _quiz[_q];
    final ok = i == q.correctIndex;
    // Lock before any await: a double tap must not answer twice.
    setState(() {
      _picked = i;
      _revealed = true;
    });
    await _stopVoice();
    if (!mounted) return;
    await _levelDelta(ok ? 10 : -5, globalOrigin, mood: ok ? GuideMood.celebrate : GuideMood.warn);
    ref.read(guideDirectorProvider.notifier).sayCue(
          ok ? MascotCueId.learnQuizRight : MascotCueId.learnQuizWrongFirst,
          speakVoice: true,
          muted: _muted,
        );
    _marks.settle(right: ok);
    unawaited(ref.read(gameSaveProvider.notifier).markWeak(widget.lessonId, q.questionText.trim(), weak: !ok));
    if (ok) LessonMissTally.hit(widget.lessonId);
    if (!ok && LessonMissTally.miss(widget.lessonId)) {
      // Let the red/green reveal read first, then offer the lesson.
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted && _phase == _Phase.quiz) await _showReadCard();
    }
  }

  bool get _quietMotion => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  void _onReadPill() {
    if (_readOpen) {
      unawaited(_tuckReadCard());
    } else if (_phase == _Phase.cards || _phase == _Phase.quiz) {
      unawaited(_showReadCard());
    }
  }

  /// After a passed level with no offer so far: a varied nudge to read, then leave.
  Future<void> _endOffer() async {
    final done = Completer<void>();
    _endOfferDone = done;
    final nudge = ReadLessonNudges.next(widget.lessonId);
    await _showReadCard(nudge: nudge);
    if (!mounted || !_readOpen) return;
    ref.read(guideDirectorProvider.notifier).say(
          mood: GuideMood.inspire,
          line: nudge.title,
          speakVoice: true,
          muted: _muted,
        );
    await done.future;
  }

  void _endOfferFinish() {
    final done = _endOfferDone;
    _endOfferDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _showReadCard({ReadNudge? nudge}) async {
    if (_readOpen || (_finishing && nudge == null) || !mounted) return;
    await _stopVoice();
    if (!mounted) return;
    _readFrom = readLessonFrom(_readPillKey, _layerKey) ?? _readFrom;
    setState(() {
      _readOpen = true;
      _readShown = true;
      _readNudge = nudge;
    });
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.32, muted: false));
    if (_quietMotion) {
      _readFly.value = 1;
    } else {
      await _readFly.forward(from: 0);
    }
  }

  Future<void> _tuckReadCard() async {
    if (!_readOpen || _readFly.isAnimating) return;
    _readFrom = readLessonFrom(_readPillKey, _layerKey) ?? _readFrom;
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.wav', volume: 0.3, muted: false));
    if (_quietMotion) {
      _readFly.value = 0;
    } else {
      await _readFly.reverse();
    }
    if (!mounted) return;
    final atEnd = _readNudge != null;
    setState(() {
      _readOpen = false;
      _readHot = !atEnd;
      _readNudge = null;
    });
    if (atEnd) _endOfferFinish();
  }

  Future<void> _startReadCard() async {
    if (!_readOpen) return;
    _readFly.value = 0;
    final atEnd = _readNudge != null;
    setState(() {
      _readOpen = false;
      _readNudge = null;
    });
    await _readLesson();
    if (atEnd) _endOfferFinish();
  }

  /// Opens this level's lesson in the reader, or explains why it can't.
  Future<void> _readLesson() async {
    final lesson = _lesson;
    if (lesson == null || lesson.points.isEmpty) {
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
      setState(() => _readHot = true);
      return;
    }
    LessonMissTally.read(widget.lessonId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonReaderPage(lesson: lesson, bn: true, muted: _muted)),
    );
    // The reader hands over to its seal page; wait until the level is on top again.
    while (mounted && !(ModalRoute.of(context)?.isCurrent ?? true)) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (mounted) setState(() => _readHot = false);
  }

  Future<void> _nextQuiz() async {
    if (!_revealed) return;
    await _stopVoice();
    if (_q >= _quiz.length - 1) {
      await _finish(cleared: true);
      return;
    }
    setState(() {
      _q++;
      _picked = null;
      _revealed = false;
      _preview = null;
      _aside.clear();
    });
    unawaited(_speakQuiz());
  }

  Future<void> _finish({required bool cleared}) async {
    if (_finishing) return;
    _finishing = true;
    await _stopVoice();
    final save = ref.read(gameSaveProvider.notifier);
    final already = ref.read(gameSaveProvider).rungProgress[widget.rungId] == 'cleared';
    // A lesson with no quiz at all (server says so) clears on its cards, like the reader.
    final noQuiz = _quiz.isEmpty;
    final mark = noQuiz ? 100 : _marks.percent;
    await save.recordLevelResult(widget.rungId, mark);
    GameSaveController.onPlayResult?.call(widget.rungId, mark: mark, ms: _playClock.elapsedMilliseconds);
    if (!mounted) return;
    _runMark = mark;
    if (!noQuiz && !_marks.passed) {
      // Below the pass line: nothing is cleared; the play's score still stands (latest counts).
      await save.commitLevelScore(widget.rungId, _runScore);
      if (!mounted) return;
      setState(() {
        _failed = true;
        _phase = _Phase.done;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final line = LearnFeedbackLines.failed[DateTime.now().millisecond % LearnFeedbackLines.failed.length];
      ref.read(guideDirectorProvider.notifier).say(
            mood: GuideMood.warn,
            line: line.shownBn,
            speakVoice: true,
            muted: _muted,
          );
      return;
    }
    if (cleared) {
      final size = MediaQuery.sizeOf(context);
      await save.markRungCleared(widget.rungId);
      _passed = true;
      await _levelDelta(20, Offset(size.width * 0.5, size.height * 0.48), mood: GuideMood.celebrate);
      // The latest play's score replaces this level's last one in the main ◆.
      await save.commitLevelScore(widget.rungId, _runScore);
      if (!already) {
        final lesson = _lesson;
        if (lesson != null) {
          await markLessonCompletedLocally(ref, lesson.id);
          await markLessonCompletedLocally(ref, '${lesson.moduleNumber}_${lesson.chapterNumber}');
        }
      }
      ref.read(guideDirectorProvider.notifier).sayCue(
            MascotCueId.learnDeckClear,
            speakVoice: true,
            muted: _muted,
          );
    }
    if (!mounted || _popped) return;
    setState(() => _phase = _Phase.done);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted || _popped) return;
    await _stopVoice();
    if (!mounted) return;
    final promised = await askLessonPromise(
      context,
      ref,
      lessonId: widget.lessonId,
      rungId: widget.rungId,
      muted: _muted,
    );
    if (!mounted || _popped) return;
    if (!promised && !_readShown) {
      await _endOffer();
      if (!mounted || _popped) return;
    }
    _popOnce(cleared);
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final quiet = MediaQuery.disableAnimationsOf(context);
    final lesson = _lesson;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF050A16),
          body: ScoreFlyHost(
            scoreKey: _scoreKey,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Theme(
                    data: SlmTheme.night(),
                    child: const SlmBackground(constrain: false, child: SizedBox.expand()),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      UnifiedGameTopHud(
                        scoreKey: _scoreKey,
                        levelScore: _runScore,
                        deathKey: _deathKey,
                        badgeText: 'L${widget.ladderIndex + 1}',
                        stepOnly: true,
                        titleText: MascotSpeechLibrary.toNaturalFieldBangla(
                          lesson?.title ?? widget.lessonId,
                        ),
                        closeIcon: Icons.close_rounded,
                        muted: _muted,
                        onClose: _leave,
                        onToggleMute: () async {
                          await _stopVoice();
                          setState(() => _muted = !_muted);
                        },
                        trailingExtra: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: bn ? 'পড়ে শোনান' : 'Listen',
                              onPressed: _muted ? null : _toggleListen,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                              icon: Icon(
                                _speaking || _voiceBusy
                                    ? Icons.stop_circle_outlined
                                    : Icons.headphones_rounded,
                                color: _speaking ? SlmColors.emerald300 : SlmColors.ivory,
                                size: 20,
                              ),
                            ),
                            ReadLessonPill(key: _readPillKey, hot: _readHot, onTap: _onReadPill),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          key: _layerKey,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(child: _body(bn: bn, quiet: quiet)),
                            if (_readOpen)
                              Positioned.fill(
                                child: ReadLessonFlyLayer(
                                  fly: _readFly,
                                  curve: _readCurve,
                                  from: _readFrom,
                                  onScrimTap: () => unawaited(_tuckReadCard()),
                                  card: ReadLessonCard(
                                    atStart: false,
                                    nudge: _readNudge,
                                    lessonLine: enDigits(
                                      'পাঠ ${widget.lessonId} · ${_lesson?.title ?? ''}',
                                    ),
                                    onStart: () => unawaited(_startReadCard()),
                                    onLater: () => unawaited(_tuckReadCard()),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body({required bool bn, required bool quiet}) {
    switch (_phase) {
      case _Phase.load:
        return const Center(child: CircularProgressIndicator(color: SlmColors.gold300));
      case _Phase.cards:
        return _CardsPhase(
          points: _points,
          card: _card,
          checkedCards: _checkedCards,
          pages: _pages,
          bn: bn,
          quiet: quiet,
          onPage: (i) {
            if (i == _card) return;
            setState(() => _card = i);
            unawaited(_stopVoice().then((_) => _speakCard(i)));
          },
          onCheckCard: _onCheckCard,
          onNext: _nextCard,
          history: _history.plays > 0
              ? LevelHistoryChip(plays: _history.plays, bestMark: _history.best)
              : null,
        );
      case _Phase.quiz:
        return _QuizPhase(
          questions: _quiz,
          index: _q,
          picked: _picked,
          revealed: _revealed,
          bn: bn,
          quiet: quiet,
          muted: _muted,
          preview: _preview,
          aside: _aside,
          onOpen: _openOption,
          onConfirm: _confirmOption,
          onReject: _rejectOption,
          onNext: _nextQuiz,
        );
      case _Phase.done when _failed:
        return LayoutBuilder(
          builder: (_, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (box.maxHeight - 36).clamp(0, double.infinity)),
              child: Center(
                child: LevelFailPanel(
                  percent: _runMark ?? 0,
                  muted: _muted,
                  history: _history.plays > 0
                      ? LevelHistoryChip(plays: _history.plays, bestMark: _history.best)
                      : null,
                  onRetry: () async {
                    await _stopVoice();
                    widget.onRetry(_muted);
                  },
                  onRead: _lesson == null ? null : () => unawaited(_readLesson()),
                  onLeave: () async {
                    await _stopVoice();
                    if (mounted) Navigator.of(context).pop(false);
                  },
                ),
              ),
            ),
          ),
        );
      case _Phase.done:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AiLinemanGuide(
                sprite: 124,
                bubbleWidth: 260,
                large: true,
                showBubble: true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: SlmColors.emerald700.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SlmColors.gold300, width: 1.4),
                ),
                child: Text(
                  bn ? 'পাঠ সম্পূর্ণ! পরের ধাপে ওঠা হচ্ছে…' : 'Lesson Cleared! Climbing up…',
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    color: SlmColors.gold200,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_runMark != null) ...[
                const SizedBox(height: 12),
                Text(
                  enDigits('নম্বর $_runMark%'),
                  style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: SlmColors.emerald300),
                ),
              ],
              if (_history.plays > 0) ...[
                const SizedBox(height: 10),
                LevelHistoryChip(plays: _history.plays, bestMark: _history.best),
              ],
            ],
          ),
        );
    }
  }
}

class _CardsPhase extends StatelessWidget {
  final List<LessonSectionPoint> points;
  final int card;
  final Set<int> checkedCards;
  final PageController pages;
  final bool bn;
  final bool quiet;
  final ValueChanged<int> onPage;
  final void Function(int index, Offset globalOrigin) onCheckCard;
  final void Function(Offset globalOrigin) onNext;

  /// Earlier plays of this level, shown quietly on the first card.
  final Widget? history;

  const _CardsPhase({
    required this.points,
    required this.card,
    required this.checkedCards,
    required this.pages,
    required this.bn,
    required this.quiet,
    required this.onPage,
    required this.onCheckCard,
    required this.onNext,
    this.history,
  });

  @override
  Widget build(BuildContext context) {
    final last = card >= points.length - 1;
    final checkedCurrent = checkedCards.contains(card);

    return Column(
      children: [
        // Top Step Progress + Mascot Companion Strip
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SlmColors.navy850,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4)),
                ),
                child: Text(
                  enDigits('কার্ড ${card + 1}/${points.length}'),
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    color: SlmColors.gold300,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: List.generate(points.length, (i) {
                    final done = checkedCards.contains(i);
                    final active = i == card;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: quiet ? Duration.zero : const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        height: active ? 6 : 4,
                        decoration: BoxDecoration(
                          color: done
                              ? SlmColors.emerald300
                              : active
                                  ? SlmColors.gold300
                                  : const Color(0x33F3F0E8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                enDigits('✓ ${checkedCards.length}/${points.length}'),
                style: TextStyle(
                  fontFamily: banglaFont,
                  color: checkedCards.length == points.length
                      ? SlmColors.emerald300
                      : SlmColors.mist,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (history != null && card == 0)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: history),
        // Interactive Flash-Card Deck
        Expanded(
          child: PageView.builder(
            controller: pages,
            itemCount: points.length,
            onPageChanged: onPage,
            itemBuilder: (context, i) => _LearnCard(
              index: i,
              point: points[i],
              checked: checkedCards.contains(i),
              bn: bn,
              onCheck: (pos) => onCheckCard(i, pos),
            ),
          ),
        ),
        // Bottom Mascot Dock + Action Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const AiLinemanGuide(
                sprite: 68,
                bubbleWidth: 185,
                showBubble: true,
                centered: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTapUp: (d) => onNext(d.globalPosition),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: checkedCurrent
                            ? const [Color(0xFFF3C969), Color(0xFFD4A037)]
                            : const [Color(0xFF1F3B34), Color(0xFF142823)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: checkedCurrent ? SlmColors.gold200 : SlmColors.emerald400,
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (checkedCurrent ? SlmColors.gold400 : SlmColors.emerald400)
                              .withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          checkedCurrent
                              ? (last ? Icons.bolt_rounded : Icons.arrow_forward_rounded)
                              : Icons.verified_rounded,
                          size: 20,
                          color: checkedCurrent ? SlmColors.navy950 : SlmColors.emerald300,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            checkedCurrent
                                ? (last ? 'কুইক চেকে যান' : 'পরের কার্ড')
                                : (last ? 'চেক করে কুইজে যান (+5 ◆)' : 'চেক করে এগোন (+5 ◆)'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: banglaFont,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: checkedCurrent ? SlmColors.navy950 : SlmColors.ivory,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearnCard extends StatelessWidget {
  final int index;
  final LessonSectionPoint point;
  final bool checked;
  final bool bn;
  final ValueChanged<Offset> onCheck;

  const _LearnCard({
    required this.index,
    required this.point,
    required this.checked,
    required this.bn,
    required this.onCheck,
  });

  String _checkText() {
    final daily = (point.dailyCheck ?? '').trim();
    if (daily.isNotEmpty) {
      return MascotSpeechLibrary.conciseFieldRule(daily, maxChars: 135);
    }
    final spec = (point.specifications ?? '').trim();
    if (spec.isNotEmpty) {
      return MascotSpeechLibrary.conciseFieldRule(spec, maxChars: 135);
    }
    return 'কাজের আগে সরঞ্জামটি হাতে নিয়ে ফাটল, ইনসুলেশন ও মেয়াদ যাচাই করুন।';
  }

  IconData _fallbackIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('gloves') || t.contains('গ্লাভস')) return Icons.pan_tool_alt_rounded;
    if (t.contains('harness') || t.contains('হারনেস') || t.contains('বেল্ট')) return Icons.safety_check_rounded;
    if (t.contains('boot') || t.contains('বুট') || t.contains('জুতো')) return Icons.hiking_rounded;
    if (t.contains('earth') || t.contains('আর্থ') || t.contains('ডিসচার্জ')) return Icons.bolt_rounded;
    if (t.contains('ptw') || t.contains('পারমিট') || t.contains('লটো')) return Icons.lock_clock_rounded;
    return Icons.health_and_safety_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final headline = MascotSpeechLibrary.toNaturalFieldBangla(point.itemName);
    final whyShort = MascotSpeechLibrary.conciseFieldRule(point.importance ?? '', maxChars: 140);
    final checkRule = _checkText();
    final specShort = MascotSpeechLibrary.conciseFieldRule(point.specifications ?? '', maxChars: 95);
    final url = point.fullImageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF132038), Color(0xFF0B1324)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: checked
                ? SlmColors.emerald400.withValues(alpha: 0.75)
                : SlmColors.gold400.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Visual Stage (46% height) with Interactive Tap-to-Inspect Hotspot
              Expanded(
                flex: 46,
                child: GestureDetector(
                  onTapUp: (d) => onCheck(d.globalPosition),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFFF3ECE0),
                        child: url == null
                            ? Center(
                                child: Icon(
                                  _fallbackIcon(headline),
                                  size: 76,
                                  color: const Color(0xFF8A6A28),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                memCacheWidth: screenDecodeWidth(context),
                                placeholder: (_, _) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8A6A28)),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    _fallbackIcon(headline),
                                    size: 68,
                                    color: const Color(0xFF8A6A28),
                                  ),
                                ),
                              ),
                      ),
                      // Top-left field card tag
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SlmColors.navy950.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                          ),
                          child: Text(
                            enDigits('ফিল্ড ব্রিফিং #${index + 1}'),
                            style: const TextStyle(
                              fontFamily: banglaFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: SlmColors.gold300,
                            ),
                          ),
                        ),
                      ),
                      // Top-right interactive check status badge
                      Positioned(
                        right: 12,
                        top: 12,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: checked
                                ? const Color(0xFF0E3B2B)
                                : const Color(0xFF2B1E08).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: checked ? SlmColors.emerald300 : SlmColors.gold300,
                              width: 1.3,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                checked ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                                size: 15,
                                color: checked ? SlmColors.emerald300 : SlmColors.gold300,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                checked ? 'চেক সম্পন্ন (+5 ◆)' : 'ট্যাপ করে চেক করুন (+5 ◆)',
                                style: TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: checked ? SlmColors.emerald300 : SlmColors.gold200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Interactive Field Takeaway + 1-Tap Pre-Work Check Box (54% height)
              Expanded(
                flex: 54,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                          height: 1.22,
                          color: SlmColors.ivory,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (whyShort.isNotEmpty)
                        Text(
                          whyShort,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: banglaFont,
                            fontSize: 14,
                            height: 1.36,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD5DFEE),
                          ),
                        ),
                      const Spacer(),
                      // Interactive "কাজের আগে চেক" Action Card
                      GestureDetector(
                        onTapUp: (d) => onCheck(d.globalPosition),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: checked
                                  ? const [Color(0xFF0F3528), Color(0xFF0A241B)]
                                  : const [Color(0xFF231C11), Color(0xFF18130B)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: checked ? SlmColors.emerald400 : SlmColors.gold400,
                              width: 1.3,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    checked ? Icons.verified_rounded : Icons.radar_rounded,
                                    size: 17,
                                    color: checked ? SlmColors.emerald300 : SlmColors.gold300,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      checked
                                          ? 'কাজের আগে চেক — নিশ্চিত করা হয়েছে!'
                                          : 'কাজের আগে কী চেক করবেন? (এখানে ট্যাপ করুন)',
                                      style: TextStyle(
                                        fontFamily: banglaFont,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: checked ? SlmColors.emerald300 : SlmColors.gold300,
                                      ),
                                    ),
                                  ),
                                  if (!checked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SlmColors.gold400.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        '+5 ◆',
                                        style: TextStyle(
                                          color: SlmColors.gold200,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                checkRule,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 13.5,
                                  height: 1.32,
                                  fontWeight: FontWeight.w700,
                                  color: checked ? SlmColors.ivory : const Color(0xFFEAE2D0),
                                ),
                              ),
                              if (checked && specShort.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'মানদণ্ড: $specShort',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: banglaFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: SlmColors.gold300,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _QuizPhase extends StatelessWidget {
  final List<LessonQuizQuestion> questions;
  final int index;
  final int? picked;
  final bool revealed;
  final bool bn;
  final bool quiet;
  final bool muted;

  /// The option open big (its [CardPreviewOverlay]), or null.
  final int? preview;

  /// Options set aside with ✕ (dimmed, still open).
  final Set<int> aside;

  /// A tap on an option: opens it big (never an answer by itself).
  final void Function(int optionIndex, Offset globalOrigin) onOpen;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onNext;

  const _QuizPhase({
    required this.questions,
    required this.index,
    required this.picked,
    required this.revealed,
    required this.bn,
    required this.quiet,
    required this.muted,
    required this.preview,
    required this.aside,
    required this.onOpen,
    required this.onConfirm,
    required this.onReject,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final q = questions[index];
    final p = preview;
    final body = _quiz(context, q);
    if (p == null || revealed || p >= q.options.length) return body;
    final label = MascotSpeechLibrary.toNaturalFieldBangla(q.options[p]);
    final image = isQuizImageOption(label);
    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned.fill(
          key: ValueKey('option-preview-$index-$p'),
          child: CardPreviewOverlay(
            textBn: image ? '' : label,
            index: p,
            art: image
                ? CachedNetworkImage(
                    imageUrl: label.startsWith('http') ? label : 'https://www.smartlineman.in/quizzes/${label.replaceFirst(RegExp(r'^/'), '')}',
                    height: 160,
                    fit: BoxFit.contain,
                    memCacheHeight: decodePx(context, 160),
                    errorWidget: (_, _, _) => Text(enDigits(label), style: const TextStyle(fontFamily: banglaFont, color: SlmColors.ivory)),
                  )
                : null,
            top: 0,
            quiet: quiet,
            muted: muted,
            onConfirm: onConfirm,
            onReject: onReject,
          ),
        ),
      ],
    );
  }

  Widget _quiz(BuildContext context, LessonQuizQuestion q) {
    final last = index >= questions.length - 1;
    final cleanQuestion = MascotSpeechLibrary.toNaturalFieldBangla(q.questionText);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SlmColors.gold400.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                ),
                child: Text(
                  enDigits('কুইক ফিল্ড ডিসিশন ${index + 1}/${questions.length}'),
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    color: SlmColors.gold300,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'সঠিক উত্তর: +10 ◆',
                style: TextStyle(
                  fontFamily: banglaFont,
                  color: SlmColors.emerald300,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF15233D), Color(0xFF0C1527)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45), width: 1.4),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      cleanQuestion,
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 17.5,
                        height: 1.38,
                        fontWeight: FontWeight.w800,
                        color: SlmColors.ivory,
                      ),
                    ),
                    if (q.image != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: q.image!.startsWith('http')
                              ? q.image!
                              : 'https://www.smartlineman.in/quizzes/${q.image}',
                          height: 132,
                          fit: BoxFit.contain,
                          memCacheHeight: decodePx(context, 140),
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    for (var i = 0; i < q.options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      CardAside(
                        aside: !revealed && aside.contains(i),
                        child: _OptionTile(
                          key: ValueKey('quiz-option-$i'),
                          label: MascotSpeechLibrary.toNaturalFieldBangla(q.options[i]),
                          selected: picked == i,
                          revealed: revealed,
                          correct: i == q.correctIndex,
                          onTapUp: revealed ? null : (d) => onOpen(i, d.globalPosition),
                        ),
                      ),
                    ],
                    if (revealed) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: (picked == q.correctIndex)
                              ? const Color(0xFF0E3829)
                              : const Color(0xFF361519),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (picked == q.correctIndex)
                                ? SlmColors.emerald400
                                : SoftDanger.ink,
                          ),
                        ),
                        child: Text(
                          picked == q.correctIndex
                              ? 'একদম সঠিক সিদ্ধান্ত! +10 ◆ পয়েন্ট যোগ হয়েছে।'
                              : 'সঠিক উত্তরটি সবুজ রঙে দেখানো হয়েছে — মনে গেঁথে নিন, মই থেকে পড়েননি।',
                          style: TextStyle(
                            fontFamily: banglaFont,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: (picked == q.correctIndex)
                                ? SlmColors.emerald300
                                : const Color(0xFFFFD8D6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const AiLinemanGuide(
                sprite: 68,
                bubbleWidth: 185,
                showBubble: true,
                centered: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: revealed ? SlmColors.gold400 : const Color(0x33E8C56A),
                    foregroundColor: SlmColors.navy950,
                    disabledForegroundColor: const Color(0x88F3F0E8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: revealed ? onNext : null,
                  icon: Icon(last ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded, size: 20),
                  label: Text(
                    last
                        ? (bn ? 'সম্পন্ন করুন (+20 ◆)' : 'Finish (+20 ◆)')
                        : (bn ? 'পরের প্রশ্ন' : 'Next Question'),
                    style: const TextStyle(
                      fontFamily: banglaFont,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool revealed;
  final bool correct;
  final GestureTapUpCallback? onTapUp;

  const _OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.revealed,
    required this.correct,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF1D2D4B);
    Color border = const Color(0xFF364D75);
    Color textColor = SlmColors.ivory;
    IconData leading = Icons.radio_button_unchecked_rounded;
    Color iconColor = SlmColors.gold300;

    if (revealed && correct) {
      bg = const Color(0xFF103F2E);
      border = SlmColors.emerald300;
      leading = Icons.check_circle_rounded;
      iconColor = SlmColors.emerald300;
    } else if (revealed && selected && !correct) {
      bg = const Color(0xFF42181E);
      border = SoftDanger.ink;
      leading = Icons.cancel_rounded;
      iconColor = SoftDanger.ink;
    } else if (selected) {
      border = SlmColors.gold300;
    }

    final image = isQuizImageOption(label);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTapUp: onTapUp,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(leading, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: image
                    ? CachedNetworkImage(
                        imageUrl: label.startsWith('http')
                            ? label
                            : 'https://www.smartlineman.in/quizzes/${label.replaceFirst(RegExp(r'^/'), '')}',
                        height: 72,
                        fit: BoxFit.contain,
                        memCacheHeight: decodePx(context, 72),
                        errorWidget: (_, _, _) => Text(
                          enDigits(label),
                          style: TextStyle(fontFamily: banglaFont, color: textColor),
                        ),
                      )
                    : Text(
                        enDigits(label),
                        style: TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 15,
                          height: 1.32,
                          fontWeight: FontWeight.w700,
                          color: textColor,
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
