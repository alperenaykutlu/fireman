class MatchModel {
  final String id;
  final String type;
  final String status;
  final int maxPlayers;
  final int currentPlayers;
  final String roomName;
  final bool hasPassword;

  MatchModel({
    required this.id,
    required this.type,
    required this.status,
    required this.maxPlayers,
    required this.currentPlayers,
    this.roomName = '',
    this.hasPassword = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final players = json['players'] as List? ?? [];
    return MatchModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'CoopRescue',
      status: json['status'] ?? 'Lobby',
      maxPlayers: json['maxPlayers'] ?? 4,
      currentPlayers: players.length,
      roomName: json['roomName'] ?? '',
      hasPassword: json['hasPassword'] ?? false,
    );
  }
}
