import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

class DesktopSerialConnection {
  final StreamController<Uint8List> _receive =
      StreamController<Uint8List>.broadcast();

  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _readerSubscription;
  Timer? _portWatch;
  Future<void>? _disconnecting;
  bool _connected = false;
  bool _lossReported = false;

  Stream<Uint8List> get receiveStream => _receive.stream;

  List<String> listPorts() => SerialPort.availablePorts;

  Future<void> connect({
    required String portName,
    required int baudRate,
    required void Function() onLost,
  }) async {
    await disconnect();

    final port = SerialPort(portName);
    if (!port.openReadWrite()) {
      final error = SerialPort.lastError?.message ?? 'error desconocido';
      port.dispose();
      throw StateError('No se pudo abrir $portName: $error');
    }

    SerialPortConfig? config;
    try {
      config = port.config;
      config
        ..baudRate = baudRate
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      port.config = config;
    } catch (_) {
      port.close();
      port.dispose();
      rethrow;
    } finally {
      config?.dispose();
    }

    _port = port;
    _lossReported = false;
    _connected = true;
    final reader = SerialPortReader(port, timeout: 100);
    _reader = reader;
    _readerSubscription = reader.stream.listen(
      _receive.add,
      onError: (Object _) => _reportLost(onLost),
      onDone: () => _reportLost(onLost),
      cancelOnError: true,
    );
    _portWatch = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connected && !SerialPort.availablePorts.contains(portName)) {
        _reportLost(onLost);
      }
    });
  }

  Future<void> write(Uint8List bytes) async {
    final port = _port;
    if (!_connected || port == null || !port.isOpen) {
      throw StateError('El puerto serial no está conectado.');
    }

    final written = port.write(bytes, timeout: 0);
    if (written != bytes.length) {
      throw StateError(
        'Escritura serial incompleta: $written de ${bytes.length} bytes.',
      );
    }
  }

  void _reportLost(void Function() onLost) {
    if (!_connected || _lossReported) return;
    _lossReported = true;
    onLost();
  }

  Future<void> disconnect() {
    return _disconnecting ??= _closePort().whenComplete(() {
      _disconnecting = null;
    });
  }

  Future<void> _closePort() async {
    _connected = false;
    _portWatch?.cancel();
    _portWatch = null;
    await _readerSubscription?.cancel();
    _readerSubscription = null;

    final reader = _reader;
    _reader = null;
    reader?.close();

    final port = _port;
    _port = null;
    if (reader != null) {
      // Let libserialport's blocking wait return before freeing its port.
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (port != null) {
      if (port.isOpen) port.close();
      port.dispose();
    }
  }
}
