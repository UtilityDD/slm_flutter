import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'game_save.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'toolbox_shield.dart';

// The shared frame of every Do level (owner's brief, 2026-11-07):
// - the guide comes first, full screen, and tells the task (like ladder
//   level 1); the game scene comes in after — no task text on the scene;
// - small mistakes are strikes: each one shows its card (the only place a
//   hint appears); the third strike fails the level with a fitting sound and
//   a lesson card that insists on reading before playing again;
// - deadly mistakes stay as they are (near-miss once, then a death).

/// How many small mistakes end a level.
const kStrikesToFail = 3;

/// The sound a level fails with, fitting its world.
enum FailSound { electric, thud, fire, paper }

extension FailSoundCue on FailSound {
  String get cue => switch (this) {
        FailSound.electric => 'sounds/learn/spark.ogg',
        FailSound.thud => 'sounds/learn/stomp.ogg',
        FailSound.fire => 'sounds/learn/rush_out.ogg',
        FailSound.paper => 'sounds/learn/level_fail.ogg',
      };
}

/// Strike counting for a Do level page.
mixin DoStrikeOut<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  int strikes = 0;

  /// The mistake that made the third strike (its lesson point is the one to read).
  DoMistake? strikeOutBy;

  bool get struckOut => strikeOutBy != null;

  /// Counts a small mistake; true when it was the third.
  bool strike(DoMistake m) {
    if (struckOut) return true;
    // A lucky-toolbox shield forgives this slip: not counted (toolbox_shield.dart).
    if (toolboxShieldSaves(ref, context)) return false;
    strikes++;
    if (strikes >= kStrikesToFail) {
      strikeOutBy = m;
      return true;
    }
    return false;
  }

  /// Saves a struck-out play (the latest play counts) — call once.
  Future<void> recordStrikeOut(LevelContext ctx, {required int percent, required int runScore}) async {
    final save = ref.read(gameSaveProvider.notifier);
    await save.recordLevelResult(ctx.rungId, percent);
    await save.commitLevelScore(ctx.rungId, runScore);
  }
}

abstract final class FrameLines {
  static const struckHead = 'তিনটে ভুল!';
  static const struckSub = 'আগে পাঠটা দেখে আসুন — তারপর আবার খেলবেন।';
  static const read = 'পাঠ পড়ুন';
  static const again = 'আবার খেলি';
  static const leave = 'মইয়ে ফিরি';
  static String step(int n) => 'ধাপ $n';
}

/// The guide, full screen, telling the task in a few lines. A tap moves on;
/// a line also moves on by itself (the voice never holds the player). When
/// the last line is done, [onDone] starts the game.
class LevelIntro extends ConsumerStatefulWidget {
  const LevelIntro({super.key, required this.lines, required this.muted, required this.onDone});

  final List<String> lines;
  final bool muted;
  final VoidCallback onDone;

  @override
  ConsumerState<LevelIntro> createState() => _LevelIntroState();
}

