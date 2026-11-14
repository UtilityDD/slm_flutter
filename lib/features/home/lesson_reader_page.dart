import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../identify/fit_image.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'bangla_read_aloud.dart';
import 'lesson_progress_store.dart';
import 'lesson_quiz_page.dart';
import 'lesson_quiz_store.dart';
import 'lesson_rich_text.dart';
import 'lesson_seal_page.dart';
import 'level_celebration_page.dart';
import 'lineman_progress.dart';
import 'reader/reader_prefs.dart';
import 'reader/reader_resume.dart';
import 'reader/sentence_highlight.dart';

/// Edge-to-edge lesson reader: the whole screen is the page (warm paper by
/// day, charcoal by night), one section at a time, read-aloud highlights the
/// sentence being spoken in the text itself.
class LessonReaderPage extends ConsumerStatefulWidget {
  final LessonCardItem lesson;
  final bool bn;

  /// Opened from a muted level: the seal at the end stays silent too.
  final bool muted;

  /// Open straight at this lesson point (0-based), e.g. from a mistake's
  /// "পাঠে দেখুন". Null: start at the beginning (or the saved place).
  final int? startPoint;

  const LessonReaderPage({super.key, required this.lesson, required this.bn, this.muted = false, this.startPoint});

  /// Tests replace the device voice with this.
  @visibleForTesting
  static SentenceSpeak? debugSpeak;

  @override
  ConsumerState<LessonReaderPage> createState() => _LessonReaderPageState();
}

enum _Phase { hero, point, tip, myth, done }

/// One screen of the reader: a phase, and for points which point.
class _Section {
  final _Phase phase;
  final int point;
  const _Section(this.phase, [this.point = 0]);
}

enum _Role { title, overline, heading, subheading, body, hint, image, tip, wrong, right, doneTitle, doneBody }

/// One block of a section. The same list draws the page and feeds the voice,
/// so sentence numbers always match what is highlighted.
class _Line {
  final _Role role;
  final String text;

  /// Spoken first and shown as a small label (myth "ভুল" / "সত্য").
  final String? label;
  final String? imageUrl;
  final bool spoken;

  /// Has `((chip))` / `[[figure]]` markup: drawn by [LessonRichText] and
  /// highlighted as a whole block.
  final bool rich;
  final List<String> sentences;

  _Line._(this.role, this.text, this.label, this.imageUrl, this.spoken, this.rich, this.sentences);

  factory _Line(_Role role, String text, {String? label, String? imageUrl, bool spoken = true}) {
    final rich = text.contains('((') || text.contains('[[');
    final body = !spoken || text.trim().isEmpty
        ? const <String>[]
        : splitBanglaSentences(rich ? lessonSpeechText(text) : text);
    return _Line._(role, text, label, imageUrl, spoken, rich, [
      if (label != null && spoken) '$label।',
      ...body,
    ]);
  }

  int get labelSentences => label != null && spoken ? 1 : 0;
}

/// Reader colours. Body ink on the page is ≥ 7:1 in both themes.
@immutable
class _Palette {
  final bool night;
  final Color bg, ink, soft, rule, accent, track, progress, highlight, plate;
  final Color tipTint, tipEdge, tipLabel;
  final Color wrongTint, wrongEdge, wrongLabel, wrongChip;
  final Color rightTint, rightEdge, rightLabel, rightChip;

  const _Palette({
    required this.night,
    required this.bg,
    required this.ink,
    required this.soft,
    required this.rule,
    required this.accent,
    required this.track,
    required this.progress,
    required this.highlight,
    required this.plate,
    required this.tipTint,
    required this.tipEdge,
    required this.tipLabel,
    required this.wrongTint,
    required this.wrongEdge,
    required this.wrongLabel,
    required this.wrongChip,
    required this.rightTint,
    required this.rightEdge,
    required this.rightLabel,
    required this.rightChip,
  });
}

