import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../admin/dev_unlock.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import '../shell/shell_insets.dart';
import 'lesson_reader_page.dart';
import 'level_lessons_sheet.dart';
import 'lineman_figure.dart';

const _shelfPaper = Color(0xFFF8F1E4);

/// Warm paper shelf for one rank's lessons — book-cover cards.
class LevelLessonsPage extends ConsumerStatefulWidget {
  final int moduleNumber;
  final int step;
  final String badgeName;
  final String chapterTitle;
  final bool bn;

  const LevelLessonsPage({
    super.key,
    required this.moduleNumber,
    required this.step,
    required this.badgeName,
    required this.chapterTitle,
    required this.bn,
  });

  @override
  ConsumerState<LevelLessonsPage> createState() => _LevelLessonsPageState();
}

class _LevelLessonsPageState extends ConsumerState<LevelLessonsPage> with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  final _nextKey = GlobalKey();
  bool _entered = false;
  bool _didAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _onDataReady(int nextIndex) {
    if (!_entered) {
      _entered = true;
      _enter.forward();
    }
    if (_didAutoScroll) return;
    _didAutoScroll = true;
    if (nextIndex < 2) return;
    Future.delayed(const Duration(milliseconds: 520), () {
      final ctx = _nextKey.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
        alignment: 0.3,
      );
    });
  }

  void _openLesson(LessonCardItem lesson) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => LessonReaderPage(lesson: lesson, bn: widget.bn),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.04, 0.02), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bn = widget.bn;
    final devOpen = ref.watch(devUnlockProvider);
    final lessonsAsync = ref.watch(moduleLessonsProvider(widget.moduleNumber));

    final slivers = <Widget>[
      SliverPersistentHeader(
        pinned: true,
        delegate: _ShelfHeaderDelegate(
          step: widget.step,
          badgeName: widget.badgeName,
          chapterTitle: widget.chapterTitle,
          bn: bn,
        ),
      ),
    ];

    lessonsAsync.when(
      loading: () => slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF8A7464))),
        ),
      ),
      error: (_, __) => slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.muted.withValues(alpha: 0.7)),
          ),
        ),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          slivers.add(
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Icon(Icons.menu_book_outlined, size: 40, color: Color(0xFFD6D3D1))),
            ),
          );
          return;
        }
        final ordered = [...lessons]..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
        final done = ordered.where((l) => l.isCompleted).length;
        final nextIndex = ordered.indexWhere((l) => !l.isCompleted);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onDataReady(nextIndex);
        });

        slivers
          ..add(
            SliverPersistentHeader(
              pinned: true,
              delegate: _ShelfProgressDelegate(done: done, total: ordered.length, bn: bn),
            ),
          )
          ..add(
            SliverPadding(
              padding: shellScrollPadding(context, left: 18, top: 6, right: 18, extraBottom: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lesson = ordered[index];
                    final prevDone = index == 0 || ordered[index - 1].isCompleted;
                    final locked = !devOpen && !lesson.isCompleted && !prevDone;
                    final isNext = index == nextIndex;
                    final start = (index * 0.07).clamp(0.0, 0.55);
                    final entrance = CurvedAnimation(
                      parent: _enter,
                      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                    );
                    return Padding(
                      key: isNext ? _nextKey : null,
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedBuilder(
                        animation: entrance,
                        builder: (context, child) => Opacity(
                          opacity: entrance.value,
                          child: Transform.translate(
                            offset: Offset(0, 28 * (1 - entrance.value)),
                            child: child,
                          ),
                        ),
                        child: _EdgeReveal(
                          child: _BookLessonCard(
                            lesson: lesson,
                            bn: bn,
                            locked: locked,
                            isNext: isNext,
                            onTap: () {
                              if (locked) {
                                final prev = ordered[index - 1];
                                showModernLockMessage(
                                  context,
                                  bn: bn,
                                  message: bn
                                      ? 'আগে পাঠ ${prev.chapterNumber} পড়ুন — তারপর এটি খুলবে।'
                                      : 'Read lesson ${prev.chapterNumber} first — then this opens.',
                                );
                                return;
                              }
                              _openLesson(lesson);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: ordered.length,
                ),
              ),
            ),
          );
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE0),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_shelfPaper, Color(0xFFF0E6D4), Color(0xFFEADFCB)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: slivers,
              ),
              // Soft paper fade so cards slip away at the bottom edge.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 36,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEADFCB).withValues(alpha: 0),
                          const Color(0xFFEADFCB),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsing header: big lineman + chapter title folds into a slim top bar.
class _ShelfHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int step;
  final String badgeName;
  final String chapterTitle;
  final bool bn;

  _ShelfHeaderDelegate({
    required this.step,
    required this.badgeName,
    required this.chapterTitle,
    required this.bn,
  });

  static const _max = 176.0;
  static const _min = 60.0;
  static const _figBig = Rect.fromLTWH(20, 58, 78, 104);
  static const _figSmall = Rect.fromLTWH(50, 8, 33, 44);

  @override
  double get maxExtent => _max;

  @override
  double get minExtent => _min;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (_max - _min)).clamp(0.0, 1.0);
    final ease = Curves.easeInOut.transform(t);
    final fig = Rect.lerp(_figBig, _figSmall, ease)!;
    final bigOpacity = (1 - t * 1.8).clamp(0.0, 1.0);
    final smallOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);

    return ColoredBox(
      color: _shelfPaper,
      child: ClipRect(
        child: Stack(
          children: [
            // Big chapter title — drifts up faster than the figure and fades.
            Positioned(
              left: 112,
              right: 20,
              top: 60 - shrinkOffset * 0.35,
              child: Opacity(
                opacity: bigOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bn ? 'পাঠের তালিকা' : 'Lesson shelf',
                      style: TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.muted.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapterTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                        color: Color(0xFF1C1917),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Lineman shrinks into the bar.
            Positioned.fromRect(
              rect: fig,
              child: LinemanFigure(step: step, enableHero: true, quiet: false),
            ),
            // Compact one-line title for the collapsed bar.
            Positioned(
              left: 92,
              right: 16,
              top: 0,
              height: _min,
              child: Opacity(
                opacity: smallOpacity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: banglaFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                ),
              ),
            ),
            // Rank badge fades out as the bar collapses.
            Positioned(
              top: 10,
              right: 14,
              child: Opacity(
                opacity: (1 - t * 2).clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A28).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 15, color: Color(0xFFF5D76E)),
                      const SizedBox(width: 6),
                      Text(
                        badgeName,
                        style: const TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF8F1E4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 6,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF3F3A36)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShelfHeaderDelegate old) =>
      old.step != step || old.badgeName != badgeName || old.chapterTitle != chapterTitle || old.bn != bn;
}

/// Pinned progress strip under the header; gains a soft shadow once cards scroll under it.
class _ShelfProgressDelegate extends SliverPersistentHeaderDelegate {
  final int done;
  final int total;
  final bool bn;

  _ShelfProgressDelegate({required this.done, required this.total, required this.bn});

  static const _h = 44.0;

  @override
  double get maxExtent => _h;

  @override
  double get minExtent => _h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ratio = total == 0 ? 0.0 : done / total;
    final complete = total > 0 && done == total;
    return Container(
      decoration: BoxDecoration(
        color: _shelfPaper,
        boxShadow: overlapsContent
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: Row(
        children: [
          Text(
            bn ? '$done / $total পড়া হয়েছে' : '$done / $total read',
            style: const TextStyle(
              fontFamily: banglaFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B5A4C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE2D4C0),
                  color: complete ? AppColors.safeGreen : const Color(0xFF8B5E3C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShelfProgressDelegate old) =>
      old.done != done || old.total != total || old.bn != bn;
}

/// Cards rising in from the bottom edge scale up from a slightly smaller size.
class _EdgeReveal extends StatefulWidget {
  final Widget child;

  const _EdgeReveal({required this.child});

  @override
  State<_EdgeReveal> createState() => _EdgeRevealState();
}

class _EdgeRevealState extends State<_EdgeReveal> {
  ScrollPosition? _position;
  double _screenH = 0;
  double _t = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_update);
      _position = next;
      _position?.addListener(_update);
      WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    }
  }

  void _update() {
    if (!mounted || _screenH == 0) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final t = ((_screenH - top) / 150).clamp(0.0, 1.0);
    if ((t - _t).abs() > 0.01) setState(() => _t = t);
  }

  @override
  void dispose() {
    _position?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenH = MediaQuery.sizeOf(context).height;
    final eased = Curves.easeOut.transform(_t);
    return Transform.scale(
      scale: 0.93 + 0.07 * eased,
      alignment: Alignment.topCenter,
      child: Opacity(opacity: 0.5 + 0.5 * eased, child: widget.child),
    );
  }
}

class _BookLessonCard extends StatelessWidget {
  final LessonCardItem lesson;
  final bool bn;
  final bool locked;
  final bool isNext;
  final VoidCallback onTap;

  const _BookLessonCard({
    required this.lesson,
    required this.bn,
    required this.locked,
    required this.onTap,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final done = lesson.isCompleted;
    final spine = locked
        ? const Color(0xFFA8A29E)
        : done
            ? const Color(0xFF166534)
            : const Color(0xFF8B5E3C);
    final paper = locked
        ? const Color(0xFFF5F0E8)
        : done
            ? const Color(0xFFF5FBF6)
            : const Color(0xFFFFFBF4);

    return Opacity(
      opacity: locked ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [paper, Color.lerp(paper, const Color(0xFFE8DCC8), 0.35)!],
              ),
              border: Border.all(
                color: isNext ? const Color(0xFFD97706) : const Color(0xFFD8C7AE).withValues(alpha: 0.85),
                width: isNext ? 1.6 : 1,
              ),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 8)),
                      BoxShadow(color: spine.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(-2, 2)),
                      if (isNext)
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [spine, Color.lerp(spine, Colors.black, 0.25)!],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 46,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bn ? 'পাঠ' : 'Ch.',
                                  style: TextStyle(
                                    fontFamily: banglaFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: spine.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '${lesson.chapterNumber}',
                                  style: TextStyle(
                                    fontFamily: banglaFont,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    height: 1.05,
                                    color: spine,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: const Color(0xFFD8C7AE)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: banglaFont,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: locked ? const Color(0xFF78716C) : const Color(0xFF1C1917),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isNext)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.play_arrow_rounded, size: 15, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text(
                                          bn ? 'এখান থেকে শুরু' : 'Continue here',
                                          style: const TextStyle(
                                            fontFamily: banglaFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    locked
                                        ? (bn ? 'আগের পাঠ শেষ করুন' : 'Finish the previous lesson')
                                        : done
                                            ? (bn ? 'আবার পড়ুন' : 'Read again')
                                            : (bn ? 'বই খুলে পড়ুন' : 'Open & read'),
                                    style: TextStyle(
                                      fontFamily: banglaFont,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: locked
                                          ? const Color(0xFFA8A29E)
                                          : done
                                              ? AppColors.safeGreen
                                              : const Color(0xFF8A7464),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            locked
                                ? Icons.lock_outline_rounded
                                : done
                                    ? Icons.menu_book_rounded
                                    : Icons.auto_stories_rounded,
                            size: 26,
                            color: spine.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
