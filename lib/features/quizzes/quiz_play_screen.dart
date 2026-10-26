import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'hourly_pack.dart';

/// Hourly quiz from the bundled pack. The phone does not know the right answer.
/// A logged-in player sends the chosen options; Supabase marks the score.
class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  List<HourlyQuestion> _questions = [];
  final List<String> _choices = [];
  String _quizId = '';
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool _loading = true;
  bool _submitting = false;
  bool _finished = false;
  String? _loadError;
  int _secondsRemaining = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final pack = await HourlyPack.load();
      final userId = SupabaseService.client.auth.currentUser?.id ?? 'guest';
      final quizId = hourlyQuizId(DateTime.now());
      final points = ref.read(authProvider).profile?.points ?? 0;
      final questions = pickHourlyQuestions(
        bank: pack.questions,
        seed: '$userId:$quizId',
        lifetimePoints: points,
      );
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _quizId = quizId;
        _loading = false;
        _loadError = questions.isEmpty ? 'এই ঘণ্টার প্রশ্ন পাওয়া যায়নি' : null;
      });
      if (questions.isNotEmpty) _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'কুইজ খোলা যায়নি';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25;
      _isAnswered = false;
      _selectedIndex = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _lockChoice();
      }
    });
  }

  void _lockChoice() {
    if (_isAnswered) return;
    _timer?.cancel();
    final question = _questions[_currentIndex];
    final choice = _selectedIndex == null ? '' : question.options[_selectedIndex!].value;
    setState(() {
      _isAnswered = true;
      _choices.add(choice);
    });
  }

  void _selectOption(int index) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);
    _lockChoice();
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _startTimer();
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_finished || _submitting) return;
    _finished = true;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      _showResult(
        title: 'খেলার শেষ',
        body: 'অতিথি হিসেবে পয়েন্ট জমা হয় না। লগইন করলে এই ঘণ্টার স্কোর যোগ হবে।',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final answers = [
        for (var i = 0; i < _questions.length; i++)
          {'id': _questions[i].id, 'choice': i < _choices.length ? _choices[i] : ''},
      ];
      final raw = await SupabaseService.client.rpc('submit_flutter_hourly_quiz', params: {
        'p_quiz_id': _quizId,
        'p_answers': answers,
        'p_user_id': user.id,
      });
      if (!mounted) return;
      final result = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      if (result['success'] == true) {
        final already = result['already_played'] == true;
        final score = result['score'];
        final correct = result['correct'];
        _showResult(
          title: already ? 'এই ঘণ্টা খেলা হয়ে গেছে' : 'কুইজ সমাপ্ত',
          body: already
              ? 'এই ঘণ্টার পয়েন্ট আগেই জমা হয়েছে।'
              : 'সঠিক $correct / ${_questions.length}। যোগ হয়েছে $score পয়েন্ট।',
        );
      } else {
        _showResult(title: 'স্কোর জমা হয়নি', body: _errorText(result['error']?.toString()));
      }
    } catch (_) {
      if (!mounted) return;
      _showResult(
        title: 'স্কোর জমা হয়নি',
        body: 'সার্ভারে স্কোর ফাংশন এখনো বসানো হয়নি, অথবা নেট বন্ধ। প্রশ্ন ফোনেই ছিল।',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _errorText(String? code) {
    return switch (code) {
      'answer_key_missing' => 'উত্তরের তালিকা সার্ভারে এখনো বসানো হয়নি। ওয়েব কুইজ আগের মতোই আছে।',
      'guest_preview' => 'অতিথি অ্যাকাউন্টে পয়েন্ট জমা হয় না।',
      'hourly_window_closed' => 'এই ঘণ্টা বন্ধ হয়ে গেছে। স্কোর যোগ হয়নি।',
      'hourly_time_mismatch' => 'এই ঘণ্টার স্কোর এখন নেওয়া যাচ্ছে না।',
      'Not authenticated' => 'লগইন করে আবার খেলুন।',
      _ => 'স্কোর যোগ করা যায়নি। আবার চেষ্টা করুন।',
    };
  }

  void _showResult({required String title, required String body}) {
    if (!mounted) return;
    final page = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title, style: bangla(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
          content: Text(body, style: bangla(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.55)),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (page.canPop()) page.pop();
              },
              child: const Text('ফিরে যান'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: const Text('ঘণ্টার কুইজ'),
        actions: [
          if (_questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!, style: const TextStyle(fontWeight: FontWeight.w600)))
              : _body(isDark),
    );
  }

  Widget _body(bool isDark) {
    final question = _questions[_currentIndex];
    final imageOptions = question.options.every((option) => option.hasImage);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: _secondsRemaining <= 5 ? AppColors.alertRed : AppColors.primaryAmber),
              const SizedBox(width: 6),
              Text(
                '$_secondsRemaining সেকেন্ড',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _secondsRemaining <= 5 ? AppColors.alertRed : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _secondsRemaining / 25,
            minHeight: 4,
            backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
            color: _secondsRemaining <= 5 ? AppColors.alertRed : AppColors.primaryAmber,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (question.image.isNotEmpty) ...[
                            SizedBox(
                              height: 180,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE7E5E4)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    question.image,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFE7E5E4)),
                            ),
                            child: Text(
                              question.text,
                              textAlign: TextAlign.center,
                              style: bangla(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.55),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (imageOptions)
                            _ImageChoices(
                              options: question.options,
                              selectedIndex: _selectedIndex,
                              locked: _isAnswered,
                              onPick: _selectOption,
                            )
                          else
                            for (var index = 0; index < question.options.length; index++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _TextChoice(
                                  letter: String.fromCharCode(65 + index),
                                  option: question.options[index],
                                  selected: _selectedIndex == index,
                                  locked: _isAnswered,
                                  onTap: () => _selectOption(index),
                                ),
                              ),
                          if (_isAnswered)
                            FilledButton(
                              onPressed: _submitting ? null : _nextQuestion,
                              child: Text(
                                _submitting
                                    ? 'জমা হচ্ছে'
                                    : _currentIndex < _questions.length - 1
                                        ? 'পরের প্রশ্ন'
                                        : 'ফলাফল',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TextChoice extends StatelessWidget {
  final String letter;
  final HourlyOption option;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _TextChoice({
    required this.letter,
    required this.option,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primaryAmber : const Color(0xFFE7E5E4);
    return Material(
      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(letter, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              if (option.hasImage) ...[
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Image.asset(option.image, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  option.hasImage ? '' : option.value,
                  style: bangla(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageChoices extends StatelessWidget {
  final List<HourlyOption> options;
  final int? selectedIndex;
  final bool locked;
  final ValueChanged<int> onPick;

  const _ImageChoices({
    required this.options,
    required this.selectedIndex,
    required this.locked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var index = 0; index < options.length; index++)
          _ImageTile(
            option: options[index],
            selected: selectedIndex == index,
            locked: locked,
            onTap: () => onPick(index),
          ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final HourlyOption option;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _ImageTile({
    required this.option,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.primaryAmber : const Color(0xFFE7E5E4), width: selected ? 2 : 1),
          ),
          child: Image.asset(
            option.image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      ),
    );
  }
}
