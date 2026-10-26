import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../shell/shell_providers.dart';
import 'identify_charts.dart';

/// Kraft-paper style chart body — port of web IdentifyChartPage.
class IdentifyChartBody extends StatelessWidget {
  final IdentifyChartPage page;
  final String title;
  final bool bn;

  const IdentifyChartBody({
    super.key,
    required this.page,
    required this.title,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    final topic = chartTopic(page.id);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 20),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E6C8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB89A6C), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x33281E10), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: topic.soft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: topic.accent.withValues(alpha: 0.25)),
                ),
                child: Icon(topic.icon, size: 20, color: topic.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(bn, 'মাঠের চার্ট', 'Field chart'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: topic.accent,
                      ),
                    ),
                    Text(
                      chartEnglishDigits(title),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Color(0xFF2A2318),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: topic.soft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  page.kindLabel(bn),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: topic.accent),
                ),
              ),
            ],
          ),
          if (page.kicker != null) ...[
            const SizedBox(height: 12),
            Text(
              page.kicker!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A3D12),
              ),
            ),
          ],
          if (page.intro != null) ...[
            const SizedBox(height: 8),
            Text(
              page.intro!,
              style: const TextStyle(fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w500, color: Color(0xFF2A2318)),
            ),
          ],
          if (page.flow.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Flow(flow: page.flow),
          ],
          if (page.steps.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < page.steps.length; i++) ...[
              _StepCard(index: i + 1, step: page.steps[i]),
              if (i < page.steps.length - 1) const SizedBox(height: 8),
            ],
          ],
          if (page.wrong != null && page.right != null) ...[
            const SizedBox(height: 14),
            _Compare(wrong: page.wrong!, right: page.right!),
          ],
          if (page.tables.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final table in page.tables) ...[
              _TableBlock(table: table),
              const SizedBox(height: 10),
            ],
          ],
          if (page.cards.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final card in page.cards) _PickCard(card: card),
              ],
            ),
          ],
          if (page.sections.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final section in page.sections) ...[
              _SectionCard(section: section),
              const SizedBox(height: 8),
            ],
          ],
          if (page.figure != null) ...[
            const SizedBox(height: 10),
            _Figure(figure: page.figure!),
          ],
          if (page.tip != null) ...[
            const SizedBox(height: 12),
            _Callout(tone: _CalloutTone.tip, text: page.tip!, bn: bn),
          ],
          if (page.warning != null) ...[
            const SizedBox(height: 8),
            _Callout(tone: _CalloutTone.warn, text: page.warning!, bn: bn),
          ],
        ],
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  final List<String> flow;

  const _Flow({required this.flow});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < flow.length; i++) ...[
          if (i > 0)
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF8A7464)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFC4B08A)),
            ),
            child: Text(
              flow[i],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2A2318)),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final ChartStep step;

  const _StepCard({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6C4A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF2A2318), shape: BoxShape.circle),
                child: Text(
                  '$index',
                  style: const TextStyle(color: Color(0xFFF3E6C8), fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF2A2318)),
                ),
              ),
            ],
          ),
          if (step.ok != null) ...[
            const SizedBox(height: 6),
            _Point(mark: '✓', text: step.ok!, color: const Color(0xFF15803D)),
          ],
          if (step.bad != null) ...[
            const SizedBox(height: 4),
            _Point(mark: '✕', text: step.bad!, color: const Color(0xFFB91C1C)),
          ],
        ],
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  final ChartCompareSide wrong;
  final ChartCompareSide right;

  const _Compare({required this.wrong, required this.right});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CompareSide(side: wrong, ok: false),
        const SizedBox(height: 8),
        _CompareSide(side: right, ok: true),
      ],
    );
  }
}

class _CompareSide extends StatelessWidget {
  final ChartCompareSide side;
  final bool ok;

  const _CompareSide({required this.side, required this.ok});

  @override
  Widget build(BuildContext context) {
    final border = ok ? const Color(0xFF86EFAC) : const Color(0xFFFECACA);
    final bg = ok ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);
    final title = ok ? const Color(0xFF166534) : const Color(0xFF9F1239);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(side.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: title)),
          const SizedBox(height: 6),
          for (final p in side.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _Point(mark: ok ? '✓' : '✕', text: p, color: title),
            ),
        ],
      ),
    );
  }
}

class _TableBlock extends StatelessWidget {
  final ChartTable table;

  const _TableBlock({required this.table});

