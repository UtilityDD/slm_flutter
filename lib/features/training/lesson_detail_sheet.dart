import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import 'training_models.dart';
import 'training_provider.dart';

class LessonDetailSheet extends ConsumerStatefulWidget {
  final LessonCardItem lesson;

  const LessonDetailSheet({
    super.key,
    required this.lesson,
  });

  @override
  ConsumerState<LessonDetailSheet> createState() => _LessonDetailSheetState();
}

class _LessonDetailSheetState extends ConsumerState<LessonDetailSheet> {
  int _readingSeconds = 15;
  Timer? _timer;
  bool _canClaim = false;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.isCompleted) {
      _canClaim = true;
      _readingSeconds = 0;
    } else {
      _startReadingGate();
    }
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

  Future<void> _claimLessonPoints() async {
    if (!_canClaim || _isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    final authState = ref.read(authProvider);
    final userId = authState.isAuthenticated ? authState.profile?.id : null;

    if (userId != null && !widget.lesson.isCompleted) {
      try {
        // Record completed lesson in Supabase profiles
        final currentCompleted = List<String>.from(authState.profile?.completedLessons ?? []);
        final lessonKey = '_';
        
        if (!currentCompleted.contains(widget.lesson.id)) {
          currentCompleted.add(widget.lesson.id);
        }
        if (!currentCompleted.contains(lessonKey)) {
          currentCompleted.add(lessonKey);
        }

        final currentPoints = authState.profile?.points ?? 0;
        final newPoints = currentPoints + 20;

        await SupabaseService.client.from('profiles').update({
          'completed_lessons': currentCompleted,
          'points': newPoints,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);

        // Refresh providers
        ref.invalidate(trainingLadderProvider);
        ref.invalidate(moduleLessonsProvider(widget.lesson.moduleNumber));
        await ref.read(authProvider.notifier).refreshProfile();
      } catch (e) {
        debugPrint('Point claim fallback: ');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.lesson.isCompleted
                      ? 'রিভিশন সম্পন্ন! জ্ঞান আরও পোক্ত হলো।'
                      : 'অভিনন্দন ওস্তাদ! +২০ পয়েন্ট আপনার একাউন্টে যোগ হয়েছে।',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.safeGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showZoomImage(String imageUrl, String caption) {
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
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(30),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                      SizedBox(height: 8),
                      Text('পোস্টার লোড করা যায়নি', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryAmber, width: 1.5),
                  ),
                  child: Text(
                    '🪜 পাঠ .',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryAmber,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 28),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Body Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Lesson Title (Big Font)
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Mission Briefing (The Hook)
                if (lesson.missionBriefing != null && lesson.missionBriefing!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2563EB), width: 1.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 28),
                            SizedBox(width: 8),
                            Text(
                              '⚡ মাঠে নামার আগে (ওস্তাদের কথা):',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.missionBriefing!,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Actionable Points / Checklist
                if (lesson.points.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppColors.safetyOrange, size: 26),
                      SizedBox(width: 8),
                      Text(
                        '🛡️ সরঞ্জাম ও কাজের নিয়ম:',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...lesson.points.map((point) {
                    final imgUrl = point.fullImageUrl;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.slate700 : AppColors.slate300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Name Header (Big Font)
                          Text(
                            point.itemName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Poster Image if available
                          if (imgUrl != null) ...[
                            GestureDetector(
                              onTap: () => _showZoomImage(imgUrl, point.imageCaption ?? point.itemName),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 170,
                                  width: double.infinity,
                                  color: Colors.black12,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: imgUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (_, __, ___) => const Center(
                                          child: Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'বড় করে দেখুন',
                                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (point.imageCaption != null && point.imageCaption!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                point.imageCaption!,
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],

                          // A. Importance (বড় বিপদ / কেন জরুরি)
                          if (point.importance != null && point.importance!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.safetyOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.safetyOrange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'কেন অত্যন্ত জরুরি:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.safetyOrange,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          point.importance!,
                                          style: const TextStyle(fontSize: 15, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // B. Daily Check (হাত-চোখে পরীক্ষা)
                          if (point.dailyCheck != null && point.dailyCheck!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🔍', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'পোলে ওঠার আগে হাত-চোখে চেক:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          point.dailyCheck!,
                                          style: const TextStyle(fontSize: 15, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // C. Specifications (মাঠের নিয়ম / মান)
                          if (point.specifications != null && point.specifications!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.slate700 : AppColors.slate100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('📏', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'মাঠের নিয়ম ও মান:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          point.specifications!,
                                          style: const TextStyle(fontSize: 15, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],

                // 3. Pro Tips (ওস্তাদের পোড়খাওয়া টিপ)
                if (lesson.proTips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryAmber, width: 1.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: AppColors.primaryAmber, size: 28),
                            SizedBox(width: 8),
                            Text(
                              '💡 ওস্তাদের পোড়খাওয়া টিপ:',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryAmber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...lesson.proTips.map((tip) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('⚡ ', style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 4. Myth Buster (ভুল ধারণা vs আসল সত্যি)
                if (lesson.myths.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
                      SizedBox(width: 8),
                      Text(
                        '❌ ভুল ধারণা vs আসল সত্যি:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...lesson.myths.map((myth) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('❌ ', style: TextStyle(fontSize: 18)),
                              Expanded(
                                child: Text(
                                  myth.myth,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✅ ', style: TextStyle(fontSize: 18)),
                              Expanded(
                                child: Text(
                                  myth.reality,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.safeGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 60), // Room for bottom button
              ],
            ),
          ),

          // Bottom Action Bar (Big Button Gate)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canClaim ? _claimLessonPoints : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canClaim ? AppColors.safeGreen : AppColors.slate700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _canClaim ? 3 : 0,
                ),
                child: _isClaiming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _canClaim ? Icons.check_circle_rounded : Icons.timer_outlined,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _canClaim
                                ? (widget.lesson.isCompleted
                                    ? 'বুঝেছি (বন্ধ করুন)'
                                    : '✅ পুরোটা পড়েছি • ২০ পয়েন্ট নিন!')
                                : '⏱️ আর  সেকেন্ড মন দিয়ে পড়ুন...',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
