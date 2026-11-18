/// Maestro encontrado en la red.
class PeerMasterInfo {
  const PeerMasterInfo({
    required this.name,
    required this.host,
    required this.port,
  });

  final String name;
  final String host;
  final int port;
}
