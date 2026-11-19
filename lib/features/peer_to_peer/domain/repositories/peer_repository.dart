import '../entities/peer_entities.dart';

abstract class PeerRepository {
  /// `false` en web: ahí solo se puede ser esclavo.
  bool get isMasterSupported;

  /// `false` en web: ahí el maestro se escribe por IP.
  bool get isDiscoverySupported;

  PeerSession get session;
  Stream<PeerSession> get sessionStream;

  /// Maestro: comandos recibidos de esclavos con permiso.
  /// Esclavo: telemetría y mensajes enviados por el maestro.
  Stream<PeerMessage> get messages;

  bool verifyMasterPassword(String password);

  /// Exige la contraseña de maestro; si es incorrecta la sesión queda en error.
  Future<void> startMaster({
    required String password,
    required String name,
    int port = PeerConfig.defaultPort,
    PeerPermission defaultPermission = PeerPermission.viewOnly,
  });

  Future<void> connectAsSlave({
    required String host,
    int port = PeerConfig.defaultPort,
    required String name,
    required PeerMachineType machine,
  });

  /// Busca maestros en la red local y los va emitiendo por nombre/IP.
  Stream<PeerMasterInfo> discoverMasters({
    Duration timeout = const Duration(seconds: 3),
  });

  /// Maestro: difunde a todos los esclavos.
  /// Esclavo: envía al maestro (los `command` requieren [PeerPermission.control]).
  Future<void> send(PeerMessage message);

  /// Maestro: envía un mensaje de configuración al esclavo indicado.
  Future<void> sendToClient(String clientId, PeerMessage message);

  Future<void> setClientPermission(String clientId, PeerPermission permission);
  Future<void> kickClient(String clientId);
  Future<void> disconnect();
}
