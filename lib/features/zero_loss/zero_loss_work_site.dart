import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zero_loss_engine.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

/// Living crew site: full-body poses, persistent orders, PTW≠LOTO, multi-cone fence.
class ZeroLossWorkSite extends ConsumerStatefulWidget {
  const ZeroLossWorkSite({super.key});

  @override
  ConsumerState<ZeroLossWorkSite> createState() => _ZeroLossWorkSiteState();
}

class _ZeroLossWorkSiteState extends ConsumerState<ZeroLossWorkSite> {
  String? _activeCrew;
  String? _sheet; // actions | ppe
  String? _beat;
  var _placeBarricade = false;
  final _found = <int>{};
  final _ppePick = <String>{};
  Timer? _beatHide;

  @override
  void dispose() {
    _beatHide?.cancel();
    super.dispose();
  }

  void _flash(String line) {
    if (line.isEmpty) return;
    _beatHide?.cancel();
    setState(() => _beat = line);
    _beatHide = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _beat = null);
    });
  }

  void _act(String action, {String? gearId}) {
    final crew = _activeCrew;
    if (crew == null && action != 'dangers_done') return;
    final game = ref.read(zeroLossProvider.notifier);

    if (action == 'barricade') {
      final block = game.siteActBlockReason('barricade', crewId: crew);
      if (block.isNotEmpty) {
        _flash(block);
        return;
      }
      setState(() {
        _placeBarricade = true;
        _sheet = null;
      });
      _flash('সাইটে ট্যাপ করে কোন বসান (২–৪টি)');
      return;
    }

    if (action != 'dangers_done' && action != 'finish') {
      final block = game.siteActBlockReason(action, crewId: crew);
      if (block.isNotEmpty) {
        _flash(block);
        return;
      }
    }
    HapticFeedback.selectionClick();
    final line = game.workSiteAct(crew ?? '', action, gearId: gearId);
    setState(() {
      if (action != 'ppe') {
        _sheet = null;
        // Keep _activeCrew so selection glow can linger; orders stay on mission.
      }
    });
    _flash(line);
  }

  void _commitPpe() {
    final crew = _activeCrew;
    if (crew == null || _ppePick.isEmpty) return;
    HapticFeedback.mediumImpact();
    final nWorn = ref.read(zeroLossProvider.notifier).wearGearBatch(crew, _ppePick.toList());
    setState(() {
      _ppePick.clear();
      _sheet = null;
    });
    _flash(nWorn > 0 ? '${n(nWorn)} কবচ পরানো হল' : 'কবচ বেছে নিন');
  }

  void _onSceneTap(TapUpDetails d, Size size) {
    if (!_placeBarricade) return;
    final x = d.localPosition.dx / size.width;
    final y = d.localPosition.dy / size.height;
    HapticFeedback.selectionClick();
    final line = ref.read(zeroLossProvider.notifier).placeBarricadeSpot(x, y);
    _flash(line);
    setState(() {});
  }

  ColorFilter? _moodFilter(JobMood? mood) => switch (mood) {
        JobMood.day => const ColorFilter.matrix(<double>[
            1.15, 0.05, 0, 0, 18, //
            0.05, 1.12, 0.02, 0, 14, //
            0, 0.04, 1.05, 0, 8, //
            0, 0, 0, 1, 0,
          ]),
        JobMood.overcast => const ColorFilter.matrix(<double>[
            0.95, 0.05, 0.05, 0, 6, //
            0.05, 0.95, 0.05, 0, 6, //
            0.05, 0.05, 1.0, 0, 10, //
            0, 0, 0, 1, 0,
          ]),
        JobMood.dusk => const ColorFilter.matrix(<double>[
            1.1, 0.08, 0, 0, 10, //
            0.04, 0.95, 0.02, 0, 0, //
            0, 0.02, 1.15, 0, 20, //
            0, 0, 0, 1, 0,
          ]),
        JobMood.storm || null => null,
      };

  Alignment _xy(double x, double y) => Alignment(x * 2 - 1, y * 2 - 1);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(zeroLossProvider)!;
    final faultId = s.activeFaultId!;
    final f = s.fault(faultId);
    final m = s.mission(faultId);
    final pack = SiteHazardPack.fromFault(f);
    final dangersDone = m.hasFlag('dangers');
    final spots = f.events.isNotEmpty ? (f.events.first.scene?.spots ?? const []) : const <SceneSpot>[];
    final pts = s.points;
    final filter = _moodFilter(f.mood);
    final game = ref.read(zeroLossProvider.notifier);
    final bloom = m.activeBloom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base plate
        Builder(
          builder: (_) {
            final img = Image.asset(
              pack.bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                f.sceneImage,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.bg),
              ),
            );
            if (filter == null) return img;
            return ColorFiltered(colorFilter: filter, child: img);
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: f.mood == JobMood.day ? 0.1 : 0.28),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),

        // Barricade place / show cones
        if (dangersDone)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final size = Size(c.maxWidth, c.maxHeight);
                return GestureDetector(
                  behavior: _placeBarricade ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                  onTapUp: _placeBarricade ? (d) => _onSceneTap(d, size) : null,
                  child: CustomPaint(
                    painter: _BarricadePainter(spots: m.barricadeSpots, closed: m.hasFlag('barricade')),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),

        // Individual cones (not one wide plate)
        if (dangersDone)
          for (final spot in m.barricadeSpots)
            Align(
              alignment: _xy(spot.$1, spot.$2),
              child: const _ConeMark(),
            ),

        if (dangersDone && m.hasFlag('earth'))
          Align(
            alignment: _xy(pack.workX - 0.14, pack.workY + 0.06),
            child: Image.asset(
              'assets/zero_loss/scene/prop_earth_set.webp',
              width: 110,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

        // LOTO lock on structure (not PTW paper)
        if (dangersDone && m.hasFlag('loto'))
          Align(
            alignment: _xy(pack.workX + 0.18, pack.workY - 0.05),
            child: Image.asset(
              'assets/zero_loss/scene/prop_lock_board.webp',
              width: 70,
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.lock_rounded, color: ZlColors.amber, size: 40),
            ),
          ),

        if (bloom == 'crowd')
          Align(
            alignment: const Alignment(0.2, 0.5),
            child: Image.asset(
              'assets/zero_loss/scene/spr_villagers.webp',
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/zero_loss/scene/overlay_crowd_walk_in.jpg',
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        if (bloom == 'vehicle')
          Align(
            alignment: const Alignment(0.55, 0.58),
            child: Image.asset(
              'assets/zero_loss/scene/prop_truck.webp',
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/zero_loss/scene/overlay_vehicle_approach.jpg',
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),

        // Full-body crew
        if (dangersDone) ..._crewBodies(s, m, pack),

        if (!dangersDone) ..._dangerLayer(spots),

        // Score + sticky beat
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xE0141C2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pts < 0 ? ZlColors.red : ZlColors.amber, width: 1.3),
                    ),
                    child: Text(
                      pts > 0 ? '+${n(pts)}' : n(pts),
                      style: zlText(18, weight: FontWeight.w900, color: pts < 0 ? ZlColors.red : ZlColors.amber),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.shortTitleBn,
                    style: zlText(11, weight: FontWeight.w700, color: ZlColors.soft).copyWith(
                      shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                  if (_beat != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _beat!,
                      textAlign: TextAlign.center,
                      style: zlText(14, weight: FontWeight.w800).copyWith(
                        shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Persistent site checklist (survives panel close)
        if (dangersDone)
          Positioned(
            left: 10,
            top: 100,
            child: _SiteChecklist(m: m, climb: pack.needsClimb),
          ),

        if (bloom != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: _sheet != null || _placeBarricade ? 220 : 118,
            child: Material(
              color: ZlColors.red.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (_activeCrew == null && m.assignedCrew.isNotEmpty) {
                    setState(() => _activeCrew = m.assignedCrew.first);
                  }
                  _act(bloom == 'crowd' || bloom == 'vehicle' ? 'clear_public' : 'handle_bloom');
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        switch (bloom) {
                          'vehicle' => Icons.directions_car_rounded,
                          'crowd' => Icons.groups_rounded,
                          'fall' => Icons.personal_injury_rounded,
                          _ => Icons.flash_on_rounded,
                        },
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          switch (bloom) {
                            'crowd' => 'লোক এসেছে — সরিয়ে দিন',
                            'vehicle' => 'গাড়ি আসছে — রাস্তা সামলান',
                            'fall' => 'পড়ে যাচ্ছেন — সামলান',
                            'shock' => 'ঝলকানি — সামলান',
                            _ => 'বিপদ! সামলান',
                          },
                          style: zlText(15, weight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (_placeBarricade)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: ZlButton(
                      label: 'শেষ কোন বাদ',
                      icon: Icons.undo_rounded,
                      color: ZlColors.soft,
                      outlined: true,
                      onTap: m.barricadeSpots.isEmpty
                          ? null
                          : () {
                              ref.read(zeroLossProvider.notifier).undoBarricadeSpot();
                              setState(() {});
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ZlButton(
                      label: m.barricadeSpots.length < 2
                          ? 'আরও কোন (${n(m.barricadeSpots.length)}/2)'
                          : 'ব্যারিকেড নিশ্চিত',
                      icon: Icons.fence_rounded,
                      onTap: m.barricadeSpots.length < 2
                          ? null
                          : () {
                              final crew = _activeCrew ?? m.assignedCrew.first;
                              final line = ref.read(zeroLossProvider.notifier).confirmBarricade(crew);
                              setState(() => _placeBarricade = false);
                              _flash(line);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_sheet != null && _activeCrew != null && !_placeBarricade)
          _ActionSheet(
            mode: _sheet!,
            pack: pack,
            bodyGear: s.scenario.bodyGear,
            kitIds: s.bodyKit(faultId),
            worn: m.wornBy(_activeCrew!),
            ppePick: _ppePick,
            blockReason: (a) => game.siteActBlockReason(a, crewId: _activeCrew),
            onClose: () => setState(() {
              _sheet = null;
              _ppePick.clear();
            }),
            onAction: (a) {
              if (a == 'ppe') {
                setState(() {
                  _sheet = 'ppe';
                  _ppePick.clear();
                });
                return;
              }
              _act(a);
            },
            onTogglePpe: (id) => setState(() {
              if (_ppePick.contains(id)) {
                _ppePick.remove(id);
              } else {
                _ppePick.add(id);
              }
            }),
            onCommitPpe: _commitPpe,
          ),

        if (!_placeBarricade)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: dangersDone
                ? ZlButton(
                    label: 'গোনা · কাজ শেষ',
                    icon: Icons.fact_check_rounded,
                    onTap: () {
                      if (_activeCrew == null && m.assignedCrew.isNotEmpty) {
                        setState(() => _activeCrew = m.assignedCrew.first);
                      }
                      _act('finish');
                    },
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spots.isEmpty ? 'সাইট দেখে নিন' : 'ছবিতে বিপদ ছুঁয়ে চিহ্নিত করুন',
                        style: zlText(14, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ZlButton(
                        label: spots.isEmpty || _found.length >= spots.length
                            ? 'কাজ শুরু'
                            : 'আরও খুঁজুন (${n(_found.length)}/${n(spots.length)})',
                        icon: Icons.play_arrow_rounded,
                        onTap: spots.isEmpty || _found.length >= (spots.length > 2 ? 2 : spots.length)
                            ? () => _act('dangers_done')
                            : null,
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  List<Widget> _crewBodies(ZeroLossState s, DispatchMission m, SiteHazardPack pack) {
    final crew = m.assignedCrew;
    final widgets = <Widget>[];
    for (var i = 0; i < crew.length; i++) {
      final id = crew[i];
      final order = m.orderOf(id);
      final (ax, ay) = _anchorFor(order, pack, i, crew.length);
      final selected = _activeCrew == id;
      widgets.add(
        Align(
          alignment: _xy(ax, ay),
          child: GestureDetector(
            onTap: () => setState(() {
              _activeCrew = id;
              _placeBarricade = false;
              _sheet = m.activeBloom != null && m.activeBloom != 'crowd' && m.activeBloom != 'vehicle'
                  ? null
                  : 'actions';
              _ppePick.clear();
            }),
            child: _BodyWorker(
              man: s.lineman(id),
              order: order,
              selected: selected,
              wornCount: m.wornBy(id).length,
              kitCount: s.bodyKit(s.activeFaultId!).length,
            ),
          ),
        ),
      );
      // PTW paper in hands while checking
      if (order == 'ptw') {
        widgets.add(
          Align(
            alignment: _xy(ax + 0.08, ay - 0.06),
            child: Image.asset(
              'assets/zero_loss/scene/gear_ptw.webp',
              width: 36,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.description_rounded, color: Colors.white, size: 28),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  (double, double) _anchorFor(String order, SiteHazardPack pack, int index, int total) {
    final spread = total <= 1 ? 0.0 : (index / (total - 1) - 0.5) * 0.28;
    return switch (order) {
      'climb' => (pack.climbX + spread * 0.3, pack.climbY),
      'work' => (pack.workX + spread * 0.4, pack.workY),
      'earth' => (pack.workX - 0.1 + spread, pack.workY + 0.02),
      'loto' => (pack.workX + 0.12 + spread * 0.2, pack.workY - 0.02),
      'ptw' => (0.22 + index * 0.12, 0.62),
      'barricade' => (0.35 + index * 0.15, 0.72),
      'clear_public' => (0.65 + spread, 0.58),
      'ppe' => (0.28 + index * 0.22, 0.68),
      _ => (0.3 + index * 0.25, 0.7),
    };
  }

  List<Widget> _dangerLayer(List<SceneSpot> spots) {
    if (spots.isEmpty) return const [];
    return [
      for (var i = 0; i < spots.length; i++)
        Align(
          alignment: Alignment(spots[i].x * 2 - 1, spots[i].y * 2 - 1),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _found.add(i));
              _flash(spots[i].labelBn.isEmpty ? 'বিপদ চিহ্নিত' : spots[i].labelBn);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _found.contains(i) ? 0.35 : 1,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_found.contains(i) ? ZlColors.green : ZlColors.red).withValues(alpha: 0.55),
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                child: Icon(
                  _found.contains(i) ? Icons.check_rounded : Icons.priority_high_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

/// Full-body figure + order label (no face circle as main UI).
class _BodyWorker extends StatelessWidget {
  final SmartLineman man;
  final String order;
  final bool selected;
  final int wornCount;
  final int kitCount;

  const _BodyWorker({
    required this.man,
    required this.order,
    required this.selected,
    required this.wornCount,
    required this.kitCount,
  });

  String get _orderBn => switch (order) {
        'ppe' => 'কবচ',
        'barricade' => 'ব্যারিকেড',
        'ptw' => 'PTW পড়ছে',
        'earth' => 'আর্থ',
        'loto' => 'LOTO লাগাচ্ছে',
        'climb' => 'খুঁটিতে',
        'work' => 'কাজে',
        'clear_public' => 'লোক সরাচ্ছে',
        _ => 'অপেক্ষায়',
      };

  String get _poseAsset => switch (order) {
        'climb' => 'assets/zero_loss/scene/spr_man_climb.webp',
        'work' => 'assets/zero_loss/scene/spr_man_tester.webp',
        'earth' => 'assets/zero_loss/scene/spr_man_earth.webp',
        'loto' => 'assets/zero_loss/scene/spr_man_point.webp',
        'ptw' => 'assets/zero_loss/scene/spr_man_phone.webp', // careful check stance
        'barricade' => 'assets/zero_loss/scene/spr_man_point.webp',
        'clear_public' => 'assets/zero_loss/scene/spr_man_stop.webp',
        'ppe' => 'assets/zero_loss/scene/spr_man_stop.webp',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final pose = _poseAsset;
    return AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: const Duration(milliseconds: 180),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: order == 'climb' ? 150 : 130,
            child: pose.isEmpty
                ? (man.art.isNotEmpty
                    ? Image.asset(man.art, fit: BoxFit.contain, alignment: Alignment.bottomCenter)
                    : CrewFigure(man: man))
                : Image.asset(
                    pose,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => man.art.isNotEmpty
                        ? Image.asset(man.art, fit: BoxFit.contain)
                        : CrewFigure(man: man),
                  ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xCC0B1220),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? ZlColors.amber : ZlColors.line),
            ),
            child: Column(
              children: [
                Text(man.name, style: zlText(11, weight: FontWeight.w900)),
                Text(
                  order == 'ppe' ? '$_orderBn · $wornCount/$kitCount' : _orderBn,
                  style: zlText(10, weight: FontWeight.w700, color: order.isEmpty ? ZlColors.soft : ZlColors.amber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteChecklist extends StatelessWidget {
  final DispatchMission m;
  final bool climb;

  const _SiteChecklist({required this.m, required this.climb});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      ('ppe', 'কবচ', m.hasFlag('ppe')),
      ('barricade', 'ফিতে', m.hasFlag('barricade')),
      ('ptw', 'PTW', m.hasFlag('ptw')),
      ('earth', 'আর্থ', m.hasFlag('earth')),
      ('loto', 'LOTO', m.hasFlag('loto')),
      if (climb) ('climb', 'উঠুন', m.hasFlag('climbed')),
      ('work', 'কাজ', m.hasFlag('worked')),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZlColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (id, label, ok) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 14,
                    color: ok ? ZlColors.green : ZlColors.soft,
                  ),
                  const SizedBox(width: 4),
                  Text(label, style: zlText(11, weight: FontWeight.w700, color: ok ? ZlColors.green : ZlColors.soft)),
                  // silence unused id warning
                  if (id.isEmpty) const SizedBox.shrink(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ConeMark extends StatelessWidget {
  const _ConeMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 40,
      child: CustomPaint(painter: _SingleConePainter()),
    );
  }
}

class _SingleConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.92, size.height * 0.78)
      ..lineTo(size.width * 0.08, size.height * 0.78)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF97316));
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.78, size.width * 0.76, size.height * 0.18),
      Paint()..color = const Color(0xFFEA580C),
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.35),
      Offset(size.width * 0.78, size.height * 0.35),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarricadePainter extends CustomPainter {
  final List<(double, double)> spots;
  final bool closed;

  _BarricadePainter({required this.spots, required this.closed});

  @override
  void paint(Canvas canvas, Size size) {
    if (spots.length < 2) return;
    final path = Path();
    for (var i = 0; i < spots.length; i++) {
      final p = Offset(spots[i].$1 * size.width, spots[i].$2 * size.height - 30);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final red = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE11D48);
    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white70;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      var drawRed = true;
      while (d < metric.length) {
        final next = math.min(d + (drawRed ? 9.0 : 5.0), metric.length);
        canvas.drawPath(metric.extractPath(d, next), drawRed ? red : white);
        d = next;
        drawRed = !drawRed;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarricadePainter old) => old.spots != spots || old.closed != closed;
}

class _ActionSheet extends StatelessWidget {
  final String mode;
  final SiteHazardPack pack;
  final List<Gear> bodyGear;
  final List<String> kitIds;
  final List<String> worn;
  final Set<String> ppePick;
  final String Function(String action) blockReason;
  final VoidCallback onClose;
  final ValueChanged<String> onAction;
  final ValueChanged<String> onTogglePpe;
  final VoidCallback onCommitPpe;

  const _ActionSheet({
    required this.mode,
    required this.pack,
    required this.bodyGear,
    required this.kitIds,
    required this.worn,
    required this.ppePick,
    required this.blockReason,
    required this.onClose,
    required this.onAction,
    required this.onTogglePpe,
    required this.onCommitPpe,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: const Color(0xF0131C2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(mode == 'ppe' ? 'কবচ বাছুন (একাধিক)' : 'নির্দেশ দিন', style: zlText(16, weight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: ZlColors.soft)),
                  ],
                ),
                if (mode == 'ppe') ...[
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: bodyGear.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final g = bodyGear[i];
                        final on = worn.contains(g.id);
                        final pick = ppePick.contains(g.id);
                        final need = kitIds.contains(g.id);
                        return GestureDetector(
                          onTap: on ? null : () => onTogglePpe(g.id),
                          child: Opacity(
                            opacity: on ? 0.45 : 1,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: pick
                                              ? ZlColors.amber
                                              : need
                                                  ? ZlColors.green.withValues(alpha: 0.5)
                                                  : ZlColors.line,
                                          width: pick ? 2.5 : 1.2,
                                        ),
                                      ),
                                      child: GearPicture(gear: g, size: 56, plain: true),
                                    ),
                                    if (pick || on)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: on ? ZlColors.green : ZlColors.amber,
                                          child: Icon(on ? Icons.check : Icons.add, size: 12, color: ZlColors.bg),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 72,
                                  child: Text(g.nameBn, maxLines: 2, textAlign: TextAlign.center, style: zlText(10, weight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ZlButton(
                    label: ppePick.isEmpty ? 'কবচ ট্যাপ করে বাছুন' : 'পরান · ${n(ppePick.length)}টি',
                    icon: Icons.checkroom_rounded,
                    onTap: ppePick.isEmpty ? null : onCommitPpe,
                  ),
                ] else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (id, label, icon) in [
                        ('ppe', 'কবচ', Icons.health_and_safety_rounded),
                        ('barricade', 'ব্যারিকেড', Icons.fence_rounded),
                        ('ptw', 'PTW পড়ুন', Icons.menu_book_rounded),
                        ('earth', 'আর্থ', Icons.electrical_services_rounded),
                        ('loto', 'LOTO', Icons.lock_rounded),
                        if (pack.needsClimb) ('climb', 'উঠুন', Icons.stairs_rounded),
                        ('work', 'কাজ', Icons.handyman_rounded),
                        ('clear_public', 'লোক সরান', Icons.directions_walk_rounded),
                      ])
                        _ActTile(
                          label: label,
                          icon: icon,
                          reason: blockReason(id),
                          onTap: () => onAction(id),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String reason;
  final VoidCallback onTap;

  const _ActTile({
    required this.label,
    required this.icon,
    required this.reason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = reason.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: locked ? 0.42 : 1,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: ZlColors.panelHi,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: locked ? ZlColors.line : ZlColors.amber.withValues(alpha: 0.45)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: locked ? ZlColors.soft : ZlColors.amber),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: zlText(11, weight: FontWeight.w800)),
              if (locked)
                Text(reason, maxLines: 2, textAlign: TextAlign.center, style: zlText(9, color: ZlColors.soft)),
            ],
          ),
        ),
      ),
    );
  }
}
