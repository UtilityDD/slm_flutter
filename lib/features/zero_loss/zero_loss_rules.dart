import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zero_loss_models.dart';
import 'zero_loss_tbt.dart';
import 'zero_loss_ui.dart';

/// Opening: SAFE HOME, then each letter, then the pressure of the shift.
/// Text appears only when the voice reaches it.
class ZeroLossRulesView extends ConsumerStatefulWidget {
  final ZeroLossScenario scenario;
  final VoidCallback onDone;

  const ZeroLossRulesView({super.key, required this.scenario, required this.onDone});

  @override
  ConsumerState<ZeroLossRulesView> createState() => _ZeroLossRulesViewState();
}

enum _Beat { title, letters, stakes }

class _ZeroLossRulesViewState extends ConsumerState<ZeroLossRulesView> {
  static const _voiceRate = 0.40;
  static const _stakes = [
    'এটা আসল কাজ। ঝড়ে লাইন বন্ধ।',
    'সময় কম। তাড়া আছে।',
    'গ্রাহক তাগাদা দেবে।',
    'তাড়াতাড়ি করতে হবে।',
    'সেফ হোম মন্ত্র মেনে চলুন।',
    'নিয়ম মেনে তাড়াতাড়ি করলে পয়েন্ট।',
    'না মানলে বিপদ।',
  ];

  final _music = AudioPlayer();
  final _clip = AudioPlayer();
  late final ZlVoice _voice;
  _Beat _beat = _Beat.title;
  int _runId = 0;
  int _lettersShown = 0;
  int _sobaiShown = 0;
  int _mantra = 0;
  int _stage = -1;
  int _line = 0;

