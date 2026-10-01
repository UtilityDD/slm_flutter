import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/shell_providers.dart';

class LifeSkillModule {
  final String code;
  final String titleBn;
  final String titleEn;
  final String descriptionBn;
  final String descriptionEn;
  final String duration;

  const LifeSkillModule({
    required this.code,
    required this.titleBn,
    required this.titleEn,
    required this.descriptionBn,
    required this.descriptionEn,
    required this.duration,
  });

  factory LifeSkillModule.fromJson(Map<String, dynamic> json) {
    return LifeSkillModule(
      code: json['lesson_code']?.toString() ?? '',
      titleBn: json['title_bn']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      descriptionBn: json['description_bn']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
    );
  }
}

final lifeSkillModulesProvider = FutureProvider<List<LifeSkillModule>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/supplementary_modules.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((row) => LifeSkillModule.fromJson(row as Map<String, dynamic>)).toList();
});

class LifeSkillScreen extends ConsumerWidget {
  const LifeSkillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final modules = ref.watch(lifeSkillModulesProvider);

    return SlmBackdrop(
      child: SafeArea(
        bottom: false,
        child: modules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (rows) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  tr(bn, 'লাইফ স্কিল', 'Life Skill'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(bn, 'কাজের বাইরের দক্ষতা। পাঠক পরের ধাপে খুলবে।', 'Skills beyond the pole. The reader opens next.'),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                for (final module in rows) ...[
                  _ModuleCard(
                    code: module.code,
                    title: bn ? module.titleBn : module.titleEn,
                    duration: module.duration,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ModuleDetail(module: module),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String code;
  final String title;
  final String duration;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.code,
    required this.title,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x61D6BDA4)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFF047857)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ],
                ),
              ),
              Text(duration, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleDetail extends ConsumerWidget {
  final LifeSkillModule module;

  const _ModuleDetail({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(module.code),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bn ? module.titleBn : module.titleEn,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              module.duration,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              bn ? module.descriptionBn : module.descriptionEn,
              style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
