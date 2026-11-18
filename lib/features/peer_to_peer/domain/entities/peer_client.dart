import 'peer_machine_type.dart';
import 'peer_permission.dart';

/// Esclavo conectado al maestro (una máquina).
class PeerClient {
  const PeerClient({
    required this.id,
    required this.name,
    required this.machine,
    required this.permission,
    required this.connectedAt,
  });

  final String id;
  final String name;
  final PeerMachineType machine;
  final PeerPermission permission;
  final DateTime connectedAt;

  PeerClient copyWith({PeerPermission? permission}) => PeerClient(
        id: id,
        name: name,
        machine: machine,
        permission: permission ?? this.permission,
        connectedAt: connectedAt,
      );
}
