import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:universal_serial/universal_serial.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../domain/entities/port_info.dart';
import '../../domain/entities/serial_config.dart';

class SerialConnectionException implements Exception {
  SerialConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SerialDatasource {
  static const String _webPortName = 'web:choose-device';

  SerialManager? _manager;
  UsbPort? _androidPort;
  String? _portName;
  StreamSubscription<String>? _subscription;
  StreamSubscription<DeviceEvent>? _deviceEvents;
  StreamSubscription<UsbEvent>? _usbEvents;
  bool _connected = false;

  final StreamController<String> _lines = StreamController<String>.broadcast();
  final StreamController<bool> _connection = StreamController<bool>.broadcast();

  Stream<String> get lines => _lines.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _connected;

  Future<List<PortInfo>> listPorts() async {
    if (!_supportsSerial) return const [];

    if (_isAndroid) {
      final devices = await UsbSerial.listDevices();
      return [
        for (final device in devices)
          PortInfo(
            name: device.deviceName,
            description: device.productName ?? device.manufacturerName,
          ),
      ];
    }

    final ports = await _serialManager.getAvailablePorts();
    final availablePorts = [for (final name in ports) PortInfo(name: name)];

    // The browser only exposes devices after the user grants access. The
    // chooser is opened later from connect(), which is initiated by a click.
    if (kIsWeb) {
      availablePorts.add(
        const PortInfo(
          name: _webPortName,
          description: 'Seleccionar dispositivo en el navegador',
        ),
      );
    }

    return availablePorts;
  }

  Future<void> connect(SerialConfig config) async {
    await disconnect();
    if (!_supportsSerial) {
      throw SerialConnectionException(
        'La conexión serial no está disponible en esta plataforma.',
      );
    }

    if (_isAndroid) {
      await _connectAndroid(config);
      return;
    }

    final manager = _serialManager;
    _subscription = _listenToBytes(manager.receiveStream);
    _deviceEvents = manager.deviceEventStream.listen(_handleDeviceEvent);

    late final bool connected;
    try {
      connected = await manager.connect(
        portAddress: kIsWeb || config.portName == _webPortName
            ? null
            : config.portName,
        baudRate: config.baudRate,
      );
    } catch (_) {
      await _teardown();
      rethrow;
    }
    if (!connected) {
      await _teardown();
      throw SerialConnectionException(
        kIsWeb
            ? 'No se pudo abrir el puerto. Usa un navegador compatible '
                  '(Chrome o Edge) en HTTPS o localhost y concede el permiso.'
            : 'No se pudo abrir ${config.portName}: revisa el permiso USB '
                  'o que el puerto no esté ocupado.',
      );
    }

    _portName = config.portName;
    _connected = true;
    _connection.add(true);
  }

  Future<void> disconnect() async {
    final wasConnected = _connected;
    await _teardown();
    if (wasConnected) _connection.add(false);
  }

  void send(String data) {
    if (!_connected) return;
    final bytes = Uint8List.fromList(utf8.encode('$data\n'));
    final androidPort = _androidPort;
    if (androidPort != null) {
      unawaited(androidPort.write(bytes));
    } else {
      unawaited(_serialManager.write(bytes));
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _lines.close();
    await _connection.close();
  }

  bool get _supportsSerial =>
      kIsWeb ||
      _isAndroid ||
      switch (defaultTargetPlatform) {
        TargetPlatform.windows ||
        TargetPlatform.macOS ||
        TargetPlatform.linux => true,
        _ => false,
      };

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  SerialManager get _serialManager => _manager ??= getSerialManager();

  StreamSubscription<String> _listenToBytes(Stream<List<int>> bytes) => bytes
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .listen(
        _lines.add,
        onError: (Object _) => unawaited(_handleLost()),
        onDone: () => unawaited(_handleLost()),
        cancelOnError: true,
      );

  Future<void> _connectAndroid(SerialConfig config) async {
    final devices = await UsbSerial.listDevices();
    final device = devices.cast<UsbDevice?>().firstWhere(
      (candidate) => candidate?.deviceName == config.portName,
      orElse: () => null,
    );
    if (device == null) {
      throw SerialConnectionException(
        'No se encontró el dispositivo ${config.portName}.',
      );
    }

    final port = await device.create();
    if (port == null) {
      throw SerialConnectionException(
        'No se pudo abrir ${config.portName}: permiso USB denegado o '
        'dispositivo no soportado.',
      );
    }

    try {
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
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      final input = port.inputStream;
      if (input == null) {
        throw SerialConnectionException(
          'No se pudo leer de ${config.portName}.',
        );
      }

      _androidPort = port;
      _portName = config.portName;
      _subscription = _listenToBytes(input.cast<List<int>>());
      _usbEvents = UsbSerial.usbEventStream?.listen((event) {
        if (event.event == UsbEvent.ACTION_USB_DETACHED &&
            event.device?.deviceName == _portName) {
          unawaited(_handleLost());
        }
      });
      _connected = true;
      _connection.add(true);
    } catch (_) {
      if (identical(_androidPort, port)) {
        await _teardown();
      } else {
        await port.close();
      }
      rethrow;
    }
  }

  void _handleDeviceEvent(DeviceEvent event) {
    if (event.type != DeviceEventType.disconnected || !_connected) return;
    if (kIsWeb || event.deviceName == null || event.deviceName == _portName) {
      unawaited(_handleLost());
    }
  }

  Future<void> _handleLost() async {
    if (!_connected) return;
    _connected = false;
    await _teardown();
    _connection.add(false);
  }

  Future<void> _teardown() async {
    _connected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _deviceEvents?.cancel();
    _deviceEvents = null;
    await _usbEvents?.cancel();
    _usbEvents = null;
    _portName = null;
    final androidPort = _androidPort;
    _androidPort = null;
    if (androidPort != null) await androidPort.close();
    await _manager?.disconnect();
  }
}
