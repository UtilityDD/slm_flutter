import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/level_lessons_sheet.dart' show playLessonCue;
import '../identify/library_catalog.dart';
import 'zero_loss_engine.dart';
import 'zero_loss_fx.dart';
import 'zero_loss_models.dart';
import 'zero_loss_scene.dart';
import 'zero_loss_stress.dart';
import 'zero_loss_ui.dart';

// ---------------------------------------------------------------------------
// Yard load: big van + easy grid of PPE/tools (incl. Parichiti library).
// ---------------------------------------------------------------------------

/// Parichiti library cutouts (webp under assets/) — prefer these over scene gear art.
const _parichitiImageBoost = <String, String>{
  'helmet': 'assets/safety/library/ppe/Safety_Helmet.webp',
  'gloves': 'assets/safety/library/ppe/Electrical_Gloves.webp',
  'boots': 'assets/safety/library/ppe/Lineman_Boot_2.webp',
  'harness': 'assets/safety/library/ppe/Full_Body_Harness_2.webp',
  'waist_belt': 'assets/safety/safety_belt.webp',
  'tester': 'assets/safety/library/tools/High_Voltage_Detector_2.webp',
  'earth_rods': 'assets/safety/library/ppe/Portable_Earth_Rod.webp',
  'lock_board': 'assets/safety/library/ppe/LOTO_Kit.webp',
  'tape_cones': 'assets/safety/library/ppe/Traffic_Cone_with_Chain.webp',
  'goggles': 'assets/safety/library/ppe/Arc_Flash_Face_Shield.webp',
  'frp_ladder': 'assets/safety/library/ppe/FRP_Ladder_2.webp',
  'rope': 'assets/safety/library/ppe/Manila_Rope.webp',
  'spare_insulator': 'assets/safety/library/insulators/Porcelain_Pin_2.webp',
  'wire_grip': 'assets/safety/library/tools/come_along_clamp.webp',
  'bamboo_ladder': 'assets/safety/library/ppe/Bamboo_Ladder.webp',
  'plain_pliers': 'assets/safety/library/tools/Combination_Pliers.webp',
  'discharge_rod': 'assets/safety/library/ppe/discharge_rod.webp',
  'ipc_clamp': 'assets/safety/library/ab-cable-items/ipc.webp',
  'torque_wrench': 'assets/safety/library/tools/Torque_Wrench.webp',
  'high_vis_vest': 'assets/safety/library/ppe/High_Visibility_Vest_3.webp',
  'high_lumen_torch': 'assets/safety/library/ppe/Helmet_Mounted_Torch_2.webp',
  'fuse_wire': 'assets/safety/library/others/Horn_Gap_Fuse.webp',
  'tree_saw': 'assets/safety/library/tools/Hacksaw.webp',
};

/// First usable Parichiti plate: bundled `assets/…webp` only (skip remote `/images` paths).
String? _parichitiWebp(LibraryItem item) {
  for (final img in item.images) {
    final lower = img.toLowerCase();
    if (!img.startsWith('assets/')) continue;
    if (!lower.endsWith('.webp')) continue;
    // Prefer library product cutouts; skip quiz photo plates / mistakes.
    if (lower.contains('/quizzes/img_') || lower.contains('mistake_')) continue;
    return img;
  }
  return null;
}

class ZeroLossLoadingView extends ConsumerStatefulWidget {
  const ZeroLossLoadingView({super.key});

  @override
  ConsumerState<ZeroLossLoadingView> createState() => _ZeroLossLoadingViewState();
}

class _ZeroLossLoadingViewState extends ConsumerState<ZeroLossLoadingView> {
  Timer? _timer;
  Timer? _nameTimer;
  List<Gear>? _yard;
  var _yardUsedLib = false;
  String? _namedId;
  int _prevPoints = 0;

