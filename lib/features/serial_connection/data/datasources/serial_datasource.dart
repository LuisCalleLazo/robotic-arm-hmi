import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import '../../domain/entities/port_info.dart';
import '../../domain/entities/serial_config.dart';

class SerialConnectionException implements Exception {
  SerialConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Acceso directo a `usb_serial` (Android).
class SerialDatasource {
  /// Muchas placas Arduino se reinician al abrir el puerto (señal DTR).
  static const Duration _boardResetDelay = Duration(milliseconds: 1500);

  UsbPort? _port;
  String? _portName;
  StreamSubscription<String>? _subscription;
  StreamSubscription<UsbEvent>? _usbEvents;
  bool _connected = false;

  final StreamController<String> _lines = StreamController<String>.broadcast();
  final StreamController<bool> _connection = StreamController<bool>.broadcast();

  Stream<String> get lines => _lines.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _connected;

  /// Ahora es asíncrono: usb_serial consulta el sistema Android.
  Future<List<PortInfo>> listPorts() async {
    final devices = await UsbSerial.listDevices();
    return [
      for (final d in devices)
        PortInfo(
          name: d.deviceName,
          description: d.productName ?? d.manufacturerName,
        ),
    ];
  }

  Future<void> connect(SerialConfig config) async {
    await disconnect();

    final devices = await UsbSerial.listDevices();
    final device = devices
        .where((d) => d.deviceName == config.portName)
        .cast<UsbDevice?>()
        .firstWhere((_) => true, orElse: () => null);

    if (device == null) {
      throw SerialConnectionException(
        'No se encontró el dispositivo ${config.portName}.',
      );
    }

    // create() solicita el permiso USB al usuario si hace falta.
    final port = await device.create();
    if (port == null) {
      throw SerialConnectionException(
        'No se pudo abrir ${config.portName}: permiso USB denegado o '
        'dispositivo no soportado.',
      );
    }

    if (!await port.open()) {
      throw SerialConnectionException(
        'No se pudo abrir ${config.portName}: error desconocido.',
      );
    }

    await port.setDTR(true);
    await port.setRTS(true);
    await port.setPortParameters(
      config.baudRate,
      config.dataBits,
      config.stopBits,
      UsbPort.PARITY_NONE,
    );

    await Future<void>.delayed(_boardResetDelay);

    final input = port.inputStream;
    if (input == null) {
      await port.close();
      throw SerialConnectionException(
        'No se pudo leer de ${config.portName}.',
      );
    }

    _port = port;
    _portName = config.portName;

    _subscription = input
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          _lines.add,
          onError: (Object _) => unawaited(_handleLost()),
          onDone: () => unawaited(_handleLost()),
          cancelOnError: true,
        );

    // Detecta cable USB desconectado.
    _usbEvents = UsbSerial.usbEventStream?.listen((event) {
      if (event.event == UsbEvent.ACTION_USB_DETACHED &&
          event.device?.deviceName == _portName) {
        unawaited(_handleLost());
      }
    });

    _connected = true;
    _connection.add(true);
  }

  Future<void> disconnect() async {
    final wasConnected = _connected;
    await _teardown();
    if (wasConnected) _connection.add(false);
  }

  void send(String data) {
    final port = _port;
    if (port == null || !_connected) return;
    unawaited(port.write(Uint8List.fromList(utf8.encode('$data\n'))));
  }

  Future<void> dispose() async {
    await disconnect();
    await _lines.close();
    await _connection.close();
  }

  /// El puerto desapareció (cable USB desconectado, error de lectura...).
  Future<void> _handleLost() async {
    if (!_connected) return;
    await _teardown();
    _connection.add(false);
  }

  Future<void> _teardown() async {
    _connected = false;

    await _subscription?.cancel();
    _subscription = null;

    await _usbEvents?.cancel();
    _usbEvents = null;

    final port = _port;
    _port = null;
    _portName = null;
    if (port != null) {
      try {
        await port.close();
      } catch (_) {}
    }
  }
}
