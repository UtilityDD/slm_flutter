import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zero_loss_engine.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

/// Short Bangla reason for one risk factor: "সেফটি বুটের বদলে চটি", "হেলমেট ছিল না", …
String riskReasonBn(ZeroLossState s, String faultId, RiskFactor r) {
  final sc = s.scenario;
  final who = r.linemanId == null ? '' : '${s.lineman(r.linemanId!).name}: ';
  if (r.fatigue) return 'ক্লান্ত ${s.lineman(r.linemanId!).name} কাজে';
  if (r.optionId != null) {
    final e = s.fault(faultId).events.firstWhere((e) => e.id == r.eventId);
    final o = e.options.firstWhere((o) => o.id == r.optionId);
    return s.fillFor(faultId, o.shortBn.isEmpty ? o.textBn : o.shortBn);
  }
  if (r.gearId != null) {
    final g = sc.gearById(r.gearId!);
    if (r.decoyId != null) return '$who${g.nameBn}-এর বদলে ${sc.gearById(r.decoyId!).nameBn}';
    if (g.kind == GearKind.decoy) return '${g.nameBn} নিয়ে কাজ';
    return '$who${g.nameBn} ছিল না';
  }
  if (r.linemanId != null) return 'অসাবধানি ${s.lineman(r.linemanId!).name}';
  return '';
}

/// The moment of the accident: picture, what happened, why, and who was hurt.
class AccidentCauseCard extends StatelessWidget {
  final ZeroLossState state;
  final String faultId;

  const AccidentCauseCard({super.key, required this.state, required this.faultId});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final m = s.mission(faultId);
    final r = m.accident!;
    final cause = s.scenario.accidentCause(r.cause);
    final gear = r.decoyId ?? r.gearId;
    final victim = m.injuredCrewId == null ? null : s.lineman(m.injuredCrewId!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.15, end: 1),
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeOutCubic,
              builder: (_, v, c) => Transform.scale(scale: v, child: c),
              child: Image.asset(cause.image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.panelHi)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Color(0xEE0B1220)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: PopIn(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                  decoration: BoxDecoration(color: ZlColors.red, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (victim != null)
                        CrewFace(man: victim, size: 28, ring: Colors.white)
                      else
                        const CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 18, color: ZlColors.red)),
                      const SizedBox(width: 6),
                      Text(victim?.name ?? 'গ্রামের লোক', style: zlText(13, weight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 6),
                      const Icon(Icons.local_hospital_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cause.titleBn, style: zlText(24, weight: FontWeight.w900, color: const Color(0xFFFCA5A5), height: 1.1)),
                  const SizedBox(height: 6),
                  PopIn(
                    delay: const Duration(milliseconds: 900),
                    child: Row(
                      children: [
                        if (gear != null) ...[
                          GearPicture(gear: s.scenario.gearById(gear), size: 40),
                          const SizedBox(width: 8),
                        ] else ...[
                          const Icon(Icons.report_rounded, color: ZlColors.amber, size: 26),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            riskReasonBn(s, faultId, r),
                            style: zlText(14.5, weight: FontWeight.w800, height: 1.25),
                          ),
                        ),
                      ],
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

/// The job step by step, green or red, so the player sees where it went wrong.
class MissionReplay extends ConsumerWidget {
  final ZeroLossState state;
  final String faultId;

  const MissionReplay({super.key, required this.state, required this.faultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    final sc = s.scenario;
    final f = s.fault(faultId);
    final m = s.mission(faultId);
    final voice = ref.read(zlVoiceProvider);
    final rows = <_ReplayRow>[];

    final tired = [for (final id in m.assignedCrew) if (s.lineman(id).fatigueLevel >= sc.tiredThreshold) s.lineman(id)];
    rows.add(_ReplayRow(
      icon: Icons.groups_rounded,
      ok: tired.isEmpty,
      title: tired.isEmpty ? 'টিম ঠিক' : 'ক্লান্ত: ${tired.map((t) => t.name).join(', ')}',
      faces: [for (final id in m.assignedCrew) s.lineman(id)],
    ));

    final body = s.missingBody(faultId);
    rows.add(_ReplayRow(
      icon: Icons.health_and_safety_rounded,
      ok: body.isEmpty,
      title: body.isEmpty ? 'সবার কবচ পরা' : 'কবচ কম',
      gear: [for (final (man, g) in body) sc.gearById(s.decoyInSlot(faultId, man, g) ?? g)],
      say: body.isEmpty
          ? null
          : body.map((b) => '${s.lineman(b.$1).name}-এর ${sc.gearById(b.$2).nameBn} ছিল না').join('। '),
    ));

    final decoys = m.packedGear.where((g) => g.kind == GearKind.decoy).toList();
    final truckBad = [...m.missingSafety.map(sc.gearById), ...decoys];
    rows.add(_ReplayRow(
      icon: Icons.local_shipping_rounded,
      ok: truckBad.isEmpty,
      title: truckBad.isEmpty ? 'ট্রাকে সব ছিল' : 'ট্রাকে গোলমাল',
      gear: truckBad,
      say: truckBad.isEmpty
          ? null
          : [
              ...m.missingSafety.map((id) => '${sc.gearById(id).nameBn} ছিল না'),
              ...decoys.map((g) => g.decoyNoteBn ?? g.nameBn),
            ].join('। '),
    ));

    final mistakes = m.chantMistakes ?? 0;
    rows.add(_ReplayRow(
      icon: Icons.record_voice_over_rounded,
      ok: mistakes == 0,
      title: mistakes == 0 ? 'টুলবক্স টক নিখুঁত' : 'টুলবক্স টকে ${n(mistakes)} ভুল',
    ));

    for (final d in m.decisions) {
      rows.add(_ReplayRow(
        mantra: sc.mantra(d.event.mantra),
        ok: d.option.best,
        title: s.fillFor(faultId, d.option.shortBn.isEmpty ? d.option.textBn : d.option.shortBn),
        say: d.option.best ? null : d.option.feedbackBn,
        best: d.option.best ? null : s.fillFor(faultId, d.event.options.firstWhere((o) => o.best).shortBn),
      ));
    }

    return ZlPanel(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.replay_rounded, color: ZlColors.soft, size: 18),
              const SizedBox(width: 6),
              Text(f.shortTitleBn, style: zlText(13.5, weight: FontWeight.w900, color: ZlColors.soft)),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++)
            PopIn(
              delay: Duration(milliseconds: 120 * i),
              child: _ReplayTile(row: rows[i], last: i == rows.length - 1, onHear: rows[i].say == null ? null : () => voice.say(rows[i].say!)),
            ),
        ],
      ),
    );
  }
}

