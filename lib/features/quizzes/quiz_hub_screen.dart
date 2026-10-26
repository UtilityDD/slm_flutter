import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../identify/library_catalog.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final stats = ref.watch(identifyStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(tr(bn, 'কুইজ', 'Quiz')),
      ),
      body: SlmBackdrop(
        child: ShellSafeArea(
          top: false,
          child: Padding(
            padding: shellScrollPadding(context, left: 16, top: 4, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HourMatchCard(
                    bn: bn,
                    hour: _istHourLabel(),
                    onPlay: () => Navigator.of(context).pushNamed(AppRoutes.hourly),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _IdentifyMatchCard(
                    bn: bn,
                    percent: stats.percent,
                    total: stats.lifeTotal,
                    onPlay: () => Navigator.of(context).pushNamed(AppRoutes.identifyPlay),
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

class _HourMatchCard extends StatelessWidget {
  final bool bn;
  final String hour;
  final VoidCallback onPlay;

  const _HourMatchCard({
    required this.bn,
    required this.hour,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF97316), Color(0xFFC2410C)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x40EA580C), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                tr(bn, 'পয়েন্টের খেলা', 'Points game'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              Text(
                hour,
                style: const TextStyle(color: Color(0xFFFFEDD5), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Text(
            tr(bn, 'ঘণ্টার কুইজ', 'Hourly quiz'),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, height: 1.2),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF9A3412),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onPlay,
              child: Text(tr(bn, 'এখন খেলুন', 'Play now'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentifyMatchCard extends StatelessWidget {
  final bool bn;
  final int percent;
  final int total;
  final VoidCallback onPlay;

  const _IdentifyMatchCard({
    required this.bn,
    required this.percent,
    required this.total,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF99F6E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x140F766E), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(bn, 'অনুশীলন', 'Practice'),
            style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          Text(
            tr(bn, 'পরিচিতি কুইজ', 'Identify quiz'),
            style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w600, height: 1.2),
          ),
          if (total > 0) ...[
            const SizedBox(height: 6),
            Text(
              tr(bn, 'স্কোর $percent%', 'Score $percent%'),
              style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onPlay,
              child: Text(tr(bn, 'শুরু করুন', 'Start'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

String _istHourLabel() {
  final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  final hour12 = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
  final suffix = ist.hour >= 12 ? 'PM' : 'AM';
  return '$hour12$suffix';
}
