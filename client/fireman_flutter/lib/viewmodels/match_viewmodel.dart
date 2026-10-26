import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/api_service.dart';

class MatchViewModel extends ChangeNotifier {
  final ApiService _apiService;
  MatchModel? _currentMatch;
  bool _isSearching = false;
  String _statusMessage = 'Lobiye bağlanmaya hazır.';
  List<MatchModel> _openRooms = const [];

  MatchModel? get currentMatch => _currentMatch;
  bool get isSearching => _isSearching;
  String get statusMessage => _statusMessage;
  List<MatchModel> get openRooms => _openRooms;

  MatchViewModel(this._apiService);

  Future<bool> createMatch({required String roomName, String? password}) async {
    _isSearching = true;
    _statusMessage = 'Oda oluşturuluyor...';
    notifyListeners();

    try {
      _currentMatch = await _apiService.createMatch('CoopRescue', 4, roomName: roomName, password: password);
      try {
        await _apiService.inviteFriendsToMatch(_currentMatch!.id);
      } catch (_) {
        // Room creation remains valid if the social notification service is temporarily unavailable.
      }
    } catch (_) {
      final serverAvailable = await _apiService.checkServerConnection();
      _statusMessage = serverAvailable
          ? 'Oda kurulamadı. Hesap oturumunu ve oda bilgilerini kontrol et.'
          : 'Oyun sunucusuna ulaşılamıyor. Sunucu henüz çalışmıyor olabilir; sunucu açıldığında tekrar dene.';
      _isSearching = false;
      notifyListeners();
      return false;
    }
    _isSearching = false;
    _statusMessage = 'Oda hazır: ${_currentMatch?.roomName}';
    notifyListeners();
    await refreshRooms();
    return true;
  }

  Future<void> refreshRooms() async {
    try { _openRooms = await _apiService.getOpenRooms(); }
    catch (_) { _statusMessage = 'Oda listesi yüklenemedi. Bağlantını kontrol et.'; }
    notifyListeners();
  }

  Future<bool> joinRoom(String roomId, {String? password}) async {
    _isSearching = true; notifyListeners();
    try {
      _currentMatch = await _apiService.joinMatch(roomId, password: password);
      _statusMessage = 'Odaya katıldın: ${_currentMatch!.roomName}';
      _isSearching = false; notifyListeners(); await refreshRooms(); return true;
    } catch (_) {
      _statusMessage = 'Odaya katılınamadı. Şifreyi ve bağlantını kontrol et.';
      _isSearching = false; notifyListeners(); return false;
    }
  }

  Future<bool> quickMatch() async {
    _isSearching = true; _statusMessage = 'Uygun oda aranıyor...'; notifyListeners();
    try {
      _currentMatch = await _apiService.quickMatch();
      _statusMessage = 'Eşleşme bulundu: ${_currentMatch!.roomName}';
      _isSearching = false; notifyListeners(); await refreshRooms(); return true;
    } catch (_) {
      _statusMessage = 'Eşleşme bulunamadı. Bağlantını kontrol et.';
      _isSearching = false; notifyListeners(); return false;
    }
  }

  Future<void> leaveCurrentMatch() async {
    final match = _currentMatch;
    if (match == null) return;
    try { await _apiService.leaveMatch(match.id); } finally {
      _currentMatch = null; _statusMessage = 'Odadan ayrıldın.'; notifyListeners(); await refreshRooms();
    }
  }
}
