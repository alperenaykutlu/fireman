import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/character.dart';
import '../models/mission.dart';
import '../models/match.dart';

class ApiService {
  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<CharacterModel> getCharacter() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/characters/me'),
        headers: _headers,
      );
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

  Future<List<MissionModel>> getMissions() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/missions'),
        headers: _headers,
      );
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
        Uri.parse('${AppConstants.baseUrl}/api/v1/matches'),
        headers: _headers,
        body: jsonEncode({'type': type, 'maxPlayers': maxPlayers}),
      );
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
