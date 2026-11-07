import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import 'beat_fx.dart';
import 'game_save.dart';
import 'lesson_promises.dart';

int _speechRun = 0;

/// After a passed Learn rung, asks for the lesson's habit promise until it has
/// been made: "আমি করব" saves it (+5 ◆ the first time, ever), "এখনো না"
/// costs nothing and the card comes back on the next pass. Returns true when
/// the card was shown, so the caller skips its other end-of-level card.
Future<bool> askLessonPromise(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  required String rungId,
  required bool muted,
}) async {
  final promise = lessonPromiseFor(lessonId);
  if (promise == null || ref.read(gameSaveProvider).promises.contains(promise.id)) return false;

  final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  unawaited(_speakInOrder([PromiseLines.ask, promise.textBn], muted));
  final yes = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: PromiseLines.ask,
    barrierColor: const Color(0xC0050A16),
    transitionDuration: quiet ? Duration.zero : const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => _PromiseCard(promise: promise, muted: muted),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
  _speechRun++;
  await MascotSpeechLibrary.stop();
  if (!context.mounted) return true;

  if (yes == true) {
    final save = ref.read(gameSaveProvider.notifier);
    await save.addPromise(promise.id);
    // Saved first, then shown: +5 once per promise, ever.
    if (await save.claimOnce('promise_reward:${promise.id}') && context.mounted) {
      final size = MediaQuery.sizeOf(context);
      await BeatFx.scoreDelta(
        ref,
        5,
        rungId: rungId,
        mood: GuideMood.celebrate,
        originGlobal: Offset(size.width * 0.5, size.height * 0.5),
        muted: muted,
      );
    }
    await MascotSpeechLibrary.speak(PromiseLines.kept, muted: muted);
  } else {
    await MascotSpeechLibrary.speak(PromiseLines.later, muted: muted);
  }
  return true;
}

/// Speaks [lines] one after another; a later call (or the card closing) cuts it.
Future<void> _speakInOrder(List<String> lines, bool muted) async {
  final run = ++_speechRun;
  for (final line in lines) {
    if (run != _speechRun) return;
    await MascotSpeechLibrary.speak(line, muted: muted);
  }
}

class _PromiseCard extends StatelessWidget {
  const _PromiseCard({required this.promise, required this.muted});

  final LessonPromise promise;
  final bool muted;

  void _answer(BuildContext context, bool yes) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(yes);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            // Reading text: dark ink on ivory, readable in sunlight.
            child: Material(
              color: SlmColors.ivory,
              elevation: 12,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.handshake_rounded, color: SlmColors.gold700, size: 34),
                    const SizedBox(height: 8),
                    Text(
                      PromiseLines.ask,
                      textAlign: TextAlign.center,
                      style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '“${promise.textBn}”',
                      textAlign: TextAlign.center,
                      style: bangla(fontSize: 21, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: SlmColors.ink,
                                side: const BorderSide(color: Color(0x553A4660)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _answer(context, false),
                              child: Text('এখনো না', style: bangla(fontSize: 16, fontWeight: FontWeight.w700, color: SlmColors.ink)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: SlmColors.gold700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _answer(context, true),
                              child: Text('আমি করব', style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
