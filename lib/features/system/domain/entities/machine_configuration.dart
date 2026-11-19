import 'dart:convert';

import 'motor.dart';
import 'sensor.dart';
import 'servo.dart';
import 'system_machine.dart';

class MachineConfiguration {
  const MachineConfiguration({
    required this.machine,
    this.components = const [],
    this.motors = const [],
    this.sensors = const [],
    this.servos = const [],
  });

  final SystemMachine machine;
  final List<SystemMachine> components;
  final List<Motor> motors;
  final List<Sensor> sensors;
  final List<Servo> servos;

  Map<String, dynamic> toJson() => {
    'machine': {'id': machine.id, 'name': machine.name, 'type': machine.type},
    'components': components
        .map(
          (component) => {
            'id': component.id,
            'name': component.name,
            'type': component.type,
            'parentMachineId': component.parentMachineId,
          },
        )
        .toList(),
    'motors': motors
        .map(
          (motor) => {
            'id': motor.id,
            'machineId': motor.systemMachineId,
            'key': motor.key,
            'sensorRight': motor.keySensorRight,
            'sensorLeft': motor.keySensorLeft,
            'speed': motor.speed,
            'maxStepsRight': motor.maxStepsRight,
            'maxStepsLeft': motor.maxStepsLeft,
          },
        )
        .toList(),
    'sensors': sensors
        .map(
          (sensor) => {
            'id': sensor.id,
            'machineId': sensor.machineId,
            'key': sensor.key,
            'name': sensor.name,
          },
        )
        .toList(),
    'servos': servos
        .map(
          (servo) => {
            'id': servo.id,
            'machineId': servo.machineId,
            'key': servo.key,
            'maxOpen': servo.maxOpen,
          },
        )
        .toList(),
  };

  String encode() => jsonEncode(toJson());

  static MachineConfiguration? fromPayload(Object? raw) {
    if (raw is! Map) return null;
    final machineRaw = raw['machine'];
    if (machineRaw is! Map) return null;
    final machine = SystemMachine(
      id: _int(machineRaw['id']),
      name: '${machineRaw['name'] ?? ''}',
      type: '${machineRaw['type'] ?? ''}',
    );
    final components = _list(raw['components'])
        .map(
          (item) => SystemMachine(
            id: _int(item['id']),
            name: '${item['name'] ?? ''}',
            type: '${item['type'] ?? ''}',
            parentMachineId: _nullableInt(item['parentMachineId']),
          ),
        )
        .toList();
    final motors = _list(raw['motors']).map((item) {
      return Motor(
        id: _int(item['id']),
        systemMachineId: _int(item['machineId'], machine.id),
        key: '${item['key'] ?? ''}',
        keySensorRight: item['sensorRight'] as String?,
        keySensorLeft: item['sensorLeft'] as String?,
        speed: _double(item['speed']),
        maxStepsRight: item['maxStepsRight']?.toString(),
        maxStepsLeft: item['maxStepsLeft']?.toString(),
      );
    }).toList();
    final sensors = _list(raw['sensors']).map((item) {
      return Sensor(
        id: _int(item['id']),
        machineId: _nullableInt(item['machineId']),
        key: '${item['key'] ?? ''}',
        name: '${item['name'] ?? ''}',
      );
    }).toList();
    final servos = _list(raw['servos']).map((item) {
      return Servo(
        id: _int(item['id']),
        machineId: _int(item['machineId'], machine.id),
        key: '${item['key'] ?? ''}',
        maxOpen: _double(item['maxOpen']),
      );
    }).toList();
    return MachineConfiguration(
      machine: machine,
      components: components,
      motors: motors,
      sensors: sensors,
      servos: servos,
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];

  static int _int(Object? value, [int fallback = 0]) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

  static int? _nullableInt(Object? value) => value == null ? null : _int(value);

  static double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class MachineConfigurationValidator {
  const MachineConfigurationValidator._();

  static String? validate(MachineConfiguration configuration) {
    final machine = configuration.machine;
    if (machine.name.trim().isEmpty) {
      return 'El nombre de la máquina es obligatorio.';
    }
    final type = machine.type.trim().toUpperCase();
    if (type.isEmpty) return 'Selecciona el tipo de máquina.';
    final components = configuration.components;
    final largeBelts = components
        .where((component) => isLargeBelt(component.type))
        .length;
    if (largeBelts > 1) {
      return 'Una máquina no puede tener más de una cinta grande.';
    }
    if (components.any(
      (component) =>
          component.name.trim().isEmpty ||
          component.type.trim().isEmpty ||
          component.parentMachineId != machine.id,
    )) {
      return 'Cada componente debe tener nombre y tipo.';
    }
    if (configuration.motors.any((motor) => motor.key.trim().isEmpty)) {
      return 'Cada motor debe tener una clave.';
    }
    if (configuration.motors.any(
      (motor) =>
          motor.keySensorRight?.trim().isEmpty == true ||
          motor.keySensorLeft?.trim().isEmpty == true,
    )) {
      return 'Las claves de sensores del motor no pueden estar vacías.';
    }
    if (configuration.motors.any(
      (motor) =>
          !motor.speed.isFinite ||
          motor.speed.truncateToDouble() != motor.speed ||
          motor.speed < 100 ||
          motor.speed > 10000 ||
          !_validOptionalMovement(motor.maxStepsRight) ||
          !_validOptionalMovement(motor.maxStepsLeft),
    )) {
      return 'La velocidad debe estar entre 100 y 10000 y los límites de movimiento ser enteros.';
    }
    if (_hasDuplicate(configuration.motors.map((motor) => motor.key))) {
      return 'No puede haber claves de motor duplicadas.';
    }
    if (configuration.sensors.any(
      (sensor) => sensor.key.trim().isEmpty || sensor.name.trim().isEmpty,
    )) {
      return 'Cada sensor debe tener clave y nombre.';
    }
    if (configuration.sensors.any(
      (sensor) => sensor.machineId != null && sensor.machineId != machine.id,
    )) {
      return 'Los sensores deben pertenecer a la máquina configurada.';
    }
    if (_hasDuplicate(configuration.sensors.map((sensor) => sensor.key))) {
      return 'No puede haber claves de sensor duplicadas.';
    }
    if (configuration.servos.any((servo) => servo.key.trim().isEmpty)) {
      return 'Cada servo debe tener una clave.';
    }
    if (configuration.servos.any((servo) => !servo.maxOpen.isFinite)) {
      return 'El valor de movimiento del servo no es válido.';
    }
    if (_hasDuplicate(configuration.servos.map((servo) => servo.key))) {
      return 'No puede haber claves de servo duplicadas.';
    }
    return null;
  }

  static bool isLargeBelt(String type) =>
      type.trim().toUpperCase() == 'CINTA GRANDE';

  static bool _validOptionalMovement(String? value) =>
      value == null || int.tryParse(value.trim()) != null;

  static bool _hasDuplicate(Iterable<String> values) {
    final keys = values.map((value) => value.trim().toUpperCase()).toList();
    return keys.toSet().length != keys.length;
  }
}
