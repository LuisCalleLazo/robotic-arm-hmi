import 'dart:async';

import '../../../peer_to_peer/domain/entities/peer_entities.dart';
import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../entities/machine_configuration.dart';
import '../entities/process.dart';
import '../entities/process_motors.dart';
import '../entities/process_servo.dart';
import '../entities/system_machine.dart';
import '../repositories/system_repository.dart';
import 'arduino_process_command_builder.dart';

class SystemConfigurationService {
  SystemConfigurationService({
    required PeerRepository peer,
    required SystemRepository system,
  }) : _peer = peer,
       _system = system {
    _messageSub = _peer.messages.listen(_onPeerMessage);
    _sessionSub = _peer.sessionStream.listen(_onSession);
  }

  final PeerRepository _peer;
  final SystemRepository _system;
  final Map<String, int> _machineByClient = {};
  final Map<String, MachineConfiguration> _configurationByClient = {};
  final Map<int, Process> _localSlaveProcesses = {};
  final Map<int, List<ProcessMotors>> _localSlaveProcessMotors = {};
  final Map<int, List<ProcessServo>> _localSlaveProcessServos = {};
  late final StreamSubscription<PeerMessage> _messageSub;
  late final StreamSubscription<PeerSession> _sessionSub;

  MachineConfiguration? get localSlaveConfiguration =>
      _configurationByClient['local'];
  List<Process> get localSlaveProcesses =>
      List.unmodifiable(_localSlaveProcesses.values);

  List<ProcessMotors> localSlaveProcessMotors(int processId) =>
      List.unmodifiable(_localSlaveProcessMotors[processId] ?? const []);

  List<ProcessServo> localSlaveProcessServos(int processId) =>
      List.unmodifiable(_localSlaveProcessServos[processId] ?? const []);

  void _onSession(PeerSession session) {
    if (!session.isActive) {
      _machineByClient.clear();
      return;
    }
    if (session.isMaster) {
      final connected = session.clients.map((client) => client.id).toSet();
      _machineByClient.removeWhere(
        (clientId, _) => clientId != 'local' && !connected.contains(clientId),
      );
    }
  }

  Future<void> saveMachine(MachineConfiguration configuration) async {
    final error = MachineConfigurationValidator.validate(configuration);
    if (error != null) throw StateError(error);
    if (_peer.session.isSlave) {
      final previous = _configurationByClient['local'];
      if (_machineByClient['local'] != null &&
          _machineByClient['local'] != configuration.machine.id) {
        throw StateError('Un esclavo solo puede administrar una máquina.');
      }
      if (previous != null &&
          !_preservesConfiguredItems(previous, configuration)) {
        throw StateError(
          'Un esclavo no puede eliminar máquinas o componentes.',
        );
      }
      await _peer.send(
        PeerMessage(
          type: PeerMessageType.configuration,
          payload: {'kind': 'machine', 'configuration': configuration.toJson()},
        ),
      );
      _machineByClient['local'] = configuration.machine.id;
      _configurationByClient['local'] = configuration;
      return;
    }
    _ensureMaster();
    await _saveLocal(configuration);
  }

  Future<void> saveProcessConfiguration({
    required Process process,
    required List<ProcessMotors> motors,
    required List<ProcessServo> servos,
  }) async {
    final error = await _validateProcessConfiguration(process, motors, servos);
    if (error != null) throw StateError(error);
    final payload = {
      'kind': 'process',
      'process': {
        'id': process.id,
        'name': process.name,
        'order': process.order,
        'activationSensorId': process.activationSensorId,
        'machineId': process.machineId,
      },
      'motors': motors
          .map(
            (item) => {
              'id': item.id,
              'processId': item.processId,
              'motorId': item.motorId,
              'name': item.name,
              'order': item.order,
              'steps': item.steps,
              'speed': item.speed,
            },
          )
          .toList(),
      'servos': servos
          .map(
            (item) => {
              'id': item.id,
              'processId': item.processId,
              'servoId': item.servoId,
              'name': item.name,
              'order': item.order,
              'openValue': item.openValue,
              'speed': item.speed,
            },
          )
          .toList(),
    };
    if (_peer.session.isSlave) {
      if (!_preservesProcessMovements(process.id, motors, servos)) {
        throw StateError('El esclavo no puede eliminar movimientos.');
      }
      await _peer.send(
        PeerMessage(type: PeerMessageType.configuration, payload: payload),
      );
      _localSlaveProcesses[process.id] = process;
      _localSlaveProcessMotors[process.id] = List.of(motors);
      _localSlaveProcessServos[process.id] = List.of(servos);
      return;
    }
    _ensureMaster();
    await _saveProcess(process, motors, servos);
  }

