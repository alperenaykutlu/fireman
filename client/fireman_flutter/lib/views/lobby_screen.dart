import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../viewmodels/match_viewmodel.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchVm = context.watch<MatchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Multiplayer & Lobi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Eşleşme Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.borderCard),
              ),
              child: Column(
                children: [
                  const Text('İtfaiye Ekibi Eşleşmesi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('4 Kişilik Kooperatif Yangın Söndürme', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Text(
                    matchVm.statusMessage,
                    style: const TextStyle(color: AppConstants.waterBlue, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (matchVm.isSearching)
                    const CircularProgressIndicator()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.fireOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => matchVm.createMatch(),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Oda Oluştur'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.waterBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => matchVm.joinRoom('Oda-Alev-99'),
                          icon: const Icon(Icons.login),
                          label: const Text('Hızlı Katıl'),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Aktif Oda Bilgisi
            if (matchVm.currentMatch != null) ...[
              const Text('Aktif Ekip Üyeleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPlayerRow('🧑‍🚒 Kaptan_Alev (Lider)', true),
              const SizedBox(height: 8),
              _buildPlayerRow('🧑‍🚒 İtfaiyeci Ahmet (Siz)', true),
              const SizedBox(height: 8),
              _buildPlayerRow('🧑‍🚒 Demir_Hortum', false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(String name, bool isReady) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderCard),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(
            isReady ? 'Hazır ✔' : 'Bekleniyor...',
            style: TextStyle(
              color: isReady ? AppConstants.waterCyan : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
