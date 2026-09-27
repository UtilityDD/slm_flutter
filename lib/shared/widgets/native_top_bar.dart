import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';

class NativeTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const NativeTopBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.electric_bolt_rounded,
              color: AppColors.primaryAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Points Pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryAmber.withValues(alpha: isDark ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryAmber.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppColors.primaryAmber,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${profile?.points ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryAmber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Avatar
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryAmber.withValues(alpha: 0.2),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primaryAmber,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

