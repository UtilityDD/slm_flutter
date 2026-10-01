import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../emergency/emergency_directory_screen.dart';
import '../home/home_screen.dart';
import '../identify/identify_screen.dart';
import '../life_skill/life_skill_screen.dart';
import '../more/more_screen.dart';
import '../quizzes/identify_quiz_screen.dart';
import '../quizzes/quiz_hub_screen.dart';
import '../quizzes/quiz_play_screen.dart';
import '../radio/radio_mini_player.dart';
import '../rank/rank_screen.dart';
import '../sops/sops_screen.dart';
import '../training/training_screen.dart';
import '../auth/login_screen.dart';
import 'app_routes.dart';
import 'feature_page.dart';
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Expanded(
            child: Navigator(
              key: _navKey,
              initialRoute: AppRoutes.home,
              onGenerateRoute: _onGenerateRoute,
            ),
          ),
          const RadioMiniPlayer(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: tab,
        bn: bn,
        onSelect: (index) {
          _navKey.currentState?.popUntil((route) => route.isFirst);
          ref.read(shellTabProvider.notifier).select(index);
        },
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.home => const _TabHost(),
      AppRoutes.training => const TrainingScreen(),
      AppRoutes.mantra => const SopsScreen(initialIndex: 1, title: '৮ মন্ত্র'),
      AppRoutes.ppe => const SopsScreen(initialIndex: 0, title: 'আমার পিপিই'),
      AppRoutes.quiz => const QuizHubScreen(),
      AppRoutes.hourly => const QuizPlayScreen(),
      AppRoutes.identifyPlay => const IdentifyQuizScreen(),
      AppRoutes.more => const MoreScreen(),
      AppRoutes.emergency => const EmergencyDirectoryScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.story => const FeaturePage(
          titleBn: 'আমাদের কথা',
          titleEn: 'Our Story',
          noteBn: 'গল্পের পাতা পরের ধাপে ওয়েবের মতো খুলবে।',
          noteEn: 'The story page will match the web in the next step.',
          icon: Icons.groups_rounded,
        ),
      AppRoutes.prizes => const FeaturePage(
          titleBn: 'পুরস্কার',
          titleEn: 'Prizes',
          noteBn: 'পুরস্কার গ্যালারি পরের ধাপে।',
          noteEn: 'The prize gallery comes in the next step.',
          icon: Icons.card_giftcard_rounded,
          tint: Color(0xFFB45309),
        ),
      AppRoutes.guide => const FeaturePage(
          titleBn: 'অ্যাপ গাইড',
          titleEn: 'App guide',
          noteBn: 'ছোট ভিডিও গাইড পরের ধাপে।',
          noteEn: 'Short app-guide videos come next.',
          icon: Icons.smartphone_rounded,
          tint: Color(0xFF334155),
        ),
      AppRoutes.progress => const FeaturePage(
          titleBn: 'আমার অগ্রগতি',
          titleEn: 'My Progress',
          noteBn: 'পয়েন্ট ও পড়ার হিসাব পরের ধাপে।',
          noteEn: 'Points and reading history come next.',
          icon: Icons.insights_rounded,
          tint: Color(0xFF0F766E),
        ),
      AppRoutes.faq => const FeaturePage(
          titleBn: 'জিজ্ঞাসা',
          titleEn: 'FAQ',
          noteBn: 'প্রশ্নোত্তর তালিকা পরের ধাপে।',
          noteEn: 'The FAQ list comes next.',
          icon: Icons.help_rounded,
        ),
      AppRoutes.knowMore => const FeaturePage(
          titleBn: 'আরো জানুন',
          titleEn: 'Know More',
          noteBn: 'অতিরিক্ত জানার পাতা পরের ধাপে।',
          noteEn: 'The know-more page comes next.',
          icon: Icons.lightbulb_rounded,
          tint: Color(0xFF3F6212),
        ),
      AppRoutes.video => const FeaturePage(
          titleBn: 'ভিডিও গাইড',
          titleEn: 'Video Guide',
          noteBn: 'ভিডিও তালিকা পরের ধাপে।',
          noteEn: 'The video list comes next.',
          icon: Icons.smart_display_rounded,
          tint: Color(0xFFA21CAF),
        ),
      AppRoutes.tools => const FeaturePage(
          titleBn: 'আমার সরঞ্জাম',
          titleEn: 'My Tools',
          noteBn: 'সরঞ্জামের তালিকা পরের ধাপে।',
          noteEn: 'The tool catalog comes next.',
          icon: Icons.handyman_rounded,
          tint: Color(0xFF44403C),
        ),
      AppRoutes.tales => const FeaturePage(
          titleBn: 'করুণ কাহিনী',
          titleEn: 'Tragic Stories',
          noteBn: 'মাঠের কাহিনী পরের ধাপে।',
          noteEn: 'Field stories come next.',
          icon: Icons.favorite_rounded,
          tint: Color(0xFF9F1239),
        ),
      AppRoutes.notices => const FeaturePage(
          titleBn: 'বিজ্ঞপ্তি',
          titleEn: 'Notifications',
          noteBn: 'বিজ্ঞপ্তির তালিকা পরের ধাপে।',
          noteEn: 'The notice list comes next.',
          icon: Icons.notifications_rounded,
          tint: Color(0xFF3730A3),
        ),
      AppRoutes.forum => const FeaturePage(
          titleBn: 'প্রশ্নোত্তর',
          titleEn: 'Forum',
          noteBn: 'ফোরাম পরের ধাপে।',
          noteEn: 'The forum comes next.',
          icon: Icons.forum_rounded,
          tint: Color(0xFF0E7490),
        ),
      _ => const FeaturePage(
          titleBn: 'স্মার্ট লাইনম্যান',
          titleEn: 'Smart Lineman',
          noteBn: 'এই পাতা এখনও খোলা হয়নি।',
          noteEn: 'This page is not open yet.',
          icon: Icons.electric_bolt_rounded,
        ),
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

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, tr(bn, 'হোম', 'Home')),
      (Icons.visibility_rounded, Icons.visibility_outlined, tr(bn, 'পরিচিতি', 'Identify')),
      (Icons.emoji_events_rounded, Icons.emoji_events_outlined, tr(bn, 'র‍্যাঙ্ক', 'Rank')),
      (Icons.star_rounded, Icons.star_outline_rounded, tr(bn, 'লাইফ স্কিল', 'Life Skill')),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF0FFFDF7),
        border: Border(top: BorderSide(color: Color(0xD9E2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x0D0F172A), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    selected: index == i,
                    icon: index == i ? items[i].$1 : items[i].$2,
                    label: items[i].$3,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navActive : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: selected
                  ? const LinearGradient(colors: [Color(0xFFFED7AA), Color(0xFFFDBA74)])
                  : null,
            ),
            child: Icon(icon, size: 22, color: selected ? const Color(0xFF7C2D12) : color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
