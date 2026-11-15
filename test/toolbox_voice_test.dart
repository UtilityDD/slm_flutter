import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/learn_voice_map.dart';
import 'package:slm_flutter/features/game/lucky_toolbox.dart';

void main() {
  test('every gift-box line has a Subrata clip (never the phone voice)', () {
    for (final line in ToolboxLines.spoken) {
      expect(learnCoachVoice[line], isNotNull, reason: 'no clip for: $line');
    }
  });

  test('spoken gift-box lines carry no changing number and no symbol', () {
    for (final line in ToolboxLines.spoken) {
      expect(line, isNot(matches(RegExp(r'[0-9০-৯◆×+"]'))), reason: line);
    }
  });

  test('every prize line said at the pick is one of the recorded lines', () {
    for (final prize in ToolboxPrize.values) {
      final r = ToolboxReward(
        ToolboxRarity.common,
        prize,
        coins: 15,
        lifeSkillId: prize == ToolboxPrize.lifeSkill ? 'x' : null,
      );
      expect(ToolboxLines.spoken, contains(ToolboxLines.won(r)), reason: prize.name);
    }
  });
}
