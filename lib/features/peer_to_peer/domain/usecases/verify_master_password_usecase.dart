import '../repositories/peer_repository.dart';

class VerifyMasterPasswordUseCase {
  const VerifyMasterPasswordUseCase(this._repo);
  final PeerRepository _repo;

  bool call(String password) => _repo.verifyMasterPassword(password);
}
