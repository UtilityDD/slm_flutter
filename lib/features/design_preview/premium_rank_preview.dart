import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../quizzes/leaderboard_provider.dart';
import '../shell/app_routes.dart';
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

/// Rank screen rebuilt on the premium design system. Same data and actions
/// as [RankScreen]; only the look differs.
class PremiumRankPreview extends ConsumerStatefulWidget {
  const PremiumRankPreview({super.key});

  @override
  ConsumerState<PremiumRankPreview> createState() => _PremiumRankPreviewState();
}

class _PremiumRankPreviewState extends ConsumerState<PremiumRankPreview> {
  int _board = 0;
  bool _night = true;

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final now = DateTime.now();
    final month = '${bn ? _bnMonths[now.month - 1] : _enMonths[now.month - 1]} ${now.year}';
    final boards = [
      tr(bn, 'মাসের সেরা', 'Champion'),
      tr(bn, 'নতুন', 'New'),
      tr(bn, 'এগিয়ে', 'Improved'),
      tr(bn, 'পড়া', 'Learner'),
    ];
    final notes = [
      tr(bn, 'এই মাসের মোট পয়েন্ট।', 'Total points this month.'),
      tr(bn, 'গত 90 দিনের নতুন সদস্য। বোর্ড শীঘ্রই।', 'Joiners from the last 90 days. Board lands next.'),
      tr(bn, 'গত মাসের চেয়ে যারা এগিয়েছেন।', 'Who grew the most since last month.'),
      tr(bn, 'এই মাসের পড়ার পয়েন্ট।', 'Reading points this month.'),
    ];

