import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('fireman_access_token');
    _profileId = prefs.getString('fireman_user_id');
  }

  Future<Map<String, dynamic>> authenticate({required String username, required String password, String? email}) async {
    final registering = email != null;
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/auth/${registering ? 'register' : 'login'}'),
      headers: const {'Content-Type': 'application/json'}, body: jsonEncode(registering
        ? {'username': username, 'email': email, 'password': password}
        : {'username': username, 'password': password})).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    final data = (jsonDecode(response.body)['data'] ?? {}) as Map<String, dynamic>;
    _authToken = data['accessToken']?.toString();
    _profileId = data['userId']?.toString();
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) await prefs.setString('fireman_access_token', _authToken!);
    if (_profileId != null) await prefs.setString('fireman_user_id', _profileId!);
    return data;
  }

  Future<void> signOut() async {
    _authToken = null; _profileId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fireman_access_token'); await prefs.remove('fireman_user_id');
  }

  Future<Map<String, dynamic>> signInWithGoogleIdToken(String idToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/google'),
      headers: _mutationHeaders(),
      body: jsonEncode({'idToken': idToken}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_apiError(response));
    }
    final data = (jsonDecode(response.body)['data'] ?? {}) as Map<String, dynamic>;
    _authToken = data['accessToken']?.toString();
    _profileId = data['userId']?.toString();
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) await prefs.setString('fireman_access_token', _authToken!);
    if (_profileId != null) await prefs.setString('fireman_user_id', _profileId!);
    return data;
  }

  Future<void> changeUsername(String username, {String? idempotencyKey}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/users/me/username'),
      headers: _mutationHeaders(idempotencyKey),
      body: jsonEncode({'newUsername': username}),
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_apiError(response));
    }
  }

  Future<void> closeAccount({String? idempotencyKey}) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/v1/users/me'),
      headers: _mutationHeaders(idempotencyKey)).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    await signOut();
  }

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  String? get accessToken => _authToken;
  String? get currentUserId => _profileId;
  String get matchHubUrl => '$_baseUrl/hubs/match';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    'X-Character-Profile-Id': ?_profileId,
  };

  /// Mutation callers can retain and pass the same key when retrying a request.
  /// The backend scopes keys by authenticated user, method and route.
  String createIdempotencyKey() {
    final random = Random.secure();
    return List<int>.generate(24, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Map<String, String> _mutationHeaders([String? idempotencyKey]) => {
    ..._headers,
    'X-Idempotency-Key': idempotencyKey ?? createIdempotencyKey(),
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

  Future<bool> saveCharacterCustomization(CharacterModel character, {String? idempotencyKey}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/characters/customization'),
        headers: _mutationHeaders(idempotencyKey),
        body: jsonEncode({
          'gender': character.gender,
          'hat': character.equippedHat ?? 'Standart kask',
          'hatStyle': character.hatStyle,
          'suit': character.equippedSuit ?? 'Klasik itfaiye ceketi',
          'suitStyle': character.suitStyle,
          'accessory': character.equippedAccessory,
          'skinColorValue': character.skinColorValue,
          'suitColorValue': character.suitColorValue,
          'mask': character.equippedMask,
          'gloves': character.equippedGloves,
          'shoes': character.equippedShoes,
          'bomb': character.equippedBomb,
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

  Future<MatchModel> createMatch(String type, int maxPlayers, {required String roomName, String? password, String? idempotencyKey}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/matches'), headers: _mutationHeaders(idempotencyKey),
      body: jsonEncode({'type': type, 'maxPlayers': maxPlayers, 'roomName': roomName, 'password': password}))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    return MatchModel.fromJson((jsonDecode(response.body)['data'] ?? {}) as Map<String, dynamic>);
  }

  Future<List<MatchModel>> getOpenRooms() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/matches/rooms'), headers: _headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    final decoded = jsonDecode(response.body);
    final rooms = decoded['data'] as List? ?? [];
    return rooms.map((room) => MatchModel.fromJson(room)).toList();
  }

  Future<MatchModel> joinMatch(String matchId, {String? password, String? idempotencyKey}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/matches/join'), headers: _mutationHeaders(idempotencyKey),
      body: jsonEncode({'matchId': matchId, 'password': password})).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    return MatchModel.fromJson((jsonDecode(response.body)['data'] ?? {}) as Map<String, dynamic>);
  }

  Future<MatchModel> quickMatch({String? idempotencyKey}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/matches/quick'), headers: _mutationHeaders(idempotencyKey))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    return MatchModel.fromJson((jsonDecode(response.body)['data'] ?? {}) as Map<String, dynamic>);
  }

  Future<void> leaveMatch(String matchId, {String? idempotencyKey}) async {
    final response = await http.delete(Uri.parse('$_baseUrl/api/v1/matches/$matchId/leave'), headers: _mutationHeaders(idempotencyKey))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
  }

  String _apiError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message']?.toString() ?? data['title']?.toString() ?? 'Sunucu isteği başarısız (${response.statusCode}).';
    } catch (_) { return 'Sunucu isteği başarısız (${response.statusCode}).'; }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/social/friends'), headers: _headers).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    final data = jsonDecode(response.body)['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/notifications'), headers: _headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    final data = jsonDecode(response.body)['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> markNotificationRead(String id) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/notifications/$id/read'), headers: _mutationHeaders(), body: '{}')
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
  }

  Future<void> inviteFriendsToMatch(String matchId) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/matches/$matchId/invite-friends'), headers: _mutationHeaders(), body: '{}')
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
  }

  Future<void> addFriendByUsername(String username, {String? idempotencyKey}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/social/friends/request-by-username'), headers: _mutationHeaders(idempotencyKey),
      body: jsonEncode({'username': username})).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
  }

  Future<void> respondFriendRequest(String friendshipId, bool accept, {String? idempotencyKey}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/social/friends/respond'), headers: _mutationHeaders(idempotencyKey),
      body: jsonEncode({'friendshipId': friendshipId, 'accept': accept})).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
  }

  Future<List<Map<String, dynamic>>> getDirectMessages(String friendId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/social/friends/$friendId/messages'), headers: _headers).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
    final data = jsonDecode(response.body)['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> sendDirectMessage(String friendId, String message, {String? idempotencyKey}) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/social/friends/$friendId/messages'), headers: _mutationHeaders(idempotencyKey),
      body: jsonEncode({'message': message})).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(_apiError(response));
  }
}