  @override
  void initState() {
    super.initState();
    final s = ref.read(zeroLossProvider)!;
    _prevPoints = s.points;
    ZlFx.holdClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(zeroLossProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameTimer?.cancel();
    ZlFx.releaseClock();
    super.dispose();
  }

  List<Gear> _buildYard(ZeroLossState s, List<LibraryItem>? lib) {
    final rng = Random(s.seed + 17);
    final fault = s.fault(s.activeFaultId!);
    final need = {...fault.requiredGear, ...fault.jobGear, ...s.scenario.bodyKitFor(fault)};

    Gear boost(Gear g) {
      final img = _parichitiImageBoost[g.id];
      if (img == null || img == g.image) return g;
      return Gear(
        id: g.id,
        nameBn: g.nameBn,
        image: img,
        emoji: g.emoji,
        icon: g.icon,
        kind: g.kind,
        area: g.area,
        bodySlot: g.bodySlot,
        mantra: g.mantra,
        decoyNoteBn: g.decoyNoteBn,
        cause: g.cause,
      );
    }

    bool isParichitiPlate(String image) =>
        image.startsWith('assets/safety/') && image.toLowerCase().endsWith('.webp');

    final fromScenario = [for (final g in s.scenario.gear) boost(g)];
    final fromLib = <Gear>[];
    if (lib != null) {
      for (final item in lib) {
        if (item.category != 'PPE' && item.category != 'Tools') continue;
        final img = _parichitiWebp(item);
        if (img == null) continue;
        final id = 'lib_${item.id}';
        // Skip near-duplicates of scenario kit (same plate or same Bangla name).
        if (fromScenario.any((g) => g.nameBn == item.nameBn || g.image == img)) continue;
        fromLib.add(Gear(
          id: id,
          nameBn: item.nameBn,
          image: img,
          emoji: '',
          kind: item.category == 'PPE' ? GearKind.safety : GearKind.tool,
          area: GearArea.truck,
          mantra: item.category == 'PPE' ? 'armour' : 'mend',
        ));
      }
    }

    final must = [for (final id in need) boost(s.scenario.gearById(id))];
    // Extra tiles: only Parichiti webp cutouts (no leftover scene gear art).
    final rest = [
      ...fromScenario.where((g) => !need.contains(g.id) && isParichitiPlate(g.image)),
      ...fromLib,
    ]..shuffle(rng);

    final seen = <String>{};
    final mix = <Gear>[
      for (final g in [...must, ...rest])
        if (seen.add(g.id)) g,
    ]..shuffle(rng);
    return mix;
  }

  void _pack(Gear g) {
    final s = ref.read(zeroLossProvider)!;
    final m = s.mission(s.activeFaultId!);
    if (m.isPacked(g.id) || m.packedGear.length >= s.scenario.truckCapacity) return;
    HapticFeedback.selectionClick();
    setState(() => _namedId = g.id);
    _nameTimer?.cancel();
    _nameTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _namedId = null);
    });
    final offer = s.scenario.gear.any((x) => x.id == g.id) ? null : g;
    ref.read(zeroLossProvider.notifier).toggleGear(g.id, offer: offer);
  }

  void _unload(String id) {
    HapticFeedback.selectionClick();
    ref.read(zeroLossProvider.notifier).toggleGear(id);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(zeroLossProvider)!;
    final lib = ref.watch(libraryCatalogProvider).value;
    if (_yard == null || (lib != null && !_yardUsedLib)) {
      _yard = _buildYard(s, lib);
      _yardUsedLib = lib != null;
    }

    final faultId = s.activeFaultId!;
    final m = s.mission(faultId);
    final cap = s.scenario.truckCapacity;
    final pts = s.points;
    final ptsDelta = pts - _prevPoints;
    if (pts != _prevPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _prevPoints = pts);
      });
    }

    final loose = [for (final g in _yard!) if (!m.isPacked(g.id)) g];

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Row(
                children: [
                  _TickTock(left: m.remainingTimeSeconds),
                  const Spacer(),
                  _AnimatedScore(points: pts, flash: ptsDelta),
                ],
              ),
            ),
            // Van bed — every packed item stays visible / scrollable to unload
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: _BigVan(gear: m.packedGear, capacity: cap, onRemove: _unload),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                gridDelegate: const SpacedGridDelegate(
                  crossAxisCount: 4,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
                itemCount: loose.length,
                itemBuilder: (_, i) {
                  final g = loose[i];
                  final full = m.packedGear.length >= cap;
                  return _YardTile(
                    gear: g,
                    showName: _namedId == g.id,
                    dimmed: full,
                    onTap: full ? null : () => _pack(g),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ZlButton(
                label: 'রওনা দিন',
                icon: Icons.local_shipping_rounded,
                onTap: s.pendingCheck == null ? ref.read(zeroLossProvider.notifier).dispatchTruck : null,
              ),
            ),
          ],
        ),
        if (s.pendingCheck != null) Positioned.fill(child: _MissingGearSheet(state: s, check: s.pendingCheck!)),
      ],
    );
  }
}