  @override
  Widget build(BuildContext context) {
    final cols = table.headers.length.clamp(1, 12);
    // More columns → tighter type so the sheet stays full-width, no side-scroll.
    final headSize = cols >= 6 ? 9.5 : cols >= 4 ? 10.5 : 11.5;
    final cellSize = cols >= 6 ? 10.5 : cols >= 4 ? 11.5 : 12.5;
    final padH = cols >= 6 ? 3.0 : cols >= 4 ? 4.0 : 6.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2318),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (table.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 7),
              child: Text(
                table.title!,
                style: const TextStyle(color: Color(0xFFF3E6C8), fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(1, 0, 1, 1),
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                for (var i = 0; i < cols; i++) i: const FlexColumnWidth(1),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: const Color(0xFF2A2318).withValues(alpha: 0.08)),
                verticalInside: BorderSide(color: const Color(0xFF2A2318).withValues(alpha: 0.06)),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFFF1D6)),
                  children: [
                    for (final h in table.headers)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padH, vertical: 7),
                        child: Text(
                          h,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: headSize,
                            height: 1.15,
                            color: const Color(0xFF8A3D12),
                          ),
                        ),
                      ),
                  ],
                ),
                for (var r = 0; r < table.rows.length; r++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r.isOdd ? const Color(0xFFFFF7E8) : const Color(0xFFFFFBF0),
                    ),
                    children: [
                      for (var i = 0; i < cols; i++)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: padH, vertical: 6),
                          child: Text(
                            i < table.rows[r].length ? table.rows[r][i] : '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
                              fontSize: cellSize,
                              height: 1.15,
                              color: const Color(0xFF2A2318),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          for (final note in [
            if (table.note != null) table.note!,
            ...table.notes,
          ])
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Text(
                note,
                style: const TextStyle(color: Color(0xFFE7D5C6), fontSize: 11.5, height: 1.35),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final ChartCardBlock card;

  const _PickCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6C4A3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF2A2318))),
            const SizedBox(height: 6),
            for (final p in card.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('· $p', style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF3F3A36))),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ChartSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final (bg, border, ink) = switch (section.tone) {
      'ok' => (const Color(0xFFECFDF5), const Color(0xFF86EFAC), const Color(0xFF166534)),
      'bad' => (const Color(0xFFFFF1F2), const Color(0xFFFECACA), const Color(0xFF9F1239)),
      _ => (const Color(0xFFFFFBF0), const Color(0xFFD6C4A3), const Color(0xFF2A2318)),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ink)),
          const SizedBox(height: 6),
          for (final p in section.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('· $p', style: TextStyle(fontSize: 13, height: 1.4, color: ink.withValues(alpha: 0.9))),
            ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final ChartFigure figure;

  const _Figure({required this.figure});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6C4A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                figure.image,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE7D5C6),
                  child: Icon(Icons.image_outlined, color: Color(0xFF8A7464)),
                ),
              ),
            ),
          ),
          if (figure.title != null) ...[
            const SizedBox(height: 8),
            Text(figure.title!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF2A2318))),
          ],
          if (figure.info != null) ...[
            const SizedBox(height: 4),
            Text(figure.info!, style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }
}

enum _CalloutTone { tip, warn }

class _Callout extends StatelessWidget {
  final _CalloutTone tone;
  final String text;
  final bool bn;

  const _Callout({required this.tone, required this.text, required this.bn});

  @override
  Widget build(BuildContext context) {
    final tip = tone == _CalloutTone.tip;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tip ? const Color(0xFFFFF7ED) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tip ? const Color(0xFFFDBA74) : const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tip ? Icons.lightbulb_rounded : Icons.warning_amber_rounded,
            size: 18,
            color: tip ? const Color(0xFFC2410C) : const Color(0xFFB91C1C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: tip ? tr(bn, 'টিপ · ', 'Tip · ') : tr(bn, 'সতর্ক · ', 'Warn · '),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: tip ? const Color(0xFFC2410C) : const Color(0xFFB91C1C),
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2A2318), height: 1.4),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String mark;
  final String text;
  final Color color;

  const _Point({required this.mark, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mark, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }
}

/// Grid tile — kraft paper chart card like slm-web.
class IdentifyChartTile extends StatelessWidget {
  final String title;
  final IdentifyChartPage? page;
  final bool bn;

  const IdentifyChartTile({
    super.key,
    required this.title,
    required this.page,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    final topic = chartTopic(page?.id ?? '');
    final preview = page?.previewLine() ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFCFC2A4),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Container(
        margin: const EdgeInsets.all(7),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E6C8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2318), width: 1.35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(topic.icon, size: 16, color: topic.accent),
                const SizedBox(width: 5),
                Text(
                  tr(bn, 'চার্ট', 'Chart'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: topic.accent,
                  ),
                ),
                const Spacer(),
                if (page != null)
                  Text(
                    page!.kindLabel(bn),
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: topic.accent.withValues(alpha: 0.85)),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              chartEnglishDigits(title),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: Color(0xFF2A2318),
              ),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A3D12),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
