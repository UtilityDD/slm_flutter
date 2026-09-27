import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'training_models.dart';

class LessonDetailSheet extends StatefulWidget {
  final LessonCardItem lesson;

  const LessonDetailSheet({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonDetailSheet> createState() => _LessonDetailSheetState();
}

class _LessonDetailSheetState extends State<LessonDetailSheet> {
  int _readingSeconds = 15;
  Timer? _timer;
  bool _canClaim = false;

  @override
  void initState() {
    super.initState();
    _startReadingGate();
  }

  void _startReadingGate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_readingSeconds > 0) {
        setState(() {
          _readingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _canClaim = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'পাঠ ${lesson.moduleNumber}.${lesson.chapterNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryAmber,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Title
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                // Mission Briefing
                if (lesson.missionBriefing != null && lesson.missionBriefing!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flag_rounded, color: AppColors.electricBlue, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'মিশন ব্রিফিং (Mission Briefing)',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.electricBlue, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lesson.missionBriefing!,
                                style: const TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sections / Instructions
                if (lesson.sections.isNotEmpty) ...[
                  const Text(
                    'মূল নির্দেশনা ও নিরাপত্তা ধাপ:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...lesson.sections.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final text = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.primaryAmber,
                            child: Text(
                              '$idx',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate900, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                ],

                // Pro-Tip
                if (lesson.proTip != null && lesson.proTip!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.safeGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.safeGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.safeGreen, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'প্রো-টিপ (Pro Tip)',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.safeGreen, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(lesson.proTip!, style: const TextStyle(fontSize: 12, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Myth Buster
                if (lesson.mythBuster != null && lesson.mythBuster!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.safetyOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.safetyOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology_alt_rounded, color: AppColors.safetyOrange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ভুল ধারণা দূরীকরণ (Myth Buster)',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.safetyOrange, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(lesson.mythBuster!, style: const TextStyle(fontSize: 12, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Action: Reading Gate Timer & Claim Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.slate700 : AppColors.slate200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_canClaim) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_top_rounded, color: AppColors.primaryAmber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'রিডিং গেট: সম্পূর্ণ পাঠ করুন (অবশিষ্ট: $_readingSeconds সে.)',
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryAmber, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (15 - _readingSeconds) / 15,
                    backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAmber),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canClaim
                        ? () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('অভিনন্দন! "${lesson.title}" পাঠ সম্পন্ন! +২০ বোনাস পয়েন্ট অর্জিত!'),
                                backgroundColor: AppColors.safeGreen,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _canClaim ? 'আমি এটি পাঠ করেছি (+২০ পয়েন্ট দাবি করুন)' : 'পাঠ সম্পন্ন করতে অপেক্ষা করুন...',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAmber,
                      foregroundColor: AppColors.slate900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
