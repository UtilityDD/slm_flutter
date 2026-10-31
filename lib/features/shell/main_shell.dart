import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
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
import '../design_preview/motion_showcase.dart';
import '../design_preview/premium_rank_preview.dart';
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
    // Dark status icons for the cream tabs; Home's navy backdrop overrides it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
      AppRoutes.premiumPreview => const PremiumRankPreview(),
      AppRoutes.motionShowcase => const MotionShowcase(),
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
                            color: SlmColors.navy950.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: SlmColors.emerald600.withValues(alpha: 0.18),
                            blurRadius: 18,
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
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SlmGradients.gold,
                        boxShadow: [
                          BoxShadow(
                            color: SlmColors.navy950.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: SlmColors.gold400.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.3, -0.45),
                            radius: 0.95,
                            colors: [SlmColors.emerald500, SlmColors.emerald700, SlmColors.emerald900],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: SlmMotion.base,
                            switchInCurve: SlmMotion.emphasized,
                            transitionBuilder: (child, t) => ScaleTransition(
                              scale: Tween(begin: 0.6, end: 1.0).animate(t),
                              child: FadeTransition(opacity: t, child: child),
                            ),
                            child: Icon(
                              items[index].$1,
                              key: ValueKey(index),
                              size: 24,
                              color: SlmColors.gold100,
                            ),
                          ),
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

    final bounds = Rect.fromLTWH(0, barTop, size.width, size.height - barTop);
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B5C49), SlmColors.emerald900, Color(0xFF042A21)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bounds);
    canvas.drawPath(path, fill);

    // Top gloss, kept inside the dock outline.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, barTop, size.width, bounds.height * 0.45),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
        ).createShader(Rect.fromLTWH(0, barTop, size.width, bounds.height * 0.45)),
    );
    canvas.restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          SlmColors.gold300.withValues(alpha: 0.8),
          SlmColors.gold600.withValues(alpha: 0.35),
        ],
      ).createShader(bounds);
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
    const idle = Color(0xFFA9C7BE);
    const duration = Duration(milliseconds: 220);

    return SlmTactile(
      semanticLabel: label,
      onTap: onTap,
      builder: (context, press, child) => Transform.scale(
        scale: 1 - 0.08 * press,
        child: child,
      ),
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
          AnimatedDefaultTextStyle(
            duration: duration,
            style: TextStyle(
              fontFamily: banglaFont,
              fontSize: 11,
              height: 1.15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? SlmColors.gold200 : idle,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
            ),
          ),
          SizedBox(
            height: 10,
            child: Center(
              child: AnimatedContainer(
                duration: SlmMotion.base,
                curve: SlmMotion.emphasized,
                width: selected ? 16 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: SlmGradients.gold,
                  borderRadius: SlmRadius.pillAll,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
