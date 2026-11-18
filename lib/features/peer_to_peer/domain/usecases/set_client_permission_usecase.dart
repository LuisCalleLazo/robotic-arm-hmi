import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class SetClientPermissionUseCase {
  const SetClientPermissionUseCase(this._repo);
  final PeerRepository _repo;

  Future<void> call(String clientId, PeerPermission permission) =>
      _repo.setClientPermission(clientId, permission);
}
