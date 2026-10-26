import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../auth/auth_provider.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import '../training/training_provider.dart';
import '../duty_slip/duty_slip_page.dart';
import 'hero_card_carousel.dart';
import 'lesson_progress_store.dart';
import 'lineman_progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final localDone = ref.watch(allCompletedLessonsProvider);
    final ladder = ref.watch(trainingLadderProvider).value;
    var highestDone = 0;
    if (ladder != null) {
      for (final m in ladder) {
        if (!m.isCompleted) break;
        highestDone = m.moduleNumber;
      }
    }
    final path = linemanPath(
      profile,
      extraCompleted: localDone,
      highestCompletedModule: highestDone > 0 ? highestDone : null,
    );
    final guest = auth.isGuest || !auth.isAuthenticated;
    final fullName = profile?.fullName?.trim() ?? '';
    final slmId = profile?.slmId?.trim() ?? '';
    final guestLabel = tr(bn, 'অতিথি', 'Guest');
    final name = guest
        ? guestLabel
        : (fullName.isNotEmpty ? fullName : (slmId.isNotEmpty ? slmId : guestLabel));

    return SlmBackdrop(
      child: ShellSafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _Header(
                bn: bn,
                name: name,
                onName: () => Navigator.of(context).pushNamed(guest ? AppRoutes.login : AppRoutes.more),
                onLanguage: (value) => ref.read(languageProvider.notifier).setBengali(value),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: shellDockBottomInset(context) + 68),
                    child: HeroCardCarousel(path: path, bn: bn),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: shellDockBottomOffset(context, 14),
                    child: Center(
                      child: _PathPlayChip(
                        label: tr(bn, 'মৃত্যুহীন পথ', 'Mrityuhin Path'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          DutySlipPage.open(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathPlayChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PathPlayChip({required this.label, required this.onTap});

  @override
  State<_PathPlayChip> createState() => _PathPlayChipState();
}

class _PathPlayChipState extends State<_PathPlayChip> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final lift = _pressed ? 0.0 : _glow.value;
          return Transform.translate(
            offset: Offset(0, _pressed ? 2 : 0),
            child: Transform.scale(
              scale: _pressed ? 0.98 : 1 + lift * 0.025,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFEA580C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE08A1E).withValues(alpha: 0.28 + lift * 0.22),
                      offset: Offset(0, _pressed ? 2 : 8),
                      blurRadius: _pressed ? 6 : 16 + lift * 6,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 18, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool bn;
  final String name;
  final VoidCallback onName;
  final ValueChanged<bool> onLanguage;

  const _Header({
    required this.bn,
    required this.name,
    required this.onName,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onName,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2, color: AppColors.ink),
            ),
          ),
        ),
        _LangPill(bn: bn, onLanguage: onLanguage),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  final bool bn;
  final ValueChanged<bool> onLanguage;

  const _LangPill({required this.bn, required this.onLanguage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EA),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE7D5C6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangSeg(label: 'বাং', selected: bn, onTap: () => onLanguage(true)),
          _LangSeg(label: 'EN', selected: !bn, onTap: () => onLanguage(false)),
        ],
      ),
    );
  }
}

class _LangSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangSeg({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

void copyInvite(BuildContext context, bool bn) {
  final text = bn
      ? 'স্মার্টলাইনম্যান — খেলতে খেলতে শিখুন, পুরস্কার জিতুন। ${AppConfig.websiteUrl}'
      : 'SmartLineman — learn while you play, win prizes. ${AppConfig.websiteUrl}';
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr(bn, 'আমন্ত্রণ কপি হয়েছে', 'Invite copied'))),
  );
}
