import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/system/data/database/system_database.dart'
    hide ProcessMotors;
import 'package:robotic_arm_hmi/features/system/data/database/system_database_manager.dart';
import 'package:robotic_arm_hmi/features/system/data/datasources/system_local_datasource.dart';
import 'package:robotic_arm_hmi/features/system/data/repositories/system_position_repository_impl.dart';
import 'package:robotic_arm_hmi/features/system/data/repositories/system_repository_impl.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_machine.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_position.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/motor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process_motors.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process_servo.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/sensor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/servo.dart';

void main() {
  late SystemDatabaseManager manager;

  setUp(() {
    manager = SystemDatabaseManager(
      databaseFactory: () => SystemDatabase(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await manager.dispose();
  });

  test('opens the local system database', () async {
    await manager.start();
    expect(await manager.getDatabase(), isA<SystemDatabase>());
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
        machineId: 1,
        mqttTopic: 'robot/entrada',
        mqttExpectedMessage: 'INICIAR',
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
    final savedProcess = (await repository.getProcesses()).single;
    expect(savedProcess.machineId, 1);
    expect(savedProcess.mqttTopic, 'robot/entrada');
    expect(savedProcess.mqttExpectedMessage, 'INICIAR');
    expect((await repository.getProcessMotors(40)).single.speed, 2000);
    expect((await repository.getProcessServos(40)).single.speed, 60);
    expect(await repository.hasProcessMotorHistory(50), isFalse);
    expect(await repository.hasProcessHistory(40), isFalse);
    await repository.deleteProcess(40);
    expect(await repository.getProcessMotors(40), isEmpty);
    expect(await repository.getProcessServos(40), isEmpty);
    expect(await repository.getProcesses(), isEmpty);
  });

  test('persists and removes system layout positions', () async {
    await manager.start();
    final machines = SystemRepositoryImpl(SystemLocalDataSource(manager));
    final positions = SystemPositionRepositoryImpl(
      SystemLocalDataSource(manager),
    );
    await machines.saveMachine(
      SystemMachine(id: 1, name: 'Cinta', type: 'CINTA GRANDE'),
    );
    await positions.saveSystemPosition(
      SystemPosition(
        id: 2,
        number: 1,
        type: 'CINTA GRANDE',
        systemMachineId: 1,
      ),
    );

    final saved = await positions.getSystemPositions();
    expect(saved.single.type, 'CINTA GRANDE');
    expect(saved.single.number, 1);
    expect(saved.single.systemMachineId, 1);

    await positions.deleteSystemPosition(2);
    expect(await positions.getSystemPositions(), isEmpty);
  });
}
