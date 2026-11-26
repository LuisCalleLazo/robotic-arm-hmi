import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../system/domain/entities/motor.dart';
import '../../../system/domain/entities/process.dart';
import '../../../system/domain/entities/process_motors.dart';
import '../../../system/domain/entities/process_servo.dart';
import '../../../system/domain/entities/sensor.dart';
import '../../../system/domain/entities/servo.dart';
import '../../../system/domain/entities/system_machine.dart';
import '../../../system/domain/repositories/system_repository.dart';
import '../../../system/domain/services/arduino_process_command_builder.dart';
import '../../../system/domain/services/system_configuration_service.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import 'scara_process_panel.dart';

typedef ArmCommandSender =
    Future<void> Function(String command, {String? simulatedCommand});

enum _ArmAxis {
  x('X', 'Base'),
  y('Y', 'Antebrazo'),
  z('Z', 'Altura'),
  a('A', 'Garra');

  const _ArmAxis(this.key, this.label);

  final String key;
  final String label;
}

class ScaraArmHmiPanel extends StatefulWidget {
  const ScaraArmHmiPanel({
    required this.canSendCommands,
    required this.simulating,
    required this.serialConnected,
    required this.connectionLabel,
    required this.telemetry,
    required this.onCommand,
    super.key,
  });

  final bool canSendCommands;
  final bool simulating;
  final bool serialConnected;
  final String connectionLabel;
  final TelemetryCubit telemetry;
  final ArmCommandSender onCommand;

  @override
  State<ScaraArmHmiPanel> createState() => _ScaraArmHmiPanelState();
}

class _ScaraArmHmiPanelState extends State<ScaraArmHmiPanel> {
  final Map<_ArmAxis, int?> _selectedMotors = {};
  final Map<_ArmAxis, TextEditingController> _stepControllers = {
    for (final axis in _ArmAxis.values)
      axis: TextEditingController(text: '500'),
  };
  final Map<_ArmAxis, TextEditingController> _speedControllers = {};
  final Map<int, double> _positions = {};
  final Map<int, double> _velocities = {};
  final Map<int, _MovementTelemetry> _motorTelemetry = {};
  final Map<String, _MovementTelemetry> _servoTelemetry = {};
  final Map<int, _HmiProcessPlan> _processPlans = {};
  final Set<int> _knownPositions = {};
  final Map<int, int> _lastDirections = {};
  final Set<String> _activeSensors = {};
  final TextEditingController _servoAngleController = TextEditingController(
    text: '90',
  );
  final TextEditingController _servoSpeedController = TextEditingController(
    text: '60',
  );

