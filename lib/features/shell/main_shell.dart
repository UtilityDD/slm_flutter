import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../emergency/emergency_directory_screen.dart';
import '../home/home_screen.dart';
import '../identify/identify_screen.dart';
import '../life_skill/life_skill_screen.dart';
import '../more/more_screen.dart';
import '../quizzes/identify_quiz_screen.dart';
import '../quizzes/quiz_hub_screen.dart';
import '../quizzes/quiz_play_screen.dart';
import '../radio/radio_mini_player.dart';
import '../radio/radio_player_provider.dart';
import '../rank/rank_screen.dart';
import '../sops/sops_screen.dart';
import '../training/training_screen.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import 'app_routes.dart';
import 'shell_insets.dart';
import 'shell_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final tab = ref.watch(shellTabProvider);
    final radioOn = ref.watch(radioProvider).isVisible;
    final dockInset = ShellDockMetrics.compute(context, radioVisible: radioOn);

    // Overlay dock (not Scaffold.bottomNavigationBar) so the notch stays
    // truly transparent. Pages clear it via [ShellDockScope] padding — never
    // a SafeArea/Scaffold-colored slab behind the bar.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShellDockScope(
            bottomInset: dockInset,
            child: Navigator(
              key: _navKey,
              initialRoute: AppRoutes.home,
              onGenerateRoute: _onGenerateRoute,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RadioMiniPlayer(),
                _BottomNav(
                  index: tab,
                  bn: bn,
                  onSelect: (index) {
                    _navKey.currentState?.popUntil((route) => route.isFirst);
                    ref.read(shellTabProvider.notifier).select(index);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.home => const _TabHost(),
      AppRoutes.training => const TrainingScreen(),
      AppRoutes.mantra => const SopsScreen(initialIndex: 1, title: '8 মন্ত্র'),
      AppRoutes.ppe => const SopsScreen(initialIndex: 0, title: 'আমার পিপিই'),
      AppRoutes.quiz => const QuizHubScreen(),
      AppRoutes.hourly => const QuizPlayScreen(),
      AppRoutes.identifyPlay => const IdentifyQuizScreen(),
      AppRoutes.more => const MoreScreen(),
      AppRoutes.emergency => const EmergencyDirectoryScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.admin => const AdminScreen(),
      _ => const _TabHost(),
    };

    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}

class _TabHost extends ConsumerWidget {
  const _TabHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    return IndexedStack(
      index: tab,
      children: const [
        HomeScreen(),
        IdentifyScreen(),
        RankScreen(),
        LifeSkillScreen(),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final bool bn;
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.index,
    required this.bn,
    required this.onSelect,
  });

  static const _barH = ShellDockMetrics.barH;
  static const _notchR = 30.0;
  static const _rise = ShellDockMetrics.rise;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, tr(bn, 'হোম', 'Home')),
      (Icons.visibility_rounded, Icons.visibility_outlined, tr(bn, 'পরিচিতি', 'Identify')),
      (Icons.emoji_events_rounded, Icons.emoji_events_outlined, tr(bn, 'র‍্যাঙ্ক', 'Rank')),
      (Icons.star_rounded, Icons.star_outline_rounded, tr(bn, 'লাইফ স্কিল', 'Life Skill')),
    ];
    const move = Duration(milliseconds: 340);
    const curve = Curves.easeOutCubic;

    // Only the bar band is laid out; notch/bubble overflow over the page.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: ShellDockMetrics.bottomGap),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        child: SizedBox(
          height: _barH,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final slot = w / items.length;
              final notchCx = slot * index + slot / 2;
              final bubble = (_notchR - 3) * 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 2,
                    height: _barH - 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _barH + _rise,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: notchCx),
                      duration: move,
                      curve: curve,
                      builder: (context, cx, _) {
                        return CustomPaint(
                          painter: _NotchedDockPainter(notchCenterX: cx, notchRadius: _notchR),
                        );
                      },
                    ),
                  ),
                  AnimatedPositioned(
                    duration: move,
                    curve: curve,
                    left: notchCx - bubble / 2,
                    top: -_rise + 4,
                    width: bubble,
                    height: bubble,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          items[index].$1,
                          size: 24,
                          color: const Color(0xFFFEF3C7),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavItem(
                              selected: index == i,
                              icon: items[i].$2,
                              label: items[i].$3,
                              onTap: () => onSelect(i),
                              hideIcon: index == i,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Floating dock with a perfect circular notch cut from the top edge.
/// Uses path difference so side tabs stay as clean as the middle ones.
class _NotchedDockPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;

  const _NotchedDockPainter({
    required this.notchCenterX,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rise = _BottomNav._rise;
    const corner = 26.0;
    final barTop = rise;
    final cx = notchCenterX;

    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, barTop, size.width, size.height),
          const Radius.circular(corner),
        ),
      );

    // Circle centered on the top edge → clean semicircle bite on every tab,
    // including the first and last (no cubic/corner clash).
    final cut = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, barTop), radius: notchRadius));

    final path = Path.combine(PathOperation.difference, bar, cut);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF165E5A), Color(0xFF0F3D39)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x66F59E0B);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _NotchedDockPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX || oldDelegate.notchRadius != notchRadius;
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hideIcon;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hideIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    const idle = Color(0xFF8FA9A4);
    const duration = Duration(milliseconds: 220);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 26,
            child: hideIcon
                ? const SizedBox.shrink()
                : Icon(icon, size: 22, color: idle),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontFamily: banglaFont,
                fontSize: 10.5,
                height: 1.15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFFFEF3C7) : idle,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
