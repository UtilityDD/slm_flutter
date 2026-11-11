import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import 'discharge_order.dart';
import 'distance_spot.dart';
import 'fire_choose.dart';
import 'fire_pass.dart';
import 'game_save.dart';
import 'gate_field.dart';
import 'golden_minute.dart';
import 'harness_check.dart';
import 'harness_fit.dart';
import 'kit_check.dart';
import 'mistake_kit.dart';
import 'pole_read.dart';
import 'ptw_match.dart';
import 'ptw_steps.dart';
import 'rod_pick.dart';
import 'shock_rescue.dart';
import 'sky_read.dart';
import 'storm_push.dart';
import 'ten_sec_scan.dart';
import 'tool_tip.dart';
import 'm3_gate_field.dart' as m3_gate_field;
import 'm3_fuse_rating.dart' as m3_fuse_rating;
import 'm3_insulator_patrol.dart' as m3_insulator_patrol;
import 'm3_sld_isolate.dart' as m3_sld_isolate;
import 'm3_dtr_checkup.dart' as m3_dtr_checkup;
import 'm3_conductor_joint.dart' as m3_conductor_joint;
import 'm3_horngap_set.dart' as m3_horngap_set;
import 'm3_la_patrol.dart' as m3_la_patrol;
import 'm3_crossarm_check.dart' as m3_crossarm_check;
import 'm3_dtr_tap.dart' as m3_dtr_tap;
import 'm3_guard_repair.dart' as m3_guard_repair;
import 'm3_guard_patrol.dart' as m3_guard_patrol;
import 'm3_insulator_pick.dart' as m3_insulator_pick;
import 'm3_pillar_fuse.dart' as m3_pillar_fuse;
import 'm3_la_earth.dart' as m3_la_earth;
import 'm3_meter_call.dart' as m3_meter_call;
import 'm3_pillar_inspect.dart' as m3_pillar_inspect;
import 'm3_service_drop.dart' as m3_service_drop;
import 'm3_crossarm_pick.dart' as m3_crossarm_pick;
import 'm3_conductor_id.dart' as m3_conductor_id;
import 'm2_comealong_pick.dart' as m2_comealong_pick;
import 'm2_comealong_pull.dart' as m2_comealong_pull;
import 'm2_crimp_steps.dart' as m2_crimp_steps;
import 'm2_dead_test.dart' as m2_dead_test;
import 'm2_gate_field.dart' as m2_gate_field;
import 'm2_hotstick_check.dart' as m2_hotstick_check;
import 'm2_hotstick_operate.dart' as m2_hotstick_operate;
import 'm2_hydraulic_pick.dart' as m2_hydraulic_pick;
import 'm2_hydraulic_use.dart' as m2_hydraulic_use;
import 'm2_lug_pick.dart' as m2_lug_pick;
import 'm2_megger_prep.dart' as m2_megger_prep;
import 'm2_megger_read.dart' as m2_megger_read;
import 'm2_meter_setup.dart' as m2_meter_setup;
import 'm2_phase_meter.dart' as m2_phase_meter;
import 'm2_phase_swap.dart' as m2_phase_swap;
import 'm2_skin_cut.dart' as m2_skin_cut;
import 'm2_skin_tools.dart' as m2_skin_tools;
import 'm2_tool_care.dart' as m2_tool_care;
import 'm2_tool_use.dart' as m2_tool_use;
import 'm2_toolbox_pack.dart' as m2_toolbox_pack;

// "আমার ভুলের খাতা": every mistake caught in a Do level, newest first, with
// its picture and "পাঠে দেখুন". Opened from the 💀 chip on the ladder.
// Static screen: nothing animates.

