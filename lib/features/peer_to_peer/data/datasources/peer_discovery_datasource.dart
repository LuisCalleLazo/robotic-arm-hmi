import '../../domain/entities/peer_entities.dart';

/// Descubrimiento de maestros por la red local (UDP broadcast). No disponible en web.
abstract class PeerDiscoveryDataSource {
  bool get isSupported;

  /// Maestro: responde a las búsquedas con su nombre y puerto.
  Future<void> startResponder({required String name, required int wsPort});
  Future<void> stopResponder();

  /// Esclavo: emite cada maestro encontrado y cierra el stream al terminar [timeout].
  Stream<PeerMasterInfo> discover({
    Duration timeout = const Duration(seconds: 3),
  });
}
