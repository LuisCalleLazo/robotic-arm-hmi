import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class DiscoverMastersUseCase {
  const DiscoverMastersUseCase(this._repo);
  final PeerRepository _repo;

  Stream<PeerMasterInfo> call({
    Duration timeout = const Duration(seconds: 3),
  }) =>
      _repo.discoverMasters(timeout: timeout);
}
