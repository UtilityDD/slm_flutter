import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../home/level_lessons_sheet.dart' show playLessonCue;
import 'zero_loss_engine.dart';
import 'zero_loss_fx.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

/// Recorded mantra clips shared with the web app (Supabase public storage).
String mantraAudioUrl(String file) => '${AppConfig.supabaseUrl}/storage/v1/object/public/avatars/audio/mantra/$file';

/// SAFE HOME on even missions, সবাই ফিরো on odd ones, so both tracks get practised.
TbtTrack tbtTrackFor(ZeroLossState s) =>
    s.missions.values.where((m) => m.chantMistakes != null).length.isEven ? TbtTrack.safe : TbtTrack.sobai;

/// One clip at a time over the network; [play] completes with false if it could not be streamed.
class MantraClipPlayer {
  final _player = AudioPlayer();
  StreamSubscription<void>? _done;

  Stream<Duration> get position => _player.onPositionChanged;

  Future<bool> play(String file, {required VoidCallback onComplete}) async {
    await _done?.cancel();
    _done = _player.onPlayerComplete.listen((_) => onComplete());
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(UrlSource(mantraAudioUrl(file)));
      return true;
    } catch (_) {
      await _done?.cancel();
      return false;
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();

  Future<void> stop() async {
    await _done?.cancel();
    await _player.stop();
  }

  void dispose() {
    _done?.cancel();
    _player.dispose();
  }
}

/// The eight track letters (S A F E H O M E / স ব আ ই ফ ই র ও).
class TbtLetterRow extends StatelessWidget {
  final ZeroLossScenario scenario;
  final TbtTrack track;
  final double size;

  /// Letters before this index are lit; null lights all.
  final int? lit;
  final int? active;
  final bool pop;

  const TbtLetterRow({
    super.key,
    required this.scenario,
    required this.track,
    this.size = 34,
    this.lit,
    this.active,
    this.pop = false,
  });

