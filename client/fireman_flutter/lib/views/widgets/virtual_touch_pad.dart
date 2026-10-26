import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'direction_button.dart';

/// Klavye gerektirmeyen, basılı tutularak kullanılan yön tuşları.
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
  @override
  Widget build(BuildContext context) {
    // Scale the pad down on short landscape screens so its controls stay inside
    // the dock instead of forcing a RenderFlex overflow.
    final buttonSize = (widget.size / 3).clamp(36.0, 56.0).toDouble();
    return SizedBox(
      width: buttonSize * 3,
      height: buttonSize * 3,
      child: Column(
        children: [
          DirectionButton(icon: Icons.keyboard_arrow_up, size: buttonSize, onDown: () => _press(0, -1), onUp: _release),
          Row(
            children: [
              DirectionButton(icon: Icons.keyboard_arrow_left, size: buttonSize, onDown: () => _press(-1, 0), onUp: _release),
              SizedBox(width: buttonSize, height: buttonSize),
              DirectionButton(icon: Icons.keyboard_arrow_right, size: buttonSize, onDown: () => _press(1, 0), onUp: _release),
            ],
          ),
          DirectionButton(icon: Icons.keyboard_arrow_down, size: buttonSize, onDown: () => _press(0, 1), onUp: _release),
        ],
      ),
    );
  }

  void _press(int dx, int dy) {
    HapticFeedback.selectionClick();
    widget.onDirectionChanged(dx, dy);
  }

  void _release() => widget.onDirectionChanged(0, 0);
}


