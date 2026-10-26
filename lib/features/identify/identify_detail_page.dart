import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'identify_chart_view.dart';
import 'identify_charts.dart';
import 'identify_style.dart';
import 'library_catalog.dart';

/// Full-page item view — swipe left/right through the list it was opened from.
class IdentifyDetailPage extends ConsumerStatefulWidget {
  final List<LibraryItem> items;
  final int initialIndex;

  const IdentifyDetailPage({super.key, required this.items, required this.initialIndex});

  @override
  ConsumerState<IdentifyDetailPage> createState() => _IdentifyDetailPageState();
}

class _IdentifyDetailPageState extends ConsumerState<IdentifyDetailPage> {
  late final PageController _pages;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pages = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = _index + delta;
    if (target < 0 || target >= widget.items.length) return;
    HapticFeedback.selectionClick();
    _pages.animateToPage(target, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _openRelated(LibraryItem item) {
    HapticFeedback.lightImpact();
    final at = widget.items.indexWhere((i) => i.id == item.id);
    if (at >= 0) {
      _pages.animateToPage(at, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, _, _) => IdentifyDetailPage(items: [item], initialIndex: 0),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final all = ref.watch(libraryCatalogProvider).value ?? const <LibraryItem>[];
    final byId = {for (final i in all) i.id: i};
    final total = widget.items.length;
    final current = widget.items[_index];
    final style = categoryStyle(current.category);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            height: MediaQuery.sizeOf(context).height * 0.55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [style.soft, AppColors.cream],
              ),
            ),
          ),
          PageView.builder(
            controller: _pages,
            itemCount: total,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final related = [
                for (final id in item.relatedIds)
                  if (byId[id] != null && id != item.id) byId[id]!,
              ];
              final chart = chartPageOf(ref.watch(identifyChartPagesProvider).value, item.id);
              return _DetailBody(
                item: item,
                bn: bn,
                chart: chart,
                related: related,
                onRelated: _openRelated,
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  _GlassButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  if (total > 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: Colors.white.withValues(alpha: 0.7),
                          child: Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: _index > 0 ? () => _go(-1) : null,
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Text(
                                '${bnNumber(_index + 1, bn)} / ${bnNumber(total, bn)}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: _index < total - 1 ? () => _go(1) : null,
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.7),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, color: AppColors.ink)),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final LibraryItem item;
  final bool bn;
  final IdentifyChartPage? chart;
  final List<LibraryItem> related;
  final ValueChanged<LibraryItem> onRelated;

  const _DetailBody({
    required this.item,
    required this.bn,
    required this.related,
    required this.onRelated,
    this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(item.category);
    final top = MediaQuery.paddingOf(context).top;
    final price = item.price.trim();
    final isChart = chart != null;

    return ListView(
      padding: shellScrollPadding(context, top: top + 56, extraBottom: 20),
      children: [
        if (isChart)
          IdentifyChartBody(page: chart!, title: item.nameBn, bn: bn)
        else ...[
          item.hasPhoto
              ? _Gallery(item: item, style: style)
              : _NoPhotoHero(item: item, style: style),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(icon: style.icon, label: categoryLabel(item.category, bn), color: style.color),
                    if (price.isNotEmpty && price != '0')
                      _Tag(
                        icon: Icons.currency_rupee_rounded,
                        label: tr(bn, 'আনুমানিক ₹${bnNumber(price, bn)}', 'About ₹$price'),
                        color: const Color(0xFF92400E),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.nameBn,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink),
                ),
                if (item.functionBn.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _InfoCard(
                    icon: Icons.lightbulb_rounded,
                    title: tr(bn, 'কী কাজে লাগে', 'What it does'),
                    body: item.functionBn,
                    color: style.color,
                    background: Colors.white,
                  ),
                ],
                if (item.guideBn.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.shield_rounded,
                    title: tr(bn, 'ব্যবহার ও সতর্কতা', 'Use & safety'),
                    body: item.guideBn,
                    color: const Color(0xFF9A3412),
                    background: const Color(0xFFFFF7ED),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (related.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              tr(bn, 'সম্পর্কিত', 'Related'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: related.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _RelatedCard(item: related[i], onTap: () => onRelated(related[i])),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.identifyPlay),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFF0F766E),
              side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: Text(
              tr(bn, 'ছবি দেখে চিনুন — খেলুন', 'Play name-the-photo'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _Gallery extends StatefulWidget {
  final LibraryItem item;
  final CategoryStyle style;

  const _Gallery({required this.item, required this.style});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _photo = 0;

  void _zoom(String path) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(child: Image.asset(path, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(ctx).top + 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.item.images;
    final height = (MediaQuery.sizeOf(context).height * 0.36).clamp(220.0, 380.0);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _photo = i),
            itemBuilder: (_, i) {
              final image = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                child: _LiftedImage(path: images[i]),
              );
              return GestureDetector(
                onTap: () => _zoom(images[i]),
                child: i == 0 ? Hero(tag: 'lib-${widget.item.id}', child: image) : image,
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _photo ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _photo ? widget.style.color : widget.style.color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Soft shadow that follows the transparent cut-out so the object floats.
class _LiftedImage extends StatelessWidget {
  final String path;

  const _LiftedImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 16),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 12),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Color(0x3357534E), BlendMode.srcIn),
              child: Image.asset(path, fit: BoxFit.contain, cacheWidth: 600),
            ),
          ),
        ),
        Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, color: AppColors.muted, size: 48),
        ),
      ],
    );
  }
}

class _NoPhotoHero extends StatelessWidget {
  final LibraryItem item;
  final CategoryStyle style;

  const _NoPhotoHero({required this.item, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [style.color, Color.lerp(style.color, Colors.black, 0.25)!],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -20,
              child: Icon(style.icon, size: 150, color: Colors.white.withValues(alpha: 0.14)),
            ),
            Center(child: Icon(style.icon, size: 56, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color background;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 16, height: 1.55, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends ConsumerWidget {
  final LibraryItem item;
  final VoidCallback onTap;

  const _RelatedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final chart = chartPageOf(ref.watch(identifyChartPagesProvider).value, item.id);
    final style = categoryStyle(item.category);
    return SizedBox(
      width: 118,
      child: Material(
        color: chart != null ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: chart != null
              ? IdentifyChartTile(title: item.nameBn, page: chart, bn: bn)
              : Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: ColoredBox(
                            color: style.wash,
                            child: item.hasPhoto
                                ? Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(item.images.first, fit: BoxFit.contain, cacheWidth: 260),
                                  )
                                : Icon(style.icon, color: style.color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.nameBn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