  @override
  Widget build(BuildContext context) {
    final ms = scenario.mantras;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < ms.length; i++)
          () {
            final c = mantraColor(ms[i].id);
            final on = lit == null || i < lit!;
            final now = i == active;
            Widget tile = AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? c : ZlColors.panelHi,
                borderRadius: BorderRadius.circular(size * 0.28),
                border: Border.all(color: now ? Colors.white : c.withValues(alpha: on ? 1 : 0.5), width: now ? 2 : 1),
                boxShadow: now ? [BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 12)] : null,
              ),
              child: Text(
                ms[i].lines[track]?.letter ?? '',
                style: zlText(size * 0.5, weight: FontWeight.w900, color: on ? Colors.white : c),
              ),
            );
            if (now) tile = AnimatedScale(scale: 1.15, duration: const Duration(milliseconds: 250), child: tile);
            return pop ? PopIn(delay: Duration(milliseconds: 90 * i), child: tile) : tile;
          }(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// টুলবক্স টক: the crew huddles, the lead talks through the 8 mantras, then
// the player says them back in order.
// ---------------------------------------------------------------------------

enum _TbtStage { listen, recall, done }

class ZeroLossTbtView extends ConsumerStatefulWidget {
  const ZeroLossTbtView({super.key});

  @override
  ConsumerState<ZeroLossTbtView> createState() => _ZeroLossTbtViewState();
}

class _ZeroLossTbtViewState extends ConsumerState<ZeroLossTbtView> {
  static const _gap = Duration(milliseconds: 450);
  static const _silentClip = Duration(milliseconds: 3600);

  final _audio = MantraClipPlayer();
  StreamSubscription<Duration>? _posSub;
  Timer? _timer;
  late final ZlVoice _voice;

  late final TbtTrack _track;
  late final List<SafetyMantra> _order;
  _TbtStage _stage = _TbtStage.recall;

  /// -1 is the track title clip, 0..7 the mantras, 8 means finished.
  int _clip = -1;
  int _posMs = 0;
  bool _paused = false;
  bool _streaming = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(zeroLossProvider)!;
    _track = tbtTrackFor(s);
    _order = s.scenario.mantras;
    _voice = ref.read(zlVoiceProvider);
    _voice.stop();
    _voice.mutedNotifier.addListener(_onMute);
    _posSub = _audio.position.listen((p) {
      if (mounted && _streaming) setState(() => _posMs = p.inMilliseconds);
    });
  }

  @override
  void dispose() {
    _voice.mutedNotifier.removeListener(_onMute);
    _timer?.cancel();
    _posSub?.cancel();
    _audio.dispose();
    super.dispose();
  }

  bool get _listened => _clip >= _order.length;

  String _clipFile() => _clip < 0
      ? ref.read(zeroLossProvider)!.scenario.tbt[_track]?.file ?? ''
      : _order[_clip].lines[_track]?.file ?? '';

  String _clipText() {
    if (_clip < 0) {
      final t = ref.read(zeroLossProvider)!.scenario.tbt[_track];
      return t == null ? '' : '${t.title}। ${t.subtitleBn}';
    }
    final m = _order[_clip];
    final l = m.lines[_track];
    return l == null ? m.ruleBn : '${l.letter}। ${l.word}। ${m.nameBn}। ${l.bodyBn}';
  }

  Future<void> _playClip() async {
    _timer?.cancel();
    if (!mounted || _listened || _stage != _TbtStage.listen) return;
    setState(() {
      _posMs = 0;
      _paused = false;
      _streaming = false;
    });
    final file = _clipFile();
    if (!_voice.muted && !_offline && file.isNotEmpty) {
      final clip = _clip;
      final ok = await _audio.play(file, onComplete: () {
        if (mounted && clip == _clip) _nextClip();
      });
      if (!mounted || clip != _clip) return;
      if (ok) {
        setState(() => _streaming = true);
        _timer = Timer(const Duration(seconds: 16), _nextClip);
        return;
      }
      _offline = true;
    }
    _playFallback();
  }

  /// Muted or offline: show the whole card, read it with TTS when allowed.
  void _playFallback() {
    final text = _clipText();
    setState(() {
      _streaming = false;
      _posMs = 1 << 20;
    });
    _voice.say(text);
    final ms = _voice.muted ? _silentClip.inMilliseconds : 2200 + text.length * 70;
    _timer = Timer(Duration(milliseconds: ms), _nextClip);
  }

  void _nextClip() {
    _timer?.cancel();
    if (!mounted || _listened) return;
    _audio.stop();
    _voice.stop();
    setState(() {
      _clip++;
      _streaming = false;
    });
    if (_listened) {
      HapticFeedback.mediumImpact();
      return;
    }
    HapticFeedback.selectionClick();
    _timer = Timer(_gap, _playClip);
  }

  void _togglePause() {
    if (_listened) return;
    if (_paused) {
      setState(() => _paused = false);
      _streaming ? _audio.resume() : _playClip();
      if (_streaming) _timer = Timer(const Duration(seconds: 16), _nextClip);
    } else {
      _timer?.cancel();
      _voice.stop();
      if (_streaming) _audio.pause();
      setState(() => _paused = true);
    }
  }

  void _replayAll() {
    _audio.stop();
    _voice.stop();
    setState(() => _clip = -1);
    _timer?.cancel();
    _timer = Timer(_gap, _playClip);
  }

  void _onMute() {
    if (!_voice.muted || !_streaming || _stage != _TbtStage.listen) return;
    _audio.stop();
    _timer?.cancel();
    _playFallback();
  }

  void _startRecall() {
    _timer?.cancel();
    _audio.stop();
    _voice.stop();
    setState(() => _stage = _TbtStage.recall);
    _voice.say(ref.read(zeroLossProvider)!.scenario.voice['recall_bn'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(zeroLossProvider)!;
    final intro = s.scenario.tbt[_track];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.home_repair_service_rounded, color: ZlColors.amber, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('টুলবক্স টক · TBT', style: zlText(18, weight: FontWeight.w900)),
                    Text(
                      'এবার আপনি বলুন',
                      style: zlText(12, color: ZlColors.soft),
                    ),
                  ],
                ),
              ),
              ZlTag(
                label: intro?.title ?? '',
                color: _track == TbtTrack.safe ? ZlColors.blue : ZlColors.green,
                icon: Icons.verified_user_rounded,
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_stage) {
              _TbtStage.listen => _listenView(s),
              _TbtStage.recall => _TbtRecall(
                  key: const ValueKey('recall'),
                  track: _track,
                  onDone: (mistakes) => setState(() {
                    _recallMistakes = mistakes;
                    _stage = _TbtStage.done;
                  }),
                ),
              _TbtStage.done => _TbtDone(
                  key: const ValueKey('done'),
                  scenario: s.scenario,
                  track: _track,
                  mistakes: _recallMistakes,
                ),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: switch (_stage) {
            _TbtStage.listen => ZlButton(
                label: 'শুনেছি · এবার আমি বলি',
                icon: Icons.record_voice_over_rounded,
                onTap: _listened ? _startRecall : null,
              ),
            _TbtStage.recall => const SizedBox(height: 50),
            _TbtStage.done => ZlButton(
                label: 'সাইটে চলুন',
                icon: Icons.arrow_forward_rounded,
                onTap: () => ref.read(zeroLossProvider.notifier).finishChant(_recallMistakes),
              ),
          },
        ),
      ],
    );
  }

  int _recallMistakes = 0;

  Widget _listenView(ZeroLossState s) {
    final faultId = s.activeFaultId!;
    final team = [for (final id in s.mission(faultId).assignedCrew) s.lineman(id)];
    final lead = s.leadOf(faultId);
    final talking = !_paused && !_listened;
    return ListView(
      key: const ValueKey('listen'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _Huddle(team: team, lead: lead, talking: talking),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(a), child: child),
          ),
          child: _clip < 0
              ? _IntroCard(key: const ValueKey(-1), scenario: s.scenario, track: _track)
              : _listened
                  ? _ListenedCard(key: const ValueKey(99), scenario: s.scenario, track: _track)
                  : _StepCard(
                      key: ValueKey(_clip),
                      mantra: _order[_clip],
                      track: _track,
                      step: _clip,
                      total: _order.length,
                      posMs: _posMs,
                    ),
        ),
        const SizedBox(height: 14),
        TbtLetterRow(
          scenario: s.scenario,
          track: _track,
          lit: _clip < 0 ? 0 : _clip,
          active: _listened || _clip < 0 ? null : _clip,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundBtn(icon: Icons.replay_rounded, onTap: _replayAll, tooltip: 'আবার শুনি'),
            const SizedBox(width: 18),
            _RoundBtn(
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onTap: _listened ? null : _togglePause,
              big: true,
              tooltip: _paused ? 'চালাও' : 'থামাও',
            ),
            const SizedBox(width: 18),
            _RoundBtn(icon: Icons.skip_next_rounded, onTap: _listened ? null : _nextClip, tooltip: 'পরের'),
          ],
        ),
        if (_offline)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(child: IconStat(icon: Icons.wifi_off_rounded, text: 'নেট নেই · যন্ত্রকণ্ঠে পড়া হচ্ছে')),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool big;
  final String tooltip;

  const _RoundBtn({required this.icon, required this.onTap, required this.tooltip, this.big = false});

  @override
  Widget build(BuildContext context) {
    final size = big ? 60.0 : 46.0;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: big ? ZlColors.amber : ZlColors.panelHi,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.5, color: big ? const Color(0xFF111827) : ZlColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// The team standing round the toolbox; the lead sways and shows a voice wave while talking.
class _Huddle extends StatefulWidget {
  final List<SmartLineman> team;
  final SmartLineman? lead;
  final bool talking;

  const _Huddle({required this.team, required this.lead, required this.talking});

  @override
  State<_Huddle> createState() => _HuddleState();
}

class _HuddleState extends State<_Huddle> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final others = widget.team.where((m) => m.id != lead?.id).toList();
    final row = [
      if (others.isNotEmpty) others.first,
      ?lead,
      ...others.skip(1),
    ];
    return Container(
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5EE), Color(0xFFFDE7C7)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 34,
            child: Container(color: const Color(0xFFE7C9A0)),
          ),
          Positioned.fill(
            top: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in row)
                  AnimatedBuilder(
                    animation: _c,
                    builder: (_, child) {
                      final isLead = m.id == lead?.id;
                      final t = isLead && widget.talking ? sin(_c.value * pi) * 3 : 0.0;
                      return Transform.translate(offset: Offset(0, -t), child: child);
                    },
                    child: SizedBox(
                      width: m.id == lead?.id ? 112 : 94,
                      height: m.id == lead?.id ? 170 : 150,
                      child: CrewFigure(man: m),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: ZlColors.amber,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.home_repair_service_rounded, color: Color(0xFF111827), size: 22),
              ),
            ),
          ),
          if (lead != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: ZlColors.bg.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) => Icon(
                        Icons.graphic_eq_rounded,
                        size: 16,
                        color: widget.talking ? Color.lerp(ZlColors.amber, ZlColors.green, _c.value) : ZlColors.soft,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${lead.name} · TBT নেতা', style: zlText(11.5, weight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final ZeroLossScenario scenario;
  final TbtTrack track;

  const _IntroCard({super.key, required this.scenario, required this.track});

  @override
  Widget build(BuildContext context) {
    final t = scenario.tbt[track];
    return ZlPanel(
      border: ZlColors.amber,
      child: Column(
        children: [
          Text(t?.title ?? '', style: zlText(26, weight: FontWeight.w900, color: ZlColors.amber)),
          const SizedBox(height: 2),
          Text(t?.subtitleBn ?? '', style: zlText(14, color: ZlColors.soft)),
          const SizedBox(height: 14),
          TbtLetterRow(scenario: scenario, track: track, size: 32, pop: true),
        ],
      ),
    );
  }
}

