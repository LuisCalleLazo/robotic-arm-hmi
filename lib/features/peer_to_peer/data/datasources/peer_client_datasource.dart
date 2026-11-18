import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Transporte del esclavo (cliente WebSocket). Funciona en web, desktop y mobile.
class PeerClientDataSource {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _messages = StreamController<String>.broadcast();
  final _closed = StreamController<void>.broadcast();

  Stream<String> get messages => _messages.stream;
  Stream<void> get onClosed => _closed.stream;

  Future<void> connect(
    Uri uri, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await disconnect();
    final channel = WebSocketChannel.connect(uri);
    try {
      await channel.ready.timeout(timeout);
    } catch (_) {
      unawaited(channel.sink.close().catchError((_) {}));
      rethrow;
    }
    _channel = channel;
    _sub = channel.stream.listen(
      (data) => _messages.add(data.toString()),
      onDone: _handleClosed,
      onError: (_) => _handleClosed(),
      cancelOnError: true,
    );
  }

  void send(String data) => _channel?.sink.add(data);

  void _handleClosed() {
    if (_channel == null) return;
    _channel = null;
    _sub = null;
    _closed.add(null);
  }

  Future<void> disconnect() async {
    final sub = _sub;
    final channel = _channel;
    _sub = null;
    _channel = null;
    await sub?.cancel();
    if (channel != null) {
      unawaited(channel.sink.close().catchError((_) {}));
    }
  }
}
