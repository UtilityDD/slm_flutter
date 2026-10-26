import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'life_skill_listen_bar.dart';
import 'life_skill_models.dart';
import 'life_skill_reader_page.dart';

class LifeSkillScreen extends ConsumerWidget {
  const LifeSkillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final modules = ref.watch(lifeSkillModulesProvider);

    return SlmBackdrop(
      child: ShellSafeArea(
        child: modules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (rows) {
            return ListView(
              padding: shellScrollPadding(context, left: 16, top: 16, right: 16),
              children: [
                Text(
                  tr(bn, 'লাইফ স্কিল', 'Life Skill'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    bn,
                    'কাজের বাইরের দক্ষতা—শুনুন ও পড়ুন।',
                    'Skills beyond the pole—listen and read.',
                  ),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                for (final module in rows) ...[
                  _ModuleCard(
                    module: module,
                    bn: bn,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LifeSkillDetailPage(module: module)),
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
  final LifeSkillModule module;
  final bool bn;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.bn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = lifeSkillTone(module.category);

    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x40D6BDA4)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tone.soft, shape: BoxShape.circle),
                child: Icon(tone.icon, color: tone.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.code,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: tone.accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.title(bn),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                module.durationLabel(),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LifeSkillDetailPage extends ConsumerStatefulWidget {
  final LifeSkillModule module;

  const LifeSkillDetailPage({super.key, required this.module});

  @override
  ConsumerState<LifeSkillDetailPage> createState() => _LifeSkillDetailPageState();
}

class _LifeSkillDetailPageState extends ConsumerState<LifeSkillDetailPage> {
  LifeSkillManuscript? _manuscript;
  bool _loadingMs = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ms = await loadLifeSkillManuscript(widget.module.manuscriptAsset);
    if (!mounted) return;
    setState(() {
      _manuscript = ms;
      _loadingMs = false;
    });
  }

  Future<void> _openReader() async {
    HapticFeedback.selectionClick();
    var ms = _manuscript;
    if (ms == null) {
      setState(() => _loadingMs = true);
      ms = await loadLifeSkillManuscript(widget.module.manuscriptAsset);
      if (!mounted) return;
      setState(() {
        _manuscript = ms;
        _loadingMs = false;
      });
    }
    if (ms == null) {
      final asset = widget.module.manuscriptAsset ?? '(none)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              ref.read(languageProvider),
              'পাঠ খোলা যায়নি ($asset)',
              'Lesson could not open ($asset)',
            ),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LifeSkillReaderPage(module: widget.module, manuscript: ms!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final module = widget.module;
    final tone = lifeSkillTone(module.category);
    final audio = module.audioUrl(bn);
    final marks = module
        .highlights(bn)
        .split('·')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(module.code),
      ),
      body: ListView(
        padding: shellScrollPadding(context, left: 20, top: 8, right: 20, extraBottom: 20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tone.soft, Colors.white],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tone.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: tone.accent.withValues(alpha: 0.25)),
                  ),
                  child: Icon(tone.icon, color: tone.accent, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.durationLabel(),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: tone.accent),
                      ),
                      Text(
                        module.title(bn),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            module.description(bn),
            style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
          ),
          if (marks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mark in marks)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tone.soft,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: tone.accent.withValues(alpha: 0.22)),
                    ),
                    child: Text(mark, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: tone.accent)),
                  ),
              ],
            ),
          ],
          if (module.trusted(bn).isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              module.trusted(bn),
              style: const TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
          ],
          if (audio.isNotEmpty) ...[
            const SizedBox(height: 18),
            LifeSkillListenBar(audioUrl: audio, accent: tone.accent, bn: bn),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadingMs ? null : _openReader,
            style: FilledButton.styleFrom(
              backgroundColor: tone.accent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _loadingMs
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.menu_book_rounded),
            label: Text(
              tr(bn, 'পাঠ পড়ুন', 'Read the lesson'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
            ),
          ),
        ],
      ),
    );
  }
}
