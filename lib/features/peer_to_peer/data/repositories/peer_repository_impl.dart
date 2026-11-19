import 'dart:async';

import '../../domain/entities/peer_entities.dart';
import '../../domain/repositories/peer_repository.dart';
import '../datasources/peer_client_datasource.dart';
import '../datasources/peer_discovery_datasource.dart';
import '../datasources/peer_server_datasource.dart';
import '../datasources/peer_server_event.dart';
import '../model/peer_message_model.dart';

class PeerRepositoryImpl implements PeerRepository {
  PeerRepositoryImpl({
    required PeerServerDataSource server,
    required PeerClientDataSource client,
    required PeerDiscoveryDataSource discovery,
  }) : _server = server,
       _client = client,
       _discovery = discovery;

  final PeerServerDataSource _server;
  final PeerClientDataSource _client;
  final PeerDiscoveryDataSource _discovery;

  final _sessionCtrl = StreamController<PeerSession>.broadcast();
  final _messagesCtrl = StreamController<PeerMessage>.broadcast();
  final _clients = <String, PeerClient>{};

  PeerSession _session = const PeerSession();
  PeerPermission _defaultPermission = PeerPermission.viewOnly;
  Completer<void>? _welcome;
  int _gen = 0;

  StreamSubscription<PeerServerEvent>? _serverSub;
  StreamSubscription<String>? _clientMsgSub;
  StreamSubscription<void>? _clientCloseSub;

  @override
  bool get isMasterSupported => _server.isSupported;

  @override
  bool get isDiscoverySupported => _discovery.isSupported;

  @override
  PeerSession get session => _session;

  @override
  Stream<PeerSession> get sessionStream => _sessionCtrl.stream;

  @override
  Stream<PeerMessage> get messages => _messagesCtrl.stream;

  void _emit(PeerSession s) {
    _session = s;
    _sessionCtrl.add(s);
  }

  String _cleanName(String raw, String fallback) {
    final t = raw.trim();
    if (t.isEmpty) return fallback;
    return t.length > 32 ? t.substring(0, 32) : t;
  }

  @override
  bool verifyMasterPassword(String password) =>
      password == PeerConfig.masterPassword;

  @override
  Stream<PeerMasterInfo> discoverMasters({
    Duration timeout = const Duration(seconds: 3),
  }) => _discovery.discover(timeout: timeout);

  // ------------------------------------------------------------ MAESTRO

  @override
  Future<void> startMaster({
    required String password,
    required String name,
    int port = PeerConfig.defaultPort,
    PeerPermission defaultPermission = PeerPermission.viewOnly,
  }) async {
    await _teardown();
    if (!isMasterSupported) {
      _emit(
        const PeerSession(
          role: PeerRole.master,
          status: PeerConnectionStatus.error,
          error: 'El modo maestro no está disponible en web.',
        ),
      );
      return;
    }
    if (!verifyMasterPassword(password)) {
      _emit(
        const PeerSession(
          role: PeerRole.master,
          status: PeerConnectionStatus.error,
          error: 'Contraseña incorrecta.',
        ),
      );
      return;
    }
    final masterName = _cleanName(name, 'Maestro');
    _defaultPermission = defaultPermission;
    _emit(
      PeerSession(
        role: PeerRole.master,
        status: PeerConnectionStatus.connecting,
        deviceName: masterName,
      ),
    );
    try {
      _serverSub = _server.events.listen(_onServerEvent);
      final bound = await _server.start(port);
      final addresses = await _server.localAddresses();
      try {
        await _discovery.startResponder(name: masterName, wsPort: bound);
      } catch (_) {
        // La búsqueda por nombre es opcional: el maestro sigue funcionando por IP.
      }
      _emit(
        PeerSession(
          role: PeerRole.master,
          status: PeerConnectionStatus.listening,
          deviceName: masterName,
          port: bound,
          addresses: addresses,
        ),
      );
    } catch (e) {
      await _teardown();
      _emit(
        PeerSession(
          role: PeerRole.master,
          status: PeerConnectionStatus.error,
          deviceName: masterName,
          port: port,
          error: 'No se pudo abrir el puerto $port: $e',
        ),
      );
    }
  }

  void _onServerEvent(PeerServerEvent event) {
    switch (event) {
      case ClientConnected(:final id, :final name, :final machine):
        final type = PeerMachineType.tryParse(machine);
        if (type == null) {
          _sendTo(
            id,
            PeerMessage(
              type: PeerMessageType.error,
              payload: {
                'code': 'machine_required',
                'message': 'Debes indicar el tipo de máquina.',
              },
            ),
          );
          _server.kick(id);
          return;
        }
        final client = PeerClient(
          id: id,
          name: name,
          machine: type,
          permission: _defaultPermission,
          connectedAt: DateTime.now(),
        );
        _clients[id] = client;
        _sendTo(
          id,
          PeerMessage(
            type: PeerMessageType.welcome,
            payload: {
              'clientId': id,
              'permission': client.permission.name,
              'masterName': _session.deviceName,
            },
          ),
        );
        _updateClients();
      case ClientDisconnected(:final id):
        if (_clients.remove(id) != null) _updateClients();
      case ClientMessage(:final id, :final raw):
        _onClientMessage(id, raw);
    }
  }

  void _onClientMessage(String id, String raw) {
    final client = _clients[id];
    final msg = PeerMessageModel.decode(raw, senderId: id);
    if (client == null || msg == null) return;
    if (msg.type == PeerMessageType.configuration) {
      _messagesCtrl.add(msg);
      return;
    }
    if (msg.type == PeerMessageType.telemetry) {
      _messagesCtrl.add(msg);
      return;
    }
    if (msg.type != PeerMessageType.command) return;
    if (client.permission.canSendCommands) {
      _messagesCtrl.add(msg);
    } else {
      _sendTo(
        id,
        PeerMessage(
          type: PeerMessageType.error,
          payload: {
            'code': 'permission_denied',
            'message': 'No tienes permiso de control.',
          },
        ),
      );
    }
  }

