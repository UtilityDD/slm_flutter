import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import 'bangla_read_aloud.dart';
import 'lesson_quiz_sfx.dart';
import 'lesson_rich_text.dart';
import 'quiz_turn_card.dart';

const double lessonQuizPassRate = 0.7;
const int _maxQuestions = 10;
const int _guaranteedImageQuestions = 2;
const int _maxSearchQuota = 5;
const String _muteKey = 'chapterQuizReadAloudMuted';
const String _waGroupLink = 'https://chat.whatsapp.com/Drmeya7EyRlErKGy3VL8DF?mode=gi_t';

enum LessonQuizOutcome { passed, readAgain, closed }

class LessonQuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String? image;

  const LessonQuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctIndex,
    this.image,
  });

  static LessonQuizQuestion? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final text = raw['questionText']?.toString().trim() ?? '';
    final opts = raw['options'];
    if (opts is! List || opts.length < 2) return null;
    final options = opts.map((o) => o?.toString() ?? '').toList();
    final correct = (raw['correctAnswerIndex'] as num?)?.toInt() ?? -1;
    if (correct < 0 || correct >= options.length) return null;
    final image = raw['image']?.toString().trim();
    return LessonQuizQuestion(
      questionText: text,
      options: options,
      correctIndex: correct,
      image: (image == null || image.isEmpty) ? null : image,
    );
  }

  bool get hasImageOptions => options.any(isQuizImageOption);
  bool get isImageQuestion => image != null || hasImageOptions;

  LessonQuizQuestion shuffledOptions(math.Random rng) {
    final order = List<int>.generate(options.length, (i) => i)..shuffle(rng);
    return LessonQuizQuestion(
      questionText: questionText,
      options: [for (final i in order) options[i]],
      correctIndex: order.indexOf(correctIndex),
      image: image,
    );
  }
}

bool isQuizImageOption(String opt) {
  final s = opt.trim();
  if (s.startsWith('/')) return true;
  return RegExp(r'\.(jpg|jpeg|png|webp|gif)(\?|$)', caseSensitive: false).hasMatch(s);
}

/// Web lesson id "1.1" → `questions_1_1.json`.
String lessonQuizFileName(int module, int chapter) => 'questions_${module}_$chapter.json';

final Map<String, List<LessonQuizQuestion>> _quizCache = {};

/// Returns null when the lesson has no quiz (404, empty, offline).
Future<List<LessonQuizQuestion>?> fetchLessonQuiz(int module, int chapter) async {
  final file = lessonQuizFileName(module, chapter);
  final cached = _quizCache[file];
  if (cached != null) return cached;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(Uri.parse('${AppConstants.remoteAssetOrigin}/quizzes/$file'));
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! List) return null;
    final list = decoded.map(LessonQuizQuestion.fromJson).whereType<LessonQuizQuestion>().toList();
    if (list.isEmpty) return null;
    _quizCache[file] = list;
    return list;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Up to 10 questions, at least 2 picture questions when available.
List<LessonQuizQuestion> selectLessonQuizQuestions(List<LessonQuizQuestion> all, [math.Random? rng]) {
  final r = rng ?? math.Random();
  final imagePool = all.where((q) => q.isImageQuestion).toList()..shuffle(r);
  final textPool = all.where((q) => !q.isImageQuestion).toList()..shuffle(r);
  final guaranteed = math.min(imagePool.length, _guaranteedImageQuestions);
  final rest = [...imagePool.skip(guaranteed), ...textPool]..shuffle(r);
  final selected = [...imagePool.take(guaranteed), ...rest].take(_maxQuestions).toList()..shuffle(r);
  return selected;
}

String _quizSpeech(LessonQuizQuestion q, int index, int total, bool bn) {
  final parts = <String>[
    bn ? 'প্রশ্ন ${index + 1}, মোট $total।' : 'Question ${index + 1} of $total.',
    q.questionText.replaceAll(RegExp(r'\s+'), ' ').trim(),
  ];
  if (q.image != null) parts.add(bn ? 'এখানে একটি ছবি আছে।' : 'There is an image for this question.');
  for (var i = 0; i < q.options.length; i++) {
    final label = 'Option ${String.fromCharCode(65 + i)}';
    final opt = q.options[i];
    parts.add(isQuizImageOption(opt)
        ? '$label: ${bn ? 'ছবি।' : 'Picture.'}'
        : '$label: ${opt.replaceAll(RegExp(r'\s+'), ' ').trim()}.');
  }
  return parts.join(' ');
}

