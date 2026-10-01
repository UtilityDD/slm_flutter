import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../identify/library_catalog.dart';

/// Identify practice, laid out like the web game: one screen, no scroll.
/// A tap flashes right or wrong on the answers, then the next question arrives.
class IdentifyQuizScreen extends ConsumerStatefulWidget {
  const IdentifyQuizScreen({super.key});

  @override
  ConsumerState<IdentifyQuizScreen> createState() => _IdentifyQuizScreenState();
}

class _IdentifyQuizScreenState extends ConsumerState<IdentifyQuizScreen> {
  IdentifyQuestion? _question;
  String? _pickedId;
  bool _flashRight = false;
  bool _ready = false;
  final List<String> _recentModes = [];
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    final items = await ref.read(libraryCatalogProvider.future);
    final charts = await ref.read(chartFactsProvider.future);
    if (!mounted) return;
    setState(() {
      _question = buildNextIdentifyQuestion(items, charts: charts);
      _ready = true;
    });
    if (_question != null) _rememberMode();
  }

  void _rememberMode() {
    final q = _question;
    if (q == null) return;
    _recentModes.add(q.mode);
    if (_recentModes.length > 6) _recentModes.removeAt(0);
  }

  void _pick(String id) {
    final question = _question;
    if (question == null || _pickedId != null) return;
    final ok = id == question.correctId;
    setState(() {
      _pickedId = id;
      _flashRight = ok;
    });
    ref.read(identifyStatsProvider.notifier).recordAnswer(ok);
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 900), _goNext);
  }

  void _goNext() {
    final items = ref.read(libraryCatalogProvider).value;
    final charts = ref.read(chartFactsProvider).value ?? const <ChartFact>[];
    if (!mounted || items == null) return;
    final next = buildNextIdentifyQuestion(
      items,
      avoidId: _question?.id,
      recentModes: _recentModes,
      charts: charts,
    );
    setState(() {
      _question = next;
      _pickedId = null;
    });
    _rememberMode();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(identifyStatsProvider);
    final question = _question;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('পরিচিতি কুইজ'),
        actions: [
          if (stats.lifeTotal > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${stats.percent}% · ${stats.lifeCorrect}/${stats.lifeTotal}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : question == null
              ? const Center(child: Text('চেনার মতো ছবি নেই', style: TextStyle(fontWeight: FontWeight.w800)))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _Board(
                    question: question,
                    pickedId: _pickedId,
                    flashRight: _flashRight,
                    onPick: _pick,
                  ),
                ),
    );
  }
}

class _Board extends StatelessWidget {
  final IdentifyQuestion question;
  final String? pickedId;
  final bool flashRight;
  final ValueChanged<String> onPick;

  const _Board({
    required this.question,
    required this.pickedId,
    required this.flashRight,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (question.textChoices || question.photoChoices) {
          return _centered(constraints, _photoOrText(constraints));
        }
        return _centered(constraints, _nameSet(constraints));
      },
    );
  }

  Widget _centered(BoxConstraints constraints, Widget child) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    );
  }

  Widget _nameSet(BoxConstraints constraints) {
    const names = 132.0;
    const prompt = 32.0;
    const gaps = 20.0;
    final photo = math.min(240.0, math.max(120.0, constraints.maxHeight - names - prompt - gaps));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'নাম কী?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: photo,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E5E4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _FitImage(question.heroImage),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _AnswerBoard(
          flashRight: pickedId == null ? null : flashRight,
          child: _NameGrid(question: question, pickedId: pickedId, onPick: onPick),
        ),
      ],
    );
  }

  Widget _photoOrText(BoxConstraints constraints) {
    final prompt = _Prompt(question: question);
    final overhead = question.mode == 'clue' ? 148.0 : 64.0;
    final side = math.min(
      constraints.maxWidth,
      math.max(160.0, constraints.maxHeight - overhead),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        prompt,
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: side,
            height: side,
            child: _AnswerBoard(
              flashRight: pickedId == null ? null : flashRight,
              child: question.textChoices
                  ? _TextGrid(question: question, pickedId: pickedId, onPick: onPick)
                  : _PhotoGrid(question: question, pickedId: pickedId, onPick: onPick),
            ),
          ),
        ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  final IdentifyQuestion question;

  const _Prompt({required this.question});

  @override
  Widget build(BuildContext context) {
    if (question.mode == 'clue') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              question.detail,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35, color: Color(0xFF44403C)),
            ),
          ),
        ],
      );
    }

    if (question.highlight.isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'কোনটা '),
            TextSpan(text: question.highlight, style: const TextStyle(color: Color(0xFFEA580C))),
            const TextSpan(text: '?'),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink),
      );
    }

    return Text(
      question.prompt,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink),
    );
  }
}