  Future<void> saveProcessDefinition(Process process) async {
    final error = await _validateProcessDefinition(process);
    if (error != null) throw StateError(error);
    if (_peer.session.isSlave) {
      await _peer.send(
        PeerMessage(
          type: PeerMessageType.configuration,
          payload: {
            'kind': 'process_definition',
            'process': _processPayload(process),
          },
        ),
      );
      _localSlaveProcesses[process.id] = process;
      return;
    }
    _ensureMaster();
    await _system.saveProcess(process);
  }

  Future<void> _onPeerMessage(PeerMessage message) async {
    if (!_peer.session.isMaster ||
        message.type != PeerMessageType.configuration) {
      return;
    }
    final kind = message.payload['kind'];
    if (kind == 'process_definition') {
      await _onProcessDefinitionMessage(message);
      return;
    }
    if (kind == 'process') {
      await _onProcessMessage(message);
      return;
    }
    if (kind != 'machine') return;

    final clientId = message.senderId;
    if (clientId == null) return;
    final configuration = MachineConfiguration.fromPayload(
      message.payload['configuration'],
    );
    if (configuration == null) {
      await _reject(clientId, 'Configuración de máquina inválida.');
      return;
    }
    final error = MachineConfigurationValidator.validate(configuration);
    final previous =
        _configurationByClient[clientId] ??
        await _loadExistingConfiguration(configuration.machine.id);
    final deletionError =
        previous != null && !_preservesConfiguredItems(previous, configuration)
        ? 'Un esclavo no puede eliminar máquinas o componentes.'
        : null;
    if (error != null ||
        deletionError != null ||
        (_machineByClient.containsKey(clientId) &&
            _machineByClient[clientId] != configuration.machine.id)) {
      await _reject(
        clientId,
        error ??
            deletionError ??
            'Un esclavo solo puede administrar una máquina.',
      );
      return;
    }
    await _saveLocal(configuration);
    _machineByClient[clientId] = configuration.machine.id;
    _configurationByClient[clientId] = configuration;
  }

  Future<void> _onProcessMessage(PeerMessage message) async {
    final raw = message.payload['process'];
    if (raw is! Map) return;
    final process = _processFromPayload(raw);
    final motors = _mapList(message.payload['motors'])
        .map(
          (item) => ProcessMotors(
            id: _int(item['id']),
            processId: _int(item['processId'], process.id),
            motorId: _int(item['motorId']),
            name: '${item['name'] ?? ''}',
            order: _int(item['order']),
            steps: _double(item['steps']),
            speed: _double(item['speed'], 5000),
          ),
        )
        .toList();
    final servos = _mapList(message.payload['servos'])
        .map(
          (item) => ProcessServo(
            id: _int(item['id']),
            processId: _int(item['processId'], process.id),
            servoId: _int(item['servoId']),
            name: '${item['name'] ?? ''}',
            order: _int(item['order']),
            openValue: _double(item['openValue']),
            speed: _double(item['speed'], 60),
          ),
        )
        .toList();
    final error = await _validateProcessConfiguration(process, motors, servos);
    if (error != null) {
      final senderId = message.senderId;
      if (senderId != null) await _reject(senderId, error);
      return;
    }
    final existingMotors = await _system.getProcessMotors(process.id);
    final existingServos = await _system.getProcessServos(process.id);
    if (!_preservesProcessMovements(
      process.id,
      motors,
      servos,
      previousMotors: existingMotors,
      previousServos: existingServos,
    )) {
      final senderId = message.senderId;
      if (senderId != null) {
        await _reject(senderId, 'El esclavo no puede eliminar movimientos.');
      }
      return;
    }
    await _saveProcess(process, motors, servos);
  }

  Future<void> _onProcessDefinitionMessage(PeerMessage message) async {
    final raw = message.payload['process'];
    if (raw is! Map) return;
    final process = _processFromPayload(raw);
    final error = await _validateProcessDefinition(process);
    if (error != null) {
      final senderId = message.senderId;
      if (senderId != null) await _reject(senderId, error);
      return;
    }
    await _system.saveProcess(process);
  }

