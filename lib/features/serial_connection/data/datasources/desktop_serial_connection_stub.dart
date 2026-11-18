import 'dart:async';
import 'dart:typed_data';

class DesktopSerialConnection {
  Stream<Uint8List> get receiveStream => const Stream.empty();

  List<String> listPorts() => const [];

  Future<void> connect({
    required String portName,
    required int baudRate,
    required void Function() onLost,
  }) async {
    throw UnsupportedError('Desktop serial is unavailable on this platform.');
  }

  Future<void> disconnect() async {}

  Future<void> write(Uint8List bytes) async {
    throw StateError('No desktop serial connection is active.');
  }
}
