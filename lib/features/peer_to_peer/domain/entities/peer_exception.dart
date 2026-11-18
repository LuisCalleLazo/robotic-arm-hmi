class PeerException implements Exception {
  const PeerException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PeerPermissionException extends PeerException {
  const PeerPermissionException()
      : super('No tienes permiso de control en esta sesión.');
}
