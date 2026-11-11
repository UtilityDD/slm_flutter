import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'choice_deck.dart';
import 'myth_rival_puppet.dart';

// The pressure moment for any Do level (GAME_LEVEL_PLAYBOOK.md §1.8) — two beats:
// 1) Careless coworker peeps in with his caption + voice only (no guide ask, no deck).
// 2) His caption collapses to a thin chip by his peep (not over the score HUD); then
//    the guide asks and the 3-card deck rises. Rival voice drives RivalTalk only —
//    the app mascot stays still with no bubble.
// Going on working while he is still talking (beat 1) refuses him too.
// Learn myth cutscenes are separate and unchanged.

/// What the coworker says and the choice that follows (option libraries:
/// one right and two wrong are dealt, all about the same length).
@immutable
class CoworkerScript {
  const CoworkerScript({
    required this.line,
    required this.exitLine,
    required this.right,
    required this.wrong,
    required this.asks,
    this.tag = 'অসাবধান লাইনম্যান',
  });

  /// His push (recorded in his voice).
  final String line;

  /// His snarl when refused (recorded in his voice).
  final String exitLine;

  /// Ways to refuse him (one is dealt).
  final List<String> right;

  /// Ways to listen to him (two are dealt).
  final List<String> wrong;

  /// The guide's question, rotated.
  final List<String> asks;

  final String tag;

  List<String> get recordedLines => [line, exitLine];
}

