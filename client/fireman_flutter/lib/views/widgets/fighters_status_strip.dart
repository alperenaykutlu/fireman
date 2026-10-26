import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fighter_status_card.dart';
import '../../viewmodels/gameplay_viewmodel.dart';
import 'score_badge.dart';
import 'timer_badge.dart';

class FightersStatusStrip extends StatelessWidget {
  const FightersStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    context.select<GameplayViewModel, String>((vm) => vm.fighters
        .map((f) => '${f.id}:${f.health}:${f.status}:${f.isDisconnected}:${f.wins}')
        .join('|'));
    final fighters = context.read<GameplayViewModel>().fighters;
    return SizedBox(
      height: 48,
      child: Row(children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            itemCount: fighters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => FighterStatusCard(fighter: fighters[index]),
          ),
        ),
        const TimerBadge(),
        const SizedBox(width: 5),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xDD111B29), borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white12)),
          child: const ScoreBadge(),
        ),
      ]),
    );
  }
}

