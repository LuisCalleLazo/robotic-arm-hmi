import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/peer_entities.dart';
import '../../domain/usecases/connect_as_slave_usecase.dart';
import '../../domain/usecases/disconnect_peer_usecase.dart';
import '../../domain/usecases/discover_masters_usecase.dart';
import '../../domain/usecases/kick_client_usecase.dart';
import '../../domain/usecases/send_peer_message_usecase.dart';
import '../../domain/usecases/set_client_permission_usecase.dart';
import '../../domain/usecases/start_master_usecase.dart';
import '../../domain/usecases/verify_master_password_usecase.dart';
import '../../domain/usecases/watch_peer_session_usecase.dart';

class PeerState {
  const PeerState(this.session);
  final PeerSession session;
}

class PeerCubit extends Cubit<PeerState> {
  PeerCubit({
    required WatchPeerSessionUseCase watchSession,
    required VerifyMasterPasswordUseCase verifyMasterPassword,
    required StartMasterUseCase startMaster,
    required ConnectAsSlaveUseCase connectAsSlave,
    required DiscoverMastersUseCase discoverMasters,
    required DisconnectPeerUseCase disconnect,
    required SendPeerMessageUseCase sendMessage,
    required SetClientPermissionUseCase setClientPermission,
    required KickClientUseCase kickClient,
    required this.isMasterSupported,
    required this.isDiscoverySupported,
  })  : _verifyMasterPassword = verifyMasterPassword,
        _startMaster = startMaster,
        _connectAsSlave = connectAsSlave,
        _discoverMasters = discoverMasters,
        _disconnect = disconnect,
        _sendMessage = sendMessage,
        _setClientPermission = setClientPermission,
        _kickClient = kickClient,
        super(PeerState(watchSession.current)) {
    _sub = watchSession().listen((s) => emit(PeerState(s)));
  }

  final bool isMasterSupported;
  final bool isDiscoverySupported;
  final VerifyMasterPasswordUseCase _verifyMasterPassword;
  final StartMasterUseCase _startMaster;
  final ConnectAsSlaveUseCase _connectAsSlave;
  final DiscoverMastersUseCase _discoverMasters;
  final DisconnectPeerUseCase _disconnect;
  final SendPeerMessageUseCase _sendMessage;
  final SetClientPermissionUseCase _setClientPermission;
  final KickClientUseCase _kickClient;
  late final StreamSubscription<PeerSession> _sub;

  bool verifyMasterPassword(String password) => _verifyMasterPassword(password);

  Future<void> startMaster({
    required String password,
    required String name,
    int port = PeerConfig.defaultPort,
    PeerPermission defaultPermission = PeerPermission.viewOnly,
  }) =>
      _startMaster(
        password: password,
        name: name,
        port: port,
        defaultPermission: defaultPermission,
      );

  Future<void> connectSlave({
    required String host,
    int port = PeerConfig.defaultPort,
    required String name,
    required PeerMachineType machine,
  }) =>
      _connectAsSlave(host: host, port: port, name: name, machine: machine);

  Stream<PeerMasterInfo> discoverMasters({
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _discoverMasters(timeout: timeout);

  Future<void> disconnect() => _disconnect();

  Future<void> setPermission(String clientId, PeerPermission permission) =>
      _setClientPermission(clientId, permission);

  Future<void> kick(String clientId) => _kickClient(clientId);

  /// Esclavo → maestro. `false` si no hay permiso o no hay conexión.
  Future<bool> sendCommand(Map<String, dynamic> payload) =>
      _trySend(PeerMessage(type: PeerMessageType.command, payload: payload));

  /// Maestro → esclavos.
  Future<bool> sendTelemetry(Map<String, dynamic> payload) =>
      _trySend(PeerMessage(type: PeerMessageType.telemetry, payload: payload));

  Future<bool> _trySend(PeerMessage m) async {
    try {
      await _sendMessage(m);
      return true;
    } on PeerException {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
