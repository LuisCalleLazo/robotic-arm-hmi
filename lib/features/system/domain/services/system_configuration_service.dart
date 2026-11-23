import 'dart:async';

import '../../../peer_to_peer/domain/entities/peer_entities.dart';
import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../entities/machine_configuration.dart';
import '../entities/motor.dart';
import '../entities/process.dart';
import '../entities/process_motors.dart';
import '../entities/process_servo.dart';
import '../entities/sensor.dart';
import '../entities/servo.dart';
import '../entities/system_machine.dart';
import '../entities/system_position.dart';
import '../repositories/system_repository.dart';
import '../repositories/system_position_repository.dart';
import 'arduino_process_command_builder.dart';

class SystemConfigurationService {
  SystemConfigurationService({
    required this._peer,
    required this._system,
    this.positions,
  }) {
    _messageSub = _peer.messages.listen(_onPeerMessage);
    _sessionSub = _peer.sessionStream.listen(_onSession);
    _onSession(_peer.session);
  }

  final PeerRepository _peer;
  final SystemRepository _system;
  final SystemPositionRepository? positions;
  final Map<String, int> _machineByClient = {};
  final Map<String, MachineConfiguration> _configurationByClient = {};
  final Map<int, Process> _localSlaveProcesses = {};
  final Map<int, List<ProcessMotors>> _localSlaveProcessMotors = {};
  final Map<int, List<ProcessServo>> _localSlaveProcessServos = {};
  final _sensorCatalogChanges = StreamController<void>.broadcast();
  final _processChanges = StreamController<void>.broadcast();
  List<Sensor> _sharedSensors = const [];
  List<SystemMachine> _sharedMachines = const [];
  List<Motor> _sharedMotors = const [];
  List<Servo> _sharedServos = const [];
  List<SystemPosition> _sharedPositions = const [];
  bool _sensorCatalogRequested = false;
  late final StreamSubscription<PeerMessage> _messageSub;
  late final StreamSubscription<PeerSession> _sessionSub;

  MachineConfiguration? get localSlaveConfiguration =>
      _configurationByClient['local'];
  List<Sensor> get sharedSensors {
    final sensors = <int, Sensor>{
      for (final sensor in _sharedSensors) sensor.id: sensor,
      for (final sensor
          in (_configurationByClient['local']?.sensors ?? const <Sensor>[]))
        sensor.id: sensor,
    };
    return List.unmodifiable(sensors.values);
  }

  List<SystemMachine> get sharedMachines {
    final machines = <int, SystemMachine>{
      for (final machine in _sharedMachines) machine.id: machine,
    };
    final configuration = _configurationByClient['local'];
    if (configuration != null) {
      machines[configuration.machine.id] = configuration.machine;
      for (final component in configuration.components) {
        machines[component.id] = component;
      }
    }
    return List.unmodifiable(machines.values);
  }

  List<Motor> get sharedMotors {
    final motors = <int, Motor>{
      for (final motor in _sharedMotors) motor.id: motor,
      for (final motor
          in (_configurationByClient['local']?.motors ?? const <Motor>[]))
        motor.id: motor,
    };
    return List.unmodifiable(motors.values);
  }

  List<Servo> get sharedServos {
    final servos = <int, Servo>{
      for (final servo in _sharedServos) servo.id: servo,
      for (final servo
          in (_configurationByClient['local']?.servos ?? const <Servo>[]))
        servo.id: servo,
    };
    return List.unmodifiable(servos.values);
  }

  List<SystemPosition> get sharedSystemPositions =>
      List.unmodifiable(_sharedPositions);

  Stream<void> get sensorCatalogChanges => _sensorCatalogChanges.stream;
  Stream<void> get processChanges => _processChanges.stream;
  List<Process> get localSlaveProcesses =>
      List.unmodifiable(_localSlaveProcesses.values);

  Future<void> publishSystemLayout() => _publishSensorCatalog();

