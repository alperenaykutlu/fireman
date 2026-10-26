import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/msgpack_hub_protocol.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'api_service.dart';

enum RealtimeConnectionStatus { idle, connecting, connected, reconnecting, disconnected, failed }

/// Authenticated, WebSocket-only SignalR transport for a single active match.
/// Snapshot decoding and network callbacks stay outside the widget build loop.
class MatchRealtimeService extends ChangeNotifier {
  MatchRealtimeService(this._api);
  final ApiService _api;

  HubConnection? _hub;
  Timer? _inputTimer;
  Timer? _pingTimer;
  String? _matchId;
  int _moveX = 0;
  int _moveY = 0;
  int _subTileX = 0;
  int _subTileY = 0;
  int _sequence = 0;
  int _clientTick = 0;
  int? _pingMs;
  bool _bombQueued = false;
  bool _disposed = false;
  bool _sendingInput = false;
  RealtimeConnectionStatus _status = RealtimeConnectionStatus.idle;
  String? _statusMessage;

  RealtimeConnectionStatus get status => _status;
  String? get statusMessage => _statusMessage;
  int? get pingMs => _pingMs;
  bool get isConnected => _status == RealtimeConnectionStatus.connected;

  ValueChanged<Map<String, dynamic>>? onSnapshot;
  ValueChanged<Map<String, dynamic>>? onPlayerJoined;
  ValueChanged<Map<String, dynamic>>? onPlayerConnectionLost;
  ValueChanged<Map<String, dynamic>>? onPlayerLeft;
  ValueChanged<String>? onViolation;

  Future<void> connect(String matchId) async {
    if (_disposed) return;
    final token = _api.accessToken;
    if (token == null || token.isEmpty || _api.currentUserId == null) {
      _setStatus(RealtimeConnectionStatus.failed, 'Çevrimiçi oyun için oyuncu hesabına giriş yap.');
      return;
    }
    _matchId = matchId;
    _setStatus(RealtimeConnectionStatus.connecting, 'Oyun sunucusuna bağlanılıyor');

    final options = HttpConnectionOptions(
      transport: HttpTransportType.WebSockets,
      accessTokenFactory: () async => _api.accessToken ?? token,
      requestTimeout: 8000,
    );
    final hub = HubConnectionBuilder()
        .withUrl(_api.matchHubUrl, options: options)
        .withHubProtocol(MessagePackHubProtocol())
        .withAutomaticReconnect(retryDelays: <int>[2000, 5000, 10000, 20000])
        .build();
    hub.keepAliveIntervalInMilliseconds = 15000;
    hub.serverTimeoutInMilliseconds = 45000;
    _hub = hub;
    _registerHandlers(hub);

    try {
      await hub.start();
      await _joinRoom(hub);
      _setStatus(RealtimeConnectionStatus.connected, 'Oyun sunucusuna bağlı');
      _startInputLoop();
      _startPingLoop();
    } catch (_) {
      _setStatus(RealtimeConnectionStatus.failed, 'Oyun sunucusuna bağlanılamadı. Yeniden deneyebilirsin.');
    }
  }

  void _registerHandlers(HubConnection hub) {
    hub.on('WorldSnapshotReceived', (args) {
      final snapshot = args == null || args.isEmpty ? null : _asMap(args.first);
      if (snapshot != null) onSnapshot?.call(snapshot);
    });
    hub.on('PlayerJoined', (args) { final value = _eventMap(args); if (value != null) onPlayerJoined?.call(value); });
    hub.on('PlayerConnectionLost', (args) { final value = _eventMap(args); if (value != null) onPlayerConnectionLost?.call(value); });
    hub.on('PlayerLeft', (args) { final value = _eventMap(args); if (value != null) onPlayerLeft?.call(value); });
    hub.on('CheatViolationAlert', (args) {
      if (args != null && args.isNotEmpty) onViolation?.call(args.first.toString());
    });
    hub.onreconnecting(({error}) {
      _stopLoops();
      _setStatus(RealtimeConnectionStatus.reconnecting, 'Bağlantı yenileniyor · oda korunuyor');
    });
    hub.onreconnected(({connectionId}) {
      unawaited(_afterReconnect(hub));
    });
    hub.onclose(({error}) {
      _stopLoops();
      _setStatus(RealtimeConnectionStatus.disconnected, 'Sunucu bağlantısı kapandı');
    });
  }

