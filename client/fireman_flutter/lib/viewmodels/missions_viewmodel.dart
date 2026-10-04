import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../services/api_service.dart';

class MissionsViewModel extends ChangeNotifier {
  final ApiService _apiService;
  List<MissionModel> _missions = [];
  bool _isLoading = false;

  List<MissionModel> get missions => _missions;
  bool get isLoading => _isLoading;

  MissionsViewModel(this._apiService);

  Future<void> loadMissions() async {
    _isLoading = true;
    notifyListeners();
    _missions = await _apiService.getMissions();
    _isLoading = false;
    notifyListeners();
  }

  void markCompleted(String id) {
    final index = _missions.indexWhere((m) => m.id == id);
    if (index != -1) {
      final old = _missions[index];
      _missions[index] = MissionModel(
        id: old.id,
        title: old.title,
        description: old.description,
        targetScore: old.targetScore,
        rewardCoins: old.rewardCoins,
        rewardXp: old.rewardXp,
        isCompleted: true,
      );
      notifyListeners();
    }
  }
}
