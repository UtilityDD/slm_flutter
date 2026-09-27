import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'radio_player_provider.dart';

class RadioMiniPlayer extends ConsumerWidget {
  const RadioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(radioProvider);

    if (!radioState.isVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: radioState.isPlaying
              ? AppColors.primaryAmber.withValues(alpha: 0.6)
              : (isDark ? AppColors.slate700 : AppColors.slate200),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Radio Icon / Equalizer Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: radioState.isPlaying
                    ? [AppColors.primaryAmber, AppColors.safetyOrange]
                    : [AppColors.slate700, AppColors.slate800],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              radioState.isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  radioState.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  radioState.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.slate200 : AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),

          // Play / Pause Button
          IconButton(
            onPressed: () {
              ref.read(radioProvider.notifier).togglePlay();
            },
            icon: Icon(
              radioState.isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              size: 32,
              color: AppColors.primaryAmber,
            ),
          ),

          // Close Button
          IconButton(
            onPressed: () {
              ref.read(radioProvider.notifier).closePlayer();
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

