import 'package:flutter/material.dart';
import 'animated_character_painter.dart';
import 'character_state.dart';

/// Animated character presentation widget used by menus, inventory and game UI.
class AnimatedFirefighterWidget extends StatefulWidget {
  final double size;
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

  const AnimatedFirefighterWidget({
    super.key,
    this.size = 120,
    this.state = CharacterAnimState.idle,
    this.direction = CharacterDirection.down,
    this.suitColor = const Color(0xFFDC2626),
    this.helmetColor = const Color(0xFFFBBF24),
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
  State<AnimatedFirefighterWidget> createState() => _AnimatedFirefighterWidgetState();
}

class _AnimatedFirefighterWidgetState extends State<AnimatedFirefighterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => CustomPaint(
      size: Size(widget.size, widget.size),
      painter: FirefighterCharacterPainter(
        animTime: _controller.value * 10.0,
        state: widget.state,
        direction: widget.direction,
        suitColor: widget.suitColor,
        helmetColor: widget.helmetColor,
        showShadow: widget.showShadow,
        showHose: widget.showHose,
        showBombGlove: widget.showBombGlove,
        isFemale: widget.isFemale,
        accessoryColor: widget.accessoryColor,
        skinColor: widget.skinColor,
        hatStyle: widget.hatStyle,
        accessoryStyle: widget.accessoryStyle,
        maskStyle: widget.maskStyle,
        suitStyle: widget.suitStyle,
      ),
    ),
  );
}
