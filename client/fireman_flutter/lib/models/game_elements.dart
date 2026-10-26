import 'package:flutter/material.dart';

enum CellType {
  empty,
  wall,         // Kırılmaz bej/taş sütun blok
  barrel,       // Patlatılabilir kırmızı/bordo varil
  suddenDeath,  // Süre bitince etraftan saran ölümcül bloklar
}

enum PowerUpType {
  dynamiteRange, // Şimşek / fitil: Dinamit patlama menzili +1
  rollerSkate,   // Paten / ayakkabı: Hareket hızı artışı
  extraDynamite, // Dinamit: +1 dinamit koyma hakkı
  shield,        // Can yenileme: +10 HP
  bombGlove,     // Eldiven: dinamitleri itip hareket ettirebilme
}

class Dynamite {
  int x;
  int y;
  final int range;
  final int ownerId; // 0: Oyuncu, 1..N: Botlar
  double timeLeft;   // Patlama süresi (saniye)
  int slideDx;       // Kayma yönü X (-1, 0, 1)
  int slideDy;       // Kayma yönü Y (-1, 0, 1)
  double slideCooldown;

  Dynamite({
    required this.x,
    required this.y,
    required this.range,
    this.ownerId = 0,
    this.timeLeft = 2.4,
    this.slideDx = 0,
    this.slideDy = 0,
    this.slideCooldown = 0.0,
  });
}

class ExplosionTile {
  final int x;
  final int y;
  double duration;
  final bool isCenter;

  ExplosionTile({
    required this.x,
    required this.y,
    this.duration = 0.35, // Daha akıcı patlama süresi
    this.isCenter = false,
  });
}

class PowerUpItem {
  final int x;
  final int y;
  final PowerUpType type;

  PowerUpItem({
    required this.x,
    required this.y,
    required this.type,
  });
}

enum PlayerStatus {
  alive,
  eliminated,
}

class ArenaFighter {
  final int id;
  String name;
  Color hatColor;
  Color bodyColor;
  Color skinColor;
  bool isFemale;
  int hatStyle;
  int suitStyle;
  int accessoryStyle;
  int maskStyle;
  int score;
  final bool isHuman;
  final String? userId;
  int x;
  int y;
  int health;
  int wins;
  int maxDynamites;
  int dynamiteRange;
  double speed;
  double moveCooldown;
  PlayerStatus status;
  bool isDisconnected;
  bool canMoveDynamite;

  ArenaFighter({
    required this.id,
    required this.name,
    required this.hatColor,
    required this.bodyColor,
    this.skinColor = const Color(0xFFFFD1A4),
    this.isFemale = false,
    this.hatStyle = 0,
    this.suitStyle = 0,
    this.accessoryStyle = 0,
    this.maskStyle = -1,
    this.score = 0,
    this.isHuman = false,
    this.userId,
    required this.x,
    required this.y,
    this.health = 100,
    this.wins = 0,
    this.maxDynamites = 1,
    this.dynamiteRange = 1,
    this.speed = 0.7,
    this.moveCooldown = 0.0,
    this.status = PlayerStatus.alive,
    this.isDisconnected = false,
    this.canMoveDynamite = false,
  });
}
