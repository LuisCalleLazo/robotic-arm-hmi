import 'dart:convert';

import '../../domain/entities/peer_entities.dart';

class PeerMessageModel {
  const PeerMessageModel._();

  static String encode(PeerMessage m) => jsonEncode({
        'type': m.type.name,
        'payload': m.payload,
        'senderId': m.senderId,
        'ts': m.timestamp.millisecondsSinceEpoch,
      });

  /// Devuelve `null` si el mensaje es inválido.
  /// [senderId] (si se pasa) sustituye al que venga en el JSON para evitar suplantación.
  static PeerMessage? decode(String raw, {String? senderId}) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final type = PeerMessageType.tryParse(map['type'] as String?);
      if (type == null) return null;
      final payload = map['payload'];
      final ts = (map['ts'] as num?)?.toInt();
      return PeerMessage(
        type: type,
        payload: payload is Map ? Map<String, dynamic>.from(payload) : const {},
        senderId: senderId ?? map['senderId'] as String?,
        timestamp: ts == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      return null;
    }
  }
}