/// Every mistake a built level can catch, by key (for its picture).
final Map<String, DoMistake> knownMistakes = {
  for (final m in [
    DischargeMistakes.lineBeforeEarth,
    DischargeMistakes.chainInsteadOfRod,
    DischargeMistakes.skipDischarge,
    DischargeMistakes.rustyEarth,
    DischargeMistakes.chainEarly,
    DischargeMistakes.earthOffFirst,
    ...RodMistakes.all,
    ...DistanceMistakes.all,
    ...ToolTipMistakes.all,
    ...PoleMistakes.all,
    ...HarnessMistakes.all,
    ...FitMistakes.all,
    ...PtwMistakes.all,
    ...StepMistakes.all,
    ...RescueMistakes.all,
    ...GoldenMistakes.all,
    ...FireMistakes.all,
    ...PassMistakes.all,
    ...KitMistakes.all,
    ...SkyMistakes.all,
    ...StormMistakes.all,
    ...TenSecMistakes.all,
    ...GateMistakes.all,
    ...m3_gate_field.M3GateMistakes.all,
    ...m3_fuse_rating.M3FuseRatingMistakes.all,
    ...m3_insulator_patrol.M3InsulatorPatrolMistakes.all,
    ...m3_sld_isolate.M3SldIsolateMistakes.all,
    ...m3_dtr_checkup.M3DtrCheckupMistakes.all,
    ...m3_conductor_joint.M3ConductorJointMistakes.all,
    ...m3_horngap_set.M3HorngapSetMistakes.all,
    ...m3_la_patrol.M3LaPatrolMistakes.all,
    ...m3_crossarm_check.M3CrossarmCheckMistakes.all,
    ...m3_dtr_tap.M3DtrTapMistakes.all,
    ...m3_guard_repair.M3GuardRepairMistakes.all,
    ...m3_guard_patrol.M3GuardPatrolMistakes.all,
    ...m3_insulator_pick.M3InsulatorPickMistakes.all,
    ...m3_pillar_fuse.M3PillarFuseMistakes.all,
    ...m3_la_earth.M3LaEarthMistakes.all,
    ...m3_meter_call.M3MeterCallMistakes.all,
    ...m3_pillar_inspect.M3PillarInspectMistakes.all,
    ...m3_service_drop.M3ServiceDropMistakes.all,
    ...m3_crossarm_pick.M3CrossarmPickMistakes.all,
    ...m3_conductor_id.M3ConductorIdMistakes.all,
    ...m2_comealong_pick.M2ComeAlongMistakes.all,
    ...m2_comealong_pull.PullMistakes.all,
    ...m2_crimp_steps.CrimpMistakes.all,
    ...m2_dead_test.DeadMistakes.all,
    ...m2_gate_field.M2GateMistakes.all,
    ...m2_hotstick_check.HotStickMistakes.all,
    ...m2_hotstick_operate.HsMistakes.all,
    ...m2_hydraulic_pick.HydMistakes.all,
    ...m2_hydraulic_use.HydMistakes.all,
    ...m2_lug_pick.LugMistakes.all,
    ...m2_megger_prep.MeggerPrepMistakes.all,
    ...m2_megger_read.M2MeggerMistakes.all,
    ...m2_meter_setup.M2MeterMistakes.all,
    ...m2_phase_meter.PmMistakes.all,
    ...m2_phase_swap.PhaseMistakes.all,
    ...m2_skin_cut.SkinMistakes.all,
    ...m2_skin_tools.SkinMistakes.all,
    ...m2_tool_care.CareMistakes.all,
    ...m2_tool_use.TuMistakes.all,
    ...m2_toolbox_pack.TbMistakes.all,
  ])
    m.key: m,
};

abstract final class MistakesBookLines {
  static const title = 'আমার ভুলের খাতা';
  static const sub = 'প্রতিটা ভুল একটা শিক্ষা — পাঠে ফিরে দেখুন।';
  static const all = 'সব';
  static const deadly = 'মারাত্মক';
  static const empty = 'এখনও কোনো ভুল নেই। ভুল হলে এখানে জমা হবে — ফিরে দেখে শিখবেন।';
  static const deaths = 'মৃত্যু';
  static const kinds = 'ভুলের ধরন';
  static const today = 'আজ';
  static const yesterday = 'গতকাল';
  static String daysAgo(int d) => '${enDigits('$d')} দিন আগে';
  static String times(int n) => '${enDigits('$n')} বার';
  static String lesson(String id) => 'পাঠ ${enDigits(id)}';
}

