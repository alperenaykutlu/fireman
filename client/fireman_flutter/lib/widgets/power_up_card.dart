import 'package:flutter/material.dart';

class PowerUpCard extends StatelessWidget {
  const PowerUpCard({super.key, required this.icon, required this.title, required this.description, required this.color});
  final String icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 95,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF161F2E),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withAlpha(120), width: 1.5),
      boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 8)],
    ),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 4),
      Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
      const SizedBox(height: 2),
      Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 9, height: 1.2)),
    ]),
  );
}
