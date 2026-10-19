import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/character.dart';
import '../models/mission.dart';
import '../models/match.dart';

class ApiService {
  String? _authToken;
  String? _profileId;
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return AppConstants.baseUrl;
  }

  void setProfileId(String profileId) {
    _profileId = profileId;
  }

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    'X-Character-Profile-Id': ?_profileId,
  };

  Future<bool> checkInternetConnection() async {
    try {
      final response = await http.get(Uri.https('connectivitycheck.gstatic.com', '/generate_204'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<CharacterModel> getCharacter() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/v1/characters/me'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return CharacterModel.fromJson(data['data'] ?? {});
      }
    } catch (_) {}
    return CharacterModel(
      id: 'demo-char-1',
      name: 'İtfaiyeci Ahmet',
      level: 1,
      experience: 150,
      equippedHat: 'Standart Kask',
      equippedSuit: 'İtfaiye Ceketi',
    );
  }

  Future<bool> saveCharacterCustomization(CharacterModel character) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/characters/customization'),
        headers: _headers,
        body: jsonEncode({
          'gender': character.gender,
          'hat': character.equippedHat ?? 'Standart kask',
          'hatStyle': character.hatStyle,
          'suit': character.equippedSuit ?? 'Klasik itfaiye ceketi',
          'suitStyle': character.suitStyle,
          'accessory': character.equippedAccessory,
          'skinColorValue': character.skinColorValue,
          'suitColorValue': character.suitColorValue,
        }),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCharacterCustomization() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/characters/customization'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<MissionModel>> getMissions() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/v1/missions'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list.map((m) => MissionModel.fromJson(m)).toList();
      }
    } catch (_) {}
    return [
      MissionModel(
        id: '1',
        title: 'Sanayi Yangınını Söndür',
        description: 'Sanayi bölgesinde çıkan yangını en az %80 söndür.',
        targetScore: 2500,
        rewardCoins: 350,
        rewardXp: 500,
      ),
      MissionModel(
        id: '2',
        title: 'Okul Binasından 3 Kişi Kurtar',
        description: 'Duman kaplı binadan mahsur kalanları güvenli alana taşı.',
        targetScore: 4000,
        rewardCoins: 500,
        rewardXp: 750,
      ),
      MissionModel(
        id: '3',
        title: 'Orman Sınır Hattını Savun',
        description: 'Alevlerin yerleşim yerine sıçramasını engelle.',
        targetScore: 6000,
        rewardCoins: 800,
        rewardXp: 1200,
      ),
    ];
  }

  Future<MatchModel?> createMatch(String type, int maxPlayers) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/matches'),
        headers: _headers,
        body: jsonEncode({'type': type, 'maxPlayers': maxPlayers}),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return MatchModel.fromJson(data['data'] ?? {});
      }
    } catch (_) {}
    return MatchModel(
      id: 'demo-room-${DateTime.now().millisecondsSinceEpoch % 1000}',
      type: type,
      status: 'Lobby',
      maxPlayers: maxPlayers,
      currentPlayers: 1,
    );
  }
}
