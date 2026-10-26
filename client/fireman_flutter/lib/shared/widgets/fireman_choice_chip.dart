import 'package:flutter/material.dart';
import '../core/constants.dart';

class FiremanChoiceChip extends StatelessWidget {
  const FiremanChoiceChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppConstants.fireOrange,
    visualDensity: VisualDensity.compact,
  );
}