const _dayPalette = _Palette(
  night: false,
  bg: Color(0xFFFBF7EF),
  ink: Color(0xFF2B2118),
  soft: Color(0xFF6B5A4B),
  rule: Color(0xFFE6DCCB),
  accent: Color(0xFF8A5A12),
  track: Color(0xFFEAE1D1),
  progress: Color(0xFFC8901A),
  highlight: Color(0xFFE0A72E),
  plate: Color(0xFFF1E9DA),
  tipTint: Color(0xFFFCF1DC),
  tipEdge: Color(0xFFD19A2A),
  tipLabel: Color(0xFF7A4E0B),
  wrongTint: Color(0xFFFCEDEA),
  wrongEdge: Color(0xFFC8443A),
  wrongLabel: Color(0xFF9E2A20),
  wrongChip: Color(0xFFF6D5D0),
  rightTint: Color(0xFFEBF6EE),
  rightEdge: Color(0xFF3F9A5C),
  rightLabel: Color(0xFF1E6B38),
  rightChip: Color(0xFFCFE9D6),
);

const _nightPalette = _Palette(
  night: true,
  bg: Color(0xFF121417),
  ink: Color(0xFFE8E2D6),
  soft: Color(0xFFA89F92),
  rule: Color(0xFF2A2D31),
  accent: Color(0xFFE2B65C),
  track: Color(0xFF2A2D31),
  progress: Color(0xFFE2B65C),
  highlight: Color(0xFFE2B65C),
  plate: Color(0xFF1C1F23),
  tipTint: Color(0xFF211E17),
  tipEdge: Color(0xFFD9A441),
  tipLabel: Color(0xFFE8C474),
  wrongTint: Color(0xFF261A19),
  wrongEdge: Color(0xFFE0675C),
  wrongLabel: Color(0xFFF2A69D),
  wrongChip: Color(0xFF3D2321),
  rightTint: Color(0xFF16221A),
  rightEdge: Color(0xFF5DBB7B),
  rightLabel: Color(0xFF9BD8AE),
  rightChip: Color(0xFF1F3A27),
);

/// Reader type ramp, already multiplied by the reading size and the clamped
/// system text scale.
class _Type {
  final TextStyle title, heading, subheading, body, caption, label, overline;

  _Type(double s, _Palette p)
      : title = TextStyle(fontFamily: banglaFont, fontSize: 26 * s, fontWeight: FontWeight.w700, height: 1.35, color: p.ink),
        heading = TextStyle(fontFamily: banglaFont, fontSize: 22 * s, fontWeight: FontWeight.w700, height: 1.4, color: p.ink),
        subheading = TextStyle(fontFamily: banglaFont, fontSize: 18 * s, fontWeight: FontWeight.w600, height: 1.5, color: p.ink),
        body = TextStyle(fontFamily: banglaFont, fontSize: 18 * s, fontWeight: FontWeight.w400, height: 1.7, color: p.ink),
        caption = TextStyle(fontFamily: banglaFont, fontSize: 14 * s, fontWeight: FontWeight.w400, height: 1.5, color: p.soft),
        label = TextStyle(fontFamily: banglaFont, fontSize: 13 * s, fontWeight: FontWeight.w700, height: 1.3),
        overline = TextStyle(fontFamily: banglaFont, fontSize: 14 * s, fontWeight: FontWeight.w600, height: 1.4, color: p.accent);
}

/// Combined reading scale: system text scale × reader size, kept in a range
/// the layout survives.
const _maxScale = 1.3;
const _minScale = 0.8;
const _maxTextWidth = 640.0;
const _fade = Duration(milliseconds: 180);

class _LessonReaderPageState extends ConsumerState<LessonReaderPage> {
  late final List<_Phase> _phases;
  late final List<LessonSectionPoint> _points;
  late final List<_Section> _sections;
  late final BanglaReadAloud _voice;
  late final SentenceReader _reader;
  late final AppLifecycleListener _life;

  int _at = 0;
  int _epoch = 0;
  List<_Line> _script = const [];
  List<int> _offsets = const [];
  List<GlobalKey> _keys = const [];
  int _followedLine = -1;

  double _scrollFraction = 0;
  double _initialFraction = 0;

  bool _isClaiming = false;
  bool _speaking = false;
  int _listenRun = 0;
  bool _navLocked = false;
  Timer? _navTimer;
  bool _userMoved = false;
  bool _finished = false;
  bool _reduceMotion = false;
  double _dragDx = 0;

