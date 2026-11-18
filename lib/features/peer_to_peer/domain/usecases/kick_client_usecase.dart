import '../repositories/peer_repository.dart';

class KickClientUseCase {
  const KickClientUseCase(this._repo);
  final PeerRepository _repo;

  Future<void> call(String clientId) => _repo.kickClient(clientId);
}
