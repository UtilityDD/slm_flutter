import 'dart:async';

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
import '../shell/shell_providers.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'beat_fx.dart';
import 'content_catalog.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';

/// Interactive Ladder Learn Deck — visual-first field flash-cards with
/// 1-tap pre-work checks (+5 ◆), unified Mascot lip-sync coaching, and
/// 2 quick-fire field decisions (+10 ◆ / -5 ◆) + 20 ◆ completion burst.
class LearnRunnerPage extends ConsumerStatefulWidget {
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
  ConsumerState<LearnRunnerPage> createState() => _LearnRunnerPageState();
}

enum _Phase { load, cards, quiz, done }

class _LearnRunnerPageState extends ConsumerState<LearnRunnerPage> {
  final _scoreKey = GlobalKey();
  final _deathKey = GlobalKey();

  late final PageController _pages;
  late final BanglaReadAloud _voice;
  late final NeuralTtsService _neural;

  _Phase _phase = _Phase.load;
  LessonCardItem? _lesson;
  List<LessonSectionPoint> _points = const [];
  List<LessonQuizQuestion> _quiz = const [];
  final Set<int> _checkedCards = <int>{};
  int _card = 0;
  int _q = 0;
  int? _picked;
  bool _revealed = false;
  bool _speaking = false;
  bool _voiceBusy = false;
  bool _muted = false;
  bool _finishing = false;
  int _listenRun = 0;
  bool _neuralRun = false;

  bool get _bn => ref.read(languageProvider);

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
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
    MascotTalk.reset();
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
    List<LessonQuizQuestion> quiz = const [];

    try {
      final lessons = await ref.read(moduleLessonsProvider(module).future);
      for (final l in lessons) {
        if (l.chapterNumber == chapter) {
          hit = l;
          break;
        }
      }
      final pool = await fetchLessonQuiz(module, chapter);
      if (pool != null && pool.isNotEmpty) {
        quiz = selectLearnExitQuestions(pool);
      }
    } catch (_) {
      // Fall back to built-in field deck below if offline or un-synced
    }

    if (hit == null || hit.points.isEmpty) {
      final catalog = await ref.read(contentCatalogProvider.future);
      CatalogLesson? catLesson;
      for (final l in catalog.lessons) {
        if (l.id == widget.lessonId) {
          catLesson = l;
          break;
        }
      }
      hit = _buildOfflineFallbackLesson(module, chapter, catLesson?.titleBn);
    }

    if (quiz.isEmpty) {
      quiz = _buildOfflineFallbackQuiz(module, chapter, hit.points);
    }

