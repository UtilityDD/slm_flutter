import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/slm_design.dart';

enum GameExitScope { level, game }

/// Premium exit confirm — same sheet for system back and header back.
Future<bool> showGameExitSheet(
  BuildContext context, {
  required GameExitScope scope,
  required bool bn,
}) async {
  HapticFeedback.selectionClick();
  final title = scope == GameExitScope.level
      ? (bn ? 'ধাপ ছাড়বেন?' : 'Leave this step?')
      : (bn ? 'খেলা ছাড়বেন?' : 'Leave the game?');
  final body = scope == GameExitScope.level
      ? (bn
          ? 'মইয়ে ফিরবেন? এই ধাপের কাজ সেভ থাকবে না।'
          : 'Return to the ladder. Progress on this step will not be saved.')
      : (bn ? 'হোমে ফিরবেন? আপনার স্কোর জমা থাকবে।' : 'Return home. Your score stays saved.');
  final yes = scope == GameExitScope.level
      ? (bn ? 'হ্যাঁ, মইয়ে ফিরি' : 'Yes, back to ladder')
      : (bn ? 'হ্যাঁ, হোমে' : 'Yes, go home');
  final no = bn ? 'খেলতে থাকি' : 'Keep playing';

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: SlmColors.navy900.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SlmColors.mist.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SlmColors.ivory,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SlmColors.mist.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: SlmColors.danger,
                      foregroundColor: SlmColors.ivory,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(yes, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      no,
                      style: const TextStyle(
                        color: SlmColors.gold300,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}