/// Simple spaced grid without importing extra packages.
class SpacedGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  const SpacedGridDelegate({
    required super.crossAxisCount,
    required super.mainAxisSpacing,
    required super.crossAxisSpacing,
    required super.childAspectRatio,
  });
}

class _YardTile extends StatelessWidget {
  final Gear gear;
  final bool showName;
  final bool dimmed;
  final VoidCallback? onTap;

  const _YardTile({
    required this.gear,
    required this.showName,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Material(
        color: ZlColors.panelHi,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: LayoutBuilder(
              builder: (_, box) {
                final side = min(box.maxWidth, box.maxHeight) - (showName ? 12 : 0);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    GearPicture(gear: gear, size: side.clamp(36, 96), plain: true),
                    if (showName)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                          color: const Color(0xCC0B1220),
                          child: Text(
                            gear.nameBn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: zlText(9, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TickTock extends StatelessWidget {
  final int left;

  const _TickTock({required this.left, int? total});

  @override
  Widget build(BuildContext context) {
    final urgent = left <= 10;
    final c = urgent ? ZlColors.amber : ZlColors.soft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 22, color: c),
        const SizedBox(width: 6),
        Text(n(left), style: zlText(22, weight: FontWeight.w900, color: c, height: 1)),
        Text('″', style: zlText(14, weight: FontWeight.w700, color: c)),
      ],
    );
  }
}

class _AnimatedScore extends StatelessWidget {
  final int points;
  final int flash;

  const _AnimatedScore({required this.points, required this.flash});

  @override
  Widget build(BuildContext context) {
    final c = points < 0 ? ZlColors.red : ZlColors.amber;
    return TweenAnimationBuilder<double>(
      key: ValueKey(points),
      tween: Tween(begin: (points - flash).toDouble(), end: points.toDouble()),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => AnimatedScale(
        scale: flash != 0 ? 1.12 : 1,
        duration: const Duration(milliseconds: 200),
        child: Text(
          v > 0 ? '+${n(v.round())}' : n(v.round()),
          style: zlText(26, weight: FontWeight.w900, color: c, height: 1),
        ),
      ),
    );
  }
}

/// Van bed — wraps every packed item so each can be tapped to unload.
class _BigVan extends StatelessWidget {
  final List<Gear> gear;
  final int capacity;
  final ValueChanged<String> onRemove;

  const _BigVan({required this.gear, required this.capacity, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    // Grow with load; scroll if many so nothing is cut off.
    final rows = gear.isEmpty ? 1 : ((gear.length + 4) ~/ 5).clamp(1, 4);
    final bedH = 8.0 + rows * 46.0;

    return Container(
      constraints: BoxConstraints(minHeight: 72, maxHeight: 28 + bedH),
      decoration: BoxDecoration(
        color: ZlColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZlColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ভ্যান · ${n(gear.length)}/${n(capacity)} · ছুঁয়ে নামান', style: zlText(11, weight: FontWeight.w800, color: ZlColors.soft)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: gear.isEmpty
                        ? Center(child: Text('নিচে থেকে তুলুন', style: zlText(11, color: ZlColors.soft)))
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final g in gear)
                                  GestureDetector(
                                    onTap: () => onRemove(g.id),
                                    child: PopIn(
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: ZlColors.panelHi,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: ZlColors.amber.withValues(alpha: 0.55)),
                                        ),
                                        child: GearPicture(gear: g, size: 32, plain: true),
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
          ),
          Container(
            width: 56,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ZlColors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF0B1220), size: 28),
          ),
        ],
      ),
    );
  }
}

class _MissingGearSheet extends ConsumerWidget {
  final ZeroLossState state;
  final DispatchCheck check;

