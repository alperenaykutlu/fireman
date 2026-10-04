class MissionModel {
  final String id;
  final String title;
  final String description;
  final int targetScore;
  final int rewardCoins;
  final int rewardXp;
  final bool isCompleted;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetScore,
    required this.rewardCoins,
    required this.rewardXp,
    this.isCompleted = false,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetScore: json['targetScore'] ?? 1000,
      rewardCoins: json['baseRewardCoins'] ?? 100,
      rewardXp: json['baseRewardXp'] ?? 200,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
