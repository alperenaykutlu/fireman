import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../viewmodels/missions_viewmodel.dart';
import '../viewmodels/character_viewmodel.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionsViewModel>().loadMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final missionsVm = context.watch<MissionsViewModel>();

    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 10, 4), child: Row(children: [
          const Expanded(child: Text('🎯 Görevler & Kurtarma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          IconButton(tooltip: 'Yenile', onPressed: () => missionsVm.loadMissions(), icon: const Icon(Icons.refresh)),
        ])),
        Expanded(child: missionsVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: missionsVm.missions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final mission = missionsVm.missions[index];

                final colors = [const Color(0xFFFF8A4C), const Color(0xFF54C8E8), const Color(0xFF9A83FF), const Color(0xFF77D28C)];
                final accent = colors[index % colors.length];
                final icons = [Icons.local_fire_department, Icons.water_drop_outlined, Icons.health_and_safety_outlined, Icons.emoji_events_outlined];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withValues(alpha: .14), const Color(0xFF172231), const Color(0xFF141C28)]),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: .28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withValues(alpha: .16), borderRadius: BorderRadius.circular(11)), child: Icon(icons[index % icons.length], color: accent, size: 19)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mission.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.bgDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🪙 ${mission.rewardCoins}  XP: ${mission.rewardXp}',
                              style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mission.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hedef Skor: ${mission.targetScore}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mission.isCompleted ? Colors.white24 : AppConstants.fireOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: mission.isCompleted
                                ? null
                                : () {
                                    missionsVm.markCompleted(mission.id);
                                    context.read<CharacterViewModel>().addRewards(mission.rewardCoins, mission.rewardXp);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🎉 ${mission.title} tamamlandı! +${mission.rewardCoins} Altın!'),
                                        backgroundColor: AppConstants.waterCyan,
                                      ),
                                    );
                                  },
                            child: Text(mission.isCompleted ? 'Tamamlandı ✔' : 'Görevi Bitir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )),
      ])),
    );
  }
}
