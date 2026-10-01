import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../../shared/widgets/slm_tiles.dart';
import '../auth/auth_provider.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _tips = [
    'লাইনে হাত দেওয়ার আগে শাটডাউন ও আর্থিং নিশ্চিত করুন। আগে জান, তারপর কাজ।',
    'ভেজা গ্লাভস বা ফাটা হেলমেট নিয়ে পোলে উঠবেন না। সন্দেহ হলে বদলান।',
    'কাজের আগে আট মন্ত্র একবার বলে নিন। তাড়াহুড়ো দুর্ঘটনা ডাকে।',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final profile = ref.watch(authProvider).profile;
    final name = profile?.displayName ?? tr(bn, 'লাইনম্যান ভাই', 'Lineman');
    final badge = profile?.badgeTitle ?? tr(bn, 'শিক্ষানবিস লাইনম্যান', 'New lineman');
    final points = profile?.points ?? 0;
    final tip = _tips[DateTime.now().day % _tips.length];
    final hour = _istHourLabel();

    return SlmBackdrop(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _Greeting(
              hello: tr(bn, 'নমস্কার', 'Hello'),
              name: name,
              badge: badge,
              points: points,
              onAvatar: () {
                final guest = ref.read(authProvider).isGuest || !ref.read(authProvider).isAuthenticated;
                Navigator.of(context).pushNamed(guest ? AppRoutes.login : AppRoutes.more);
              },
            ),
            const SizedBox(height: 10),
            _TipCard(
              text: tip,
              onTap: () => _openTip(context, tip),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Home3dTile(
                    label: tr(bn, 'কুইজ', 'Quiz'),
                    icon: Icons.schedule_rounded,
                    tone: TileTone.quiz,
                    chip: '+50',
                    live: true,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.quiz),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Home3dTile(
                    label: tr(bn, 'পাঠ', 'Learn'),
                    icon: Icons.menu_book_rounded,
                    tone: TileTone.learn,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.training),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Home3dTile(
                    label: tr(bn, '৮ মন্ত্র', '8 Mantra'),
                    icon: Icons.verified_user_rounded,
                    tone: TileTone.safe,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.mantra),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Home3dTile(
                    label: tr(bn, 'আরও', 'More'),
                    icon: Icons.grid_view_rounded,
                    tone: TileTone.folder,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.more),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(bn, 'এই ঘণ্টা $hour', 'This hour $hour'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0x61D6BDA4)),
            const SizedBox(height: 12),
            _ConnectRow(bn: bn),
          ],
        ),
      ),
    );
  }

  void _openTip(BuildContext context, String tip) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFEFB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'আজকের টিপ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Text(
                  tip,
                  style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('বন্ধ', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _istHourLabel() {
  final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  final hour12 = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
  final suffix = ist.hour >= 12 ? 'PM' : 'AM';
  return '$hour12$suffix';
}

class _Greeting extends StatelessWidget {
  final String hello;
  final String name;
  final String badge;
  final int points;
  final VoidCallback onAvatar;

  const _Greeting({
    required this.hello,
    required this.name,
    required this.badge,
    required this.points,
    required this.onAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$hello, ',
                      style: const TextStyle(
                        color: AppColors.hello,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    TextSpan(text: name),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·', style: TextStyle(color: Color(0xFFE7CBB8), fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFC2410C)),
                  const SizedBox(width: 2),
                  Text(
                    '$points',
                    style: const TextStyle(
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onAvatar,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE8D4),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFFF3D0B4), spreadRadius: 2),
                BoxShadow(color: Color(0x1FEA580C), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFFC2410C), size: 28),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TipCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3D5B8)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE6FFFFFF), Color(0x8CFFF4E8)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x12EA580C), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEA580C), Color(0xFFF59E0B), Color(0xFF38BDF8)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectRow extends ConsumerWidget {
  final bool bn;

  const _ConnectRow({required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _ConnectButton(
          color: const Color(0xFF3B6FD4),
          icon: Icons.facebook_rounded,
          label: tr(bn, 'ফেসবুক পেজ', 'Facebook Page'),
          onTap: () => _open('https://www.facebook.com/smartlineman'),
        ),
        const SizedBox(width: 6),
        _ConnectButton(
          color: const Color(0xFF2F9E5B),
          icon: Icons.chat_rounded,
          label: tr(bn, 'হোয়াটসঅ্যাপ গ্রুপ', 'WhatsApp Group'),
          onTap: () => _open('https://chat.whatsapp.com/Ljs2zuKTCX2K0oS16ga8wG?mode=gi_t'),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0x9EFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x6BD6BDA4)),
            ),
            child: Row(
              children: [
                _LangChip(
                  label: 'বাং',
                  selected: bn,
                  onTap: () => ref.read(languageProvider.notifier).setBengali(true),
                ),
                _LangChip(
                  label: 'EN',
                  selected: !bn,
                  onTap: () => ref.read(languageProvider.notifier).setBengali(false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ConnectButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ConnectButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x9EFFFFFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x6BD6BDA4)),
          ),
          child: Icon(icon, color: color, size: 20, semanticLabel: label),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? AppColors.ink : AppColors.muted,
            ),
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
