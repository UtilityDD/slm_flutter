import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../admin/dev_unlock.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import '../shell/shell_insets.dart';
import 'lesson_reader_page.dart';
import 'level_lessons_sheet.dart';
import 'lineman_figure.dart';

const _shelfTop = SlmColors.navy900;

/// Night shelf for one rank's lessons — book-cover cards.
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
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: SlmColors.gold400)),
        ),
      ),
      error: (_, __) => slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Icon(Icons.wifi_off_rounded, size: 40, color: SlmColors.slate),
          ),
        ),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          slivers.add(
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Icon(Icons.menu_book_outlined, size: 40, color: SlmColors.slate)),
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
                      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0), curve: SlmMotion.emphasized),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: Stack(
          children: [
            Positioned.fill(
              child: Theme(
                data: SlmTheme.night(),
                child: const SlmBackground(constrain: false, child: SizedBox.expand()),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: slivers,
                  ),
                  // Soft fade so cards slip away at the bottom edge.
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
                              SlmColors.navy950.withValues(alpha: 0),
                              SlmColors.navy950,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _shelfTop,
        border: Border(
          bottom: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.28 * t)),
        ),
      ),
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
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: SlmColors.gold300,
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
                        color: SlmColors.ivory,
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
                      color: SlmColors.ivory,
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
                    color: SlmColors.navy800,
                    borderRadius: SlmRadius.pillAll,
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                    boxShadow: [
                      BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.18), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 15, color: SlmColors.gold300),
                      const SizedBox(width: 6),
                      Text(
                        badgeName,
                        style: const TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SlmColors.gold100,
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: SlmColors.ivory),
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
        color: _shelfTop,
        boxShadow: overlapsContent
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: Row(
        children: [
          Text(
            bn ? '$done / $total পড়া হয়েছে' : '$done / $total read',
            style: TextStyle(
              fontFamily: banglaFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: complete ? SlmColors.emerald300 : SlmColors.mist,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: SlmMotion.emphasized,
              builder: (context, value, _) => _ShelfBar(value: value, complete: complete),
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

class _ShelfBar extends StatelessWidget {
  final double value;
  final bool complete;

  const _ShelfBar({required this.value, required this.complete});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: SlmColors.navy950,
        borderRadius: SlmRadius.pillAll,
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: complete ? SlmGradients.emerald : SlmGradients.gold,
              borderRadius: SlmRadius.pillAll,
              boxShadow: [
                BoxShadow(
                  color: (complete ? SlmColors.emerald400 : SlmColors.gold400).withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        ? SlmColors.slate
        : done
            ? SlmColors.emerald300
            : isNext
                ? SlmColors.gold300
                : SlmColors.bronze;
    final metal = locked
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SlmColors.slate, SlmColors.navy600],
          )
        : done
            ? SlmGradients.emerald
            : isNext
                ? SlmGradients.gold
                : SlmGradients.bronze;

    return Opacity(
      opacity: locked ? 0.78 : 1,
      child: SlmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        semanticLabel: lesson.title,
        child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: isNext ? SlmGradients.navyHero : SlmGradients.navyCard,
              border: Border.all(
                color: isNext
                    ? SlmColors.gold400
                    : done
                        ? SlmColors.emerald600.withValues(alpha: 0.5)
                        : SlmColors.gold400.withValues(alpha: 0.18),
                width: isNext ? 1.4 : 1,
              ),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
                      if (isNext)
                        BoxShadow(
                          color: SlmColors.gold400.withValues(alpha: 0.25),
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
                      gradient: metal,
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
                                    color: spine.withValues(alpha: 0.85),
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
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: SlmColors.gold400.withValues(alpha: 0.2),
                          ),
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
                                    color: locked ? SlmColors.slate : SlmColors.ivory,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isNext)
                                  SlmShimmer(
                                    period: const Duration(milliseconds: 3800),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: SlmGradients.gold,
                                        borderRadius: SlmRadius.pillAll,
                                        boxShadow: [
                                          BoxShadow(
                                            color: SlmColors.gold400.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.play_arrow_rounded, size: 15, color: SlmColors.navy900),
                                          const SizedBox(width: 3),
                                          Text(
                                            bn ? 'এখান থেকে শুরু' : 'Continue here',
                                            style: const TextStyle(
                                              fontFamily: banglaFont,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: SlmColors.navy900,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                          ? SlmColors.slate
                                          : done
                                              ? SlmColors.emerald300
                                              : SlmColors.mist,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CardMedal(
                            color: spine,
                            icon: locked
                                ? Icons.lock_outline_rounded
                                : done
                                    ? Icons.menu_book_rounded
                                    : Icons.auto_stories_rounded,
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
    );
  }
}

class _CardMedal extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _CardMedal({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}
