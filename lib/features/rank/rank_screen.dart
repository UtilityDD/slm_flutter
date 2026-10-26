import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../auth/auth_provider.dart';
import '../quizzes/leaderboard_provider.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

class RankScreen extends ConsumerStatefulWidget {
  const RankScreen({super.key});

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen> {
  int _board = 0;

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
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

    return SlmBackdrop(
      child: ShellSafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33F59E0B)),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, size: 20, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(bn, 'র‍্যাঙ্ক', 'Rank'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Material(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pushNamed(AppRoutes.quiz);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              tr(bn, 'কুইজ', 'Quiz'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _BoardSegment(
                labels: boards,
                selected: _board,
                onChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _board = i);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Text(
                notes[_board],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 1.3,
                ),
              ),
            ),
            Expanded(
              child: _board == 0
                  ? const _ChampionBoard()
                  : _ComingSoon(
                      bn: bn,
                      title: boards[_board],
                      note: notes[_board],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardSegment extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _BoardSegment({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE3),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x33D6BDA4)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: selected == i
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected == i ? const Color(0xFFEA580C) : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final bool bn;
  final String title;
  final String note;

  const _ComingSoon({
    required this.bn,
    required this.title,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: shellScrollPadding(context, left: 32, top: 8, right: 32, extraBottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33D6BDA4)),
              ),
              child: const Icon(Icons.hourglass_top_rounded, size: 28, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr(bn, 'শীঘ্রই খুলবে', 'Opening soon'),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampionBoard extends ConsumerWidget {
  const _ChampionBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final me = ref.watch(authProvider).profile?.id;
    final board = ref.watch(liveLeaderboardProvider);

    return board.when(
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFD97706)),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr(bn, 'বোর্ড লোড হয়নি', 'Could not load the board'),
            style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Text(
              tr(bn, 'এখনও কেউ নেই', 'No one here yet'),
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          );
        }

        final top = rows.take(3).toList();
        final rest = rows.length > 3 ? rows.sublist(3) : const <LeaderboardEntry>[];

        return ListView(
          padding: shellScrollPadding(context, left: 16, top: 6, right: 16),
          children: [
            _Podium(top: top),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 14),
              _BoardList(rows: rest, meId: me, bn: bn),
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
    if (top.isEmpty) return const SizedBox.shrink();

    // Visual order: 2nd · 1st · 3rd
    final slots = <LeaderboardEntry?>[
      top.length > 1 ? top[1] : null,
      top[0],
      top.length > 2 ? top[2] : null,
    ];
    final ranks = <int?>[
      top.length > 1 ? 2 : null,
      1,
      top.length > 2 ? 3 : null,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x66FDBA74)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFBF5), Colors.white],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14EA580C), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: slots[i] == null
                  ? const SizedBox(height: 120)
                  : _PodiumSlot(
                      entry: slots[i]!,
                      rank: ranks[i]!,
                      raised: ranks[i] == 1,
                    ),
            ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool raised;

  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.raised,
  });

  @override
  Widget build(BuildContext context) {
    final ring = switch (rank) {
      1 => const Color(0xFFFBBF24),
      2 => const Color(0xFFCBD5E1),
      _ => const Color(0xFFFB923C),
    };
    final pedestal = switch (rank) {
      1 => const [Color(0xFFFCD34D), Color(0xFFF59E0B)],
      2 => const [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
      _ => const [Color(0xFFFDBA74), Color(0xFFEA580C)],
    };
    final avatarSize = raised ? 64.0 : 52.0;
    final pedHeight = switch (rank) {
      1 => 52.0,
      2 => 38.0,
      _ => 30.0,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: raised ? 4 : 0, left: 4, right: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.workspace_premium_rounded, size: 22, color: Color(0xFFF59E0B)),
            )
          else
            const SizedBox(height: 26),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2.5),
              boxShadow: [
                BoxShadow(color: ring.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 2)),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: ClipOval(child: _AvatarFace(url: entry.avatarUrl, name: entry.name, size: avatarSize)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _firstName(entry.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.points}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9A3412),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: pedHeight,
            width: double.infinity,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: pedestal,
              ),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
                shadows: [Shadow(color: Color(0x33000000), blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardList extends StatelessWidget {
  final List<LeaderboardEntry> rows;
  final String? meId;
  final bool bn;

  const _BoardList({
    required this.rows,
    required this.meId,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33D6BDA4)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0x14D6BDA4)),
            _RankRow(
              entry: rows[i],
              isMe: meId != null && meId == rows[i].id,
              bn: bn,
            ),
          ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final bool bn;

  const _RankRow({
    required this.entry,
    required this.isMe,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (entry.rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFEA580C),
      _ => AppColors.muted,
    };

    return Container(
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0x14EA580C)
            : entry.rank == 1
                ? const Color(0x0AF59E0B)
                : Colors.transparent,
        border: isMe
            ? const Border(left: BorderSide(color: Color(0xFFEA580C), width: 3))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: rankColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: _AvatarFace(url: entry.avatarUrl, name: entry.name, size: 36),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          tr(bn, 'আপনি', 'You'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  entry.district,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.points}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFC2410C),
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFace extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const _AvatarFace({
    required this.url,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first);
    final fallback = ColoredBox(
      color: const Color(0xFFF5F0EA),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
      ),
    );

    final src = url?.trim();
    if (src == null || src.isEmpty) return fallback;

    return Image.network(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return fallback;
      },
    );
  }
}

String _firstName(String full) {
  final t = full.trim();
  if (t.isEmpty) return '—';
  return t.split(RegExp(r'\s+')).first;
}
