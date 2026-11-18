import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class WatchPeerSessionUseCase {
  const WatchPeerSessionUseCase(this._repo);
  final PeerRepository _repo;

  PeerSession get current => _repo.session;
  Stream<PeerSession> call() => _repo.sessionStream;
}
