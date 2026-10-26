import 'package:flutter/material.dart';
import '../../core/constants.dart';

class FiremanMiniButton extends StatelessWidget {
  const FiremanMiniButton({super.key, required this.icon, required this.label, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppConstants.bgDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppConstants.borderCard)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}
