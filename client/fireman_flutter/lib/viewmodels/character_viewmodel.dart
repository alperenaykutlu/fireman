import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../services/api_service.dart';

class CharacterViewModel extends ChangeNotifier {
  final ApiService _apiService;
  CharacterModel? _character;
  bool _isLoading = false;

  int _coins = 500;
  final int _gems = 10;

  CharacterModel? get character => _character;
  bool get isLoading => _isLoading;
  int get coins => _coins;
  int get gems => _gems;

  CharacterViewModel(this._apiService);

  Future<void> loadCharacter() async {
    _isLoading = true;
    notifyListeners();
    _character = await _apiService.getCharacter();
    _isLoading = false;
    notifyListeners();
  }

  void equipHat(String hatName) {
    if (_character != null) {
      _character = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        level: _character!.level,
        experience: _character!.experience,
        equippedHat: hatName,
        equippedSuit: _character!.equippedSuit,
      );
      notifyListeners();
    }
  }

  void addRewards(int earnedCoins, int earnedXp) {
    _coins += earnedCoins;
    if (_character != null) {
      int newExp = _character!.experience + earnedXp;
      int newLevel = 1 + (newExp ~/ 1000);
      _character = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        level: newLevel,
        experience: newExp,
        equippedHat: _character!.equippedHat,
        equippedSuit: _character!.equippedSuit,
      );
    }
    notifyListeners();
  }
}
