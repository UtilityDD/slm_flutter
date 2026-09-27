import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/native_top_bar.dart';
import '../home/home_screen.dart';
import '../training/training_screen.dart';
import '../sops/sops_screen.dart';
import '../quizzes/quizzes_screen.dart';
import '../more/more_screen.dart';
import '../radio/radio_mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'স্মার্ট লাইনম্যান (Home)',
    'সুরক্ষা প্রশিক্ষণ (Training)',
    'এসওপি ও সরঞ্জাম (SOPs)',
    'কুইজ ও লিডারবোর্ড (Quizzes)',
    'জরুরি ও প্রোফাইল (More)',
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const TrainingScreen(),
      const SopsScreen(),
      const QuizzesScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      appBar: NativeTopBar(title: _titles[_currentIndex]),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          // Persistent Floating LifeSkill Radio Mini-Player
          const RadioMiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: isDark ? AppColors.slate900 : Colors.white,
        indicatorColor: AppColors.primaryAmber.withValues(alpha: 0.2),
        elevation: 4,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryAmber),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.primaryAmber),
            label: 'ট্রেনিং',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded, color: AppColors.primaryAmber),
            label: 'এসওপি',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded, color: AppColors.primaryAmber),
            label: 'কুইজ',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded, color: AppColors.primaryAmber),
            label: 'আরও',
          ),
        ],
      ),
    );
  }
}

