import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../../../system/domain/entities/motor.dart';
import '../../../system/domain/entities/sensor.dart';
import '../../../system/domain/entities/servo.dart';
import '../../../system/domain/entities/system_machine.dart';
import '../../../system/domain/entities/system_position.dart';
import '../../../system/domain/repositories/system_position_repository.dart';
import '../../../system/domain/repositories/system_repository.dart';
import '../../../system/domain/services/arduino_process_command_builder.dart';
import '../../../system/domain/services/system_configuration_service.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import 'scara_process_panel.dart';

class SystemOverviewPanel extends StatefulWidget {
  const SystemOverviewPanel({
    required this.canSendCommands,
    required this.serialConnected,
    required this.simulating,
    required this.telemetry,
    required this.onCommand,
    super.key,
  });

  final bool canSendCommands;
  final bool serialConnected;
  final bool simulating;
  final TelemetryCubit telemetry;
  final Future<void> Function(String command) onCommand;

  @override
  State<SystemOverviewPanel> createState() => _SystemOverviewPanelState();
}

class _SystemOverviewPanelState extends State<SystemOverviewPanel> {
  static const _largeBeltType = 'CINTA GRANDE';
  static const _smallBeltType = 'CINTA PEQUEÑA';
  static const _armType = 'BRAZO SCARA';

  List<SystemMachine> _machines = const [];
  List<Motor> _motors = const [];
  List<Servo> _servos = const [];
  List<Sensor> _sensors = const [];
  List<SystemPosition> _positions = const [];
  final Map<int, double> _motorPositions = {};
  final Map<int, double> _servoAngles = {};
  final Map<int, int> _motorDirections = {};
  final Set<int> _movingMotors = {};
  final Set<String> _activeSensorKeys = {};
  final List<_OverviewSlot> _slots = [];
  int? _largeBeltId;
  int _nextPositionId = 1;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  StreamSubscription<TelemetryLogEntry>? _lineSubscription;
  StreamSubscription<void>? _sensorCatalogSubscription;

