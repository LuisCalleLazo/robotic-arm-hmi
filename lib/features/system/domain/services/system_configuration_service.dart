import 'dart:async';

import '../entities/machine_configuration.dart';
import '../entities/process.dart';
import '../entities/process_motors.dart';
import '../entities/process_servo.dart';
import '../entities/system_machine.dart';
import '../repositories/system_repository.dart';

class SystemConfigurationService {
  SystemConfigurationService({required SystemRepository system})
    : _system = system;

  final SystemRepository _system;
  final _sensorCatalogChanges = StreamController<void>.broadcast();
  final _machineCatalogChanges = StreamController<void>.broadcast();
  final _processChanges = StreamController<void>.broadcast();

  Stream<void> get sensorCatalogChanges => _sensorCatalogChanges.stream;
  Stream<void> get machineCatalogChanges => _machineCatalogChanges.stream;
  Stream<void> get processChanges => _processChanges.stream;

  Future<void> saveMachine(MachineConfiguration configuration) async {
    final error = MachineConfigurationValidator.validate(configuration);
    if (error != null) throw StateError(error);

    final existingMachines = await _system.getMachines();
    final existingMotors = await _system.getMotors();
    final existingServos = await _system.getServos();
    final existingSensors = await _system.getSensors();
    final componentIds = configuration.components
        .map((item) => item.id)
        .toSet();
    final motorIds = configuration.motors.map((item) => item.id).toSet();
    final servoIds = configuration.servos.map((item) => item.id).toSet();
    final sensorIds = configuration.sensors.map((item) => item.id).toSet();

    for (final component in existingMachines.where(
      (item) =>
          item.parentMachineId == configuration.machine.id &&
          !componentIds.contains(item.id),
    )) {
      await _system.deleteMachineTree(component.id);
    }
    for (final motor in existingMotors.where(
      (item) =>
          (item.systemMachineId == configuration.machine.id ||
              componentIds.contains(item.systemMachineId)) &&
          !motorIds.contains(item.id),
    )) {
      await _system.deleteMotor(motor.id);
    }
    for (final servo in existingServos.where(
      (item) =>
          (item.machineId == configuration.machine.id ||
              componentIds.contains(item.machineId)) &&
          !servoIds.contains(item.id),
    )) {
      await _system.deleteServo(servo.id);
    }
    for (final sensor in existingSensors.where(
      (item) =>
          (item.machineId == configuration.machine.id ||
              componentIds.contains(item.machineId)) &&
          !sensorIds.contains(item.id),
    )) {
      await _system.deleteSensor(sensor.id);
    }

    await _system.saveMachine(configuration.machine);
    for (final component in configuration.components) {
      await _system.saveMachine(component);
    }
    for (final sensor in configuration.sensors) {
      await _system.saveSensor(sensor);
    }
    for (final motor in configuration.motors) {
      await _system.saveMotor(motor);
    }
    for (final servo in configuration.servos) {
      await _system.saveServo(servo);
    }
    _machineCatalogChanges.add(null);
    _sensorCatalogChanges.add(null);
  }

  Future<void> saveProcessDefinition(Process process) async {
    final error = await _validateProcessDefinition(process);
    if (error != null) throw StateError(error);
    await _system.saveProcess(process);
    _processChanges.add(null);
  }

  Future<void> saveProcessConfiguration({
    required Process process,
    required List<ProcessMotors> motors,
    required List<ProcessServo> servos,
  }) async {
    final error = await _validateProcessConfiguration(process, motors, servos);
    if (error != null) throw StateError(error);

    final existingMotors = await _system.getProcessMotors(process.id);
    final motorIds = motors.map((item) => item.id).toSet();
    for (final item in existingMotors.where(
      (item) => !motorIds.contains(item.id),
    )) {
      if (await _system.hasProcessMotorHistory(item.id)) {
        throw StateError(
          'No se puede eliminar el movimiento ${item.name}: tiene históricos asociados.',
        );
      }
      await _system.deleteProcessMotor(item.id);
    }
    final existingServos = await _system.getProcessServos(process.id);
    final servoIds = servos.map((item) => item.id).toSet();
    for (final item in existingServos.where(
      (item) => !servoIds.contains(item.id),
    )) {
      await _system.deleteProcessServo(item.id);
    }

    await _system.saveProcess(process);
    for (final motor in motors) {
      await _system.saveProcessMotor(motor);
    }
    for (final servo in servos) {
      await _system.saveProcessServo(servo);
    }
    _processChanges.add(null);
  }

