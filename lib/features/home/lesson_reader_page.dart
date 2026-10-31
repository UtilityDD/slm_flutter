import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'bangla_read_aloud.dart';
import 'hero_card_carousel.dart';
import 'lesson_progress_store.dart';
import 'lesson_quiz_page.dart';
import 'lesson_rich_text.dart';
import 'level_celebration_page.dart';

/// Immersive guided reader — Kindle / Google Books paper feel + Bangla read-aloud.
class LessonReaderPage extends ConsumerStatefulWidget {
  final LessonCardItem lesson;
  final bool bn;

  const LessonReaderPage({super.key, required this.lesson, required this.bn});

  @override
  ConsumerState<LessonReaderPage> createState() => _LessonReaderPageState();
}

enum _Phase { hero, point, tip, myth, done }

class _LessonReaderPageState extends ConsumerState<LessonReaderPage> {
  late final List<_Phase> _phases;
  late final List<LessonSectionPoint> _points;
  late final BanglaReadAloud _voice;
  int _phaseIndex = 0;
  int _pointDone = 0;
  bool _isClaiming = false;
  bool _speaking = false;
  bool _voiceBusy = false;

  // Reading stays dark ink on warm paper; only the chrome around it is night.
  static const _paper = SlmColors.ivory;
  static const _paperDeep = SlmColors.ivoryDeep;
  static const _ink = SlmColors.ink;
  static const _softInk = Color(0xFF3A4660);
  static const _accent = SlmColors.gold700;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _points = lesson.points;
    _phases = [
      _Phase.hero,
      if (_points.isNotEmpty) _Phase.point,
      if (lesson.proTips.isNotEmpty) _Phase.tip,
      if (lesson.myths.isNotEmpty) _Phase.myth,
      _Phase.done,
    ];
    _voice = BanglaReadAloud();
    _voice.onSpeakingChanged = (value) {
      if (!mounted) return;
      setState(() => _speaking = value);
    };
    _voice.init();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  bool get _pointsFinished => _points.isEmpty || _pointDone >= _points.length;

  Future<void> _stopVoice() async {
    await _voice.stop();
    if (mounted) setState(() => _speaking = false);
  }

  String _pageSpeech() {
    final lesson = widget.lesson;
    final bn = widget.bn;
    final phase = _phases[_phaseIndex];
    final buf = StringBuffer();

    switch (phase) {
      case _Phase.hero:
        buf.writeln(lesson.title);
        if (lesson.missionBriefing != null && lesson.missionBriefing!.isNotEmpty) {
          buf.writeln(lesson.missionBriefing!);
        } else {
          buf.writeln(bn ? 'এই পাঠের মূল কথা পরের ধাপে আসবে।' : 'The main points come next.');
        }
      case _Phase.point:
        if (_pointsFinished) {
          buf.writeln(bn ? 'সব ধাপ সম্পন্ন।' : 'All steps done.');
          for (final p in _points) {
            buf.writeln(p.itemName);
          }
        } else {
          final p = _points[_pointDone.clamp(0, _points.length - 1)];
          buf.writeln(p.itemName);
          if (p.specifications != null) buf.writeln(p.specifications!);
          if (p.importance != null) {
            buf.writeln(bn ? 'কেন জরুরি।' : 'Why it matters.');
            buf.writeln(p.importance!);
          }
          if (p.dailyCheck != null) {
            buf.writeln(bn ? 'কাজের আগে চেক।' : 'Check before work.');
            buf.writeln(p.dailyCheck!);
          }
        }
      case _Phase.tip:
        buf.writeln(bn ? 'কাজের সহজ টিপ।' : 'Easy field tip.');
        for (final tip in lesson.proTips) {
          buf.writeln(tip);
        }
      case _Phase.myth:
        buf.writeln(bn ? 'ভুল কথা এবং সত্য কথা।' : 'Wrong and right.');
        for (final myth in lesson.myths) {
          buf.writeln(bn ? 'ভুল।' : 'Wrong.');
          buf.writeln(myth.myth);
          buf.writeln(bn ? 'সত্য।' : 'Right.');
          buf.writeln(myth.reality);
        }
      case _Phase.done:
        buf.writeln(bn ? 'পাঠ শেষ। নিচের বাটনে চাপুন।' : 'Lesson complete. Tap below.');
    }
    return buf.toString();
  }