  const _MissingGearSheet({required this.state, required this.check});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.read(zeroLossProvider.notifier);
    final sc = state.scenario;
    final items = [
      for (final g in check.missingSafety) (g, ZlColors.red, mantraIcon(g.mantra)),
      for (final g in check.missingJob) (g, ZlColors.amber, Icons.schedule_rounded),
      for (final g in check.decoys) (g, ZlColors.orange, Icons.block_rounded),
    ];
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: PopIn(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: const BoxDecoration(
              color: ZlColors.panel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(top: BorderSide(color: ZlColors.red, width: 3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.front_hand_rounded, color: ZlColors.red, size: 44),
                const SizedBox(height: 4),
                Text('থামুন! ট্রাকে নেই', style: zlText(19, weight: FontWeight.w900)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final (g, c, icon) in items)
                      SizedBox(
                        width: 78,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: c, width: 2)),
                                  child: GearPicture(gear: g, size: 60),
                                ),
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: CircleAvatar(radius: 12, backgroundColor: c, child: Icon(icon, size: 14, color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(g.nameBn, textAlign: TextAlign.center, maxLines: 2, style: zlText(11, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (check.missingSafety.isNotEmpty)
                      ZlTag(label: 'ঝুঁকি +${pct(check.missingSafety.length * sc.missingGearRisk)}', color: ZlColors.red, icon: Icons.warning_rounded),
                    if (check.missingJob.isNotEmpty)
                      ZlTag(label: '+${n(sc.reloadMinutes * 2)} মিনিট', color: ZlColors.amber, icon: Icons.schedule_rounded),
                    if (check.decoys.isNotEmpty) const ZlTag(label: 'ভুল জিনিস', color: ZlColors.orange, icon: Icons.block_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                ZlButton(
                  label: 'আবার লোড  ·  +${n(sc.reloadMinutes)} মিনিট',
                  icon: Icons.replay_rounded,
                  color: ZlColors.green,
                  onTap: game.reloadTruck,
                ),
                const SizedBox(height: 10),
                ZlButton(
                  label: 'এভাবেই যাব',
                  icon: Icons.warning_amber_rounded,
                  color: ZlColors.red,
                  outlined: true,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    game.takeShortcut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// On site: one hazard at a time.
// ---------------------------------------------------------------------------

class ZeroLossSiteView extends ConsumerStatefulWidget {
  final VoidCallback onReplayVoice;

  const ZeroLossSiteView({super.key, required this.onReplayVoice});

  @override
  ConsumerState<ZeroLossSiteView> createState() => _ZeroLossSiteViewState();
}

class _ZeroLossSiteViewState extends ConsumerState<ZeroLossSiteView> {
  late bool _arrived;
  bool _why = false;
  String? _eventId;
  final _found = <int>{};
  bool _hunted = false;

  /// Duty mode: what the crew says right after an order, before moving on.
  String? _beat;
  bool _hesitant = false;
  Timer? _beatTimer;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    final s = ref.read(zeroLossProvider)!;
    _arrived = s.mission(s.activeFaultId!).decisions.isNotEmpty;
    ZlFx.holdClock();
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    ref.read(zlVoiceProvider).stop();
    ZlFx.releaseClock();
    super.dispose();
  }

  void _choose(ZeroLossState s, HazardOption o) {
    ref.read(zlVoiceProvider).stop();
    final game = ref.read(zeroLossProvider.notifier);
    playLessonCue(o.best);
    HapticFeedback.selectionClick();
    setState(() => _why = false);
    game.chooseOption(o.id);
    if (!s.duty) return;
    final lines = s.scenario.hesitationBn;
    _hesitant = !o.best && lines.isNotEmpty && _rng.nextDouble() < 0.6;
    setState(() => _beat = _hesitant ? lines[_rng.nextInt(lines.length)] : 'ঠিক আছে, তাই হোক।');
    if (_hesitant) {
      HapticFeedback.mediumImpact();
      ref.read(zlVoiceProvider).say(_beat!);
    }
    _beatTimer?.cancel();
    _beatTimer = Timer(Duration(milliseconds: _hesitant ? 2600 : 1200), () {
      if (!mounted) return;
      ref.read(zlVoiceProvider).stop();
      setState(() => _beat = null);
      game.continueAfterFeedback();
    });
  }

  void _syncEvent(HazardEvent e, bool picked) {
    if (_eventId == e.id) return;
    _eventId = e.id;
    _found.clear();
    _why = false;
    _hunted = picked || (e.scene?.spots.isEmpty ?? true);
  }

  void _onFound(HazardEvent e, int i) {
    playLessonCue(true);
    setState(() => _found.add(i));
    if (_found.length == e.scene!.spots.length) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _eventId == e.id) setState(() => _hunted = true);
      });
    }
  }

  void _revealAll(HazardEvent e) {
    setState(() {
      _found.addAll(List.generate(e.scene!.spots.length, (i) => i));
      _hunted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(zeroLossProvider)!;
    final faultId = s.activeFaultId!;
    final m = s.mission(faultId);

    if (!_arrived) {
      return _TravelIntro(
        location: m.location,
        weather: s.setting.region.weatherShortBn,
        onDone: () {
          if (!mounted) return;
          setState(() => _arrived = true);
          widget.onReplayVoice();
        },
      );
    }

    final game = ref.read(zeroLossProvider.notifier);
    final f = s.fault(faultId);
    final event = f.events[m.eventIndex];
    final picked = s.pendingFeedback;
    _syncEvent(event, picked != null);
    final scene = event.scene;
    final hunting = scene != null && !_hunted && picked == null;

    final Widget panel;
    if (hunting) {
      panel = _HuntBar(
        key: ValueKey('hunt-${event.id}'),
        found: _found.length,
        total: scene.spots.length,
        onReveal: () => _revealAll(event),
      );
    } else if (picked == null) {
      panel = Column(
        key: ValueKey('opts-${event.id}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < event.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PopIn(
                key: ValueKey('${event.id}-${event.options[i].id}'),
                delay: Duration(milliseconds: 90 * i),
                child: _OptionTile(
                  option: event.options[i],
                  picked: null,
                  onHear: () {
                    final voice = ref.read(zlVoiceProvider);
                    voice.stop();
                    voice.say(s.fillFor(faultId, event.options[i].textBn));
                  },
                  onTap: () => _choose(s, event.options[i]),
                ),
              ),
            ),
        ],
      );
    } else if (s.duty) {
      panel = _DutyBeat(
        key: ValueKey('beat-${event.id}'),
        man: s.leadOf(faultId),
        order: s.fillFor(faultId, picked.shortBn.isEmpty ? picked.textBn : picked.shortBn),
        reply: _beat ?? '',
        hesitant: _hesitant,
      );
    } else {
      panel = Column(
        key: ValueKey('fb-${event.id}'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Feedback(
            option: picked,
            mantra: s.scenario.mantra(event.mantra),
            why: _why,
            onWhy: () => setState(() => _why = !_why),
          ),
          const SizedBox(height: 10),
          ZlButton(
            label: m.eventIndex + 1 < f.events.length ? 'পরের ধাপ' : 'কাজ শেষ',
            icon: Icons.arrow_forward_rounded,
            onTap: game.continueAfterFeedback,
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              Expanded(child: MantraRail(scenario: s.scenario, report: s.mantraReport(faultId), activeId: event.mantra, compact: true)),
              const SizedBox(width: 8),
              StressClock(minute: s.finishMinute(faultId), limit: f.urgencyMinutes, size: 44),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: _SpeakerLine(
            key: ValueKey('say-${event.id}'),
            state: s,
            faultId: faultId,
            event: event,
            onReplay: widget.onReplayVoice,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Stack(
                key: ValueKey('scene-${event.id}'),
                fit: StackFit.expand,
                children: [
                  if (scene != null)
                    ZlScene(
                      plan: scene,
                      picked: s.duty ? null : picked,
                      found: _found,
                      hunting: hunting,
                      onFound: (i) => _onFound(event, i),
                      roles: {'lead': s.leadOf(faultId), 'junior': s.juniorOf(faultId)},
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(event.image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.panelHi)),
                    ),
                  if (event.alertBn.isNotEmpty)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: IgnorePointer(child: _PulsingAlert(text: s.fillFor(faultId, event.alertBn))),
                    ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.42),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: panel),
            ),
          ),
        ),
      ],
    );
  }
}

/// Duty mode: the order given, and the crew's reply. A careful senior may hesitate.
class _DutyBeat extends StatelessWidget {
  final SmartLineman? man;
  final String order;
  final String reply;
  final bool hesitant;

  const _DutyBeat({super.key, required this.man, required this.order, required this.reply, required this.hesitant});

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: ZlPanel(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded, color: ZlColors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(order, style: zlText(14.5, weight: FontWeight.w800, height: 1.3))),
              ],
            ),
            if (reply.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (man != null) CrewFace(man: man!, size: 38, ring: hesitant ? ZlColors.amber : ZlColors.line),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Shake(
                      trigger: hesitant ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          reply,
                          style: zlText(14, weight: FontWeight.w800, color: const Color(0xFF1C1917)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3, backgroundColor: ZlColors.line, color: ZlColors.soft),
          ],
        ),
      ),
    );
  }
}

