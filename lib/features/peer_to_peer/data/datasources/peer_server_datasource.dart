import 'peer_server_event.dart';

/// Transporte del maestro (servidor WebSocket local). Solo desktop/mobile.
abstract class PeerServerDataSource {
  bool get isSupported;
  Stream<PeerServerEvent> get events;

  /// Devuelve el puerto realmente enlazado.
  Future<int> start(int port);
  Future<List<String>> localAddresses();
  void sendTo(String clientId, String data);
  void broadcast(String data);
  void kick(String clientId);
  Future<void> stop();
}
