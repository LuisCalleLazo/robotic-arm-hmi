import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class ConnectAsSlaveUseCase {
  const ConnectAsSlaveUseCase(this._repo);
  final PeerRepository _repo;

  Future<void> call({
    required String host,
    int port = PeerConfig.defaultPort,
    required String name,
    required PeerMachineType machine,
  }) =>
      _repo.connectAsSlave(host: host, port: port, name: name, machine: machine);
}
