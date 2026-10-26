import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/character.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CharacterViewModel extends ChangeNotifier {
  final ApiService _apiService;
  CharacterModel? _character;
  bool _isLoading = false;

  int _coins = 500;
  final Map<String, int> _unlocked = {};
  final int _gems = 10;

  CharacterModel? get character => _character;
  bool get isLoading => _isLoading;
  int get coins => _coins;
  int get gems => _gems;
  int get hatUnlocked => unlockedFor('hat');
  int get suitUnlocked => unlockedFor('suit');
  int get accessoryUnlocked => unlockedFor('accessory');
  int unlockedFor(String category) => _unlocked[category] ?? 0;

  CharacterViewModel(this._apiService);

  Future<void> loadCharacter() async {
    if (_character != null && !_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt('character_coins') ?? 500;
      for (final category in ['hat', 'suit', 'accessory', 'mask', 'gloves', 'shoes', 'bomb']) {
        _unlocked[category] = prefs.getInt('${category}_unlocked') ?? 0;
      }
      var profileId = prefs.getString('character_profile_id');
      if (profileId == null) {
        profileId = _newProfileId();
        await prefs.setString('character_profile_id', profileId);
      }
      _apiService.setProfileId(profileId);

      // Render the saved local appearance immediately; network sync can finish in the background.
      _character = CharacterModel(
        id: 'device-profile',
        name: 'İtfaiyeci',
        level: 1,
        experience: 0,
        equippedHat: prefs.getString('character_hat') ?? 'Standart kask',
        equippedSuit:
            prefs.getString('character_suit') ?? 'Klasik itfaiye ceketi',
        gender: prefs.getString('character_gender') ?? 'male',
        equippedAccessory:
            prefs.getString('character_accessory') ?? 'Hortum seti',
        hatStyle: prefs.getInt('character_hat_style') ?? 0,
        suitStyle: prefs.getInt('character_suit_style') ?? 0,
        skinColorValue: prefs.getInt('character_skin_color') ?? 0xFFFFD1A4,
        suitColorValue: prefs.getInt('character_suit_color') ?? 0xFFDC2626,
        equippedMask: prefs.getString('character_mask') ?? 'Standart maske',
        equippedGloves: prefs.getString('character_gloves') ?? 'Standart eldiven',
        equippedShoes: prefs.getString('character_shoes') ?? 'Standart ayakkabı',
        equippedBomb: prefs.getString('character_bomb') ?? 'Klasik dinamit',
      );
      _isLoading = false;
      notifyListeners();

      final remoteCharacter = await _apiService.getCharacter();
      final saved = await _apiService.getCharacterCustomization();
      final local = _character!;
      _character = CharacterModel(
        id: remoteCharacter.id,
        name: remoteCharacter.name,
        level: remoteCharacter.level,
        experience: remoteCharacter.experience,
        gender: saved?['gender'] ?? local.gender,
        equippedHat: saved?['hat'] ?? local.equippedHat,
        hatStyle: saved?['hatStyle'] ?? local.hatStyle,
        equippedSuit: saved?['suit'] ?? local.equippedSuit,
        suitStyle: saved?['suitStyle'] ?? local.suitStyle,
        equippedAccessory: saved?['accessory'] ?? local.equippedAccessory,
        skinColorValue: saved?['skinColorValue'] ?? local.skinColorValue,
        suitColorValue: saved?['suitColorValue'] ?? local.suitColorValue,
        equippedMask: saved?['mask'] ?? local.equippedMask,
        equippedGloves: saved?['gloves'] ?? local.equippedGloves,
        equippedShoes: saved?['shoes'] ?? local.equippedShoes,
        equippedBomb: saved?['bomb'] ?? local.equippedBomb,
      );
      notifyListeners();
    } catch (_) {
      _character ??= CharacterModel(
        id: 'device-profile',
        name: 'İtfaiyeci',
        level: 1,
        experience: 0,
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  String _newProfileId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
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
        gender: _character!.gender,
        equippedAccessory: _character!.equippedAccessory,
        hatStyle: _character!.hatStyle,
        suitStyle: _character!.suitStyle,
        skinColorValue: _character!.skinColorValue,
        suitColorValue: _character!.suitColorValue,
        equippedMask: _character!.equippedMask,
        equippedGloves: _character!.equippedGloves,
        equippedShoes: _character!.equippedShoes,
        equippedBomb: _character!.equippedBomb,
      );
      SharedPreferences.getInstance().then(
        (p) => p.setString('character_hat', hatName),
      );
      notifyListeners();
    }
  }

  void customize({
    String? gender,
    String? hat,
    String? suit,
    String? accessory,
    int? hatStyle,
    int? suitStyle,
    int? skinColorValue,
    int? suitColorValue,
    String? mask,
    String? gloves,
    String? shoes,
    String? bomb,
  }) {
    final current = _character;
    if (current == null) return;
    _character = CharacterModel(
      id: current.id,
      name: current.name,
      level: current.level,
      experience: current.experience,
      equippedHat: hat ?? current.equippedHat,
      equippedSuit: suit ?? current.equippedSuit,
      gender: gender ?? current.gender,
      equippedAccessory: accessory ?? current.equippedAccessory,
      hatStyle: hatStyle ?? current.hatStyle,
      suitStyle: suitStyle ?? current.suitStyle,
      skinColorValue: skinColorValue ?? current.skinColorValue,
      suitColorValue: suitColorValue ?? current.suitColorValue,
      equippedMask: mask ?? current.equippedMask,
      equippedGloves: gloves ?? current.equippedGloves,
      equippedShoes: shoes ?? current.equippedShoes,
      equippedBomb: bomb ?? current.equippedBomb,
    );
    SharedPreferences.getInstance().then((p) async {
      await p.setString('character_gender', _character!.gender);
      await p.setString(
        'character_hat',
        _character!.equippedHat ?? 'Standart Kask',
      );
      await p.setString(
        'character_suit',
        _character!.equippedSuit ?? 'İtfaiye Ceketi',
      );
      await p.setString('character_accessory', _character!.equippedAccessory);
      await p.setInt('character_hat_style', _character!.hatStyle);
      await p.setInt('character_suit_style', _character!.suitStyle);
      await p.setInt('character_skin_color', _character!.skinColorValue);
      await p.setInt('character_suit_color', _character!.suitColorValue);
      await p.setString('character_mask', _character!.equippedMask);
      await p.setString('character_gloves', _character!.equippedGloves);
      await p.setString('character_shoes', _character!.equippedShoes);
      await p.setString('character_bomb', _character!.equippedBomb);
      await _apiService.saveCharacterCustomization(_character!);
    });
    notifyListeners();
  }

  bool purchaseNext(String category) {
    final current = unlockedFor(category);
    if (current >= 49 || _coins < 100) return false;
    _coins -= 100;
    _unlocked[category] = current + 1;
    SharedPreferences.getInstance().then((p) async {
      await p.setInt('character_coins', _coins);
      await p.setInt('${category}_unlocked', current + 1);
    });
    notifyListeners();
    return true;
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
        gender: _character!.gender,
        equippedAccessory: _character!.equippedAccessory,
        hatStyle: _character!.hatStyle,
        suitStyle: _character!.suitStyle,
        skinColorValue: _character!.skinColorValue,
        suitColorValue: _character!.suitColorValue,
        equippedMask: _character!.equippedMask,
        equippedGloves: _character!.equippedGloves,
        equippedShoes: _character!.equippedShoes,
        equippedBomb: _character!.equippedBomb,
      );
    }
    SharedPreferences.getInstance().then((p) => p.setInt('character_coins', _coins));
    notifyListeners();
  }
}
