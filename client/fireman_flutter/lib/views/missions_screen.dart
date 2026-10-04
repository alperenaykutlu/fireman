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
      appBar: AppBar(
        title: const Text('🎯 Görevler & Kurtarma'),
        actions: [
          IconButton(
            onPressed: () => missionsVm.loadMissions(),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: missionsVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: missionsVm.missions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final mission = missionsVm.missions[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.borderCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                              style: const TextStyle(fontSize: 12, color: AppConstants.gold, fontWeight: FontWeight.bold),
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
            ),
    );
  }
}
