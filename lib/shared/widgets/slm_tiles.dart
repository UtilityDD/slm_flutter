import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TileTone {
  final Color face;
  final Color edge;
  final Color iconFace;
  final Color iconInk;

  const TileTone({
    required this.face,
    required this.edge,
    required this.iconFace,
    required this.iconInk,
  });

  static const quiz = TileTone(
    face: Color(0xFFFFF5EF),
    edge: Color(0xFFF3B392),
    iconFace: Color(0xFFFFB088),
    iconInk: Color(0xFFC2410C),
  );
  static const learn = TileTone(
    face: Color(0xFFEFFBF7),
    edge: Color(0xFF8FD4C2),
    iconFace: Color(0xFF7EE0C8),
    iconInk: Color(0xFF0F766E),
  );
  static const safe = TileTone(
    face: Color(0xFFF1F7FF),
    edge: Color(0xFF9EC4F2),
    iconFace: Color(0xFF93C5FD),
    iconInk: Color(0xFF1D4ED8),
  );
  static const folder = TileTone(
    face: Color(0xFFFFFDF9),
    edge: Color(0xFFE6D3C2),
    iconFace: Color(0xFFF3E4D4),
    iconInk: Color(0xFF78716C),
  );
  static const story = TileTone(
    face: Color(0xFFFFF6F1),
    edge: Color(0xFFF0B89A),
    iconFace: Color(0xFFFB9B7A),
    iconInk: Color(0xFFC2410C),
  );
  static const prize = TileTone(
    face: Color(0xFFFFFBEB),
    edge: Color(0xFFF0D07A),
    iconFace: Color(0xFFFBBF24),
    iconInk: Color(0xFFB45309),
  );
  static const phone = TileTone(
    face: Color(0xFFF5F7F9),
    edge: Color(0xFFC5D0DA),
    iconFace: Color(0xFF94A3B8),
    iconInk: Color(0xFF334155),
  );
  static const idea = TileTone(
    face: Color(0xFFF7FEE7),
    edge: Color(0xFFC4DD6A),
    iconFace: Color(0xFFA3E635),
    iconInk: Color(0xFF3F6212),
  );
  static const video = TileTone(
    face: Color(0xFFFDF4FF),
    edge: Color(0xFFE9B4F0),
    iconFace: Color(0xFFE879F9),
    iconInk: Color(0xFFA21CAF),
  );
  static const tools = TileTone(
    face: Color(0xFFF8F7F6),
    edge: Color(0xFFD6CFC8),
    iconFace: Color(0xFFD6D3D1),
    iconInk: Color(0xFF44403C),
  );
  static const sos = TileTone(
    face: Color(0xFFFFE4E6),
    edge: Color(0xFFE11D48),
    iconFace: Color(0xFFE11D48),
    iconInk: Color(0xFFFFFFFF),
  );
  static const heart = TileTone(
    face: Color(0xFFFFF1F2),
    edge: Color(0xFFF0A8B8),
    iconFace: Color(0xFFFB7185),
    iconInk: Color(0xFF9F1239),
  );
  static const indigo = TileTone(
    face: Color(0xFFF4F3FF),
    edge: Color(0xFFC4B5FD),
    iconFace: Color(0xFFC4B5FD),
    iconInk: Color(0xFF4338CA),
  );
  static const bell = TileTone(
    face: Color(0xFFEEF2FF),
    edge: Color(0xFFA5B4FC),
    iconFace: Color(0xFF818CF8),
    iconInk: Color(0xFF3730A3),
  );
  static const forum = TileTone(
    face: Color(0xFFECFEFF),
    edge: Color(0xFF67E8F9),
    iconFace: Color(0xFF22D3EE),
    iconInk: Color(0xFF0E7490),
  );
  static const share = TileTone(
    face: Color(0xFFF0F9FF),
    edge: Color(0xFF7DD3FC),
    iconFace: Color(0xFF38BDF8),
    iconInk: Color(0xFF0369A1),
  );
}

class Home3dTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final TileTone tone;
  final VoidCallback onTap;
  final String? chip;
  final bool live;

  const Home3dTile({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.chip,
    this.live = false,
  });

  @override
  State<Home3dTile> createState() => _Home3dTileState();
}

class _Home3dTileState extends State<Home3dTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final depth = _pressed ? 1.0 : 5.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.88),
              widget.tone.face,
            ],
          ),
          boxShadow: [
            BoxShadow(color: widget.tone.edge, offset: Offset(1, depth), blurRadius: 0),
            BoxShadow(
              color: const Color(0x296B4423),
              offset: Offset(2, depth + 1),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0x291C1917),
              offset: const Offset(2, 8),
              blurRadius: 8,
              spreadRadius: -6,
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1 / 0.94,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconBadge(
                icon: widget.icon,
                tone: widget.tone,
                chip: widget.chip,
                live: widget.live,
                size: 71,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class More3dRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final TileTone tone;
  final VoidCallback onTap;
  final bool emphasize;

  const More3dRow({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.emphasize = false,
  });

  @override
  State<More3dRow> createState() => _More3dRowState();
}

class _More3dRowState extends State<More3dRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        margin: EdgeInsets.only(bottom: widget.emphasize ? 4 : 0),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: widget.tone.face,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: widget.tone.edge, offset: const Offset(1, 4), blurRadius: 0),
            const BoxShadow(
              color: Color(0x141C1917),
              offset: Offset(1, 6),
              blurRadius: 8,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            _IconBadge(icon: widget.icon, tone: widget.tone, size: 51),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: widget.emphasize ? FontWeight.w800 : FontWeight.w700,
                  height: 1.35,
                  color: widget.emphasize ? const Color(0xFF9F1239) : AppColors.inkSoft,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.emphasize ? const Color(0xFFE11D48) : const Color(0xFFC4B8AC),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final TileTone tone;
  final double size;
  final String? chip;
  final bool live;

  const _IconBadge({
    required this.icon,
    required this.tone,
    required this.size,
    this.chip,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + (chip == null ? 0 : 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.45),
                radius: 1.05,
                colors: [
                  Colors.white.withValues(alpha: 0.72),
                  tone.iconFace,
                ],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x29FFFFFF), offset: Offset(0, 2), blurRadius: 0),
              ],
            ),
            child: Icon(icon, color: tone.iconInk, size: size * 0.46),
          ),
          if (live)
            const Positioned(
              top: 2,
              right: 6,
              child: _LiveDot(),
            ),
          if (chip != null)
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFFFF6EF), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFC2410C), offset: Offset(1, 2), blurRadius: 0),
                  ],
                ),
                child: Text(
                  chip!,
                  style: const TextStyle(
                    color: Color(0xFFFFF7ED),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14 * _controller.value,
                height: 14 * _controller.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEA580C).withValues(alpha: 1 - _controller.value),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
