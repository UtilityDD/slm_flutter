import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'choice_deck.dart';
import 'myth_rival_puppet.dart';

// The pressure moment for any Do level (GAME_LEVEL_PLAYBOOK.md §1.8): the
// careless coworker — level 1's rival, same art, same puppet, his recorded
// voice — peeps round the left or right edge at a random moment and pushes the
// shortcut; then the guide puts the choice to the player (a different way each
// time) on a 3-card deck: one way to refuse him, two ways to listen.
// Going on working (taking a tool, pulling a switch) while he is still
// talking refuses him too. His lines need clips in his voice (see the playbook §3).

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
    HapticFeedback.heavyImpact();
    if (!coworkerMuted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.6, muted: false));
    final s = coworkerScript;
    setState(() {
      coworkerOpen = true;
      _choiceReady = false;
      _choiceWrong = null;
      _choicePicked = null;
      _choiceOpts = dealChoices(s.right, s.wrong, coworkerRng);
      _coworkerOut = null;
      _coworkerLeft = coworkerRng.nextBool();
    });
    unawaited(() async {
      await MascotSpeechLibrary.speak(s.line, muted: coworkerMuted, rival: true);
      if (!mounted || !coworkerOpen) return;
      // The guide puts it to the player; the answers come up.
      setState(() => _choiceReady = true);
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
      ? CoworkerPeek(key: key, fromLeft: _coworkerLeft, exit: _coworkerOut, quiet: quiet, lineBn: coworkerScript.line, tagBn: coworkerScript.tag)
      : null;

  /// Call from the level's dispose.
  void disposeCoworker() => _coworkerTimer?.cancel();
}

/// How the coworker leaves: beaten (the player acted) or smirking (obeyed).
enum CoworkerExit { beaten, smirk }

/// The careless coworker (level 1's rival — same art, same puppet) peeps
/// round the left or right edge: he leans in from behind the screen's side,
/// head and shoulders in view, and says to let the fire be. The guide then
/// puts the choice to the player. The scene dims a little behind him (taps
/// still reach the tools and the switch).
class CoworkerPeek extends StatefulWidget {
  const CoworkerPeek({
    super.key,
    required this.fromLeft,
    required this.exit,
    required this.quiet,
    required this.lineBn,
    required this.tagBn,
  });

  final bool fromLeft;
  final CoworkerExit? exit;
  final bool quiet;
  final String lineBn;
  final String tagBn;

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
      // One last flinch / smirk, then still.
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
    final pw = math.min(250.0, size.width * 0.6);
    final ph = pw * 1.22;
    final leaving = widget.exit != null;
    final quiet = widget.quiet;
    // He leans in round the edge: his feet are behind the side of the screen,
    // the lean brings his head and shoulders into view.
    const lean = 0.5;
    final pivotY = size.height * 0.72;
    return Positioned.fill(
      child: Stack(
        children: [
          // The scene dims a little (taps pass through to it).
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: leaving ? 0 : 1,
              duration: const Duration(milliseconds: 260),
              child: const ColoredBox(color: Color(0x4D050A16), child: SizedBox.expand()),
            ),
          ),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: leaving ? 0 : 1),
              duration: Duration(milliseconds: quiet ? 1 : (leaving ? 380 : 300)),
              curve: leaving ? Curves.easeInBack : Curves.easeOutBack,
              builder: (_, v, child) {
                // The pivot (his feet) slides from well out of view to just past the edge.
                final out = -pw * 0.9 + pw * 0.62 * v;
                final pivotX = widget.fromLeft ? out : size.width - out;
                return Stack(
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
                  ],
                );
              },
              child: IgnorePointer(
                child: Transform.flip(
                  // His art faces left: from the left edge he turns to the player.
                  flipX: widget.fromLeft,
                  child: AnimatedBuilder(
                    animation: _bob,
                    builder: (_, _) => ValueListenableBuilder<bool>(
                      valueListenable: MascotTalk.active,
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
          // His words, up in the sky so the fire he waves off stays in view.
          Positioned(
            left: 14,
            right: 14,
            top: size.height * 0.15,
            child: AnimatedOpacity(
              opacity: leaving ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: quiet ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3B0C14), Color(0xFF22070C)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SlmColors.danger, width: 1.8),
                      boxShadow: [BoxShadow(color: SlmColors.danger.withValues(alpha: 0.40), blurRadius: 18, spreadRadius: 1)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(999)),
                          child: Text(widget.tagBn, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        const SizedBox(height: 7),
                        Text(widget.lineBn,
                            textAlign: TextAlign.center,
                            style: bangla(fontSize: 16, fontWeight: FontWeight.w800, height: 1.35, color: SlmColors.ivory)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

