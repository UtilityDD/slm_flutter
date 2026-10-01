import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../quizzes/leaderboard_provider.dart';
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
      tr(bn, 'নতুন সদস্য', 'New'),
      tr(bn, 'এগিয়ে', 'Improved'),
      tr(bn, 'পড়াশোনা', 'Learner'),
    ];
    final notes = [
      tr(bn, 'এই মাসের মোট পয়েন্ট।', 'Total points this month.'),
      tr(bn, 'গত ৯০ দিনের নতুন সদস্য। বোর্ডের হিসাব পরের ধাপে।', 'Joiners from the last 90 days. Scoring lands next.'),
      tr(bn, 'গত মাসের চেয়ে যারা এগিয়েছেন।', 'Who grew the most since last month.'),
      tr(bn, 'এই মাসের পড়ার পয়েন্ট।', 'Reading points this month.'),
    ];

    return SlmBackdrop(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                tr(bn, 'র‍্যাঙ্ক', 'Rank'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: boards.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _board == index;
                  return ChoiceChip(
                    label: Text(boards[index]),
                    selected: selected,
                    onSelected: (_) => setState(() => _board = index),
                    selectedColor: const Color(0xFFFFEDD5),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.navActive : AppColors.inkSoft,
                    ),
                    side: BorderSide(color: selected ? const Color(0xFFFDBA74) : const Color(0x61D6BDA4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                notes[_board],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            ),
            Expanded(child: _board == 0 ? const _ChampionList() : _WaitingNote(text: notes[_board])),
          ],
        ),
      ),
    );
  }
}

class _WaitingNote extends StatelessWidget {
  final String text;

  const _WaitingNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

class _ChampionList extends ConsumerWidget {
  const _ChampionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(liveLeaderboardProvider);
    return board.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (rows) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final row = rows[index];
            final medal = switch (row.rank) {
              1 => '১',
              2 => '২',
              3 => '৩',
              _ => '${row.rank}',
            };
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: row.rank <= 3 ? const Color(0xFFFDBA74) : const Color(0x61D6BDA4),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: row.rank <= 3 ? const Color(0xFFFFEDD5) : const Color(0xFFF5F0EA),
                    child: Text(
                      medal,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navActive),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        Text(
                          row.district,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${row.points}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC2410C), fontSize: 16),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
