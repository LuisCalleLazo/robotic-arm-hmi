import '../../domain/entities/peer_entities.dart';
import 'peer_discovery_datasource.dart';

PeerDiscoveryDataSource createPeerDiscoveryDataSource() =>
    _UnsupportedDiscoveryDataSource();

class _UnsupportedDiscoveryDataSource implements PeerDiscoveryDataSource {
  @override
  bool get isSupported => false;

  @override
  Future<void> startResponder({
    required String name,
    required int wsPort,
  }) async {}

  @override
  Future<void> stopResponder() async {}

  @override
  Stream<PeerMasterInfo> discover({
    Duration timeout = const Duration(seconds: 3),
  }) =>
      const Stream.empty();
}
