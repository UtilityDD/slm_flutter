import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/bangla_read_aloud.dart';
import 'zero_loss_engine.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

/// Cinematic open: আট মন্ত্র → SAFE HOME letters → control call → crew reply → shift.
class ZeroLossOpening extends ConsumerStatefulWidget {
  final ZeroLossState state;

  const ZeroLossOpening({super.key, required this.state});

  @override
  ConsumerState<ZeroLossOpening> createState() => _ZeroLossOpeningState();
}

enum _OpenAct { hero, spell, letter, call, reply }

class _ZeroLossOpeningState extends ConsumerState<ZeroLossOpening> with TickerProviderStateMixin {
  static const _safeHome = 'SAFE HOME';
  static const _rate = 0.44;

  late final ZlVoice _voice;
  late final AnimationController _fire;
  late final AnimationController _fluid;

  _OpenAct _act = _OpenAct.hero;
  int _spellLen = 0;
  int _letter = 0;
  int _callBeat = 0;
  int _clause = 0;
  Timer? _spellTimer;
  String? _wireWhere;
  String? _feederName;

  ZeroLossState get s => widget.state;

  /// Touch-paced SAFE HOME teaching lines (letter → English → Bangla → one line).
  static const _teach = <(String, String, String, String)>[
    ('S', 'Stop', 'থামো', 'কাজের আগে সবাই মিলে নিজেদের মধ্যে আলোচনা করুন — কী, কেন, কোথায়, কীভাবে জানুন।'),
    ('A', 'Armour', 'কবচ', 'মানে PPE। দেখে নিন সব কবচ ঠিক আছে কি না — হেলমেট, গ্লাভস, বুট, বেল্ট।'),
    ('F', 'Form', 'পারমিট', 'লিখিত PTW হাতে নিন। ফিডারের নাম মিলিয়ে নিন। ফোনে শুধু নয়।'),
    ('E', 'End power', 'কাটো', 'দুদিক অফ করুন। তালা মারুন। ডেঞ্জার বোর্ড ঝোলান।'),
    ('H', 'Hold earth', 'আর্থ', 'আগে টেস্টার, তারপর ডিসচার্জ, তারপর দুদিকে আর্থ বাঁধুন।'),
    ('O', 'Ok fence', 'ফিতে', 'লাল ফিতে ও কোন দিয়ে জায়গা ঘেরুন। সাধারণ লোক সরান।'),
    ('M', 'Mend', 'কাজ', 'বেল্ট লক করে তবে মেরামত শুরু। তাড়াহুড়োয় হাত দেবেন না।'),
    ('E', 'Exit', 'গোনা', 'কাজ শেষে লোক ও হাতিয়ার গোনুন। আর্থ শেষে খুলুন। পারমিট ফেরত দিন।'),
  ];

  @override
  void initState() {
    super.initState();
    _voice = ref.read(zlVoiceProvider);
    _fire = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _fluid = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    final rng = Random(s.seed ^ 41);
    final f0 = s.scenario.faults.first;
    final spots = f0.wireSpotsBn;
    _wireWhere = spots.isNotEmpty ? spots[rng.nextInt(spots.length)] : _wireSpot(f0, rng);
    _feederName = _feederLabel(s.setting, rng);
  }

  @override
  void dispose() {
    _spellTimer?.cancel();
    _fire.dispose();
    _fluid.dispose();
    _voice.stop();
    super.dispose();
  }

  static String _wireSpot(FaultDispatch f, Random rng) {
    final byFault = switch (f.id) {
      'wire_on_ground' || 'service_connection' || 'ab_cable_piercing' => ['রাস্তায়', 'মাঠে', 'হাটের পাশে'],
      'tree_trimming' => ['গাছের নিচে', 'মাঠে', 'বাড়ির পাশে'],
      'ug_cable_joint' => ['খাতায়', 'রাস্তার নিচে', 'পুকুর পাড়ে'],
      'dtr_hg_fuse' || 'dtr_maintenance' => ['ডিটিআর কাছে', 'পোল গাছের নিচে'],
      'jumper_cutting' || 'insulator_double_pole' => ['ডাবল পোলে', 'স্প্যানে'],
      'leaning_pole_repair' => ['হেলানো খুঁটিতে', 'রাস্তার ধারে'],
      _ => ['মাঠে', 'রাস্তায়', 'পুকুরে', 'বাঁশবাগানে'],
    };
    return byFault[rng.nextInt(byFault.length)];
  }

