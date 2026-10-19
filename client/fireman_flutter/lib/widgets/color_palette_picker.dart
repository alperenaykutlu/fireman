import 'package:flutter/material.dart';

class ColorPalettePicker extends StatelessWidget {
  const ColorPalettePicker({super.key, required this.colors, required this.selectedValue, required this.onSelected, this.spacing = 10});
  final List<Color> colors;
  final int selectedValue;
  final ValueChanged<Color> onSelected;
  final double spacing;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: spacing,
    runSpacing: 8,
    children: colors.map((color) {
      final selected = color.value == selectedValue;
      return InkWell(
        onTap: () => onSelected(color),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 3 : 1),
          ),
        ),
      );
    }).toList(),
  );
}
