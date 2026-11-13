import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';

/// Wrong answers in a row per lesson level (picture or "why" choice), kept
/// across replays in this app session. Every third in a row offers the
/// lesson; a right answer or reading the lesson starts the count again.
abstract final class LessonMissTally {
  static final Map<String, int> _misses = {};

  /// Records a miss; true when this lesson has just reached another three in a row.
  static bool miss(String lessonId) {
    final n = (_misses[lessonId] ?? 0) + 1;
    _misses[lessonId] = n;
    return n % 3 == 0;
  }

  /// A right answer breaks the run.
  static void hit(String lessonId) => _misses.remove(lessonId);

  static void read(String lessonId) => _misses.remove(lessonId);

  static void resetAll() => _misses.clear();
}

/// End-of-level nudge to read the lesson, shown when no mistake offer came up.
typedef ReadNudge = ({String title, String message});

/// Picks a different nudge each time, never the one this lesson showed last.
abstract final class ReadLessonNudges {
  static const all = <ReadNudge>[
    (title: 'আরও জানুন', message: 'খেলায় যা দেখলেন, পাঠে তার পুরো কারণ আছে।'),
    (title: 'জেনে রাখা ভালো', message: 'দুই মিনিটের পাঠ—মাঠে কাজে লাগবে সারা জীবন।'),
    (title: 'না জানলে বিপদ হতে পারে', message: 'একটা ছোট ভুলেই দুর্ঘটনা। পাঠটা একবার পড়ে নিন।'),
    (title: 'যত জানবেন, তত নিরাপদ', message: 'পাঠে আরও কিছু নিয়ম আছে, যা খেলায় আসেনি।'),
    (title: 'পাকা লাইনম্যান হোন', message: 'উত্তর জানা ভালো, কারণ জানা আরও ভালো।'),
    (title: 'নিজের জন্য, পরিবারের জন্য', message: 'নিরাপদে বাড়ি ফেরার নিয়মগুলো পাঠে লেখা আছে।'),
    (title: 'একবার ঝালিয়ে নিন', message: 'পড়ে নিলে পরের লেভেল আরও সহজ লাগবে।'),
    (title: 'ভেতরের কথাটা জানুন', message: 'কেন এই নিয়ম—পাঠে সহজ ভাষায় বলা আছে।'),
  ];

  static final Map<String, int> _last = {};
  static int? _lastAny;

  static ReadNudge next(String lessonId, [Random? rng]) {
    final r = rng ?? Random();
    final avoid = {?_last[lessonId], ?_lastAny};
    final pool = [for (var i = 0; i < all.length; i++) if (!avoid.contains(i)) i];
    final pick = pool[r.nextInt(pool.length)];
    _last[lessonId] = pick;
    _lastAny = pick;
    return all[pick];
  }

  static void resetAll() {
    _last.clear();
    _lastAny = null;
  }
}

/// The read-lesson button in a level's top bar: the book icon only (owner's
/// brief, Nov 2026 — no "পাঠ" text), a 44 dp touch target around a smaller
/// gold-rimmed disc. Glows gold while the offer is tucked away ([hot]).
class ReadLessonPill extends StatelessWidget {
  const ReadLessonPill({super.key, required this.hot, required this.onTap});

  final bool hot;
  final VoidCallback onTap;

  /// Touch target (dp), never smaller.
  static const double tapSize = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'পাঠ পড়ুন',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: tapSize,
          child: Center(
            child: AnimatedContainer(
              duration: SlmMotion.base,
              curve: Curves.easeOut,
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: hot ? SlmGradients.gold : null,
                color: hot ? null : SlmColors.navy950.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hot ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: hot
                    ? [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.6), blurRadius: 16)]
                    : const [],
              ),
              child: Icon(Icons.menu_book_rounded, size: 19, color: hot ? SlmColors.navy950 : SlmColors.gold200),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dimmed board + the offer card, flying between the pill ([from], relative
/// to this layer's centre) and the centre. Drive [fly] 0 → 1 to open.
class ReadLessonFlyLayer extends StatelessWidget {
  const ReadLessonFlyLayer({
    super.key,
    required this.fly,
    required this.curve,
    required this.from,
    required this.onScrimTap,
    required this.card,
  });

  final AnimationController fly;
  final Animation<double> curve;
  final Offset from;
  final VoidCallback onScrimTap;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fly,
      child: card,
      builder: (_, card) {
        final t = curve.value;
        final fade = fly.value;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onScrimTap,
                child: ColoredBox(color: const Color(0xFF040814).withValues(alpha: 0.62 * fade)),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: from * (1 - t),
                child: Transform.scale(
                  scale: 0.08 + 0.92 * t,
                  child: Opacity(opacity: (fade * 1.6).clamp(0.0, 1.0), child: card),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// [pill] centre relative to [layer] centre, or null before layout.
Offset? readLessonFrom(GlobalKey pill, GlobalKey layer) {
  final p = pill.currentContext?.findRenderObject() as RenderBox?;
  final l = layer.currentContext?.findRenderObject() as RenderBox?;
  if (p == null || l == null || !p.hasSize || !l.hasSize) return null;
  return p.localToGlobal(p.size.center(Offset.zero)) - l.localToGlobal(l.size.center(Offset.zero));
}

/// Offer to read the lesson: শুরু করুন opens it, এখন না tucks it into the pill.
class ReadLessonCard extends StatelessWidget {
  const ReadLessonCard({
    super.key,
    required this.atStart,
    required this.lessonLine,
    required this.onStart,
    required this.onLater,
    this.nudge,
  });

  final bool atStart;
  final String lessonLine;
  final VoidCallback onStart;
  final VoidCallback onLater;

  /// End-of-level wording; the buttons then read পরে পড়ব / পাঠ পড়ুন.
  final ReadNudge? nudge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 304,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF22324F), Color(0xFF0E172C)],
        ),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.85), width: 1.6),
        boxShadow: [
          BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 1),
          const BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SlmGradients.gold,
              boxShadow: [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.55), blurRadius: 18)],
            ),
            child: const Icon(Icons.menu_book_rounded, size: 34, color: SlmColors.navy950),
          ),
          const SizedBox(height: 14),
          Text(
            nudge?.title ?? 'পাঠটা পড়ে নিন',
            textAlign: TextAlign.center,
            style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: SlmColors.gold200),
          ),
          const SizedBox(height: 6),
          Text(
            nudge?.message ??
                (atStart ? 'শুরুর আগে একবার পড়ে নিলে সব উত্তর সহজ হবে।' : 'সঠিক উত্তর পাঠেই আছে—একবার দেখে নিন।'),
            textAlign: TextAlign.center,
            style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.ivory),
          ),
          const SizedBox(height: 8),
          Text(
            lessonLine,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: SlmColors.mist),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _CardButton(label: nudge == null ? 'এখন না' : 'পরে পড়ব', filled: false, onTap: onLater)),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  label: nudge == null ? 'শুরু করুন' : 'পাঠ পড়ুন',
                  filled: true,
                  icon: Icons.play_arrow_rounded,
                  onTap: onStart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, required this.onTap, this.icon});

  final String label;
  final bool filled;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? SlmColors.navy950 : SlmColors.ivory;
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled ? SlmGradients.gold : null,
          color: filled ? null : SlmColors.navy950.withValues(alpha: 0.5),
          border: Border.all(color: filled ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: ink), const SizedBox(width: 4)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
