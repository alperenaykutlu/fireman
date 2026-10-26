import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_audio_service.dart';
import '../core/character/animated_firefighter_widget.dart';
import '../core/character/character_state.dart';
import '../core/constants.dart';
import '../models/user_profile.dart';
import '../viewmodels/gameplay_viewmodel.dart';
import '../viewmodels/character_viewmodel.dart';
import 'character_screen.dart';
import 'gameplay_screen.dart';
import 'lobby_screen.dart';
import 'friends_screen.dart';
import 'missions_screen.dart';
import '../shared/widgets/menu_buttons.dart';
import '../shared/widgets/fireman_card.dart';

class MainMenuScreen extends StatefulWidget {
  final UserProfile profile;

  const MainMenuScreen({super.key, required this.profile});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleAnimController;
  late Animation<double> _breathAnim;
  late Animation<double> _swayAnim;

  @override
  void initState() {
    super.initState();
    GameAudioService.instance.startGameMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CharacterViewModel>().loadCharacter());
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Text('🎮 ', style: TextStyle(fontSize: 22)),
              Text(
                'Tek Oyna (Offline)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
      onTap: () async {
        Navigator.pop(context);
        if (!mounted) return;
        context.read<GameplayViewModel>().setPlayerCount(count);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameplayScreen(isOnline: false, playerName: widget.profile.username, profile: widget.profile)),
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
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.fireOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    var musicEnabled = true;
    var vibrationEnabled = true;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: AppConstants.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('⚙️ Oyun Ayarları'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Müzik ve ses efektleri'),
                  value: musicEnabled,
                  secondary: const Icon(Icons.volume_up, color: AppConstants.waterBlue),
                  onChanged: (enabled) {
                    setDialogState(() => musicEnabled = enabled);
                    GameAudioService.instance.setMusicEnabled(enabled);
                    GameAudioService.instance.setEffectsEnabled(enabled);
                  },
                ),
                SwitchListTile(
                  title: const Text('Titreşim (Haptic)'),
                  value: vibrationEnabled,
                  secondary: const Icon(Icons.vibration, color: AppConstants.waterCyan),
                  onChanged: (enabled) {
                    setDialogState(() => vibrationEnabled = enabled);
                    GameAudioService.instance.setVibrationEnabled(enabled);
                  },
                ),
                const ListTile(
                  title: Text('Grafik Kalitesi: Yüksek 60FPS'),
                  trailing: Icon(Icons.hd, color: AppConstants.gold),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  dense: true,
                  leading: Icon(Icons.notifications_active, color: AppConstants.gold),
                  title: Text('Günlük oyun davetleri otomatik'),
                  subtitle: Text('Her gün 12:30 ve 19:30 · Bildirim izni gerekir'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Kapat',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaderboardDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        final dialogHeight = min(520.0, size.height * .88);
        final topThree = [
          ('Su_Püskürten_99', '62,450', const Color(0xFFC0C9D5)),
          ('Kaptan_Alev', '84,200', AppConstants.gold),
          ('Demir_Hortum', '49,100', const Color(0xFFCD7F32)),
        ];
        return Dialog(
          backgroundColor: AppConstants.bgCard,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SizedBox(
            width: min(560.0, size.width - 36),
            height: dialogHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppConstants.gold,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Liderlik Tablosu',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const Text(
                    'Sezonun en başarılı itfaiyecileri',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: min(108.0, dialogHeight * .34),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildPodiumTile(
                              index == 1 ? 1 : (index == 0 ? 2 : 3),
                              topThree[index].$1,
                              topThree[index].$2,
                              topThree[index].$3,
                              height: index == 1 ? 96 : (index == 0 ? 80 : 72),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sıralama',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (var rank = 4; rank <= 8; rank++)
                          if (rank != widget.profile.rank)
                            _buildLeaderboardRow(
                              rank,
                              [
                                'AlevNöbetçisi',
                                'KurtarmaEkibi',
                                'MaviKask',
                                'GeceVardiyası',
                                'Cesurİtfaiyeci',
                              ][rank - 4],
                              '${42000 - (rank - 4) * 3750}',
                            ),
                        _buildLeaderboardRow(
                          widget.profile.rank,
                          widget.profile.username,
                          '${widget.profile.totalScore}',
                          isMe: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodiumTile(
    int rank,
    String name,
    String score,
    Color accent, {
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
          bottom: Radius.circular(8),
        ),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            rank == 1 ? Icons.workspace_premium : Icons.military_tech,
            color: accent,
            size: rank == 1 ? 22 : 18,
          ),
          Text(
            '#$rank',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          ),
          Text(
            score,
            maxLines: 1,
            style: TextStyle(color: accent, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(
    int rank,
    String name,
    String score, {
    bool isMe = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMe
            ? AppConstants.fireOrange.withValues(alpha: 0.2)
            : AppConstants.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppConstants.fireOrange : AppConstants.borderCard,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name.isEmpty ? 'Oyuncu' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (isMe)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'SEN',
                style: TextStyle(
                  color: AppConstants.fireOrange,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Text(
            '$score puan',
            style: const TextStyle(
              color: AppConstants.gold,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 430;
    final destinations = const [
      (label: 'Oyna', icon: Icons.sports_esports_outlined, active: Icons.sports_esports),
      (label: 'İstatistik', icon: Icons.bar_chart_outlined, active: Icons.bar_chart),
      (label: 'Atölye', icon: Icons.checkroom_outlined, active: Icons.checkroom),
      (label: 'Görevler', icon: Icons.task_alt_outlined, active: Icons.task_alt),
      (label: 'Arkadaşlar', icon: Icons.people_alt_outlined, active: Icons.people_alt),
      (label: 'Odalar', icon: Icons.public_outlined, active: Icons.public),
    ];
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        body: SafeArea(
          child: Builder(builder: (context) {
            final controller = DefaultTabController.of(context);
            return Padding(
            padding: EdgeInsets.fromLTRB(compact ? 7 : 12, compact ? 6 : 10, compact ? 7 : 12, compact ? 6 : 10),
            child: Row(children: [
              Container(
                width: compact ? 68 : 82,
                decoration: BoxDecoration(color: const Color(0xFF151F2D), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .06))),
                child: Column(children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: compact ? 6 : 11), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppConstants.fireOrange.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.local_fire_department, color: AppConstants.fireOrange))),
                  Expanded(child: AnimatedBuilder(animation: controller, builder: (context, _) => ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final item = destinations[index];
                      final selected = controller.index == index;
                      return Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), child: Tooltip(message: item.label, child: InkWell(
                        onTap: () => controller.animateTo(index, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(duration: const Duration(milliseconds: 180), height: compact ? 42 : 50, decoration: BoxDecoration(color: selected ? AppConstants.fireOrange.withValues(alpha: .17) : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppConstants.fireOrange.withValues(alpha: .42) : Colors.transparent)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(selected ? item.active : item.icon, size: compact ? 17 : 19, color: selected ? AppConstants.fireOrange : Colors.white54), if (!compact) ...[const SizedBox(height: 2), Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: selected ? Colors.white : Colors.white54))]])),
                      )));
                    },
                  ))),
                  IconButton(tooltip: 'Ayarlar', visualDensity: VisualDensity.compact, onPressed: _showSettingsDialog, icon: const Icon(Icons.settings_outlined, size: 19, color: Colors.white70)),
                ]),
              ),
              SizedBox(width: compact ? 8 : 13),
              Expanded(child: Column(children: [
                Container(height: compact ? 34 : 42, padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16), decoration: BoxDecoration(color: const Color(0xFF151F2D), borderRadius: BorderRadius.circular(14)), child: Row(children: [
                  Expanded(child: Text(widget.profile.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: compact ? 12 : 14))),
                  const Icon(Icons.emoji_events_outlined, color: AppConstants.gold, size: 16), const SizedBox(width: 5), Text('${widget.profile.totalScore} PUAN', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold, fontSize: 11)),
                  const SizedBox(width: 12),
                  Consumer<CharacterViewModel>(builder: (context, characterVm, _) => Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.monetization_on_outlined, color: Color(0xFFFFC857), size: 16),
                    const SizedBox(width: 4),
                    Text('${characterVm.coins} 🪙', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFD166), fontSize: 11)),
                  ])),
                ])),
                SizedBox(height: compact ? 5 : 9),
                Expanded(child: TabBarView(children: [
                  _buildPlayPage(compact),
                  _buildStatisticsPage(compact),
                  CharacterScreen(username: widget.profile.username, embedded: true),
                  const MissionsScreen(),
                  const FriendsScreen(),
                  const LobbyScreen(),
                ])),
              ])),
            ]),
          );
          }),
        ),
      ),
    );
  }

  Widget _buildPlayPage(bool compact) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 18),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: FiremanCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _idleAnimController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, sin(_idleAnimController.value * pi) * 5),
                        child: Transform.rotate(angle: _swayAnim.value, child: Transform.scale(scale: _breathAnim.value, child: child)),
                      ),
                      child: Consumer<CharacterViewModel>(builder: (context, characterVm, _) {
                        final character = characterVm.character;
                        if (character == null) return AnimatedFirefighterWidget(size: compact ? 92 : 150, state: CharacterAnimState.idle);
                        return AnimatedFirefighterWidget(size: compact ? 92 : 150, state: CharacterAnimState.idle,
                          isFemale: character.gender == 'female', hatStyle: character.hatStyle,
                          accessoryStyle: character.equippedAccessory.contains('telsizi') ? 1 : character.equippedAccessory.contains('tüp') ? 2 : 0,
                          suitStyle: character.suitStyle,
                          maskStyle: character.equippedMask.toLowerCase().contains('standart') ? -1 : 0,
                          suitColor: Color(character.suitColorValue), skinColor: Color(character.skinColorValue));
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.profile.username, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 5),
                    const Text('Kıdemli İtfaiyeci', style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ),
            SizedBox(width: compact ? 10 : 18),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FiremanMenuButton(
                    title: 'TEK OYNA', subtitle: 'Botlara karşı 2–4 oyuncu',
                    icon: Icons.local_fire_department,
                    gradient: const [Color(0xFFFF5722), Color(0xFFFF9800)],
                    onTap: _showOfflinePlayerCountDialog,
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  FiremanMenuButton(
                    title: 'ONLINE OYNA', subtitle: 'Arkadaşlarınla eşleş',
                    icon: Icons.public,
                    gradient: const [Color(0xFF0070F3), Color(0xFF00C6FF)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsPage(bool compact) {
    final stats = [
      ('Kazanılan puan', '${widget.profile.totalScore}', AppConstants.gold),
      ('Oynanan oyun', '${widget.profile.gamesPlayed}', Colors.white),
      ('Kazanılan oyun', '${widget.profile.gamesWon}', AppConstants.waterCyan),
      ('Sıralama', '#${widget.profile.rank}', AppConstants.fireOrange),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 18),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: compact ? 1.9 : 2.4,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return FiremanCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(stat.$1, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(stat.$2, style: TextStyle(color: stat.$3, fontWeight: FontWeight.w900, fontSize: 19)),
                    ]),
                  );
                },
              ),
            ),
            Row(children: [
              FiremanMiniButton(icon: Icons.emoji_events, label: 'Tablo', color: AppConstants.gold, onTap: _showLeaderboardDialog),
              const SizedBox(width: 10),
              FiremanMiniButton(icon: Icons.settings, label: 'Ayarlar', onTap: _showSettingsDialog),
              const SizedBox(width: 10),
              FiremanMiniButton(icon: Icons.exit_to_app, label: 'Çıkış', color: Colors.redAccent, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oyundan çıkılıyor...')));
              }),
            ]),
          ],
        ),
      ),
    );
  }

}