String _num(int n, bool bn) => '$n';

enum _Mode { loading, active, result, review }

/// Lesson quiz — port of the web ChapterQuizModal (70% pass, shuffle, read-aloud, review).
class LessonQuizPage extends StatefulWidget {
  final List<LessonQuizQuestion> questions;
  final String lessonBadge;
  final String lessonTitle;
  final bool bn;
  final bool isPractice;

  const LessonQuizPage({
    super.key,
    required this.questions,
    required this.lessonBadge,
    required this.lessonTitle,
    required this.bn,
    this.isPractice = false,
  });

  @override
  State<LessonQuizPage> createState() => _LessonQuizPageState();
}

class _LessonQuizPageState extends State<LessonQuizPage> {
  static const _paper = SlmColors.ivory;
  static const _paperDeep = SlmColors.ivoryDeep;
  static const _ink = SlmColors.ink;
  static const _softInk = Color(0xFF3A4660);
  static const _accent = SlmColors.gold700;
  static const _right = SlmColors.emerald700;
  static const _wrong = Color(0xFFB83A2E);
  static const _wrongSoft = Color(0xFFF2998E);

  final _rng = math.Random();
  final _voice = BanglaReadAloud();
  final _sfx = LessonQuizSfx();
  final _scroll = ScrollController();

  _Mode _mode = _Mode.loading;
  bool _retrying = false;
  List<LessonQuizQuestion> _quiz = const [];
  final Map<int, int> _answers = {};
  int _index = 0;
  int _score = 0;
  bool _muted = false;
  bool _speaking = false;
  int _searchCount = 0;

  bool get bn => widget.bn;
  String tr(String b, String e) => bn ? b : e;
  int get _passThreshold => (_quiz.length * lessonQuizPassRate).ceil();
  bool get _passed => _score >= _passThreshold;

