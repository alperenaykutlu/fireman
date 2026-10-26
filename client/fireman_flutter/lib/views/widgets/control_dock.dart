import 'package:flutter/material.dart';

class ControlDock extends StatelessWidget {
  const ControlDock({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Container(
    constraints: const BoxConstraints(minWidth: 58),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFF111B29), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .07))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.white54), const SizedBox(height: 4),
      Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .7, color: Colors.white54)), const SizedBox(height: 5),
      child,
    ]),
  ));
}

