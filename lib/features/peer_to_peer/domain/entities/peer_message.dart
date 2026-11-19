enum PeerMessageType {
  welcome,
  permission,
  command,
  configuration,
  telemetry,
  kicked,
  error;

  static PeerMessageType? tryParse(String? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

class PeerMessage {
  PeerMessage({
    required this.type,
    this.payload = const {},
    this.senderId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final PeerMessageType type;
  final Map<String, dynamic> payload;

  /// En el maestro: id del esclavo que envió el mensaje.
  final String? senderId;
  final DateTime timestamp;
}
