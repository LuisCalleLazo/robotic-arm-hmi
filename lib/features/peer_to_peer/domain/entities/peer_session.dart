import 'peer_client.dart';
import 'peer_connection_status.dart';
import 'peer_machine_type.dart';
import 'peer_permission.dart';
import 'peer_role.dart';

class PeerSession {
  const PeerSession({
    this.role,
    this.status = PeerConnectionStatus.disconnected,
    this.permission = PeerPermission.viewOnly,
    this.deviceName,
    this.machine,
    this.masterName,
    this.clientId,
    this.host,
    this.port,
    this.addresses = const [],
    this.clients = const [],
    this.error,
  });

  final PeerRole? role;
  final PeerConnectionStatus status;

  /// Permiso propio (esclavo). El maestro siempre tiene control total.
  final PeerPermission permission;

  /// Nombre de este dispositivo.
  final String? deviceName;

  /// Esclavo: máquina que representa este dispositivo.
  final PeerMachineType? machine;

  /// Esclavo: nombre del maestro al que está conectado.
  final String? masterName;
  final String? clientId;

  /// Esclavo: host del maestro.
  final String? host;
  final int? port;

  /// Maestro: IPs locales donde escucha.
  final List<String> addresses;

  /// Maestro: esclavos conectados (los esclavos nunca reciben esta lista).
  final List<PeerClient> clients;
  final String? error;

  bool get isMaster => role == PeerRole.master;
  bool get isSlave => role == PeerRole.slave;
  bool get isActive =>
      status == PeerConnectionStatus.listening ||
      status == PeerConnectionStatus.connected;

  PeerSession copyWith({
    PeerConnectionStatus? status,
    PeerPermission? permission,
    String? clientId,
    String? masterName,
    List<PeerClient>? clients,
    String? error,
    bool clearError = false,
  }) =>
      PeerSession(
        role: role,
        status: status ?? this.status,
        permission: permission ?? this.permission,
        deviceName: deviceName,
        machine: machine,
        masterName: masterName ?? this.masterName,
        clientId: clientId ?? this.clientId,
        host: host,
        port: port,
        addresses: addresses,
        clients: clients ?? this.clients,
        error: clearError ? null : (error ?? this.error),
      );
}
