import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/peer_entities.dart';
import 'peer_discovery_datasource.dart';

PeerDiscoveryDataSource createPeerDiscoveryDataSource() =>
    PeerDiscoveryDataSourceIo();

class PeerDiscoveryDataSourceIo implements PeerDiscoveryDataSource {
  static const _probe = 'PEER_DISCOVER_V1';
  RawDatagramSocket? _responder;

  @override
  bool get isSupported => true;

  // ------------------------------------------------------------ MAESTRO

  @override
  Future<void> startResponder({
    required String name,
    required int wsPort,
  }) async {
    await stopResponder();
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      PeerConfig.discoveryPort,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    final reply = utf8.encode(
      jsonEncode({'app': 'peer_to_peer', 'name': name, 'port': wsPort}),
    );
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;
      if (utf8.decode(dg.data, allowMalformed: true) != _probe) return;
      try {
        socket.send(reply, dg.address, dg.port);
      } catch (_) {}
    });
    _responder = socket;
  }

  @override
  Future<void> stopResponder() async {
    _responder?.close();
    _responder = null;
  }

  // ------------------------------------------------------------ ESCLAVO

  Future<List<InternetAddress>> _targets() async {
    final targets = <String>{'255.255.255.255', '127.0.0.1'};
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final i in ifaces) {
        for (final a in i.addresses) {
          final p = a.address.split('.');
          if (p.length == 4) targets.add('${p[0]}.${p[1]}.${p[2]}.255');
        }
      }
    } catch (_) {}
    return targets.map(InternetAddress.new).toList();
  }

  @override
  Stream<PeerMasterInfo> discover({
    Duration timeout = const Duration(seconds: 3),
  }) {
    final controller = StreamController<PeerMasterInfo>();
    RawDatagramSocket? socket;
    Timer? resend;
    Timer? stopTimer;
    var closed = false;

    Future<void> close() async {
      if (closed) return;
      closed = true;
      resend?.cancel();
      stopTimer?.cancel();
      socket?.close();
      await controller.close();
    }

    controller.onListen = () async {
      try {
        final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        if (closed) {
          s.close();
          return;
        }
        socket = s;
        s.broadcastEnabled = true;
        final seen = <String>{};
        s.listen((event) {
          if (event != RawSocketEvent.read) return;
          final dg = s.receive();
          if (dg == null) return;
          try {
            final map = jsonDecode(utf8.decode(dg.data));
            if (map is! Map || map['app'] != 'peer_to_peer') return;
            final name = map['name'] as String;
            final port = (map['port'] as num).toInt();
            if (seen.add('$name:$port') && !controller.isClosed) {
              controller.add(
                PeerMasterInfo(name: name, host: dg.address.address, port: port),
              );
            }
          } catch (_) {}
        });

        final targets = await _targets();
        final probe = utf8.encode(_probe);
        void sendProbes() {
          for (final t in targets) {
            try {
              s.send(probe, t, PeerConfig.discoveryPort);
            } catch (_) {}
          }
        }

        sendProbes();
        resend = Timer.periodic(
          const Duration(milliseconds: 700),
          (_) => sendProbes(),
        );
        stopTimer = Timer(timeout, close);
      } catch (_) {
        await close();
      }
    };
    controller.onCancel = close;
    return controller.stream;
  }
}
