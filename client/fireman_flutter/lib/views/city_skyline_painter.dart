import 'dart:math';
import 'package:flutter/material.dart';

class CinematicCitySkylinePainter extends CustomPainter {
  final double pageOffset;

  CinematicCitySkylinePainter({required this.pageOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gökyüzü Gradyanı
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF030712),
          Color(0xFF0F172A),
          Color(0xFF1E1B4B),
          Color(0xFF311018), // Yangın kızıllığı
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Ay ve Kızıl Hale
    final moonCenter = Offset(
      size.width * 0.82 - (pageOffset * 20),
      size.height * 0.16,
    );
    final glowPaint = Paint()
      ..color = const Color(0xFFFDE047).withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(moonCenter, 32, glowPaint);
    canvas.drawCircle(moonCenter, 18, Paint()..color = const Color(0xFFFEF08A));

    // 2. Uzak Şehir Silueti (Parallax Hızı: 0.3)
    final distantBuildingPaint = Paint()..color = const Color(0xFF0D1322);
    _drawBuildings(
      canvas,
      size,
      baseY: size.height * 0.65,
      step: 38,
      heightSeed: 85,
      offset: pageOffset * 25,
      paint: distantBuildingPaint,
    );

    // 3. Yakın Şehir Silueti (Parallax Hızı: 0.6)
    final nearBuildingPaint = Paint()..color = const Color(0xFF090E18);
    _drawBuildings(
      canvas,
      size,
      baseY: size.height * 0.76,
      step: 48,
      heightSeed: 130,
      offset: pageOffset * 50,
      paint: nearBuildingPaint,
    );

    // Zemin ve Islak Sokak Işıltısı
    final groundPaint = Paint()..color = const Color(0xFF05070B);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.88, size.width, size.height * 0.12),
      groundPaint,
    );

    final lineGlow = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF5722).withAlpha(120),
          const Color(0xFFFFC107).withAlpha(120),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.88, size.width, 3));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.88, size.width, 2.5),
      lineGlow,
    );
  }

  void _drawBuildings(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double step,
    required double heightSeed,
    required double offset,
    required Paint paint,
  }) {
    for (double x = -offset % step - step; x < size.width + step; x += step) {
      final h = (sin(x * 0.12).abs() * heightSeed) + 40;
      canvas.drawRect(Rect.fromLTWH(x, baseY - h, step * 0.92, h + 150), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CinematicCitySkylinePainter oldDelegate) =>
      oldDelegate.pageOffset != pageOffset;
}

