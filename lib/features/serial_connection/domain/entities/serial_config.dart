import 'package:equatable/equatable.dart';

const List<int> kBaudRates = [
  9600,
  19200,
  38400,
  57600,
  115200,
  230400,
  250000,
  500000,
  1000000,
];

const int kDefaultBaudRate = 115200;

class SerialConfig extends Equatable {
  const SerialConfig({
    required this.portName,
    this.baudRate = kDefaultBaudRate,
    this.dataBits = 8,
    this.stopBits = 1,
  });

  final String portName;
  final int baudRate;
  final int dataBits;
  final int stopBits;

  @override
  List<Object?> get props => [portName, baudRate, dataBits, stopBits];
}
