import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/mascot_speech_library.dart';
import 'game_save.dart';

/// "প্রথম সপ্তাহ": lessons 1.1–1.5 are five workdays of a new helper. Before a
/// lesson's first play, a short scene card sets the day — when, where, and one
/// line from the ওস্তাদ — so the player walks into a place, not a quiz.
@immutable
class LessonDay {
  const LessonDay({required this.day, required this.whenBn, required this.whereBn, required this.lineBn});

  final int day;
  final String whenBn;
  final String whereBn;

  /// Spoken by the coach (recorded with the Learn voice pack).
  final String lineBn;
}

const lessonDays = <String, LessonDay>{
  '1.1': LessonDay(day: 1, whenBn: 'ভোর 6:40', whereBn: 'স্টোর রুম', lineBn: 'আজ প্রথম দিন। আগে নিজের কবচ চিনে নিন।'),
  '1.2': LessonDay(day: 2, whenBn: 'সকাল 9:15', whereBn: 'বাজারের রাস্তা', lineBn: 'আজ বাজারের লাইন। দূরত্বই আপনাকে বাঁচাবে।'),
  '1.3': LessonDay(day: 3, whenBn: 'সকাল 7:30', whereBn: 'বৃষ্টির পরে গ্রামের পোল', lineBn: 'বৃষ্টির পরের পোল। ওঠার আগে পোলকে পড়ুন।'),
  '1.4': LessonDay(day: 4, whenBn: 'সকাল 11:00', whereBn: 'প্রথমবার পোলে ওঠা', lineBn: 'আজ প্রথম পোলে ওঠা। লাইফলাইন ঠিক আছে তো?'),
  '1.5': LessonDay(day: 5, whenBn: 'দুপুর 2:10', whereBn: 'শাটডাউনের কাজ', lineBn: 'লাইন বন্ধ। তবু ঘুমন্ত বাঘ জেগে থাকতে পারে।'),
};

/// Shows the day card before the first play of [rungId] (not on replays, so
/// practice stays quick). Holds ~3 s or until tapped; the coach line plays
/// under it. Returns when the card is gone.
Future<void> showLessonDayCard(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  required String rungId,
  required bool muted,
}) async {
  final day = lessonDays[lessonId];
  if (day == null || ref.read(gameSaveProvider).rungProgress[rungId] == 'cleared') return;
  final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  final nav = Navigator.of(context);
  var open = true;
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xF2050A16),
    builder: (_) => _DayCard(day: day, onTap: () {
      if (open) nav.pop();
    }),
  );
  unawaited(MascotSpeechLibrary.speak(day.lineBn, muted: muted));
  final closed = nav.push(route).whenComplete(() => open = false);
  // Long enough to read and hear the line, short enough for a 2-minute break.
  final hold = Future<void>.delayed(Duration(milliseconds: quiet ? 2600 : 3200));
  await Future.any([closed, hold]);
  if (open && route.isActive) nav.removeRoute(route);
  open = false;
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.onTap});

  final LessonDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                enDigits('দিন ${day.day}'),
                style: bangla(fontSize: 44, fontWeight: FontWeight.w900, color: SlmColors.gold300, height: 1),
              ),
              const SizedBox(height: 10),
              Container(width: 64, height: 2, color: SlmColors.gold400.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                enDigits('${day.whenBn} · ${day.whereBn}'),
                textAlign: TextAlign.center,
                style: bangla(fontSize: 18, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.3),
              ),
              const SizedBox(height: 18),
              Text(
                day.lineBn,
                textAlign: TextAlign.center,
                style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.mist, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