  @override
  void initState() {
    super.initState();
    _lineSubscription = widget.telemetry.lineEvents.listen(_onLine);
    final peer = GetIt.I<PeerRepository>();
    _sensorCatalogSubscription = GetIt.I<SystemConfigurationService>()
        .sensorCatalogChanges
        .listen((_) {
          if (peer.session.isSlave) _load();
        });
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestTelemetry());
  }

  @override
  void didUpdateWidget(covariant SystemOverviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.telemetry != widget.telemetry) {
      _lineSubscription?.cancel();
      _lineSubscription = widget.telemetry.lineEvents.listen(_onLine);
    }
    if (!oldWidget.canSendCommands && widget.canSendCommands) {
      _requestTelemetry();
    }
  }

  @override
  void dispose() {
    _lineSubscription?.cancel();
    _sensorCatalogSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final peer = GetIt.I<PeerRepository>();
      final configuration = GetIt.I<SystemConfigurationService>();
      late final List<SystemMachine> machines;
      late final List<Motor> motors;
      late final List<Servo> servos;
      late final List<Sensor> sensors;
      late final List<SystemPosition> positions;
      if (peer.session.isSlave) {
        machines = configuration.sharedMachines;
        motors = configuration.sharedMotors;
        servos = configuration.sharedServos;
        sensors = configuration.sharedSensors;
        positions = configuration.sharedSystemPositions;
      } else {
        final repository = GetIt.I<SystemRepository>();
        machines = await repository.getMachines();
        motors = await repository.getMotors();
        servos = await repository.getServos();
        sensors = await repository.getSensors();
        positions = await GetIt.I<SystemPositionRepository>()
            .getSystemPositions();
      }
      if (!mounted) return;
      setState(() {
        _machines = machines;
        _motors = motors;
        _servos = servos;
        _sensors = sensors;
        _positions = positions;
        _nextPositionId =
            positions.fold<int>(
              0,
              (maxId, item) => item.id > maxId ? item.id : maxId,
            ) +
            1;
        _largeBeltId = _findPosition(
          positions,
          _largeBeltType,
          1,
        )?.systemMachineId;
        final cellNumbers = <int>{
          for (final item in positions)
            if (_isSmallBelt(item.type) || _isArm(item.type)) item.number,
        };
        _slots
          ..clear()
          ..addAll(
            (cellNumbers.toList()..sort()).map(
              (number) => _OverviewSlot(
                number: number,
                smallPosition: _findPosition(positions, _smallBeltType, number),
                armPosition: _findPosition(positions, _armType, number),
              ),
            ),
          );
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  SystemPosition? _findPosition(
    List<SystemPosition> positions,
    String type,
    int number,
  ) {
    for (final position in positions) {
      if (position.number == number && _sameType(position.type, type)) {
        return position;
      }
    }
    return null;
  }

  bool _sameType(String left, String right) =>
      _typeKey(left) == _typeKey(right);

  String _typeKey(String value) => value
      .toUpperCase()
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll(RegExp(r'[^A-Z]'), '');

  bool _isArm(String type) => _typeKey(type).contains('BRAZO');

  bool _isSmallBelt(String type) =>
      _typeKey(type).contains('CINTA') && _typeKey(type).contains('PEQUENA');

  bool _isLargeBelt(String type) =>
      _typeKey(type).contains('CINTA') && _typeKey(type).contains('GRANDE');

  Future<void> _requestTelemetry() async {
    if (!widget.canSendCommands ||
        !widget.serialConnected ||
        widget.simulating) {
      return;
    }
    try {
      await widget.onCommand('BCT100');
      await widget.onCommand('BC?');
    } catch (error) {
      _notify('No se pudo activar la telemetría del sistema: $error');
    }
  }

  List<SystemMachine> _machinesOf(bool Function(String) matches) =>
      _machines.where((machine) => matches(machine.type)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<SystemMachine> _availableMachines({
    required bool Function(String) matches,
    required int? selectedId,
    required Set<int> usedIds,
  }) => _machinesOf(matches)
      .where(
        (machine) => machine.id == selectedId || !usedIds.contains(machine.id),
      )
      .toList();

  Set<int> _selectedSmallBeltIds({_OverviewSlot? excluding}) => {
    for (final slot in _slots)
      if (!identical(slot, excluding) && slot.smallMachineId != null)
        slot.smallMachineId!,
  };

  Set<int> _selectedArmIds({_OverviewSlot? excluding}) => {
    for (final slot in _slots)
      if (!identical(slot, excluding) && slot.armMachineId != null)
        slot.armMachineId!,
  };

  Future<void> _saveLargeBelt(int? machineId) async {
    final oldPosition = _findPosition(_positions, _largeBeltType, 1);
    if (machineId == oldPosition?.systemMachineId) return;
    setState(() => _saving = true);
    try {
      final repository = GetIt.I<SystemPositionRepository>();
      if (machineId == null) {
        if (oldPosition != null) {
          await repository.deleteSystemPosition(oldPosition.id);
        }
      } else {
        await repository.saveSystemPosition(
          SystemPosition(
            id: oldPosition?.id ?? _nextPositionId++,
            number: 1,
            type: _largeBeltType,
            systemMachineId: machineId,
          ),
        );
      }
      await GetIt.I<SystemConfigurationService>().publishSystemLayout();
      await _load();
    } catch (error) {
      _notify('No se pudo guardar la cinta grande: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSlot(_OverviewSlot slot) async {
    setState(() => _saving = true);
    try {
      final repository = GetIt.I<SystemPositionRepository>();
      await _saveSlotPosition(
        repository,
        slot,
        type: _smallBeltType,
        machineId: slot.smallMachineId,
        oldPosition: slot.smallPosition,
      );
      await _saveSlotPosition(
        repository,
        slot,
        type: _armType,
        machineId: slot.armMachineId,
        oldPosition: slot.armPosition,
      );
      await GetIt.I<SystemConfigurationService>().publishSystemLayout();
      await _load();
    } catch (error) {
      _notify('No se pudo guardar la celda ${slot.number}: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSlotPosition(
    SystemPositionRepository repository,
    _OverviewSlot slot, {
    required String type,
    required int? machineId,
    required SystemPosition? oldPosition,
  }) async {
    if (machineId == null) {
      if (oldPosition != null) {
        await repository.deleteSystemPosition(oldPosition.id);
      }
      return;
    }
    if (machineId == oldPosition?.systemMachineId) return;
    await repository.saveSystemPosition(
      SystemPosition(
        id: oldPosition?.id ?? _nextPositionId++,
        number: slot.number,
        type: type,
        systemMachineId: machineId,
      ),
    );
  }

  Future<void> _deleteSlot(_OverviewSlot slot) async {
    setState(() => _saving = true);
    try {
      final repository = GetIt.I<SystemPositionRepository>();
      for (final position in [slot.smallPosition, slot.armPosition]) {
        if (position != null) {
          await repository.deleteSystemPosition(position.id);
        }
      }
      await GetIt.I<SystemConfigurationService>().publishSystemLayout();
      await _load();
    } catch (error) {
      _notify('No se pudo eliminar la celda ${slot.number}: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSlot() {
    final nextNumber =
        _slots.fold<int>(
          0,
          (maxNumber, slot) =>
              slot.number > maxNumber ? slot.number : maxNumber,
        ) +
        1;
    setState(() => _slots.add(_OverviewSlot(number: nextNumber)));
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _onLine(TelemetryLogEntry entry) {
    final line = entry.line.trim();
    if (line.isEmpty) return;
    if (entry.source == TelemetrySource.serialSent) {
      if (_updateSensors(line) && mounted) setState(() {});
      return;
    }
    var changed = _updateSensors(line);
    final fields = line.split(',');
    if (fields.length == 6 && fields.first.startsWith('BC')) {
      final motor = _motorForKey(fields.first);
      final position = double.tryParse(fields[2]);
      final velocity = double.tryParse(fields[4]);
      if (motor != null) {
        if (position != null) _motorPositions[motor.id] = position;
        if (velocity != null && velocity != 0) {
          _motorDirections[motor.id] = velocity.sign.toInt();
        }
        if (velocity == 0) {
          _movingMotors.remove(motor.id);
        } else {
          _movingMotors.add(motor.id);
        }
        changed = true;
      }
    } else if (line.startsWith('POS,')) {
      final armId = _slots
          .map((slot) => slot.armMachineId)
          .whereType<int>()
          .firstOrNull;
      if (armId != null) {
        for (final match in RegExp(r'([XYAZ])=(-?\d+)').allMatches(line)) {
          final axis = match.group(1)!;
          final motor = _axisMotor(armId, axis);
          final position = double.tryParse(match.group(2)!);
          if (motor != null && position != null) {
            _motorPositions[motor.id] = position;
            changed = true;
          }
        }
      }
    } else if (fields.length >= 5 && fields[0] == 'BC' && fields[1] == 'EVT') {
      final event = fields[2].toUpperCase();
      if (event == 'INICIO' && fields.length >= 5) {
        final motor = _motorForKey(fields[3]);
        final distance = double.tryParse(fields[4]);
        if (motor != null && distance != null) {
          _motorDirections[motor.id] = distance.sign.toInt();
          _movingMotors.add(motor.id);
          changed = true;
        }
      } else if ((event == 'FIN' || event == 'SENSOR') && fields.length >= 5) {
        final motor = _motorForKey(fields[3]);
        final position = double.tryParse(fields[4]);
        if (motor != null && position != null) {
          _motorPositions[motor.id] = position;
          _movingMotors.remove(motor.id);
          changed = true;
        }
      } else if (event == 'STOP' || event == 'SENSOR_BLOQUEADO') {
        _movingMotors.clear();
        changed = true;
      }
    } else if (fields.length >= 4 &&
        fields[0].startsWith('BC') &&
        fields[0] != 'BC') {
      final servoKey = fields[0].toUpperCase();
      final servo = _servos.where(
        (item) =>
            ArduinoProcessCommandBuilder.commandKey(item.key).toUpperCase() ==
            servoKey,
      );
      final angle = double.tryParse(fields[2]);
      if (servo.isNotEmpty && angle != null) {
        _servoAngles[servo.first.id] = angle;
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  bool _updateSensors(String line) {
    final normalized = line.toUpperCase();
    var changed = false;
    for (final sensor in _sensors) {
      final key = sensor.key.trim().toUpperCase();
      if (key.isEmpty) continue;
      if (normalized == '${key}1') {
        changed = _activeSensorKeys.add(key) || changed;
      } else if (normalized == '${key}0') {
        changed = _activeSensorKeys.remove(key) || changed;
      }
    }
    final fields = line.split(',');
    if (fields.length == 6 && fields.first.startsWith('BC')) {
      final motor = _motorForKey(fields.first);
      if (motor != null) {
        final active = int.tryParse(fields[5]) == 1;
        final direction = _motorDirections[motor.id] ?? 0;
        final sensorKey = direction >= 0
            ? motor.keySensorRight
            : motor.keySensorLeft;
        if (sensorKey != null) {
          if (active) {
            changed = _activeSensorKeys.add(sensorKey.toUpperCase()) || changed;
          } else {
            changed =
                _activeSensorKeys.remove(sensorKey.toUpperCase()) || changed;
          }
        }
      }
    } else if (fields.length >= 5 &&
        fields[0] == 'BC' &&
        fields[1] == 'EVT' &&
        fields[2] == 'SENSOR') {
      final motor = _motorForKey(fields[3]);
      if (motor != null) {
        final direction = _motorDirections[motor.id] ?? 0;
        final key = direction >= 0 ? motor.keySensorRight : motor.keySensorLeft;
        if (key != null) {
          changed = _activeSensorKeys.add(key.toUpperCase()) || changed;
        }
      }
    }
    return changed;
  }

  Motor? _motorForKey(String key) {
    final normalized = ArduinoProcessCommandBuilder.commandKey(
      key,
    ).toUpperCase();
    return _motors
        .where(
          (motor) =>
              ArduinoProcessCommandBuilder.commandKey(
                motor.key,
              ).toUpperCase() ==
              normalized,
        )
        .firstOrNull;
  }

  List<int> _machineAndComponentIds(int machineId) => {
    machineId,
    ..._machines
        .where((machine) => machine.parentMachineId == machineId)
        .map((machine) => machine.id),
  }.toList();

  Motor? _axisMotor(int machineId, String axis) {
    final machineIds = _machineAndComponentIds(machineId).toSet();
    return _motors
        .where(
          (motor) =>
              machineIds.contains(motor.systemMachineId) &&
              ArduinoProcessCommandBuilder.commandKey(
                motor.key,
              ).toUpperCase().endsWith(axis),
        )
        .firstOrNull;
  }

  double _normalizedMotorPosition(Motor? motor, String axis) {
    if (motor == null) return 0.5;
    final maxRight =
        double.tryParse(motor.maxStepsRight ?? '')?.abs() ??
        _defaultSteps(axis);
    final maxLeft =
        double.tryParse(motor.maxStepsLeft ?? '')?.abs() ?? _defaultSteps(axis);
    final total = maxRight + maxLeft;
    if (total <= 0) return 0.5;
    return (((_motorPositions[motor.id] ?? 0) + maxLeft) / total)
        .clamp(0, 1)
        .toDouble();
  }

  double _defaultSteps(String axis) => switch (axis) {
    'X' => 30450,
    'Y' => 11834,
    'A' => 3426,
    'Z' => 47829,
    _ => 10000,
  };

  double _normalizedGripper(int machineId) {
    final machineIds = _machineAndComponentIds(machineId).toSet();
    final servo = _servos
        .where((item) => machineIds.contains(item.machineId))
        .firstOrNull;
    if (servo == null) return 0.5;
    final maximum = servo.maxOpen.clamp(1, 180);
    return ((_servoAngles[servo.id] ?? 90) / maximum).clamp(0, 1).toDouble();
  }

  Sensor? _firstSensor(int machineId) {
    final machineIds = _machineAndComponentIds(machineId).toSet();
    final localSensors =
        _sensors
            .where(
              (sensor) =>
                  sensor.machineId != null &&
                  machineIds.contains(sensor.machineId),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (localSensors.isNotEmpty) return localSensors.first;
    return _sensors.where((sensor) => sensor.machineId == null).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('No se pudo cargar el sistema: $_error'));
    }
    return Column(
      children: [
        _configurationPanel(),
        Expanded(child: _systemBoard()),
      ],
    );
  }

  Widget _configurationPanel() {
    final largeBelts = _machinesOf(_isLargeBelt);
    final colors = Theme.of(context).colorScheme;
    final isSlave = GetIt.I<PeerRepository>().session.isSlave;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: ExpansionTile(
        initiallyExpanded: _positions.isEmpty,
        leading: Icon(Icons.tune, color: colors.primary),
        title: const Text('Distribución de máquinas'),
        subtitle: Text(
          'Una cinta grande · ${_slots.length} celdas de cinta pequeña y brazo',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (isSlave)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'La distribución se configura en el maestro.',
                textAlign: TextAlign.left,
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final field = DropdownButtonFormField<int?>(
                initialValue: _largeBeltId,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Seleccionar máquina',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sin asignar'),
                  ),
                  ...largeBelts.map(
                    (machine) => DropdownMenuItem<int?>(
                      value: machine.id,
                      child: Text(machine.name),
                    ),
                  ),
                ],
                onChanged: _saving || isSlave
                    ? null
                    : (id) => _saveLargeBelt(id),
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cinta grande',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    field,
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cinta grande',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 250, child: field),
                ],
              );
            },
          ),
          const Divider(height: 24),
          for (final slot in _slots) _slotConfiguration(slot, isSlave),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _saving || isSlave ? null : _addSlot,
              icon: const Icon(Icons.add),
              label: const Text('Agregar cinta pequeña y brazo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotConfiguration(_OverviewSlot slot, bool isSlave) {
    final smallMachines = _availableMachines(
      matches: _isSmallBelt,
      selectedId: slot.smallMachineId,
      usedIds: _selectedSmallBeltIds(excluding: slot),
    );
    final arms = _availableMachines(
      matches: _isArm,
      selectedId: slot.armMachineId,
      usedIds: _selectedArmIds(excluding: slot),
    );
    final smallBeltField = DropdownButtonFormField<int?>(
      initialValue: slot.smallMachineId,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Cinta pequeña',
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
        ...smallMachines.map(
          (machine) => DropdownMenuItem<int?>(
            value: machine.id,
            child: Text(machine.name),
          ),
        ),
      ],
      onChanged: _saving || isSlave
          ? null
          : (id) => setState(() => slot.smallMachineId = id),
    );
    final armField = DropdownButtonFormField<int?>(
      initialValue: slot.armMachineId,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Brazo SCARA',
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
        ...arms.map(
          (machine) => DropdownMenuItem<int?>(
            value: machine.id,
            child: Text(machine.name),
          ),
        ),
      ],
      onChanged: _saving || isSlave
          ? null
          : (id) => setState(() => slot.armMachineId = id),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Guardar celda',
          onPressed: _saving || isSlave ? null : () => _saveSlot(slot),
          icon: const Icon(Icons.save_outlined),
        ),
        IconButton(
          tooltip: 'Eliminar celda',
          onPressed: _saving || isSlave ? null : () => _deleteSlot(slot),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: constraints.maxWidth < 640
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Celda ${slot.number}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      actions,
                    ],
                  ),
                  smallBeltField,
                  const SizedBox(height: 6),
                  armField,
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      'Celda ${slot.number}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: smallBeltField),
                  const SizedBox(width: 8),
                  Expanded(child: armField),
                  actions,
                ],
              ),
      ),
    );
  }

  Widget _systemBoard() {
    final largeMachine = _machines
        .where((machine) => machine.id == _largeBeltId)
        .firstOrNull;
    final largeSensor = largeMachine == null
        ? null
        : _firstSensor(largeMachine.id);
    if (_slots.every(
          (slot) => slot.smallMachineId == null && slot.armMachineId == null,
        ) &&
        largeMachine == null) {
      return const Center(
        child: Text('Asigna las cintas y los brazos para ver la distribución.'),
      );
    }
    final boardHeight = math.max(190.0, _slots.length * 190.0).toDouble();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [for (final slot in _slots) _workCell(slot)]),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  largeMachine?.name ?? 'Cinta grande sin asignar',
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 112,
                  height: boardHeight,
                  child: _ConveyorVisual(
                    vertical: true,
                    machineName: largeMachine?.name ?? 'Sin asignar',
                    sensor: largeSensor,
                    sensorActive:
                        largeSensor != null &&
                        _activeSensorKeys.contains(
                          largeSensor.key.toUpperCase(),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _workCell(_OverviewSlot slot) {
    final smallMachine = _machines
        .where((machine) => machine.id == slot.smallMachineId)
        .firstOrNull;
    final armMachine = _machines
        .where((machine) => machine.id == slot.armMachineId)
        .firstOrNull;
    final smallSensor = smallMachine == null
        ? null
        : _firstSensor(smallMachine.id);
    return Container(
      width: 550,
      height: 190,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Text(
                  smallMachine?.name ?? 'Cinta pequeña sin asignar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _ConveyorVisual(
                    vertical: false,
                    machineName: smallMachine?.name ?? 'Sin asignar',
                    sensor: smallSensor,
                    sensorActive:
                        smallSensor != null &&
                        _activeSensorKeys.contains(
                          smallSensor.key.toUpperCase(),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 205,
            child: Column(
              children: [
                Text(
                  armMachine?.name ?? 'Brazo sin asignar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: armMachine == null
                      ? const Center(
                          child: Icon(Icons.precision_manufacturing_outlined),
                        )
                      : ScaraArmCanvas(
                          x: _normalizedMotorPosition(
                            _axisMotor(armMachine.id, 'X'),
                            'X',
                          ),
                          y: _normalizedMotorPosition(
                            _axisMotor(armMachine.id, 'Y'),
                            'Y',
                          ),
                          z: _normalizedMotorPosition(
                            _axisMotor(armMachine.id, 'Z'),
                            'Z',
                          ),
                          a: _normalizedMotorPosition(
                            _axisMotor(armMachine.id, 'A'),
                            'A',
                          ),
                          gripperOpen: _normalizedGripper(armMachine.id),
                          machineState: _armMoving(armMachine.id)
                              ? 'En movimiento'
                              : 'Listo',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _armMoving(int machineId) {
    final machineIds = _machineAndComponentIds(machineId).toSet();
    return _motors.any(
      (motor) =>
          machineIds.contains(motor.systemMachineId) &&
          _movingMotors.contains(motor.id),
    );
  }
}

class _OverviewSlot {
  _OverviewSlot({required this.number, this.smallPosition, this.armPosition})
    : smallMachineId = smallPosition?.systemMachineId,
      armMachineId = armPosition?.systemMachineId;

  final int number;
  final SystemPosition? smallPosition;
  final SystemPosition? armPosition;
  int? smallMachineId;
  int? armMachineId;
}

class _ConveyorVisual extends StatelessWidget {
  const _ConveyorVisual({
    required this.vertical,
    required this.machineName,
    required this.sensor,
    required this.sensorActive,
  });

  final bool vertical;
  final String machineName;
  final Sensor? sensor;
  final bool sensorActive;

  @override
  Widget build(BuildContext context) {
    final currentSensor = sensor;
    return CustomPaint(
      painter: _ConveyorPainter(
        vertical: vertical,
        color: Theme.of(context).colorScheme,
        sensorActive: sensorActive,
      ),
      child: Stack(
        children: [
          Align(
            alignment: vertical ? Alignment.center : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RotatedBox(
                quarterTurns: vertical ? 3 : 0,
                child: Text(
                  machineName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: vertical ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Tooltip(
                message: currentSensor == null
                    ? 'Sin sensor configurado'
                    : '${currentSensor.name} · ${currentSensor.key}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentSensor == null
                            ? Colors.grey
                            : sensorActive
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        boxShadow: sensorActive
                            ? [
                                BoxShadow(
                                  color: Colors.greenAccent.withValues(
                                    alpha: .8,
                                  ),
                                  blurRadius: 9,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (currentSensor != null) ...[
                      const SizedBox(width: 4),
                      RotatedBox(
                        quarterTurns: vertical ? 3 : 0,
                        child: Text(
                          currentSensor.key,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: .85),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConveyorPainter extends CustomPainter {
  const _ConveyorPainter({
    required this.vertical,
    required this.color,
    required this.sensorActive,
  });

  final bool vertical;
  final ColorScheme color;
  final bool sensorActive;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(12)),
      Paint()..color = color.surfaceContainerHighest,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(12)),
      Paint()
        ..color = color.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final rollerPaint = Paint()
      ..color = color.outlineVariant
      ..strokeWidth = 2;
    if (vertical) {
      for (var y = 18.0; y < size.height - 10; y += 24) {
        canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), rollerPaint);
      }
    } else {
      for (var x = 18.0; x < size.width - 10; x += 24) {
        canvas.drawLine(
          Offset(x, 14),
          Offset(x, size.height - 14),
          rollerPaint,
        );
      }
    }
    final sensorPoint = vertical
        ? Offset(9, size.height * .52)
        : Offset(size.width - 9, size.height * .5);
    canvas.drawCircle(
      sensorPoint,
      8,
      Paint()
        ..color = sensorActive ? Colors.greenAccent : Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ConveyorPainter oldDelegate) =>
      vertical != oldDelegate.vertical ||
      color != oldDelegate.color ||
      sensorActive != oldDelegate.sensorActive;
}
