import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final List<QuizQuestion> _questions = const [
    QuizQuestion(
      question: '১১ কেভি লাইনে কাজ শুরু করার পূর্বে প্রথম আবশ্যিক পদক্ষেপ কী?',
      options: [
        'কন্ডাক্টরে হাত দিয়ে বিদ্যুৎ পরীক্ষা করা',
        'পিটিডব্লিউ (Permit To Work) নিশ্চিতকরণ ও ডিসচার্জ রড দিয়ে আর্থিং করা',
        'ফিউজ সরাসরি শর্ট করে দেওয়া',
        'হেলমেট খুলে লাইনে ওঠা',
      ],
      correctIndex: 1,
      explanation: 'পিটিডব্লিউ গ্রহণ এবং উভয় প্রান্তে নির্ভরযোগ্য আর্থিং না করে কোনো অবস্থাতেই লাইনে স্পর্শ করা যাবে না।',
    ),
    QuizQuestion(
      question: 'বৈদ্যুতিক ইনসুলেটিং গ্লাভস ব্যবহারের আগে কোন পরীক্ষাটি করা বাধ্যতামূলক?',
      options: [
        'হাওয়া ফুলিয়ে এয়ার টেস্ট (Air Leak Test) করা',
        'জলে ভিজিয়ে রাখা',
        'রোদ্রে শুকানো',
        'তেল বা গ্রিজ মাখানো',
      ],
      correctIndex: 0,
      explanation: 'গ্লাভসে কোনো ক্ষুদ্র ছিদ্র আছে কিনা তা নিশ্চিত হতে বাতাস ভরে এয়ার টেস্ট করা আবশ্যক।',
    ),
    QuizQuestion(
      question: 'ট্রান্সফরমার ডিও (DO) ফিউজ পরিবর্তনের সময় কী ব্যবহার করতে হবে?',
      options: [
        'লোহার রড',
        'শুকনো বাঁশ বা ইনসুলেটেড অপারেটিং রড',
        'খালি হাত',
        'তামার তারের টুকরো',
      ],
      correctIndex: 1,
      explanation: 'ডিও ফিউজ প্রতিস্থাপনে সর্বদা পরীক্ষিত ইনসুলেটেড অপারেটিং রড এবং সেফটি গ্লাভস ব্যবহার করতে হয়।',
    ),
    QuizQuestion(
      question: 'কর্মক্ষেত্রে সহকর্মী বিদ্যুৎস্পৃষ্ট হলে প্রাথমিক কর্তব্য কী?',
      options: [
        'তাকে খালি হাতে টেনে ধরা',
        'অবিলম্বে মেইন সুইচ বন্ধ করা অথবা শুকনো কাঠ/ইনসুলেটর দিয়ে সংযোগ বিচ্ছিন্ন করা',
        'জল ঢেলে দেওয়া',
        'অপেক্ষা করা',
      ],
      correctIndex: 1,
      explanation: 'বিদ্যুৎ সংযোগ দ্রুত বিচ্ছিন্ন করতে হবে এবং উদ্ধারকারীকে অবশ্যই নিজেকে ইনসুলেটেড রাখতে হবে।',
    ),
    QuizQuestion(
      question: 'পোলে কাজের সময় ফুল বডি সেফটি হারনেস কোথায় লক করতে হবে?',
      options: [
        'পোল বা নিরাপদ ফিক্সড স্ট্রাকচারে সুরক্ষিত অ্যাঙ্করেজ পয়েন্টে',
        'বিদ্যুৎবাহী তারের সাথে',
        'নিজের জামার সাথে',
        'লক করার প্রয়োজন নেই',
      ],
      correctIndex: 0,
      explanation: 'সেফটি ল্যানইয়ার্ড সর্বদা নির্ভরযোগ্য ও ওজন সহ্যকারী দৃঢ় স্ট্রাকচারে লক করতে হয়।',
    ),
  ];

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _isAnswered = false;
  int _score = 0;
  int _secondsRemaining = 25;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25;
      _isAnswered = false;
      _selectedIndex = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    if (!_isAnswered) {
      setState(() {
        _isAnswered = true;
      });
    }
  }

  void _selectOption(int index) {
    if (_isAnswered) return;
    _timer?.cancel();

    final isCorrect = index == _questions[_currentIndex].correctIndex;
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      if (isCorrect) {
        _score += 10;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startTimer();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.slate800 : Colors.white,
          title: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.primaryAmber, size: 28),
              SizedBox(width: 8),
              Text('কুইজ সমাপ্ত!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'আপনি মোট অর্জিত করেছেন: $_score পয়েন্ট',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'মোট প্রশ্ন: ${_questions.length} • সঠিক উত্তর: ${_score ~/ 10}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAmber,
                foregroundColor: AppColors.slate900,
              ),
              child: const Text('হোমে ফিরে যান'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('প্রশ্ন ${_currentIndex + 1} / ${_questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'স্কোর: $_score',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryAmber, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer Progress Bar
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: _secondsRemaining <= 5 ? AppColors.alertRed : AppColors.primaryAmber,
                ),
                const SizedBox(width: 6),
                Text(
                  'অবশিষ্ট সময়: $_secondsRemaining সেকেন্ড',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _secondsRemaining <= 5 ? AppColors.alertRed : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _secondsRemaining / 25,
              backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _secondsRemaining <= 5 ? AppColors.alertRed : AppColors.primaryAmber,
              ),
            ),
            const SizedBox(height: 20),

            // Question Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
              ),
              child: Text(
                question.question,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4),
              ),
            ),
            const SizedBox(height: 18),

            // Options
            ...List.generate(question.options.length, (index) {
              final optText = question.options[index];
              Color optBorder = isDark ? AppColors.slate700 : AppColors.slate200;
              Color optBg = isDark ? AppColors.slate800 : Colors.white;
              Color optTextCol = isDark ? Colors.white : AppColors.slate900;

              if (_isAnswered) {
                if (index == question.correctIndex) {
                  optBorder = AppColors.safeGreen;
                  optBg = AppColors.safeGreen.withValues(alpha: 0.15);
                  optTextCol = AppColors.safeGreen;
                } else if (_selectedIndex == index) {
                  optBorder = AppColors.alertRed;
                  optBg = AppColors.alertRed.withValues(alpha: 0.15);
                  optTextCol = AppColors.alertRed;
                }
              }

              return InkWell(
                onTap: () => _selectOption(index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: optBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: optBorder, width: _isAnswered && (index == question.correctIndex || _selectedIndex == index) ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: optBorder.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(fontWeight: FontWeight.w700, color: optTextCol),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: optTextCol),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Explanation & Next Button
            if (_isAnswered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.electricBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.explanation,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.slate900),
                  label: Text(
                    _currentIndex < _questions.length - 1 ? 'পরবর্তী প্রশ্ন' : 'ফলাফল দেখুন',
                    style: const TextStyle(color: AppColors.slate900, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAmber,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
