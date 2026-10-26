import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/gameplay_viewmodel.dart';

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final score = context.select<GameplayViewModel, int>((vm) => vm.score);
    return Text('PUAN: $score', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.amberAccent));
  }
}