class _ListenedCard extends StatelessWidget {
  final ZeroLossScenario scenario;
  final TbtTrack track;

  const _ListenedCard({super.key, required this.scenario, required this.track});

  @override
  Widget build(BuildContext context) {
    return ZlPanel(
      border: ZlColors.green,
      child: Row(
        children: [
          const PopIn(child: Icon(Icons.verified_rounded, color: ZlColors.green, size: 44)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TBT শেষ', style: zlText(18, weight: FontWeight.w900, color: ZlColors.green)),
                Text('এবার মুখস্থ বলার পালা', style: zlText(13, color: ZlColors.soft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One mantra, revealed in step with the recorded voice.
class _StepCard extends StatelessWidget {
  final SafetyMantra mantra;
  final TbtTrack track;
  final int step;
  final int total;
  final int posMs;

  const _StepCard({
    super.key,
    required this.mantra,
    required this.track,
    required this.step,
    required this.total,
    required this.posMs,
  });

  @override
  Widget build(BuildContext context) {
    final c = mantraColor(mantra.id);
    final l = mantra.lines[track];
    final showWord = l == null || posMs >= l.wordAt;
    final showName = l == null || posMs >= l.nameAt;
    final showBody = l == null || posMs >= l.bodyAt;
    const fade = Duration(milliseconds: 350);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.32), ZlColors.panel],
        ),
        border: Border.all(color: c.withValues(alpha: 0.8), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PopIn(
                child: Container(
                  width: 74,
                  height: 74,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 14)],
                  ),
                  child: Text(l?.letter ?? '', style: zlText(42, weight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ধাপ ${n(step + 1)}/${n(total)}', style: zlText(11.5, weight: FontWeight.w700, color: ZlColors.soft)),
                    AnimatedOpacity(
                      opacity: showWord ? 1 : 0,
                      duration: fade,
                      child: Text(l?.word ?? '', style: zlText(24, weight: FontWeight.w900, color: c)),
                    ),
                    AnimatedOpacity(
                      opacity: showName ? 1 : 0,
                      duration: fade,
                      child: Row(
                        children: [
                          Icon(mantraIcon(mantra.id), size: 18, color: ZlColors.text),
                          const SizedBox(width: 6),
                          Text(mantra.nameBn, style: zlText(17, weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: showBody ? 1 : 0,
            duration: fade,
            child: AnimatedSlide(
              offset: showBody ? Offset.zero : const Offset(0, 0.2),
              duration: fade,
              child: Text(l?.bodyBn ?? mantra.ruleBn, style: zlText(16, weight: FontWeight.w700, color: ZlColors.cream, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recall: tap the eight mantras in order.
// ---------------------------------------------------------------------------

class _TbtRecall extends ConsumerStatefulWidget {
  final TbtTrack track;
  final ValueChanged<int> onDone;

  const _TbtRecall({super.key, required this.track, required this.onDone});

  @override
  ConsumerState<_TbtRecall> createState() => _TbtRecallState();
}

class _TbtRecallState extends ConsumerState<_TbtRecall> {
  late final List<SafetyMantra> _order;
  late final List<SafetyMantra> _deck;
  int _next = 0;
  int _mistakes = 0;
  int _stepMistakes = 0;
  int _streak = 0;
  final _shakes = <String, int>{};

  @override
  void initState() {
    super.initState();
    final s = ref.read(zeroLossProvider)!;
    _order = s.scenario.mantras;
    _deck = [..._order]..shuffle(Random(s.seed + s.missions.values.where((m) => m.chantMistakes != null).length + 7));
  }

  void _pick(SafetyMantra m) {
    if (_next >= _order.length) return;
    final voice = ref.read(zlVoiceProvider);
    voice.stop();
    if (m.id == _order[_next].id) {
      _streak++;
      playLessonCue(true);
      if (_streak >= 3) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      voice.say(m.nameBn);
      setState(() {
        _next++;
        _stepMistakes = 0;
      });
      if (_next >= _order.length) {
        HapticFeedback.heavyImpact();
        if (_mistakes == 0) {
          ZlFx.cue('sounds/safe_home.wav', volume: 0.85);
        }
        final s = ref.read(zeroLossProvider)!;
        voice.stop();
        voice.say(_mistakes == 0 ? s.scenario.voice['chant_ok_bn'] ?? '' : _order.map((e) => e.nameBn).join(', '));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onDone(_mistakes);
        });
      }
    } else {
      _streak = 0;
      playLessonCue(false);
      HapticFeedback.heavyImpact();
      setState(() {
        _mistakes++;
        _stepMistakes++;
        _shakes[m.id] = (_shakes[m.id] ?? 0) + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(zeroLossProvider)!;
    final hint = _stepMistakes >= 2 && _next < _order.length ? _order[_next].id : null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ZlPanel(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              children: [
                TbtLetterRow(scenario: s.scenario, track: widget.track, lit: _next, active: _next < _order.length ? _next : null),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _next == 0 ? 'প্রথম মন্ত্র কোনটা?' : '${_order[_next - 1].nameBn} → পরেরটা?',
                        style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft),
                      ),
                    ),
                    if (_streak >= 2) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 2),
                            Text('${n(_streak)}x কম্বো', style: zlText(11, weight: FontWeight.w900, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                    if (_mistakes > 0) ZlTag(label: '${n(_mistakes)} ভুল', color: ZlColors.red, icon: Icons.close_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: [
              for (final m in _deck)
                _order.indexOf(m) < _next
                    ? const SizedBox.shrink()
                    : Shake(
                        trigger: _shakes[m.id] ?? 0,
                        child: _RecallCard(mantra: m, track: widget.track, hint: hint == m.id, onTap: () => _pick(m)),
                      ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecallCard extends StatefulWidget {
  final SafetyMantra mantra;
  final TbtTrack track;
  final bool hint;
  final VoidCallback onTap;

  const _RecallCard({required this.mantra, required this.track, required this.hint, required this.onTap});

  @override
  State<_RecallCard> createState() => _RecallCardState();
}

class _RecallCardState extends State<_RecallCard> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _pressed = false;

  @override
  void didUpdateWidget(_RecallCard old) {
    super.didUpdateWidget(old);
    if (widget.hint && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!widget.hint && _pulse.isAnimating) _pulse.reset();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = mantraColor(widget.mantra.id);
    final letter = widget.mantra.lines[widget.track]?.letter ?? '';
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: (_pressed ? 0.94 : 1.0) * (1 + _pulse.value * 0.08),
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.withValues(alpha: 0.35), c.withValues(alpha: 0.12)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.hint ? Colors.white : c.withValues(alpha: 0.65),
              width: widget.hint ? 2.2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (letter.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      letter,
                      style: zlText(10, weight: FontWeight.w900, color: Colors.white70),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mantraIcon(widget.mantra.id), size: 30, color: c),
                    const SizedBox(height: 6),
                    Text(
                      widget.mantra.nameBn,
                      style: zlText(15, weight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TbtDone extends StatelessWidget {
  final ZeroLossScenario scenario;
  final TbtTrack track;
  final int mistakes;

  const _TbtDone({super.key, required this.scenario, required this.track, required this.mistakes});

  @override
  Widget build(BuildContext context) {
    final perfect = mistakes == 0;
    final order = scenario.mantras;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Center(
          child: PopIn(
            child: Icon(perfect ? Icons.workspace_premium_rounded : Icons.check_circle_rounded, size: 56, color: perfect ? ZlColors.amber : ZlColors.green),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            perfect ? 'নিখুঁত! +${n(scenario.chantBonusPoints)} পয়েন্ট' : 'হয়েছে · ${n(mistakes)} ভুল',
            style: zlText(17, weight: FontWeight.w900, color: perfect ? ZlColors.amber : ZlColors.green),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < order.length; i++)
          PopIn(
            delay: Duration(milliseconds: 60 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: mantraColor(order[i].id), borderRadius: BorderRadius.circular(9)),
                    child: Text(order[i].lines[track]?.letter ?? '', style: zlText(15, weight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Text(order[i].nameBn, style: zlText(14, weight: FontWeight.w800, color: mantraColor(order[i].id))),
                  ),
                  Expanded(child: Text(order[i].chantBn, style: zlText(13, color: ZlColors.soft))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