/// Mix into a Do level's state; implement the hooks.
mixin CoworkerMoment<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // --- hooks -----------------------------------------------------------------
  CoworkerScript get coworkerScript;
  math.Random get coworkerRng;
  bool get coworkerMuted;

  /// May he come in now? true = yes; false = not yet (try again shortly);
  /// null = too late for this play (the moment has passed).
  bool? coworkerCanCome();

  /// The guide speaks (the level's speech chain).
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk});

  /// The level's hush (stops the guide's chain and the voice).
  void coworkerHush();

  /// Clear the guide's bubble + idle face when the coworker takes the stage.
  void coworkerClearGuideBubble() {
    final guide = ref.read(guideDirectorProvider.notifier);
    guide.softClearLine();
    guide.react(GuideMood.idle);
  }

  /// The consequences of the answer: points, slip, lines. [held] = refused him;
  /// [direct] = refused by going on working.
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct});

  // --- state -----------------------------------------------------------------
  Timer? _coworkerTimer;
  var coworkerOpen = false;
  var coworkerDone = false;
  var _coworkerLeft = true;
  CoworkerExit? _coworkerOut;
  var _choiceReady = false;
  /// Beat 1 = full caption; beat 2 = thin chip while the deck is up.
  var _coworkerCaptionFull = true;
  List<ChoiceOption> _choiceOpts = const [];
  String? _choiceWrong;
  String? _choicePicked;
  int _askN = 0;

  /// The choice deck is up (he has spoken; the guide asked).
  bool get coworkerChoiceUp => coworkerOpen && _choiceReady;

  /// He is on screen (talking or leaving).
  bool get coworkerOnScreen => coworkerOpen || _coworkerOut != null;

  /// He peeps from the right (put the guide on the left meanwhile).
  bool get coworkerFromRight => coworkerOnScreen && !_coworkerLeft;

  /// The next wording of the guide's question.
  String nextCoworkerAsk() => coworkerScript.asks[_askN++ % coworkerScript.asks.length];

  /// He will turn up a moment from now (1.2–2.4 s), once per play.
  void scheduleCoworker() {
    if (coworkerDone) return;
    _coworkerTimer?.cancel();
    _coworkerTimer = Timer(Duration(milliseconds: 1200 + coworkerRng.nextInt(1200)), _tryCoworker);
  }

  void _tryCoworker() {
    if (!mounted || coworkerDone || coworkerOpen) return;
    final can = coworkerCanCome();
    if (can == null) return;
    if (!can) {
      _coworkerTimer = Timer(const Duration(milliseconds: 900), _tryCoworker);
      return;
    }
    coworkerHush();
    coworkerClearGuideBubble();
    HapticFeedback.heavyImpact();
    if (!coworkerMuted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.6, muted: false));
    final s = coworkerScript;
    setState(() {
      coworkerOpen = true;
      _choiceReady = false;
      _coworkerCaptionFull = true;
      _choiceWrong = null;
      _choicePicked = null;
      _choiceOpts = dealChoices(s.right, s.wrong, coworkerRng);
      _coworkerOut = null;
      _coworkerLeft = coworkerRng.nextBool();
    });
    unawaited(() async {
      // Beat 1 — only he speaks; caption stays full; no deck yet.
      await MascotSpeechLibrary.speak(s.line, muted: coworkerMuted, rival: true);
      if (!mounted || !coworkerOpen) return;
      // Beat 2 — collapse his words to a chip, then guide + deck.
      setState(() {
        _coworkerCaptionFull = false;
        _choiceReady = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted || !coworkerOpen) return;
      await coworkerGuideSay([nextCoworkerAsk()], mood: GuideMood.think);
    }());
  }

  /// A card of the choice: it shakes red / pops green first.
  Future<void> _onChoice(ChoiceOption o, Offset origin) async {
    if (!coworkerChoiceUp || _choiceWrong != null || _choicePicked != null) return;
    setState(() => o.correct ? _choicePicked = o.textBn : _choiceWrong = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    await answerCoworker(o.correct, origin);
  }

  /// Refuse him ([held]) or listen; [direct]: by going on working.
  Future<void> answerCoworker(bool held, Offset origin, {bool direct = false}) async {
    if (!coworkerOpen) return;
    coworkerHush();
    setState(() {
      coworkerOpen = false;
      coworkerDone = true;
      _choiceReady = false;
      _coworkerCaptionFull = true;
      _coworkerOut = held ? CoworkerExit.beaten : CoworkerExit.smirk;
    });
    unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _coworkerOut = null);
    }));
    await onCoworkerAnswer(held, origin, direct: direct);
  }

  /// His snarl as he leaves, refused (use in [onCoworkerAnswer]).
  Future<void> coworkerSnarl() => MascotSpeechLibrary.speak(coworkerScript.exitLine, muted: coworkerMuted, rival: true);

  /// The choice deck (place it on the scene's bottom edge).
  Widget coworkerDeck({required bool quiet, Key? key}) => ChoiceDeck(
        key: key,
        options: _choiceOpts,
        quiet: quiet,
        muted: coworkerMuted,
        wrong: {?_choiceWrong},
        picked: _choicePicked,
        onPick: (o, at) => unawaited(_onChoice(o, at)),
      );

  /// Him, peeping in (a page-level layer), or null.
  Widget? coworkerPeek({required bool quiet, Key? key}) => coworkerOnScreen
      ? CoworkerPeek(
          key: key,
          fromLeft: _coworkerLeft,
          exit: _coworkerOut,
          quiet: quiet,
          lineBn: coworkerScript.line,
          tagBn: coworkerScript.tag,
          captionFull: _coworkerCaptionFull && _coworkerOut == null,
        )
      : null;

  /// Call from the level's dispose.
  void disposeCoworker() => _coworkerTimer?.cancel();
}

/// How the coworker leaves: beaten (the player acted) or smirking (obeyed).
enum CoworkerExit { beaten, smirk }

/// The careless coworker peeps from the edge. Beat 1: full caption under the
/// HUD. Beat 2: thin chip by his peep so it never covers the score line.
class CoworkerPeek extends StatefulWidget {
  const CoworkerPeek({
    super.key,
    required this.fromLeft,
    required this.exit,
    required this.quiet,
    required this.lineBn,
    required this.tagBn,
    this.captionFull = true,
  });

  final bool fromLeft;
  final CoworkerExit? exit;
  final bool quiet;
  final String lineBn;
  final String tagBn;

  /// true = big readable push; false = thin reminder chip (choice is up).
  final bool captionFull;

  static const bodyAsset = 'assets/duty_slip/dress/myth_rival_bad.webp';

  @override
  State<CoworkerPeek> createState() => _CoworkerPeekState();
}

