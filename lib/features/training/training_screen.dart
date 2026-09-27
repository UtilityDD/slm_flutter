import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'lesson_detail_sheet.dart';
import 'training_models.dart';
import 'training_provider.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  int? _expandedModuleNumber = 1; // Default open module 1

  @override
  Widget build(BuildContext context) {
    final ladderAsync = ref.watch(trainingLadderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ladderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('প্রশিক্ষণ লোড ত্রুটি: $e')),
        data: (modules) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.electricBlue, Color(0xFF1E40AF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stairs_rounded, color: Colors.amber, size: 36),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'লাইনম্যান সিঁড়ি আরোহণ (Safety Ladder)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'লেভেল ১ থেকে শুরু করে ধাপে ধাপে ১০টি অধ্যায় সম্পন্ন করুন এবং মাস্টার লাইনম্যান হিসেবে উত্তীর্ণ হন।',
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ladder Progression Path
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = modules[index];
                      final isLast = index == modules.length - 1;
                      return _buildLadderRung(item, isLast, isDark);
                    },
                    childCount: modules.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLadderRung(TrainingModuleItem item, bool isLast, bool isDark) {
    final isExpanded = _expandedModuleNumber == item.moduleNumber;

    Color nodeColor;
    IconData nodeIcon;

    switch (item.status) {
      case LadderStepStatus.completed:
        nodeColor = AppColors.safeGreen;
        nodeIcon = Icons.check_rounded;
        break;
      case LadderStepStatus.active:
        nodeColor = AppColors.primaryAmber;
        nodeIcon = Icons.electric_bolt_rounded;
        break;
      case LadderStepStatus.locked:
        nodeColor = isDark ? AppColors.slate700 : AppColors.slate200;
        nodeIcon = Icons.lock_outline_rounded;
        break;
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Rail & Connector Line
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  // Step Badge Node
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isActive
                          ? AppColors.primaryAmber.withValues(alpha: 0.2)
                          : (item.isCompleted ? AppColors.safeGreen.withValues(alpha: 0.2) : (isDark ? AppColors.slate800 : AppColors.slate100)),
                      border: Border.all(
                        color: nodeColor,
                        width: item.isActive ? 2.5 : 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        nodeIcon,
                        color: nodeColor,
                        size: item.isCompleted ? 22 : 20,
                      ),
                    ),
                  ),

                  // Vertical connecting line to next step
                  if (!isLast)
                    Container(
                      width: 3,
                      height: isExpanded ? 320 : 70,
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? AppColors.safeGreen.withValues(alpha: 0.8)
                            : (isDark ? AppColors.slate700 : AppColors.slate200),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Step Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate800 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: item.isActive
                        ? AppColors.primaryAmber.withValues(alpha: 0.6)
                        : (item.isCompleted
                            ? AppColors.safeGreen.withValues(alpha: 0.4)
                            : (isDark ? AppColors.slate700 : AppColors.slate200)),
                    width: item.isActive ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Main Rung Summary
                    InkWell(
                      onTap: () {
                        if (item.isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('পূর্ববর্তী লেভেল সম্পন্ন করে এই ধাপ আনলক করুন।')),
                          );
                          return;
                        }
                        setState(() {
                          _expandedModuleNumber = isExpanded ? null : item.moduleNumber;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: nodeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ধাপ ${item.moduleNumber}: ${item.badgeName}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: nodeColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (item.isLocked)
                                  const Text('লক করা 🔒', style: TextStyle(fontSize: 11, color: Colors.grey))
                                else
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: item.totalLessons > 0 ? (item.completedLessons / item.totalLessons) : 0,
                                      minHeight: 5,
                                      backgroundColor: isDark ? AppColors.slate700 : AppColors.slate100,
                                      valueColor: AlwaysStoppedAnimation<Color>(nodeColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${item.completedLessons}/${item.totalLessons} পাঠ',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded Lessons from Supabase
                    if (isExpanded) ...[
                      const Divider(height: 1),
                      _buildModuleLessonsList(item.moduleNumber, isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleLessonsList(int moduleNumber, bool isDark) {
    final lessonsAsync = ref.watch(moduleLessonsProvider(moduleNumber));

    return lessonsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('পাঠ লোড ব্যর্থ: $e', style: const TextStyle(fontSize: 12, color: Colors.red)),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('এই অধ্যায়ে কোনো সক্রিয় পাঠ পাওয়া যায়নি।', style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: lessons.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final lesson = lessons[idx];
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: lesson.isCompleted
                    ? AppColors.safeGreen
                    : AppColors.primaryAmber.withValues(alpha: 0.2),
                child: lesson.isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        '${lesson.chapterNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryAmber,
                        ),
                      ),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'পাঠ ${lesson.moduleNumber}.${lesson.chapterNumber} • +২০ পয়েন্ট',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => LessonDetailSheet(lesson: lesson),
                );
              },
            );
          },
        );
      },
    );
  }
}

