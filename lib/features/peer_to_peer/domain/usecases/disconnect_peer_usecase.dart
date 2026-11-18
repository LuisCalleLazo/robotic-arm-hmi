import '../repositories/peer_repository.dart';

class DisconnectPeerUseCase {
  const DisconnectPeerUseCase(this._repo);
  final PeerRepository _repo;

  Future<void> call() => _repo.disconnect();
}