/// "Find the hazards" prompt under the scene.
class _HuntBar extends StatelessWidget {
  final int found;
  final int total;
  final VoidCallback onReveal;

  const _HuntBar({super.key, required this.found, required this.total, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    final done = found >= total;
    return ZlPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      border: done ? ZlColors.green : ZlColors.amber,
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.touch_app_rounded, color: done ? ZlColors.green : ZlColors.amber, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(done ? 'সব বিপদ খুঁজে পেয়েছেন!' : 'ছবিতে বিপদ খুঁজে ছুঁয়ে দিন', style: zlText(14.5, weight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < total; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 5),
                        width: 22,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i < found ? ZlColors.amber : ZlColors.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    Text('${n(found)}/${n(total)}', style: zlText(12, weight: FontWeight.w800, color: ZlColors.soft)),
                  ],
                ),
              ],
            ),
          ),
          if (!done)
            TextButton(
              onPressed: onReveal,
              child: Text('দেখিয়ে দিন', style: zlText(12.5, weight: FontWeight.w700, color: ZlColors.soft)),
            ),
        ],
      ),
    );
  }
}

/// Who is talking, and what they say, above the scene.
class _SpeakerLine extends StatelessWidget {
  final ZeroLossState state;
  final String faultId;
  final HazardEvent event;
  final VoidCallback onReplay;

