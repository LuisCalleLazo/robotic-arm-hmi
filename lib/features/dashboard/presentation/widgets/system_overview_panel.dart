import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
import 'system_overview_machine_types.dart';
import 'system_overview_machine_selection.dart';

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
  static const _largeBeltType = 'Cinta grande';
  static const _smallBeltType = 'Cinta pequeña';
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
  int _loadGeneration = 0;
  bool _loading = true;
  bool _saving = false;
  bool _systemStopped = false;
  String? _error;
  StreamSubscription<TelemetryLogEntry>? _lineSubscription;
  StreamSubscription<void>? _machineCatalogSubscription;

  @override
  void initState() {
    super.initState();
    _lineSubscription = widget.telemetry.lineEvents.listen(_onLine);
    final configuration = GetIt.I<SystemConfigurationService>();
    _machineCatalogSubscription = configuration.machineCatalogChanges.listen(
      (_) => _load(),
    );
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
    _machineCatalogSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    try {
      final repository = GetIt.I<SystemRepository>();
      final machines = await repository.getMachines();
      final motors = await repository.getMotors();
      final servos = await repository.getServos();
      final sensors = await repository.getSensors();
      final positions = await GetIt.I<SystemPositionRepository>()
          .getSystemPositions();
      if (!mounted || generation != _loadGeneration) return;
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
        final lastSection = positions
            .where(
              (position) =>
                  _isSmallBelt(position.type) || _isArm(position.type),
            )
            .fold<int>(1, (last, position) => math.max(last, position.number));
        _slots
          ..clear()
          ..addAll([
            for (var number = 1; number <= lastSection; number++)
              _OverviewSlot(
                number: number,
                smallPosition: _findPosition(positions, _smallBeltType, number),
                armPosition: _findPosition(positions, _armType, number),
                smallMachineId: _findPosition(
                  positions,
                  _smallBeltType,
                  number,
                )?.systemMachineId,
                armMachineId: _findPosition(
                  positions,
                  _armType,
                  number,
                )?.systemMachineId,
              ),
          ]);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
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
      .replaceAll('Ñ', 'N')
      .replaceAll(RegExp(r'[^A-Z]'), '');

  bool _isArm(String type) => SystemOverviewMachineTypes.isArm(type);

  bool _isSmallBelt(String type) =>
      SystemOverviewMachineTypes.isSmallBelt(type);

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

  List<SystemMachine> _availableMachines(int? selectedId) {
    final assignedIds = {
      ?_largeBeltId,
      for (final slot in _slots) ...[
        if (slot.smallMachineId != null) slot.smallMachineId!,
        if (slot.armMachineId != null) slot.armMachineId!,
      ],
    };
    return availableSystemOverviewMachines(
      machines: _machines,
      assignedMachineIds: assignedIds,
      selectedMachineId: selectedId,
    );
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

  Future<void> _selectLargeBelt() => _selectMachine(
    title: 'Seleccionar cinta grande',
    type: _largeBeltType,
    number: 1,
    selectedId: _largeBeltId,
    oldPosition: _findPosition(_positions, _largeBeltType, 1),
  );

  Future<void> _selectSlotMachine(
    _OverviewSlot slot, {
    required bool smallBelt,
  }) {
    final type = smallBelt ? _smallBeltType : _armType;
    return _selectMachine(
      title: smallBelt ? 'Seleccionar cinta pequeña' : 'Seleccionar brazo',
      type: type,
      number: slot.number,
      selectedId: smallBelt ? slot.smallMachineId : slot.armMachineId,
      oldPosition: smallBelt ? slot.smallPosition : slot.armPosition,
    );
  }

  Future<void> _selectMachine({
    required String title,
    required String type,
    required int number,
    required int? selectedId,
    required SystemPosition? oldPosition,
  }) async {
    if (_saving) return;
    final machines = _availableMachines(selectedId);
    final selected = await showDialog<SystemMachine>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          height: 360,
          child: machines.isEmpty
              ? const Center(child: Text('No hay máquinas registradas.'))
              : ListView(
                  children: [
                    for (final machine in machines)
                      ListTile(
                        leading: Icon(
                          machine.id == selectedId
                              ? Icons.radio_button_checked
                              : Icons.precision_manufacturing_outlined,
                        ),
                        title: Text(machine.name),
                        subtitle: Text(machine.type),
                        selected: machine.id == selectedId,
                        onTap: () => Navigator.pop(context, machine),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected == null || selected.id == selectedId) return;
    setState(() => _saving = true);
    try {
      final repository = GetIt.I<SystemPositionRepository>();
      await repository.saveSystemPosition(
        SystemPosition(
          id: oldPosition?.id ?? _nextPositionId++,
          number: number,
          type: type,
          systemMachineId: selected.id,
        ),
      );
      await GetIt.I<SystemConfigurationService>().publishSystemLayout();
      await _load();
    } catch (error) {
      _notify('No se pudo asignar ${selected.name}: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _stopAll() async {
    try {
      await widget.onCommand('BCSTOP');
      if (mounted) setState(() => _systemStopped = true);
    } catch (error) {
      _notify('No se pudo detener el sistema: $error');
    }
  }

  void _onLine(TelemetryLogEntry entry) {
    final line = entry.line.trim();
    if (line.isEmpty) return;
    if (entry.source == TelemetrySource.serialSent) {
      final command = line.toUpperCase();
      var stopped = _systemStopped;
      if (command == 'BCSTOP' ||
          command == 'STOP' ||
          command == 'BCPAUSE' ||
          command == 'PAUSE') {
        stopped = true;
      } else if (command != 'BCT100' && command != 'BC?' && command != 'POS') {
        stopped = false;
      }
      if (stopped != _systemStopped && mounted) {
        setState(() => _systemStopped = stopped);
      }
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
          _systemStopped = false;
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
        if (event == 'STOP') _systemStopped = true;
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
    for (final key in _configuredSensorKeys) {
      if (normalized == '${key}1') {
        changed = _activeSensorKeys.add(key) || changed;
      } else if (normalized == '${key}0') {
        changed = _activeSensorKeys.remove(key) || changed;
      }
    }
    return changed;
  }

  Set<String> get _configuredSensorKeys => {
    for (final sensor in _sensors)
      if (sensor.key.trim().isNotEmpty) sensor.key.trim().toUpperCase(),
    for (final motor in _motors)
      if (motor.keySensorLeft?.trim().isNotEmpty == true)
        motor.keySensorLeft!.trim().toUpperCase(),
    for (final motor in _motors)
      if (motor.keySensorRight?.trim().isNotEmpty == true)
        motor.keySensorRight!.trim().toUpperCase(),
  };

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
        .where((machine) => machine.id == machineId)
        .map((machine) => machine.parentMachineId)
        .whereType<int>(),
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

  Set<String> _sensorKeysForMachine(int machineId) {
    final machineIds = _machineAndComponentIds(machineId).toSet();
    return {
      for (final sensor in _sensors)
        if (sensor.machineId != null &&
            machineIds.contains(sensor.machineId) &&
            sensor.key.trim().isNotEmpty)
          sensor.key.trim().toUpperCase(),
      for (final motor in _motors)
        if (machineIds.contains(motor.systemMachineId) &&
            motor.keySensorLeft?.trim().isNotEmpty == true)
          motor.keySensorLeft!.trim().toUpperCase(),
      for (final motor in _motors)
        if (machineIds.contains(motor.systemMachineId) &&
            motor.keySensorRight?.trim().isNotEmpty == true)
          motor.keySensorRight!.trim().toUpperCase(),
    };
  }

  bool _sensorActiveForMachine(int machineId) =>
      _sensorKeysForMachine(machineId).any(_activeSensorKeys.contains);

  String? _sensorKeyForMachine(int machineId) {
    final keys = _sensorKeysForMachine(machineId);
    return keys.where(_activeSensorKeys.contains).firstOrNull ??
        keys.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('No se pudo cargar el sistema: $_error'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Sistema general',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: widget.canSendCommands ? _stopAll : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Parar todo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addSlot,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar sección'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _systemBoard()),
      ],
    );
  }

  Widget _systemBoard() {
    final largeMachine = _machineById(_largeBeltId);
    final largeSensorKey = largeMachine == null
        ? null
        : _sensorKeyForMachine(largeMachine.id);
    final largeSensorActive =
        largeMachine != null && _sensorActiveForMachine(largeMachine.id);
    final boardHeight = math.max(190.0, _slots.length * 190.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(710.0, constraints.maxWidth - 32);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: availableWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [for (final slot in _slots) _workCell(slot)],
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 140,
                    height: boardHeight + 36,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _selectLargeBelt,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            children: [
                              Text(
                                largeMachine?.name ?? 'Cinta grande · asignar',
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _ConveyorVisual(
                                  vertical: true,
                                  machineName:
                                      largeMachine?.name ??
                                      'Toca para seleccionar',
                                  sensorKey: largeSensorKey,
                                  isMoving:
                                      !_systemStopped && !largeSensorActive,
                                  sensorActive: largeSensorActive,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _workCell(_OverviewSlot slot) {
    final smallMachine = _machineById(slot.smallMachineId);
    final armMachine = _machineById(slot.armMachineId);
    final smallSensorKey = smallMachine == null
        ? null
        : _sensorKeyForMachine(smallMachine.id);
    final smallSensorActive =
        smallMachine != null && _sensorActiveForMachine(smallMachine.id);
    return Container(
      width: 550,
      height: 190,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectSlotMachine(slot, smallBelt: true),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Text(
                        smallMachine?.name ?? 'Cinta pequeña · asignar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ConveyorVisual(
                          vertical: false,
                          machineName:
                              smallMachine?.name ?? 'Toca para seleccionar',
                          sensorKey: smallSensorKey,
                          isMoving: !_systemStopped && !smallSensorActive,
                          sensorActive: smallSensorActive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 205,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectSlotMachine(slot, smallBelt: false),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Text(
                        armMachine?.name ?? 'Brazo · asignar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ScaraArmCanvas(
                          x: armMachine == null
                              ? 0.5
                              : _normalizedMotorPosition(
                                  _axisMotor(armMachine.id, 'X'),
                                  'X',
                                ),
                          y: armMachine == null
                              ? 0.5
                              : _normalizedMotorPosition(
                                  _axisMotor(armMachine.id, 'Y'),
                                  'Y',
                                ),
                          z: armMachine == null
                              ? 0.5
                              : _normalizedMotorPosition(
                                  _axisMotor(armMachine.id, 'Z'),
                                  'Z',
                                ),
                          a: armMachine == null
                              ? 0.5
                              : _normalizedMotorPosition(
                                  _axisMotor(armMachine.id, 'A'),
                                  'A',
                                ),
                          gripperOpen: armMachine == null
                              ? 0.5
                              : _normalizedGripper(armMachine.id),
                          machineState: armMachine == null
                              ? 'Selecciona un brazo'
                              : _armMoving(armMachine.id)
                              ? 'En movimiento'
                              : 'Listo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _armMoving(int machineId) {
    return _machineMoving(machineId);
  }

  SystemMachine? _machineById(int? machineId) =>
      _machines.where((machine) => machine.id == machineId).firstOrNull;

  bool _machineMoving(int machineId) {
    final machineIds = _machineAndComponentIds(machineId).toSet();
    return _motors.any(
      (motor) =>
          machineIds.contains(motor.systemMachineId) &&
          _movingMotors.contains(motor.id),
    );
  }
}

class _OverviewSlot {
  _OverviewSlot({
    required this.number,
    this.smallPosition,
    this.armPosition,
    this.smallMachineId,
    this.armMachineId,
  });

  final int number;
  final SystemPosition? smallPosition;
  final SystemPosition? armPosition;
  int? smallMachineId;
  int? armMachineId;
}

class _ConveyorVisual extends StatefulWidget {
  const _ConveyorVisual({
    required this.vertical,
    required this.machineName,
    required this.sensorKey,
    required this.isMoving,
    required this.sensorActive,
  });

  final bool vertical;
  final String machineName;
  final String? sensorKey;
  final bool isMoving;
  final bool sensorActive;

  @override
  State<_ConveyorVisual> createState() => _ConveyorVisualState();
}

class _ConveyorVisualState extends State<_ConveyorVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rollerAnimation;

  @override
  void initState() {
    super.initState();
    _rollerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isMoving) _rollerAnimation.repeat();
  }

  @override
  void didUpdateWidget(covariant _ConveyorVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMoving == widget.isMoving) return;
    if (widget.isMoving) {
      _rollerAnimation.repeat();
    } else {
      _rollerAnimation.stop();
      _rollerAnimation.value = 0;
    }
  }

  @override
  void dispose() {
    _rollerAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSensorKey = widget.sensorKey;
    return CustomPaint(
      painter: _ConveyorPainter(
        vertical: widget.vertical,
        color: Theme.of(context).colorScheme,
        sensorActive: widget.sensorActive,
        isMoving: widget.isMoving,
        animation: _rollerAnimation,
      ),
      child: Stack(
        children: [
          Align(
            alignment: widget.vertical
                ? Alignment.center
                : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RotatedBox(
                quarterTurns: widget.vertical ? 3 : 0,
                child: Text(
                  widget.machineName,
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
            alignment: widget.vertical
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Tooltip(
                message: currentSensorKey ?? 'Sin sensor configurado',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentSensorKey == null
                            ? Colors.grey
                            : widget.sensorActive
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        boxShadow: widget.sensorActive
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
                    if (currentSensorKey != null) ...[
                      const SizedBox(width: 4),
                      RotatedBox(
                        quarterTurns: widget.vertical ? 3 : 0,
                        child: Text(
                          currentSensorKey,
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
    required this.isMoving,
    required Animation<double> animation,
  }) : _animation = animation,
       super(repaint: animation);

  final bool vertical;
  final ColorScheme color;
  final bool sensorActive;
  final bool isMoving;
  final Animation<double> _animation;

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
    final offset = isMoving ? (1 - _animation.value) * 24 : 0.0;
    if (vertical) {
      for (var y = 18.0 - offset; y < size.height - 10; y += 24) {
        if (y < 6) continue;
        canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), rollerPaint);
      }
    } else {
      for (var x = 18.0 - offset; x < size.width - 10; x += 24) {
        if (x < 6) continue;
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
      sensorActive != oldDelegate.sensorActive ||
      isMoving != oldDelegate.isMoving ||
      _animation.value != oldDelegate._animation.value;
}
