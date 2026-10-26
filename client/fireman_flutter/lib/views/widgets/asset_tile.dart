import 'package:flutter/material.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({required this.title, required this.index, required this.accent, required this.selected, required this.unlocked, required this.price, this.onTap});
  final String title; final int index; final Color accent; final bool selected; final bool unlocked; final String price; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Ink(
    decoration: BoxDecoration(color: selected ? accent.withValues(alpha: .2) : const Color(0xFF1A2635), borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? accent : Colors.white.withValues(alpha: .07), width: selected ? 1.5 : 1)),
    child: Stack(children: [
      Positioned(right: 6, bottom: 0, child: Text((index + 1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: accent.withValues(alpha: .08)))),
      Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: accent.withValues(alpha: .16), borderRadius: BorderRadius.circular(10)), child: Icon(_iconFor(title), color: accent, size: 17)), const Spacer(), if (selected) Icon(Icons.check_circle, color: accent, size: 17) else if (!unlocked) const Icon(Icons.lock_outline, color: Colors.white38, size: 15)]),
        const Spacer(), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 3), Text(price, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: unlocked ? accent : Colors.white54)),
      ])),
    ]),
  )));
  IconData _iconFor(String title) {
    if (title.contains('kask')) return Icons.sports_motorsports;
    if (title.contains('kıyafet')) return Icons.checkroom;
    if (title.contains('maske')) return Icons.masks;
    if (title.contains('eldiven')) return Icons.back_hand_outlined;
    if (title.contains('ayakkabı')) return Icons.hiking;
    if (title.contains('dinamit')) return Icons.whatshot;
    if (title.contains('telsiz')) return Icons.campaign_outlined;
    return Icons.extension_outlined;
  }
}
