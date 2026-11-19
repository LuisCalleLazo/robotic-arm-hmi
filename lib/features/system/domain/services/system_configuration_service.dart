import 'dart:async';

import '../../../peer_to_peer/domain/entities/peer_entities.dart';
import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../entities/machine_configuration.dart';
import '../entities/process.dart';
import '../entities/process_motors.dart';
import '../entities/process_servo.dart';
import '../repositories/system_repository.dart';

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
  late final StreamSubscription<PeerMessage> _messageSub;
  late final StreamSubscription<PeerSession> _sessionSub;

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
      if (_machineByClient['local'] != null &&
          _machineByClient['local'] != configuration.machine.id) {
        throw StateError('Un esclavo solo puede administrar una máquina.');
      }
      await _peer.send(
        PeerMessage(
          type: PeerMessageType.configuration,
          payload: {'kind': 'machine', 'configuration': configuration.toJson()},
        ),
      );
      _machineByClient['local'] = configuration.machine.id;
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
    if (process.name.trim().isEmpty) {
      throw StateError('El nombre del proceso es obligatorio.');
    }
    final payload = {
      'kind': 'process',
      'process': {
        'id': process.id,
        'name': process.name,
        'order': process.order,
        'activationSensorId': process.activationSensorId,
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
            },
          )
          .toList(),
    };
    if (_peer.session.isSlave) {
      await _peer.send(
        PeerMessage(type: PeerMessageType.configuration, payload: payload),
      );
      return;
    }
    _ensureMaster();
    await _saveProcess(process, motors, servos);
  }

  Future<void> _onPeerMessage(PeerMessage message) async {
    if (!_peer.session.isMaster ||
        message.type != PeerMessageType.configuration) {
      return;
    }
    final kind = message.payload['kind'];
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
    if (error != null ||
        (_machineByClient.containsKey(clientId) &&
            _machineByClient[clientId] != configuration.machine.id)) {
      await _reject(
        clientId,
        error ?? 'Un esclavo solo puede administrar una máquina.',
      );
      return;
    }
    await _saveLocal(configuration);
    _machineByClient[clientId] = configuration.machine.id;
  }

  Future<void> _onProcessMessage(PeerMessage message) async {
    final raw = message.payload['process'];
    if (raw is! Map) return;
    final process = Process(
      id: _int(raw['id']),
      name: '${raw['name'] ?? ''}',
      order: _int(raw['order']),
      activationSensorId: _nullableInt(raw['activationSensorId']),
    );
    if (process.name.trim().isEmpty) return;
    final motors = _mapList(message.payload['motors'])
        .map(
          (item) => ProcessMotors(
            id: _int(item['id']),
            processId: _int(item['processId'], process.id),
            motorId: _int(item['motorId']),
            name: '${item['name'] ?? ''}',
            order: _int(item['order']),
            steps: _double(item['steps']),
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
          ),
        )
        .toList();
    await _saveProcess(process, motors, servos);
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

  Future<void> _saveProcess(
    Process process,
    List<ProcessMotors> motors,
    List<ProcessServo> servos,
  ) async {
    await _system.saveProcess(process);
    for (final motor in motors) {
      await _system.saveProcessMotor(motor);
    }
    for (final servo in servos) {
      await _system.saveProcessServo(servo);
    }
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

  static double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
