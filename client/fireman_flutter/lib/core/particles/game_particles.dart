import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleType {
  ember, // Alev kıvılcımı
  smoke, // Yükselen duman
  water, // Su damlası
  spark, // Dinamik elektrik / şok kıvılcımı
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double maxLife;
  double life;
  Color color;
  ParticleType type;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
    required this.life,
    required this.color,
    required this.type,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;

    if (type == ParticleType.ember) {
      vy -= 18.0 * dt; // Yukarı doğru süzülme
      vx += sin(life * 5.0) * 10.0 * dt; // Hafif rüzgar dalgalanması
    } else if (type == ParticleType.water) {
      vy += 90.0 * dt; // Yerçekimi etkisi
    } else if (type == ParticleType.smoke) {
      vy -= 12.0 * dt;
      size += 6.0 * dt; // Genişleme
    }

    return life > 0;
  }
}

/// Performans odaklı Parçacık Simülatörü ve Ressamı
class ParticleSystemPainter extends CustomPainter {
  final List<Particle> particles;
  static final Paint _paint = Paint();

  ParticleSystemPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = (progress * 255).toInt();
      _paint.color = p.color.withAlpha(alpha);

      if (p.type == ParticleType.smoke) {
        _paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
        _paint.maskFilter = null;
      } else if (p.type == ParticleType.ember) {
        canvas.drawCircle(Offset(p.x, p.y), p.size * progress, _paint);
        // Kıvılcım çekirdeği (beyaz merkez)
        _paint.color = Colors.white.withAlpha((alpha * 0.7).toInt());
        canvas.drawCircle(Offset(p.x, p.y), (p.size * progress) * 0.4, _paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticleSystemPainter oldDelegate) => true;
}

/// Arka plan veya efekt için otomatik kıvılcım üreten hafif katman
class AmbientEmberOverlay extends StatefulWidget {
  final int maxParticles;
  final Widget? child;

  const AmbientEmberOverlay({
    super.key,
    this.maxParticles = 25,
    this.child,
  });

  @override
  State<AmbientEmberOverlay> createState() => _AmbientEmberOverlayState();
}

class _AmbientEmberOverlayState extends State<AmbientEmberOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<Particle> _particles = [];
  final Random _rnd = Random();
  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _ticker.addListener(_onTick);
  }

  void _onTick() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (_lastTime == 0) {
      _lastTime = now;
      return;
    }
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    // Güncelleme
    _particles.removeWhere((p) => !p.update(dt));

    // Yeni kıvılcımlar ekle
    if (_particles.length < widget.maxParticles && mounted) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < 2; i++) {
        final life = 2.0 + _rnd.nextDouble() * 2.5;
        _particles.add(
          Particle(
            x: _rnd.nextDouble() * size.width,
            y: size.height + 10,
            vx: (_rnd.nextDouble() - 0.5) * 40,
            vy: -35 - _rnd.nextDouble() * 55,
            size: 2.5 + _rnd.nextDouble() * 3.5,
            maxLife: life,
            life: life,
            color: _rnd.nextBool()
                ? const Color(0xFFFF5722)
                : const Color(0xFFFFB300),
            type: ParticleType.ember,
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ParticleSystemPainter(particles: _particles),
            ),
          ),
        ),
      ],
    );
  }
}
