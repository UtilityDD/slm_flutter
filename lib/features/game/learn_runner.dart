import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/services/neural_tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../home/bangla_read_aloud.dart';
import '../home/lesson_progress_store.dart';
import '../home/lesson_quiz_page.dart';
import '../identify/fit_image.dart';
import '../shell/shell_providers.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';

/// Ladder Learn beat — swipe cards + 2-question exit. Never a fall.
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

enum _Phase { load, cards, quiz, done, error }

class _LearnRunnerPageState extends ConsumerState<LearnRunnerPage> {
  static const _ink = SlmColors.ink;
  static const _accent = Color(0xFF8A6A28);

  late final PageController _pages;
  late final BanglaReadAloud _voice;
  late final NeuralTtsService _neural;

  _Phase _phase = _Phase.load;
  LessonCardItem? _lesson;
  List<LessonSectionPoint> _points = const [];
  List<LessonQuizQuestion> _quiz = const [];
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
  String? _error;

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
      setState(() => _speaking = v);
    };
    _neural.onSpeakingChanged = (v) {
      if (!mounted) return;
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
    _pages.dispose();
    _neural.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final parts = widget.lessonId.split('.');
    final module = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 1;
    final chapter = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;

    try {
      final lessons = await ref.read(moduleLessonsProvider(module).future);
      LessonCardItem? hit;
      for (final l in lessons) {
        if (l.chapterNumber == chapter) {
          hit = l;
          break;
        }
      }
      if (hit == null || hit.points.isEmpty) {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.error;
          _error = _bn ? 'এই পাঠ এখন লোড হচ্ছে না।' : 'This lesson could not load.';
        });
        return;
      }

      final pool = await fetchLessonQuiz(module, chapter);
      final quiz = pool == null || pool.isEmpty ? const <LessonQuizQuestion>[] : selectLearnExitQuestions(pool);

      if (!mounted) return;
      setState(() {
        _lesson = hit;
        _points = hit!.points;
        _quiz = quiz;
        _phase = _Phase.cards;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_speakCard(0));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = _bn ? 'এই পাঠ এখন লোড হচ্ছে না।' : 'This lesson could not load.';
      });
    }
  }

  Future<void> _stopVoice() async {
    _listenRun++;
    _neuralRun = false;
    await _neural.stop();
    await _voice.stop();
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
    final why = (p.importance ?? '').trim();
    final clips = <NeuralClip>[
      NeuralClip(p.itemName.trim(), pauseMs: 450),
      if (why.isNotEmpty) ...lessonBodyClips(why),
    ];
    await _say(clips);
  }

  Future<void> _speakQuiz() async {
    if (_muted || _q >= _quiz.length) return;
    final q = _quiz[_q];
    await _say(
      quizQuestionClips(
        question: q.questionText,
        options: q.options,
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

  void _nextCard() {
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
    unawaited(_speakQuiz());
  }

  Future<void> _pickOption(int i) async {
    if (_revealed || _finishing) return;
    final q = _quiz[_q];
    final ok = i == q.correctIndex;
    HapticFeedback.selectionClick();
    setState(() {
      _picked = i;
      _revealed = true;
    });
    final save = ref.read(gameSaveProvider.notifier);
    if (ok) {
      await save.addPoints(5, rungId: widget.rungId);
    } else {
      await save.addPoints(-5, rungId: widget.rungId);
    }
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
      await save.markRungCleared(widget.rungId);
      if (!already) {
        await save.addPoints(20, rungId: widget.rungId);
        final lesson = _lesson;
        if (lesson != null) {
          await markLessonCompletedLocally(ref, lesson.id);
          await markLessonCompletedLocally(ref, '${lesson.moduleNumber}_${lesson.chapterNumber}');
        }
      }
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop(cleared);
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
        if (!await _confirmExit()) return;
        if (!mounted) return;
        Navigator.of(this.context).pop(false);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Color(0xFF050A16),
          body: Stack(
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
                    _Chrome(
                      bn: bn,
                      title: lesson?.title ?? widget.lessonId,
                      chapter: lesson?.chapterNumber,
                      speaking: _speaking,
                      busy: _voiceBusy,
                      muted: _muted,
                      onClose: () async {
                        if (!await _confirmExit()) return;
                        if (!mounted) return;
                        Navigator.of(this.context).pop(false);
                      },
                      onListen: _toggleListen,
                      onMute: () async {
                        await _stopVoice();
                        setState(() => _muted = !_muted);
                      },
                    ),
                    Expanded(child: _body(bn: bn, quiet: quiet)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body({required bool bn, required bool quiet}) {
    switch (_phase) {
      case _Phase.load:
        return const Center(child: CircularProgressIndicator(color: SlmColors.gold300));
      case _Phase.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: banglaFont, color: SlmColors.ivory, fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(bn ? 'মইয়ে ফিরুন' : 'Back to ladder', style: const TextStyle(color: SlmColors.gold300)),
                ),
              ],
            ),
          ),
        );
      case _Phase.cards:
        return _CardsPhase(
          points: _points,
          card: _card,
          pages: _pages,
          bn: bn,
          quiet: quiet,
          onPage: (i) {
            if (i == _card) return;
            setState(() => _card = i);
            unawaited(_stopVoice().then((_) => _speakCard(i)));
          },
          onNext: _nextCard,
          onMore: _openSpecs,
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
          child: Text(
            bn ? 'ভালো হয়েছে!' : 'Well done!',
            style: const TextStyle(fontFamily: banglaFont, color: SlmColors.gold200, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        );
    }
  }

  void _openSpecs(LessonSectionPoint point) {
    final specs = (point.specifications ?? '').trim();
    if (specs.isEmpty) return;
    final bn = _bn;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SlmColors.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD8C7AE), borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              bn ? 'আরও' : 'More',
              style: const TextStyle(fontFamily: banglaFont, fontSize: 16, fontWeight: FontWeight.w700, color: _accent),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
              child: SingleChildScrollView(
                child: Text(
                  enDigits(specs),
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 16, height: 1.55, fontWeight: FontWeight.w500, color: _ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chrome extends StatelessWidget {
  final bool bn;
  final String title;
  final int? chapter;
  final bool speaking;
  final bool busy;
  final bool muted;
  final VoidCallback onClose;
  final VoidCallback onListen;
  final VoidCallback onMute;

  const _Chrome({
    required this.bn,
    required this.title,
    required this.chapter,
    required this.speaking,
    required this.busy,
    required this.muted,
    required this.onClose,
    required this.onListen,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 4),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: Color(0xFFF3F0E8))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter == null ? (bn ? 'শিখুন' : 'Learn') : enDigits(bn ? 'পাঠ $chapter' : 'Lesson $chapter'),
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8C56A),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF3F0E8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: muted ? (bn ? 'শব্দ চালু' : 'Unmute') : (bn ? 'শব্দ বন্ধ' : 'Mute'),
            onPressed: onMute,
            icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Color(0xFFB8C0D0)),
          ),
          IconButton(
            tooltip: bn ? 'পড়ে শোনান' : 'Listen',
            onPressed: muted ? null : onListen,
            icon: Icon(
              speaking || busy ? Icons.stop_circle_outlined : Icons.headphones_rounded,
              color: speaking ? SlmColors.emerald300 : Color(0xFFF3F0E8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardsPhase extends StatelessWidget {
  final List<LessonSectionPoint> points;
  final int card;
  final PageController pages;
  final bool bn;
  final bool quiet;
  final ValueChanged<int> onPage;
  final VoidCallback onNext;
  final void Function(LessonSectionPoint) onMore;

  const _CardsPhase({
    required this.points,
    required this.card,
    required this.pages,
    required this.bn,
    required this.quiet,
    required this.onPage,
    required this.onNext,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final last = card >= points.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                enDigits('${card + 1}/${points.length}'),
                style: const TextStyle(fontFamily: banglaFont, color: Color(0xFFB8C0D0), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: List.generate(points.length, (i) {
                    final on = i <= card;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: quiet ? Duration.zero : const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 3,
                        decoration: BoxDecoration(
                          color: on ? SlmColors.gold300 : Color(0x33F3F0E8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: pages,
            itemCount: points.length,
            onPageChanged: onPage,
            itemBuilder: (context, i) => _LearnCard(
              point: points[i],
              bn: bn,
              onMore: () => onMore(points[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SlmColors.gold400,
                foregroundColor: SlmColors.navy950,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onNext,
              child: Text(
                last ? (bn ? 'কুইজে যান' : 'Take the quiz') : (bn ? 'পরের' : 'Next'),
                style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearnCard extends StatelessWidget {
  final LessonSectionPoint point;
  final bool bn;
  final VoidCallback onMore;

  const _LearnCard({required this.point, required this.bn, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final why = (point.importance ?? '').trim();
    final whyShort = why.length > 120 ? '${why.substring(0, 117).trim()}…' : why;
    final hasMore = (point.specifications ?? '').trim().isNotEmpty;
    final url = point.fullImageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SlmColors.ivory,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: ColoredBox(
                  color: const Color(0xFFEDE4D4),
                  child: url == null
                      ? const Center(child: Icon(Icons.shield_moon_outlined, size: 64, color: Color(0xFF8A6A28)))
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          memCacheWidth: screenDecodeWidth(context),
                          placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF8A6A28))),
                        ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enDigits(point.itemName.trim()),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: SlmColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (whyShort.isNotEmpty)
                        Expanded(
                          child: Text(
                            enDigits(whyShort),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: banglaFont,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3A4660),
                            ),
                          ),
                        ),
                      if (hasMore)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onMore,
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF8A6A28),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(bn ? 'আরও' : 'More', style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w700)),
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
  final ValueChanged<int> onPick;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            enDigits(bn ? 'প্রশ্ন ${index + 1}/${questions.length}' : 'Question ${index + 1}/${questions.length}'),
            style: const TextStyle(fontFamily: banglaFont, color: Color(0xFFE8C56A), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      enDigits(q.questionText),
                      style: const TextStyle(fontFamily: banglaFont, fontSize: 17, height: 1.4, fontWeight: FontWeight.w700, color: SlmColors.ink),
                    ),
                    if (q.image != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: q.image!.startsWith('http') ? q.image! : 'https://www.smartlineman.in/quizzes/${q.image}',
                          height: 140,
                          fit: BoxFit.contain,
                          memCacheHeight: decodePx(context, 140),
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    for (var i = 0; i < q.options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _OptionTile(
                        label: q.options[i],
                        selected: picked == i,
                        revealed: revealed,
                        correct: i == q.correctIndex,
                        onTap: revealed ? null : () => onPick(i),
                      ),
                    ],
                    if (revealed && picked != q.correctIndex) ...[
                      const SizedBox(height: 12),
                      Text(
                        bn ? 'সঠিক উত্তর দেখুন — পয়েন্ট কাটা গেছে, মই থেকে পড়েননি।' : 'See the right answer — points lost, no fall.',
                        style: const TextStyle(fontFamily: banglaFont, fontSize: 13, height: 1.35, color: Color(0xFF3A4660)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: revealed ? SlmColors.gold400 : Color(0x33E8C56A),
              foregroundColor: SlmColors.navy950,
              disabledForegroundColor: Color(0x88F3F0E8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: revealed ? onNext : null,
            child: Text(
              last ? (bn ? 'মইয়ে ফিরুন' : 'Back to ladder') : (bn ? 'পরের প্রশ্ন' : 'Next question'),
              style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w800, fontSize: 16),
            ),
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
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.revealed,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF4EFE4);
    Color border = const Color(0xFFD8C7AE);
    if (revealed && correct) {
      bg = const Color(0xFFD9F2E4);
      border = SlmColors.emerald700;
    } else if (revealed && selected && !correct) {
      bg = const Color(0xFFF8D7D2);
      border = const Color(0xFFB83A2E);
    } else if (selected) {
      border = SlmColors.gold700;
    }

    final image = isQuizImageOption(label);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: image
              ? CachedNetworkImage(
                  imageUrl: label.startsWith('http') ? label : 'https://www.smartlineman.in/quizzes/${label.replaceFirst(RegExp(r'^/'), '')}',
                  height: 72,
                  fit: BoxFit.contain,
                  memCacheHeight: decodePx(context, 72),
                  errorWidget: (_, _, _) => Text(enDigits(label), style: const TextStyle(fontFamily: banglaFont, color: SlmColors.ink)),
                )
              : Text(
                  enDigits(label),
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 15, height: 1.3, fontWeight: FontWeight.w600, color: SlmColors.ink),
                ),
        ),
      ),
    );
  }
}
