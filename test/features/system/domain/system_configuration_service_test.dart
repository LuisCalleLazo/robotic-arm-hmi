import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/peer_to_peer/domain/entities/peer_entities.dart';
import 'package:robotic_arm_hmi/features/peer_to_peer/domain/repositories/peer_repository.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/machine_configuration.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/motor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_machine.dart';
import 'package:robotic_arm_hmi/features/system/domain/repositories/system_repository.dart';
import 'package:robotic_arm_hmi/features/system/domain/services/system_configuration_service.dart';

void main() {
  late _FakePeerRepository peer;
  late SystemConfigurationService service;

  setUp(() {
    peer = _FakePeerRepository();
    service = SystemConfigurationService(
      peer: peer,
      system: _UnusedSystemRepository(),
    );
  });

  tearDown(() async {
    await service.dispose();
    await peer.close();
  });

  test(
    'slave can create and edit its machine without deleting components',
    () async {
      await service.saveMachine(_configuration());
      await service.saveMachine(
        _configuration(motorSpeed: 6200, componentName: 'Cinta editada'),
      );

      expect(service.localSlaveConfiguration?.motors.single.speed, 6200);
      expect(
        service.localSlaveConfiguration?.components.single.name,
        'Cinta editada',
      );
      await expectLater(
        service.saveMachine(_configuration(includeMotor: false)),
        throwsStateError,
      );
      await expectLater(
        service.saveMachine(_configuration(includeComponent: false)),
        throwsStateError,
      );
      expect(peer.sent, hasLength(2));
    },
  );
}

MachineConfiguration _configuration({
  double motorSpeed = 5000,
  String componentName = 'Cinta',
  bool includeMotor = true,
  bool includeComponent = true,
}) => MachineConfiguration(
  machine: SystemMachine(id: 1, name: 'Brazo', type: 'SISTEMA'),
  components: includeComponent
      ? [
          SystemMachine(
            id: 2,
            name: componentName,
            type: 'CINTA PEQUEÑA',
            parentMachineId: 1,
          ),
        ]
      : const [],
  motors: includeMotor
      ? [
          Motor(
            id: 3,
            systemMachineId: 1,
            key: 'X',
            keySensorRight: null,
            keySensorLeft: null,
            speed: motorSpeed,
            maxStepsRight: null,
            maxStepsLeft: null,
          ),
        ]
      : const [],
);

class _FakePeerRepository implements PeerRepository {
  final _sessionChanges = StreamController<PeerSession>.broadcast();
  final _messages = StreamController<PeerMessage>.broadcast();
  final sent = <PeerMessage>[];

  @override
  PeerSession get session => const PeerSession(
    role: PeerRole.slave,
    status: PeerConnectionStatus.connected,
  );

  @override
  Stream<PeerSession> get sessionStream => _sessionChanges.stream;

  @override
  Stream<PeerMessage> get messages => _messages.stream;

  @override
  Future<void> send(PeerMessage message) async => sent.add(message);

  Future<void> close() async {
    await _sessionChanges.close();
    await _messages.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedSystemRepository implements SystemRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
