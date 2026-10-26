class CharacterModel {
  final String id;
  final String name;
  final int level;
  final int experience;
  final String? equippedHat;
  final String? equippedSuit;
  final String gender;
  final String equippedAccessory;
  final int hatStyle;
  final int suitStyle;
  final int skinColorValue;
  final int suitColorValue;
  final String equippedMask;
  final String equippedGloves;
  final String equippedShoes;
  final String equippedBomb;

  CharacterModel({
    required this.id,
    required this.name,
    required this.level,
    required this.experience,
    this.equippedHat,
    this.equippedSuit,
    this.gender = 'male',
    this.equippedAccessory = 'Standart Aksesuar',
    this.hatStyle = 0,
    this.suitStyle = 0,
    this.skinColorValue = 0xFFFFD1A4,
    this.suitColorValue = 0xFFDC2626,
    this.equippedMask = 'Standart maske',
    this.equippedGloves = 'Standart eldiven',
    this.equippedShoes = 'Standart ayakkabı',
    this.equippedBomb = 'Klasik dinamit',
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'İtfaiyeci',
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      equippedHat: json['equippedHat'],
      equippedSuit: json['equippedSuit'],
      gender: json['gender'] ?? 'male',
      equippedAccessory: json['equippedAccessory'] ?? 'Standart Aksesuar',
      hatStyle: json['hatStyle'] ?? 0,
      suitStyle: json['suitStyle'] ?? 0,
      skinColorValue: json['skinColorValue'] ?? 0xFFFFD1A4,
      suitColorValue: json['suitColorValue'] ?? 0xFFDC2626,
      equippedMask: json['mask'] ?? 'Standart maske',
      equippedGloves: json['gloves'] ?? 'Standart eldiven',
      equippedShoes: json['shoes'] ?? 'Standart ayakkabı',
      equippedBomb: json['bomb'] ?? 'Klasik dinamit',
    );
  }
}
