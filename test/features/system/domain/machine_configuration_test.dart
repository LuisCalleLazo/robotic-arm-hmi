import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/machine_configuration.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/motor.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/servo.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_machine.dart';

void main() {
  test('rejects more than one large belt', () {
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: 1, name: 'Línea', type: 'SISTEMA'),
      components: [
        SystemMachine(id: 2, name: 'Grande 1', type: 'CINTA GRANDE'),
        SystemMachine(id: 3, name: 'Grande 2', type: 'CINTA GRANDE'),
      ],
    );

    expect(
      MachineConfigurationValidator.validate(configuration),
      'Una máquina no puede tener más de una cinta grande.',
    );
  });

  test('allows several small belts and arms', () {
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: 1, name: 'Línea', type: 'SISTEMA'),
      components: [
        SystemMachine(
          id: 2,
          name: 'Cinta 1',
          type: 'CINTA PEQUEÑA',
          parentMachineId: 1,
        ),
        SystemMachine(
          id: 3,
          name: 'Cinta 2',
          type: 'CINTA PEQUEÑA',
          parentMachineId: 1,
        ),
        SystemMachine(
          id: 4,
          name: 'Brazo 1',
          type: 'BRAZO SCARA',
          parentMachineId: 1,
        ),
        SystemMachine(
          id: 5,
          name: 'Brazo 2',
          type: 'BRAZO SCARA',
          parentMachineId: 1,
        ),
      ],
    );

    expect(MachineConfigurationValidator.validate(configuration), isNull);
  });

  test('allows long motor and servo keys and negative movement values', () {
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: 1, name: 'Línea', type: 'SISTEMA'),
      motors: [
        Motor(
          id: 1,
          systemMachineId: 1,
          key: 'MOTOR-NORTE',
          keySensorRight: 'SENSOR-DERECHO',
          keySensorLeft: null,
          speed: 5000,
          maxStepsRight: '-120',
          maxStepsLeft: '300',
        ),
      ],
      servos: [Servo(id: 1, machineId: 1, key: 'SERVO-PINZA', maxOpen: -45)],
    );

    expect(MachineConfigurationValidator.validate(configuration), isNull);
  });

  test('rejects zero or negative motor speed', () {
    final configuration = MachineConfiguration(
      machine: SystemMachine(id: 1, name: 'Línea', type: 'SISTEMA'),
      motors: [
        Motor(
          id: 1,
          systemMachineId: 1,
          key: 'M',
          keySensorRight: null,
          keySensorLeft: null,
          speed: 0,
          maxStepsRight: '-120',
          maxStepsLeft: null,
        ),
      ],
    );

    expect(
      MachineConfigurationValidator.validate(configuration),
      'La velocidad debe estar entre 100 y 10000 y los límites de movimiento ser enteros.',
    );
  });
}
