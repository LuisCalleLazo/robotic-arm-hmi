import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/peer_to_peer/domain/entities/peer_connection_status.dart';
import 'package:robotic_arm_hmi/features/peer_to_peer/domain/entities/peer_role.dart';
import 'package:robotic_arm_hmi/features/peer_to_peer/domain/entities/peer_session.dart';
import 'package:robotic_arm_hmi/features/peer_to_peer/domain/repositories/peer_repository.dart';
import 'package:robotic_arm_hmi/features/system/data/database/system_database.dart'
    hide ProcessMotors;
import 'package:robotic_arm_hmi/features/system/data/database/system_database_manager.dart';
import 'package:robotic_arm_hmi/features/system/data/datasources/system_local_datasource.dart';
import 'package:robotic_arm_hmi/features/system/data/repositories/system_repository_impl.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_machine.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/motor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process_motors.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process_servo.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/sensor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/servo.dart';

void main() {
  late _FakePeerRepository peer;
  late SystemDatabaseManager manager;

  setUp(() {
    peer = _FakePeerRepository();
    manager = SystemDatabaseManager(
      peer,
      databaseFactory: () => SystemDatabase(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await manager.dispose();
    await peer.close();
  });

  test('does not open a database for a slave', () async {
    peer.setSession(
      const PeerSession(
        role: PeerRole.slave,
        status: PeerConnectionStatus.connected,
      ),
    );

    await manager.start();

    await expectLater(manager.getDatabase(), throwsStateError);
  });

  test('opens the system database only for an active master', () async {
    peer.setSession(
      const PeerSession(
        role: PeerRole.master,
        status: PeerConnectionStatus.listening,
      ),
    );

    await manager.start();

    final repository = SystemRepositoryImpl(SystemLocalDataSource(manager));
    await repository.saveMachine(
      SystemMachine(id: 1, name: 'Brazo', type: 'BRAZO SCARA'),
    );
    final machines = await repository.getMachines();
    expect(machines, hasLength(1));
    expect(machines.single.name, 'Brazo');
    expect(machines.single.type, 'BRAZO SCARA');
  });

  test('persists machine sensors and per-movement speeds', () async {
    peer.setSession(
      const PeerSession(
        role: PeerRole.master,
        status: PeerConnectionStatus.listening,
      ),
    );
    await manager.start();
    final repository = SystemRepositoryImpl(SystemLocalDataSource(manager));
    await repository.saveMachine(
      SystemMachine(id: 1, name: 'Brazo', type: 'BRAZO SCARA'),
    );
    await repository.saveSensor(
      Sensor(id: 10, machineId: 1, key: 'SENSOR-EXT', name: 'Entrada'),
    );
    await repository.saveMotor(
      Motor(
        id: 20,
        systemMachineId: 1,
        key: 'BCX',
        keySensorRight: null,
        keySensorLeft: null,
        speed: 5000,
        maxStepsRight: null,
        maxStepsLeft: null,
      ),
    );
    await repository.saveServo(
      Servo(id: 30, machineId: 1, key: 'BCS', maxOpen: 180),
    );
    await repository.saveProcess(
      Process(
        id: 40,
        name: 'Tomar',
        order: 0,
        activationSensorId: 10,
        machineId: 1,
      ),
    );
    await repository.saveProcessMotor(
      ProcessMotors(
        id: 50,
        processId: 40,
        motorId: 20,
        name: 'BCX',
        order: 0,
        steps: -500,
        speed: 2000,
      ),
    );
    await repository.saveProcessServo(
      ProcessServo(
        id: 60,
        processId: 40,
        servoId: 30,
        name: 'BCS',
        order: 1,
        openValue: 90,
        speed: 60,
      ),
    );

    expect((await repository.getSensors()).single.machineId, 1);
    expect((await repository.getProcesses()).single.machineId, 1);
    expect((await repository.getProcessMotors(40)).single.speed, 2000);
    expect((await repository.getProcessServos(40)).single.speed, 60);
    expect(await repository.hasProcessMotorHistory(50), isFalse);
    await repository.deleteProcessMotor(50);
    expect(await repository.getProcessMotors(40), isEmpty);
  });
}

class _FakePeerRepository implements PeerRepository {
  final _sessions = StreamController<PeerSession>.broadcast();
  PeerSession _session = const PeerSession();

  void setSession(PeerSession session) {
    _session = session;
    _sessions.add(session);
  }

  @override
  PeerSession get session => _session;

  @override
  Stream<PeerSession> get sessionStream => _sessions.stream;

  Future<void> close() => _sessions.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
