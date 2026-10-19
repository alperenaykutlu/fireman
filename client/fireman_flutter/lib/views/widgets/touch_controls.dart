import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mobilde klavye gerektirmeyen, akıcı, dokunsal (tactile) sanal oyun kumandası.
class VirtualTouchPad extends StatefulWidget {
  final Function(int dx, int dy) onDirectionChanged;
  final double size;

  const VirtualTouchPad({
    super.key,
    required this.onDirectionChanged,
    this.size = 140,
  });

  @override
  State<VirtualTouchPad> createState() => _VirtualTouchPadState();
}

class _VirtualTouchPadState extends State<VirtualTouchPad> {
  Offset _dragPosition = Offset.zero;
  int _lastDx = 0;
  int _lastDy = 0;

  void _updateDirection(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPos - center;
    final distance = delta.distance;

    final maxRadius = widget.size * 0.42;
    if (distance > maxRadius) {
      _dragPosition = Offset.fromDirection(delta.direction, maxRadius);
    } else {
      _dragPosition = delta;
    }

    // Yön tespiti (deadzone: 16 piksel)
    int dx = 0;
    int dy = 0;

    if (distance > 16) {
      if (delta.dx.abs() > delta.dy.abs()) {
        dx = delta.dx > 0 ? 1 : -1;
      } else {
        dy = delta.dy > 0 ? 1 : -1;
      }
    }

    if (dx != _lastDx || dy != _lastDy) {
      _lastDx = dx;
      _lastDy = dy;
      HapticFeedback.selectionClick();
      widget.onDirectionChanged(dx, dy);
    }

    setState(() {});
  }

  void _reset() {
    _dragPosition = Offset.zero;
    if (_lastDx != 0 || _lastDy != 0) {
      _lastDx = 0;
      _lastDy = 0;
      widget.onDirectionChanged(0, 0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final knobOffset = center + _dragPosition;

    return GestureDetector(
      onPanStart: (details) => _updateDirection(details.localPosition),
      onPanUpdate: (details) => _updateDirection(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: () => _reset(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E293B).withAlpha(180),
          border: Border.all(
            color: const Color(0xFF38BDF8).withAlpha(120),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // D-Pad Yön İpuçları (Oklar)
            const Positioned(
              top: 6,
              child: Icon(Icons.arrow_drop_up, color: Colors.white38, size: 28),
            ),
            const Positioned(
              bottom: 6,
              child: Icon(Icons.arrow_drop_down, color: Colors.white38, size: 28),
            ),
            const Positioned(
              left: 6,
              child: Icon(Icons.arrow_left, color: Colors.white38, size: 28),
            ),
            const Positioned(
              right: 6,
              child: Icon(Icons.arrow_right, color: Colors.white38, size: 28),
            ),

            // Hareketli Joystick Topuzu (Knob)
            Positioned(
              left: knobOffset.dx - 26,
              top: knobOffset.dy - 26,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                    center: Alignment(-0.3, -0.3),
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withAlpha(150),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.touch_app, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dokunsal, basış animasyonlu büyük aksiyon butonu (Dinamit / Su)
class GlowingActionButton extends StatefulWidget {
  final String label;
  final String iconEmoji;
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const GlowingActionButton({
    super.key,
    required this.label,
    required this.iconEmoji,
    required this.onPressed,
    this.primaryColor = const Color(0xFFEF4444),
    this.secondaryColor = const Color(0xFF991B1B),
    this.size = 80,
  });

  @override
  State<GlowingActionButton> createState() => _GlowingActionButtonState();
}

class _GlowingActionButtonState extends State<GlowingActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [widget.primaryColor, widget.secondaryColor],
              center: const Alignment(-0.2, -0.3),
            ),
            border: Border.all(
              color: Colors.amberAccent.withAlpha(_isPressed ? 255 : 180),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withAlpha(_isPressed ? 180 : 100),
                blurRadius: _isPressed ? 18 : 12,
                spreadRadius: _isPressed ? 4 : 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.iconEmoji,
                style: TextStyle(fontSize: widget.size * 0.38),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: widget.size * 0.12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