class _ReplayRow {
  final IconData? icon;
  final SafetyMantra? mantra;
  final bool ok;
  final String title;
  final String? best;
  final String? say;
  final List<Gear> gear;
  final List<SmartLineman> faces;

  const _ReplayRow({
    this.icon,
    this.mantra,
    required this.ok,
    required this.title,
    this.best,
    this.say,
    this.gear = const [],
    this.faces = const [],
  });
}

class _ReplayTile extends StatelessWidget {
  final _ReplayRow row;
  final bool last;
  final VoidCallback? onHear;

  const _ReplayTile({required this.row, required this.last, this.onHear});

  @override
  Widget build(BuildContext context) {
    final c = row.ok ? ZlColors.green : ZlColors.red;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: c.withValues(alpha: 0.2),
                  child: row.mantra != null
                      ? Icon(mantraIcon(row.mantra!.id), size: 16, color: c)
                      : Icon(row.icon, size: 16, color: c),
                ),
                if (!last) Expanded(child: Container(width: 2, color: ZlColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(row.ok ? Icons.check_rounded : Icons.close_rounded, size: 18, color: c),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(row.title, style: zlText(13.5, weight: FontWeight.w800, color: row.ok ? ZlColors.text : const Color(0xFFFCA5A5))),
                      ),
                      if (onHear != null)
                        GestureDetector(
                          onTap: onHear,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.volume_up_rounded, size: 18, color: ZlColors.soft),
                          ),
                        ),
                    ],
                  ),
                  if (row.best != null && row.best!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, left: 22),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_rounded, size: 13, color: ZlColors.green),
                          const SizedBox(width: 4),
                          Expanded(child: Text(row.best!, style: zlText(12, weight: FontWeight.w700, color: ZlColors.green))),
                        ],
                      ),
                    ),
                  if (row.gear.isNotEmpty || row.faces.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, left: 22),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final g in row.gear) GearPicture(gear: g, size: 30),
                          for (final man in row.faces) CrewFace(man: man, size: 26),
                        ],
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
