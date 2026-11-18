import '../entities/peer_entities.dart';
import '../repositories/peer_repository.dart';

class SendPeerMessageUseCase {
  const SendPeerMessageUseCase(this._repo);
  final PeerRepository _repo;

  Future<void> call(PeerMessage message) => _repo.send(message);
}
