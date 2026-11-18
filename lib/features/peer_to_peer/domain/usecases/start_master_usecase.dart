import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class StartMasterUseCase {
  const StartMasterUseCase(this._repo);
  final PeerRepository _repo;

  Future<void> call({
    required String password,
    required String name,
    int port = PeerConfig.defaultPort,
    PeerPermission defaultPermission = PeerPermission.viewOnly,
  }) =>
      _repo.startMaster(
        password: password,
        name: name,
        port: port,
        defaultPermission: defaultPermission,
      );
}