  Future<String?> _validateProcessDefinition(Process process) async {
    if (process.name.trim().isEmpty || process.order < 0) {
      return 'El proceso requiere un nombre y un orden válido.';
    }
    final machineId = process.machineId;
    if (machineId == null) return 'Selecciona la máquina del proceso.';
    if (_peer.session.isSlave) {
      final configuration = _configurationByClient['local'];
      if (configuration == null || configuration.machine.id != machineId) {
        return 'El proceso debe pertenecer a la máquina del esclavo.';
      }
      if (process.activationSensorId != null &&
          !configuration.sensors.any(
            (sensor) => sensor.id == process.activationSensorId,
          )) {
        return 'El sensor debe pertenecer a la máquina seleccionada.';
      }
      return null;
    }
    final machines = await _system.getMachines();
    if (!machines.any((machine) => machine.id == machineId)) {
      return 'La máquina seleccionada ya no existe.';
    }
    final machineIds = _machineIds(machines, machineId);
    final sensorId = process.activationSensorId;
    if (sensorId != null) {
      final sensors = await _system.getSensors();
      final sensor = sensors.where((item) => item.id == sensorId).firstOrNull;
      if (sensor == null ||
          (sensor.machineId != null &&
              !machineIds.contains(sensor.machineId))) {
        return 'El sensor debe pertenecer a la máquina seleccionada.';
      }
    }
    return null;
  }

