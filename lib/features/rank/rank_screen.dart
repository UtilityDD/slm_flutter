import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../quizzes/leaderboard_provider.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

const _bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];
const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Space the pinned standing card takes above the dock.
const _standingReserve = 132.0;

/// Monthly leaderboard: podium, ranked list, and the member's own standing
/// pinned above the dock.
class RankScreen extends ConsumerWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final now = DateTime.now();
    final month = '${bn ? _bnMonths[now.month - 1] : _enMonths[now.month - 1]} ${now.year}';
    final board = ref.watch(liveLeaderboardProvider);

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
                      Padding(
                        padding: EdgeInsets.fromLTRB(g, SlmSpace.sm, g, SlmSpace.md),
                        child: SlmReveal(child: _Header(bn: bn, month: month)),
                      ),
                      Expanded(
                        child: _ChampionBoard(
                          bn: bn,
                          padding: shellScrollPadding(
                            context,
                            left: g,
                            right: g,
                            extraBottom: board.hasValue ? _standingReserve + SlmSpace.md : SlmSpace.xl,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (board.hasValue)
                  Positioned(
                    left: g,
                    right: g,
                    bottom: shellDockBottomOffset(context, 10),
                    child: SlmReveal(index: 3, rise: 22, child: _StandingCard(bn: bn)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool bn;
  final String month;

  const _Header({required this.bn, required this.month});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SlmIconBadge(icon: Icons.emoji_events_rounded, style: SlmIconStyle.medal, size: 44),
        const SizedBox(width: SlmSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlmText(tr(bn, 'র‍্যাঙ্ক', 'Rank'), role: SlmTextRole.headline, color: SlmColors.ivory, maxLines: 1),
              const SizedBox(height: 2),
              SlmText(
                tr(bn, 'এই মাসের মোট পয়েন্ট · $month', 'Total points this month · $month'),
                role: SlmTextRole.caption,
                color: SlmColors.gold300,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChampionBoard extends ConsumerWidget {
  final bool bn;
  final EdgeInsets padding;

  const _ChampionBoard({required this.bn, required this.padding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meId = ref.watch(authProvider).profile?.id;
    final board = ref.watch(liveLeaderboardProvider);

    return board.when(
      loading: () => ListView(padding: padding, children: const [_BoardSkeleton()]),
      error: (_, _) => Padding(
        padding: padding,
        child: SlmEmptyState(
          icon: Icons.cloud_off_rounded,
          title: tr(bn, 'বোর্ড লোড হয়নি', 'Could not load the board'),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Padding(
            padding: padding,
            child: SlmEmptyState(
              icon: Icons.emoji_events_rounded,
              title: tr(bn, 'এখনও কেউ নেই', 'No one here yet'),
            ),
          );
        }
        final rest = rows.length > 3 ? rows.sublist(3) : const <LeaderboardEntry>[];
        return ListView(
          padding: padding,
          children: [
            SlmReveal(index: 1, child: _Podium(top: rows.take(3).toList())),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: SlmSpace.xl),
              SlmReveal(
                index: 2,
                child: SlmSectionHeader(
                  overline: tr(bn, 'লিডারবোর্ড', 'Leaderboard'),
                  title: tr(bn, 'সেরা ${rows.length}', 'Top ${rows.length}'),
                ),
              ),
              for (var i = 0; i < rest.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: SlmSpace.xs),
                  child: SlmReveal(
                    index: 3 + (i < 8 ? i : 8),
                    child: _RankRow(entry: rest[i], isMe: meId != null && meId == rest[i].id, bn: bn),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top;

  const _Podium({required this.top});

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int i) => top.length > i ? top[i] : null;
    final order = [at(1), at(0), at(2)];
    return SlmCard(
      variant: SlmCardVariant.gold,
      padding: const EdgeInsets.fromLTRB(SlmSpace.xs, SlmSpace.lg, SlmSpace.xs, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in order)
            Expanded(child: e == null ? const SizedBox(height: 150) : _PodiumSlot(entry: e)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;

  const _PodiumSlot({required this.entry});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final medal = SlmMedalLook.forRank(entry.rank) ?? SlmMedal.bronze;
    final first = entry.rank == 1;
    final k = s.layout.scale;
    final pedestal = switch (entry.rank) { 1 => 64.0, 2 => 46.0, _ => 34.0 } * k;
    final name = entry.name.trim().split(RegExp(r'\s+')).first;

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
              ? SlmPulse(
                  color: medal.glow,
                  child: SlmAvatar(name: entry.name, url: entry.avatarUrl, size: 68, medal: medal),
                )
              : SlmAvatar(name: entry.name, url: entry.avatarUrl, size: 54, medal: medal),
          const SizedBox(height: SlmSpace.xs),
          SlmText(name.isEmpty ? '—' : name, role: SlmTextRole.label, maxLines: 1, align: TextAlign.center),
          SlmCountUp(
            value: entry.points,
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
              '${entry.rank}',
              style: s.type.number.copyWith(fontSize: 18 * k, color: SlmColors.navy950),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final bool bn;

  const _RankRow({required this.entry, required this.isMe, required this.bn});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    return SlmCard(
      variant: isMe ? SlmCardVariant.gold : SlmCardVariant.surface,
      radius: SlmRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: SlmSpace.sm),
      child: Row(
        children: [
          SlmRankDisc(rank: entry.rank),
          const SizedBox(width: SlmSpace.sm),
          SlmAvatar(name: entry.name, url: entry.avatarUrl, size: 40),
          const SizedBox(width: SlmSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: SlmText(entry.name, role: SlmTextRole.titleSm, maxLines: 1)),
                    if (isMe) ...[
                      const SizedBox(width: SlmSpace.xs),
                      SlmChip(label: tr(bn, 'আপনি', 'You'), tone: SlmTone.emerald, selected: true),
                    ],
                  ],
                ),
                SlmText(entry.district, role: SlmTextRole.caption, maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: SlmSpace.xs),
          Text('${entry.points}', style: s.type.number.copyWith(color: s.palette.accent)),
        ],
      ),
    );
  }
}

/// The signed-in member's place on the board and the gap to the next spot.
class _StandingCard extends ConsumerWidget {
  final bool bn;

  const _StandingCard({required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.slm;
    final auth = ref.watch(authProvider);
    final rows = ref.watch(liveLeaderboardProvider).value ?? const <LeaderboardEntry>[];
    final meId = auth.profile?.id;
    final i = meId == null ? -1 : rows.indexWhere((r) => r.id == meId);
    final me = i >= 0 ? rows[i] : null;
    final above = i > 0 ? rows[i - 1] : null;

    final String headline;
    final String detail;
    double? progress;
    if (me == null) {
      headline = auth.isAuthenticated ? tr(bn, 'এখনও বোর্ডে নেই', 'Not on the board yet') : tr(bn, 'অতিথি', 'Guest');
      detail = auth.isAuthenticated
          ? tr(bn, 'পয়েন্ট জিতে এই মাসের সেরা ${rows.length}-এ উঠে আসুন।', 'Earn points to reach this month\'s top ${rows.length}.')
          : tr(bn, 'লগইন করলে আপনার পয়েন্ট বোর্ডে উঠবে।', 'Sign in to put your points on the board.');
    } else if (above == null) {
      headline = tr(bn, 'আপনিই শীর্ষে', 'You are on top');
      detail = tr(bn, 'জায়গা ধরে রাখতে পয়েন্ট বাড়াতে থাকুন।', 'Keep earning to hold the spot.');
      progress = 1;
    } else {
      final gap = above.points - me.points;
      headline = tr(bn, 'স্থান ${me.rank}', 'Rank ${me.rank}');
      detail = tr(bn, 'পরের স্থানে যেতে আর $gap পয়েন্ট', '$gap points to the next spot');
      progress = above.points == 0 ? 0 : (me.points / above.points).clamp(0.0, 1.0);
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