  @override
  void initState() {
    super.initState();
    _voice.onSpeakingChanged = (v) {
      if (mounted) setState(() => _speaking = v);
    };
    _voice.init();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _muted = p.getBool(_muteKey) ?? false);
    });
    _start();
  }

  @override
  void dispose() {
    _voice.dispose();
    _sfx.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start({bool retry = false}) async {
    await _voice.stop();
    setState(() {
      _mode = _Mode.loading;
      _retrying = retry;
      _quiz = widget.questions.map((q) => q.shuffledOptions(_rng)).toList()..shuffle(_rng);
      _answers.clear();
      _index = 0;
      _score = 0;
    });
    _sfx.shuffle();
    await Future.delayed(const Duration(milliseconds: 720));
    if (!mounted) return;
    setState(() => _mode = _Mode.active);
    _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    if (_muted || _mode != _Mode.active || _quiz.isEmpty) return;
    await _voice.speak(_quizSpeech(_quiz[_index], _index, _quiz.length, bn));
  }

  Future<void> _toggleMute() async {
    HapticFeedback.selectionClick();
    final next = !_muted;
    setState(() => _muted = next);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_muteKey, next);
    if (next) {
      await _voice.stop();
    } else {
      _speakCurrent();
    }
  }

  void _select(int option) {
    HapticFeedback.selectionClick();
    _sfx.select();
    setState(() => _answers[_index] = option);
  }

  Future<void> _next() async {
    if (!_answers.containsKey(_index)) return;
    HapticFeedback.lightImpact();
    await _voice.stop();
    if (_index < _quiz.length - 1) {
      setState(() => _index++);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _speakCurrent();
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    var s = 0;
    for (var i = 0; i < _quiz.length; i++) {
      if (_answers[i] == _quiz[i].correctIndex) s++;
    }
    final passed = s >= (_quiz.length * lessonQuizPassRate).ceil();
    HapticFeedback.heavyImpact();
    await _sfx.complete();
    if (!mounted) return;
    setState(() {
      _score = s;
      _mode = _Mode.result;
    });
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    _sfx.result(passed);
  }

  Future<void> _close([LessonQuizOutcome outcome = LessonQuizOutcome.closed]) async {
    await _voice.stop();
    if (mounted) Navigator.of(context).pop(outcome);
  }

  Future<void> _askSearch(String text) async {
    if (text.trim().isEmpty) return;
    await _voice.stop();
    if (!mounted) return;
    final left = _maxSearchQuota - _searchCount;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(left > 0 ? Icons.travel_explore_rounded : Icons.psychology_alt_rounded, color: _accent, size: 36),
        title: Text(
          left > 0 ? tr('গুগলে খুঁজবেন?', 'Search on Google?') : tr('সার্চ সীমা শেষ', 'Search limit reached'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w800, color: _ink),
        ),
        content: Text(
          left > 0
              ? tr('এই কুইজে আর ${_num(left, bn)} বার খোঁজা যাবে।', '$left searches left in this quiz.')
              : tr('নিজের বুদ্ধি খাটান!', 'Use your own judgement!'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: banglaFont, color: _softInk, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('বাতিল', 'Cancel'), style: const TextStyle(fontFamily: banglaFont, color: _softInk)),
          ),
          if (left > 0)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('খুঁজুন', 'Search'), style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
    if (go != true) return;
    setState(() => _searchCount++);
    await launchUrl(
      Uri.parse('https://www.google.com/search?q=${Uri.encodeQueryComponent(text)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _report(int qIndex) async {
    await _voice.stop();
    if (!mounted) return;
    final controller = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('প্রশ্নে ভুল জানান', 'Report this question'),
              style: const TextStyle(fontFamily: banglaFont, fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 6),
            Text(
              _quiz[qIndex].questionText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: banglaFont, color: _softInk, height: 1.45),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(fontFamily: banglaFont, color: _ink),
              decoration: InputDecoration(
                hintText: tr('কী ভুল মনে হচ্ছে লিখুন…', 'What looks wrong?'),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.send_rounded),
              label: Text(tr('হোয়াটসঅ্যাপে পাঠান', 'Send on WhatsApp'),
                  style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    final comment = controller.text.trim();
    controller.dispose();
    if (send != true) return;
    final q = _quiz[qIndex];
    final options = [
      for (var i = 0; i < q.options.length; i++) '${String.fromCharCode(65 + i)}. ${q.options[i]}',
    ].join('\n');
    final divider = '-' * 40;
    final report = [
      '[QUIZ REPORT]',
      divider,
      'Lesson: #${widget.lessonBadge}',
      '',
      'Question:',
      q.questionText,
      '',
      'Options:',
      options,
      divider,
      'Comment:',
      comment,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF3F3A36),
      content: Text(
        tr('রিপোর্ট কপি হয়েছে — গ্রুপে পেস্ট করুন।', 'Report copied — paste it in the group.'),
        style: const TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w600),
      ),
    ));
    await launchUrl(Uri.parse(_waGroupLink), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_mode == _Mode.review) {
          setState(() => _mode = _Mode.result);
        } else {
          _close();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                child: AnimatedSwitcher(
                  duration: SlmMotion.slow,
                  switchInCurve: SlmMotion.emphasized,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(anim), child: child),
                  ),
                  child: switch (_mode) {
                    _Mode.loading => _buildLoading(),
                    _Mode.active => _buildActive(),
                    _Mode.result => _buildResult(),
                    _Mode.review => _buildReview(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nightButton(SlmButton button) => Theme(data: SlmTheme.night(), child: button);

  Widget _buildLoading() {
    return QuizDealSplash(
      key: const ValueKey('loading'),
      label: _retrying ? tr('নতুন করে সাজানো হচ্ছে…', 'Reshuffling…') : tr('কুইজ প্রস্তুত করা হচ্ছে...', 'Preparing quiz...'),
      paper: _paper,
      paperDeep: _paperDeep,
      ink: Colors.black,
      accent: SlmColors.gold500,
      softInk: SlmColors.mist,
    );
  }

  Widget _header({required Widget title, List<Widget> actions = const []}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _close(),
            icon: const Icon(Icons.close_rounded, color: SlmColors.ivory),
            tooltip: tr('বন্ধ করুন', 'Close'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SlmColors.navy800,
              borderRadius: SlmRadius.pillAll,
              border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6)),
            ),
            child: Text(
              widget.lessonBadge,
              style: const TextStyle(fontFamily: banglaFont, color: SlmColors.gold200, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: title),
          ...actions,
        ],
      ),
    );
  }

  Widget _buildActive() {
    final q = _quiz[_index];
    final total = _quiz.length;
    final answered = _answers.containsKey(_index);
    final last = _index == total - 1;
    final imageOptions = q.hasImageOptions;

    return Column(
      key: const ValueKey('active'),
      children: [
        _header(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isPractice ? tr('অনুশীলন কুইজ', 'Practice quiz') : tr('অধ্যায় কুইজ', 'Chapter quiz'),
                style: const TextStyle(fontFamily: banglaFont, fontSize: 12, color: SlmColors.gold300, fontWeight: FontWeight.w600),
              ),
              Text(
                '${tr('প্রশ্ন', 'Question')} ${_num(_index + 1, bn)} / ${_num(total, bn)}',
                style: const TextStyle(fontFamily: banglaFont, fontSize: 16, color: SlmColors.ivory, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _askSearch(q.questionText),
              icon: const Icon(Icons.travel_explore_rounded, color: SlmColors.mist),
              tooltip: tr('গুগলে খুঁজুন', 'Search Google'),
            ),
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _muted ? Icons.volume_off_rounded : (_speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded),
                color: _muted ? SlmColors.slate : SlmColors.gold300,
              ),
              tooltip: _muted ? tr('পড়ে শোনান', 'Read aloud') : tr('শব্দ বন্ধ', 'Mute'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: SlmMotion.base,
                    curve: SlmMotion.emphasized,
                    height: i == _index ? 6 : 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: SlmRadius.pillAll,
                      gradient: i < _index ? SlmGradients.gold : null,
                      color: i < _index
                          ? null
                          : i == _index
                              ? SlmColors.gold400.withValues(alpha: 0.6)
                              : SlmColors.navy700,
                      boxShadow: i == _index
                          ? [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.45), blurRadius: 6)]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              QuizTurnCard(
                turnKey: _index,
                paper: _paper,
                ink: Colors.black,
                accent: SlmColors.gold500,
                onFlipStart: () => _sfx.flip(),
                child: Column(
                  key: ValueKey('qface$_index'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 20,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    if (q.image != null) ...[
                      const SizedBox(height: 14),
                      LessonFigurePlate(
                        imageUrl: resolveTrainingMediaSrc(q.image!),
                        paperColor: _paperDeep,
                        maxHeightFraction: 0.28,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey('opts$_index'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (imageOptions)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          for (var i = 0; i < q.options.length; i++) _imageOption(q.options[i], i),
                        ],
                      )
                    else
                      for (var i = 0; i < q.options.length; i++) _textOption(q.options[i], i),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: _nightButton(SlmButton(
            label: last ? tr('কুইজ জমা দিন', 'Submit quiz') : tr('পরবর্তী প্রশ্ন', 'Next question'),
            variant: last ? SlmButtonVariant.primary : SlmButtonVariant.gold,
            size: SlmButtonSize.large,
            expand: true,
            trailingIcon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
            onPressed: answered ? _next : null,
          )),
        ),
      ],
    );
  }

  Widget _letter(int i, bool selected) {
    return AnimatedContainer(
      duration: SlmMotion.fast,
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? SlmColors.navy950 : SlmColors.navy700,
        border: Border.all(color: SlmColors.gold400.withValues(alpha: selected ? 0.9 : 0.45)),
      ),
      child: Text(
        String.fromCharCode(65 + i),
        style: TextStyle(fontWeight: FontWeight.w800, color: selected ? SlmColors.gold200 : SlmColors.gold300),
      ),
    );
  }

  BoxDecoration _optionDecoration(bool selected) => BoxDecoration(
        gradient: selected ? SlmGradients.gold : SlmGradients.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? SlmColors.gold200 : SlmColors.gold400.withValues(alpha: 0.28),
          width: selected ? 1.6 : 1.1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      );

  Widget _textOption(String text, int i) {
    final selected = _answers[_index] == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SlmPressable(
        pressedScale: 0.97,
        haptic: false,
        onTap: () => _select(i),
        child: AnimatedScale(
          duration: SlmMotion.fast,
          curve: SlmMotion.emphasized,
          scale: selected ? 1.02 : 1.0,
          child: AnimatedContainer(
            duration: SlmMotion.base,
            curve: SlmMotion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: _optionDecoration(selected),
            child: Row(
              children: [
                _letter(i, selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: banglaFont,
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? SlmColors.navy950 : SlmColors.ivory,
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

  Widget _imageOption(String src, int i) {
    final selected = _answers[_index] == i;
    return SlmPressable(
      pressedScale: 0.96,
      haptic: false,
      onTap: () => _select(i),
      child: AnimatedScale(
        duration: SlmMotion.fast,
        curve: SlmMotion.emphasized,
        scale: selected ? 1.03 : 1.0,
        child: AnimatedContainer(
          duration: SlmMotion.base,
          curve: SlmMotion.emphasized,
          padding: const EdgeInsets.all(4),
          decoration: _optionDecoration(selected),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: _paperDeep,
                    child: CachedNetworkImage(
                      imageUrl: resolveTrainingMediaSrc(src),
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: _softInk),
                    ),
                  ),
                ),
              ),
              Positioned(left: 6, top: 6, child: _letter(i, selected)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final total = _quiz.length;
    final pct = total == 0 ? 0 : (_score * 100 / total).round();
    final passed = _passed;
    final tone = passed ? SlmColors.emerald400 : SlmColors.gold400;

    return Column(
      key: const ValueKey('result'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => _close(),
            icon: const Icon(Icons.close_rounded, color: SlmColors.ivory),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              SlmReveal(
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct / 100),
                          duration: const Duration(milliseconds: 1100),
                          curve: SlmMotion.emphasized,
                          builder: (_, v, __) => Container(
                            width: 168,
                            height: 168,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SlmGradients.navyHero,
                              border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55), width: 1.2),
                              boxShadow: [
                                BoxShadow(color: tone.withValues(alpha: 0.28 * v + 0.08), blurRadius: 28, spreadRadius: 2),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: v,
                                    strokeWidth: 11,
                                    strokeCap: StrokeCap.round,
                                    color: tone,
                                    backgroundColor: SlmColors.navy700,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(passed ? '✨' : '💪', style: const TextStyle(fontSize: 26)),
                                    Text(
                                      '${_num((v * 100).round(), bn)}%',
                                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: tone),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (passed)
                          const IgnorePointer(
                            child: SlmSparkBurst(playOnMount: true, radius: 104, count: 22),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SlmReveal(
                index: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.14),
                      borderRadius: SlmRadius.pillAll,
                      border: Border.all(color: tone.withValues(alpha: 0.55)),
                    ),
                    child: Text(
                      passed ? tr('পাস', 'Pass') : tr('আরেকটু চেষ্টা', 'Almost there'),
                      style: TextStyle(fontFamily: banglaFont, fontWeight: FontWeight.w800, color: tone),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SlmReveal(
                index: 2,
                child: Column(
                  children: [
                    Text(
                      passed ? tr('কুইজ সম্পন্ন!', 'Quiz complete!') : tr('পাস মার্ক অর্জিত হয়নি', 'Pass mark not reached'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SlmColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('মোট ${_num(total, bn)}টির মধ্যে ${_num(_score, bn)}টি সঠিক', '$_score of $total correct'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: SlmColors.gold200,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      passed
                          ? tr('ভালো হয়েছে—কুইজটি সম্পন্ন।', 'Well done — quiz complete.')
                          : tr('নিচে উত্তরগুলো দেখে নিন।', 'Check your answers below.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: banglaFont, fontSize: 14, color: SlmColors.mist),
                    ),
                  ],
                ),
              ),
              if (!passed)
                SlmReveal(
                  index: 3,
                  child: Column(
                    children: [
                      const SizedBox(height: 22),
                      _passBar(pct / 100),
                      const SizedBox(height: 10),
                      Text(
                        tr('পাস করার জন্য 70% সঠিক উত্তর প্রয়োজন।', 'You need 70% correct to pass.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _wrongSoft,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _nightButton(SlmButton(
                label: passed ? tr('পরবর্তী পাঠে যান', 'Go to next lesson') : tr('আবার চেষ্টা করুন', 'Try again'),
                variant: passed ? SlmButtonVariant.primary : SlmButtonVariant.gold,
                size: SlmButtonSize.large,
                expand: true,
                trailingIcon: passed ? Icons.arrow_forward_rounded : Icons.refresh_rounded,
                onPressed: passed ? () => _close(LessonQuizOutcome.passed) : () => _start(retry: true),
              )),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _nightButton(SlmButton.secondary(
                      label: tr('উত্তরগুলো দেখুন', 'Review answers'),
                      expand: true,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _mode = _Mode.review);
                      },
                    )),
                  ),
                  if (!passed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _nightButton(SlmButton.secondary(
                        label: tr('আবার পড়ুন', 'Read again'),
                        expand: true,
                        onPressed: () => _close(LessonQuizOutcome.readAgain),
                      )),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passBar(double value) {
    return SizedBox(
      height: 26,
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: SlmColors.navy900,
                    borderRadius: SlmRadius.pillAll,
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.25), width: 0.8),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 8,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.clamp(0, 1)),
                  duration: const Duration(milliseconds: 900),
                  curve: SlmMotion.emphasized,
                  builder: (_, v, __) => Container(
                    width: w * v,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: SlmGradients.gold,
                      borderRadius: SlmRadius.pillAll,
                      boxShadow: [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.45), blurRadius: 6)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * lessonQuizPassRate - 1.5,
                top: 2,
                child: Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SlmColors.emerald400,
                    borderRadius: SlmRadius.pillAll,
                    boxShadow: [BoxShadow(color: SlmColors.emerald400.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      key: const ValueKey('review'),
      children: [
        _header(
          title: Text(
            tr('আপনার উত্তরগুলো দেখুন', 'Review your answers'),
            style: const TextStyle(fontFamily: banglaFont, fontSize: 16, fontWeight: FontWeight.w800, color: SlmColors.ivory),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _quiz.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, qi) => qi < 4 ? SlmReveal(index: qi, child: _reviewCard(qi)) : _reviewCard(qi),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: _nightButton(SlmButton(
            label: tr('ফলাফলে ফিরে যান', 'Back to result'),
            variant: SlmButtonVariant.gold,
            expand: true,
            icon: Icons.arrow_back_rounded,
            onPressed: () => setState(() => _mode = _Mode.result),
          )),
        ),
      ],
    );
  }

  Widget _reviewCard(int qi) {
    final q = _quiz[qi];
    final picked = _answers[qi];
    final correct = picked == q.correctIndex;
    final status = picked == null
        ? tr('উত্তর দেওয়া হয়নি', 'Not answered')
        : correct
            ? tr('সঠিক', 'Correct')
            : tr('ভুল', 'Wrong');
    final statusColor = correct ? _right : _wrong;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_paper, _paperDeep],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${tr('প্রশ্ন', 'Q')} ${_num(qi + 1, bn)}',
                style: const TextStyle(fontFamily: banglaFont, fontSize: 13, fontWeight: FontWeight.w700, color: _softInk),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(status,
                    style: TextStyle(fontFamily: banglaFont, fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _askSearch(q.questionText),
                icon: const Icon(Icons.travel_explore_rounded, size: 20, color: _softInk),
                tooltip: tr('গুগলে খুঁজুন', 'Search Google'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _report(qi),
                icon: const Icon(Icons.flag_outlined, size: 20, color: _softInk),
                tooltip: tr('ভুল জানান', 'Report'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              q.questionText,
              style: const TextStyle(fontFamily: banglaFont, fontSize: 16, height: 1.45, fontWeight: FontWeight.w700, color: _ink),
            ),
          ),
          if (q.image != null) ...[
            const SizedBox(height: 8),
            LessonFigurePlate(imageUrl: resolveTrainingMediaSrc(q.image!), paperColor: _paperDeep, maxHeightFraction: 0.22),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < q.options.length; i++) _reviewOption(q, i, picked),
        ],
      ),
    );
  }

  Widget _reviewOption(LessonQuizQuestion q, int i, int? picked) {
    final isCorrect = i == q.correctIndex;
    final isPicked = i == picked;
    final color = isCorrect ? _right : (isPicked ? _wrong : _softInk);
    final icon = isCorrect
        ? Icons.check_circle_rounded
        : isPicked
            ? Icons.cancel_rounded
            : Icons.radio_button_unchecked_rounded;
    final opt = q.options[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: isCorrect || isPicked ? color : _softInk.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isQuizImageOption(opt)
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 84,
                        width: 120,
                        color: _paperDeep,
                        child: CachedNetworkImage(imageUrl: resolveTrainingMediaSrc(opt), fit: BoxFit.contain),
                      ),
                    ),
                  )
                : Text(
                    opt,
                    style: TextStyle(
                      fontFamily: banglaFont,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: isCorrect || isPicked ? FontWeight.w700 : FontWeight.w500,
                      color: isCorrect || isPicked ? color : _softInk,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
