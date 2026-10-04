import 'package:flutter/foundation.dart';

class GameplayViewModel extends ChangeNotifier {
  double _waterPercentage = 100.0;
  double _firePercentage = 100.0;
  int _score = 0;
  int _rescues = 0;
  double _playerPositionX = 60.0;

  double get waterPercentage => _waterPercentage;
  double get firePercentage => _firePercentage;
  int get score => _score;
  int get rescues => _rescues;
  double get playerPositionX => _playerPositionX;

  void sprayWater() {
    if (_waterPercentage <= 0) return;

    _waterPercentage = (_waterPercentage - 2.5).clamp(0.0, 100.0);
    _firePercentage = (_firePercentage - 4.0).clamp(0.0, 100.0);
    _score += 50;

    if (_firePercentage <= 0) {
      _rescues += 1;
      _score += 500;
    }
    notifyListeners();
  }

  void refillWater() {
    _waterPercentage = 100.0;
    notifyListeners();
  }

  void restartFire() {
    _firePercentage = 100.0;
    notifyListeners();
  }

  void movePlayer(double delta) {
    _playerPositionX = (_playerPositionX + delta).clamp(20.0, 240.0);
    notifyListeners();
  }
}