  List<ProcessMotors> localSlaveProcessMotors(int processId) =>
      List.unmodifiable(_localSlaveProcessMotors[processId] ?? const []);

  List<ProcessServo> localSlaveProcessServos(int processId) =>
      List.unmodifiable(_localSlaveProcessServos[processId] ?? const []);

  void _onSession(PeerSession session) {
    if (!session.isActive) {
      _machineByClient.clear();
      _sensorCatalogRequested = false;
      return;
    }
    if (session.isSlave && !_sensorCatalogRequested) {
      _sensorCatalogRequested = true;
      unawaited(_requestSensorCatalog());
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
    await _publishSensorCatalog();
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

  Future<void> deleteProcess(int processId) async {
    _ensureMaster();
    if (await _system.hasProcessHistory(processId)) {
      throw StateError(
        'No se puede eliminar el proceso porque tiene históricos asociados.',
      );
    }
    await _system.deleteProcess(processId);
    await _peer.send(
      PeerMessage(
        type: PeerMessageType.telemetry,
        payload: {'kind': 'process_deleted', 'processId': processId},
      ),
    );
  }

  Future<void> _onPeerMessage(PeerMessage message) async {
    if (_peer.session.isSlave &&
        message.type == PeerMessageType.telemetry &&
        message.payload['kind'] == 'process_deleted') {
      final processId = _int(message.payload['processId']);
      _localSlaveProcesses.remove(processId);
      _localSlaveProcessMotors.remove(processId);
      _localSlaveProcessServos.remove(processId);
      _processChanges.add(null);
      return;
    }
    if (_peer.session.isSlave &&
        message.type == PeerMessageType.telemetry &&
        message.payload['kind'] == 'sensor_catalog') {
      _sharedSensors = _mapList(message.payload['sensors'])
          .map(
            (item) => Sensor(
              id: _int(item['id']),
              machineId: _nullableInt(item['machineId']),
              key: '${item['key'] ?? ''}',
              name: '${item['name'] ?? ''}',
            ),
          )
          .toList();
      _sharedMachines = _mapList(message.payload['machines'])
          .map(
            (item) => SystemMachine(
              id: _int(item['id']),
              name: '${item['name'] ?? ''}',
              type: '${item['type'] ?? ''}',
              parentMachineId: _nullableInt(item['parentMachineId']),
            ),
          )
          .toList();
      _sharedMotors = _mapList(message.payload['motors'])
          .map(
            (item) => Motor(
              id: _int(item['id']),
              systemMachineId: _int(item['systemMachineId']),
              key: '${item['key'] ?? ''}',
              keySensorRight: item['keySensorRight']?.toString(),
              keySensorLeft: item['keySensorLeft']?.toString(),
              speed: _double(item['speed']),
              maxStepsRight: item['maxStepsRight']?.toString(),
              maxStepsLeft: item['maxStepsLeft']?.toString(),
            ),
          )
          .toList();
      _sharedServos = _mapList(message.payload['servos'])
          .map(
            (item) => Servo(
              id: _int(item['id']),
              machineId: _int(item['machineId']),
              key: '${item['key'] ?? ''}',
              maxOpen: _double(item['maxOpen'], 180),
            ),
          )
          .toList();
      _sharedPositions = _mapList(message.payload['positions'])
          .map(
            (item) => SystemPosition(
              id: _int(item['id']),
              number: _int(item['number']),
              type: '${item['type'] ?? ''}',
              systemMachineId: _int(item['systemMachineId']),
            ),
          )
          .toList();
      _sensorCatalogChanges.add(null);
      return;
    }
    if (_peer.session.isMaster &&
        message.type == PeerMessageType.telemetry &&
        message.payload['kind'] == 'sensor_catalog_request') {
      final senderId = message.senderId;
      if (senderId != null) await _sendSensorCatalog(senderId);
      return;
    }
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
    await _publishSensorCatalog();
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
    if (process.name.trim().isEmpty) {
      return 'El proceso requiere un nombre.';
    }
    final machineId = process.machineId;
    if (machineId == null) return 'Selecciona la máquina del proceso.';
    if (_peer.session.isSlave) {
      final configuration = _configurationByClient['local'];
      if (configuration == null || configuration.machine.id != machineId) {
        return 'El proceso debe pertenecer a la máquina del esclavo.';
      }
      if (process.activationSensorId != null &&
          !sharedSensors.any(
            (sensor) => sensor.id == process.activationSensorId,
          )) {
        return 'El sensor de activación no existe.';
      }
      return null;
    }
    final machines = await _system.getMachines();
    if (!machines.any((machine) => machine.id == machineId)) {
      return 'La máquina seleccionada ya no existe.';
    }
    final sensorId = process.activationSensorId;
    if (sensorId != null) {
      final sensors = await _system.getSensors();
      final sensor = sensors.where((item) => item.id == sensorId).firstOrNull;
      if (sensor == null) return 'El sensor de activación no existe.';
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
    if (_peer.session.isSlave) {
      final configuration = _configurationByClient['local'];
      if (configuration == null ||
          configuration.machine.id != process.machineId) {
        return 'El proceso debe pertenecer a la máquina del esclavo.';
      }
      if (process.activationSensorId != null &&
          !sharedSensors.any(
            (sensor) => sensor.id == process.activationSensorId,
          )) {
        return 'El sensor de activación no existe.';
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

  Future<void> _requestSensorCatalog() async {
    if (!_peer.session.isSlave || !_peer.session.isActive) return;
    await _peer.send(
      PeerMessage(
        type: PeerMessageType.telemetry,
        payload: {'kind': 'sensor_catalog_request'},
      ),
    );
  }

  Future<void> _publishSensorCatalog() async {
    if (!_peer.session.isMaster) return;
    for (final client in _peer.session.clients) {
      await _sendSensorCatalog(client.id);
    }
  }

  Future<void> _sendSensorCatalog(String clientId) async {
    final sensors = await _system.getSensors();
    final machines = await _system.getMachines();
    final motors = await _system.getMotors();
    final servos = await _system.getServos();
    final positions = await this.positions?.getSystemPositions() ?? const [];
    await _peer.sendToClient(
      clientId,
      PeerMessage(
        type: PeerMessageType.telemetry,
        payload: {
          'kind': 'sensor_catalog',
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
          'machines': machines
              .map(
                (machine) => {
                  'id': machine.id,
                  'name': machine.name,
                  'type': machine.type,
                  'parentMachineId': machine.parentMachineId,
                },
              )
              .toList(),
          'motors': motors
              .map(
                (motor) => {
                  'id': motor.id,
                  'systemMachineId': motor.systemMachineId,
                  'key': motor.key,
                  'keySensorRight': motor.keySensorRight,
                  'keySensorLeft': motor.keySensorLeft,
                  'speed': motor.speed,
                  'maxStepsRight': motor.maxStepsRight,
                  'maxStepsLeft': motor.maxStepsLeft,
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
          'positions': positions
              .map(
                (position) => {
                  'id': position.id,
                  'number': position.number,
                  'type': position.type,
                  'systemMachineId': position.systemMachineId,
                },
              )
              .toList(),
        },
      ),
    );
  }

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
    final removedMotors = existingMotors.where(
      (item) => !motorIds.contains(item.id),
    );
    for (final item in removedMotors) {
      if (await _system.hasProcessMotorHistory(item.id)) {
        throw StateError(
          'No se puede eliminar el movimiento ${item.name}: tiene históricos asociados.',
        );
      }
    }
    for (final item in removedMotors) {
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
    return motors
            .map((item) => item.id)
            .toSet()
            .containsAll(existingMotors.map((item) => item.id)) &&
        servos
            .map((item) => item.id)
            .toSet()
            .containsAll(existingServos.map((item) => item.id));
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
    await _sensorCatalogChanges.close();
    await _processChanges.close();
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
