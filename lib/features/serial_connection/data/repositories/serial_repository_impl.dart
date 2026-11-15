import 'dart:async';

import '../../domain/entities/port_info.dart';
import '../../domain/entities/serial_config.dart';
import '../../domain/repositories/serial_repository.dart';
import '../datasources/serial_datasource.dart';

class SerialRepositoryImpl implements SerialRepository {
  SerialRepositoryImpl(this._datasource);

  final SerialDatasource _datasource;

  @override
  List<PortInfo> listPorts() => _datasource.listPorts();

  @override
  Stream<String> get lines => _datasource.lines;

  @override
  Stream<bool> get connectionChanges => _datasource.connectionChanges;

  @override
  bool get isConnected => _datasource.isConnected;

  @override
  Future<void> connect(SerialConfig config) => _datasource.connect(config);

  @override
  Future<void> disconnect() => _datasource.disconnect();

  @override
  void send(String data) => _datasource.send(data);

  @override
  void dispose() => unawaited(_datasource.dispose());
}