  Future<void> _joinRoom(HubConnection hub) async {
    final matchId = _matchId;
    if (matchId == null) return;
    await hub.invoke('JoinMatchRoom', args: <Object>[matchId]);
  }

  Future<void> _afterReconnect(HubConnection hub) async {
    try {
      await _joinRoom(hub);
      _setStatus(RealtimeConnectionStatus.connected, 'Yeniden bağlandı · oda durumu eşitleniyor');
      _startInputLoop();
      _startPingLoop();
    } catch (_) {
      _setStatus(RealtimeConnectionStatus.failed, 'Odaya yeniden katılınamadı');
    }
  }

  void setMovement(int dx, int dy, {required int subTileX, required int subTileY}) {
    _moveX = dx.clamp(-1, 1).toInt();
    _moveY = dy.clamp(-1, 1).toInt();
    if (_moveX != 0 && _moveY != 0) _moveY = 0;
    _subTileX = subTileX;
    _subTileY = subTileY;
  }

  void placeBomb({required int subTileX, required int subTileY}) {
    _subTileX = subTileX;
    _subTileY = subTileY;
    _bombQueued = true;
    unawaited(_sendInput());
  }

  void _startInputLoop() {
    _inputTimer?.cancel();
    _inputTimer = Timer.periodic(const Duration(milliseconds: 33), (_) => unawaited(_sendInput()));
  }

  Future<void> _sendInput() async {
    final hub = _hub;
    final matchId = _matchId;
    final userId = _api.currentUserId;
    if (!isConnected || hub == null || matchId == null || userId == null || _sendingInput) return;
    final direction = _moveY < 0 ? 1 : _moveY > 0 ? 2 : _moveX < 0 ? 3 : _moveX > 0 ? 4 : 0;
    if (direction == 0 && !_bombQueued) return;

    final bomb = _bombQueued;
    _bombQueued = false;
    _sendingInput = true;
    final packet = <String, Object>{
      'MatchId': matchId,
      'UserId': userId,
      'Seq': ++_sequence,
      'ClientTick': ++_clientTick,
      'MoveDir': direction,
      'PlaceBomb': bomb,
      'SubTileX': _subTileX,
      'SubTileY': _subTileY,
    };
    try {
      await hub.send('SendPlayerInput', args: <Object>[matchId, packet]);
    } catch (_) {
      if (bomb) _bombQueued = true;
    } finally {
      _sendingInput = false;
    }
  }

  void _startPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_measurePing()));
    unawaited(_measurePing());
  }

  Future<void> _measurePing() async {
    final hub = _hub;
    if (!isConnected || hub == null) return;
    final clock = Stopwatch()..start();
    try {
      await hub.invoke('Ping', args: <Object>[DateTime.now().millisecondsSinceEpoch]);
      _pingMs = clock.elapsedMilliseconds;
      notifyListeners();
    } catch (_) {
      // The transport's reconnect callback owns connection state transitions.
    }
  }

  Future<void> disconnect({bool leaveRoom = true}) async {
    _stopLoops();
    final hub = _hub;
    final matchId = _matchId;
    _hub = null;
    if (hub == null) return;
    try {
      if (leaveRoom && matchId != null && isConnected) {
        await hub.invoke('LeaveMatchRoom', args: <Object>[matchId]);
      }
    } catch (_) {}
    try { await hub.stop(); } catch (_) {}
    _setStatus(RealtimeConnectionStatus.disconnected, null);
  }

  void _stopLoops() {
    _inputTimer?.cancel();
    _inputTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _setStatus(RealtimeConnectionStatus status, String? message) {
    if (_disposed) return;
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  static Map<String, dynamic>? _eventMap(List<Object?>? args) => args == null || args.isEmpty ? null : _asMap(args.first);

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is! Map) return null;
    return {for (final entry in value.entries) entry.key.toString(): entry.value};
  }

  @override
  void dispose() {
    _disposed = true;
    _stopLoops();
    final hub = _hub;
    _hub = null;
    if (hub != null) unawaited(hub.stop().catchError((_) {}));
    super.dispose();
  }
}