  const _SpeakerLine({super.key, required this.state, required this.faultId, required this.event, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final man = speakerMan(s, faultId, event);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: -40, end: 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (_, v, c) => Transform.translate(offset: Offset(v, 0), child: c),
          child: man != null
              ? CrewFace(man: man, size: 46, ring: Colors.white)
              : CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(speakerIcon(event.speaker), size: 26, color: ZlColors.bg),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 4, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(speakerName(s, faultId, event), style: zlText(11.5, weight: FontWeight.w800, color: const Color(0xFF9A3412))),
                      Text(
                        s.fillFor(faultId, event.lineBn.isEmpty ? event.situationBn : event.lineBn),
                        style: zlText(14, weight: FontWeight.w700, color: const Color(0xFF1C1917), height: 1.3),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onReplay,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF9A3412)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TravelIntro extends StatefulWidget {
  final String location;
  final String weather;
  final VoidCallback onDone;

  const _TravelIntro({required this.location, required this.weather, required this.onDone});

  @override
  State<_TravelIntro> createState() => _TravelIntroState();
}

class _TravelIntroState extends State<_TravelIntro> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _c.stop();
        widget.onDone();
      },
      child: Stack(
        children: [
          const Positioned.fill(child: StormOverlay(drops: 90)),
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => LayoutBuilder(
              builder: (_, box) {
                final t = Curves.easeInOut.transform(_c.value);
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: box.maxHeight * 0.55,
                      child: Container(height: 6, color: ZlColors.line),
                    ),
                    Positioned(
                      right: 24,
                      top: box.maxHeight * 0.55 - 52,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on_rounded, color: ZlColors.red, size: 36),
                          Text(widget.location, style: zlText(12, weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16 + (box.maxWidth - 120) * t,
                      top: box.maxHeight * 0.55 - 40 + sin(_c.value * pi * 18) * 1.5,
                      child: const Icon(Icons.local_shipping_rounded, size: 46, color: ZlColors.amber),
                    ),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('রওনা দিল', style: zlText(22, weight: FontWeight.w900)),
                const SizedBox(height: 4),
                ZlTag(label: widget.weather, color: ZlColors.blue, icon: Icons.thunderstorm_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingAlert extends StatefulWidget {
  final String text;

  const _PulsingAlert({required this.text});

  @override
  State<_PulsingAlert> createState() => _PulsingAlertState();
}

class _PulsingAlertState extends State<_PulsingAlert> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xCCB91C1C), const Color(0xFFEF4444), _c.value),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: ZlColors.red.withValues(alpha: 0.4 * _c.value), blurRadius: 12)],
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(widget.text, style: zlText(12.5, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final HazardOption option;
  final HazardOption? picked;
  final VoidCallback onHear;
  final VoidCallback? onTap;

  const _OptionTile({required this.option, required this.picked, required this.onHear, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPicked = picked?.id == option.id;
    final revealBest = picked != null && option.best;
    final color = isPicked
        ? (option.best ? ZlColors.green : ZlColors.red)
        : revealBest
            ? ZlColors.green
            : ZlColors.line;
    final iconColor = picked == null ? ZlColors.amber : color;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: picked != null && !isPicked && !revealBest ? 0.4 : 1,
      child: Material(
        color: isPicked ? color.withValues(alpha: 0.16) : ZlColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: color, width: isPicked || revealBest ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                  child: Icon(
                    isPicked || revealBest ? (option.best ? Icons.check_rounded : Icons.close_rounded) : optionIcon(option.icon),
                    color: iconColor == ZlColors.line ? ZlColors.soft : iconColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.shortBn.isEmpty ? option.textBn : option.shortBn,
                    style: zlText(15.5, weight: FontWeight.w800, height: 1.3),
                  ),
                ),
                IconButton(
                  onPressed: onHear,
                  icon: const Icon(Icons.volume_up_outlined, size: 20, color: ZlColors.soft),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  final HazardOption option;
  final SafetyMantra mantra;
  final bool why;
  final VoidCallback onWhy;

  const _Feedback({required this.option, required this.mantra, required this.why, required this.onWhy});

  @override
  Widget build(BuildContext context) {
    final c = option.best ? ZlColors.green : ZlColors.red;
    final pts = option.best ? ZeroLossPoints.decision : -ZeroLossPoints.wrongDecision;
    return PopIn(
      child: ZlPanel(
        border: c,
        color: c.withValues(alpha: 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(option.best ? Icons.verified_rounded : Icons.dangerous_rounded, color: c, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option.best ? 'সঠিক সিদ্ধান্ত' : 'ভুল সিদ্ধান্ত',
                    style: zlText(18, weight: FontWeight.w900, color: c),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: option.best ? ZlColors.green : ZlColors.orange, borderRadius: BorderRadius.circular(14)),
                  child: Text(signedBn(pts), style: zlText(18, weight: FontWeight.w900, color: ZlColors.bg, height: 1.1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (option.safety != 0)
                  ZlTag(
                    label: signedBn(option.safety),
                    color: option.safety > 0 ? ZlColors.green : ZlColors.red,
                    icon: Icons.health_and_safety_rounded,
                  ),
                if (option.satisfaction != 0)
                  ZlTag(
                    label: signedBn(option.satisfaction),
                    color: option.satisfaction > 0 ? ZlColors.blue : ZlColors.red,
                    icon: Icons.sentiment_satisfied_alt_rounded,
                  ),
                if (option.minutes > 0) ZlTag(label: '+${n(option.minutes)}′', color: ZlColors.soft, icon: Icons.timer_outlined),
                if (option.risk > 0) ZlTag(label: '+${pct(option.risk)}', color: ZlColors.red, icon: Icons.warning_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Text(option.feedbackBn, style: zlText(13.5, weight: FontWeight.w600, color: ZlColors.text.withValues(alpha: 0.85), height: 1.4)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onWhy,
              child: Row(
                children: [
                  MantraBadge(mantra: mantra, size: 22),
                  const SizedBox(width: 6),
                  Text('${mantra.nameBn} মন্ত্র', style: zlText(12.5, weight: FontWeight.w800, color: mantraColor(mantra.id))),
                  Icon(why ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: ZlColors.soft),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: why
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(mantra.ruleBn, style: zlText(13, color: ZlColors.soft, height: 1.45)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
