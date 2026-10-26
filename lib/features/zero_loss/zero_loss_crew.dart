import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/level_lessons_sheet.dart' show playLessonCue;

import 'zero_loss_engine.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

// ---------------------------------------------------------------------------
// Crew line-up card (map)
// ---------------------------------------------------------------------------

class CrewCard extends StatefulWidget {
  final ZeroLossState state;
  final SmartLineman man;
  final String faultId;
  final VoidCallback onTap;

  const CrewCard({super.key, required this.state, required this.man, required this.faultId, required this.onTap});

  @override
  State<CrewCard> createState() => _CrewCardState();
}

class _CrewCardState extends State<CrewCard> with TickerProviderStateMixin {
  late final _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Timer? _nameTimer;
  bool _named = false;

  bool get _tired => widget.man.fatigueLevel >= widget.state.scenario.tiredThreshold;

  @override
  void initState() {
    super.initState();
    if (_tired && !widget.man.isInjured) _sway.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPulse();
    });
  }

  @override
  void didUpdateWidget(CrewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPulse();
    });
  }

  void _syncPulse() {
    final where = widget.state.assignedFault(widget.man.id);
    final mine = where == widget.faultId;
    final dim = widget.man.isInjured || (where != null && !mine);
    if (mine && !dim) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    _sway.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _flashName() {
    setState(() => _named = true);
    _nameTimer?.cancel();
    _nameTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _named = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final man = widget.man;
    final where = s.assignedFault(man.id);
    final mine = where == widget.faultId;
    final busy = where != null && !mine;
    final dim = man.isInjured || busy;
    final label = busy
        ? '${man.name} · ব্যস্ত'
        : man.isInjured
            ? '${man.name} · আহত'
            : man.name;

    return GestureDetector(
      onTap: () {
        _flashName();
        if (!dim) widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        scale: mine ? 1.04 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: dim ? 0.38 : 1,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => Container(
                          width: mine ? 72 : 56,
                          height: 8,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: mine ? ZlColors.amber.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25),
                            boxShadow: mine
                                ? [
                                    BoxShadow(
                                      color: ZlColors.amber.withValues(alpha: 0.2 + 0.25 * _pulse.value),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 4, 2, 14),
                      child: AnimatedBuilder(
                        animation: _sway,
                        builder: (_, child) => Transform.rotate(
                          alignment: Alignment.bottomCenter,
                          angle: _tired ? (_sway.value - 0.5) * 0.05 : 0,
                          child: child,
                        ),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: 160,
                            height: 220,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CrewFigure(man: man),
                                // Tick sits on the chest of the figure.
                                if (mine && !dim)
                                  const Align(
                                    alignment: Alignment(0, -0.12),
                                    child: _BodyTick(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (man.isInjured)
                      const Center(child: Icon(Icons.local_hospital_rounded, color: ZlColors.red, size: 32)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: zlText(12, weight: FontWeight.w800, color: mine ? ZlColors.amber : ZlColors.text),
              ),
              const SizedBox(height: 2),
              _CrewHealthLine(man: man, tiredThreshold: s.scenario.tiredThreshold),
              SizedBox(
                height: 14,
                child: AnimatedOpacity(
                  opacity: _named && !busy ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    man.noteBn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: zlText(10, color: ZlColors.soft),
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

/// Amber check stamped on the lineman's chest when selected.
class _BodyTick extends StatelessWidget {
  const _BodyTick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZlColors.amber.withValues(alpha: 0.95),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.check_rounded, size: 20, color: ZlColors.bg),
    );
  }
}

class _CrewHealthLine extends StatelessWidget {
  final SmartLineman man;
  final int tiredThreshold;

  const _CrewHealthLine({required this.man, required this.tiredThreshold});

  @override
  Widget build(BuildContext context) {
    final energy = 100 - man.fatigueLevel;
    final energyColor =
        man.fatigueLevel >= tiredThreshold ? ZlColors.red : man.fatigueLevel >= 40 ? ZlColors.amber : ZlColors.green;
    final safetyColor = man.safetyRating >= 4 ? ZlColors.green : man.safetyRating == 3 ? ZlColors.amber : ZlColors.red;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= man.safetyRating ? safetyColor : ZlColors.line,
            ),
          ),
        const SizedBox(width: 6),
        Icon(Icons.bolt_rounded, size: 12, color: energyColor),
        Text(n(energy), style: zlText(11, weight: FontWeight.w800, color: energyColor, height: 1)),
      ],
    );
  }
}

/// Faces of the assigned team, with dashed empty seats.
class TeamSeats extends StatelessWidget {
  final ZeroLossState state;
  final String faultId;
  final double size;

  const TeamSeats({super.key, required this.state, required this.faultId, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final m = state.mission(faultId);
    final need = state.fault(faultId).requiredCrewCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < need; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: i < m.assignedCrew.length
                ? PopIn(
                    key: ValueKey(m.assignedCrew[i]),
                    child: CrewFace(man: state.lineman(m.assignedCrew[i]), size: size, ring: ZlColors.amber),
                  )
                : Container(
                    width: size + 4,
                    height: size + 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ZlColors.soft.withValues(alpha: 0.5), width: 1.4),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded, size: size * 0.5, color: ZlColors.soft),
                  ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// কবচ: dress every lineman before the truck
// ---------------------------------------------------------------------------

class ZeroLossArmourView extends ConsumerStatefulWidget {
  const ZeroLossArmourView({super.key});

  @override
  ConsumerState<ZeroLossArmourView> createState() => _ZeroLossArmourViewState();
}

class _ZeroLossArmourViewState extends ConsumerState<ZeroLossArmourView> {
  int _current = 0;
  final _shakes = <String, int>{};
  String? _namedId;
  Timer? _nameTimer;
  late final List<Gear> _tray;

  @override
  void initState() {
    super.initState();
    final s = ref.read(zeroLossProvider)!;
    _tray = [...s.scenario.bodyGear]..shuffle(Random(s.seed + 1));
  }

  @override
  void dispose() {
    _nameTimer?.cancel();
    ref.read(zlVoiceProvider).stop();
    super.dispose();
  }

  void _flashName(String id) {
    setState(() => _namedId = id);
    _nameTimer?.cancel();
    _nameTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _namedId = null);
    });
  }

  static const _slotPos = {
    'head': Alignment(-0.18, -0.58),
    'torso': Alignment(-0.22, -0.02),
    'hands': Alignment(0.24, 0.06),
    'feet': Alignment(0.2, 0.58),
  };

  static const _slotFrom = {
    'head': Alignment(-1.15, -0.9),
    'torso': Alignment(-1.15, -0.02),
    'hands': Alignment(1.15, 0.06),
    'feet': Alignment(1.15, 0.75),
  };

  void _wear(ZeroLossState s, String faultId, Gear g) {
    _flashName(g.id);
    final team = s.mission(faultId).assignedCrew;
    final manId = team[_current];
    final result = ref.read(zeroLossProvider.notifier).wearGear(manId, g.id);
    final voice = ref.read(zlVoiceProvider);
    switch (result) {
      case WearResult.worn:
        playLessonCue(true);
        HapticFeedback.lightImpact();
        final next = ref.read(zeroLossProvider)!;
        if (next.looksReady(faultId, manId)) {
          voice.say('${next.lineman(manId).name} তৈরি');
          final pending = team.indexWhere((id) => !next.looksReady(faultId, id));
          if (pending >= 0) {
            Future.delayed(const Duration(milliseconds: 450), () {
              if (mounted) setState(() => _current = pending);
            });
          }
        }
        break;
      case WearResult.wrong:
      case WearResult.notNeeded:
        // Soft cue only — teaching is TBT preview + debrief, not mid-play lectures.
        HapticFeedback.selectionClick();
        setState(() => _shakes[g.id] = (_shakes[g.id] ?? 0) + 1);
        break;
      case WearResult.removed:
      case WearResult.ignored:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(zeroLossProvider)!;
    final game = ref.read(zeroLossProvider.notifier);
    final faultId = s.activeFaultId!;
    final m = s.mission(faultId);
    final team = m.assignedCrew;
    _current = _current.clamp(0, team.length - 1);
    final man = s.lineman(team[_current]);
    final kit = s.bodyKit(faultId);
    final worn = m.wornBy(man.id);
    final armour = s.scenario.mantra('armour');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              MantraBadge(mantra: armour, size: 34, active: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(armour.nameBn, style: zlText(16, weight: FontWeight.w800, color: mantraColor('armour'))),
              ),
              for (var i = 0; i < team.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _current = i),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _FaceProgress(
                      man: s.lineman(team[i]),
                      done: s.duty
                          ? kit.where((k) => m.wornBy(team[i]).any((w) => s.scenario.gearById(w).bodySlot == s.scenario.gearById(k).bodySlot)).length
                          : kit.where(m.wornBy(team[i]).contains).length,
                      total: kit.length,
                      selected: i == _current,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (s.looksReady(faultId, man.id)) BoxShadow(color: ZlColors.green.withValues(alpha: 0.28), blurRadius: 28),
                ],
              ),
                child: LayoutBuilder(
                builder: (_, box) => Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, 0.05),
                            radius: 0.75,
                            colors: [Color(0xFF1A2740), Color(0x00101828)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 22,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: RadialGradient(
                            colors: [Color(0xAA000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 28,
                      child: Align(alignment: Alignment.centerLeft, child: SafetyShield(rating: man.safetyRating)),
                    ),
                    Positioned(
                      right: 18,
                      bottom: 46,
                      child: EnergyBadge(man: man, tiredThreshold: s.scenario.tiredThreshold),
                    ),
                    Positioned.fill(
                      left: 60,
                      right: 60,
                      top: 10,
                      bottom: 10,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (c, a) => SlideTransition(
                          position: Tween(begin: const Offset(0.3, 0), end: Offset.zero).animate(a),
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: CrewFigure(key: ValueKey(man.id), man: man),
                      ),
                    ),
                    for (final id in kit)
                      Builder(builder: (_) {
                        final slot = s.scenario.gearById(id).bodySlot;
                        final onId = worn.where((w) => s.scenario.gearById(w).bodySlot == slot).firstOrNull;
                        final wornNow = onId != null;
                        return AnimatedAlign(
                          duration: const Duration(milliseconds: 480),
                          curve: Curves.easeOutBack,
                          alignment: wornNow ? (_slotPos[slot] ?? Alignment.center) : (_slotFrom[slot] ?? Alignment.center),
                          child: _BodySlot(
                            gear: s.scenario.gearById(onId ?? id),
                            worn: wornNow,
                            onTap: wornNow ? () => game.wearGear(man.id, onId) : null,
                          ),
                        );
                      }),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: s.looksReady(faultId, man.id)
                              ? const ZlTag(key: ValueKey('ok'), label: 'তৈরি', color: ZlColors.green, icon: Icons.verified_rounded)
                              : Text(man.name, key: const ValueKey('name'), style: zlText(14, weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            itemCount: _tray.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final g = _tray[i];
              final on = worn.contains(g.id);
              return Shake(
                trigger: _shakes[g.id] ?? 0,
                child: GestureDetector(
                  onTap: () => _wear(s, faultId, g),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: on ? 0.35 : 1,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 16,
                          width: 76,
                          child: GentleName(text: g.nameBn, show: _namedId == g.id, size: 11),
                        ),
                        GearPicture(gear: g, size: 68, plain: true),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: ZlButton(
            label: s.duty
                ? 'ট্রাকে চলুন'
                : (s.isDressed(faultId) ? 'সবাই তৈরি · ট্রাকে চলুন' : 'জিনিস ছুঁয়ে ${man.name}-কে পরান'),
            icon: s.duty || s.isDressed(faultId) ? Icons.local_shipping_rounded : Icons.touch_app_rounded,
            onTap: game.canLoad(faultId)
                ? () {
                    ref.read(zlVoiceProvider).stop();
                    game.openLoading(faultId);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _FaceProgress extends StatelessWidget {
  final SmartLineman man;
  final int done;
  final int total;
  final bool selected;

  const _FaceProgress({required this.man, required this.done, required this.total, required this.selected});

  @override
  Widget build(BuildContext context) {
    final complete = done == total;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: done / total,
              strokeWidth: 3,
              backgroundColor: ZlColors.line,
              valueColor: AlwaysStoppedAnimation(complete ? ZlColors.green : ZlColors.amber),
            ),
          ),
          AnimatedScale(
            scale: selected ? 1 : 0.85,
            duration: const Duration(milliseconds: 200),
            child: CrewFace(man: man, size: 36),
          ),
          if (complete)
            const Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(radius: 8, backgroundColor: ZlColors.green, child: Icon(Icons.check, size: 11, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _BodySlot extends StatelessWidget {
  final Gear gear;
  final bool worn;
  final VoidCallback? onTap;

  const _BodySlot({required this.gear, required this.worn, this.onTap});

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
        child: worn
            ? SizedBox(
                key: const ValueKey('on'),
                width: size,
                height: size,
                child: GearPicture(gear: gear, size: size, plain: true),
              )
            : Opacity(
                key: const ValueKey('off'),
                opacity: 0.28,
                child: SizedBox(width: size, height: size, child: GearPicture(gear: gear, size: size, plain: true)),
              ),
      ),
    );
  }
}