class _AnswerBoard extends StatelessWidget {
  final bool? flashRight;
  final Widget child;

  const _AnswerBoard({required this.flashRight, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (flashRight != null)
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: flashRight! ? const Color(0xFF059669) : const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Text(
                flashRight! ? 'ঠিক' : 'ভুল',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _FitImage extends StatelessWidget {
  final String path;

  const _FitImage(this.path);

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Image.asset(
      path,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined, color: AppColors.muted),
    );
  }
}

class _NameGrid extends StatelessWidget {
  final IdentifyQuestion question;
  final String? pickedId;
  final ValueChanged<String> onPick;

  const _NameGrid({required this.question, required this.pickedId, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _name(question.choices[0])),
            const SizedBox(width: 8),
            Expanded(child: _name(question.choices[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _name(question.choices[2])),
            const SizedBox(width: 8),
            Expanded(child: _name(question.choices[3])),
          ],
        ),
      ],
    );
  }

  Widget _name(IdentifyChoice choice) {
    return _ChoiceShell(
      picked: pickedId == choice.id,
      right: choice.id == question.correctId,
      locked: pickedId != null,
      onTap: () => onPick(choice.id),
      child: Text(
        choice.nameBn,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.25),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final IdentifyQuestion question;
  final String? pickedId;
  final ValueChanged<String> onPick;

  const _PhotoGrid({required this.question, required this.pickedId, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _row(question.choices[0], question.choices[1])),
        const SizedBox(height: 8),
        Expanded(child: _row(question.choices[2], question.choices[3])),
      ],
    );
  }

  Widget _row(IdentifyChoice a, IdentifyChoice b) {
    return Row(
      children: [
        Expanded(child: _photo(a)),
        const SizedBox(width: 8),
        Expanded(child: _photo(b)),
      ],
    );
  }

  Widget _photo(IdentifyChoice choice) {
    return _ChoiceShell(
      picked: pickedId == choice.id,
      right: choice.id == question.correctId,
      locked: pickedId != null,
      onTap: () => onPick(choice.id),
      padding: const EdgeInsets.all(8),
      child: SizedBox.expand(child: _FitImage(choice.image)),
    );
  }
}

class _TextGrid extends StatelessWidget {
  final IdentifyQuestion question;
  final String? pickedId;
  final ValueChanged<String> onPick;

  const _TextGrid({required this.question, required this.pickedId, required this.onPick});

  static const _tones = [
    (Color(0xFFE0F2FE), Color(0xFF0284C7), Color(0xFF0C4A6E)),
    (Color(0xFFFFF7ED), Color(0xFFEA580C), Color(0xFF7C2D12)),
    (Color(0xFFECFDF5), Color(0xFF059669), Color(0xFF064E3B)),
    (Color(0xFFF5F3FF), Color(0xFF7C3AED), Color(0xFF4C1D95)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _row(0, 1)),
        const SizedBox(height: 8),
        Expanded(child: _row(2, 3)),
      ],
    );
  }

  Widget _row(int a, int b) {
    return Row(
      children: [
        Expanded(child: _tile(a)),
        const SizedBox(width: 8),
        Expanded(child: _tile(b)),
      ],
    );
  }

  Widget _tile(int index) {
    final choice = question.choices[index];
    final tone = _tones[index];
    final letter = String.fromCharCode(65 + index);
    return _ChoiceShell(
      picked: pickedId == choice.id,
      right: choice.id == question.correctId,
      locked: pickedId != null,
      fill: tone.$1,
      onTap: () => onPick(choice.id),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone.$2, shape: BoxShape.circle),
            child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          Text(
            choice.nameBn,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, height: 1.15, color: tone.$3),
          ),
        ],
      ),
    );
  }
}

class _ChoiceShell extends StatelessWidget {
  final bool picked;
  final bool right;
  final bool locked;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final Color fill;

  const _ChoiceShell({
    required this.picked,
    required this.right,
    required this.locked,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    this.fill = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final showRight = locked && picked && right;
    final showWrong = locked && picked && !right;
    final border = showRight
        ? const Color(0xFF34D399)
        : showWrong
            ? const Color(0xFFFB7185)
            : const Color(0xFFE7E5E4);
    final background = showRight
        ? const Color(0xFFECFDF5)
        : showWrong
            ? const Color(0xFFFFF1F2)
            : fill;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: showRight || showWrong ? 2 : 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
