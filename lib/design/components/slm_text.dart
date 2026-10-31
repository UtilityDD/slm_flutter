import 'package:flutter/material.dart';

import '../theme/slm_theme.dart';
import '../tokens/slm_type.dart';

enum SlmTextRole { display, headline, title, titleSm, body, bodySm, label, caption, overline, number }

/// Text that picks its style from the type scale and adapts it to the script
/// it contains, so the same call works for Bangla and English strings.
class SlmText extends StatelessWidget {
  final String text;
  final SlmTextRole role;
  final Color? color;
  final FontWeight? weight;
  final double? size;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const SlmText(
    this.text, {
    super.key,
    this.role = SlmTextRole.body,
    this.color,
    this.weight,
    this.size,
    this.align,
    this.maxLines,
    this.overflow,
  });

  static TextStyle styleFor(SlmType t, SlmTextRole role) => switch (role) {
        SlmTextRole.display => t.display,
        SlmTextRole.headline => t.headline,
        SlmTextRole.title => t.title,
        SlmTextRole.titleSm => t.titleSm,
        SlmTextRole.body => t.body,
        SlmTextRole.bodySm => t.bodySm,
        SlmTextRole.label => t.label,
        SlmTextRole.caption => t.caption,
        SlmTextRole.overline => t.overline,
        SlmTextRole.number => t.number,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.slm.type;
    var style = styleFor(t, role).copyWith(color: color, fontWeight: weight);
    if (size != null) style = style.copyWith(fontSize: size! * context.slm.layout.scale);
    final bangla = slmIsBangla(text);
    final shown = role == SlmTextRole.overline && !bangla ? text.toUpperCase() : text;
    return Text(
      shown,
      style: SlmType.adapt(style, text),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}