  Future<String?> _validateProcessConfiguration(
    Process process,
    List<ProcessMotors> motors,
    List<ProcessServo> servos,
  ) async {
    if (process.name.trim().isEmpty || process.order < 0) {
      return 'El proceso requiere un nombre y un orden válido.';
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
    if (_peer.session.isSlave) {
      final configuration = _configurationByClient['local'];
      if (configuration == null ||
          configuration.machine.id != process.machineId) {
        return 'El proceso debe pertenecer a la máquina del esclavo.';
      }
      if (process.activationSensorId != null &&
          !configuration.sensors.any(
            (sensor) => sensor.id == process.activationSensorId,
          )) {
        return 'El sensor de activación no existe en la máquina del esclavo.';
      }
      if (motors.any(
        (item) =>
            !configuration.motors.any((motor) => motor.id == item.motorId),
      )) {
        return 'El proceso referencia un motor que no pertenece a la máquina.';
      }
      if (servos.any(
        (item) =>
            !configuration.servos.any((servo) => servo.id == item.servoId),
      )) {
        return 'El proceso referencia un servo que no pertenece a la máquina.';
      }
    } else if (_peer.session.isMaster) {
      final machines = await _system.getMachines();
      if (process.machineId != null &&
          !machines.any((machine) => machine.id == process.machineId)) {
        return 'La máquina del proceso ya no existe.';
      }
      final machineIds = process.machineId == null
          ? null
          : _machineIds(machines, process.machineId!);
      if (process.machineId != null && machineIds!.isEmpty) {
        return 'La máquina del proceso ya no existe.';
      }
      final sensors = await _system.getSensors();
      if (process.activationSensorId != null) {
        final sensor = sensors
            .where((item) => item.id == process.activationSensorId)
            .firstOrNull;
        if (sensor == null) return 'El sensor de activación no existe.';
        if (process.machineId != null &&
            sensor.machineId != null &&
            !machineIds!.contains(sensor.machineId)) {
          return 'El sensor debe pertenecer a la máquina del proceso.';
        }
      }
      final availableMotors = await _system.getMotors();
      final motorById = {for (final motor in availableMotors) motor.id: motor};
      if (motors.any((item) => !motorById.containsKey(item.motorId))) {
        return 'El proceso referencia un motor que no existe.';
      }
      if (process.machineId != null &&
          motors.any(
            (item) =>
                !machineIds!.contains(motorById[item.motorId]!.systemMachineId),
          )) {
        return 'Los motores deben pertenecer a la máquina del proceso.';
      }
      final availableServos = await _system.getServos();
      final servoById = {for (final servo in availableServos) servo.id: servo};
      if (servos.any((item) => !servoById.containsKey(item.servoId))) {
        return 'El proceso referencia un servo que no existe.';
      }
      if (process.machineId != null &&
          servos.any(
            (item) => !machineIds!.contains(servoById[item.servoId]!.machineId),
          )) {
        return 'Los servos deben pertenecer a la máquina del proceso.';
      }
      final seenCommands = <(int, String)>{};
      for (final item in motors) {
        final key = ArduinoProcessCommandBuilder.commandKey(
          motorById[item.motorId]!.key,
        ).toUpperCase();
        if (!seenCommands.add((item.order, key))) {
          return 'No se puede ordenar el mismo actuador dos veces en un paso.';
        }
      }
      for (final item in servos) {
        final key = ArduinoProcessCommandBuilder.commandKey(
          servoById[item.servoId]!.key,
        ).toUpperCase();
        if (!seenCommands.add((item.order, key))) {
          return 'No se puede ordenar el mismo actuador dos veces en un paso.';
        }
      }
    }
    return null;
  }

  Future<void> _reject(String clientId, String message) => _peer.sendToClient(
    clientId,
    PeerMessage(
      type: PeerMessageType.error,
      payload: {'code': 'configuration_rejected', 'message': message},
    ),
  );

  Future<void> _saveLocal(MachineConfiguration configuration) async {
    final existing = await _system.getMachines();
    final componentIds = configuration.components
        .map((item) => item.id)
        .toSet();
    for (final item in existing.where(
      (item) =>
          item.parentMachineId == configuration.machine.id &&
          !componentIds.contains(item.id),
    )) {
      await _system.deleteMachine(item.id);
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
  }

  Future<MachineConfiguration?> _loadExistingConfiguration(
    int machineId,
  ) async {
    final machine = await _system.getMachine(machineId);
    if (machine == null) return null;
    final machines = await _system.getMachines();
    return MachineConfiguration(
      machine: machine,
      components: machines
          .where((item) => item.parentMachineId == machineId)
          .toList(),
      motors: (await _system.getMotors())
          .where((item) => item.systemMachineId == machineId)
          .toList(),
      sensors: (await _system.getSensors())
          .where((item) => item.machineId == machineId)
          .toList(),
      servos: (await _system.getServos())
          .where((item) => item.machineId == machineId)
          .toList(),
    );
  }

  Future<void> _saveProcess(
    Process process,
    List<ProcessMotors> motors,
    List<ProcessServo> servos,
  ) async {
    final existingMotors = await _system.getProcessMotors(process.id);
    final motorIds = motors.map((item) => item.id).toSet();
    for (final item in existingMotors.where(
      (item) => !motorIds.contains(item.id),
    )) {
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
  }

  bool _preservesProcessMovements(
    int processId,
    List<ProcessMotors> motors,
    List<ProcessServo> servos, {
    List<ProcessMotors>? previousMotors,
    List<ProcessServo>? previousServos,
  }) {
    final existingMotors =
        previousMotors ?? _localSlaveProcessMotors[processId] ?? const [];
    final existingServos =
        previousServos ?? _localSlaveProcessServos[processId] ?? const [];
    return motors.map((item) => item.id).toSet().containsAll(
          existingMotors.map((item) => item.id),
        ) &&
        servos.map((item) => item.id).toSet().containsAll(
          existingServos.map((item) => item.id),
        );
  }

  Map<String, dynamic> _processPayload(Process process) => {
    'id': process.id,
    'name': process.name,
    'order': process.order,
    'activationSensorId': process.activationSensorId,
    'machineId': process.machineId,
  };

  Process _processFromPayload(Map raw) => Process(
    id: _int(raw['id']),
    name: '${raw['name'] ?? ''}',
    order: _int(raw['order']),
    activationSensorId: _nullableInt(raw['activationSensorId']),
    machineId: _nullableInt(raw['machineId']),
  );

  Set<int> _machineIds(List<SystemMachine> machines, int machineId) => {
    machineId,
    ...machines
        .where((machine) => machine.parentMachineId == machineId)
        .map((machine) => machine.id),
  };

  bool _preservesConfiguredItems(
    MachineConfiguration previous,
    MachineConfiguration updated,
  ) {
    bool containsIds<T>(
      Iterable<T> previousItems,
      Iterable<T> updatedItems,
      int Function(T) idOf,
    ) {
      final previousIds = previousItems.map(idOf).toSet();
      final updatedIds = updatedItems.map(idOf).toSet();
      return updatedIds.containsAll(previousIds);
    }

    return previous.machine.id == updated.machine.id &&
        containsIds(
          previous.components,
          updated.components,
          (item) => item.id,
        ) &&
        containsIds(previous.motors, updated.motors, (item) => item.id) &&
        containsIds(previous.servos, updated.servos, (item) => item.id) &&
        containsIds(previous.sensors, updated.sensors, (item) => item.id);
  }

  void _ensureMaster() {
    if (!_peer.session.isMaster || !_peer.session.isActive) {
      throw StateError(
        'Solo el maestro puede guardar una configuración local.',
      );
    }
  }

  Future<void> dispose() async {
    await _messageSub.cancel();
    await _sessionSub.cancel();
  }

  static List<Map<String, dynamic>> _mapList(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];

  static int _int(Object? value, [int fallback = 0]) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

  static int? _nullableInt(Object? value) => value == null ? null : _int(value);

  static double _double(Object? value, [double fallback = 0]) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
}