class _LevelIntroState extends ConsumerState<LevelIntro> {
  int _i = -1;
  var _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  void dispose() {
    _done = true;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _run() async {
    if (!widget.muted) unawaited(ZlFx.cue('sounds/learn/rush_in.ogg', volume: 0.45, muted: false));
    for (var i = 0; i < widget.lines.length; i++) {
      if (!mounted || _done) return;
      setState(() => _i = i);
      final line = widget.lines[i];
      ref.read(guideDirectorProvider.notifier).say(mood: i == 0 ? GuideMood.inspire : GuideMood.talk, line: line);
      // A line stays until both the voice and a fair reading time are done
      // (TTS may report "done" at once). No skipping, as level 1.
      final read = Duration(milliseconds: (line.length * 90).clamp(2600, 9000));
      await Future.wait([
        MascotSpeechLibrary.speak(line, muted: widget.muted),
        Future<void>.delayed(read),
      ]);
      if (!mounted || _done) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    _finish();
  }

  /// A tap does not skip (as level 1): the guide finishes the task first.
  void _tap() => HapticFeedback.selectionClick();

  void _finish() {
    if (_done) return;
    _done = true;
    unawaited(MascotSpeechLibrary.stop());
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF1C2C4A), Color(0xFF070D1A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: quiet ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutBack,
                  builder: (_, t, child) => Transform.translate(offset: Offset(0, 30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                  child: const AiLinemanGuide(sprite: 196, bubbleWidth: 290, showBubble: true, large: true, centered: true),
                ),
                const Spacer(),
                // Progress dots for the lines (no start button: as level 1, the game
                // begins when the guide has said the task).
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.lines.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= _i ? SlmColors.gold300 : const Color(0x33FFFFFF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 42),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The third strike: the level fails. A fitting sound, the picture of the
/// last mistake, and the guide insists on the lesson; "আবার খেলি" opens up
/// only after reading (or after a short wait, if the lesson cannot be loaded).
class StruckOutCard extends ConsumerStatefulWidget {
  const StruckOutCard({
    super.key,
    required this.mistake,
    required this.lessonId,
    required this.sound,
    required this.muted,
    required this.onRetry,
    required this.onLeave,
  });

  final DoMistake mistake;
  final String lessonId;
  final FailSound sound;
  final bool muted;
  final VoidCallback onRetry;
  final VoidCallback onLeave;

  @override
  ConsumerState<StruckOutCard> createState() => _StruckOutCardState();
}

class _StruckOutCardState extends ConsumerState<StruckOutCard> {
  var _read = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    if (!widget.muted) {
      unawaited(ZlFx.cue(widget.sound.cue, volume: 0.9, muted: false));
      unawaited(ZlFx.cue('sounds/learn/level_fail.ogg', volume: 0.6, muted: false));
    }
    // The guide speaks after the first frame (no provider change during build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.warn, line: FrameLines.struckSub);
      unawaited(MascotSpeechLibrary.speak(FrameLines.struckSub, muted: widget.muted));
    });
    // If the lesson can't open (offline), playing again is not held forever.
    _fallback = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _read = true);
    });
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  Future<void> _openLesson() async {
    unawaited(MascotSpeechLibrary.stop());
    await openLessonPoint(context, ref, lessonId: widget.lessonId, point: widget.mistake.lessonPoint, muted: widget.muted);
    if (mounted) setState(() => _read = true);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context);
    final m = widget.mistake;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xE6070D1A),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SlmColors.warning, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < kStrikesToFail; i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(Icons.close_rounded, color: SlmColors.danger, size: 26),
                        ),
                    ],
                  ),
                  Text(FrameLines.struckHead, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.danger)),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: m.art.endsWith('.svg') ? SvgPicture.asset(m.art, fit: BoxFit.contain) : Image.asset(m.art, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  Text(FrameLines.struckSub,
                      textAlign: TextAlign.center,
                      style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.4)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _FrameButton(label: FrameLines.read, icon: Icons.menu_book_rounded, filled: !_read, onTap: () => unawaited(_openLesson())),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _FrameButton(label: FrameLines.leave, icon: Icons.stairs_rounded, filled: false, onTap: widget.onLeave)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Opacity(
                          opacity: _read ? 1 : 0.35,
                          child: _FrameButton(
                            label: FrameLines.again,
                            icon: Icons.replay_rounded,
                            filled: _read,
                            onTap: _read ? widget.onRetry : () => HapticFeedback.selectionClick(),
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
    );
  }
}

class _FrameButton extends StatelessWidget {
  const _FrameButton({required this.label, required this.icon, required this.filled, required this.onTap});
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? SlmColors.navy800 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: SlmColors.navy800, width: filled ? 0 : 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: filled ? SlmColors.ivory : SlmColors.navy800),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: filled ? SlmColors.ivory : SlmColors.navy800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