  List<SafetyMantra> get _mantras => widget.scenario.mantras;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(zlVoiceProvider);
    _voice.mutedNotifier.addListener(_onMute);
    _clip.setReleaseMode(ReleaseMode.stop);
    _clip.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    _startMusic();
    _begin();
  }

  @override
  void dispose() {
    _runId++;
    _voice.mutedNotifier.removeListener(_onMute);
    _voice.stop();
    _clip.dispose();
    _music.dispose();
    super.dispose();
  }

  bool _alive(int run) => mounted && run == _runId;

  Future<void> _startMusic() async {}

  void _onMute() {
    if (_voice.muted) {
      _clip.pause();
      _voice.stop();
    } else {
      _clip.resume();
    }
  }

  void _begin() {
    final run = ++_runId;
    _voice.stop();
    _clip.stop();
    switch (_beat) {
      case _Beat.title:
        _runTitle(run);
      case _Beat.letters:
        _runLetters(run);
      case _Beat.stakes:
        _runStakes(run);
    }
  }

  Future<bool> _playClip(String file, int run, void Function(int ms, int durMs) onTick) async {
    if (_voice.muted) return false;
    try {
      await _clip.stop();
      await Future<void>.delayed(const Duration(milliseconds: 40));
    } catch (_) {}
    if (!_alive(run)) return false;
    final done = Completer<void>();
    var durMs = 0;
    var heard = false;
    final durationSub = _clip.onDurationChanged.listen((d) => durMs = d.inMilliseconds);
    final positionSub = _clip.onPositionChanged.listen((p) {
      heard = true;
      if (_alive(run)) onTick(p.inMilliseconds, durMs);
    });
    final completeSub = _clip.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await _clip.play(UrlSource(mantraAudioUrl(file)));
      await done.future.timeout(const Duration(seconds: 14), onTimeout: () {});
      return heard;
    } catch (_) {
      return false;
    } finally {
      await durationSub.cancel();
      await positionSub.cancel();
      await completeSub.cancel();
    }
  }

  Future<void> _reveal(int run, int count, Duration total, void Function(int shown) apply) async {
    if (count <= 0) return;
    final step = total.inMilliseconds / count;
    for (var i = 1; i <= count; i++) {
      await Future<void>.delayed(Duration(milliseconds: step.round()));
      if (!_alive(run)) return;
      setState(() => apply(i));
    }
  }

  Future<void> _runTitle(int run) async {
    if (_alive(run)) {
      setState(() {
        _lettersShown = 0;
        _sobaiShown = 0;
      });
    }
    final safe = widget.scenario.tbt[TbtTrack.safe]?.file;
    final playedSafe = safe != null &&
        await _playClip(safe, run, (ms, dur) {
          if (dur <= 0) return;
          final shown = ((ms / dur) * 8).ceil().clamp(0, 8);
          if (shown != _lettersShown && _alive(run)) setState(() => _lettersShown = shown);
        });
    if (!_alive(run)) return;
    if (!playedSafe) {
      final speech = _voice.sayAwait('সেফ হোম', rate: _voiceRate);
      await _reveal(run, 8, const Duration(milliseconds: 2800), (n) => _lettersShown = n);
      await speech;
    }
    if (!_alive(run)) return;
    setState(() => _lettersShown = 8);

    final sobai = widget.scenario.tbt[TbtTrack.sobai]?.file;
    final playedSobai = sobai != null &&
        await _playClip(sobai, run, (ms, dur) {
          if (dur <= 0) return;
          final shown = ((ms / dur) * 2).ceil().clamp(0, 2);
          if (shown != _sobaiShown && _alive(run)) setState(() => _sobaiShown = shown);
        });
    if (!_alive(run)) return;
    if (!playedSobai) {
      final speech = _voice.sayAwait('সবাই ফিরো', rate: _voiceRate);
      await _reveal(run, 2, const Duration(milliseconds: 1600), (n) => _sobaiShown = n);
      await speech;
    }
    if (_alive(run)) setState(() => _sobaiShown = 2);
  }

  Future<void> _runLetters(int run) async {
    for (var i = _mantra; i < _mantras.length; i++) {
      if (!_alive(run)) return;
      setState(() {
        _mantra = i;
        _stage = -1;
      });
      final mantra = _mantras[i];
      final line = mantra.lines[TbtTrack.safe];
      var played = false;
      if (line != null) {
        played = await _playClip(line.file, run, (ms, _) {
          final stage = ms >= line.bodyAt ? 3 : ms >= line.nameAt ? 2 : ms >= line.wordAt ? 1 : (ms > 80 ? 0 : -1);
          if (stage != _stage && _alive(run)) setState(() => _stage = stage);
        });
      }
      if (!_alive(run)) return;
      if (!played) {
        setState(() => _stage = 0);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (_alive(run)) setState(() => _stage = 2);
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (!_alive(run)) return;
      if (_stage < 3) setState(() => _stage = 3);
      final meaning = line?.bodyBn ?? mantra.ruleBn;
      if (meaning.isNotEmpty) await _voice.sayAwait(meaning, rate: _voiceRate);
      if (!_alive(run)) return;
      if (i < _mantras.length - 1) await Future<void>.delayed(const Duration(milliseconds: 280));
    }
  }

  Future<void> _runStakes(int run) async {
    for (var i = _line; i < _stakes.length; i++) {
      if (!_alive(run)) return;
      setState(() => _line = i);
      await _voice.sayAwait(_stakes[i], rate: _voiceRate);
      if (!_alive(run)) return;
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
  }

  void _go(_Beat beat) {
    setState(() {
      _beat = beat;
      _stage = -1;
      if (beat == _Beat.letters) _mantra = 0;
      if (beat == _Beat.stakes) _line = 0;
    });
    _begin();
  }

  void _leave() {
    _runId++;
    _voice.stop();
    _clip.stop();
    _music.stop();
    widget.onDone();
  }

  void _next() {
    HapticFeedback.selectionClick();
    switch (_beat) {
      case _Beat.title:
        _go(_Beat.letters);
      case _Beat.letters:
        if (_mantra < _mantras.length - 1) {
          setState(() => _mantra++);
          _begin();
        } else {
          _go(_Beat.stakes);
        }
      case _Beat.stakes:
        if (_line < _stakes.length - 1) {
          setState(() => _line++);
          _begin();
        } else {
          _leave();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _beat == _Beat.stakes && _line == _stakes.length - 1;
    final page = _beat.index;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _leave,
            child: Text('বাদ দিন', style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft)),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _next,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: switch (_beat) {
                _Beat.title => _TitleBeat(key: const ValueKey('title'), letters: _lettersShown, sobai: _sobaiShown),
                _Beat.letters => _LetterBeat(
                    key: ValueKey('letter-$_mantra'),
                    mantra: _mantras[_mantra],
                    index: _mantra,
                    total: _mantras.length,
                    stage: _stage,
                  ),
                _Beat.stakes => _StakeBeat(key: ValueKey('stake-$_line'), line: _stakes[_line]),
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _Beat.values.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == page ? ZlColors.amber : ZlColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ZlButton(
            label: last ? 'বুঝেছি · শুরু করি' : 'পরের',
            icon: last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
            onTap: _next,
          ),
        ),
      ],
    );
  }
}

