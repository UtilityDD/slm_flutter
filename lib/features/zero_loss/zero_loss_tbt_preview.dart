import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zero_loss_engine.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

/// Short pre-work TBT: 8 mantra steps + required vs not-required kit for this shift.
class ZeroLossTbtPreview extends ConsumerWidget {
  const ZeroLossTbtPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(zeroLossProvider)!;
    final kit = s.shiftKit;
    final mantras = s.scenario.mantras;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              Text('টিবিটি', style: zlText(22, weight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('কাজের আগে · সবাই ফিরো', style: zlText(13, color: ZlColors.soft)),
              const SizedBox(height: 14),
              for (var i = 0; i < mantras.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StepRow(index: i + 1, mantra: mantras[i]),
                ),
              const SizedBox(height: 10),
              Text('আজকের কবচ ও সরঞ্জাম', style: zlText(15, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              _KitBlock(title: 'লাগবে', color: ZlColors.green, gear: [...kit.requiredBody, ...kit.requiredTruck]),
              const SizedBox(height: 8),
              _KitBlock(title: 'লাগবে না', color: ZlColors.orange, gear: [...kit.notRequiredBody, ...kit.notRequiredTruck]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ZlButton(
            label: 'কাজে নামুন',
            icon: Icons.play_arrow_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(zeroLossProvider.notifier).leaveTbtPreview();
            },
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final SafetyMantra mantra;

  const _StepRow({required this.index, required this.mantra});

  @override
  Widget build(BuildContext context) {
    final c = mantraColor(mantra.id);
    final line = mantra.chantBn.isNotEmpty ? mantra.chantBn : mantra.ruleBn;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MantraBadge(mantra: mantra, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${n(index)}. ${mantra.nameBn}', style: zlText(14, weight: FontWeight.w900, color: c)),
              if (line.isNotEmpty) Text(line, style: zlText(12.5, color: ZlColors.soft, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KitBlock extends StatelessWidget {
  final String title;
  final Color color;
  final List<Gear> gear;

  const _KitBlock({required this.title, required this.color, required this.gear});

  @override
  Widget build(BuildContext context) {
    if (gear.isEmpty) return const SizedBox.shrink();
    return ZlPanel(
      border: color.withValues(alpha: 0.55),
      color: color.withValues(alpha: 0.08),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: zlText(13, weight: FontWeight.w900, color: color)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final g in gear)
                SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      GearPicture(gear: g, size: 44, plain: true),
                      const SizedBox(height: 3),
                      Text(
                        g.nameBn,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: zlText(10.5, weight: FontWeight.w600, height: 1.15),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
