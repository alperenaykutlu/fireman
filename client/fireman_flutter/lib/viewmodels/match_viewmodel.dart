import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/api_service.dart';

class MatchViewModel extends ChangeNotifier {
  final ApiService _apiService;
  MatchModel? _currentMatch;
  bool _isSearching = false;
  String _statusMessage = 'Lobiye bağlanmaya hazır.';

  MatchModel? get currentMatch => _currentMatch;
  bool get isSearching => _isSearching;
  String get statusMessage => _statusMessage;

  MatchViewModel(this._apiService);

  Future<void> createMatch() async {
    _isSearching = true;
    _statusMessage = 'Oda oluşturuluyor...';
    notifyListeners();

    _currentMatch = await _apiService.createMatch('CoopRescue', 4);
    _isSearching = false;
    _statusMessage = 'Oda hazır: ${_currentMatch?.id}';
    notifyListeners();
  }

  void joinRoom(String roomId) {
    _currentMatch = MatchModel(
      id: roomId,
      type: 'CoopRescue',
      status: 'InProgress',
      maxPlayers: 4,
      currentPlayers: 2,
    );
    _statusMessage = 'Odaya katıldınız! Oyun başlıyor.';
    notifyListeners();
  }
}