  static String _feederLabel(ZeroLossSetting set, Random rng) {
    final tags = ['ফিডার-১', 'ফিডার-২', 'রুরাল ফিডার', 'ইন্ডাস্ট্রিয়াল ফিডার', 'মার্কেট ফিডার'];
    return '${set.office.replaceAll(' সাপ্লাই অফিস', '')} ${tags[rng.nextInt(tags.length)]}';
  }

  String get _opOpen =>
      '${s.setting.districtBn} কন্ট্রোল রুম থেকে বলছি।';

  String get _opFault {
    final f = s.scenario.faults.first;
    final pack = SiteHazardPack.fromFault(f);
    // Keep call consistent with the worksite hazard (not a generic snapped-wire line).
    final core = f.id == 'wire_on_ground'
        ? '১১ হাজার ভোল্টের তার ছিঁড়ে $_wireWhere পড়ে আছে।'
        : '${f.shortTitleBn} — $_wireWhere।';
    return '$core $_feederName ব্রেকডাউন। ${pack.operatorLineBn.split('।').first}।';
  }

  String get _linemanAsk => 'কোথায়?';

  String get _opPlace =>
      '${s.mission(s.scenario.faults.first.id).location}-এ। দ্রুত যান, কিন্তু সেফ হোম মেনে।';

  String get _crewReply => 'ঠিক আছে। আমরা কাজে যাচ্ছি। পিটিডব্লিউ রেডি রাখুন।';

  void _skipToCall() {
    _spellTimer?.cancel();
    _voice.stop();
    HapticFeedback.selectionClick();
    setState(() {
      _act = _OpenAct.call;
      _callBeat = 0;
      _clause = 0;
    });
    _speakCall();
  }

