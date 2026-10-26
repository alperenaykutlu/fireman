import 'package:flutter/material.dart';
import '../../core/character/animated_character_painter.dart';
import '../../core/character/character_state.dart';

class FighterPortraitPainter extends CustomPainter {
  FighterPortraitPainter({required this.hatColor, required this.bodyColor, required this.isAlive});

  final Color hatColor;
  final Color bodyColor;
  final bool isAlive;

  @override
  void paint(Canvas canvas, Size size) {
    FirefighterCharacterPainter(
      animTime: 0,
      state: isAlive ? CharacterAnimState.idle : CharacterAnimState.hit,
      direction: CharacterDirection.down,
      suitColor: isAlive ? bodyColor : Colors.black,
      helmetColor: isAlive ? hatColor : Colors.black,
      skinColor: isAlive ? const Color(0xFFFFD1A4) : Colors.black,
      accessoryColor: isAlive ? const Color(0xFF38BDF8) : Colors.black,
      showShadow: false,
      showHose: false,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant FighterPortraitPainter oldDelegate) =>
      oldDelegate.hatColor != hatColor ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.isAlive != isAlive;
}
