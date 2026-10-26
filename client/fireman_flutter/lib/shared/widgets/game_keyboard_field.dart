import 'package:flutter/material.dart';

/// Text entry field that opens the in-game keyboard instead of the system one.
class GameKeyboardField extends StatelessWidget {
  const GameKeyboardField({super.key, required this.controller, required this.label,
    required this.onFocus, this.obscureText = false, this.maxLength = 32});

  final TextEditingController controller;
  final String label;
  final ValueChanged<TextEditingController> onFocus;
  final bool obscureText;
  final int maxLength;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: true,
    showCursor: true,
    maxLength: maxLength,
    obscureText: obscureText,
    onTap: () => onFocus(controller),
    decoration: InputDecoration(labelText: label, counterText: '', suffixIcon: const Icon(Icons.keyboard_alt_outlined)),
  );
}