  Future<void> _toggleListen() async {
    if (_voiceBusy) return;
    setState(() => _voiceBusy = true);
    try {
      if (_speaking) {
        await _stopVoice();
        return;
      }
      HapticFeedback.selectionClick();
      final ok = await _voice.speak(_pageSpeech());
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.bn
                  ? 'এই ফোনে বাংলা কণ্ঠ পাওয়া যায়নি। ভাষা প্যাক ইনস্টল করুন।'
                  : 'No Bangla voice on this phone. Install a language pack.',
              style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF3F3A36),
          ),
        );
        setState(() => _speaking = false);
      }
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  void _advance() {
    HapticFeedback.selectionClick();
    _stopVoice();
    final phase = _phases[_phaseIndex];
    if (phase == _Phase.point && _pointDone < _points.length) {
      setState(() => _pointDone++);
      return;
    }
    if (_phaseIndex < _phases.length - 1) {
      setState(() => _phaseIndex++);
    }
  }

  Future<void> _claim() async {
    if (_isClaiming) return;
    await _stopVoice();
    setState(() => _isClaiming = true);

    final lesson = widget.lesson;
    final pool = await fetchLessonQuiz(lesson.moduleNumber, lesson.chapterNumber);
    if (!mounted) return;
    if (pool != null) {
      final outcome = await Navigator.of(context).push<LessonQuizOutcome>(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => LessonQuizPage(
            questions: selectLessonQuizQuestions(pool),
            lessonBadge: '${lesson.moduleNumber}.${lesson.chapterNumber}',
            lessonTitle: lesson.title,
            bn: widget.bn,
            isPractice: lesson.isCompleted,
          ),
          transitionsBuilder: (_, anim, __, child) {
            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
      if (!mounted) return;
      if (outcome != LessonQuizOutcome.passed) {
        setState(() {
          _isClaiming = false;
          if (outcome == LessonQuizOutcome.readAgain) {
            _phaseIndex = 0;
            _pointDone = 0;
          }
        });
        return;
      }
    }
    await _completeLesson();
  }

  Future<void> _completeLesson() async {
    final wasRevision = widget.lesson.isCompleted;
    final module = widget.lesson.moduleNumber;
    var siblings = const <LessonCardItem>[];
    try {
      siblings = await ref.read(moduleLessonsProvider(module).future);
    } catch (_) {}
    final othersDone = siblings.isNotEmpty &&
        siblings.where((l) => l.id != widget.lesson.id).every((l) => l.isCompleted);
    final moduleFullyDone = othersDone; // current lesson completes (or already completed) the set

    // Always unlock the next lesson on this device (guest + signed-in).
    await markLessonCompletedLocally(ref, widget.lesson.id);
    await markLessonCompletedLocally(ref, '${module}_${widget.lesson.chapterNumber}');

    final authState = ref.read(authProvider);
    final userId = authState.isAuthenticated ? authState.profile?.id : null;
    final nextLevel = module < 10 ? module + 1 : module;

    if (userId != null) {
      try {
        final currentCompleted = List<String>.from(authState.profile?.completedLessons ?? []);
        if (!currentCompleted.contains(widget.lesson.id)) {
          currentCompleted.add(widget.lesson.id);
        }
        final updates = <String, dynamic>{
          'completed_lessons': currentCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (!wasRevision) {
          updates['points'] = (authState.profile?.points ?? 0) + 20;
        }
        if (moduleFullyDone) {
          final currentLevel = authState.profile?.trainingLevel ?? 1;
          if (nextLevel > currentLevel) {
            updates['training_level'] = nextLevel;
          }
        }
        await SupabaseService.client.from('profiles').update(updates).eq('id', userId);
        await ref.read(authProvider.notifier).refreshProfile();
      } catch (_) {}
    }

    ref.invalidate(trainingLadderProvider);
    ref.invalidate(moduleLessonsProvider(module));

    if (!mounted) return;

    // Celebrate first clear, or recover if module is done but celebration never ran.
    final alreadyCelebrated = moduleFullyDone ? await hasCelebratedModule(module) : true;
    final levelJustCleared = moduleFullyDone && !alreadyCelebrated;

    if (levelJustCleared) {
      HapticFeedback.heavyImpact();
      await markModuleCelebrated(ref, module);
      final nextStep = module < 10 ? module + 1 : null;
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 480),
          pageBuilder: (_, __, ___) => LevelCelebrationPage(
            completedStep: module,
            completedTitle: heroTitle(module, widget.bn),
            nextStep: nextStep,
            nextTitle: nextStep == null ? null : heroTitle(nextStep, widget.bn),
            bn: widget.bn,
          ),
          transitionsBuilder: (_, anim, __, child) {
            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      );
      return;
    }

    if (!wasRevision && mounted) {
      showSlmXpToast(context, amount: 20, unit: widget.bn ? 'পয়েন্ট' : 'points');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasRevision
              ? (widget.bn ? 'রিভিশন সম্পন্ন।' : 'Revision done.')
              : (widget.bn ? 'ভালো হয়েছে! +20 পয়েন্ট যোগ হয়েছে।' : 'Well done! +20 points added.'),
          style: const TextStyle(fontFamily: banglaFont, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  void _zoom(String url, String caption) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(caption, textAlign: TextAlign.center, style: const TextStyle(fontFamily: banglaFont, color: Colors.white, fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }

  void _openNote(String body) {
    final pipe = body.indexOf('|');
    final title = pipe >= 0 ? body.substring(pipe + 1).trim() : (widget.bn ? 'আরও জানুন' : 'More');
    final text = pipe >= 0 ? body.substring(0, pipe).trim() : body.trim();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8C7AE), borderRadius: BorderRadius.circular(99))),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontFamily: banglaFont, fontSize: 16, fontWeight: FontWeight.w600, color: _accent)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(fontFamily: banglaFont, fontSize: 17, height: 1.55, fontWeight: FontWeight.w500, color: _ink)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final bn = widget.bn;
    final phase = _phases[_phaseIndex];
    final totalSteps = 1 + _points.length + (lesson.proTips.isNotEmpty ? 1 : 0) + (lesson.myths.isNotEmpty ? 1 : 0);
    var progress = 0;
    if (phase == _Phase.hero) {
      progress = 0;
    } else if (phase == _Phase.point) {
      progress = 1 + _pointDone.clamp(0, _points.length);
    } else if (phase == _Phase.tip) {
      progress = 1 + _points.length;
    } else if (phase == _Phase.myth) {
      progress = 1 + _points.length + (lesson.proTips.isNotEmpty ? 1 : 0);
    } else {
      progress = totalSteps;
    }

    String cta;
    if (phase == _Phase.done) {
      cta = lesson.isCompleted
          ? (bn ? 'অনুশীলন কুইজ দিন' : 'Take practice quiz')
          : (bn ? 'পুরোটা পড়েছি · কুইজ দিন' : 'I finished · take the quiz');
    } else if (phase == _Phase.point && !_pointsFinished) {
      cta = bn ? 'বুঝেছি · পরের ধাপ' : 'Got it · next step';
    } else if (phase == _Phase.point && _pointsFinished) {
      cta = bn ? 'সব ধাপ শেষ · এগোন' : 'All steps done · continue';
    } else {
      cta = bn ? 'পরের পাতা' : 'Next page';
    }

    final ratio = totalSteps == 0 ? 0.0 : progress / totalSteps;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 12, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await _stopVoice();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close_rounded, color: SlmColors.ivory),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bn ? 'পাঠ ${lesson.chapterNumber}' : 'Lesson ${lesson.chapterNumber}',
                                style: const TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: SlmColors.gold300,
                                ),
                              ),
                              Text(
                                lesson.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: SlmColors.ivory,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ListenButton(
                          speaking: _speaking,
                          busy: _voiceBusy,
                          bn: bn,
                          onTap: _toggleListen,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: ratio),
                      duration: SlmMotion.slow,
                      curve: SlmMotion.emphasized,
                      builder: (context, value, _) => _ReaderBar(value: value, complete: phase == _Phase.done),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_paper, _paperDeep],
                          ),
                          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: AnimatedSwitcher(
                            duration: SlmMotion.slow,
                            reverseDuration: SlmMotion.fast,
                            switchInCurve: SlmMotion.emphasized,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0.035, 0), end: Offset.zero).animate(anim),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey('$_phaseIndex-$_pointDone'),
                              child: _buildBody(phase, lesson, bn),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + MediaQuery.paddingOf(context).bottom * 0.15),
                    child: Theme(
                      data: SlmTheme.night(),
                      child: SlmButton(
                        label: cta,
                        variant: phase == _Phase.done ? SlmButtonVariant.primary : SlmButtonVariant.gold,
                        size: SlmButtonSize.large,
                        expand: true,
                        loading: _isClaiming,
                        trailingIcon: phase == _Phase.done ? null : Icons.arrow_forward_rounded,
                        onPressed: _isClaiming
                            ? null
                            : () {
                                if (phase == _Phase.done) {
                                  _claim();
                                } else {
                                  _advance();
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_Phase phase, LessonCardItem lesson, bool bn) {
    switch (phase) {
      case _Phase.hero:
        return ListView(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 28),
          children: [
            Text(
              lesson.title,
              style: const TextStyle(
                fontFamily: banglaFont,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.38,
                color: _ink,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [SlmColors.gold500, Color(0x00BF9443)]),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              bn ? 'প্রথমে এটা বুঝুন' : 'Understand this first',
              style: const TextStyle(
                fontFamily: banglaFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _accent,
              ),
            ),
            const SizedBox(height: 12),
            if (lesson.missionBriefing != null && lesson.missionBriefing!.isNotEmpty)
              LessonRichText(
                text: lesson.missionBriefing!,
                bn: bn,
                style: const TextStyle(
                  fontFamily: banglaFont,
                  fontSize: 19.5,
                  height: 1.72,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
                onOpenImage: _zoom,
                onOpenNote: _openNote,
              )
            else
              Text(
                bn ? 'এই পাঠের মূল কথা পরের ধাপে আসবে।' : 'The main points come next.',
                style: const TextStyle(fontFamily: banglaFont, fontSize: 18, height: 1.6, color: _softInk),
              ),
            const SizedBox(height: 28),
            Text(
              bn ? 'উপরে শুনুন বাটনে চাপুন — অথবা নিচে পরের পাতায় যান।' : 'Tap Listen above — or turn the page below.',
              style: const TextStyle(fontFamily: banglaFont, fontSize: 13.5, height: 1.5, color: Color(0xFF8A7464)),
            ),
          ],
        );
      case _Phase.point:
        return _GuidedPoints(
          points: _points,
          done: _pointDone,
          bn: bn,
          onZoom: _zoom,
          onOpenNote: _openNote,
        );
      case _Phase.tip:
        return ListView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
          children: [
            Text(
              bn ? 'কাজের সহজ টিপ' : 'Easy field tip',
              style: const TextStyle(fontFamily: banglaFont, fontSize: 24, fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(height: 16),
            for (final tip in lesson.proTips)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8D2B0)),
                ),
                child: LessonRichText(
                  text: tip,
                  bn: bn,
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 18, height: 1.65, fontWeight: FontWeight.w500, color: _ink),
                  onOpenImage: _zoom,
                  onOpenNote: _openNote,
                ),
              ),
          ],
        );
      case _Phase.myth:
        return ListView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
          children: [
            Text(
              bn ? 'ভুল কথা · সত্য কথা' : 'Wrong · Right',
              style: const TextStyle(fontFamily: banglaFont, fontSize: 24, fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(height: 16),
            for (final myth in lesson.myths)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8D2B0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bn ? 'ভুল' : 'Wrong', style: const TextStyle(fontFamily: banglaFont, fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                    const SizedBox(height: 6),
                    LessonRichText(
                      text: myth.myth,
                      bn: bn,
                      style: const TextStyle(fontFamily: banglaFont, fontSize: 17.5, height: 1.55, fontWeight: FontWeight.w600, color: Color(0xFF7F1D1D)),
                      onOpenImage: _zoom,
                      onOpenNote: _openNote,
                    ),
                    const SizedBox(height: 14),
                    Text(bn ? 'সত্য' : 'Right', style: const TextStyle(fontFamily: banglaFont, fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                    const SizedBox(height: 6),
                    LessonRichText(
                      text: myth.reality,
                      bn: bn,
                      style: const TextStyle(fontFamily: banglaFont, fontSize: 17.5, height: 1.55, fontWeight: FontWeight.w500, color: Color(0xFF14532D)),
                      onOpenImage: _zoom,
                      onOpenNote: _openNote,
                    ),
                  ],
                ),
              ),
          ],
        );
      case _Phase.done:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      SlmSparkBurst(playOnMount: true, radius: 78),
                      SlmReveal(rise: 0, child: _DoneMedal()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  bn ? 'পাঠ শেষ' : 'Lesson complete',
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 28, fontWeight: FontWeight.w700, color: _ink),
                ),
                const SizedBox(height: 10),
                Text(
                  bn
                      ? 'কুইজে 70% সঠিক হলে পাঠ সম্পন্ন — 20 পয়েন্ট।'
                      : 'Score 70% in the quiz to complete the lesson — 20 points.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 16, height: 1.5, color: _softInk),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _ListenButton extends StatelessWidget {
  final bool speaking;
  final bool busy;
  final bool bn;
  final VoidCallback onTap;

  const _ListenButton({
    required this.speaking,
    required this.busy,
    required this.bn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: speaking ? (bn ? 'থামান' : 'Stop') : (bn ? 'শুনুন' : 'Listen'),
      child: Material(
        color: speaking ? SlmColors.emerald700 : SlmColors.navy800,
        shape: StadiumBorder(
          side: BorderSide(color: SlmColors.gold400.withValues(alpha: speaking ? 0.9 : 0.55)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: SlmColors.gold200),
                  )
                else
                  Icon(
                    speaking ? Icons.stop_rounded : Icons.headphones_rounded,
                    size: 18,
                    color: SlmColors.gold200,
                  ),
                const SizedBox(width: 6),
                Text(
                  speaking ? (bn ? 'থামান' : 'Stop') : (bn ? 'শুনুন' : 'Listen'),
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: SlmColors.gold100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderBar extends StatelessWidget {
  final double value;
  final bool complete;

  const _ReaderBar({required this.value, required this.complete});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: SlmColors.navy950,
        borderRadius: SlmRadius.pillAll,
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: complete ? SlmGradients.emerald : SlmGradients.gold,
              borderRadius: SlmRadius.pillAll,
              boxShadow: [
                BoxShadow(
                  color: (complete ? SlmColors.emerald400 : SlmColors.gold400).withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneMedal extends StatelessWidget {
  const _DoneMedal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SlmGradients.gold,
        boxShadow: SlmShadows.glow(SlmColors.gold400),
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [SlmColors.emerald500, SlmColors.emerald700, SlmColors.emerald900],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Icon(Icons.menu_book_rounded, size: 44, color: SlmColors.gold100),
      ),
    );
  }
}

class _GuidedPoints extends StatelessWidget {
  final List<LessonSectionPoint> points;
  final int done;
  final bool bn;
  final void Function(String, String) onZoom;
  final void Function(String) onOpenNote;

  const _GuidedPoints({
    required this.points,
    required this.done,
    required this.bn,
    required this.onZoom,
    required this.onOpenNote,
  });

  @override
  Widget build(BuildContext context) {
    final finished = done >= points.length;
    final active = finished ? points.length : done.clamp(0, points.length - 1);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Text(
              finished
                  ? (bn ? 'সব ধাপ সম্পন্ন' : 'All steps done')
                  : (bn ? 'ধাপ ${active + 1} / ${points.length}' : 'Step ${active + 1} / ${points.length}'),
              style: const TextStyle(fontFamily: banglaFont, fontSize: 13, fontWeight: FontWeight.w700, color: SlmColors.gold700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < points.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: SlmMotion.slow,
                        curve: SlmMotion.emphasized,
                        height: 4,
                        margin: EdgeInsets.only(right: i == points.length - 1 ? 0 : 3),
                        decoration: BoxDecoration(
                          color: i < done
                              ? SlmColors.emerald600
                              : (!finished && i == done)
                                  ? SlmColors.gold500
                                  : const Color(0xFFDCD2BE),
                          borderRadius: SlmRadius.pillAll,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (finished)
          for (final point in points) _DoneChip(title: point.itemName)
        else
          for (var i = 0; i < points.length; i++)
            if (i < done)
              _DoneChip(title: points[i].itemName)
            else if (i == done)
              _ActivePointCard(index: i + 1, point: points[i], bn: bn, onZoom: onZoom, onOpenNote: onOpenNote)
            else
              _LockedChip(title: points[i].itemName),
      ],
    );
  }
}

class _DoneChip extends StatelessWidget {
  final String title;
  const _DoneChip({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: AppColors.safeGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontFamily: banglaFont, fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedChip extends StatelessWidget {
  final String title;
  const _LockedChip({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFD0BA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Color(0xFFB8A894), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: banglaFont, fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFB8A894)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePointCard extends StatelessWidget {
  final int index;
  final LessonSectionPoint point;
  final bool bn;
  final void Function(String, String) onZoom;
  final void Function(String) onOpenNote;

  const _ActivePointCard({
    required this.index,
    required this.point,
    required this.bn,
    required this.onZoom,
    required this.onOpenNote,
  });

  @override
  Widget build(BuildContext context) {
    final img = point.fullImageUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: SlmColors.navy900.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: SlmGradients.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: SlmColors.gold700.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 16, fontWeight: FontWeight.w700, color: SlmColors.navy900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  point.itemName,
                  style: const TextStyle(fontFamily: banglaFont, fontSize: 21, fontWeight: FontWeight.w700, height: 1.35, color: SlmColors.ink),
                ),
              ),
            ],
          ),
          if (img != null && img.isNotEmpty) ...[
            const SizedBox(height: 14),
            LessonFigurePlate(
              imageUrl: img,
              paperColor: const Color(0xFFEADFCB),
              onTap: () => onZoom(img, point.imageCaption ?? point.itemName),
            ),
          ],
          if (point.specifications != null && point.specifications!.isNotEmpty) ...[
            const SizedBox(height: 14),
            LessonRichText(
              text: point.specifications!,
              bn: bn,
              style: const TextStyle(fontFamily: banglaFont, fontSize: 17.5, height: 1.65, fontWeight: FontWeight.w500, color: Color(0xFF1F1A14)),
              onOpenImage: onZoom,
              onOpenNote: onOpenNote,
            ),
          ],
          if (point.importance != null && point.importance!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FactBox(
              tint: const Color(0xFFF3F0E8),
              title: bn ? 'কেন জরুরি' : 'Why it matters',
              child: LessonRichText(
                text: point.importance!,
                bn: bn,
                style: const TextStyle(fontFamily: banglaFont, fontSize: 16.5, height: 1.6, fontWeight: FontWeight.w500, color: Color(0xFF1F1A14)),
                onOpenImage: onZoom,
                onOpenNote: onOpenNote,
              ),
            ),
          ],
          if (point.dailyCheck != null && point.dailyCheck!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _FactBox(
              tint: const Color(0xFFEFF7F1),
              title: bn ? 'কাজের আগে চেক' : 'Check before work',
              child: LessonRichText(
                text: point.dailyCheck!,
                bn: bn,
                style: const TextStyle(fontFamily: banglaFont, fontSize: 16.5, height: 1.6, fontWeight: FontWeight.w500, color: Color(0xFF1F1A14)),
                onOpenImage: onZoom,
                onOpenNote: onOpenNote,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactBox extends StatelessWidget {
  final Color tint;
  final String title;
  final Widget child;

  const _FactBox({required this.tint, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: banglaFont, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: SlmColors.gold700),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
