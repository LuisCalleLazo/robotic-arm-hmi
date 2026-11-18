import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class WatchPeerMessagesUseCase {
  const WatchPeerMessagesUseCase(this._repo);
  final PeerRepository _repo;

  Stream<PeerMessage> call() => _repo.messages;
}
