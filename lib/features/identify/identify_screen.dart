import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'identify_chart_view.dart';
import 'identify_charts.dart';
import 'identify_detail_page.dart';
import 'identify_search.dart';
import 'identify_style.dart';
import 'library_catalog.dart';

const _allGroup = '__all__';
const _sectionPreview = 4;
const _teal = Color(0xFF0F766E);

class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _speech = SpeechToText();
  String _query = '';
  String _group = _allGroup;
  bool _showPill = false;
  bool _speechReady = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > 230;
      if (show != _showPill) setState(() => _showPill = show);
    });
  }

  @override
  void dispose() {
    if (_speech.isListening) {
      _speech.stop();
    }
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<bool> _ensureSpeech() async {
    if (_speechReady) return true;
    _speechReady = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() => _listening = false);
        final bn = ref.read(languageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(bn, 'কণ্ঠ শোনা যায়নি। আবার চেষ্টা করুন।', 'Could not hear that. Try again.'),
            ),
          ),
        );
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == SpeechToText.notListeningStatus || status == SpeechToText.doneStatus) {
          setState(() => _listening = false);
        }
      },
    );
    return _speechReady;
  }

  Future<String?> _voiceLocale(bool bn) async {
    final locales = await _speech.locales();
    if (locales.isEmpty) return null;
    final prefer = bn ? const ['bn_BD', 'bn_IN', 'bn'] : const ['en_IN', 'en_US', 'en_GB', 'en'];
    for (final id in prefer) {
      for (final locale in locales) {
        if (locale.localeId == id || locale.localeId.toLowerCase().startsWith(id.toLowerCase())) {
          return locale.localeId;
        }
      }
    }
    return locales.first.localeId;
  }

  Future<void> _toggleVoiceSearch() async {
    HapticFeedback.selectionClick();
    _searchFocus.unfocus();
    final bn = ref.read(languageProvider);

    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final ok = await _ensureSpeech();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(bn, 'এই ফোনে ভয়েস সার্চ চালু নেই।', 'Voice search is not available on this phone.'),
          ),
        ),
      );
      return;
    }

    final localeId = await _voiceLocale(bn);
    if (!mounted) return;
    setState(() => _listening = true);

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          _search.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
          setState(() => _query = words);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.search,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          localeId: localeId,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(bn, 'ভয়েস সার্চ শুরু হয়নি।', 'Could not start voice search.'),
          ),
        ),
      );
    }
  }

  void _selectGroup(String id) {
    if (id == _group) return;
    HapticFeedback.selectionClick();
    setState(() => _group = id);
    if (_scroll.hasClients && _scroll.offset > 230) {
      _scroll.animateTo(230, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  void _openDetail(List<LibraryItem> list, int index) {
    HapticFeedback.lightImpact();
    _searchFocus.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _, _) => IdentifyDetailPage(items: list, initialIndex: index),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  bool _matches(LibraryItem item, String q) => identifyMatches(item, q);

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final catalog = ref.watch(libraryCatalogProvider);
    final stats = ref.watch(identifyStatsProvider);

    return SlmBackdrop(
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) {
          final groups = orderedCategories(items);
          if (_group != _allGroup && !groups.contains(_group)) _group = _allGroup;
          final q = _query.trim().toLowerCase();
          final counts = {for (final g in groups) g: items.where((i) => i.category == g).length};

          return Stack(
            children: [
              GestureDetector(
                onTap: _searchFocus.unfocus,
                behavior: HitTestBehavior.translucent,
                child: ShellSafeArea(
                  child: CustomScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Intro(bn: bn, stats: stats),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterBarDelegate(
                        child: _FilterBar(
                          bn: bn,
                          controller: _search,
                          focus: _searchFocus,
                          query: _query,
                          listening: _listening,
                          groups: groups,
                          counts: counts,
                          total: items.length,
                          active: _group,
                          onQuery: (v) => setState(() => _query = v),
                          onGroup: _selectGroup,
                          onVoice: _toggleVoiceSearch,
                        ),
                      ),
                    ),
                    ..._content(bn, items, groups, q),
                    SliverToBoxAdapter(
                      child: SizedBox(height: shellDockBottomInset(context) + 12),
                    ),
                  ],
                ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: shellDockBottomOffset(context),
                child: IgnorePointer(
                  ignoring: !_showPill,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    offset: _showPill ? Offset.zero : const Offset(0, 1.6),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _showPill ? 1 : 0,
                      child: Center(child: _QuizPill(bn: bn)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _content(bool bn, List<LibraryItem> items, List<String> groups, String q) {
    if (q.isNotEmpty) {
      final hits = items.where((i) => _matches(i, q)).toList();
      if (hits.isEmpty) return [_emptySliver(bn)];
      return [
        _sliverLabel(tr(bn, '${bnNumber(hits.length, bn)}টি পাওয়া গেছে', '${hits.length} found')),
        _grid(bn, hits, keyPrefix: 'q'),
      ];
    }
    if (_group != _allGroup) {
      final list = items.where((i) => i.category == _group).toList();
      if (list.isEmpty) return [_emptySliver(bn)];
      return [_grid(bn, list, keyPrefix: _group)];
    }
    return [
      for (final g in groups) ...() {
        final list = items.where((i) => i.category == g).toList();
        final preview = list.take(_sectionPreview).toList();
        return [
          SliverToBoxAdapter(
            child: _SectionHeader(
              bn: bn,
              group: g,
              count: list.length,
              showAll: list.length > preview.length,
              onAll: () => _selectGroup(g),
            ),
          ),
          _grid(bn, preview, keyPrefix: 'all-$g', openList: list),
        ];
      }(),
    ];
  }

  Widget _sliverLabel(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ),
      );

  Widget _emptySliver(bool bn) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Text(
                tr(bn, 'কিছু পাওয়া যায়নি', 'Nothing found'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 4),
              Text(
                tr(bn, 'অন্য নাম বা কাজ লিখে দেখুন', 'Try another name or use'),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );

  Widget _grid(bool bn, List<LibraryItem> list, {required String keyPrefix, List<LibraryItem>? openList}) {
    final source = openList ?? list;
    final charts = ref.watch(identifyChartPagesProvider).value;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 168,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.86,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = list[index];
            final chart = chartPageOf(charts, item.id);
            return _Appear(
              key: ValueKey('$keyPrefix-${item.id}'),
              index: index,
              child: _ItemCard(
                item: item,
                bn: bn,
                heroTag: 'lib-${item.id}',
                chart: chart,
                onTap: () => _openDetail(source, source.indexOf(item)),
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final bool bn;
  final IdentifyStats stats;

  const _Intro({required this.bn, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(bn, 'পরিচিতি', 'Identify'),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          _QuizBanner(bn: bn, stats: stats),
        ],
      ),
    );
  }
}

class _QuizBanner extends StatelessWidget {
  final bool bn;
  final IdentifyStats stats;

  const _QuizBanner({required this.bn, required this.stats});

  @override
  Widget build(BuildContext context) {
    final played = stats.lifeTotal > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pushNamed(AppRoutes.identifyPlay);
        },
        child: Ink(
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF115E59), Color(0xFF0F766E), Color(0xFF14B8A6)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x400F766E), blurRadius: 22, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: -18,
                  child: Icon(Icons.image_search_rounded, size: 120, color: Colors.white.withValues(alpha: 0.13)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr(bn, 'ছবি দেখে চিনুন', 'Name the photos'),
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              played
                                  ? tr(bn, 'সব মিলিয়ে ${bnNumber(stats.percent, bn)}% · ${bnNumber(stats.lifeTotal, bn)}টি উত্তর',
                                      'All-time ${stats.percent}% · ${stats.lifeTotal} answered')
                                  : tr(bn, 'ছোট খেলা — কতগুলো চেনেন দেখুন', 'Quick game — see how many you know'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: _teal, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    played ? tr(bn, 'আবার খেলুন', 'Play again') : tr(bn, 'খেলা শুরু', 'Start'),
                                    style: const TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (played) _ScoreRing(percent: stats.percent, bn: bn),
                    ],
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

class _ScoreRing extends StatelessWidget {
  final int percent;
  final bool bn;

  const _ScoreRing({required this.percent, required this.bn});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: 74,
        height: 74,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            Text(
              '${bnNumber((v * 100).round(), bn)}%',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterBarDelegate({required this.child});

  static const _bar = 100.0;

  @override
  double get minExtent => _bar;
  @override
  double get maxExtent => _bar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final stuck = overlapsContent || shrinkOffset > 0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: stuck ? 16 : 0, sigmaY: stuck ? 16 : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: stuck ? AppColors.cream.withValues(alpha: 0.86) : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: stuck ? const Color(0x33D6BDA4) : Colors.transparent),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) => true;
}

class _FilterBar extends StatelessWidget {
  final bool bn;
  final TextEditingController controller;
  final FocusNode focus;
  final String query;
  final bool listening;
  final List<String> groups;
  final Map<String, int> counts;
  final int total;
  final String active;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onGroup;
  final VoidCallback onVoice;

  const _FilterBar({
    required this.bn,
    required this.controller,
    required this.focus,
    required this.query,
    required this.listening,
    required this.groups,
    required this.counts,
    required this.total,
    required this.active,
    required this.onQuery,
    required this.onGroup,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final searching = query.trim().isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: SizedBox(
            height: 46,
            child: TextField(
              controller: controller,
              focusNode: focus,
              onChanged: onQuery,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 15, height: 1.3, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: listening
                    ? tr(bn, 'শুনছি… বলুন', 'Listening… speak now')
                    : tr(bn, 'নাম বা কাজ দিয়ে খুঁজুন', 'Search by name or use'),
                hintStyle: TextStyle(color: listening ? _teal : AppColors.muted),
                prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.muted),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searching && !listening)
                      IconButton(
                        tooltip: tr(bn, 'মুছুন', 'Clear'),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          controller.clear();
                          onQuery('');
                        },
                      ),
                    IconButton(
                      tooltip: listening
                          ? tr(bn, 'থামান', 'Stop')
                          : tr(bn, 'ভয়েস সার্চ', 'Voice search'),
                      onPressed: onVoice,
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: listening ? const Color(0x1A0F766E) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          size: 22,
                          color: listening ? _teal : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                filled: true,
                fillColor: listening ? const Color(0xFFF0FDFA) : Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0x40D6BDA4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: listening ? _teal.withValues(alpha: 0.45) : const Color(0x40D6BDA4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _teal, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: searching ? 0.4 : 1,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _GroupChip(
                  label: tr(bn, 'সব', 'All'),
                  count: total,
                  color: _teal,
                  selected: active == _allGroup && !searching,
                  bn: bn,
                  onTap: () => onGroup(_allGroup),
                ),
                for (final g in groups)
                  _GroupChip(
                    label: categoryLabel(g, bn),
                    count: counts[g] ?? 0,
                    color: categoryStyle(g).color,
                    selected: active == g && !searching,
                    bn: bn,
                    onTap: () => onGroup(g),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final bool bn;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.bn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : const Color(0x33D6BDA4),
              width: 1,
            ),
          ),
          child: Text(
            '$label · ${bnNumber(count, bn)}',
            style: TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool bn;
  final String group;
  final int count;
  final bool showAll;
  final VoidCallback onAll;

  const _SectionHeader({
    required this.bn,
    required this.group,
    required this.count,
    required this.showAll,
    required this.onAll,
  });

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(group);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Icon(style.icon, size: 18, color: style.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoryLabel(group, bn),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          if (showAll)
            TextButton(
              onPressed: onAll,
              style: TextButton.styleFrom(foregroundColor: style.color),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(bn, 'সব দেখুন (${bnNumber(count, bn)})', 'See all ($count)'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(bnNumber(count, bn), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _Appear extends StatelessWidget {
  final int index;
  final Widget child;

  const _Appear({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * 0.07, 0.5);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: c),
      ),
      child: child,
    );
  }
}

class _ItemCard extends StatefulWidget {
  final LibraryItem item;
  final bool bn;
  final String heroTag;
  final IdentifyChartPage? chart;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.bn,
    required this.heroTag,
    required this.onTap,
    this.chart,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final style = categoryStyle(item.category);
    final isChart = widget.chart != null || item.category == 'Charts';

    if (isChart) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _down ? 0.97 : 1,
          child: Hero(
            tag: widget.heroTag,
            child: IdentifyChartTile(
              title: item.nameBn,
              page: widget.chart,
              bn: widget.bn,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _down ? 0.97 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ColoredBox(
                  color: style.wash,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: item.hasPhoto
                            ? Hero(
                                tag: widget.heroTag,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    item.images.first,
                                    fit: BoxFit.contain,
                                    cacheWidth: 360,
                                    errorBuilder: (_, _, _) =>
                                        Icon(Icons.image_outlined, color: style.color.withValues(alpha: 0.45)),
                                  ),
                                ),
                              )
                            : ColoredBox(
                                color: style.wash,
                                child: Icon(style.icon, color: style.color),
                              ),
                      ),
                      if (item.images.length > 1)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              bnNumber(item.images.length, widget.bn),
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.nameBn,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.25,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizPill extends StatelessWidget {
  final bool bn;

  const _QuizPill({required this.bn});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _teal,
      elevation: 8,
      shadowColor: const Color(0x660F766E),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.identifyPlay),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: _teal, size: 22),
              ),
              const SizedBox(width: 8),
              Text(
                tr(bn, 'ছবি দেখে চিনুন', 'Name the photos'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