  void _beginSpell() {
    HapticFeedback.mediumImpact();
    _voice.stop();
    setState(() {
      _act = _OpenAct.spell;
      _spellLen = 0;
    });
    _spellTimer?.cancel();
    _spellTimer = Timer.periodic(const Duration(milliseconds: 110), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_spellLen >= _safeHome.length) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 420), () {
          if (!mounted || _act != _OpenAct.spell) return;
          setState(() {
            _act = _OpenAct.letter;
            _letter = 0;
          });
          _fluid.forward(from: 0);
          _speakLetter();
        });
        return;
      }
      setState(() => _spellLen++);
    });
  }

  void _speakLetter() {
    if (_letter < 0 || _letter >= _teach.length) return;
    final t = _teach[_letter];
    _voice.say('${t.$1}. ${t.$2}. ${t.$3}. ${t.$4}', rate: _rate);
  }

  void _pace() {
    switch (_act) {
      case _OpenAct.hero:
        _beginSpell();
      case _OpenAct.spell:
        _spellTimer?.cancel();
        if (_spellLen < _safeHome.length) {
          setState(() => _spellLen = _safeHome.length);
          Future.delayed(const Duration(milliseconds: 280), () {
            if (!mounted || _act != _OpenAct.spell) return;
            setState(() {
              _act = _OpenAct.letter;
              _letter = 0;
            });
            _fluid.forward(from: 0);
            _speakLetter();
          });
        }
      case _OpenAct.letter:
        _voice.stop();
        HapticFeedback.selectionClick();
        if (_letter >= _teach.length - 1) {
          _skipToCall();
          return;
        }
        setState(() => _letter++);
        _fluid.forward(from: 0);
        _speakLetter();
      case _OpenAct.call:
        _nextCall();
      case _OpenAct.reply:
        break;
    }
  }

  void _speakCall() {
    final line = switch (_callBeat) {
      0 => _opOpen,
      1 => _opFault,
      2 => _linemanAsk,
      3 => _opPlace,
      _ => '',
    };
    if (line.isEmpty) return;
    _voice.say(line, rate: _rate, onClause: (i) {
      if (mounted && _act == _OpenAct.call && _clause != i) setState(() => _clause = i);
    });
  }

  void _nextCall() {
    _voice.stop();
    HapticFeedback.selectionClick();
    if (_callBeat >= 3) {
      setState(() => _act = _OpenAct.reply);
      _voice.say(_crewReply, rate: _rate);
      return;
    }
    setState(() {
      _callBeat++;
      _clause = 0;
    });
    _speakCall();
  }

  void _enterShift() {
    _voice.stop();
    HapticFeedback.mediumImpact();
    ref.read(zeroLossProvider.notifier).startShift();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _act == _OpenAct.reply ? null : _pace,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 480),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey('${_act.name}-$_letter-$_callBeat'),
          child: switch (_act) {
            _OpenAct.hero => _HeroAct(fire: _fire, onOpen: _beginSpell, onSkip: _skipToCall),
            _OpenAct.spell => _SpellAct(shown: _safeHome.substring(0, _spellLen)),
            _OpenAct.letter => _LetterAct(teach: _teach[_letter], fluid: _fluid),
            _OpenAct.call => _CallAct(
                state: s,
                beat: _callBeat,
                clause: _clause,
                opOpen: _opOpen,
                opFault: _opFault,
                ask: _linemanAsk,
                place: _opPlace,
                onNext: _nextCall,
              ),
            _OpenAct.reply => _ReplyAct(line: _crewReply, onGo: _enterShift),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Acts
// ---------------------------------------------------------------------------

class _HeroAct extends StatelessWidget {
  final AnimationController fire;
  final VoidCallback onOpen;
  final VoidCallback onSkip;

  const _HeroAct({required this.fire, required this.onOpen, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.15),
              radius: 1.1,
              colors: [Color(0xFF2A1208), Color(0xFF0B1220)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: fire,
          builder: (_, _) => CustomPaint(
            painter: _FireGlowPainter(t: fire.value),
            child: const SizedBox.expand(),
          ),
        ),
        Column(
          children: [
            const Spacer(flex: 3),
            GestureDetector(
              onTap: onOpen,
              child: Text(
                'আট মন্ত্র',
                textAlign: TextAlign.center,
                style: zlText(48, weight: FontWeight.w900, height: 1.05).copyWith(
                  color: const Color(0xFFFFF3E0),
                  shadows: const [
                    Shadow(color: Color(0xFFFF6B00), blurRadius: 28),
                    Shadow(color: Color(0xCCFF3D00), blurRadius: 54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('SAFE HOME', style: zlText(14, weight: FontWeight.w800, color: ZlColors.amber)),
            const Spacer(flex: 2),
            TextButton(
              onPressed: onSkip,
              child: Text('এড়িয়ে যান', style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft)),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ],
    );
  }
}

/// Glowing fire flicker — intensity only, no breathing scale.
class _FireGlowPainter extends CustomPainter {
  final double t;

  _FireGlowPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.42);
    final flicker = 0.72 + 0.28 * sin(t * pi);
    final layers = [
      (size.shortestSide * 0.55, Color.fromRGBO(255, 60, 0, 0.10 * flicker)),
      (size.shortestSide * 0.34, Color.fromRGBO(255, 120, 20, 0.22 * flicker)),
      (size.shortestSide * 0.18, Color.fromRGBO(255, 200, 80, 0.35 * flicker)),
    ];
    for (final (r, color) in layers) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(c, r, [color, color.withValues(alpha: 0)]),
      );
    }
    // Ember sparks
    final rng = Random(7);
    for (var i = 0; i < 14; i++) {
      final a = rng.nextDouble() * pi * 2;
      final d = size.shortestSide * (0.08 + 0.22 * rng.nextDouble()) * (0.85 + 0.2 * flicker);
      final p = c + Offset(cos(a), sin(a) * 0.7) * d;
      canvas.drawCircle(
        p,
        1.4 + rng.nextDouble() * 2.2,
        Paint()..color = Color.fromRGBO(255, 180 + rng.nextInt(60), 40, 0.35 + 0.4 * flicker * rng.nextDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireGlowPainter old) => old.t != t;
}

class _SpellAct extends StatelessWidget {
  final String shown;

  const _SpellAct({required this.shown});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ZlColors.bg,
      child: Center(
        child: Text(
          shown,
          textAlign: TextAlign.center,
          style: zlText(42, weight: FontWeight.w900, height: 1.1).copyWith(
            letterSpacing: 4,
            color: ZlColors.amber,
            shadows: const [Shadow(color: Color(0x99FF6B00), blurRadius: 22)],
          ),
        ),
      ),
    );
  }
}

class _LetterAct extends StatelessWidget {
  final (String, String, String, String) teach;
  final AnimationController fluid;

  const _LetterAct({required this.teach, required this.fluid});

  @override
  Widget build(BuildContext context) {
    final (letter, en, bn, line) = teach;
    return AnimatedBuilder(
      animation: fluid,
      builder: (_, _) {
        final t = Curves.easeOutCubic.transform(fluid.value);
        return ColoredBox(
          color: ZlColors.bg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              children: [
                const Spacer(),
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - t)),
                    child: Text(
                      letter,
                      style: zlText(88, weight: FontWeight.w900, color: ZlColors.amber, height: 1).copyWith(
                        shadows: const [Shadow(color: Color(0xAAFF6B00), blurRadius: 30)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: ((t - 0.15) / 0.85).clamp(0.0, 1.0),
                  child: Text(en, style: zlText(28, weight: FontWeight.w900)),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: ((t - 0.28) / 0.72).clamp(0.0, 1.0),
                  child: Text(bn, style: zlText(22, weight: FontWeight.w800, color: ZlColors.blue)),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: ((t - 0.4) / 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - ((t - 0.4) / 0.6).clamp(0.0, 1.0))),
                    child: Text(line, textAlign: TextAlign.center, style: zlText(17, weight: FontWeight.w600, height: 1.45)),
                  ),
                ),
                const Spacer(),
                Text('স্পর্শ করে এগোন', style: zlText(12, color: ZlColors.soft)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CallAct extends StatelessWidget {
  final ZeroLossState state;
  final int beat;
  final int clause;
  final String opOpen;
  final String opFault;
  final String ask;
  final String place;
  final VoidCallback onNext;

  const _CallAct({
    required this.state,
    required this.beat,
    required this.clause,
    required this.opOpen,
    required this.opFault,
    required this.ask,
    required this.place,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final speech = switch (beat) {
      0 => opOpen,
      1 => opFault,
      2 => ask,
      _ => place,
    };
    final bits = speechBits(speech);
    final line = bits.isEmpty ? speech : bits[clause.clamp(0, bits.length - 1)].shown;
    final fromLineman = beat == 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/zero_loss/scene/bg_control_room.webp', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0x00000000), Color(0xF20B1220)],
              stops: [0, 0.4, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!fromLineman) ...[
                    _Face(
                      image: 'assets/zero_loss/scene/operator_control.jpg',
                      label: 'কন্ট্রোল',
                      alignment: const Alignment(0, -0.2),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _Bubble(
                      title: fromLineman ? 'লাইন্ম্যান' : 'অপারেটর',
                      line: line,
                      alignEnd: fromLineman,
                    ),
                  ),
                  if (fromLineman) ...[
                    const SizedBox(width: 10),
                    _Face(
                      image: 'assets/zero_loss/scene/spr_man_phone.webp',
                      label: 'আপনি',
                      alignment: Alignment.center,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ZlButton(label: 'পরের', icon: Icons.arrow_forward_rounded, onTap: onNext),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplyAct extends StatelessWidget {
  final String line;
  final VoidCallback onGo;

  const _ReplyAct({required this.line, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/zero_loss/scene/bg_pole_storm.webp', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0x22000000), Color(0xF20B1220)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/zero_loss/scene/spr_man_phone.webp',
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.engineering_rounded, size: 96, color: ZlColors.amber),
              ),
              const SizedBox(height: 12),
              Text('আপনি ভাবছেন…', style: zlText(13, color: ZlColors.soft)),
              const SizedBox(height: 10),
              _Bubble(title: 'লাইন্ম্যান', line: line, alignEnd: false),
              const SizedBox(height: 18),
              ZlButton(label: 'টিম সাজান', icon: Icons.groups_rounded, onTap: onGo),
            ],
          ),
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  final String image;
  final String label;
  final Alignment alignment;

  const _Face({required this.image, required this.label, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ZlColors.amber, width: 2.2),
            image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover, alignment: alignment),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: zlText(11, weight: FontWeight.w800, color: ZlColors.amber)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String title;
  final String line;
  final bool alignEnd;

  const _Bubble({required this.title, required this.line, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF0141C2C),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(alignEnd ? 18 : 4),
          bottomRight: Radius.circular(alignEnd ? 4 : 18),
        ),
        border: Border.all(color: ZlColors.amber.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: zlText(12, weight: FontWeight.w800, color: ZlColors.amber)),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(line, key: ValueKey(line), style: zlText(18, weight: FontWeight.w800, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
