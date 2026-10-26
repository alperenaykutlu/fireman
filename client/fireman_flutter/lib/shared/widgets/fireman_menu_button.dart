import 'package:flutter/material.dart';

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
