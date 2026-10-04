import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../viewmodels/character_viewmodel.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterViewModel>().loadCharacter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final charVm = context.watch<CharacterViewModel>();
    final char = charVm.character;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧑‍🚒 Karakter & Ekipman'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text('🪙 ${charVm.coins}  💎 ${charVm.gems}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: charVm.isLoading || char == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profil Kartı
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppConstants.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.borderCard),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.bgDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConstants.borderCard),
                          ),
                          child: const Text('🧑‍🚒', style: TextStyle(fontSize: 48)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(char.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Seviye ${char.level} • Kıdemli Çavuş', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (char.experience % 1000) / 1000.0,
                                minHeight: 6,
                                backgroundColor: AppConstants.bgDark,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.fireOrange),
                              ),
                              const SizedBox(height: 4),
                              Text('${char.experience} / ${(char.level) * 1000} XP', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Kuşanılan Eşyalar
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Kuşanılmış Teçhizat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildEquipSlot('Kask', char.equippedHat ?? 'Standart Kask', '🪖'),
                      const SizedBox(width: 10),
                      _buildEquipSlot('Ceket', char.equippedSuit ?? 'İtfaiye Ceketi', '🦺'),
                      const SizedBox(width: 10),
                      _buildEquipSlot('Nozul', 'Yüksek Basınç', '🧯'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dolap / Gardırop
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Gardırop (Şapkalar & Kasklar)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  _buildWardrobeItem(context, 'Titanyum Alev Kaskı', '🪖', 'Epik Teçhizat'),
                  const SizedBox(height: 8),
                  _buildWardrobeItem(context, 'Gece Görüşlü Termal Kask', '🥽', 'Nadir Teçhizat'),
                  const SizedBox(height: 8),
                  _buildWardrobeItem(context, 'Altın Şampiyon Kaskı', '👑', 'Efsanevi Teçhizat'),
                ],
              ),
            ),
    );
  }

  Widget _buildEquipSlot(String title, String value, String icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderCard),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.fireOrange)),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeItem(BuildContext context, String name, String icon, String rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderCard),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(rarity, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.borderCard,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              context.read<CharacterViewModel>().equipHat(name);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name kuşanıldı!'), backgroundColor: AppConstants.waterBlue),
              );
            },
            child: const Text('Kuşan', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
