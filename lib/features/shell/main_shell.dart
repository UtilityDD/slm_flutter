import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../emergency/emergency_directory_screen.dart';
import '../home/home_screen.dart';
import '../identify/identify_screen.dart';
import '../more/more_screen.dart';
import '../quizzes/identify_quiz_screen.dart';
import '../rank/rank_screen.dart';
import '../sops/sops_screen.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import '../design_preview/motion_showcase.dart';
import '../design_preview/premium_rank_preview.dart';
import 'app_routes.dart';
import 'shell_insets.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _navKey = GlobalKey<NavigatorState>();
  final _heroController = MaterialApp.createMaterialHeroController();

  @override
  Widget build(BuildContext context) {
    final dockInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ShellDockScope(
              bottomInset: dockInset,
              // Route Android system back into the nested navigator so pages
              // pop (and their PopScope confirms run) instead of the app exiting.
              child: NavigatorPopHandler<Object?>(
                onPopWithResult: (result) => _navKey.currentState?.maybePop(result),
                child: Navigator(
                  key: _navKey,
                  initialRoute: AppRoutes.home,
                  onGenerateRoute: _onGenerateRoute,
                  observers: [_heroController],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.home => const HomeScreen(),
      AppRoutes.ppe => const SopsScreen(initialIndex: 0, title: 'আমার পিপিই'),
      AppRoutes.identifyPlay => const IdentifyQuizScreen(),
      AppRoutes.identify => const IdentifyScreen(),
      AppRoutes.rank => const RankScreen(),
      AppRoutes.more => const MoreScreen(),
      AppRoutes.emergency => const EmergencyDirectoryScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.admin => const AdminScreen(),
      // Dev-only previews never open in a release build.
      AppRoutes.premiumPreview when kDebugMode => const PremiumRankPreview(),
      AppRoutes.motionShowcase when kDebugMode => const MotionShowcase(),
      _ => const HomeScreen(),
    };

    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