  /// La lista de esclavos y sus máquinas solo la ve el maestro: no se difunde.
  void _updateClients() =>
      _emit(_session.copyWith(clients: _clients.values.toList()));

  void _sendTo(String id, PeerMessage m) =>
      _server.sendTo(id, PeerMessageModel.encode(m));

  @override
  Future<void> sendToClient(String clientId, PeerMessage message) async {
    if (!_session.isMaster || !_clients.containsKey(clientId)) {
      throw const PeerException('El cliente no está conectado al maestro.');
    }
    _sendTo(clientId, message);
  }

  @override
  Future<void> setClientPermission(
    String clientId,
    PeerPermission permission,
  ) async {
    final c = _clients[clientId];
    if (c == null || !_session.isMaster) return;
    _clients[clientId] = c.copyWith(permission: permission);
    _sendTo(
      clientId,
      PeerMessage(
        type: PeerMessageType.permission,
        payload: {'permission': permission.name},
      ),
    );
    _updateClients();
  }

  @override
  Future<void> kickClient(String clientId) async {
    if (!_session.isMaster || !_clients.containsKey(clientId)) return;
    _sendTo(clientId, PeerMessage(type: PeerMessageType.kicked));
    _server.kick(clientId);
  }

  // ------------------------------------------------------------ ESCLAVO

  @override
  Future<void> connectAsSlave({
    required String host,
    int port = PeerConfig.defaultPort,
    required String name,
    required PeerMachineType machine,
  }) async {
    await _teardown();
    final gen = _gen;
    final deviceName = _cleanName(name, 'Esclavo');
    _emit(
      PeerSession(
        role: PeerRole.slave,
        status: PeerConnectionStatus.connecting,
        deviceName: deviceName,
        machine: machine,
        host: host,
        port: port,
      ),
    );
    final welcome = Completer<void>();
    welcome.future.ignore();
    _welcome = welcome;
    try {
      _clientMsgSub = _client.messages.listen(_onMasterMessage);
      _clientCloseSub = _client.onClosed.listen((_) => _onSocketClosed());
      await _client.connect(
        Uri(
          scheme: 'ws',
          host: host,
          port: port,
          path: '/ws',
          queryParameters: {'name': deviceName, 'machine': machine.id},
        ),
      );
      await welcome.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      if (gen != _gen) return; // cancelado por el usuario
      await _teardown();
      _emit(
        PeerSession(
          role: PeerRole.slave,
          status: PeerConnectionStatus.error,
          deviceName: deviceName,
          machine: machine,
          host: host,
          port: port,
          error: e is PeerException
              ? e.message
              : 'No se pudo conectar a $host:$port',
        ),
      );
    }
  }

  void _onMasterMessage(String raw) {
    final msg = PeerMessageModel.decode(raw);
    if (msg == null) return;
    switch (msg.type) {
      case PeerMessageType.welcome:
        _emit(
          _session.copyWith(
            status: PeerConnectionStatus.connected,
            clientId: msg.payload['clientId'] as String?,
            masterName: msg.payload['masterName'] as String?,
            permission: PeerPermission.fromName(
              msg.payload['permission'] as String?,
            ),
            clearError: true,
          ),
        );
        final w = _welcome;
        if (w != null && !w.isCompleted) w.complete();
      case PeerMessageType.permission:
        _emit(
          _session.copyWith(
            permission: PeerPermission.fromName(
              msg.payload['permission'] as String?,
            ),
          ),
        );
      case PeerMessageType.kicked:
        _emit(
          _session.copyWith(
            status: PeerConnectionStatus.error,
            error: 'El maestro te expulsó de la sesión.',
          ),
        );
      default:
        _messagesCtrl.add(msg);
    }
  }

  void _onSocketClosed() {
    final w = _welcome;
    if (w != null && !w.isCompleted) {
      w.completeError(const PeerException('El maestro rechazó la conexión.'));
      return;
    }
    if (_session.isSlave && _session.status == PeerConnectionStatus.connected) {
      _emit(
        _session.copyWith(
          status: PeerConnectionStatus.disconnected,
          error: 'Se perdió la conexión con el maestro.',
        ),
      );
    }
  }

  // ------------------------------------------------------------ COMÚN

  @override
  Future<void> send(PeerMessage message) async {
    if (_session.isMaster &&
        _session.status == PeerConnectionStatus.listening) {
      _server.broadcast(PeerMessageModel.encode(message));
      return;
    }
    if (_session.isSlave && _session.status == PeerConnectionStatus.connected) {
      if (message.type == PeerMessageType.command &&
          !_session.permission.canSendCommands) {
        throw const PeerPermissionException();
      }
      _client.send(PeerMessageModel.encode(message));
      return;
    }
    throw const PeerException('No hay una conexión activa.');
  }

  Future<void> _cancelClientSubs() async {
    await _clientMsgSub?.cancel();
    await _clientCloseSub?.cancel();
    _clientMsgSub = null;
    _clientCloseSub = null;
  }

  Future<void> _teardown() async {
    _gen++;
    await _serverSub?.cancel();
    _serverSub = null;
    await _cancelClientSubs();
    _welcome = null;
    _clients.clear();
    await _server.stop();
    await _discovery.stopResponder();
    await _client.disconnect();
  }

  @override
  Future<void> disconnect() async {
    await _teardown();
    _emit(const PeerSession());
  }
}
