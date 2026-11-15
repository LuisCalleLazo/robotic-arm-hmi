import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialDatasource {
  SerialPort? _port;
  SerialPortReader? _reader;

  List<String> availablePorts() => SerialPort.availablePorts;

  Stream<String> connect(String name, {int baud = 115200}) {
    _port = SerialPort(name);
    if (!_port!.openReadWrite()) {
      throw Exception(SerialPort.lastError);
    }
    _port!.config = SerialPortConfig()
      ..baudRate = baud
      ..bits = 8
      ..parity = SerialPortParity.none
      ..stopBits = 1;

    _reader = SerialPortReader(_port!);
    return _reader!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }

  void write(String data) =>
      _port?.write(Uint8List.fromList(utf8.encode('$data\n')));

  void dispose() {
    _reader?.close();
    _port?.close();
    _port?.dispose();
  }
}
