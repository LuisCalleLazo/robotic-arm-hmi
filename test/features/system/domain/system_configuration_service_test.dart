import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/system/data/database/system_database.dart'
    hide ProcessMotors;
import 'package:robotic_arm_hmi/features/system/data/database/system_database_manager.dart';
import 'package:robotic_arm_hmi/features/system/data/datasources/system_local_datasource.dart';
import 'package:robotic_arm_hmi/features/system/data/repositories/system_repository_impl.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/machine_configuration.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/motor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process_motors.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/process_servo.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/sensor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/servo.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_machine.dart';
import 'package:robotic_arm_hmi/features/system/domain/services/system_configuration_service.dart';

void main() {
  late SystemDatabaseManager manager;
  late SystemConfigurationService service;
  late SystemRepositoryImpl repository;

  setUp(() async {
    manager = SystemDatabaseManager(
      databaseFactory: () => SystemDatabase(NativeDatabase.memory()),
    );
    await manager.start();
    repository = SystemRepositoryImpl(SystemLocalDataSource(manager));
    service = SystemConfigurationService(system: repository);
  });

  tearDown(() async {
    await service.dispose();
    await manager.dispose();
  });

  test('saves a machine with multiple small belts and arms', () async {
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: 1, name: 'Sistema', type: 'Sistema'),
      components: [
        SystemMachine(
          id: 2,
          name: 'Cinta 1',
          type: 'Cinta pequeña',
          parentMachineId: 1,
        ),
        SystemMachine(
          id: 3,
          name: 'Cinta 2',
          type: 'Cinta pequeña',
          parentMachineId: 1,
        ),
        SystemMachine(id: 4, name: 'Brazo', type: 'Brazo', parentMachineId: 1),
        SystemMachine(
          id: 5,
          name: 'Cinta grande',
          type: 'Cinta grande',
          parentMachineId: 1,
        ),
      ],
      motors: [
        Motor(
          id: 10,
          systemMachineId: 4,
          key: 'X',
          keySensorRight: null,
          keySensorLeft: null,
          speed: 5000,
          maxStepsRight: null,
          maxStepsLeft: null,
        ),
      ],
      servos: [Servo(id: 11, machineId: 4, key: 'S', maxOpen: 180)],
      sensors: [Sensor(id: 12, machineId: 1, key: 'CGC', name: 'Entrada')],
    );

    await service.saveMachine(configuration);

    expect(await repository.getMachines(), hasLength(5));
    expect(await repository.getMotors(), hasLength(1));
    expect(await repository.getServos(), hasLength(1));
    expect(await repository.getSensors(), hasLength(1));
  });

  test('rejects a machine configured with multiple large belts', () async {
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: 1, name: 'Sistema', type: 'Sistema'),
      components: [
        SystemMachine(
          id: 2,
          name: 'Cinta grande 1',
          type: 'Cinta grande',
          parentMachineId: 1,
        ),
        SystemMachine(
          id: 3,
          name: 'Cinta grande 2',
          type: 'CINTA GRANDE',
          parentMachineId: 1,
        ),
      ],
    );

    await expectLater(service.saveMachine(configuration), throwsStateError);
    expect(await repository.getMachines(), isEmpty);
  });

  test(
    'coordinates motor and servo movements in one process sequence',
    () async {
      await service.saveMachine(
        MachineConfiguration(
          machine: SystemMachine(id: 1, name: 'Sistema', type: 'Sistema'),
          motors: [
            Motor(
              id: 10,
              systemMachineId: 1,
              key: 'X',
              keySensorRight: null,
              keySensorLeft: null,
              speed: 5000,
              maxStepsRight: null,
              maxStepsLeft: null,
            ),
          ],
          servos: [Servo(id: 11, machineId: 1, key: 'S', maxOpen: 180)],
        ),
      );

      await service.saveProcessConfiguration(
        process: Process(
          id: 20,
          name: 'Mover',
          order: 0,
          machineId: 1,
          mqttTopic: 'robot/entrada',
          mqttExpectedMessage: 'INICIAR',
        ),
        motors: [
          ProcessMotors(
            id: 21,
            processId: 20,
            motorId: 10,
            name: 'X',
            order: 0,
            steps: 100,
            speed: 1000,
          ),
        ],
        servos: [
          ProcessServo(
            id: 22,
            processId: 20,
            servoId: 11,
            name: 'S',
            order: 1,
            openValue: 90,
            speed: 60,
          ),
        ],
      );

      expect(await repository.getProcessMotors(20), hasLength(1));
      expect(await repository.getProcessServos(20), hasLength(1));
      final savedProcess = (await repository.getProcesses()).single;
      expect(savedProcess.mqttTopic, 'robot/entrada');
      expect(savedProcess.mqttExpectedMessage, 'INICIAR');
    },
  );

  test('requires both MQTT topic and expected message', () async {
    await service.saveMachine(
      MachineConfiguration(
        machine: SystemMachine(id: 1, name: 'Sistema', type: 'Sistema'),
      ),
    );

    await expectLater(
      service.saveProcessDefinition(
        Process(
          id: 30,
          name: 'Activar',
          order: 0,
          machineId: 1,
          mqttTopic: 'robot/entrada',
        ),
      ),
      throwsStateError,
    );
    expect(await repository.getProcesses(), isEmpty);
  });
}
