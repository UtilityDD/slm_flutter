import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../shell/shell_providers.dart';
import 'league_board.dart';
import 'league_service.dart';

/// Settings/profile part of the league: the member's "মাসের সেরা লাইনম্যান"
/// badges and the switch that hides the name on the board.
class LeagueProfileSection extends ConsumerWidget {
  const LeagueProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final wins = ref.watch(myLeagueWinsProvider).value ?? const <LeagueWin>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in wins.take(6)) ...[
          LeagueWinBadge(win: w, bn: bn),
          const SizedBox(height: SlmSpace.xs),
        ],
        const LeagueNameSwitch(),
      ],
    );
  }
}

/// "মাসের সেরা লাইনম্যান · অক্টোবর 2026" with the place and scope.
class LeagueWinBadge extends StatelessWidget {
  const LeagueWinBadge({super.key, required this.win, required this.bn});

  final LeagueWin win;
  final bool bn;

  @override
  Widget build(BuildContext context) {
    final month = leagueMonthLabel(win.year, win.month, bn: bn);
    final scope = win.state
        ? tr(bn, 'সারা রাজ্যে', 'State-wide')
        : (win.district?.trim().isNotEmpty ?? false)
            ? win.district!.trim()
            : tr(bn, 'জেলায়', 'District');
    return SlmCard(
      variant: SlmCardVariant.gold,
      radius: SlmRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: SlmSpace.sm),
      child: Row(
        children: [
          SlmRankDisc(rank: win.place, size: 36),
          const SizedBox(width: SlmSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlmText(
                  tr(bn, 'মাসের সেরা লাইনম্যান · $month', 'Lineman of the month · $month'),
                  role: SlmTextRole.titleSm,
                  color: SlmColors.ivory,
                  maxLines: 2,
                ),
                SlmText(
                  tr(bn, '$scope · স্থান ${win.place}', '$scope · place ${win.place}'),
                  role: SlmTextRole.caption,
                  color: SlmColors.gold300,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const Icon(Icons.workspace_premium_rounded, color: SlmColors.gold300),
        ],
      ),
    );
  }
}

/// "বোর্ডে আমার নাম দেখান": off shows "লাইনম্যান #1234" instead of the name.
class LeagueNameSwitch extends ConsumerStatefulWidget {
  const LeagueNameSwitch({super.key});

  @override
  ConsumerState<LeagueNameSwitch> createState() => _LeagueNameSwitchState();
}

class _LeagueNameSwitchState extends ConsumerState<LeagueNameSwitch> {
  bool _saving = false;

  Future<void> _set(bool value) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null || profile.isGuest || _saving) return;
    setState(() => _saving = true);
    // slm_app.set_league_show_name (supabase/slm_app_10_league.sql).
    final ok = await ref.read(leagueShowNameProvider.notifier).set(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      final bn = ref.read(languageProvider);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(tr(bn, 'সেভ হয়নি। আবার চেষ্টা করুন।', 'Could not save. Try again.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final profile = ref.watch(authProvider).profile;
    if (profile == null || profile.isGuest) return const SizedBox.shrink();
    final masked = leagueMaskedName(slmId: profile.slmId, id: profile.id);
    final showName = ref.watch(leagueShowNameProvider);
    return SlmCard(
      variant: SlmCardVariant.sunken,
      radius: SlmRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: SlmSpace.xxs),
      // Own Material: a ListTile inside the card's coloured box asserts otherwise.
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          tr(bn, 'বোর্ডে আমার নাম দেখান', 'Show my name on the board'),
          style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.ivory),
        ),
        subtitle: Text(
          tr(bn, 'বন্ধ থাকলে দেখাবে: $masked', 'When off, the board shows: $masked'),
          style: bangla(fontSize: 12.5, fontWeight: FontWeight.w500, color: SlmColors.mist, height: 1.35),
        ),
        value: showName.value ?? true,
        activeThumbColor: SlmColors.gold300,
        activeTrackColor: SlmColors.gold700,
        onChanged: _saving || showName.isLoading ? null : _set,
        ),
      ),
    );
  }
}
