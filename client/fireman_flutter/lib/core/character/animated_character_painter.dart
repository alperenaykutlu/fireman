import 'dart:math';
import 'package:flutter/material.dart';
import 'character_state.dart';

/// Yüksek kaliteli, eklemleri hareket edebilen, nefes alan ve
/// durum makinesine (idle, walk, run, action, hit, celebrate) sahip
/// İtfaiyeci Karakter Render Motoru.
class FirefighterCharacterPainter extends CustomPainter {
  final double animTime; // Saniye cinsinden akıcı zaman
  final CharacterAnimState state;
  final CharacterDirection direction;
  final Color suitColor;
  final Color helmetColor;
  final bool showShadow;
  final bool showHose;
  final bool showBombGlove;
  final bool isFemale;
  final Color accessoryColor;
  final Color skinColor;
  final int hatStyle;
  final int accessoryStyle;
  final int maskStyle;
  final int suitStyle;

  // Performans: Statik önbelleklenmiş Paint nesneleri
  static final Paint _shadowPaint = Paint()..color = const Color(0x55000000);
  static final Paint _glovePaint = Paint()..color = const Color(0xFF1E293B);
  static final Paint _bootPaint = Paint()..color = const Color(0xFF0F172A);
  static final Paint _stripePaint = Paint()
    ..color = const Color(0xFFEAB308); // Fosforlu sarı
  static final Paint _silverStripePaint = Paint()
    ..color = const Color(0xFFE2E8F0); // Reflektör gümüş
  static final Paint _badgePaint = Paint()..color = const Color(0xFFFFD700);
  static final Paint _eyeWhite = Paint()..color = Colors.white;
  static final Paint _eyePupil = Paint()..color = const Color(0xFF0F172A);
  static final Paint _mouthPaint = Paint()
    ..color = const Color(0xFF991B1B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  static final Paint _hosePaint = Paint()
    ..color = const Color(0xFF475569)
    ..strokeWidth = 4.0
    ..style = PaintingStyle.stroke;
  static final Paint _waterSprayPaint = Paint()
    ..color = const Color(0xCC38BDF8)
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

  FirefighterCharacterPainter({
    required this.animTime,
    this.state = CharacterAnimState.idle,
    this.direction = CharacterDirection.down,
    this.suitColor = const Color(0xFFDC2626), // Yangın kırmızısı
    this.helmetColor = const Color(0xFFFBBF24), // İtfaiye altın/sarısı
    this.showShadow = true,
    this.showHose = true,
    this.showBombGlove = false,
    this.isFemale = false,
    this.accessoryColor = const Color(0xFF38BDF8),
    this.skinColor = const Color(0xFFFFD1A4),
    this.hatStyle = 0,
    this.accessoryStyle = 0,
    this.maskStyle = -1,
    this.suitStyle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width, size.height) / 100.0;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, scale);

    // Hareket parametreleri hesaplama (Eklemler ve animasyon açısı)
    double walkCycle = 0;
    double breathOffset = 0;
    double armAngleLeft = 0;
    double armAngleRight = 0;
    double legAngleLeft = 0;
    double legAngleRight = 0;
    double headTilt = 0;
    bool isBlinking = false;

    // Göz kırpma döngüsü (her 3.5 saniyede 0.15 saniye kırpma)
    final blinkPhase = animTime % 3.5;
    if (blinkPhase < 0.15) {
      isBlinking = true;
    }

    switch (state) {
      case CharacterAnimState.idle:
        breathOffset = sin(animTime * 2.5) * 1.5;
        headTilt = sin(animTime * 1.2) * 0.04;
        armAngleLeft = sin(animTime * 2.5) * 0.08;
        armAngleRight = -sin(animTime * 2.5) * 0.08;
        break;

      case CharacterAnimState.walk:
        walkCycle = animTime * 6.0;
        breathOffset = (sin(walkCycle * 2.0).abs()) * 2.0;
        headTilt = sin(walkCycle) * 0.05;
        legAngleLeft = sin(walkCycle) * 0.45;
        legAngleRight = -sin(walkCycle) * 0.45;
        armAngleLeft = -sin(walkCycle) * 0.40;
        armAngleRight = sin(walkCycle) * 0.40;
        break;

      case CharacterAnimState.run:
        walkCycle = animTime * 10.0;
        breathOffset = (sin(walkCycle * 2.0).abs()) * 3.5;
        headTilt = sin(walkCycle) * 0.10;
        legAngleLeft = sin(walkCycle) * 0.75;
        legAngleRight = -sin(walkCycle) * 0.75;
        armAngleLeft = -sin(walkCycle) * 0.70;
        armAngleRight = sin(walkCycle) * 0.70;
        break;

      case CharacterAnimState.action:
        breathOffset = sin(animTime * 4.0) * 1.0;
        armAngleRight = -0.8 + sin(animTime * 8.0) * 0.05;
        armAngleLeft = -0.5;
        legAngleLeft = 0.2;
        legAngleRight = -0.2;
        break;

      case CharacterAnimState.hit:
        breathOffset = sin(animTime * 18.0) * 2.5;
        headTilt = sin(animTime * 15.0) * 0.2;
        armAngleLeft = -0.6;
        armAngleRight = 0.6;
        break;

      case CharacterAnimState.celebrate:
        breathOffset = (sin(animTime * 6.0).abs()) * 4.0;
        armAngleLeft = -2.2 + sin(animTime * 5.0) * 0.2;
        armAngleRight = -2.2 - sin(animTime * 5.0) * 0.2;
        headTilt = sin(animTime * 4.0) * 0.08;
        break;
    }

    // 1. Zemin Gölgesi (Nefes aldıkça veya zıpladıkça dinamik küçülür/büyür)
    if (showShadow) {
      final shadowScale = 1.0 - (breathOffset / 30.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 42),
          width: 44 * shadowScale,
          height: 14 * shadowScale,
        ),
        _shadowPaint,
      );
    }

    // Gövde ve eklemleri çizerken sarsıntı/yön düzenlemesi
    if (direction == CharacterDirection.left) {
      canvas.scale(-1, 1);
    }

    // Hasar alma anında kırmızı flash efekti
    Paint suitPaint = Paint()..color = suitColor;
    if (state == CharacterAnimState.hit && (animTime * 15).toInt() % 2 == 0) {
      suitPaint = Paint()..color = Colors.white;
    }

    // 2. Bacaklar ve Çizmeler (Eklemli kalça/diz yapısı)
    _drawLeg(canvas, -10, 15 + breathOffset * 0.3, legAngleLeft, suitPaint);
    _drawLeg(canvas, 10, 15 + breathOffset * 0.3, legAngleRight, suitPaint);

    // 3. Gövde (İtfaiyeci Montu + Fosforlu Reflektör Bantlar)
    final torsoCenterY = 0.0 - breathOffset;
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, torsoCenterY), width: 32, height: 36),
      const Radius.circular(8),
    );
    canvas.drawRRect(torsoRect, suitPaint);
    if (suitStyle % 3 == 1) {
      canvas.drawRect(Rect.fromLTWH(-14, torsoCenterY - 10, 4, 23), _stripePaint);
      canvas.drawRect(Rect.fromLTWH(10, torsoCenterY - 10, 4, 23), _stripePaint);
    } else if (suitStyle % 3 == 2) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-5, torsoCenterY - 15, 10, 12), const Radius.circular(3)), Paint()..color = accessoryColor);
    }

    if (accessoryStyle == 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, torsoCenterY - 11, 12, 9),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF172033),
      );
      canvas.drawLine(
        Offset(10, torsoCenterY - 8),
        Offset(18, torsoCenterY - 8),
        Paint()
          ..color = accessoryColor
          ..strokeWidth = 2,
      );
    } else if (accessoryStyle == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-23, torsoCenterY - 13, 8, 28),
          const Radius.circular(4),
        ),
        Paint()..color = accessoryColor,
      );
      canvas.drawLine(
        Offset(-19, torsoCenterY - 14),
        Offset(-19, torsoCenterY + 15),
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 1.5,
      );
    } else {
      final coil = Paint()
        ..color = accessoryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawOval(Rect.fromLTWH(-25, torsoCenterY - 2, 10, 16), coil);
      canvas.drawOval(Rect.fromLTWH(-23, torsoCenterY + 1, 6, 10), coil);
    }

    // Fosforlu Emniyet Şeritleri (Yatay Reflektörler)
    final stripeRect1 = Rect.fromCenter(
      center: Offset(0, torsoCenterY + 4),
      width: 32,
      height: 5,
    );
    canvas.drawRect(stripeRect1, _stripePaint);

    final silverStripeRect = Rect.fromCenter(
      center: Offset(0, torsoCenterY + 4),
      width: 32,
      height: 2,
    );
    canvas.drawRect(silverStripeRect, _silverStripePaint);

    // İtfaiyeci Kemeri ve Tokası
    final beltRect = Rect.fromCenter(
      center: Offset(0, torsoCenterY + 14),
      width: 33,
      height: 6,
    );
    canvas.drawRect(beltRect, _bootPaint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, torsoCenterY + 14),
        width: 8,
        height: 7,
      ),
      _badgePaint,
    );

    // 4. Kollar ve Eldivenler (Omuz Pivotu)
    _drawArm(
      canvas,
      -18,
      torsoCenterY - 10,
      armAngleLeft,
      suitPaint,
      isLeft: true,
    );
    _drawArm(
      canvas,
      18,
      torsoCenterY - 10,
      armAngleRight,
      suitPaint,
      isLeft: false,
    );

    if (showBombGlove) {
      // Picked-up bomb glove is shown as a small held item on the right hand.
      final hand = Offset(18, torsoCenterY + 9);
      canvas.drawCircle(hand, 7, Paint()..color = const Color(0xFF14B8A6));
      canvas.drawCircle(hand, 4.5, Paint()..color = const Color(0xFF0F172A));
      canvas.drawLine(
        hand.translate(3, -5),
        hand.translate(7, -9),
        Paint()
          ..color = Colors.amberAccent
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 5. Su Hortumu ve Püskürtme (Aksiyon durumunda)
    if (showHose && state == CharacterAnimState.action) {
      final hosePath = Path();
      hosePath.moveTo(0, torsoCenterY + 12);
      hosePath.quadraticBezierTo(14, torsoCenterY + 18, 22, torsoCenterY - 4);
      canvas.drawPath(hosePath, _hosePaint);

      // Su nozulu
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(24, torsoCenterY - 6),
          width: 8,
          height: 6,
        ),
        _silverStripePaint,
      );

      // Püsküren su dalgası
      final waterPath = Path();
      waterPath.moveTo(28, torsoCenterY - 6);
      waterPath.lineTo(44 + sin(animTime * 15) * 3, torsoCenterY - 12);
      waterPath.moveTo(28, torsoCenterY - 6);
      waterPath.lineTo(48 + cos(animTime * 15) * 4, torsoCenterY - 5);
      canvas.drawPath(waterPath, _waterSprayPaint);

      // Su tanecikleri
      canvas.drawCircle(
        Offset(52 + sin(animTime * 20) * 4, torsoCenterY - 10),
        3,
        _waterSprayPaint,
      );
      canvas.drawCircle(
        Offset(46 + cos(animTime * 22) * 5, torsoCenterY - 2),
        2.5,
        _waterSprayPaint,
      );
    }

    // 6. Kafa, Boyun ve Yüz (Nefes & tilt senkronize)
    canvas.save();
    canvas.translate(0, torsoCenterY - 22);
    canvas.rotate(headTilt);

    // Yüz tabanı
    canvas.drawCircle(const Offset(0, 0), 15, Paint()..color = skinColor);
    if (isFemale) {
      final hairPaint = Paint()..color = const Color(0xFF4A2518);
      canvas.drawArc(
        const Rect.fromLTWH(-16, -14, 32, 34),
        pi,
        pi,
        false,
        hairPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      canvas.drawCircle(const Offset(-14, 7), 4, hairPaint);
      canvas.drawCircle(const Offset(14, 7), 4, hairPaint);
    }

    // Gözler ve Göz Kırpma
    if (isBlinking) {
      canvas.drawLine(const Offset(-7, -1), const Offset(-2, -1), _mouthPaint);
      canvas.drawLine(const Offset(2, -1), const Offset(7, -1), _mouthPaint);
    } else {
      // Sol göz
      canvas.drawCircle(const Offset(-5, -2), 3.8, _eyeWhite);
      canvas.drawCircle(const Offset(-4.5, -2), 2.0, _eyePupil);
      canvas.drawCircle(const Offset(-4.0, -3), 1.0, _eyeWhite); // Parlama

      // Sağ göz
      canvas.drawCircle(const Offset(5, -2), 3.8, _eyeWhite);
      canvas.drawCircle(const Offset(4.5, -2), 2.0, _eyePupil);
      canvas.drawCircle(const Offset(5.0, -3), 1.0, _eyeWhite); // Parlama
    }

    // Gülümseme / Kararlı Ağız
    final mouthPath = Path();
    if (state == CharacterAnimState.hit) {
      mouthPath.moveTo(-5, 7);
      mouthPath.lineTo(5, 7);
    } else if (state == CharacterAnimState.celebrate) {
      mouthPath.arcTo(
        Rect.fromCenter(center: const Offset(0, 5), width: 10, height: 8),
        0,
        pi,
        true,
      );
    } else {
      mouthPath.arcTo(
        Rect.fromCenter(center: const Offset(0, 4), width: 8, height: 6),
        0,
        pi,
        true,
      );
    }
    canvas.drawPath(mouthPath, _mouthPaint);
    if (maskStyle >= 0) {
      final maskPaint = Paint()..color = Color.lerp(accessoryColor, Colors.white, (maskStyle % 5) * .08)!;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-9, 3, 18, 9), const Radius.circular(4)), maskPaint);
      final strapPaint = Paint()..color = Colors.white70..strokeWidth = 1.2;
      canvas.drawLine(const Offset(-8, 5), const Offset(-13, 2), strapPaint);
      canvas.drawLine(const Offset(8, 5), const Offset(13, 2), strapPaint);
    }

    // 7. İtfaiyeci Kaskı (Görsel Derinlikli, Siperlikli ve Bröveli)
    final helmetPaint = Paint()
      ..color = hatStyle == 1 ? accessoryColor : helmetColor;
    final helmetBackPaint = Paint()
      ..color = Color.lerp(helmetColor, Colors.black, 0.25)!;

    // Kask Kubbesi
    if (hatStyle != 2) {
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(0, -6), width: 34, height: 28),
        pi,
        pi,
        true,
        helmetPaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(0, -7), width: 34, height: 28),
        pi,
        pi,
        true,
        Paint()..color = accessoryColor,
      );
      canvas.drawRect(
        const Rect.fromLTWH(-18, -5, 36, 4),
        Paint()..color = accessoryColor,
      );
    }

    // Kask Ön Siperliği (Geniş kenarlık)
    final brimPath = Path();
    brimPath.moveTo(-19, -4);
    brimPath.quadraticBezierTo(0, -1, 19, -4);
    brimPath.lineTo(17, -7);
    brimPath.quadraticBezierTo(0, -5, -17, -7);
    brimPath.close();
    canvas.drawPath(brimPath, helmetBackPaint);

    // Altın İtfaiyeci Brövesi (Merkez arma)
    final badgePath = Path();
    badgePath.moveTo(0, -16);
    badgePath.lineTo(4, -10);
    badgePath.lineTo(3, -4);
    badgePath.lineTo(-3, -4);
    badgePath.lineTo(-4, -10);
    badgePath.close();
    canvas.drawPath(badgePath, _badgePaint);

    // Kask Üst Sırt Çizgisi (Reflektör / kabartma sırt)
    canvas.drawLine(
      const Offset(0, -19),
      const Offset(0, -5),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
    canvas.restore();
  }

  void _drawLeg(
    Canvas canvas,
    double x,
    double y,
    double angle,
    Paint suitPaint,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    // Üst bacak (Pantolon)
    final legRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-4, 0, 8, 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(legRect, suitPaint);

    // Pantolon paça reflektör şeridi
    canvas.drawRect(Rect.fromLTWH(-4, 11, 8, 3), _stripePaint);

    // İtfaiyeci Çizmesi
    final bootPath = Path();
    bootPath.moveTo(-5, 16);
    bootPath.lineTo(5, 16);
    bootPath.lineTo(7, 24);
    bootPath.lineTo(-5, 24);
    bootPath.close();
    canvas.drawPath(bootPath, _bootPaint);

    // Taban koruması
    canvas.drawRect(Rect.fromLTWH(-5, 23, 12, 2.5), _stripePaint);

    canvas.restore();
  }

  void _drawArm(
    Canvas canvas,
    double x,
    double y,
    double angle,
    Paint suitPaint, {
    required bool isLeft,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    // Kol (Ceket kolu)
    final armRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-3.5, 0, 7, 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(armRect, suitPaint);

    // Kol reflektörü
    canvas.drawRect(Rect.fromLTWH(-3.5, 10, 7, 3), _stripePaint);

    // Eldiven (El)
    canvas.drawCircle(const Offset(0, 19), 4.5, _glovePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FirefighterCharacterPainter oldDelegate) {
    return oldDelegate.animTime != animTime ||
        oldDelegate.state != state ||
        oldDelegate.direction != direction ||
        oldDelegate.suitColor != suitColor ||
        oldDelegate.skinColor != skinColor ||
        oldDelegate.helmetColor != helmetColor ||
        oldDelegate.showBombGlove != showBombGlove ||
        oldDelegate.hatStyle != hatStyle ||
        oldDelegate.suitStyle != suitStyle ||
        oldDelegate.accessoryStyle != accessoryStyle ||
        oldDelegate.maskStyle != maskStyle;
  }
}
