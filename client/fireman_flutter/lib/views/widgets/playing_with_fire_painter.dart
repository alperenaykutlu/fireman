import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/character/animated_character_painter.dart';
import '../../core/character/character_state.dart';
import '../../models/game_elements.dart';
import '../../viewmodels/gameplay_viewmodel.dart';
class PlayingWithFirePainter extends CustomPainter {
  final GameplayViewModel vm;

  // Önbelleklenmiş Paint nesneleri (Her karede new Paint() tahsisatını önler)
  static final Paint _bgPaint = Paint()..color = const Color(0xFF222222);
  static final Paint _floorLightPaint = Paint()
    ..color = const Color(0xFF343A43);
  static final Paint _floorDarkPaint = Paint()..color = const Color(0xFF2D333C);
  static final Paint _gridBorderPaint = Paint()
    ..color = const Color(0xFF2C2C2C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  static final Paint _stonePaint = Paint()..color = const Color(0xFFB5A67D);
  static final Paint _stoneLightPaint = Paint()
    ..color = const Color(0xFFDCD2AD)
    ..strokeWidth = 2;
  static final Paint _stoneDarkPaint = Paint()
    ..color = const Color(0xFF6B5D3D)
    ..strokeWidth = 2;

  static final Paint _greyStonePaint = Paint()..color = const Color(0xFF64748B);
  static final Paint _greyStoneLightPaint = Paint()
    ..color = const Color(0xFF94A3B8)
    ..strokeWidth = 2;
  static final Paint _greyStoneDarkPaint = Paint()
    ..color = const Color(0xFF334155)
    ..strokeWidth = 2;
  static final Paint _greyStoneInnerPaint = Paint()
    ..color = const Color(0xFF475569)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final Paint _barrelBandPaint = Paint()
    ..color = const Color(0xFF262626)
    ..strokeWidth = 2.5;
  static final Paint _barrelLidPaint = Paint()..color = const Color(0xFFB91C1C);

  static final Paint _dynStickPaint = Paint()..color = const Color(0xFFDC2626);
  static final Paint _dynSlideStickPaint = Paint()
    ..color = Colors.amber.shade800;
  static final Paint _dynStickLinePaint = Paint()
    ..color = const Color(0xFF991B1B)
    ..strokeWidth = 1.5;
  static final Paint _dynTapePaint = Paint()..color = const Color(0xFF18181B);
  static final Paint _dynFusePaint = Paint()
    ..color = Colors.white70
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  static final Paint _whiteFlashPaint = Paint()..color = Colors.white;

  PlayingWithFirePainter({required this.vm});

  @override
  void paint(Canvas canvas, Size size) {
    if (vm.grid.isEmpty) return;
    final cellW = size.width / vm.grid.first.length;
    final cellH = size.height / vm.grid.length;

    // Only animated game entities are repainted on each simulation update.
    for (final p in vm.powerUps) {
      final rect = Rect.fromLTWH(p.x * cellW, p.y * cellH, cellW, cellH);
      _drawPowerUp(canvas, rect, p.type);
    }

    // 4. Dinamitler
    for (final dyn in vm.dynamites) {
      final rect = Rect.fromLTWH(dyn.x * cellW, dyn.y * cellH, cellW, cellH);
      _drawDynamite(
        canvas,
        rect,
        isSliding: dyn.slideDx != 0 || dyn.slideDy != 0,
        timeLeft: dyn.timeLeft,
      );
    }

    // 5. Patlama Alevleri
    for (final exp in vm.explosions) {
      final rect = Rect.fromLTWH(exp.x * cellW, exp.y * cellH, cellW, cellH);
      _drawExplosion(canvas, rect, exp);
    }

    // 6. Savaşçılar (Oyuncu ve Botlar)
    for (final fighter in vm.fighters) {
      if (fighter.status == PlayerStatus.alive) {
        final rect = Rect.fromLTWH(
          fighter.x * cellW,
          fighter.y * cellH,
          cellW,
          cellH,
        );
        _drawFighterSprite(canvas, rect, fighter);
      }
    }
  }

  void _drawStoneBlock(Canvas canvas, Rect rect) {
    final inset = rect.deflate(rect.shortestSide * .08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(rect.shortestSide * .12)),
      _stonePaint,
    );
    canvas.drawLine(
      inset.topLeft,
      inset.topRight,
      _stoneLightPaint..strokeWidth = rect.shortestSide * .08,
    );
    canvas.drawLine(
      inset.topLeft,
      inset.bottomLeft,
      _stoneLightPaint..strokeWidth = rect.shortestSide * .08,
    );
    canvas.drawLine(
      inset.bottomLeft,
      inset.bottomRight,
      _stoneDarkPaint..strokeWidth = rect.shortestSide * .08,
    );
    canvas.drawLine(
      inset.topRight,
      inset.bottomRight,
      _stoneDarkPaint..strokeWidth = rect.shortestSide * .08,
    );
    final face = inset.deflate(rect.shortestSide * .15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(rect.shortestSide * .08)),
      Paint()..color = const Color(0xFF998A63),
    );
    final mortar = Paint()
      ..color = const Color(0xFF6F6247)
      ..strokeWidth = rect.shortestSide * .035;
    canvas.drawLine(
      Offset(face.left, face.center.dy),
      Offset(face.right, face.center.dy),
      mortar,
    );
    canvas.drawLine(
      Offset(face.center.dx, face.top),
      Offset(face.center.dx, face.bottom),
      mortar,
    );
    canvas.drawCircle(
      Offset(face.left + face.width * .25, face.top + face.height * .25),
      rect.shortestSide * .035,
      Paint()..color = const Color(0xFFD6C69A),
    );
  }

  void _drawGreyStoneBlock(Canvas canvas, Rect rect) {
    final inset = rect.deflate(rect.shortestSide * .08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(rect.shortestSide * .12)),
      _greyStonePaint,
    );
    final edge = rect.shortestSide * .075;
    canvas.drawLine(
      inset.topLeft,
      inset.topRight,
      _greyStoneLightPaint..strokeWidth = edge,
    );
    canvas.drawLine(
      inset.topLeft,
      inset.bottomLeft,
      _greyStoneLightPaint..strokeWidth = edge,
    );
    canvas.drawLine(
      inset.bottomLeft,
      inset.bottomRight,
      _greyStoneDarkPaint..strokeWidth = edge,
    );
    canvas.drawLine(
      inset.topRight,
      inset.bottomRight,
      _greyStoneDarkPaint..strokeWidth = edge,
    );
    final face = inset.deflate(rect.shortestSide * .15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(rect.shortestSide * .08)),
      _greyStoneInnerPaint,
    );
    final crack = Path()
      ..moveTo(face.left + face.width * .2, face.top + face.height * .12)
      ..lineTo(face.center.dx, face.center.dy)
      ..lineTo(face.right - face.width * .18, face.center.dy)
      ..lineTo(
        face.center.dx + face.width * .06,
        face.bottom - face.height * .08,
      );
    canvas.drawPath(
      crack,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = edge * .45
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawBarrel(Canvas canvas, Rect rect) {
    final barrelRect = rect.deflate(rect.shortestSide * .12);
    canvas.drawOval(
      Rect.fromLTWH(
        barrelRect.left + barrelRect.width * .12,
        barrelRect.bottom - barrelRect.height * .10,
        barrelRect.width * .85,
        barrelRect.height * .16,
      ),
      Paint()..color = Colors.black.withValues(alpha: .42),
    );
    final barrelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF991B1B), Color(0xFF7F1D1D), Color(0xFF450A0A)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(barrelRect);

    final rrect = RRect.fromRectAndRadius(barrelRect, const Radius.circular(3));
    canvas.drawRRect(rrect, barrelPaint);

    final y1 = barrelRect.top + barrelRect.height * 0.28;
    final y2 = barrelRect.top + barrelRect.height * 0.72;

    canvas.drawLine(
      Offset(barrelRect.left + 1, y1),
      Offset(barrelRect.right - 1, y1),
      _barrelBandPaint,
    );
    canvas.drawLine(
      Offset(barrelRect.left + 1, y2),
      Offset(barrelRect.right - 1, y2),
      _barrelBandPaint,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        barrelRect.left + 2,
        barrelRect.top + 1,
        barrelRect.width - 4,
        barrelRect.height * 0.22,
      ),
      _barrelLidPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        barrelRect.left + barrelRect.width * .23,
        barrelRect.top + barrelRect.height * .04,
        barrelRect.width * .20,
        barrelRect.height * .08,
      ),
      Paint()..color = Colors.white.withValues(alpha: .35),
    );
    final hazard = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = rect.shortestSide * .07;
    canvas.drawLine(
      Offset(barrelRect.center.dx, barrelRect.top + barrelRect.height * .37),
      Offset(barrelRect.center.dx, barrelRect.top + barrelRect.height * .64),
      hazard,
    );
  }

  void _drawDynamite(
    Canvas canvas,
    Rect rect, {
    bool isSliding = false,
    required double timeLeft,
  }) {
    final center = rect.center;
    final w = rect.width * 0.70;
    final h = rect.height * 0.60;

    final stickRect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        stickRect,
        Radius.circular(rect.shortestSide * .16),
      ),
      isSliding ? _dynSlideStickPaint : _dynStickPaint,
    );

    canvas.drawLine(
      Offset(stickRect.left, stickRect.top + h * 0.33),
      Offset(stickRect.right, stickRect.top + h * 0.33),
      _dynStickLinePaint,
    );
    canvas.drawLine(
      Offset(stickRect.left, stickRect.top + h * 0.66),
      Offset(stickRect.right, stickRect.top + h * 0.66),
      _dynStickLinePaint,
    );

    final tapeRect = Rect.fromCenter(
      center: center,
      width: w * 0.35,
      height: h,
    );
    canvas.drawRect(tapeRect, _dynTapePaint);

    final shine = Paint()..color = Colors.white.withValues(alpha: .30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          stickRect.left + w * .09,
          stickRect.top + h * .12,
          w * .12,
          h * .25,
        ),
        Radius.circular(rect.shortestSide * .06),
      ),
      shine,
    );

    final path = Path();
    path.moveTo(stickRect.right - 2, stickRect.top + 2);
    path.quadraticBezierTo(
      stickRect.right + 4,
      stickRect.top - 6,
      stickRect.right + 2,
      stickRect.top - 10,
    );
    canvas.drawPath(path, _dynFusePaint);

    final blink = (timeLeft * 8).floor().isEven;
    final sparkCenter = Offset(
      stickRect.right + rect.width * .06,
      stickRect.top - rect.height * .10,
    );
    if (blink) {
      final sparkPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(sparkCenter, rect.shortestSide * .13, sparkPaint);
      canvas.drawCircle(
        sparkCenter,
        rect.shortestSide * .065,
        _whiteFlashPaint,
      );
      canvas.drawLine(
        sparkCenter.translate(-rect.width * .12, 0),
        sparkCenter.translate(rect.width * .12, 0),
        Paint()
          ..color = Colors.orangeAccent
          ..strokeWidth = rect.shortestSide * .04,
      );
      canvas.drawLine(
        sparkCenter.translate(0, -rect.height * .12),
        sparkCenter.translate(0, rect.height * .12),
        Paint()
          ..color = Colors.orangeAccent
          ..strokeWidth = rect.shortestSide * .04,
      );
    }
  }

  void _drawExplosion(Canvas canvas, Rect rect, ExplosionTile explosion) {
    final life = (explosion.duration / .35).clamp(0.0, 1.0).toDouble();
    final bounds = rect.deflate(rect.shortestSide * .04);
    final center = bounds.center;
    final phase = (explosion.x * 13 + explosion.y * 7) * .13;
    final burst = Path();
    for (var point = 0; point < 16; point++) {
      final angle = phase + point * pi / 8;
      final radius =
          bounds.shortestSide * (point.isEven ? .49 : .31) * (.72 + life * .28);
      final position =
          center + Offset(cos(angle) * radius, sin(angle) * radius);
      if (point == 0) {
        burst.moveTo(position.dx, position.dy);
      } else {
        burst.lineTo(position.dx, position.dy);
      }
    }
    burst.close();
    final gradient = Paint()
      ..shader = RadialGradient(
        colors: explosion.isCenter
            ? [
                const Color(0xFFFFFFF2),
                const Color(0xFFFFE66D),
                const Color(0xFFFF5A1F).withValues(alpha: life),
              ]
            : [
                const Color(0xFFFFF3A3),
                const Color(0xFFFFA629).withValues(alpha: life),
                const Color(0xFFE83A18).withValues(alpha: life),
              ],
      ).createShader(bounds);
    canvas.drawPath(burst, gradient);
    final core = Paint()
      ..color = const Color(0xFFFFF8C5).withValues(alpha: life);
    canvas.drawCircle(
      center,
      bounds.shortestSide * (explosion.isCenter ? .23 : .15) * life,
      core,
    );
    for (var ember = 0; ember < 4; ember++) {
      final angle = phase + ember * pi / 2 + pi / 4;
      final point =
          center +
          Offset(
            cos(angle) * bounds.width * .34,
            sin(angle) * bounds.height * .34,
          );
      canvas.drawCircle(
        point,
        bounds.shortestSide * .045 * life,
        Paint()..color = const Color(0xFFFFD166).withValues(alpha: life),
      );
    }
  }

  void _drawPowerUp(Canvas canvas, Rect rect, PowerUpType type) {
    String emoji;
    Color boxColor;

    switch (type) {
      case PowerUpType.dynamiteRange:
        emoji = '⚡';
        boxColor = const Color(0xFF1E3A8A);
        break;
      case PowerUpType.rollerSkate:
        emoji = '🛼';
        boxColor = const Color(0xFF065F46);
        break;
      case PowerUpType.extraDynamite:
        emoji = '🧨';
        boxColor = const Color(0xFF7F1D1D);
        break;
      case PowerUpType.shield:
        emoji = '❤️';
        boxColor = const Color(0xFF854D0E);
        break;
      case PowerUpType.bombGlove:
        emoji = '🧤';
        boxColor = const Color(0xFF0F766E);
        break;
    }

    final pRect = rect.deflate(4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pRect, const Radius.circular(4)),
      Paint()..color = boxColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pRect, const Radius.circular(4)),
      Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: rect.width * 0.55),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawFighterSprite(Canvas canvas, Rect rect, ArenaFighter fighter) {
    canvas.save();
    canvas.translate(rect.left, rect.top);

    final isMoving = fighter.isHuman
        ? vm.isHumanMoving
        : (fighter.moveCooldown > 0);
    final direction = fighter.isHuman
        ? (vm.holdDx < 0
              ? CharacterDirection.left
              : (vm.holdDx > 0
                    ? CharacterDirection.right
                    : (vm.holdDy < 0
                          ? CharacterDirection.up
                          : CharacterDirection.down)))
        : CharacterDirection.down;

    final animTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final state = fighter.isHuman && vm.isHumanHitFlashing
        ? CharacterAnimState.hit
        : isMoving
        ? CharacterAnimState.walk
        : CharacterAnimState.idle;

    final painter = FirefighterCharacterPainter(
      animTime: animTime,
      state: state,
      direction: direction,
      suitColor: fighter.bodyColor,
      helmetColor: fighter.hatColor,
      skinColor: fighter.skinColor,
      isFemale: fighter.isFemale,
      hatStyle: fighter.hatStyle,
      suitStyle: fighter.suitStyle,
      accessoryStyle: fighter.accessoryStyle,
      maskStyle: fighter.maskStyle,
      showShadow: true,
      showHose: false,
      showBombGlove: fighter.isHuman && fighter.canMoveDynamite,
    );

    painter.paint(canvas, rect.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlayingWithFirePainter oldDelegate) => true;
}