class MistakesBookPage extends ConsumerStatefulWidget {
  const MistakesBookPage({super.key, this.now});

  /// Tests: a fixed "now" for the day labels.
  final DateTime? now;

  @override
  ConsumerState<MistakesBookPage> createState() => _MistakesBookPageState();
}

class _MistakesBookPageState extends ConsumerState<MistakesBookPage> {
  var _deadlyOnly = false;

  String _when(int atMs) {
    final now = widget.now ?? DateTime.now();
    final at = DateTime.fromMillisecondsSinceEpoch(atMs);
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays;
    if (days <= 0) return MistakesBookLines.today;
    if (days == 1) return MistakesBookLines.yesterday;
    return MistakesBookLines.daysAgo(days);
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameSaveProvider);
    final all = save.mistakes.reversed.toList();
    final shown = _deadlyOnly ? all.where((m) => m.deadly).toList() : all;
    return Scaffold(
      backgroundColor: SlmColors.navy950,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: SlmColors.ivory),
                  ),
                  Expanded(
                    child: Text(MistakesBookLines.title,
                        style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(MistakesBookLines.sub,
                  style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: SlmColors.gold200)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // Wraps on narrow phones instead of overflowing.
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Stat(mark: '💀', value: save.deaths, label: MistakesBookLines.deaths),
                  _Stat(mark: '📒', value: all.length, label: MistakesBookLines.kinds),
                  _Filter(label: MistakesBookLines.all, on: !_deadlyOnly, onTap: () => setState(() => _deadlyOnly = false)),
                  _Filter(label: MistakesBookLines.deadly, on: _deadlyOnly, onTap: () => setState(() => _deadlyOnly = true)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          MistakesBookLines.empty,
                          textAlign: TextAlign.center,
                          style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.mist, height: 1.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = shown[i];
                        return _MistakeTile(
                          entry: e,
                          art: knownMistakes[e.key]?.art,
                          when: _when(e.atMs),
                          onRead: e.lessonPoint == null
                              ? null
                              : () => unawaited(openLessonPoint(context, ref, lessonId: e.lessonId, point: e.lessonPoint)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.mark, required this.value, required this.label});
  final String mark;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: SlmColors.navy850, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mark, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(enDigits('$value'), style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          const SizedBox(width: 5),
          Text(label, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: SlmColors.mist)),
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        // No alignment: sized to the label (inside a Wrap it would stretch).
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? SlmColors.gold300 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: on ? 1 : 0.5)),
        ),
        child: Text(label,
            style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: on ? SlmColors.navy950 : SlmColors.gold200)),
      ),
    );
  }
}

class _MistakeTile extends StatelessWidget {
  const _MistakeTile({required this.entry, required this.art, required this.when, required this.onRead});
  final MistakeEntry entry;
  final String? art;
  final String when;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final edge = entry.deadly ? SlmColors.danger : SlmColors.gold500;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SlmColors.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: edge, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (entry.deadly) const Text('💀 ', style: TextStyle(fontSize: 13)),
              Text(MistakesBookLines.lesson(entry.lessonId),
                  style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
              const Spacer(),
              Text('$when · ${MistakesBookLines.times(entry.count)}',
                  style: bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
            ],
          ),
          const SizedBox(height: 8),
          if (art != null) ...[
            SizedBox(
              height: 120,
              child: art!.endsWith('.svg') ? SvgPicture.asset(art!, fit: BoxFit.contain) : Image.asset(art!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
          ],
          Text(entry.textBn,
              style: bangla(fontSize: 14.5, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.4)),
          if (onRead != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRead,
                icon: const Icon(Icons.menu_book_rounded, size: 18, color: SlmColors.navy800),
                label: Text(MistakeLines.readLesson,
                    style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.navy800)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
