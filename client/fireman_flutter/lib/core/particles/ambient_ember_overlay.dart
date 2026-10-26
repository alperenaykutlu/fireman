import 'dart:math';
import 'package:flutter/material.dart';
import 'game_particles.dart';

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

