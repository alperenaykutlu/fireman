import 'package:flutter/material.dart';

class DirectionButton extends StatefulWidget {
  const DirectionButton({super.key, required this.icon, required this.size, required this.onDown, required this.onUp});
  final IconData icon;
  final double size;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<DirectionButton> createState() => _DirectionButtonState();
}

class _DirectionButtonState extends State<DirectionButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
    if (pressed) {
      widget.onDown();
    } else {
      widget.onUp();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _setPressed(true),
    onTapUp: (_) => _setPressed(false),
    onTapCancel: () => _setPressed(false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _pressed ? const [Color(0xFF4BBDF4), Color(0xFF1672B3)] : const [Color(0xFF29394E), Color(0xFF172333)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _pressed ? const Color(0xFFB9E9FF) : const Color(0xFF6CBEE7).withAlpha(145), width: _pressed ? 2 : 1.2),
        boxShadow: _pressed ? const [] : const [BoxShadow(color: Color(0x5538BDF8), blurRadius: 7, offset: Offset(0, 3))],
      ),
      child: Icon(widget.icon, color: Colors.white, size: widget.size * .66, shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))]),
    ),
  );
}
