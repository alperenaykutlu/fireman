import 'package:flutter/material.dart';

/// On-screen keyboard for short labels, room passwords and chat input.
class GameKeyboard extends StatelessWidget {
  const GameKeyboard({super.key, required this.controller, this.onDone, this.numericOnly = false});
  final TextEditingController controller;
  final VoidCallback? onDone;
  final bool numericOnly;

  static const _rows = ['1234567890', 'qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  void _insert(String value) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    for (final row in (numericOnly ? const ['123', '456', '789', '0'] : _rows)) Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final key in row.split('')) Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _key(key.toUpperCase(), () => _insert(key)),
        )),
      ]),
    ),
    if (!numericOnly) Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
      for (final symbol in const ['@', '.', '-', '_']) Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _key(symbol, () => _insert(symbol)),
      )),
    ])),
    Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
      Expanded(flex: 2, child: _key('⌫', () {
        final text = controller.text;
        final selection = controller.selection;
        if (text.isEmpty) return;
        final hasSelection = selection.isValid && selection.start != selection.end;
        final start = hasSelection ? selection.start : (selection.isValid ? selection.start : text.length) - 1;
        final end = hasSelection ? selection.end : (selection.isValid ? selection.start : text.length);
        if (start < 0) return;
        controller.value = TextEditingValue(text: text.replaceRange(start, end, ''),
          selection: TextSelection.collapsed(offset: start));
      })),
      if (!numericOnly) ...[
        const SizedBox(width: 4),
        Expanded(flex: 6, child: _key('BOŞLUK', () => _insert(' '))),
      ],
      const SizedBox(width: 4),
      Expanded(flex: 2, child: _key('TAMAM', onDone ?? () {})),
    ])),
  ]);

  Widget _key(String label, VoidCallback action) => SizedBox(height: 34,
    child: FilledButton.tonal(onPressed: action, style: FilledButton.styleFrom(
      padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ), child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))));
}
