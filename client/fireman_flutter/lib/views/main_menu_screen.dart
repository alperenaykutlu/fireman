import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/character/animated_character_painter.dart';
import '../core/character/character_state.dart';
import '../core/constants.dart';
import '../models/user_profile.dart';
import '../viewmodels/gameplay_viewmodel.dart';
import 'character_screen.dart';
import 'gameplay_screen.dart';
import 'lobby_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final UserProfile profile;

  const MainMenuScreen({super.key, required this.profile});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _idleAnimController;
  late Animation<double> _breathAnim;
  late Animation<double> _swayAnim;

  @override
  void initState() {
    super.initState();
    // Karakterin nefes alma ve hafif sallanma (idle breathing & swaying) animasyonu
    _idleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _idleAnimController, curve: Curves.easeInOutSine),
    );

    _swayAnim = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _idleAnimController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _idleAnimController.dispose();
    super.dispose();
  }

  void _showOfflinePlayerCountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('🎮 ', style: TextStyle(fontSize: 22)),
              Text('Tek Oyna (Offline)', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Arenada mücadele edecek toplam oyuncu sayısını seçin:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerCountButton(2, '2 Kişilik\n(1v1 Bot)'),
                  _buildPlayerCountButton(3, '3 Kişilik\n(1v2 Bot)'),
                  _buildPlayerCountButton(4, '4 Kişilik\n(1v3 Bot)'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerCountButton(int count, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.read<GameplayViewModel>().setPlayerCount(count);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameplayScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.fireOrange, width: 1.5),
        ),
        child: Column(
          children: [
            Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.fireOrange)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('⚙️ Oyun Ayarları'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Müzik & Ses Efektleri'),
                trailing: Icon(Icons.volume_up, color: AppConstants.waterBlue),
              ),
              ListTile(
                title: Text('Titreşim (Haptic)'),
                trailing: Icon(Icons.vibration, color: AppConstants.waterCyan),
              ),
              ListTile(
                title: Text('Grafik Kalitesi: Yüksek 60FPS'),
                trailing: Icon(Icons.hd, color: AppConstants.gold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: Colors.white70)),
            )
          ],
        );
      },
    );
  }

  void _showLeaderboardDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppConstants.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🏆 Liderlik Tablosu'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildLeaderboardRow(1, 'Kaptan_Alev', '84,200', true),
                _buildLeaderboardRow(2, 'Su_Püskürten_99', '62,450', false),
                _buildLeaderboardRow(3, 'Demir_Hortum', '49,100', false),
                _buildLeaderboardRow(widget.profile.rank, widget.profile.username, '${widget.profile.totalScore}', true, isMe: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: Colors.white70)),
            )
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String score, bool isTop, {bool isMe = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? AppConstants.fireOrange.withValues(alpha: 0.2) : AppConstants.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: isMe ? Border.all(color: AppConstants.fireOrange) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('#$rank  $name ${isMe ? "(Sen)" : ""}', style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
          Text('$score Puan', style: const TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ÜST BAŞLIK & PROFİL ADI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 24)),
                      Text(
                        widget.profile.username,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppConstants.borderCard),
                    ),
                    child: const Text('ONLINE 🟢', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.waterCyan)),
                  ),
                ],
              ),
            ),

            // ORTA ALAN: SOLDA İSTATİSTİKLER, SAĞDA NEFES ALAN VE SALLANAN KARAKTER
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // SOL TARAF: OYUNCU İSTATİSTİKLERİ
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.borderCard),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bar_chart, color: AppConstants.fireOrange, size: 20),
                                SizedBox(width: 8),
                                Text('İSTATİSTİKLER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ],
                            ),
                            const Divider(color: AppConstants.borderCard),
                            _buildStatItem('Kazanılan Puan', '${widget.profile.totalScore} 🪙', AppConstants.gold),
                            _buildStatItem('Oynanan Oyun', '${widget.profile.gamesPlayed}', Colors.white),
                            _buildStatItem('Kazanılan Oyun', '${widget.profile.gamesWon}', AppConstants.waterCyan),
                            _buildStatItem('Mevcut Sıralama', '#${widget.profile.rank}', AppConstants.fireOrange),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // SAĞ TARAF: NEFES ALAN VE SALLANAN KARAKTER (ANIMATED IDLE CHARACTER)
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.borderCard),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Canlı Salınım & Nefes Animasyonu
                            AnimatedBuilder(
                              animation: _idleAnimController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, sin(_idleAnimController.value * pi) * 6), // Dikey nefes alma
                                  child: Transform.rotate(
                                    angle: _swayAnim.value, // Hafif sağa sola sallanma
                                    child: Transform.scale(
                                      scale: _breathAnim.value,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 120,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.waterBlue.withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      spreadRadius: 6,
                                    )
                                  ],
                                ),
                              child: const AnimatedFirefighterWidget(
                                size: 120,
                                state: CharacterAnimState.idle,
                              ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.bgDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppConstants.borderCard),
                              ),
                              child: const Text('Kıdemli İtfaiyeci', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ALT BÖLÜM: 6 SEÇENEK BUTONLARI (TEK OYNA, ONLİNE OYNA, TABLO, DÜZENLE, AYARLAR, ÇIKIŞ)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Üst Sıra: Ana Oyun Modları (Tek Oyna, Online Oyna)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuButton(
                          title: 'TEK OYNA',
                          subtitle: '2, 3 veya 4 Kişilik',
                          icon: Icons.sports_esports,
                          gradient: const [Color(0xFFFF5722), Color(0xFFFF9800)],
                          onTap: _showOfflinePlayerCountDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuButton(
                          title: 'ONLINE OYNA',
                          subtitle: '4 Kişilik Eşleşme',
                          icon: Icons.public,
                          gradient: const [Color(0xFF0070F3), Color(0xFF00C6FF)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LobbyScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Alt Sıra: Yardımcı Seçenekler (Tablo, Düzenle, Ayarlar, Çıkış)
                  Row(
                    children: [
                      _buildMiniButton(icon: Icons.leaderboard, label: 'Tablo', onTap: _showLeaderboardDialog),
                      const SizedBox(width: 8),
                      _buildMiniButton(
                        icon: Icons.checkroom,
                        label: 'Düzenle',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CharacterScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildMiniButton(icon: Icons.settings, label: 'Ayarlar', onTap: _showSettingsDialog),
                      const SizedBox(width: 8),
                      _buildMiniButton(
                        icon: Icons.exit_to_app,
                        label: 'Çıkış',
                        color: Colors.redAccent,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Oyundan çıkılıyor...')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: gradient.first.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppConstants.bgDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppConstants.borderCard),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