    return Theme(
      data: _night ? SlmTheme.night() : SlmTheme.day(),
      child: Builder(
        builder: (context) {
          final g = context.slm.layout.gutter;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SlmBackground(
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SlmTopBar(
                      title: tr(bn, 'র‍্যাঙ্ক', 'Rank'),
                      subtitle: tr(bn, 'মাসিক লিডারবোর্ড · $month', 'Monthly leaderboard · $month'),
                      onBack: () => Navigator.of(context).maybePop(),
                      backLabel: tr(bn, 'ফিরে যান', 'Back'),
                      actions: [
                        SlmChip(
                          label: bn ? 'EN' : 'বাং',
                          icon: Icons.translate_rounded,
                          onTap: () => ref.read(languageProvider.notifier).setBengali(!bn),
                        ),
                        SlmIconButton(
                          icon: _night ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          tooltip: tr(bn, 'দিন / রাত', 'Day / night'),
                          size: 44,
                          onPressed: () => setState(() => _night = !_night),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        padding: shellScrollPadding(context, left: g, top: SlmSpace.xs, right: g, extraBottom: SlmSpace.xl),
                        children: [
                          SlmReveal(
                            child: Theme(data: SlmTheme.night(), child: _StandingHero(bn: bn)),
                          ),
                          const SizedBox(height: SlmSpace.lg),
                          SlmReveal(
                            index: 1,
                            child: SlmSegmented(
                              labels: boards,
                              selected: _board,
                              onChanged: (i) => setState(() => _board = i),
                            ),
                          ),
                          const SizedBox(height: SlmSpace.xs),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: SlmSpace.xs),
                            child: SlmText(notes[_board], role: SlmTextRole.caption),
                          ),
                          const SizedBox(height: SlmSpace.md),
                          AnimatedSwitcher(
                            duration: SlmMotion.base,
                            child: _board == 0
                                ? _ChampionBoard(key: const ValueKey('champ'), bn: bn)
                                : SlmEmptyState(
                                    key: ValueKey(_board),
                                    icon: Icons.hourglass_top_rounded,
                                    title: boards[_board],
                                    message: notes[_board],
                                    action: SlmChip(
                                      label: tr(bn, 'শীঘ্রই খুলবে', 'Opening soon'),
                                      icon: Icons.schedule_rounded,
                                      tone: SlmTone.emerald,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Signed-in member's place on the board, with distance to the next spot.
class _StandingHero extends ConsumerWidget {
  final bool bn;
  const _StandingHero({required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.slm;
    final auth = ref.watch(authProvider);
    final rows = ref.watch(liveLeaderboardProvider).value ?? const <LeaderboardEntry>[];
    final meId = auth.profile?.id;
    final signedIn = auth.isAuthenticated;
    final i = meId == null ? -1 : rows.indexWhere((r) => r.id == meId);
    final me = i >= 0 ? rows[i] : null;
    final above = i > 0 ? rows[i - 1] : null;

    final String headline;
    final String detail;
    final double progress;
    if (me == null) {
      headline = signedIn ? tr(bn, 'এখনও বোর্ডে নেই', 'Not on the board yet') : tr(bn, 'অতিথি', 'Guest');
      detail = signedIn
          ? tr(bn, 'কুইজ খেলে পয়েন্ট জিতুন, সেরা 25-এ উঠে আসুন।', 'Play quizzes to earn points and reach the top 25.')
          : tr(bn, 'লগইন করলে আপনার পয়েন্ট বোর্ডে উঠবে।', 'Sign in to put your points on the board.');
      progress = 0;
    } else if (above == null) {
      headline = tr(bn, 'আপনিই শীর্ষে', 'You are on top');
      detail = tr(bn, 'জায়গা ধরে রাখতে খেলতে থাকুন।', 'Keep playing to hold the spot.');
      progress = 1;
    } else {
      final gap = above.points - me.points;
      headline = tr(bn, 'স্থান ${me.rank}', 'Rank ${me.rank}');
      detail = tr(bn, 'পরের স্থানে যেতে আর $gap পয়েন্ট', '$gap points to the next spot');
      progress = above.points == 0 ? 0 : me.points / above.points;
    }

    return SlmCard(
      variant: SlmCardVariant.hero,
      padding: EdgeInsets.all(SlmSpace.lg * s.layout.scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              me == null
                  ? const SlmIconBadge(icon: Icons.person_rounded, style: SlmIconStyle.medal, size: 56)
                  : SlmPulse(
                      color: s.palette.accent,
                      child: SlmRankDisc(rank: me.rank, size: 56),
                    ),
              const SizedBox(width: SlmSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlmText(tr(bn, 'আপনার অবস্থান', 'Your standing'), role: SlmTextRole.overline),
                    const SizedBox(height: 2),
                    SlmText(headline, role: SlmTextRole.title, color: Colors.white, maxLines: 1),
                  ],
                ),
              ),
              if (me != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SlmCountUp(
                      value: me.points,
                      style: s.type.number.copyWith(fontSize: 26 * s.layout.scale, color: s.palette.accent),
                    ),
                    SlmText(tr(bn, 'পয়েন্ট', 'points'), role: SlmTextRole.caption),
                  ],
                ),
            ],
          ),
          const SizedBox(height: SlmSpace.md),
          if (me != null) ...[
            SlmProgressBar(value: progress),
            const SizedBox(height: SlmSpace.xs),
          ],
          SlmText(detail, role: SlmTextRole.bodySm, color: SlmColors.mist),
          const SizedBox(height: SlmSpace.md),
          signedIn
              ? SlmButton.gold(
                  label: tr(bn, 'কুইজ খেলে পয়েন্ট বাড়ান', 'Play a quiz to earn points'),
                  icon: Icons.bolt_rounded,
                  expand: true,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.quiz),
                )
              : SlmButton(
                  label: tr(bn, 'লগইন করুন', 'Sign in'),
                  icon: Icons.login_rounded,
                  expand: true,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                ),
        ],
      ),
    );
  }
}

class _ChampionBoard extends ConsumerWidget {
  final bool bn;
  const _ChampionBoard({super.key, required this.bn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meId = ref.watch(authProvider).profile?.id;
    final board = ref.watch(liveLeaderboardProvider);

    return board.when(
      loading: () => const _BoardSkeleton(),
      error: (_, _) => SlmEmptyState(
        icon: Icons.cloud_off_rounded,
        title: tr(bn, 'বোর্ড লোড হয়নি', 'Could not load the board'),
        action: SlmButton.secondary(
          label: tr(bn, 'আবার চেষ্টা', 'Try again'),
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(liveLeaderboardProvider),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return SlmEmptyState(
            icon: Icons.emoji_events_rounded,
            title: tr(bn, 'এখনও কেউ নেই', 'No one here yet'),
          );
        }
        final rest = rows.length > 3 ? rows.sublist(3) : const <LeaderboardEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SlmReveal(index: 2, child: _Podium(top: rows.take(3).toList())),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: SlmSpace.xl),
              SlmSectionHeader(
                overline: tr(bn, 'লিডারবোর্ড', 'Leaderboard'),
                title: tr(bn, 'সেরা ${rows.length}', 'Top ${rows.length}'),
              ),
              for (var i = 0; i < rest.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: SlmSpace.xs),
                  child: SlmReveal(
                    index: 3 + i,
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
          SlmText(name, role: SlmTextRole.label, maxLines: 1, align: TextAlign.center),
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
    final row = Row(
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
        Text(
          '${entry.points}',
          style: s.type.number.copyWith(color: s.palette.accent),
        ),
      ],
    );

    return SlmCard(
      variant: isMe ? SlmCardVariant.gold : SlmCardVariant.surface,
      radius: SlmRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: SlmSpace.sm),
      child: row,
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
