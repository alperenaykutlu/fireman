import 'package:flutter/material.dart';
import '../core/constants.dart';

class FiremanMenuButton extends StatelessWidget {
  const FiremanMenuButton({super.key, required this.title, required this.subtitle, required this.icon, required this.gradient, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.sizeOf(context).height < 430 ? 7 : 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ])),
      ]),
    ),
  );
}

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