  Future<void> deleteProcess(int processId) async {
    if (await _system.hasProcessHistory(processId)) {
      throw StateError(
        'No se puede eliminar el proceso porque tiene históricos asociados.',
      );
    }
    await _system.deleteProcess(processId);
    _processChanges.add(null);
  }

  Future<void> publishSystemLayout() async {
    _machineCatalogChanges.add(null);
  }

  Future<String?> _validateProcessDefinition(Process process) async {
    if (process.name.trim().isEmpty) {
      return 'El proceso requiere un nombre.';
    }
    final machineId = process.machineId;
    if (machineId == null) return 'Selecciona la máquina del proceso.';
    final machines = await _system.getMachines();
    if (!machines.any((machine) => machine.id == machineId)) {
      return 'La máquina seleccionada ya no existe.';
    }
    final topic = process.mqttTopic?.trim();
    final message = process.mqttExpectedMessage;
    if ((topic == null) != (message == null)) {
      return 'Configura tanto el topic como el mensaje esperado de MQTT.';
    }
    if (topic != null && topic.isEmpty) {
      return 'El topic MQTT no puede estar vacío.';
    }
    if (message != null && message.isEmpty) {
      return 'El mensaje MQTT esperado no puede estar vacío.';
    }
    return null;
  }

  Future<String?> _validateProcessConfiguration(
    Process process,
    List<ProcessMotors> motors,
    List<ProcessServo> servos,
  ) async {
    if (process.name.trim().isEmpty) {
      return 'El proceso requiere un nombre.';
    }
    if (motors.isEmpty && servos.isEmpty) {
      return 'El proceso debe contener al menos un movimiento.';
    }
    if (!motors.any((item) => item.order == 0) &&
        !servos.any((item) => item.order == 0)) {
      return 'El proceso debe iniciar con un movimiento de orden 0.';
    }
    if (motors.any(
      (item) =>
          item.processId != process.id ||
          item.order < 0 ||
          !item.steps.isFinite ||
          item.steps.truncateToDouble() != item.steps ||
          !item.speed.isFinite ||
          item.speed.truncateToDouble() != item.speed ||
          item.speed < 100 ||
          item.speed > 10000,
    )) {
      return 'Los movimientos de motor requieren pasos enteros y velocidad de 100 a 10000.';
    }
    if (servos.any(
      (item) =>
          item.processId != process.id ||
          item.order < 0 ||
          !item.openValue.isFinite ||
          item.openValue.truncateToDouble() != item.openValue ||
          item.openValue < 0 ||
          item.openValue > 180 ||
          !item.speed.isFinite ||
          item.speed.truncateToDouble() != item.speed ||
          item.speed < 0 ||
          item.speed > 720,
    )) {
      return 'Los servos requieren ángulo entero de 0 a 180 y velocidad de 0 a 720.';
    }

    final definitionError = await _validateProcessDefinition(process);
    if (definitionError != null) return definitionError;
    final machines = await _system.getMachines();
    final machineIds = _machineIds(machines, process.machineId!);
    final motorsById = {
      for (final motor in await _system.getMotors()) motor.id: motor,
    };
    final servosById = {
      for (final servo in await _system.getServos()) servo.id: servo,
    };
    if (motors.any(
      (item) =>
          !motorsById.containsKey(item.motorId) ||
          !machineIds.contains(motorsById[item.motorId]!.systemMachineId),
    )) {
      return 'Los motores deben existir y pertenecer a la máquina del proceso.';
    }
    if (servos.any(
      (item) =>
          !servosById.containsKey(item.servoId) ||
          !machineIds.contains(servosById[item.servoId]!.machineId),
    )) {
      return 'Los servos deben existir y pertenecer a la máquina del proceso.';
    }
    final seenCommands = <(int, String)>{};
    for (final item in motors) {
      final key = motorsById[item.motorId]!.key.trim().toUpperCase();
      if (!seenCommands.add((item.order, key))) {
        return 'No se puede ordenar el mismo actuador dos veces en un paso.';
      }
    }
    for (final item in servos) {
      final key = servosById[item.servoId]!.key.trim().toUpperCase();
      if (!seenCommands.add((item.order, key))) {
        return 'No se puede ordenar el mismo actuador dos veces en un paso.';
      }
    }
    return null;
  }

  Set<int> _machineIds(List<SystemMachine> machines, int machineId) => {
    machineId,
    ...machines
        .where((machine) => machine.parentMachineId == machineId)
        .map((machine) => machine.id),
  };

  Future<void> dispose() async {
    await _sensorCatalogChanges.close();
    await _machineCatalogChanges.close();
    await _processChanges.close();
  }
}
