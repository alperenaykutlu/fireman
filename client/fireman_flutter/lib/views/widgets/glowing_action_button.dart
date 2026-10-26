import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
