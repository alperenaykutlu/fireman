class Vector2 {
  final double x;
  final double y;
  const Vector2(this.x, this.y);
}

/// Client prediction input packet
class ClientPredictionInput {
  final int seq;
  final int dx;
  final int dy;
  final bool placeBomb;

  ClientPredictionInput({
    required this.seq,
    required this.dx,
    required this.dy,
    required this.placeBomb,
  });
}

/// Manages client-side movement prediction and server reconciliation
class PredictionReconciliationEngine {
  static const int subUnitsPerTile = 256;
  static const int playerMoveSpeed = 8; // subunits per tick

  // Predicted state on client
  int predictedSubX = 256; // tile 1
  int predictedSubY = 256; // tile 1
  int nextSeq = 1;

  // History of pending inputs not yet acknowledged by server
  final List<ClientPredictionInput> _pendingInputs = [];

  /// Called when player touches D-Pad / Joystick
  ClientPredictionInput processInput(int dx, int dy, bool placeBomb) {
    final input = ClientPredictionInput(
      seq: nextSeq++,
      dx: dx,
      dy: dy,
      placeBomb: placeBomb,
    );

    _pendingInputs.add(input);

    // Apply immediate local prediction
    predictedSubX += input.dx * playerMoveSpeed;
    predictedSubY += input.dy * playerMoveSpeed;

    return input;
  }

  /// Called when an authoritative WorldSnapshot arrives from SignalR
  void reconcileWithServer(int serverSubX, int serverSubY, int lastAckedSeq) {
    // 1. Remove all inputs acknowledged by the server
    _pendingInputs.removeWhere((input) => input.seq <= lastAckedSeq);

    // 2. Reset predicted position to authoritative server position
    predictedSubX = serverSubX;
    predictedSubY = serverSubY;

    // 3. Re-apply all pending (unacknowledged) inputs on top of server state
    for (final input in _pendingInputs) {
      predictedSubX += input.dx * playerMoveSpeed;
      predictedSubY += input.dy * playerMoveSpeed;
    }
  }

  /// Current display position in grid tile coordinates (floating point for smooth rendering)
  double get displayTileX => predictedSubX / subUnitsPerTile;
  double get displayTileY => predictedSubY / subUnitsPerTile;
}
