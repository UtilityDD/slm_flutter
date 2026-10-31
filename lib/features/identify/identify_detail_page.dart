import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/slm_design.dart';
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            height: MediaQuery.sizeOf(context).height * 0.55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [style.color.withValues(alpha: 0.22), style.color.withValues(alpha: 0)],
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
                          decoration: BoxDecoration(
                            color: SlmColors.navy900.withValues(alpha: 0.72),
                            borderRadius: SlmRadius.pillAll,
                            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                color: SlmColors.ivory,
                                disabledColor: SlmColors.slate.withValues(alpha: 0.5),
                                onPressed: _index > 0 ? () => _go(-1) : null,
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Text(
                                '${bnNumber(_index + 1, bn)} / ${bnNumber(total, bn)}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: SlmColors.gold200),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                color: SlmColors.ivory,
                                disabledColor: SlmColors.slate.withValues(alpha: 0.5),
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
          color: SlmColors.navy900.withValues(alpha: 0.72),
          shape: CircleBorder(side: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.45))),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, color: SlmColors.ivory)),
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
          SlmReveal(child: IdentifyChartBody(page: chart!, title: item.nameBn, bn: bn))
        else ...[
          item.hasPhoto
              ? _Gallery(item: item, style: style)
              : _NoPhotoHero(item: item, style: style),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlmReveal(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        icon: style.icon,
                        label: categoryLabel(item.category, bn),
                        color: Color.lerp(style.color, Colors.white, 0.3)!,
                      ),
                      if (price.isNotEmpty && price != '0')
                        _Tag(
                          icon: Icons.currency_rupee_rounded,
                          label: tr(bn, 'আনুমানিক ₹${bnNumber(price, bn)}', 'About ₹$price'),
                          color: SlmColors.gold300,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SlmReveal(
                  index: 1,
                  child: Text(
                    item.nameBn,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: SlmColors.ivory,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                  ),
                ),
                if (item.functionBn.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  SlmReveal(
                    index: 2,
                    child: _InfoCard(
                      icon: Icons.lightbulb_rounded,
                      title: tr(bn, 'কী কাজে লাগে', 'What it does'),
                      body: item.functionBn,
                      color: SlmColors.gold700,
                    ),
                  ),
                ],
                if (item.guideBn.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SlmReveal(
                    index: 3,
                    child: _InfoCard(
                      icon: Icons.shield_rounded,
                      title: tr(bn, 'ব্যবহার ও সতর্কতা', 'Use & safety'),
                      body: item.guideBn,
                      color: const Color(0xFFB4441E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (related.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(gradient: SlmGradients.gold, borderRadius: SlmRadius.pillAll),
                ),
                const SizedBox(width: 8),
                Text(
                  tr(bn, 'সম্পর্কিত', 'Related'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 156,
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
          child: Theme(
            data: SlmTheme.night(),
            child: SlmButton.gold(
              label: tr(bn, 'ছবি দেখে চিনুন — খেলুন', 'Play name-the-photo'),
              icon: Icons.play_circle_fill_rounded,
              expand: true,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.identifyPlay),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(1.3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: SlmGradients.goldEdge,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 26, offset: const Offset(0, 12)),
                BoxShadow(color: widget.style.color.withValues(alpha: 0.18), blurRadius: 30),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.7),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 0.9,
                    colors: [Colors.white, SlmColors.ivory, Color.lerp(SlmColors.ivoryDeep, widget.style.color, 0.07)!],
                    stops: const [0, 0.45, 1],
                  ),
                ),
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _photo = i),
                  itemBuilder: (_, i) {
                    final image = Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      child: _LiftedImage(path: images[i]),
                    );
                    return GestureDetector(
                      onTap: () => _zoom(images[i]),
                      child: i == 0 ? Hero(tag: 'lib-${widget.item.id}', child: image) : image,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: SlmMotion.base,
                    curve: SlmMotion.emphasized,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _photo ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: i == _photo ? SlmGradients.gold : null,
                      color: i == _photo ? null : SlmColors.navy600,
                      borderRadius: SlmRadius.pillAll,
                      boxShadow: i == _photo
                          ? [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.5), blurRadius: 6)]
                          : null,
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
          errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, color: SlmColors.slate, size: 48),
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
        color: SlmColors.navy800.withValues(alpha: 0.9),
        borderRadius: SlmRadius.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.5)),
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

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SlmColors.ivory, SlmColors.ivoryDeep],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.15)]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
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
                    style: const TextStyle(fontSize: 16, height: 1.55, fontWeight: FontWeight.w500, color: SlmColors.ink),
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
      child: SlmPressable(
        pressedScale: 0.96,
        onTap: onTap,
        child: chart != null
            ? IdentifyChartTile(title: item.nameBn, page: chart, bn: bn)
            : Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: SlmGradients.navyCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [SlmColors.ivory, Color.lerp(SlmColors.ivoryDeep, style.color, 0.06)!],
                            ),
                          ),
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
                      style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
