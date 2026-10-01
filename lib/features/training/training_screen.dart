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
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('সুরক্ষা সিঁড়ি'),
      ),
      body: ladderAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'সুরক্ষা সিঁড়ি সাজানো হচ্ছে...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.safetyOrange),
                const SizedBox(height: 12),
                Text(
                  'সিঁড়ি লোড করা যায়নি: ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        data: (modules) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Banner: Lineman Safety Ladder
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.stairs_rounded, color: Colors.amberAccent, size: 36),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🪜 পোলে ওঠার সুরক্ষা সিঁড়ি',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ধাপে ধাপে ১০টি সিঁড়ি পার করুন। সুরক্ষিত থাকুন এবং ওস্তাদ লাইনম্যানের শিরোপা জিতুন!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLadderRung(TrainingModuleItem item, bool isLast, bool isDark) {
    final isExpanded = _expandedModuleNumber == item.moduleNumber;

    Color rungColor;
    IconData rungIcon;
    String statusLabel;

    switch (item.status) {
      case LadderStepStatus.completed:
        rungColor = AppColors.safeGreen;
        rungIcon = Icons.check_circle_rounded;
        statusLabel = 'সম্পন্ন ✅';
        break;
      case LadderStepStatus.active:
        rungColor = AppColors.primaryAmber;
        rungIcon = Icons.bolt_rounded;
        statusLabel = 'চলতি সিঁড়ি ⚡';
        break;
      case LadderStepStatus.locked:
        rungColor = isDark ? Colors.white38 : AppColors.slate700;
        rungIcon = Icons.lock_rounded;
        statusLabel = 'তালাবন্ধ 🔒';
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Sturdy Ladder Rail & Node
          SizedBox(
            width: 58,
            child: Column(
              children: [
                // Step Node Circle (Big 52dp)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isActive
                        ? AppColors.primaryAmber.withValues(alpha: 0.2)
                        : (item.isCompleted
                            ? AppColors.safeGreen.withValues(alpha: 0.2)
                            : (isDark ? AppColors.slate800 : AppColors.slate100)),
                    border: Border.all(
                      color: rungColor,
                      width: item.isActive ? 3 : 2,
                    ),
                    boxShadow: item.isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primaryAmber.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      rungIcon,
                      color: rungColor,
                      size: 28,
                    ),
                  ),
                ),

                // Vertical Ladder Side-Rail
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? AppColors.safeGreen
                            : (isDark ? AppColors.slate700 : AppColors.slate300),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: Big Rung Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: item.isActive
                      ? AppColors.primaryAmber
                      : (item.isCompleted
                          ? AppColors.safeGreen.withValues(alpha: 0.6)
                          : (isDark ? AppColors.slate700 : AppColors.slate200)),
                  width: item.isActive ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Rung Header Bar (Tap Target)
                  InkWell(
                    onTap: () {
                      if (item.isLocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🔒 আগের সিঁড়ির পাঠগুলো শেষ করে এই ধাপে উঠুন।',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: AppColors.slate900,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _expandedModuleNumber = isExpanded ? null : item.moduleNumber;
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rungColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'সিঁড়ি : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: rungColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.slate700 : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: rungColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Rung Title (Big Font)
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Progress Bar & Lesson Count
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: item.totalLessons > 0
                                        ? (item.completedLessons / item.totalLessons)
                                        : 0,
                                    minHeight: 8,
                                    backgroundColor: isDark ? AppColors.slate700 : AppColors.slate100,
                                    valueColor: AlwaysStoppedAnimation<Color>(rungColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '/ পাঠ সম্পন্ন',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          // Bottom Expand Prompt
                          if (!item.isLocked) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  isExpanded ? 'পাঠ লুকান ▲' : 'পাঠগুলো দেখুন ▼',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: rungColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Expanded Lessons List
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
    );
  }

  Widget _buildModuleLessonsList(int moduleNumber, bool isDark) {
    final lessonsAsync = ref.watch(moduleLessonsProvider(moduleNumber));

    return lessonsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 8),
              Text('পাঠগুলো সাজানো হচ্ছে...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('পাঠ লোড ব্যর্থ: ', style: const TextStyle(fontSize: 13, color: Colors.red)),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'এই ধাপে কোনো সক্রিয় পাঠ পাওয়া যায়নি।',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: lessons.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final lesson = lessons[idx];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => LessonDetailSheet(lesson: lesson),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Row(
                    children: [
                      // Large Lesson Number Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lesson.isCompleted
                              ? AppColors.safeGreen
                              : AppColors.primaryAmber.withValues(alpha: 0.2),
                          border: Border.all(
                            color: lesson.isCompleted ? AppColors.safeGreen : AppColors.primaryAmber,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: lesson.isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                              : Text(
                                  '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryAmber,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  'পাঠ .',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white60 : AppColors.slate700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.safeGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '+২০ পয়েন্ট 🪙',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.safeGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Large Tap Action Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: lesson.isCompleted
                              ? AppColors.safeGreen.withValues(alpha: 0.12)
                              : AppColors.primaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lesson.isCompleted ? 'রিভিশন ↻' : 'পড়ুন 👉',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: lesson.isCompleted ? AppColors.safeGreen : AppColors.primaryAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
