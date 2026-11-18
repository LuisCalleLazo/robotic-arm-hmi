import 'peer_server_datasource.dart';
import 'peer_server_event.dart';

PeerServerDataSource createPeerServerDataSource() =>
    _UnsupportedPeerServerDataSource();

class _UnsupportedPeerServerDataSource implements PeerServerDataSource {
  @override
  bool get isSupported => false;

  @override
  Stream<PeerServerEvent> get events => const Stream.empty();

  @override
  Future<int> start(int port) async => throw UnsupportedError(
        'El modo maestro (servidor local) no está disponible en web.',
      );

  @override
  Future<List<String>> localAddresses() async => const [];

  @override
  void sendTo(String clientId, String data) {}

  @override
  void broadcast(String data) {}

  @override
  void kick(String clientId) {}

  @override
  Future<void> stop() async {}
}