    if (!mounted) return;
    setState(() {
      _lesson = hit;
      _points = hit!.points;
      _quiz = quiz;
      _phase = _Phase.cards;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(guideDirectorProvider.notifier).sayCue(
            MascotCueId.learnDeckStart,
            speakVoice: false,
            muted: _muted,
          );
      unawaited(_speakCard(0));
    });
  }

  LessonCardItem _buildOfflineFallbackLesson(int module, int chapter, String? titleBn) {
    final title = titleBn ?? 'মাঠের সুরক্ষা ও জীবনরক্ষাকারী অভ্যাস';
    return LessonCardItem(
      id: '${module}_$chapter',
      moduleNumber: module,
      chapterNumber: chapter,
      title: title,
      missionBriefing: 'কাজের আগে জরুরি ফিল্ড চেক',
      points: const [
        LessonSectionPoint(
          itemName: 'Class-E Electrical Helmet ও Chin-Strap',
          importance:
              'উঁচু পোলে আর্ক ফ্ল্যাশ ও উপর থেকে পড়া যন্ত্রাংশ থেকে মাথা বাঁচাতে নিশ্ছিদ্র Class-E হেলমেট পরুন। গামছা বেঁধে হেলমেট পরবেন না।',
          dailyCheck: 'মাথায় হেলমেট বসিয়ে চিন-স্ট্র্যাপ লক করুন এবং ফাটল নেই নিশ্চিত করুন।',
          specifications: '20 kV পর্যন্ত ডাই-ইলেকট্রিক সুরক্ষা · ভেন্টিলেশন ছিদ্রহীন শেল।',
        ),
        LessonSectionPoint(
          itemName: 'HT Insulated Hand Gloves (11 kV / 33 kV)',
          importance:
              'Shutdown নেওয়া থাকলেও ইনডাকশন কারেন্ট বা ব্যাক-ফিড থেকে হাত বাঁচাতে রেটেড রাবার গ্লাভসই আপনার প্রথম বর্ম।',
          dailyCheck: 'কাজের আগে গ্লাভস মুড়িয়ে হাওয়া ভরে পিন-হোল বা লিক চেক করুন।',
          specifications: 'Class-2 (17 kV টেস্টেড) বা Class-3 · সম্পূর্ণ শুকনো ও তেলমুক্ত।',
        ),
        LessonSectionPoint(
          itemName: 'Full-Body Safety Harness ও D-Ring',
          importance:
              'কোমরের বেল্ট পতনের ঝাঁকুনিতে মেরুদণ্ড ভেঙে দেয়। পোলে ওঠার আগে সবসময় Full-Body Harness ও Energy Absorber Lanyard পরুন।',
          dailyCheck: 'পিঠের D-Ring কাঁধের মাঝখানে রাখুন এবং ফিতেয় দুই আঙুলের ছাড় যাচাই করুন।',
          specifications: 'ফিতেয় কাটা বা সেলাই ছেঁড়া থাকলে ব্যবহার নিষিদ্ধ।',
        ),
        LessonSectionPoint(
          itemName: 'Voltage Detector, Discharge Rod ও দুদিক Earthing',
          importance:
              'লিখিত PTW ও LOTO তালা লাগানোর পর টেস্টার দিয়ে লাইন চেক করুন, আগে মাটিতে আর্থ লাগিয়ে ডিসচার্জ রড ছোঁয়ান এবং দুদিকে আর্থিং করুন।',
          dailyCheck: 'টেস্টারের Self-Test বোতাম টিপে বিপ শব্দ ও ডিসচার্জ রডের কপার তার যাচাই করুন।',
          specifications: 'আগে মাটি পরে লাইন — খোলার সময় আগে লাইন শেষে মাটি।',
        ),
      ],
    );
  }

  List<LessonQuizQuestion> _buildOfflineFallbackQuiz(
    int module,
    int chapter,
    List<LessonSectionPoint> points,
  ) {
    return const [
      LessonQuizQuestion(
        questionText: '11 kV লাইনে কাজের আগে রাবার গ্লাভস পরার সবচেয়ে জরুরি পরীক্ষা কোনটি?',
        options: [
          'গ্লাভস মুড়িয়ে হাওয়া ভরে পিন-হোল বা লিক চেক করা',
          'জলে ভিজিয়ে গ্লাভস নরম করে নেওয়া',
          'সুতির গ্লাভস পরে সরাসরি তারে হাত দেওয়া',
        ],
        correctIndex: 0,
      ),
      LessonQuizQuestion(
        questionText: 'ডিসচার্জ রড দিয়ে লাইন চার্জমুক্ত করার সঠিক নিয়ম কোনটি?',
        options: [
          'আগে তারে হুক লাগিয়ে পরে মাটিতে আর্থ ক্ল্যাম্প লাগানো',
          'আগে মাটির আর্থ স্পাইকে ক্ল্যাম্প শক্ত করে লাগিয়ে তবেই তারে হুক ছোঁয়ানো',
          'ডিসচার্জ রড ছাড়াই খালি হাতে ব্রাস চেইন ছোঁড়া',
        ],
        correctIndex: 1,
      ),
    ];
  }

  Future<void> _stopVoice() async {
    _listenRun++;
    _neuralRun = false;
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

  Future<void> _onCheckCard(int index, Offset globalOrigin) async {
    if (_checkedCards.contains(index)) return;
    setState(() => _checkedCards.add(index));
    await _stopVoice();
    await BeatFx.scoreDelta(
      ref,
      5,
      rungId: widget.rungId,
      mood: GuideMood.glad,
      originGlobal: globalOrigin,
      muted: _muted,
    );
    final p = _points[index];
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
      unawaited(_onCheckCard(_card, globalOrigin));
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
    });
    ref.read(guideDirectorProvider.notifier).sayCue(
          MascotCueId.learnQuizStart,
          speakVoice: false,
          muted: _muted,
        );
    unawaited(_speakQuiz());
  }

  Future<void> _pickOption(int i, Offset globalOrigin) async {
    if (_revealed || _finishing) return;
    await _stopVoice();
    final q = _quiz[_q];
    final ok = i == q.correctIndex;
    setState(() {
      _picked = i;
      _revealed = true;
    });
    await BeatFx.scoreDelta(
      ref,
      ok ? 10 : -5,
      rungId: widget.rungId,
      mood: ok ? GuideMood.celebrate : GuideMood.warn,
      originGlobal: globalOrigin,
      muted: _muted,
    );
    ref.read(guideDirectorProvider.notifier).sayCue(
          ok ? MascotCueId.learnQuizRight : MascotCueId.learnQuizWrongFirst,
          speakVoice: true,
          muted: _muted,
        );
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
    });
    unawaited(_speakQuiz());
  }

  Future<void> _finish({required bool cleared}) async {
    if (_finishing) return;
    _finishing = true;
    await _stopVoice();
    final save = ref.read(gameSaveProvider.notifier);
    final already = ref.read(gameSaveProvider).rungProgress[widget.rungId] == 'cleared';
    if (cleared) {
      final size = MediaQuery.sizeOf(context);
      await save.markRungCleared(widget.rungId);
      final bonus = already ? 5 : 20;
      await BeatFx.scoreDelta(
        ref,
        bonus,
        rungId: widget.rungId,
        mood: GuideMood.celebrate,
        originGlobal: Offset(size.width * 0.5, size.height * 0.48),
        muted: _muted,
      );
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
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    Navigator.of(context).pop(cleared);
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final quiet = MediaQuery.disableAnimationsOf(context);
    final lesson = _lesson;
    final badgeLabel = lesson?.chapterNumber != null
        ? 'পাঠ ${lesson!.chapterNumber}'
        : 'পাঠ ${widget.lessonId}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!await _confirmExit()) return;
        if (!mounted) return;
        Navigator.of(this.context).pop(false);
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
                        deathKey: _deathKey,
                        badgeText: badgeLabel,
                        titleText: MascotSpeechLibrary.toNaturalFieldBangla(
                          lesson?.title ?? widget.lessonId,
                        ),
                        closeIcon: Icons.close_rounded,
                        muted: _muted,
                        onClose: () async {
                          if (!await _confirmExit()) return;
                          if (!mounted) return;
                          Navigator.of(this.context).pop(false);
                        },
                        onToggleMute: () async {
                          await _stopVoice();
                          setState(() => _muted = !_muted);
                        },
                        trailingExtra: IconButton(
                          tooltip: bn ? 'পড়ে শোনান' : 'Listen',
                          onPressed: _muted ? null : _toggleListen,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                          icon: Icon(
                            _speaking || _voiceBusy
                                ? Icons.stop_circle_outlined
                                : Icons.headphones_rounded,
                            color: _speaking ? SlmColors.emerald300 : SlmColors.ivory,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(child: _body(bn: bn, quiet: quiet)),
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
        );
      case _Phase.quiz:
        return _QuizPhase(
          questions: _quiz,
          index: _q,
          picked: _picked,
          revealed: _revealed,
          bn: bn,
          onPick: _pickOption,
          onNext: _nextQuiz,
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
                  onTapDown: (d) => onNext(d.globalPosition),
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
                  onTapDown: (d) => onCheck(d.globalPosition),
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
                        onTapDown: (d) => onCheck(d.globalPosition),
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
  final void Function(int optionIndex, Offset globalOrigin) onPick;
  final VoidCallback onNext;

  const _QuizPhase({
    required this.questions,
    required this.index,
    required this.picked,
    required this.revealed,
    required this.bn,
    required this.onPick,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final q = questions[index];
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
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    for (var i = 0; i < q.options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      _OptionTile(
                        label: MascotSpeechLibrary.toNaturalFieldBangla(q.options[i]),
                        selected: picked == i,
                        revealed: revealed,
                        correct: i == q.correctIndex,
                        onTapDown: revealed ? null : (d) => onPick(i, d.globalPosition),
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
  final GestureTapDownCallback? onTapDown;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.revealed,
    required this.correct,
    required this.onTapDown,
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
        onTapDown: onTapDown,
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
