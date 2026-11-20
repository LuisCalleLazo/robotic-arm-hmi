import 'dart:async';

import '../../peer_to_peer/domain/entities/peer_entities.dart';
import '../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../../serial_connection/domain/repositories/serial_repository.dart';
import '../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../presentation/cubit/telemetry_cubit.dart';

/// Uniforma el transporte de líneas seriales entre maestro y esclavos.
class SerialPeerBridge {
  SerialPeerBridge({
    required SerialRepository serial,
    required PeerRepository peer,
    required TelemetryCubit telemetry,
    required ConnectionBloc connection,
  }) : _serial = serial,
       _peer = peer,
       _telemetry = telemetry,
       _connection = connection {
    _serialSub = _serial.lines.listen(_onSerialLine);
    _peerSub = _peer.messages.listen(_onPeerMessage);
  }

  final SerialRepository _serial;
  final PeerRepository _peer;
  final TelemetryCubit _telemetry;
  final ConnectionBloc _connection;
  late final StreamSubscription<String> _serialSub;
  late final StreamSubscription<PeerMessage> _peerSub;

  void _onSerialLine(String line) {
    if (!_peer.session.isActive) return;
    unawaited(
      _peer.send(
        PeerMessage(
          type: PeerMessageType.telemetry,
          payload: {'kind': 'serial_line', 'line': line},
        ),
      ),
    );
  }

  void _onPeerMessage(PeerMessage message) {
    if (message.type == PeerMessageType.command &&
        message.payload['kind'] == 'serial_command') {
      unawaited(_forwardCommand(message));
      return;
    }
    if (message.type == PeerMessageType.error &&
        message.payload['kind'] == 'serial_command_error') {
      final error = message.payload['message'];
      _telemetry.ingestPeerLine(
        'ERROR,${error ?? 'No se pudo enviar el comando.'}',
      );
      return;
    }
    if (message.type != PeerMessageType.telemetry) {
      return;
    }
    final line = message.payload['line'];
    if (line is! String) return;
    final kind = message.payload['kind'];
    if (kind == 'serial_sent') {
      _telemetry.ingestPeerSentLine(line);
      return;
    }
    if (kind != 'serial_line') return;
    _telemetry.ingestPeerLine(line);
    final session = _peer.session;
    final senderId = message.senderId;
    if (!session.isMaster || senderId == null) return;
    for (final client in session.clients) {
      if (client.id == senderId) continue;
      unawaited(
        _peer.sendToClient(
          client.id,
          PeerMessage(
            type: PeerMessageType.telemetry,
            payload: {'kind': 'serial_line', 'line': line},
          ),
        ),
      );
    }
  }

  Future<void> _forwardCommand(PeerMessage message) async {
    final senderId = message.senderId;
    final line = message.payload['line'];
    if (!_peer.session.isMaster ||
        senderId == null ||
        line is! String ||
        line.trim().isEmpty) {
      return;
    }
    if (!_connection.state.isConnected) {
      await _peer.sendToClient(
        senderId,
        PeerMessage(
          type: PeerMessageType.error,
          payload: {
            'kind': 'serial_command_error',
            'message': 'El maestro no tiene un puerto serial conectado.',
          },
        ),
      );
      return;
    }
    _connection.add(CommandSent(line.trim(), sourceClientId: senderId));
  }

  Future<void> dispose() async {
    await _serialSub.cancel();
    await _peerSub.cancel();
  }
}
