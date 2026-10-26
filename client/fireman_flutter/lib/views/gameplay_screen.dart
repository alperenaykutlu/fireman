import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_elements.dart';
import '../models/user_profile.dart';
import '../viewmodels/character_viewmodel.dart';
import '../viewmodels/gameplay_viewmodel.dart';
import '../viewmodels/match_viewmodel.dart';
import '../services/api_service.dart';
import '../services/match_realtime_service.dart';
import 'connection_notice.dart';
import 'widgets/touch_controls.dart';
import 'widgets/fighters_status_strip.dart';
import 'widgets/control_dock.dart';
import 'widgets/arena_viewport.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, this.isOnline = false, this.playerName, this.profile});

  final bool isOnline;
  final String? playerName;
  final UserProfile? profile;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  MatchRealtimeService? _realtime;
  String? _connectionMessage;
  bool _connectionChecked = false;
  bool _settlingMatch = false;
  bool _matchSettled = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final characterVm = context.read<CharacterViewModel>();
      await characterVm.loadCharacter();
      if (!mounted) return;
      final vm = context.read<GameplayViewModel>();
      vm.configureLocalPlayer(name: widget.playerName ?? widget.profile?.username, character: characterVm.character);
      vm.addListener(_settleCompletedMatch);
    });
    if (widget.isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectRealtime());
    }
  }

  @override
  void dispose() {
    try { context.read<GameplayViewModel>().removeListener(_settleCompletedMatch); } catch (_) {}
    if (widget.isOnline) {
      final realtime = _realtime;
      if (realtime != null) unawaited(realtime.disconnect());
      try { unawaited(context.read<MatchViewModel>().leaveCurrentMatch()); } catch (_) {}
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _settleCompletedMatch() {
    if (!mounted) return;
    final vm = context.read<GameplayViewModel>();
    if (!vm.isGameOver) { _matchSettled = false; return; }
    if (_matchSettled || _settlingMatch) return;
    _settlingMatch = true;
    _matchSettled = true;
    unawaited(() async {
      final score = vm.score;
      final profile = widget.profile ?? await UserProfile.load();
      profile.totalScore += score;
      profile.gamesPlayed += 1;
      if (_humanPlayer(vm)?.status == PlayerStatus.alive) profile.gamesWon += 1;
      await profile.save();
      final characterVm = context.read<CharacterViewModel>();
      await characterVm.loadCharacter();
      final coins = score <= 0 ? 0 : (score * (widget.isOnline ? 0.01 : 0.001)).floor();
      characterVm.addRewards(coins, score > 0 ? score ~/ 10 : 0);
      if (mounted) setState(() {});
      _settlingMatch = false;
    }());
  }

  Future<void> _connectRealtime() async {
    if (!mounted || !widget.isOnline) return;
    final match = context.read<MatchViewModel>().currentMatch;
    if (match == null) {
      setState(() { _connectionMessage = 'Aktif oyun odası bulunamadı'; _connectionChecked = true; });
      return;
    }
    final api = context.read<ApiService>();
    final vm = context.read<GameplayViewModel>();
    final realtime = MatchRealtimeService(api);
    _realtime = realtime;
    vm.setOnlineUserId(api.currentUserId ?? '');
    vm.enableAuthoritativeOnlineMode();
    realtime.addListener(_onRealtimeChanged);
    realtime.onSnapshot = vm.applyAuthoritativeSnapshot;
    realtime.onPlayerLeft = (event) => vm.markUserDisconnected(_eventString(event, 'UserId'));
    realtime.onPlayerConnectionLost = (event) {
      if (!mounted) return;
      final name = _eventString(event, 'Username');
      setState(() { _connectionMessage = name.isEmpty ? 'Bir oyuncu yeniden bağlanıyor' : '$name yeniden bağlanıyor'; });
    };
    await realtime.connect(match.id);
    if (mounted) _onRealtimeChanged();
  }

  static String _eventString(Map<String, dynamic> event, String key) =>
      (event[key] ?? event[key[0].toLowerCase() + key.substring(1)])?.toString() ?? '';

  void _onRealtimeChanged() {
    final realtime = _realtime;
    if (!mounted || realtime == null) return;
    final message = switch (realtime.status) {
      RealtimeConnectionStatus.connected => null,
      RealtimeConnectionStatus.connecting => 'Oyun sunucusuna bağlanılıyor',
      RealtimeConnectionStatus.reconnecting => 'Bağlantı koptu • yeniden bağlanılıyor',
      RealtimeConnectionStatus.disconnected => 'Sunucu bağlantısı kapandı',
      RealtimeConnectionStatus.failed => realtime.statusMessage ?? 'Oyun sunucusuna bağlanılamadı',
      RealtimeConnectionStatus.idle => 'Bağlantı bekleniyor',
    };
    if (_connectionMessage != message || !_connectionChecked) {
      setState(() { _connectionMessage = message; _connectionChecked = true; });
    }
  }

  void _setMovement(GameplayViewModel vm, int dx, int dy) {
    vm.setMovementDirection(dx, dy);
    final realtime = _realtime;
    if (widget.isOnline && realtime != null) {
      final player = _humanPlayer(vm);
      realtime.setMovement(dx, dy,
        subTileX: (player?.x ?? 0) * 256 + 128,
        subTileY: (player?.y ?? 0) * 256 + 128,
      );
    }
  }

  void _placeBomb(GameplayViewModel vm) {
    if (!widget.isOnline) { vm.placeDynamite(); return; }
    final player = _humanPlayer(vm);
    _realtime?.placeBomb(
      subTileX: (player?.x ?? 0) * 256 + 128,
      subTileY: (player?.y ?? 0) * 256 + 128,
    );
  }

  ArenaFighter? _humanPlayer(GameplayViewModel vm) {
    for (final fighter in vm.fighters) {
      if (fighter.isHuman) return fighter;
    }
    return null;
  }

  void _handleKeyEvent(KeyEvent event, GameplayViewModel vm) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _placeBomb(vm);
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }

    // Çapraz hareketi engelle: Ya sadece yatay ya sadece dikey (Orthogonal)
    int dx = 0;
    int dy = 0;

    final isUp =
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyW);
    final isDown =
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyS);
    final isLeft =
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA);
    final isRight =
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD);

    if (isUp && !isDown) {
      dy = -1;
    } else if (isDown && !isUp) {
      dy = 1;
    } else if (isLeft && !isRight) {
      dx = -1;
    } else if (isRight && !isLeft) {
      dx = 1;
    }

    _setMovement(vm, dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    // Sadece klavye tuş eventleri için context.read kullanılır; tüm ekranı izlemiyoruz (Optimizasyon 1.3)
    final vm = context.read<GameplayViewModel>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, vm),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final controlSize = (constraints.maxHeight * 0.40).clamp(
                60.0,
                96.0,
              ).toDouble();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Row(children: [
                      Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFFF7043).withValues(alpha: .16), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.local_fire_department, color: Color(0xFFFF805A), size: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(widget.isOnline ? 'ÇEVRİMİÇİ ARENA' : 'ANTRENMAN ARENASI', style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                        Row(children: [if (widget.isOnline) ...[Icon(Icons.circle, size: 7, color: !_connectionChecked ? const Color(0xFFFFC857) : _connectionMessage == null ? const Color(0xFF5DE0A5) : const Color(0xFFFF705C)), const SizedBox(width: 5)], Text(widget.isOnline ? (_connectionMessage ?? (_realtime?.pingMs == null ? 'Sunucuya bağlı' : 'Sunucuya bağlı · ${_realtime!.pingMs} ms')) : 'Botlara karşı', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))]),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF172436), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFC857).withValues(alpha: .28))), child: Row(children: [const Icon(Icons.group_outlined, color: Color(0xFFFFC857), size: 15), const SizedBox(width: 4), Text('${vm.totalPlayerCount} OYUNCU', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5))])),
                      const SizedBox(width: 7),
                      IconButton(visualDensity: VisualDensity.compact, tooltip: 'Arenayı yeniden başlat', onPressed: () { _pressedKeys.clear(); vm.startNewGame(); }, icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 19)),
                      IconButton(visualDensity: VisualDensity.compact, tooltip: 'Oyundan çık', onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 19)),
                    ]),
                  ),
                  const FightersStatusStrip(),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ControlDock(
                              title: 'HAREKET', icon: Icons.open_with_rounded,
                              child: VirtualTouchPad(size: controlSize, onDirectionChanged: (dx, dy) => _setMovement(vm, dx, dy)),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Container(
                                    decoration: BoxDecoration(color: const Color(0xFF0C121B), borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFF6D829A).withValues(alpha: .45)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))]),
                                    clipBehavior: Clip.antiAlias,
                                    child: const ArenaViewport(),
                                  ))),
                                  if (_connectionMessage != null)
                                    Positioned(
                                      left: 8,
                                      right: 8,
                                      top: 8,
                                      child: ConnectionAlert(
                                        message: _connectionMessage!,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ControlDock(
                              title: 'AKSİYON', icon: Icons.bolt_rounded,
                              child: GlowingActionButton(label: 'DİNAMİT', iconEmoji: '🧨', size: controlSize * 0.82, onPressed: () => _placeBomb(vm)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
