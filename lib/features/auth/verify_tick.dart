import 'package:flutter/material.dart';

/// Grey check while unverified. Gold once an admin has verified the member.
class VerifyTick extends StatelessWidget {
  final bool gold;
  final double size;

  const VerifyTick({super.key, this.gold = false, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final icon = size * 0.72;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gold
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDE68A),
                  Color(0xFFF59E0B),
                  Color(0xFFD97706),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE7E5E4),
                  Color(0xFFD6D3D1),
                  Color(0xFFA8A29E),
                ],
              ),
        border: Border.all(
          color: gold ? const Color(0xFF92400E) : const Color(0xFF78716C),
          width: 1,
        ),
        boxShadow: gold
            ? const [
                BoxShadow(
                  color: Color(0x66F59E0B),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 0,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Icon(
        Icons.check_rounded,
        size: icon,
        color: gold ? Colors.white : const Color(0xFF57534E),
      ),
    );
  }
}