  List<SystemMachine> _machines = const [];
  List<SystemMachine> _allMachines = const [];
  List<Motor> _motors = const [];
  List<Servo> _servos = const [];
  List<Sensor> _sensors = const [];
  SystemMachine? _selectedMachine;
  Servo? _selectedServo;
  StreamSubscription<TelemetryLogEntry>? _lineSubscription;
  StreamSubscription<void>? _sensorCatalogSubscription;
  Timer? _animationTimer;
  final Map<int, _PositionAnimation> _animations = {};
  int _configurationGeneration = 0;
  bool _telemetryRequested = false;
  bool _loading = true;
  bool _paused = false;
  DateTime? _pauseStartedAt;
  String _machineState = 'Sin posición recibida';
  double _servoAngle = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _lineSubscription = widget.telemetry.lineEvents.listen(_onLine);
    _sensorCatalogSubscription = GetIt.I<SystemConfigurationService>()
        .sensorCatalogChanges
        .listen((_) => _loadConfiguration());
    _loadConfiguration();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTelemetry());
  }

  @override
  void didUpdateWidget(covariant ScaraArmHmiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.telemetry != widget.telemetry) {
      _lineSubscription?.cancel();
      _sensorCatalogSubscription?.cancel();
      _lineSubscription = widget.telemetry.lineEvents.listen(_onLine);
    }
    if (oldWidget.serialConnected != widget.serialConnected ||
        oldWidget.simulating != widget.simulating) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTelemetry());
    }
    if ((oldWidget.serialConnected && !widget.serialConnected) ||
        (oldWidget.simulating && !widget.simulating)) {
      _cancelAnimations();
      if (mounted) {
        setState(() {
          _machineState = 'Desconectado';
        });
      }
    }
  }

  @override
  void dispose() {
    _lineSubscription?.cancel();
    _animationTimer?.cancel();
    for (final controller in _stepControllers.values) {
      controller.dispose();
    }
    for (final controller in _speedControllers.values) {
      controller.dispose();
    }
    _servoAngleController.dispose();
    _servoSpeedController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    final generation = ++_configurationGeneration;
    try {
      final repository = GetIt.I<SystemRepository>();
      final machines = await repository.getMachines();
      final motors = await repository.getMotors();
      final servos = await repository.getServos();
      final sensors = await repository.getSensors();
      final processes = await repository.getProcesses();
      final processPlans = <int, _HmiProcessPlan>{};
      for (final process in processes) {
        processPlans[process.id] = _HmiProcessPlan(
          process: process,
          motors: await repository.getProcessMotors(process.id),
          servos: await repository.getProcessServos(process.id),
        );
      }

      final armMachines = machines
          .where((machine) => machine.type.toUpperCase().contains('BRAZO'))
          .toList();
      final candidates = armMachines.isNotEmpty
          ? armMachines
          : machines.where((machine) {
              final componentIds = {
                machine.id,
                ...machines
                    .where((item) => item.parentMachineId == machine.id)
                    .map((item) => item.id),
              };
              return motors.any(
                (motor) => componentIds.contains(motor.systemMachineId),
              );
            }).toList();
      if (!mounted || generation != _configurationGeneration) return;
      setState(() {
        _machines = candidates;
        _allMachines = machines;
        _motors = motors;
        _servos = servos;
        _sensors = sensors;
        _processPlans
          ..clear()
          ..addAll(processPlans);
        _selectedMachine = candidates.isEmpty ? null : candidates.first;
        _loading = false;
      });
      _selectMachine(candidates.isEmpty ? null : candidates.first);
    } catch (error) {
      if (!mounted || generation != _configurationGeneration) return;
      setState(() {
        _loading = false;
        _loadError = '$error';
      });
    }
  }

  void _selectMachine(SystemMachine? machine) {
    if (machine == null) {
      setState(() {
        _selectedMachine = null;
        _selectedServo = null;
        _selectedMotors.clear();
      });
      return;
    }
    final machineIds = {
      machine.id,
      ..._allMachines
          .where((item) => item.parentMachineId == machine.id)
          .map((item) => item.id),
    };
    final motors = _motors
        .where((motor) => machineIds.contains(motor.systemMachineId))
        .toList();
    final servos = _servos
        .where((servo) => machineIds.contains(servo.machineId))
        .toList();
    final sensors = _sensors
        .where(
          (sensor) =>
              sensor.machineId == null || machineIds.contains(sensor.machineId),
        )
        .toList();
    final previousSelections = Map<_ArmAxis, int?>.from(_selectedMotors);
    setState(() {
      _selectedMachine = machine;
      _selectedServo = servos.isEmpty ? null : servos.first;
      _activeSensors.removeWhere(
        (key) => sensors.every((sensor) => sensor.key.toUpperCase() != key),
      );
      for (final axis in _ArmAxis.values) {
        final prior = _selectedMotors[axis];
        final candidate = motors.where((motor) => motor.id == prior);
        final matching = candidate.isNotEmpty
            ? candidate.first
            : motors.where((motor) => _matchesAxis(motor, axis)).firstOrNull;
        _selectedMotors[axis] = matching?.id;
      }
      for (final axis in _ArmAxis.values) {
        final motor = _motorFor(axis);
        if (motor != null && previousSelections[axis] != motor.id) {
          _speedControllers[axis]?.dispose();
          _speedControllers[axis] = TextEditingController(
            text: motor.speed.round().toString(),
          );
        }
      }
    });
  }

  bool _matchesAxis(Motor motor, _ArmAxis axis) {
    final key = ArduinoProcessCommandBuilder.commandKey(
      motor.key,
    ).toUpperCase().substring(2);
    return key == axis.key;
  }

  Motor? _motorFor(_ArmAxis axis) {
    final id = _selectedMotors[axis];
    for (final motor in _motors) {
      if (motor.id == id) return motor;
    }
    return null;
  }

  List<Motor> get _machineMotors {
    final machine = _selectedMachine;
    if (machine == null) return const [];
    final ids = {
      machine.id,
      ..._allMachines
          .where((item) => item.parentMachineId == machine.id)
          .map((item) => item.id),
    };
    return _motors
        .where((motor) => ids.contains(motor.systemMachineId))
        .toList();
  }

  List<Servo> get _machineServos {
    final machine = _selectedMachine;
    if (machine == null) return const [];
    final ids = {
      machine.id,
      ..._allMachines
          .where((item) => item.parentMachineId == machine.id)
          .map((item) => item.id),
    };
    return _servos.where((servo) => ids.contains(servo.machineId)).toList();
  }

  List<Sensor> get _machineSensors {
    final machine = _selectedMachine;
    if (machine == null) return const [];
    final ids = {
      machine.id,
      ..._allMachines
          .where((item) => item.parentMachineId == machine.id)
          .map((item) => item.id),
    };
    return _sensors
        .where(
          (sensor) =>
              sensor.machineId == null || ids.contains(sensor.machineId),
        )
        .toList();
  }

  List<_HmiProcessPlan> _plansForMachine(SystemMachine? machine) {
    if (machine == null) return const [];
    final machineIds = {
      machine.id,
      ..._allMachines
          .where((item) => item.parentMachineId == machine.id)
          .map((item) => item.id),
    };
    final motorIds = _motors
        .where((motor) => machineIds.contains(motor.systemMachineId))
        .map((motor) => motor.id)
        .toSet();
    final servoIds = _servos
        .where((servo) => machineIds.contains(servo.machineId))
        .map((servo) => servo.id)
        .toSet();
    return _processPlans.values.where((plan) {
      if (plan.process.machineId != null) {
        return machineIds.contains(plan.process.machineId);
      }
      return plan.motors.any((item) => motorIds.contains(item.motorId)) ||
          plan.servos.any((item) => servoIds.contains(item.servoId));
    }).toList()..sort((a, b) => a.process.name.compareTo(b.process.name));
  }

  void _ensureTelemetry() {
    if (_telemetryRequested || widget.simulating || !widget.serialConnected) {
      return;
    }
    _telemetryRequested = true;
    unawaited(() async {
      try {
        await widget.onCommand('BCT100');
        await widget.onCommand('BC?');
      } catch (error) {
        _telemetryRequested = false;
        if (mounted) _notify('No se pudo activar la telemetría: $error');
      }
    }());
  }

  void _onLine(TelemetryLogEntry entry) {
    final line = entry.line.trim();
    if (line.isEmpty) return;
    if (entry.source == TelemetrySource.serialSent) {
      _handleSensorSignal(line);
      return;
    }
    var changed = false;
    final sensorSignal = _sensorSignal(line);
    if (sensorSignal != null) {
      final (sensor, isActive) = sensorSignal;
      final key = sensor.key.trim().toUpperCase();
      if (isActive) {
        final newlyActive = _activeSensors.add(key);
        changed = newlyActive || changed;
      } else {
        changed = _activeSensors.remove(key) || changed;
      }
    }

    if (line.startsWith('STATE,')) {
      _machineState = line.substring(6);
      if (_machineState == 'PAUSED') {
        _pauseStartedAt ??= DateTime.now();
        _paused = true;
      } else {
        if (_paused) _resumeAnimations();
        _paused = false;
      }
      changed = true;
    } else if (line.startsWith('BC,EVT,') || line.startsWith('BC,ERR,')) {
      changed = _handleFirmwareEvent(line);
    } else if (line.startsWith('BCS,') || _isServoTelemetry(line)) {
      changed = _handleServoTelemetry(line);
    } else if (line.startsWith('BC')) {
      changed = _handleAxisTelemetry(line);
    } else if (line.startsWith('POS,')) {
      changed = _handleSimulatorPosition(line);
    } else if (line.startsWith('EVT,SERVO,')) {
      final angle = double.tryParse(line.split(',').last);
      if (angle != null) {
        _servoAngle = angle.clamp(0, 180).toDouble();
        changed = true;
      }
    } else if (line.startsWith('ERR,')) {
      _cancelAnimations();
      _machineState = 'Error: ${line.substring(4)}';
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  void _handleSensorSignal(String line) {
    final signal = _sensorSignal(line);
    if (signal == null) return;
    final (sensor, isActive) = signal;
    final key = sensor.key.trim().toUpperCase();
    if (!isActive) {
      final changed = _activeSensors.remove(key);
      if (changed && mounted) setState(() {});
      return;
    }

    final newlyActive = _activeSensors.add(key);
    if (newlyActive && mounted) setState(() {});
  }

  (Sensor, bool)? _sensorSignal(String line) {
    final normalizedLine = line.trim().toUpperCase();
    final sensors = [..._sensors]
      ..sort((a, b) => b.key.trim().length.compareTo(a.key.trim().length));
    for (final sensor in sensors) {
      final key = sensor.key.trim().toUpperCase();
      if (key.isEmpty) continue;
      if (normalizedLine == '${key}1') return (sensor, true);
      if (normalizedLine == '${key}0') return (sensor, false);
    }

    final fields = line.split(',');
    if (fields.length < 4 ||
        fields[0].trim().toUpperCase() != 'BC' ||
        fields[1].trim().toUpperCase() != 'SENSOR') {
      return null;
    }
    final key = fields[2].trim().toUpperCase();
    final sensor = sensors
        .where((item) => item.key.trim().toUpperCase() == key)
        .firstOrNull;
    if (sensor == null) return null;
    final state = fields[3].trim().toUpperCase();
    return (
      sensor,
      state == '1' || state == 'ON' || state == 'TRUE' || state == 'ACTIVE',
    );
  }

  bool _handleAxisTelemetry(String line) {
    final fields = line.split(',');
    if (fields.length < 3) return false;
    final key = fields.first.toUpperCase();
    final motor = _motorForKey(key);
    if (motor == null) return false;
    final positionIndex = fields.length >= 5 ? 2 : 1;
    final position = double.tryParse(fields[positionIndex]);
    if (position != null) {
      _cancelAnimation(motor.id);
      _positions[motor.id] = position;
      _knownPositions.add(motor.id);
      if (_machineState == 'Sin posición recibida') {
        _machineState = 'Posición sincronizada';
      }
    }
    if (fields.length >= 5) {
      final velocity = double.tryParse(fields[4]);
      if (velocity != null) {
        _velocities[motor.id] = velocity;
        _motorTelemetry
            .putIfAbsent(motor.id, _MovementTelemetry.new)
            .currentSpeed = velocity
            .abs();
        if (velocity != 0) _lastDirections[motor.id] = velocity.sign.toInt();
      }
    }
    if (fields.length >= 6) {
      _setSensorForDirection(motor, int.tryParse(fields[5]) == 1);
    }
    if (fields.length >= 4 && int.tryParse(fields[3]) == 0) {
      _finishMotorMovement(motor, _positions[motor.id]);
    }
    return true;
  }

  bool _handleServoTelemetry(String line) {
    final fields = line.split(',');
    if (fields.length < 3) return false;
    final key = fields.first.toUpperCase();
    final angle = double.tryParse(fields[2]);
    if (angle == null) return false;
    final target = fields.length >= 4 ? double.tryParse(fields[3]) : null;
    if (target != null) {
      final metrics = _servoTelemetry.putIfAbsent(key, _MovementTelemetry.new);
      final sampleTime = DateTime.now();
      final previousSample = metrics.lastSample;
      final previousTime = metrics.lastSampleAt;
      if (previousSample != null && previousTime != null) {
        final elapsed = sampleTime.difference(previousTime).inMicroseconds;
        if (elapsed > 0) {
          metrics.currentSpeed =
              (angle - previousSample).abs() * 1000000 / elapsed;
        }
      }
      metrics.lastSample = angle;
      metrics.lastSampleAt = sampleTime;
      if ((target - angle).abs() >= 0.5) {
        metrics.startedAt ??= sampleTime;
        metrics.startValue ??= angle;
        metrics.target = target;
      } else {
        _finishServoMovement(metrics, angle, sampleTime);
      }
    }
    _servoAngle = angle.clamp(0, 180).toDouble();
    return true;
  }

  bool _isServoTelemetry(String line) {
    final key = line.split(',').first.toUpperCase();
    return _machineServos.any(
      (servo) =>
          ArduinoProcessCommandBuilder.commandKey(servo.key).toUpperCase() ==
          key,
    );
  }

  Set<String> _wireKeys(String configuredKey) {
    return {
      ArduinoProcessCommandBuilder.commandKey(configuredKey).toUpperCase(),
    };
  }

  bool _handleFirmwareEvent(String line) {
    final fields = line.split(',');
    if (fields.length < 3) return false;
    final event = fields[2].toUpperCase();
    if (event == 'STOP' || event == 'PAUSE' || event == 'PLAY') {
      if (event == 'STOP') {
        _cancelAnimations();
        for (final motor in _machineMotors) {
          _finishMotorMovement(motor, _positions[motor.id]);
        }
      }
      if (event == 'PAUSE') {
        _pauseStartedAt ??= DateTime.now();
      } else if (event == 'PLAY') {
        _resumeAnimations();
      }
      _paused = event == 'PAUSE';
      _machineState = event;
      return true;
    }
    if (event == 'SERVO' && fields.length >= 4) {
      final angle = double.tryParse(fields[3]);
      if (angle == null) return false;
      _servoAngle = angle.clamp(0, 180).toDouble();
      return true;
    }
    if (event == 'SENSOR' && fields.length >= 5) {
      final motor = _motorForKey(fields[3]);
      final position = double.tryParse(fields[4]);
      if (motor != null && position != null) {
        _cancelAnimation(motor.id);
        _positions[motor.id] = position;
        _knownPositions.add(motor.id);
        _finishMotorMovement(motor, position);
        if (_machineState == 'Sin posición recibida') {
          _machineState = 'Posición sincronizada';
        }
        final direction = _lastDirections[motor.id] ?? 0;
        final sensorKey = direction >= 0
            ? motor.keySensorRight
            : motor.keySensorLeft;
        if (sensorKey != null) _activeSensors.add(sensorKey.toUpperCase());
      }
      _machineState = 'Límite de sensor';
      return true;
    }
    if (event == 'SENSOR_BLOQUEADO' && fields.length >= 4) {
      final motor = _motorForKey(fields[3]);
      if (motor != null) {
        _cancelAnimation(motor.id);
        final direction = _lastDirections[motor.id] ?? 0;
        final sensorKey = direction >= 0
            ? motor.keySensorRight
            : motor.keySensorLeft;
        if (sensorKey != null) _activeSensors.add(sensorKey.toUpperCase());
        _finishMotorMovement(motor, _positions[motor.id]);
      }
      _machineState = 'Límite activo';
      return true;
    }
    if (event == 'INICIO' && fields.length >= 5) {
      final motor = _motorForKey(fields[3]);
      final distance = double.tryParse(fields[4]);
      if (motor != null && distance != null) {
        _lastDirections[motor.id] = distance.sign.toInt();
        final start = _positions[motor.id] ?? 0;
        final metrics = _motorTelemetry.putIfAbsent(
          motor.id,
          _MovementTelemetry.new,
        );
        metrics
          ..startedAt = DateTime.now()
          ..startValue = start
          ..target = start + distance;
        final speed = _velocities[motor.id]?.abs();
        _animatePosition(
          motor,
          start,
          start + distance,
          speed == null || speed <= 0 ? motor.speed : speed,
        );
      }
      _machineState = 'En movimiento';
      return true;
    }
    if (event == 'FIN' && fields.length >= 5) {
      final motor = _motorForKey(fields[3]);
      final position = double.tryParse(fields[4]);
      if (motor != null && position != null) {
        _cancelAnimation(motor.id);
        _positions[motor.id] = position;
        _knownPositions.add(motor.id);
        _finishMotorMovement(motor, position);
      }
      _machineState = _animations.isEmpty ? 'Listo' : 'En movimiento';
      return true;
    }
    if (line.startsWith('BC,ERR,')) {
      _machineState = 'Error serial';
      return true;
    }
    return false;
  }

  Motor? _motorForKey(String key) {
    final normalized = key.toUpperCase();
    for (final motor in _machineMotors) {
      if (_wireKeys(motor.key).contains(normalized)) return motor;
    }
    return null;
  }

  void _finishMotorMovement(Motor motor, double? finalPosition) {
    final metrics = _motorTelemetry[motor.id];
    final startedAt = metrics?.startedAt;
    if (metrics == null || startedAt == null) return;
    final duration = DateTime.now().difference(startedAt);
    final start = metrics.startValue;
    final distance = start == null || finalPosition == null
        ? (metrics.target != null && start != null
              ? (metrics.target! - start).abs()
              : null)
        : (finalPosition - start).abs();
    metrics
      ..lastDuration = duration
      ..lastAverageSpeed = distance == null || duration.inMicroseconds == 0
          ? null
          : distance * 1000000 / duration.inMicroseconds
      ..startedAt = null
      ..startValue = null
      ..target = null;
  }

  void _finishServoMovement(
    _MovementTelemetry metrics,
    double finalAngle,
    DateTime finishedAt,
  ) {
    final startedAt = metrics.startedAt;
    if (startedAt == null) return;
    final duration = finishedAt.difference(startedAt);
    final startAngle = metrics.startValue;
    final distance = startAngle == null
        ? null
        : (finalAngle - startAngle).abs();
    metrics
      ..lastDuration = duration
      ..lastAverageSpeed = distance == null || duration.inMicroseconds == 0
          ? null
          : distance * 1000000 / duration.inMicroseconds
      ..startedAt = null
      ..startValue = null
      ..target = null
      ..currentSpeed = 0;
  }

  void _setSensorForDirection(Motor motor, bool active) {
    final direction = _lastDirections[motor.id] ?? 0;
    final key = direction >= 0 ? motor.keySensorRight : motor.keySensorLeft;
    if (key == null) return;
    if (active) {
      _activeSensors.add(key.toUpperCase());
    } else {
      _activeSensors.remove(key.toUpperCase());
    }
  }

  bool _handleSimulatorPosition(String line) {
    final matches = RegExp(r'([XYAZ])=(-?\d+)').allMatches(line);
    var changed = false;
    for (final match in matches) {
      final axis = _ArmAxis.values.firstWhere(
        (item) => item.key == match.group(1),
      );
      final motor = _motorFor(axis);
      final position = double.tryParse(match.group(2)!);
      if (motor == null || position == null) continue;
      _cancelAnimation(motor.id);
      _positions[motor.id] = position;
      _knownPositions.add(motor.id);
      changed = true;
    }
    return changed;
  }

  double _maxRight(Motor motor) =>
      double.tryParse(motor.maxStepsRight ?? '')?.abs() ?? _defaultRange(motor);

  double _maxLeft(Motor motor) =>
      double.tryParse(motor.maxStepsLeft ?? '')?.abs() ?? _defaultRange(motor);

  double _defaultRange(Motor motor) {
    final key = ArduinoProcessCommandBuilder.commandKey(
      motor.key,
    ).toUpperCase().substring(2);
    return switch (key) {
      'X' => 30450,
      'Y' => 11834,
      'A' => 3426,
      'Z' => 47829,
      _ => 10000,
    };
  }

  double _normalizedPosition(_ArmAxis axis) {
    final motor = _motorFor(axis);
    if (motor == null) return 0.5;
    final position = _positions[motor.id] ?? 0;
    final low = -_maxLeft(motor);
    final high = _maxRight(motor);
    if (high <= low) return 0.5;
    return ((position - low) / (high - low)).clamp(0, 1).toDouble();
  }

  double get _normalizedServoAngle {
    final maximum = (_selectedServo?.maxOpen ?? 180).clamp(0, 180);
    if (maximum <= 0) return 0;
    return (_servoAngle / maximum).clamp(0, 1).toDouble();
  }

  Future<void> _move(_ArmAxis axis, int direction) async {
    final motor = _motorFor(axis);
    final amount = int.tryParse(_stepControllers[axis]!.text);
    final speed = double.tryParse(_speedControllers[axis]?.text ?? '');
    if (motor == null || amount == null || amount <= 0 || speed == null) {
      _notify('Ingresa pasos y una velocidad válida para el eje ${axis.key}.');
      return;
    }
    if (speed < 100 || speed > 10000) {
      _notify('La velocidad de motor debe estar entre 100 y 10000 pasos/s.');
      return;
    }
    final steps = direction * amount;
    final current = _positions[motor.id] ?? 0;
    final target = current + steps;
    if (target > _maxRight(motor) || target < -_maxLeft(motor)) {
      _notify('El movimiento supera el límite configurado para ${motor.key}.');
      return;
    }
    final command = ArduinoProcessCommandBuilder.movement(
      key: motor.key,
      value: steps,
      speed: speed,
    );
    final simTarget = target.clamp(-_maxLeft(motor), _maxRight(motor)).round();
    _lastDirections[motor.id] = direction;
    _machineState = 'En movimiento';
    _animatePosition(motor, current, simTarget.toDouble(), speed);
    try {
      await widget.onCommand(
        command,
        simulatedCommand: '${axis.key}$simTarget',
      );
    } catch (error) {
      _cancelAnimation(motor.id);
      _machineState = 'Error de envío';
      _notify('No se pudo enviar el movimiento: $error');
    }
    if (mounted) setState(() {});
  }

  void _animatePosition(
    Motor motor,
    double start,
    double target,
    double speed,
  ) {
    final effectiveSpeed = speed > 0 ? speed : 1000;
    final durationSeconds = ((target - start).abs() / effectiveSpeed)
        .clamp(0.25, 4)
        .toDouble();
    _animations[motor.id] = _PositionAnimation(
      start: start,
      target: target,
      startedAt: DateTime.now(),
      duration: Duration(milliseconds: (durationSeconds * 1000).round()),
    );
    _animationTimer ??= Timer.periodic(
      const Duration(milliseconds: 35),
      (_) => _tickAnimations(),
    );
  }

  void _tickAnimations() {
    if (!mounted || _paused || _animations.isEmpty) return;
    final now = DateTime.now();
    final completed = <int>[];
    for (final entry in _animations.entries) {
      final animation = entry.value;
      final progress =
          (now.difference(animation.startedAt).inMilliseconds /
                  animation.duration.inMilliseconds)
              .clamp(0, 1)
              .toDouble();
      _positions[entry.key] =
          animation.start + (animation.target - animation.start) * progress;
      if (progress >= 1) completed.add(entry.key);
    }
    for (final id in completed) {
      _animations.remove(id);
    }
    setState(() {
      if (_animations.isEmpty) _machineState = 'Posición estimada';
    });
    if (_animations.isEmpty) {
      _animationTimer?.cancel();
      _animationTimer = null;
    }
  }

  void _cancelAnimation(int motorId) {
    _animations.remove(motorId);
    if (_animations.isEmpty) {
      _animationTimer?.cancel();
      _animationTimer = null;
    }
  }

  void _cancelAnimations() {
    _animations.clear();
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  void _resumeAnimations() {
    final pausedAt = _pauseStartedAt;
    if (pausedAt != null) {
      final pauseDuration = DateTime.now().difference(pausedAt);
      for (final animation in _animations.values) {
        animation.startedAt = animation.startedAt.add(pauseDuration);
      }
      for (final metrics in [
        ..._motorTelemetry.values,
        ..._servoTelemetry.values,
      ]) {
        final startedAt = metrics.startedAt;
        if (startedAt != null) {
          metrics.startedAt = startedAt.add(pauseDuration);
        }
      }
    }
    _pauseStartedAt = null;
  }

  Future<void> _sendAction(String command, {String? simulatedCommand}) async {
    try {
      await widget.onCommand(command, simulatedCommand: simulatedCommand);
      if (command == 'BCSTOP') {
        _cancelAnimations();
        _machineState = 'Detenido';
      } else if (command == 'BCPAUSE') {
        _paused = true;
        _pauseStartedAt = DateTime.now();
        _machineState = 'Pausado';
      } else if (command == 'BCPLAY') {
        _resumeAnimations();
        _paused = false;
        _machineState = 'En movimiento';
      }
      if (mounted) setState(() {});
    } catch (error) {
      _notify('No se pudo enviar el comando: $error');
    }
  }

  Future<void> _setServo() async {
    final servo = _selectedServo;
    final angle = double.tryParse(_servoAngleController.text);
    final speed = double.tryParse(_servoSpeedController.text);
    if (servo == null ||
        angle == null ||
        speed == null ||
        speed < 0 ||
        speed > 720) {
      _notify('Ingresa un ángulo y una velocidad de servo válidos.');
      return;
    }
    final boundedAngle = angle.clamp(0, servo.maxOpen.clamp(0, 180)).round();
    try {
      await widget.onCommand(
        ArduinoProcessCommandBuilder.movement(
          key: servo.key,
          value: boundedAngle,
          speed: speed,
        ),
        simulatedCommand: 'S$boundedAngle',
      );
      setState(() => _servoAngle = boundedAngle.toDouble());
    } catch (error) {
      _notify('No se pudo enviar el movimiento del servo: $error');
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(child: Text('No se pudo cargar el brazo: $_loadError'));
    }
    if (_machines.isEmpty) {
      return const Center(
        child: Text(
          'No hay una máquina tipo brazo con componentes configurados.',
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          final animationHeight = (constraints.maxHeight * 0.38)
              .clamp(120.0, 320.0)
              .toDouble();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: animationHeight, child: _animationPanel()),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _rightControls(colors),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _animationPanel()),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _rightControls(colors),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _animationPanel() => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.precision_manufacturing_outlined),
          title: Text(_selectedMachine?.name ?? 'Brazo SCARA'),
          subtitle: Text(_machineState),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              SizedBox(width: 132, child: _movementTelemetrySidebar()),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ScaraArmCanvas(
                    x: _normalizedPosition(_ArmAxis.x),
                    y: _normalizedPosition(_ArmAxis.y),
                    z: _normalizedPosition(_ArmAxis.z),
                    a: _normalizedPosition(_ArmAxis.a),
                    gripperOpen: _normalizedServoAngle,
                    machineState: _machineState,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _movementTelemetrySidebar() {
    final theme = Theme.of(context);
    final motors = _machineMotors;
    final servos = _machineServos;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'TELEMETRÍA',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final motor in motors)
          _movementTelemetryCard(
            title: _motorTelemetryTitle(motor),
            metrics: _motorTelemetry[motor.id],
            speedUnit: 'pasos/s',
          ),
        for (final servo in servos)
          _movementTelemetryCard(
            title: '${servo.key} · Servo',
            metrics:
                _servoTelemetry[ArduinoProcessCommandBuilder.commandKey(
                  servo.key,
                ).toUpperCase()],
            speedUnit: '°/s',
          ),
      ],
    );
  }

  String _motorTelemetryTitle(Motor motor) {
    for (final axis in _ArmAxis.values) {
      if (_motorFor(axis)?.id == motor.id) return '${axis.key} · ${axis.label}';
    }
    return ArduinoProcessCommandBuilder.commandKey(motor.key).toUpperCase();
  }

  Widget _movementTelemetryCard({
    required String title,
    required _MovementTelemetry? metrics,
    required String speedUnit,
  }) {
    final theme = Theme.of(context);
    final currentSpeed = metrics?.currentSpeed;
    final duration = metrics?.lastDuration;
    final averageSpeed = metrics?.lastAverageSpeed;
    final startedAt = metrics?.startedAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${metrics?.startedAt != null ? 'En movimiento · ' : ''}'
              '${currentSpeed == null ? '—' : currentSpeed.toStringAsFixed(0)} '
              '$speedUnit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
            Text(
              startedAt != null
                  ? 'Tiempo: ${_formatMovementDuration(DateTime.now().difference(startedAt))}'
                  : duration == null
                  ? 'Último: —'
                  : 'Último: ${_formatMovementDuration(duration)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
            if (averageSpeed != null)
              Text(
                'Media: ${averageSpeed.toStringAsFixed(0)} $speedUnit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }

  String _formatMovementDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s';
  }

  List<Widget> _rightControls(ColorScheme colors) => [
    _machineSelector(),
    const SizedBox(height: 12),
    _stateCard(colors),
    const SizedBox(height: 12),
    _processControls(),
    const SizedBox(height: 12),
    _axisControls(),
    const SizedBox(height: 12),
    _servoControls(),
    const SizedBox(height: 12),
    _sensorStates(),
  ];

  Widget _machineSelector() => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<SystemMachine>(
        initialValue: _selectedMachine,
        decoration: const InputDecoration(
          labelText: 'Brazo SCARA',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.precision_manufacturing_outlined),
        ),
        items: _machines
            .map(
              (machine) =>
                  DropdownMenuItem(value: machine, child: Text(machine.name)),
            )
            .toList(),
        onChanged: _selectMachine,
      ),
    ),
  );

  Widget _processControls() {
    final plans = _plansForMachine(_selectedMachine);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Procesos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              const Text('No hay procesos asociados a este brazo.')
            else ...[
              for (final plan in plans)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(plan.process.name),
                  subtitle: Text(
                    plan.process.mqttTopic == null
                        ? 'Al conectar el serial'
                        : 'MQTT · ${plan.process.mqttTopic} = '
                              '${plan.process.mqttExpectedMessage}',
                  ),
                  trailing: Text(
                    '${plan.motors.length + plan.servos.length} mov.',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stateCard(ColorScheme colors) {
    final hasPosition = _ArmAxis.values.any((axis) {
      final motor = _motorFor(axis);
      return motor != null && _knownPositions.contains(motor.id);
    });
    final statusColor = widget.simulating
        ? Colors.blue
        : widget.serialConnected
        ? Colors.green
        : colors.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(Icons.circle, size: 12, color: statusColor),
              label: Text(
                widget.simulating ? 'Simulado' : widget.connectionLabel,
              ),
            ),
            Chip(
              avatar: Icon(
                hasPosition ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 18,
              ),
              label: Text(hasPosition ? _machineState : 'Posición estimada'),
            ),
            FilledButton.tonalIcon(
              onPressed: widget.canSendCommands
                  ? () => _sendAction('BCSTOP', simulatedCommand: 'STOP')
                  : null,
              icon: const Icon(Icons.stop),
              label: const Text('Parar todo'),
            ),
            OutlinedButton.icon(
              onPressed: widget.canSendCommands
                  ? () => _sendAction('BCPAUSE', simulatedCommand: 'PAUSE')
                  : null,
              icon: const Icon(Icons.pause),
              label: const Text('Pausar'),
            ),
            OutlinedButton.icon(
              onPressed: widget.canSendCommands
                  ? () => _sendAction('BCPLAY', simulatedCommand: 'PLAY')
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continuar'),
            ),
            IconButton(
              tooltip: 'Consultar posición (BC?)',
              onPressed: widget.canSendCommands
                  ? () => _sendAction('BC?', simulatedCommand: 'POS')
                  : null,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _axisControls() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Motores', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final axis in _ArmAxis.values) _axisRow(axis),
        ],
      ),
    ),
  );

  Widget _axisRow(_ArmAxis axis) {
    final motor = _motorFor(axis);
    final speedController = _speedControllers[axis];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: _selectedMotors[axis],
            decoration: InputDecoration(
              labelText: '${axis.key} · ${axis.label}',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sin asignar'),
              ),
              ..._machineMotors.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text('${item.key} · ${item.speed.round()} pasos/s'),
                ),
              ),
            ],
            onChanged: (id) {
              setState(() {
                _selectedMotors[axis] = id;
                final selected = _machineMotors
                    .where((item) => item.id == id)
                    .firstOrNull;
                if (selected != null) {
                  _speedControllers[axis]?.dispose();
                  _speedControllers[axis] = TextEditingController(
                    text: selected.speed.round().toString(),
                  );
                }
              });
            },
          ),
          if (motor != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepControllers[axis],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pasos',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: speedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Pasos/s',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mover ${axis.key} en sentido negativo',
                  onPressed: widget.canSendCommands
                      ? () => _move(axis, -1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: 'Mover ${axis.key} en sentido positivo',
                  onPressed: widget.canSendCommands
                      ? () => _move(axis, 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Text(
              '${_positions[motor.id]?.round() ?? 0} pasos'
              '${_knownPositions.contains(motor.id) ? '' : ' · estimado'}'
              ' · ${_velocities[motor.id]?.toStringAsFixed(0) ?? '—'} pasos/s'
              ' · límite −${_maxLeft(motor).round()} / +${_maxRight(motor).round()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _servoControls() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pinza / servo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: _selectedServo?.id,
            decoration: const InputDecoration(labelText: 'Servo'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sin asignar'),
              ),
              ..._machineServos.map(
                (servo) => DropdownMenuItem<int?>(
                  value: servo.id,
                  child: Text(servo.key),
                ),
              ),
            ],
            onChanged: (id) => setState(() {
              _selectedServo = _machineServos
                  .where((servo) => servo.id == id)
                  .firstOrNull;
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _servoAngleController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ángulo',
                    suffixText: '°',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _servoSpeedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Velocidad',
                    suffixText: '°/s',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mover servo',
                onPressed: widget.canSendCommands && _selectedServo != null
                    ? _setServo
                    : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
          Slider(
            value: _servoAngle.clamp(
              0,
              (_selectedServo?.maxOpen ?? 180).clamp(1, 180),
            ),
            max: (_selectedServo?.maxOpen ?? 180).clamp(1, 180),
            label: '${_servoAngle.round()}°',
            onChanged: _selectedServo == null
                ? null
                : (angle) => setState(() {
                    _servoAngle = angle;
                    _servoAngleController.text = angle.round().toString();
                  }),
          ),
        ],
      ),
    ),
  );

  Widget _sensorStates() {
    final sensors = _machineSensors;
    final sensorKeys = <String>{
      for (final motor in _machineMotors)
        if (motor.keySensorLeft != null && motor.keySensorLeft!.isNotEmpty)
          motor.keySensorLeft!,
      for (final motor in _machineMotors)
        if (motor.keySensorRight != null && motor.keySensorRight!.isNotEmpty)
          motor.keySensorRight!,
      for (final sensor in sensors) sensor.key,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sensores de límite',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (sensorKeys.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No hay sensores configurados para este brazo.'),
              )
            else
              Wrap(
                spacing: 8,
                children: [
                  for (final key in sensorKeys)
                    Chip(
                      avatar: Icon(
                        Icons.sensors,
                        size: 16,
                        color: _activeSensors.contains(key.toUpperCase())
                            ? Colors.orange
                            : null,
                      ),
                      label: Text(
                        '$key · ${_activeSensors.contains(key.toUpperCase()) ? 'activo' : 'libre'}',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HmiProcessPlan {
  const _HmiProcessPlan({
    required this.process,
    required this.motors,
    required this.servos,
  });

  final Process process;
  final List<ProcessMotors> motors;
  final List<ProcessServo> servos;
}

class _PositionAnimation {
  _PositionAnimation({
    required this.start,
    required this.target,
    required this.startedAt,
    required this.duration,
  });

  final double start;
  final double target;
  DateTime startedAt;
  final Duration duration;
}

class _MovementTelemetry {
  double? currentSpeed;
  Duration? lastDuration;
  double? lastAverageSpeed;
  DateTime? startedAt;
  double? startValue;
  double? target;
  DateTime? lastSampleAt;
  double? lastSample;
}
