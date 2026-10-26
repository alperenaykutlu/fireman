import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/gameplay_viewmodel.dart';

class TimerBadge extends StatelessWidget {
  const TimerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final time = context.select<GameplayViewModel, String>((vm) => vm.formattedTimer);
    final suddenDeath = context.select<GameplayViewModel, bool>((vm) => vm.isSuddenDeath);
    final color = suddenDeath ? Colors.redAccent : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: suddenDeath ? Colors.red.shade900 : Colors.black87,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer, size: 14, color: color),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: suddenDeath ? Colors.white : Colors.amberAccent)),
      ]),
    );
  }
}
