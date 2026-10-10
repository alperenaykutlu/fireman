import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String username;
  int totalScore;
  int gamesPlayed;
  int gamesWon;
  int rank;

  UserProfile({
    required this.username,
    this.totalScore = 1250,
    this.gamesPlayed = 8,
    this.gamesWon = 5,
    this.rank = 14,
  });

  static const String keyUsername = 'fireman_username';
  static const String keyScore = 'fireman_score';
  static const String keyPlayed = 'fireman_played';
  static const String keyWon = 'fireman_won';
  static const String keyRank = 'fireman_rank';
  static const String keyHasCompletedOnboarding = 'fireman_onboarding_done';

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyHasCompletedOnboarding) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasCompletedOnboarding, true);
  }

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(keyUsername) ?? '';
    final score = prefs.getInt(keyScore) ?? 1250;
    final played = prefs.getInt(keyPlayed) ?? 8;
    final won = prefs.getInt(keyWon) ?? 5;
    final rank = prefs.getInt(keyRank) ?? 14;

    return UserProfile(
      username: username,
      totalScore: score,
      gamesPlayed: played,
      gamesWon: won,
      rank: rank,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUsername, username);
    await prefs.setInt(keyScore, totalScore);
    await prefs.setInt(keyPlayed, gamesPlayed);
    await prefs.setInt(keyWon, gamesWon);
    await prefs.setInt(keyRank, rank);
  }
}
