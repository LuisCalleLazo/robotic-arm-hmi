import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../../domain/entities/port_info.dart';
import '../../domain/entities/serial_config.dart';

class SerialConnectionException implements Exception {
  SerialConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Acceso directo a `flutter_libserialport`.
class SerialDatasource {
  /// Muchas placas Arduino se reinician al abrir el puerto (señal DTR).
  /// Esperamos un momento para no leer basura del arranque.
  static const Duration _boardResetDelay = Duration(milliseconds: 1500);

  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<String>? _subscription;
  bool _connected = false;

  final StreamController<String> _lines = StreamController<String>.broadcast();
  final StreamController<bool> _connection = StreamController<bool>.broadcast();

  Stream<String> get lines => _lines.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _connected;

  List<PortInfo> listPorts() {
    return [
      for (final name in SerialPort.availablePorts)
        PortInfo(name: name, description: _describe(name)),
    ];
  }

  String? _describe(String name) {
    final port = SerialPort(name);
    try {
      return port.description ?? port.productName;
    } catch (_) {
      return null;
    } finally {
      port.dispose();
    }
  }

  Future<void> connect(SerialConfig config) async {
    await disconnect();

    final port = SerialPort(config.portName);
    if (!port.openReadWrite()) {
      final error = SerialPort.lastError;
      port.dispose();
      throw SerialConnectionException(
        _openErrorMessage(config.portName, error),
      );
    }

    final portConfig = SerialPortConfig()
      ..baudRate = config.baudRate
      ..bits = config.dataBits
      ..stopBits = config.stopBits
      ..parity = SerialPortParity.none
      ..setFlowControl(SerialPortFlowControl.none);
    port.config = portConfig;
    portConfig.dispose();

    await Future<void>.delayed(_boardResetDelay);

    _port = port;
    _reader = SerialPortReader(port);
    _subscription = _reader!.stream
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          _lines.add,
          onError: (Object _) => unawaited(_handleLost()),
          onDone: _handleLost,
          cancelOnError: true,
        );

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
    port.write(Uint8List.fromList(utf8.encode('$data\n')));
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

    _reader?.close();
    _reader = null;

    final port = _port;
    _port = null;
    if (port != null) {
      if (port.isOpen) port.close();
      port.dispose();
    }
  }

  String _openErrorMessage(String name, SerialPortError? error) {
    final detail = (error != null && error.message.isNotEmpty)
        ? error.message
        : 'error desconocido';

    final looksLikePermissions =
        detail.toLowerCase().contains('permission') ||
        detail.toLowerCase().contains('denied');
    final hint = (Platform.isLinux && looksLikePermissions)
        ? ' Agrega tu usuario al grupo "dialout" y vuelve a iniciar sesión.'
        : '';

    return 'No se pudo abrir $name: $detail.$hint';
  }
}
