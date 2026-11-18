import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'peer_server_datasource.dart';
import 'peer_server_event.dart';

PeerServerDataSource createPeerServerDataSource() => PeerServerDataSourceIo();

class PeerServerDataSourceIo implements PeerServerDataSource {
  final _events = StreamController<PeerServerEvent>.broadcast();
  final _clients = <String, WebSocketChannel>{};
  HttpServer? _server;
  int _seq = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<PeerServerEvent> get events => _events.stream;

  @override
  Future<int> start(int port) async {
    final running = _server;
    if (running != null) return running.port;
    final server = await shelf_io.serve(
      _handler,
      InternetAddress.anyIPv4,
      port,
    );
    _server = server;
    return server.port;
  }

  FutureOr<Response> _handler(Request request) {
    if (request.url.path == 'ws') {
      final params = request.url.queryParameters;
      final raw = params['name']?.trim();
      final name = (raw == null || raw.isEmpty)
          ? 'Esclavo'
          : (raw.length > 32 ? raw.substring(0, 32) : raw);
      final machine = params['machine'];
      final ws = webSocketHandler(
        (WebSocketChannel channel, String? protocol) =>
            _onConnect(channel, name, machine),
        pingInterval: const Duration(seconds: 10),
      );
      return ws(request);
    }
    return Response.ok('peer_to_peer master');
  }

  void _onConnect(WebSocketChannel channel, String name, String? machine) {
    final id = 'c${++_seq}';
    _clients[id] = channel;
    _events.add(ClientConnected(id, name, machine));
    channel.stream.listen(
      (data) => _events.add(ClientMessage(id, data.toString())),
      onDone: () => _drop(id),
      onError: (_) => _drop(id),
      cancelOnError: true,
    );
  }

  void _drop(String id) {
    if (_clients.remove(id) != null) _events.add(ClientDisconnected(id));
  }

  @override
  Future<List<String>> localAddresses() async {
    final ifaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return [
      for (final i in ifaces)
        for (final a in i.addresses) a.address,
    ];
  }

  @override
  void sendTo(String clientId, String data) =>
      _clients[clientId]?.sink.add(data);

  @override
  void broadcast(String data) {
    for (final c in _clients.values) {
      c.sink.add(data);
    }
  }

  @override
  void kick(String clientId) {
    final c = _clients[clientId];
    if (c == null) return;
    unawaited(c.sink.close().catchError((_) {}));
    _drop(clientId);
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    for (final c in _clients.values.toList()) {
      unawaited(c.sink.close().catchError((_) {}));
    }
    _clients.clear();
    await server?.close(force: true);
  }
}
