import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/shell_providers.dart';

class FeaturePage extends ConsumerWidget {
  final String titleBn;
  final String titleEn;
  final String noteBn;
  final String noteEn;
  final IconData icon;
  final Color tint;

  const FeaturePage({
    super.key,
    required this.titleBn,
    required this.titleEn,
    required this.noteBn,
    required this.noteEn,
    required this.icon,
    this.tint = const Color(0xFFEA580C),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(tr(bn, titleBn, titleEn)),
      ),
      body: SlmBackdrop(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 40),
              ),
              const SizedBox(height: 18),
              Text(
                tr(bn, titleBn, titleEn),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                tr(bn, noteBn, noteEn),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15.5, height: 1.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
