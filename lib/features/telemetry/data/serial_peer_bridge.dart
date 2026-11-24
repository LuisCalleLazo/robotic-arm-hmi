import 'dart:async';

import '../../peer_to_peer/domain/entities/peer_entities.dart';
import '../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../../serial_connection/domain/repositories/serial_repository.dart';
import '../../serial_connection/presentation/bloc/connection_bloc.dart';
import 'consecutive_serial_line_filter.dart';
import '../presentation/cubit/telemetry_cubit.dart';

/// Uniforma el transporte de líneas seriales entre maestro y esclavos.
class SerialPeerBridge {
  SerialPeerBridge({
    required this._serial,
    required this._peer,
    required this._telemetry,
    required this._connection,
  }) {
    _serialSub = _serial.lines.listen(_onSerialLine);
    _peerSub = _peer.messages.listen(_onPeerMessage);
    _telemetrySub = _telemetry.lineEvents.listen(_onTelemetryLine);
    _sessionSub = _peer.sessionStream.listen((_) => _serialLineFilter.reset());
  }

  final SerialRepository _serial;
  final PeerRepository _peer;
  final TelemetryCubit _telemetry;
  final ConnectionBloc _connection;
  late final StreamSubscription<String> _serialSub;
  late final StreamSubscription<PeerMessage> _peerSub;
  late final StreamSubscription<TelemetryLogEntry> _telemetrySub;
  late final StreamSubscription<PeerSession> _sessionSub;
  final _serialLineFilter = ConsecutiveSerialLineFilter();

  void _onSerialLine(String line) {
    _sendSerialLine(line);
  }

  void _onTelemetryLine(TelemetryLogEntry entry) {
    if (entry.source == TelemetrySource.simulated) {
      _sendSerialLine(entry.line);
    }
  }

  void _sendSerialLine(String line) {
    final normalized = line.trim();
    if (!_peer.session.isActive ||
        !_serialLineFilter.accept(
          normalized,
          allowRepeated: _isSensorSignal(normalized),
        )) {
      return;
    }
    unawaited(
      _peer.send(
        PeerMessage(
          type: PeerMessageType.telemetry,
          payload: {'kind': 'serial_line', 'line': normalized},
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
    final normalized = line.trim();
    if (!_serialLineFilter.accept(
      normalized,
      allowRepeated: _isSensorSignal(normalized),
    )) {
      return;
    }
    _telemetry.ingestPeerLine(normalized);
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
            payload: {'kind': 'serial_line', 'line': normalized},
          ),
        ),
      );
    }
  }

  bool _isSensorSignal(String line) =>
      RegExp(r'^[A-Z][A-Z0-9_-]*[01]$', caseSensitive: false).hasMatch(line);

  Future<void> _forwardCommand(PeerMessage message) async {
    final senderId = message.senderId;
    final line = message.payload['line'];
    if (!_peer.session.isMaster ||
        senderId == null ||
        line is! String ||
        line.trim().isEmpty) {
      return;
    }
    if (_telemetry.state.isSimulating) {
      _telemetry.recordSent(line.trim());
      _telemetry.sendSimulatedCommand(line.trim());
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
    await _telemetrySub.cancel();
    await _sessionSub.cancel();
  }
}
