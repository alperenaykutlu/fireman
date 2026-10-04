class CharacterModel {
  final String id;
  final String name;
  final int level;
  final int experience;
  final String? equippedHat;
  final String? equippedSuit;

  CharacterModel({
    required this.id,
    required this.name,
    required this.level,
    required this.experience,
    this.equippedHat,
    this.equippedSuit,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'İtfaiyeci',
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      equippedHat: json['equippedHat'],
      equippedSuit: json['equippedSuit'],
    );
  }
}
