import 'package:flutter/material.dart';

class FiremanSectionTitle extends StatelessWidget {
  const FiremanSectionTitle(this.title, {super.key, this.padding = const EdgeInsets.only(top: 8, bottom: 6)});
  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
  );
}
