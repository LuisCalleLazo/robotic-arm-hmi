import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/serial_connection/domain/entities/port_info.dart';
import 'package:robotic_arm_hmi/features/serial_connection/domain/entities/serial_config.dart';
import 'package:robotic_arm_hmi/features/serial_connection/domain/repositories/serial_repository.dart';
import 'package:robotic_arm_hmi/features/serial_connection/presentation/bloc/connection_bloc.dart';

void main() {
  test(
    'preserves the originating peer when forwarding a serial command',
    () async {
      final repository = _FakeSerialRepository();
      final sharedCommand = Completer<CommandSent>();
      final loggedCommands = <String>[];
      final bloc = ConnectionBloc(
        repository,
        onCommandSent: loggedCommands.add,
        onCommandShared: (event) async => sharedCommand.complete(event),
      );
      addTearDown(() async {
        await bloc.close();
        await repository.close();
      });

      await bloc.stream.firstWhere((state) => state.ports.isNotEmpty);
      final connected = bloc.stream.firstWhere((state) => state.isConnected);
      bloc.add(const ConnectRequested());
      await connected;

      bloc.add(const CommandSent('BCX500:2000', sourceClientId: 'slave-1'));
      final event = await sharedCommand.future.timeout(
        const Duration(seconds: 1),
      );

      expect(event.text, 'BCX500:2000');
      expect(event.sourceClientId, 'slave-1');
      expect(repository.sent, ['BCX500:2000']);
      expect(loggedCommands, ['BCX500:2000']);
    },
  );

  test('returns to disconnected state when serial link is lost', () async {
    final repository = _FakeSerialRepository();
    final bloc = ConnectionBloc(repository);
    addTearDown(() async {
      await bloc.close();
      await repository.close();
    });

    await bloc.stream.firstWhere((state) => state.ports.isNotEmpty);
    expect(bloc.state.selectedPort, 'COM3');

    final connected = bloc.stream.firstWhere((state) => state.isConnected);
    bloc.add(const ConnectRequested());
    await connected;

    final disconnected = bloc.stream.firstWhere(
      (state) => state.status == LinkStatus.disconnected && state.error != null,
    );
    repository.connectionController.add(false);
    final state = await disconnected;

    expect(state.error, contains('Se perdió la conexión'));
  });
}

class _FakeSerialRepository implements SerialRepository {
  final StreamController<String> _lines = StreamController<String>.broadcast();
  final StreamController<bool> connectionController =
      StreamController<bool>.broadcast();
  final sent = <String>[];

  @override
  Stream<String> get lines => _lines.stream;

  @override
  Stream<bool> get connectionChanges => connectionController.stream;

  @override
  bool get isConnected => false;

  @override
  Future<List<PortInfo>> listPorts() async => const [
    PortInfo(name: 'COM3', description: 'Arduino'),
  ];

  @override
  Future<void> connect(SerialConfig config) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void send(String data) => sent.add(data);

  @override
  void dispose() {}

  Future<void> close() async {
    await _lines.close();
    await connectionController.close();
  }
}