class _CoworkerPeekState extends State<CoworkerPeek> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void initState() {
    super.initState();
    if (!widget.quiet) unawaited(_bob.repeat());
  }

  @override
  void didUpdateWidget(CoworkerPeek old) {
    super.didUpdateWidget(old);
    if (widget.exit != null && old.exit == null) {
      _bob.stop();
      if (!widget.quiet) unawaited(_bob.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    // Slightly smaller peep so the work scene stays visible.
    final pw = math.min(200.0, size.width * 0.48);
    final ph = pw * 1.22;
    final leaving = widget.exit != null;
    final quiet = widget.quiet;
    const lean = 0.42;
    final pivotY = size.height * 0.74;
    // UnifiedGameTopHud is 54 tall — keep captions under the score line.
    final belowHud = pad.top + 54 + 8;
    return Positioned.fill(
      child: Stack(
        children: [
          // Light dim — enough to mark interruption, not a blackout.
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: leaving ? 0 : 1,
              duration: const Duration(milliseconds: 260),
              child: const ColoredBox(color: Color(0x28050A16), child: SizedBox.expand()),
            ),
          ),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: leaving ? 0 : 1),
              duration: Duration(milliseconds: quiet ? 1 : (leaving ? 380 : 300)),
              curve: leaving ? Curves.easeInBack : Curves.easeOutBack,
              builder: (_, v, child) {
                final out = -pw * 0.9 + pw * 0.58 * v;
                final pivotX = widget.fromLeft ? out : size.width - out;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: pivotX - pw / 2,
                      top: pivotY - ph,
                      width: pw,
                      height: ph,
                      child: Transform.rotate(
                        angle: (widget.fromLeft ? lean : -lean) * (0.6 + 0.4 * v),
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    ),
                    // Beat 2: chip rides with him — never a top strip over ◆.
                    if (!leaving && !widget.captionFull)
                      Positioned(
                        left: widget.fromLeft ? (pivotX - 8).clamp(8.0, size.width - 200) : null,
                        right: widget.fromLeft ? null : (size.width - pivotX - 8).clamp(8.0, size.width - 200),
                        top: (pivotY - ph - 44).clamp(belowHud, size.height * 0.55),
                        width: math.min(280.0, size.width * 0.72),
                        child: IgnorePointer(
                          child: _ChipCaption(tagBn: widget.tagBn, lineBn: widget.lineBn),
                        ),
                      ),
                  ],
                );
              },
              child: IgnorePointer(
                child: Transform.flip(
                  flipX: widget.fromLeft,
                  child: AnimatedBuilder(
                    animation: _bob,
                    builder: (_, _) => ValueListenableBuilder<bool>(
                      valueListenable: RivalTalk.active,
                      builder: (_, talking, _) => MythRivalPuppet(
                        size: pw,
                        bodyAsset: CoworkerPeek.bodyAsset,
                        phase: _bob.value,
                        speaking: talking && !leaving,
                        reduce: quiet,
                        defeated: widget.exit == CoworkerExit.beaten,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Beat 1: full caption under the HUD (not over the score pills).
          if (!leaving && widget.captionFull)
            Positioned(
              left: 12,
              right: 12,
              top: belowHud,
              child: IgnorePointer(
                child: _FullCaption(tagBn: widget.tagBn, lineBn: widget.lineBn),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullCaption extends StatelessWidget {
  const _FullCaption({required this.tagBn, required this.lineBn});
  final String tagBn;
  final String lineBn;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.86 + 0.14 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B0C14), Color(0xFF22070C)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.danger, width: 1.5),
          boxShadow: [BoxShadow(color: SlmColors.danger.withValues(alpha: 0.28), blurRadius: 12, spreadRadius: 0.5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(999)),
              child: Text(tagBn, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            Text(
              enDigits(lineBn),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.35, color: SlmColors.ivory),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact reminder of what he said while the player picks refuse/listen.
class _ChipCaption extends StatelessWidget {
  const _ChipCaption({required this.tagBn, required this.lineBn});
  final String tagBn;
  final String lineBn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          color: const Color(0xEE22070C),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SlmColors.danger.withValues(alpha: 0.75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(999)),
              child: Text(tagBn, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                enDigits(lineBn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: SlmColors.ivory),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
