import 'package:flutter/material.dart';
import '../../models/game_elements.dart';
import 'fighter_portrait_painter.dart';

class FighterStatusCard extends StatelessWidget {
  const FighterStatusCard({super.key, required this.fighter});
  final ArenaFighter fighter;

  @override
  Widget build(BuildContext context) {
    final alive = fighter.status == PlayerStatus.alive;
    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF202938),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alive ? fighter.hatColor.withValues(alpha: .8) : Colors.white12),
      ),
      child: Row(children: [
        SizedBox(width: 28, height: 36, child: CustomPaint(painter: FighterPortraitPainter(hatColor: fighter.hatColor, bodyColor: fighter.bodyColor, isAlive: alive))),
        const SizedBox(width: 7),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text(fighter.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.bold))),
            Icon(alive ? Icons.favorite : Icons.close, size: 12, color: alive ? Colors.greenAccent : Colors.redAccent),
          ]),
          if (!fighter.isDisconnected) ...[
            const SizedBox(height: 3),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
              value: fighter.health.clamp(0, 100) / 100,
              minHeight: 4,
              backgroundColor: Colors.black45,
              valueColor: AlwaysStoppedAnimation(fighter.health > 40 ? Colors.greenAccent : Colors.redAccent),
            )),
            const SizedBox(height: 1),
          ],
          Text(fighter.isDisconnected ? 'OYUNDAN DÜŞTÜ' : '${fighter.health}%  •  ${fighter.wins} galibiyet',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, height: 1, color: Colors.white60)),
        ])),
      ]),
    );
  }
}