const _titleLetters = ['S', 'A', 'F', 'E', 'H', 'O', 'M', 'E'];
const _titleIds = ['stop', 'armour', 'permit', 'cut', 'earth', 'fence', 'mend', 'count'];

class _TitleBeat extends StatelessWidget {
  final int letters;
  final int sobai;

  const _TitleBeat({super.key, required this.letters, required this.sobai});

  @override
  Widget build(BuildContext context) {
    final size = ((MediaQuery.sizeOf(context).width - 64) / 4.8).clamp(48.0, 72.0);
    Widget word(int from) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = from; i < from + 4; i++)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: letters > i ? 1 : 0,
                child: SizedBox(
                  width: size,
                  child: Text(
                    _titleLetters[i],
                    textAlign: TextAlign.center,
                    style: zlText(size * 0.92, weight: FontWeight.w900, color: mantraColor(_titleIds[i]), height: 1),
                  ),
                ),
              ),
          ],
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('জিরো লস', style: zlText(14, weight: FontWeight.w800, color: ZlColors.soft)),
        const SizedBox(height: 28),
        word(0),
        const SizedBox(height: 6),
        word(4),
        const SizedBox(height: 36),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: sobai > 0 ? 1 : 0,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'সবাই'),
                TextSpan(text: sobai > 1 ? ' ফিরো' : ''),
              ],
            ),
            textAlign: TextAlign.center,
            style: zlText(34, weight: FontWeight.w900, color: ZlColors.green),
          ),
        ),
      ],
    );
  }
}

class _LetterBeat extends StatelessWidget {
  final SafetyMantra mantra;
  final int index;
  final int total;
  final int stage;

  const _LetterBeat({super.key, required this.mantra, required this.index, required this.total, required this.stage});

  @override
  Widget build(BuildContext context) {
    final line = mantra.lines[TbtTrack.safe];
    final color = mantraColor(mantra.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${n(index + 1)} / ${n(total)}', style: zlText(13, weight: FontWeight.w800, color: ZlColors.soft)),
          const SizedBox(height: 18),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: stage >= 0 ? 1 : 0,
            child: Text(line?.letter ?? '', style: zlText(96, weight: FontWeight.w900, color: color, height: 1)),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: stage >= 1 ? 1 : 0,
            child: FittedBox(
              child: Text(line?.word ?? '', style: zlText(36, weight: FontWeight.w900, color: color)),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: stage >= 2 ? 1 : 0,
            child: Text(mantra.nameBn, style: zlText(28, weight: FontWeight.w900)),
          ),
          const SizedBox(height: 18),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 280),
            opacity: stage >= 3 ? 1 : 0,
            child: Text(
              line?.bodyBn ?? '',
              textAlign: TextAlign.center,
              style: zlText(20, weight: FontWeight.w700, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _StakeBeat extends StatelessWidget {
  final String line;

  const _StakeBeat({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Text(line, textAlign: TextAlign.center, style: zlText(32, weight: FontWeight.w900, height: 1.4)),
      ),
    );
  }
}
