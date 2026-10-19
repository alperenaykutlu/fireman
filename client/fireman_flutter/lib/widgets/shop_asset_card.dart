import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'fireman_card.dart';

class ShopAssetCard extends StatelessWidget {
  const ShopAssetCard({super.key, required this.title, required this.subtitle, required this.selected, required this.unlocked, this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FiremanCard(
    padding: EdgeInsets.zero,
    margin: const EdgeInsets.only(bottom: 6),
    color: selected ? const Color(0xFF263449) : AppConstants.bgCard,
    borderRadius: 12,
    onTap: unlocked && !selected ? onTap : null,
    child: ListTile(
      dense: true,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.greenAccent)
          : unlocked
              ? const Icon(Icons.checkroom, color: Colors.white70)
              : const Icon(Icons.lock, color: Colors.white54),
    ),
  );
}