  _Section get _section => _sections[_at];
  bool get _onLast => _at == _sections.length - 1;

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
    _sections = [
      const _Section(_Phase.hero),
      for (var i = 0; i < _points.length; i++) _Section(_Phase.point, i),
      if (lesson.proTips.isNotEmpty) const _Section(_Phase.tip),
      if (lesson.myths.isNotEmpty) const _Section(_Phase.myth),
      const _Section(_Phase.done),
    ];
    final start = widget.startPoint;
    if (start != null && _points.isNotEmpty) {
      _at = 1 + start.clamp(0, _points.length - 1);
    }
    _voice = BanglaReadAloud();
    // Warm the device voice; a phone without one just has no read-aloud.
    unawaited(_voice.init().catchError((Object _) {}));
    _reader = SentenceReader(const [], voice: _voice, speak: LessonReaderPage.debugSpeak);
    _reader.active.addListener(_followSentence);
    _loadScript();
    _life = AppLifecycleListener(onPause: _saveSpot);
    // Download (or read the saved copy of) the quiz while the lesson is read,
    // so it is ready offline by the last page.
    unawaited(LessonQuizStore.instance.prefetch(lesson.moduleNumber, lesson.chapterNumber));
    if (!lesson.isCompleted && start == null) unawaited(_restoreSpot());
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _life.dispose();
    _saveSpot();
    _reader.active.removeListener(_followSentence);
    unawaited(_reader.dispose());
    unawaited(_voice.dispose());
    super.dispose();
  }

  // ---------------------------------------------------------------- script

  void _loadScript() {
    _script = _scriptFor(_section);
    var n = 0;
    _offsets = [
      for (final line in _script) (n += line.sentences.length) - line.sentences.length,
    ];
    _keys = [for (final _ in _script) GlobalKey()];
    _followedLine = -1;
    _reader.setSentences([for (final line in _script) ...line.sentences]);
  }

  List<_Line> _paragraphs(_Role role, String text) => [
        for (final p in text.split(RegExp(r'\r?\n')))
          if (p.trim().isNotEmpty) _Line(role, p.trim()),
      ];

  List<_Line> _scriptFor(_Section section) {
    final lesson = widget.lesson;
    final bn = widget.bn;
    switch (section.phase) {
      case _Phase.hero:
        final brief = lesson.missionBriefing;
        return [
          _Line(_Role.title, lesson.title),
          _Line(_Role.overline, bn ? 'প্রথমে এটা বুঝুন' : 'Understand this first'),
          if (brief != null && brief.isNotEmpty)
            ..._paragraphs(_Role.body, brief)
          else
            _Line(_Role.hint, bn ? 'এই পাঠের মূল কথা পরের ধাপে আসবে।' : 'The main points come next.'),
          _Line(
            _Role.hint,
            bn
                ? 'উপরের হেডফোনে চাপলে পাঠটি শুনতে পাবেন। পরের ধাপে যেতে পাতাটি বাঁ দিকে সরান।'
                : 'Tap the headphones above to listen. Swipe left for the next step.',
            spoken: false,
          ),
        ];
      case _Phase.point:
        final p = _points[section.point];
        final img = p.fullImageUrl;
        return [
          _Line(_Role.heading, p.itemName),
          if (img != null && img.isNotEmpty) _Line(_Role.image, p.imageCaption ?? '', imageUrl: img, spoken: false),
          if (p.specifications != null && p.specifications!.isNotEmpty) ..._paragraphs(_Role.body, p.specifications!),
          if (p.importance != null && p.importance!.isNotEmpty) ...[
            _Line(_Role.subheading, bn ? 'কেন জরুরি' : 'Why it matters'),
            ..._paragraphs(_Role.body, p.importance!),
          ],
          if (p.dailyCheck != null && p.dailyCheck!.isNotEmpty) ...[
            _Line(_Role.subheading, bn ? 'কাজের আগে চেক' : 'Check before work'),
            ..._paragraphs(_Role.body, p.dailyCheck!),
          ],
        ];
      case _Phase.tip:
        return [
          _Line(_Role.heading, bn ? 'কাজের সহজ টিপ' : 'Easy field tip'),
          for (final tip in lesson.proTips) _Line(_Role.tip, tip),
        ];
      case _Phase.myth:
        return [
          _Line(_Role.heading, bn ? 'ভুল কথা · সত্য কথা' : 'Wrong · Right'),
          for (final myth in lesson.myths) ...[
            _Line(_Role.wrong, myth.myth, label: bn ? 'ভুল' : 'Wrong'),
            _Line(_Role.right, myth.reality, label: bn ? 'সত্য' : 'Right'),
          ],
        ];
      case _Phase.done:
        return [
          _Line(_Role.doneTitle, bn ? 'পাঠ শেষ' : 'Lesson complete'),
          _Line(
            _Role.doneBody,
            bn
                ? 'কুইজে 70% সঠিক হলে পাঠ সম্পন্ন—পাবেন এই পাঠের সিল।'
                : 'Score 70% in the quiz to complete the lesson and earn its seal.',
          ),
        ];
    }
  }

  // ------------------------------------------------------------ navigation

  void _goTo(int index, {double fraction = 0}) {
    final target = index.clamp(0, _sections.length - 1);
    _listenRun++;
    setState(() {
      _speaking = false;
      _at = target;
      _epoch++;
      _initialFraction = fraction;
      _scrollFraction = fraction;
      _loadScript();
    });
    _saveSpot();
  }

  /// Next / previous section, with a short lock so a double tap moves once.
  void _step(int delta) {
    if (_navLocked || _isClaiming) return;
    final target = _at + delta;
    if (target < 0 || target >= _sections.length) return;
    _navLocked = true;
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 250), () => _navLocked = false);
    _userMoved = true;
    HapticFeedback.selectionClick();
    _goTo(target);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dx = _dragDx;
    _dragDx = 0;
    if (v < -250 || (v.abs() <= 250 && dx < -60)) {
      if (!_onLast) _step(1);
    } else if (v > 250 || (v.abs() <= 250 && dx > 60)) {
      _step(-1);
    }
  }

  // ---------------------------------------------------------------- resume

  ReaderSpot get _spot => ReaderSpot(
        phaseIndex: _phases.indexOf(_section.phase),
        pointIndex: _section.point,
        scrollFraction: _scrollFraction,
      );

  void _saveSpot() {
    if (_finished || widget.lesson.isCompleted) return;
    unawaited(ReaderResume.save(widget.lesson.id, _spot));
  }

  Future<void> _restoreSpot() async {
    final spot = await ReaderResume.load(widget.lesson.id);
    if (spot == null || !mounted || _userMoved || _finished) return;
    if (spot.phaseIndex >= _phases.length) return;
    final phase = _phases[spot.phaseIndex];
    final point = _points.isEmpty ? 0 : spot.pointIndex.clamp(0, _points.length - 1);
    final target = _sections.indexWhere((s) => s.phase == phase && (phase != _Phase.point || s.point == point));
    if (target < 0 || (target == 0 && spot.scrollFraction < 0.02)) return;
    _goTo(target, fraction: phase == _Phase.done ? 0 : spot.scrollFraction);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          widget.bn ? 'আগের জায়গা থেকে' : 'Back where you left off',
          style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF3F3A36),
      ),
    );
  }

  // ------------------------------------------------------------ read-aloud

  Future<void> _stopVoice() async {
    _listenRun++;
    await _reader.stop();
    if (mounted && _speaking) setState(() => _speaking = false);
  }

  Future<void> _toggleListen() async {
    if (_speaking) {
      await _stopVoice();
      return;
    }
    HapticFeedback.selectionClick();
    final run = ++_listenRun;
    setState(() => _speaking = true);
    var ok = false;
    try {
      ok = await _reader.start();
    } catch (_) {}
    if (!mounted || run != _listenRun) return;
    setState(() => _speaking = false);
    if (!ok) _noVoiceNotice();
  }

  /// Keeps the line being read on screen.
  void _followSentence() {
    final a = _reader.active.value;
    if (a == null) return;
    var line = -1;
    for (var i = 0; i < _script.length; i++) {
      if (a >= _offsets[i] && a < _offsets[i] + _script[i].sentences.length) {
        line = i;
        break;
      }
    }
    if (line < 0 || line == _followedLine) return;
    _followedLine = line;
    final ctx = _keys[line].currentContext;
    if (ctx == null) return;
    unawaited(Scrollable.ensureVisible(
      ctx,
      alignment: 0.2,
      duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    ));
  }

  void _noVoiceNotice() {
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
  }

  // ------------------------------------------------------------ quiz/claim

  Future<void> _claim() async {
    if (_isClaiming) return;
    await _stopVoice();
    if (!mounted) return;
    setState(() => _isClaiming = true);

    final lesson = widget.lesson;
    final load = await LessonQuizStore.instance.load(lesson.moduleNumber, lesson.chapterNumber);
    if (!mounted) return;
    if (load.status == LessonQuizStatus.unavailable) {
      // Never clear a lesson without its quiz: keep it open and offer a retry.
      setState(() => _isClaiming = false);
      final retry = await showLessonQuizOfflineDialog(context, bn: widget.bn);
      if (retry == true && mounted) await _claim();
      return;
    }
    if (load.isReady) {
      // Picked once, outside the page builder, so a rebuild of the route never reshuffles.
      final questions = selectLessonQuizQuestions(load.questions);
      final outcome = await Navigator.of(context).push<LessonQuizOutcome>(
        SlmPageRoute<LessonQuizOutcome>(
          builder: (_) => LessonQuizPage(
            questions: questions,
            lessonBadge: '${lesson.moduleNumber}.${lesson.chapterNumber}',
            lessonTitle: lesson.title,
            bn: widget.bn,
            isPractice: lesson.isCompleted,
          ),
        ),
      );
      if (!mounted) return;
      if (outcome != LessonQuizOutcome.passed) {
        setState(() => _isClaiming = false);
        if (outcome == LessonQuizOutcome.readAgain) _goTo(0);
        return;
      }
    }
    await _completeLesson();
  }

  Future<void> _completeLesson() async {
    // The lesson is done: its saved reading place goes.
    _finished = true;
    await ReaderResume.clear(widget.lesson.id);
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
    // An offline (cached) profile is stale: writing from it would overwrite
    // newer server totals, so the server copy waits for a live session.
    final userId = authState.isAuthenticated && !authState.offline ? authState.profile?.id : null;
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

    // No explicit invalidate here: the ladder and lesson list already watch
    // auth and local progress, and their content rows are cached per session.

    // Lessons give no points: the win is the seal and the next lesson opening.
    if (!mounted) return;

    // Celebrate first clear, or recover if module is done but celebration never ran.
    final alreadyCelebrated = moduleFullyDone ? await hasCelebratedModule(module) : true;
    final levelJustCleared = moduleFullyDone && !alreadyCelebrated;

    if (levelJustCleared) {
      HapticFeedback.heavyImpact();
      await markModuleCelebrated(ref, module);
      if (!mounted) return;
      final nextStep = module < 10 ? module + 1 : null;
      await Navigator.of(context).pushReplacement(
        SlmPageRoute<void>(
          style: SlmTransition.scaleFade,
          builder: (_) => LevelCelebrationPage(
            completedStep: module,
            completedTitle: heroTitle(module, widget.bn),
            nextStep: nextStep,
            nextTitle: nextStep == null ? null : heroTitle(nextStep, widget.bn),
            bn: widget.bn,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final lesson = widget.lesson;
    final ordered = [...siblings]..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    if (!ordered.any((l) => l.id == lesson.id)) {
      ordered
        ..add(lesson)
        ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    }
    final mine = ordered.indexWhere((l) => l.id == lesson.id);
    final next = mine + 1 < ordered.length ? ordered[mine + 1] : null;
    final nav = Navigator.of(context);
    final bn = widget.bn;
    HapticFeedback.mediumImpact();
    await nav.pushReplacement(
      SlmPageRoute<void>(
        style: SlmTransition.scaleFade,
        builder: (_) => LessonSealPage(
          lesson: lesson,
          seals: [for (final l in ordered) l.isCompleted || l.id == lesson.id],
          mine: mine,
          revision: wasRevision,
          bn: bn,
          muted: widget.muted,
          next: next,
          onOpenNext: next == null
              ? null
              : () => nav.pushReplacement(
                    SlmPageRoute<void>(builder: (_) => LessonReaderPage(lesson: next, bn: bn, muted: widget.muted)),
                  ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ media/notes

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
                memCacheWidth: screenDecodeWidth(context),
                placeholder: (_, _) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, _, _) => const Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
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

  void _openNote(String body, _Palette p) {
    final pipe = body.indexOf('|');
    final title = pipe >= 0 ? body.substring(pipe + 1).trim() : (widget.bn ? 'আরও জানুন' : 'More');
    final text = pipe >= 0 ? body.substring(0, pipe).trim() : body.trim();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 42, height: 4, decoration: BoxDecoration(color: p.rule, borderRadius: BorderRadius.circular(99))),
              ),
              const SizedBox(height: 14),
              Text(title, style: TextStyle(fontFamily: banglaFont, fontSize: 16, fontWeight: FontWeight.w600, color: p.accent)),
              const SizedBox(height: 10),
              Text(text, style: TextStyle(fontFamily: banglaFont, fontSize: 17, height: 1.7, fontWeight: FontWeight.w400, color: p.ink)),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final size = ref.watch(readerTextSizeProvider);
    final theme = ref.watch(readerThemeProvider);
    final p = readerIsNight(context, theme) ? _nightPalette : _dayPalette;
    _reduceMotion = slmReduceMotion(context);
    final system = MediaQuery.textScalerOf(context).scale(100) / 100;
    final scale = (system * size.scale).clamp(_minScale, _maxScale).toDouble();
    final type = _Type(scale, p);
    final ratio = _sections.length <= 1 ? 1.0 : _at / (_sections.length - 1);
    final page = KeyedSubtree(
      key: ValueKey('section-$_at-$_epoch'),
      child: _sectionView(p, type),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.night ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxScale,
        child: Scaffold(
          backgroundColor: p.bg,
          bottomNavigationBar: _bottomBar(p),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ProgressLine(value: ratio, palette: p, animate: !_reduceMotion),
                _header(p, size, theme),
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _dragDx = 0,
                    onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
                    onHorizontalDragEnd: _onDragEnd,
                    child: MediaQuery(
                      // Body sizes already carry the clamped scale.
                      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                      // Reduce motion: no switcher at all, the page changes at once.
                      child: _reduceMotion
                          ? page
                          : AnimatedSwitcher(
                              duration: _fade,
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                              layoutBuilder: (current, previous) => Stack(
                                fit: StackFit.expand,
                                children: [...previous, ?current],
                              ),
                              child: page,
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
  }

  Widget _header(_Palette p, ReaderTextSize size, ReaderTheme theme) {
    final bn = widget.bn;
    final iconColor = p.ink;
    final off = p.soft.withValues(alpha: 0.4);
    final themeIcon = switch (theme) {
      ReaderTheme.day => Icons.light_mode_outlined,
      ReaderTheme.night => Icons.dark_mode_outlined,
      ReaderTheme.system => Icons.brightness_auto_outlined,
    };
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('reader-close'),
              tooltip: bn ? 'বন্ধ করুন' : 'Close',
              onPressed: () async {
                await _stopVoice();
                if (mounted) Navigator.of(context).pop();
              },
              icon: Icon(Icons.close_rounded, color: iconColor),
            ),
            Expanded(
              child: Text(
                bn ? 'পাঠ ${widget.lesson.chapterNumber}' : 'Lesson ${widget.lesson.chapterNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: banglaFont, fontSize: 13, fontWeight: FontWeight.w600, color: p.soft),
              ),
            ),
            IconButton(
              key: const ValueKey('reader-smaller'),
              tooltip: bn ? 'লেখা ছোট করুন' : 'Smaller text',
              onPressed: size == ReaderTextSize.values.first ? null : () => ref.read(readerTextSizeProvider.notifier).smaller(),
              icon: const Icon(Icons.text_decrease_rounded),
              color: iconColor,
              disabledColor: off,
            ),
            IconButton(
              key: const ValueKey('reader-bigger'),
              tooltip: bn ? 'লেখা বড় করুন' : 'Larger text',
              onPressed: size == ReaderTextSize.values.last ? null : () => ref.read(readerTextSizeProvider.notifier).bigger(),
              icon: const Icon(Icons.text_increase_rounded),
              color: iconColor,
              disabledColor: off,
            ),
            IconButton(
              key: const ValueKey('reader-theme'),
              tooltip: bn ? 'পাতার রং বদলান' : 'Page colour',
              onPressed: () => ref.read(readerThemeProvider.notifier).cycle(),
              icon: Icon(themeIcon, color: iconColor),
            ),
            IconButton(
              key: const ValueKey('reader-listen'),
              tooltip: _speaking ? (bn ? 'থামান' : 'Stop') : (bn ? 'শুনুন' : 'Listen'),
              onPressed: _toggleListen,
              icon: Icon(
                _speaking ? Icons.stop_circle_outlined : Icons.headphones_rounded,
                color: _speaking ? p.accent : iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(_Palette p) {
    final bn = widget.bn;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final back = IconButton(
      key: const ValueKey('reader-back'),
      tooltip: bn ? 'আগের ধাপ' : 'Previous step',
      onPressed: _at == 0 || _isClaiming ? null : () => _step(-1),
      icon: const Icon(Icons.chevron_left_rounded, size: 28),
      color: p.ink,
      disabledColor: p.soft.withValues(alpha: 0.35),
    );
    final Widget bar;
    if (_onLast) {
      final cta = widget.lesson.isCompleted
          ? (bn ? 'অনুশীলন কুইজ দিন' : 'Take practice quiz')
          : (bn ? 'পুরোটা পড়েছি · কুইজ দিন' : 'I finished · take the quiz');
      bar = Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 16, 10),
        child: Row(
          children: [
            back,
            const SizedBox(width: 4),
            Expanded(
              child: Theme(
                data: p.night ? SlmTheme.night() : SlmTheme.day(),
                child: SlmButton(
                  key: const ValueKey('reader-cta'),
                  label: cta,
                  variant: SlmButtonVariant.primary,
                  size: SlmButtonSize.large,
                  expand: true,
                  loading: _isClaiming,
                  onPressed: _isClaiming ? null : _claim,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bar = SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              back,
              Expanded(
                child: Text(
                  bn ? 'ধাপ ${_at + 1}/${_sections.length}' : 'Step ${_at + 1}/${_sections.length}',
                  key: const ValueKey('reader-position'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: banglaFont, fontSize: 13, fontWeight: FontWeight.w600, color: p.soft),
                ),
              ),
              TextButton(
                key: const ValueKey('reader-next'),
                onPressed: _isClaiming ? null : () => _step(1),
                style: TextButton.styleFrom(
                  foregroundColor: p.accent,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.only(left: 12, right: 6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bn ? 'পরের ধাপ' : 'Next step',
                      style: const TextStyle(fontFamily: banglaFont, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(top: BorderSide(color: p.rule)),
      ),
      child: Padding(padding: EdgeInsets.only(bottom: bottom), child: bar),
    );
  }

  // --------------------------------------------------------------- content

  Widget _sectionView(_Palette p, _Type type) {
    final width = MediaQuery.sizeOf(context).width;
    final side = width < 400 ? 20.0 : 24.0;
    final lines = _script;
    final offsets = _offsets;
    final keys = _keys;
    if (_section.phase == _Phase.done) {
      return LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: side, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: (box.maxHeight - 48).clamp(0, double.infinity)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxTextWidth),
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
                    for (var i = 0; i < lines.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      KeyedSubtree(key: keys[i], child: _lineView(lines[i], offsets[i], p, type)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return _SectionScroll(
      initialFraction: _initialFraction,
      onFraction: (f) => _scrollFraction = f,
      builder: (controller) => SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(side, 20, side, 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxTextWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) SizedBox(height: _gap(lines[i - 1], lines[i])),
                  KeyedSubtree(key: keys[i], child: _lineView(lines[i], offsets[i], p, type)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _bulletLead = RegExp(r'^(?:[•·\-*–]|[0-9০-৯]+[.)।])\s*');

  /// Space above [b]: paragraphs 14, list items 8, headings 24, a myth's
  /// truth sits right under its myth.
  double _gap(_Line a, _Line b) {
    if (b.role == _Role.right) return 2;
    if (b.role == _Role.wrong && a.role == _Role.right) return 16;
    switch (b.role) {
      case _Role.overline:
        return 20;
      case _Role.subheading:
        return 24;
      case _Role.image:
        return 16;
      case _Role.hint:
        return a.role == _Role.body ? 24 : 14;
      default:
        break;
    }
    if (a.role == _Role.heading || a.role == _Role.overline || a.role == _Role.subheading) return 10;
    if (a.role == _Role.body && b.role == _Role.body && _bulletLead.hasMatch(b.text) && _bulletLead.hasMatch(a.text)) return 8;
    return 14;
  }

  Widget _lineView(_Line line, int offset, _Palette p, _Type type) {
    final style = switch (line.role) {
      _Role.title => type.title,
      _Role.overline => type.overline,
      _Role.heading => type.heading,
      _Role.subheading => type.subheading,
      _Role.hint => type.caption,
      _Role.doneTitle => type.title,
      _Role.doneBody => type.caption.copyWith(fontSize: type.body.fontSize! * 0.9),
      _ => type.body,
    };
    final align = line.role == _Role.doneTitle || line.role == _Role.doneBody ? TextAlign.center : TextAlign.start;

    if (line.role == _Role.image) {
      final url = line.imageUrl!;
      final caption = line.text.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonFigurePlate(
            imageUrl: url,
            paperColor: p.plate,
            radius: 12,
            onTap: () => _zoom(url, caption.isNotEmpty ? caption : _points[_section.point].itemName),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(caption, style: type.caption),
          ],
        ],
      );
    }

    Widget text(int? active) {
      if (line.rich) {
        return LessonRichText(
          text: line.text,
          bn: widget.bn,
          style: style,
          figurePaper: p.plate,
          captionStyle: type.caption,
          onOpenImage: _zoom,
          onOpenNote: (body) => _openNote(body, p),
        );
      }
      return Align(
        alignment: align == TextAlign.center ? Alignment.center : AlignmentDirectional.centerStart,
        child: DefaultTextStyle.merge(
          textAlign: align,
          child: HighlightedParagraph(text: line.text, activeSentence: active, style: style, highlight: p.highlight),
        ),
      );
    }

    Widget follow(Widget Function(int? local) build) {
      if (line.sentences.isEmpty) return build(null);
      return ValueListenableBuilder<int?>(
        valueListenable: _reader.active,
        builder: (context, active, _) {
          final local = active == null ? null : active - offset;
          final inLine = local != null && local >= 0 && local < line.sentences.length ? local : null;
          return build(inLine);
        },
      );
    }

    switch (line.role) {
      case _Role.tip:
        return follow((local) => _EdgeBlock(
              tint: p.tipTint,
              edge: p.tipEdge,
              reading: line.rich && local != null ? p.highlight : null,
              child: text(line.rich ? null : local),
            ));
      case _Role.wrong:
      case _Role.right:
        final wrong = line.role == _Role.wrong;
        return follow((local) {
          final onLabel = local != null && local < line.labelSentences;
          final inText = local == null || onLabel ? null : local - line.labelSentences;
          return _EdgeBlock(
            tint: wrong ? p.wrongTint : p.rightTint,
            edge: wrong ? p.wrongEdge : p.rightEdge,
            reading: line.rich && inText != null ? p.highlight : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(
                  text: line.label!,
                  color: wrong ? p.wrongLabel : p.rightLabel,
                  fill: wrong ? p.wrongChip : p.rightChip,
                  style: type.label,
                  reading: onLabel,
                ),
                const SizedBox(height: 8),
                text(line.rich ? null : inText),
              ],
            ),
          );
        });
      default:
        return follow((local) {
          final child = text(line.rich ? null : local);
          if (!line.rich || local == null) return child;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: p.highlight.withValues(alpha: HighlightedParagraph.highlightAlpha),
              borderRadius: BorderRadius.circular(6),
            ),
            child: child,
          );
        });
    }
  }
}

/// Thin progress line on the very top edge. Moves once per page turn, then
/// stands still.
class _ProgressLine extends StatelessWidget {
  final double value;
  final _Palette palette;
  final bool animate;

  const _ProgressLine({required this.value, required this.palette, required this.animate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('reader-progress'),
      height: 3,
      child: ColoredBox(
        color: palette.track,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: ColoredBox(color: palette.progress),
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns one section's scroll position: starts at [initialFraction] and
/// reports how far down the reader is.
class _SectionScroll extends StatefulWidget {
  final double initialFraction;
  final ValueChanged<double> onFraction;
  final Widget Function(ScrollController controller) builder;

  const _SectionScroll({required this.initialFraction, required this.onFraction, required this.builder});

  @override
  State<_SectionScroll> createState() => _SectionScrollState();
}

class _SectionScrollState extends State<_SectionScroll> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_report);
    if (widget.initialFraction > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final max = _controller.position.maxScrollExtent;
        _controller.jumpTo(max * widget.initialFraction);
      });
    }
  }

  void _report() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    widget.onFraction(max <= 0 ? 0 : (_controller.offset / max).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// Light tinted block with a 3 dp coloured left edge (tips, myths).
class _EdgeBlock extends StatelessWidget {
  final Color tint;
  final Color edge;
  final Color? reading;
  final Widget child;

  const _EdgeBlock({required this.tint, required this.edge, required this.child, this.reading});

  @override
  Widget build(BuildContext context) {
    final fill = reading == null ? tint : Color.alphaBlend(reading!.withValues(alpha: HighlightedParagraph.highlightAlpha), tint);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        border: Border(left: BorderSide(color: edge, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: child,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  final Color fill;
  final TextStyle style;
  final bool reading;

  const _Label({required this.text, required this.color, required this.fill, required this.style, required this.reading});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: reading ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(text, style: style.copyWith(color: color)),
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
