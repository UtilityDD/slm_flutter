import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'league_board.dart';
import 'league_service.dart';

/// Space the pinned standing card takes above the dock.
const _standingReserve = 132.0;

/// The three boards of the league.
enum LeagueTab { district, state, allTime }

/// "মাসিক লাইনম্যান লিগ" (docs/LEAGUE.md): verified linemen ranked by level
/// clears this month — in the member's district, state-wide — and by their
/// best stars ever. Guests and unverified members can look but never appear.
/// The first visit asks once whether to show the member's name.
class RankScreen extends ConsumerStatefulWidget {
  const RankScreen({super.key});

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen> {
  LeagueTab? _tab;

  /// The name question was shown in this visit (never twice).
  var _askedName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The Home "new month" chip stops once the board is opened this month.
      ref.read(leagueSeenMonthProvider.notifier).markSeen(leagueMonthKey(ref.read(leagueClockProvider)()));
      _maybeAskName();
    });
  }

  /// "বোর্ডে আপনার নাম দেখাবেন?" once, for a signed-in member (not an admin)
  /// whose my_league says it was never answered. The answer goes through
  /// set_league_show_name, which marks it answered on the server.
  Future<void> _maybeAskName() async {
    final auth = ref.read(authProvider);
    final p = auth.profile;
    if (_askedName || !auth.isAuthenticated || p == null || p.isGuest || auth.isAdmin) return;
    LeagueMe? me;
    try {
      me = await ref.read(myLeagueProvider.future);
    } catch (_) {}
    if (!mounted || me == null || me.nameAsked || _askedName) return;
    _askedName = true;
    final bn = ref.read(languageProvider);
    final masked = leagueMaskedName(slmId: p.slmId, id: p.id);
    final show = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NameQuestion(bn: bn, masked: masked),
    );
    if (show == null || !mounted) return;
    await ref.read(leagueShowNameProvider.notifier).set(show);
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final verified = auth.isAuthenticated && !auth.isAdmin && linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final district = auth.isAuthenticated ? (auth.profile?.district?.trim() ?? '') : '';
    final tabs = [if (district.isNotEmpty) LeagueTab.district, LeagueTab.state, LeagueTab.allTime];
    final tab = tabs.contains(_tab) ? _tab! : tabs.first;
    final query = (allTime: tab == LeagueTab.allTime, district: tab == LeagueTab.district);
    final board = ref.watch(leagueBoardProvider(query));
    final now = leagueNow();
    final month = leagueMonthLabel(now.year, now.month, bn: bn);
    final showStanding = verified && board.hasValue;

    String label(LeagueTab t) => switch (t) {
          LeagueTab.district => tr(bn, 'আমার জেলা', 'My district'),
          LeagueTab.state => tr(bn, 'সারা রাজ্য', 'State'),
          LeagueTab.allTime => tr(bn, 'সর্বকালের সেরা', 'All-time best'),
        };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Builder(
          builder: (context) {
            final g = context.slm.layout.gutter;
            return Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
                ShellSafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlmTopBar(
                        title: tr(bn, 'লাইনম্যান লিগ', 'Lineman league'),
                        subtitle: query.allTime
                            ? tr(bn, 'সব লেভেলের সেরা তারা · কখনও মোছে না', 'Best stars on every level · never resets')
                            : month,
                        onBack: () => Navigator.of(context).maybePop(),
                        backLabel: tr(bn, 'ফিরে যান', 'Back'),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(g, SlmSpace.xs, g, SlmSpace.sm),
                        child: SlmSegmented(
                          labels: [for (final t in tabs) label(t)],
                          selected: tabs.indexOf(tab),
                          onChanged: (i) => setState(() => _tab = tabs[i]),
                        ),
                      ),
                      Expanded(
                        child: _Board(
                          bn: bn,
                          board: board,
                          monthly: !query.allTime,
                          onRefresh: () => refreshLeagueBoard(ref, query),
                          banner: verified ? null : _JoinBanner(bn: bn),
                          padding: shellScrollPadding(
                            context,
                            left: g,
                            right: g,
                            top: 0,
                            extraBottom: showStanding ? _standingReserve + SlmSpace.md : SlmSpace.xl,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStanding)
                  Positioned(
                    left: g,
                    right: g,
                    bottom: shellDockBottomOffset(context, 10),
                    child: SlmReveal(
                      index: 3,
                      rise: 22,
                      child: _StandingCard(bn: bn, rows: board.value!, monthly: !query.allTime),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The member's own row shows the hidden-name form at once after the switch
/// is turned off (the saved board may still carry the name).
String _shownName(LeagueRow row, AuthState auth, {required bool showName}) {
  final p = auth.profile;
  if (row.isMe && p != null && !p.isGuest && !showName) {
    return leagueMaskedName(slmId: p.slmId, id: p.id);
  }
  return row.name;
}

class _Board extends ConsumerWidget {
  final bool bn;
  final AsyncValue<List<LeagueRow>> board;
  final Widget? banner;
  final EdgeInsets padding;

  /// This month's board (at least 3 levels to appear) or the all-time one.
  final bool monthly;

  /// Pull to refresh (at most once a minute per board).
  final Future<void> Function() onRefresh;

  const _Board({
    required this.bn,
    required this.board,
    required this.banner,
    required this.padding,
    required this.monthly,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: SlmColors.gold300,
      child: _list(context, ref),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final showName = ref.watch(leagueShowNameProvider).value ?? true;
    final head = [
      if (banner != null) ...[banner!, const SizedBox(height: SlmSpace.md)],
    ];
    return board.when(
      skipLoadingOnReload: true,
      loading: () => ListView(physics: const AlwaysScrollableScrollPhysics(), padding: padding, children: [...head, const _BoardSkeleton()]),
      error: (_, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          ...head,
          SlmEmptyState(
            icon: Icons.cloud_off_rounded,
            title: tr(bn, 'বোর্ড লোড হয়নি', 'Could not load the board'),
            message: tr(bn, 'ইন্টারনেট চালু করে আবার খুলুন।', 'Turn on the internet and open it again.'),
          ),
        ],
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            children: [
              ...head,
              SlmEmptyState(
                icon: Icons.emoji_events_rounded,
                title: tr(bn, 'এখনও কেউ নেই', 'No one here yet'),
                message: monthly
                    ? tr(bn, 'এই মাসে 3টি লেভেল পার করলেই বোর্ডে উঠবেন।', 'Clear 3 levels this month to get on the board.')
                    : tr(bn, 'লেভেল পার করলেই পয়েন্ট বোর্ডে উঠবে।', 'Clear a level to get on the board.'),
              ),
            ],
          );
        }
        final top = rows.where((r) => r.rank <= 3).toList();
        final rest = rows.where((r) => r.rank > 3).toList();
        final shown = rows.where((r) => r.rank <= 50).length;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            ...head,
            SlmReveal(index: 1, child: _Podium(top: top, nameOf: (r) => _shownName(r, auth, showName: showName))),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: SlmSpace.xl),
              SlmReveal(
                index: 2,
                child: SlmSectionHeader(
                  overline: tr(bn, 'লিডারবোর্ড', 'Leaderboard'),
                  title: tr(bn, 'সেরা $shown', 'Top $shown'),
                ),
              ),
              for (var i = 0; i < rest.length; i++) ...[
                // The member's own row, when below the top 50, comes after a gap.
                if (i > 0 && rest[i].rank > rest[i - 1].rank + 1)
                  const Padding(
                    padding: EdgeInsets.only(bottom: SlmSpace.xs),
                    child: Center(child: Icon(Icons.more_vert_rounded, color: SlmColors.mist)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: SlmSpace.xs),
                  child: SlmReveal(
                    index: 3 + (i < 8 ? i : 8),
                    child: _RankRow(row: rest[i], name: _shownName(rest[i], auth, showName: showName), bn: bn),
                  ),
                ),
              ],
            ],
            const SizedBox(height: SlmSpace.sm),
            SlmText(
              tr(bn, 'সমান পয়েন্ট হলে যিনি আগে পৌঁছেছেন তিনি আগে।', 'On equal points, whoever got there first is ahead.'),
              key: const ValueKey('league-tie-note'),
              role: SlmTextRole.caption,
              color: SlmColors.mist,
              align: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

/// Shown to guests and members not yet verified: they can look, not appear.
class _JoinBanner extends ConsumerWidget {
  final bool bn;

  const _JoinBanner({required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final String? status;
    if (!auth.isAuthenticated) {
      status = tr(bn, 'লগইন করে যাচাইয়ের জন্য আবেদন করুন।', 'Sign in and ask to be verified.');
    } else if (auth.isAdmin) {
      status = tr(bn, 'অ্যাডমিন অ্যাকাউন্ট বোর্ডে দেখায় না।', 'Admin accounts are not on the board.');
    } else {
      status = tr(bn, 'আপনার যাচাই: অপেক্ষমাণ', 'Your verification: pending');
    }
    return SlmCard(
      variant: SlmCardVariant.gold,
      radius: SlmRadius.md,
      onTap: auth.isAuthenticated && !auth.isAdmin ? () => showVerifySheet(context) : null,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: SlmSpace.sm),
      child: Row(
        children: [
          const SlmIconBadge(icon: Icons.verified_user_rounded, style: SlmIconStyle.medal, size: 40),
          const SizedBox(width: SlmSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlmText(
                  tr(bn, 'যাচাই হলে আপনিও বোর্ডে উঠবেন', 'Once verified, you will be on the board too'),
                  role: SlmTextRole.titleSm,
                  color: SlmColors.ivory,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                SlmText(status, role: SlmTextRole.bodySm, color: SlmColors.mist, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeagueRow> top;
  final String Function(LeagueRow) nameOf;

  const _Podium({required this.top, required this.nameOf});

  @override
  Widget build(BuildContext context) {
    LeagueRow? at(int i) => top.length > i ? top[i] : null;
    final order = [at(1), at(0), at(2)];
    return SlmCard(
      variant: SlmCardVariant.gold,
      padding: const EdgeInsets.fromLTRB(SlmSpace.xs, SlmSpace.lg, SlmSpace.xs, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in order)
            Expanded(child: e == null ? const SizedBox(height: 150) : _PodiumSlot(row: e, name: nameOf(e))),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeagueRow row;
  final String name;

  const _PodiumSlot({required this.row, required this.name});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final medal = SlmMedalLook.forRank(row.rank) ?? SlmMedal.bronze;
    final first = row.rank == 1;
    final k = s.layout.scale;
    final pedestal = switch (row.rank) { 1 => 64.0, 2 => 46.0, _ => 34.0 } * k;
    // A hidden name ("লাইনম্যান #1234") stays whole; a real one shows its first word.
    final short = name.contains('#') ? name : name.trim().split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.xxs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (first)
            SlmShimmer(child: Icon(Icons.workspace_premium_rounded, size: 28 * k, color: s.palette.accent))
          else
            SizedBox(height: 28 * k),
          const SizedBox(height: SlmSpace.xxs),
          first
              ? SlmPulse(color: medal.glow, child: SlmAvatar(name: name, size: 68, medal: medal))
              : SlmAvatar(name: name, size: 54, medal: medal),
          const SizedBox(height: SlmSpace.xs),
          SlmText(short.isEmpty ? '—' : short, role: SlmTextRole.label, maxLines: 1, align: TextAlign.center),
          SlmCountUp(
            value: row.points,
            style: s.type.number.copyWith(fontSize: 14 * k, color: s.palette.accent),
          ),
          const SizedBox(height: SlmSpace.xs),
          Container(
            height: pedestal,
            width: double.infinity,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: SlmSpace.xs),
            decoration: BoxDecoration(
              gradient: medal.gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(SlmRadius.md)),
            ),
            foregroundDecoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(SlmRadius.md)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x40000000)],
              ),
            ),
            child: Text(
              '${row.rank}',
              style: s.type.number.copyWith(fontSize: 18 * k, color: SlmColors.navy950),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeagueRow row;
  final String name;
  final bool bn;

  const _RankRow({required this.row, required this.name, required this.bn});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final where = row.districtFor(bn).trim();
    final levels = tr(bn, '${row.rungs} লেভেল', '${row.rungs} levels');
    return SlmCard(
      variant: row.isMe ? SlmCardVariant.gold : SlmCardVariant.surface,
      radius: SlmRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: SlmSpace.sm),
      child: Row(
        children: [
          SlmRankDisc(rank: row.rank),
          const SizedBox(width: SlmSpace.sm),
          SlmAvatar(name: name, size: 40),
          const SizedBox(width: SlmSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: SlmText(name, role: SlmTextRole.titleSm, maxLines: 1)),
                    if (row.isMe) ...[
                      const SizedBox(width: SlmSpace.xs),
                      SlmChip(label: tr(bn, 'আপনি', 'You'), tone: SlmTone.emerald, selected: true),
                    ],
                  ],
                ),
                SlmText(where.isEmpty ? levels : '$where · $levels', role: SlmTextRole.caption, maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: SlmSpace.xs),
          Text('${row.points}', style: s.type.number.copyWith(color: s.palette.accent)),
        ],
      ),
    );
  }
}

/// The verified member's place on this board and the gap to the next spot.
class _StandingCard extends StatelessWidget {
  final bool bn;
  final List<LeagueRow> rows;
  final bool monthly;

  const _StandingCard({required this.bn, required this.rows, required this.monthly});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final i = rows.indexWhere((r) => r.isMe);
    final me = i >= 0 ? rows[i] : null;

    final String headline;
    final String detail;
    double? progress;
    if (me == null) {
      headline = tr(bn, 'এখনও বোর্ডে নেই', 'Not on the board yet');
      detail = monthly
          ? tr(bn, 'এই মাসে কমপক্ষে 3টি লেভেল পার করুন — প্রতিটি তারা 10 পয়েন্ট।',
              'Clear at least 3 levels this month — every star is 10 points.')
          : tr(bn, 'লেভেল পার করুন — প্রতিটি তারা 10 পয়েন্ট।', 'Clear levels — every star is 10 points.');
    } else if (me.rank == 1) {
      headline = tr(bn, 'আপনিই শীর্ষে', 'You are on top');
      detail = tr(bn, 'জায়গা ধরে রাখতে আরও লেভেলে 3 তারা নিন।', 'Take 3 stars on more levels to hold the spot.');
      progress = 1;
    } else {
      final gap = me.gapToNext;
      final above = me.points + gap;
      headline = tr(bn, 'স্থান ${me.rank}', 'Rank ${me.rank}');
      detail = gap > 0
          ? tr(bn, 'পরের স্থানে যেতে আর $gap পয়েন্ট', '$gap points to the next spot')
          : tr(bn, 'সমান পয়েন্ট — উপরের জন আগে পৌঁছেছেন। আর একটা তারা নিলেই এগিয়ে যাবেন',
              'Level on points — they got there first. One more star puts you ahead');
      progress = above == 0 ? 0 : (me.points / above).clamp(0.0, 1.0);
    }

    return SlmCard(
      variant: SlmCardVariant.hero,
      padding: const EdgeInsets.fromLTRB(SlmSpace.md, SlmSpace.sm, SlmSpace.md, SlmSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              me == null
                  ? const SlmIconBadge(icon: Icons.person_rounded, style: SlmIconStyle.medal, size: 44)
                  : SlmPulse(color: s.palette.accent, child: SlmRankDisc(rank: me.rank, size: 44)),
              const SizedBox(width: SlmSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlmText(tr(bn, 'আপনার অবস্থান', 'Your standing'), role: SlmTextRole.overline),
                    const SizedBox(height: 1),
                    SlmText(headline, role: SlmTextRole.titleSm, color: SlmColors.ivory, maxLines: 1),
                  ],
                ),
              ),
              if (me != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SlmCountUp(
                      value: me.points,
                      style: s.type.number.copyWith(fontSize: 22 * s.layout.scale, color: s.palette.accent),
                    ),
                    SlmText(tr(bn, 'পয়েন্ট', 'points'), role: SlmTextRole.caption),
                  ],
                ),
            ],
          ),
          const SizedBox(height: SlmSpace.xs),
          if (progress != null) ...[
            SlmProgressBar(value: progress),
            const SizedBox(height: SlmSpace.xxs),
          ],
          SlmText(detail, role: SlmTextRole.bodySm, color: SlmColors.mist, maxLines: 2),
        ],
      ),
    );
  }
}

/// Placeholder rows with a light sweep while the board loads.
class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: p.surfaceRaised, borderRadius: SlmRadius.smAll),
        );
    return SlmShimmer(
      period: const Duration(milliseconds: 1600),
      intensity: 0.35,
      child: Column(
        children: [
          bar(double.infinity, 190),
          const SizedBox(height: SlmSpace.lg),
          for (var i = 0; i < 4; i++) ...[
            bar(double.infinity, 62),
            const SizedBox(height: SlmSpace.xs),
          ],
        ],
      ),
    );
  }
}

/// The one-time question on the first visit: show the name on the board?
class _NameQuestion extends StatelessWidget {
  final bool bn;
  final String masked;

  const _NameQuestion({required this.bn, required this.masked});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SlmColors.navy900,
      title: Text(
        tr(bn, 'বোর্ডে আপনার নাম দেখাবেন?', 'Show your name on the board?'),
        style: bangla(fontSize: 18, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.3),
      ),
      content: Text(
        tr(bn, 'না বললে বোর্ডে দেখাবে: $masked। পরে সেটিংস থেকে বদলাতে পারবেন।',
            'If not, the board shows: $masked. You can change it later in Settings.'),
        style: bangla(fontSize: 14.5, fontWeight: FontWeight.w500, color: SlmColors.mist, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr(bn, 'না', 'No'), style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.mist)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr(bn, 'হ্যাঁ', 'Yes'), style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
        ),
      ],
    );
  }
}
