import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../mqtt/data/mqtt_connection_service.dart';
import '../../../mqtt/domain/entities/mqtt_incoming_message.dart';
import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../../domain/entities/motor.dart';
import '../../domain/entities/process.dart';
import '../../domain/entities/process_motors.dart';
import '../../domain/entities/process_servo.dart';
import '../../domain/entities/servo.dart';
import '../../domain/entities/system_machine.dart';
import '../../domain/repositories/system_repository.dart';
import '../../domain/services/arduino_process_command_builder.dart';
import '../../domain/services/system_configuration_service.dart';

class ProcessProgrammingPage extends StatefulWidget {
  const ProcessProgrammingPage({super.key});

  @override
  State<ProcessProgrammingPage> createState() => _ProcessProgrammingPageState();
}

class _ProcessProgrammingPageState extends State<ProcessProgrammingPage> {
  final _runningProcesses = <int>{};
  final List<_SavedPlan> _queuedPlans = [];
  final List<MqttIncomingMessage> _pendingMqttMessages = [];
  final Set<String> _mqttTopics = {};

  List<SystemMachine> _machines = const [];
  List<SystemMachine> _allMachines = const [];
  List<Motor> _motors = const [];
  List<Servo> _servos = const [];
  List<_SavedPlan> _plans = const [];
  bool _loading = true;
  bool _wasConnected = false;
  bool _wasSimulating = false;
  bool _startupQueued = false;
  bool _serialReady = false;
  bool _processTelemetryEnabled = false;
  int _readyProbeAttempts = 0;
  Timer? _readyProbeTimer;
  int _executionGeneration = 0;
  String? _executionMessage;
  Set<String> _pendingAxes = {};
  final Map<String, _PendingServo> _pendingServos = {};
  Completer<void>? _groupFinished;
  bool _drainingQueue = false;
  StreamSubscription<TelemetryLogEntry>? _lineSubscription;
  StreamSubscription<TelemetryState>? _telemetrySubscription;
  StreamSubscription<SerialConnectionState>? _connectionSubscription;
  StreamSubscription<MqttIncomingMessage>? _mqttMessageSubscription;
  StreamSubscription<void>? _machineCatalogSubscription;
  StreamSubscription<void>? _processChangesSubscription;

  ConnectionBloc get _connection => GetIt.I<ConnectionBloc>();
  TelemetryCubit get _telemetry => GetIt.I<TelemetryCubit>();
  bool get _isSimulating => _telemetry.state.isSimulating;
  bool get _hasExecutionTransport =>
      _connection.state.isConnected || _isSimulating;

  @override
  void initState() {
    super.initState();
    _lineSubscription = _telemetry.lineEvents.listen(_onSerialLine);
    _wasSimulating = _isSimulating;
    _serialReady = _isSimulating && _telemetry.isSimulationReady;
    _telemetrySubscription = _telemetry.stream.listen(_onTelemetryStateChanged);
    _connectionSubscription = _connection.stream.listen(_onConnectionChanged);
    _mqttMessageSubscription = GetIt.I<MqttConnectionService>().messages.listen(
      _onMqttMessage,
    );
    final configurationService = GetIt.I<SystemConfigurationService>();
    _machineCatalogSubscription = configurationService.machineCatalogChanges
        .listen((_) {
          if (!mounted) return;
          setState(() => _loading = true);
          _loadOptions();
        });
    _processChangesSubscription = configurationService.processChanges.listen((
      _,
    ) {
      if (!mounted) return;
      setState(() => _loading = true);
      _loadOptions();
    });
    _wasConnected = _connection.state.isConnected;
    _loadOptions();
  }

  @override
  void dispose() {
    _lineSubscription?.cancel();
    _telemetrySubscription?.cancel();
    _connectionSubscription?.cancel();
    _mqttMessageSubscription?.cancel();
    _machineCatalogSubscription?.cancel();
    _processChangesSubscription?.cancel();
    _readyProbeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final repository = GetIt.I<SystemRepository>();
      _allMachines = await repository.getMachines();
      _machines = _allMachines
          .where((machine) => machine.parentMachineId == null)
          .toList();
      _motors = await repository.getMotors();
      _servos = await repository.getServos();
      final processes = await repository.getProcesses();
      final plans = <_SavedPlan>[];
      for (final process in processes) {
        final motors = await repository.getProcessMotors(process.id);
        final servos = await repository.getProcessServos(process.id);
        plans.add(
          _SavedPlan(
            process: process.machineId == null
                ? Process(
                    id: process.id,
                    name: process.name,
                    order: process.order,
                    machineId: _inferMachineId(process, motors, servos),
                    mqttTopic: process.mqttTopic,
                    mqttExpectedMessage: process.mqttExpectedMessage,
                  )
                : process,
            motors: motors,
            servos: servos,
          ),
        );
      }
      _plans = plans;
    } catch (error) {
      _executionMessage = 'No se pudo cargar la configuración: $error';
    }
    if (!mounted) return;
    setState(() => _loading = false);
    final pendingMessages = List<MqttIncomingMessage>.of(_pendingMqttMessages);
    _pendingMqttMessages.clear();
    for (final message in pendingMessages) {
      _handleMqttMessage(message);
    }
    if (_hasExecutionTransport) _queueStartupPlans();
  }

  void _onMqttMessage(MqttIncomingMessage message) {
    if (_mqttTopics.add(message.topic) && mounted) setState(() {});
    if (_loading) {
      _pendingMqttMessages.add(message);
      return;
    }
    _handleMqttMessage(message);
  }

  void _handleMqttMessage(MqttIncomingMessage message) {
    final matchingPlans = _plans.where(
      (plan) =>
          plan.process.mqttTopic == message.topic &&
          plan.process.mqttExpectedMessage == message.payload &&
          (plan.motors.isNotEmpty || plan.servos.isNotEmpty),
    );
    for (final plan in matchingPlans) {
      _queuePlan(plan);
    }
  }

  void _onTelemetryStateChanged(TelemetryState state) {
    if (state.isSimulating == _wasSimulating) return;
    _wasSimulating = state.isSimulating;
    _startupQueued = false;
    _serialReady = state.isSimulating && _telemetry.isSimulationReady;
    _executionGeneration++;
    _readyProbeTimer?.cancel();
    _readyProbeTimer = null;
    if (!state.isSimulating) {
      _queuedPlans.clear();
      _runningProcesses.clear();
      _failPending(StateError('Se detuvo la emulación.'));
    } else if (_serialReady && !_loading) {
      _queueStartupPlans();
    }
    _drainQueue();
    if (mounted) setState(() {});
  }

  int? _inferMachineId(
    Process process,
    List<ProcessMotors> motors,
    List<ProcessServo> servos,
  ) {
    final motor = _motors
        .where((item) => motors.any((action) => action.motorId == item.id))
        .firstOrNull;
    final servo = _servos
        .where((item) => servos.any((action) => action.servoId == item.id))
        .firstOrNull;
    final componentMachineId = motor?.systemMachineId ?? servo?.machineId;
    if (componentMachineId == null) return null;
    return _allMachines
            .where((item) => item.id == componentMachineId)
            .firstOrNull
            ?.parentMachineId ??
        componentMachineId;
  }

  void _onConnectionChanged(SerialConnectionState state) {
    if (state.isConnected && !_wasConnected) {
      _wasConnected = true;
      _startupQueued = false;
      _serialReady = false;
      _readyProbeTimer?.cancel();
      _readyProbeTimer = null;
      _executionGeneration++;
      _processTelemetryEnabled = false;
      if (!_loading) _queueStartupPlans();
      return;
    }
    if (!state.isConnected && _wasConnected) {
      _wasConnected = false;
      _startupQueued = false;
      _serialReady = false;
      _queuedPlans.clear();
      _runningProcesses.clear();
      _readyProbeTimer?.cancel();
      _readyProbeTimer = null;
      _executionGeneration++;
      _failPending(StateError('Se perdió la conexión serial.'));
    }
  }

  void _queueStartupPlans() {
    if (_startupQueued || !_hasExecutionTransport) {
      return;
    }
    final activePlans = _plans
        .where((plan) => plan.motors.isNotEmpty || plan.servos.isNotEmpty)
        .toList();
    final startupPlans = activePlans
        .where((plan) => plan.process.mqttTopic == null)
        .toList();
    if (startupPlans.isEmpty) {
      _startupQueued = true;
      _drainQueue();
      return;
    }
    if (_isSimulating && !_telemetry.isSimulationReady) {
      if (mounted) {
        setState(
          () => _executionMessage = 'Esperando que el emulador esté listo.',
        );
      }
      return;
    }
    if (!_isSimulating && !_serialReady) {
      _startArduinoReadyProbe();
      return;
    }
    _startupQueued = true;
    if (startupPlans.any((plan) => plan.servos.isNotEmpty)) {
      _ensureProcessTelemetry();
    }
    for (final plan in startupPlans) {
      _queuePlan(plan);
    }
  }

  void _startArduinoReadyProbe() {
    if (_readyProbeTimer != null) return;
    _readyProbeAttempts = 0;
    _probeArduino();
    _readyProbeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _probeArduino(),
    );
    if (mounted) {
      setState(
        () => _executionMessage =
            'Esperando respuesta del Arduino (BC,INFO,LISTO o BC,STATUS...).',
      );
    }
  }

  void _probeArduino() {
    if (!_connection.state.isConnected) {
      _readyProbeTimer?.cancel();
      _readyProbeTimer = null;
      return;
    }
    if (_readyProbeAttempts >= 15) {
      _readyProbeTimer?.cancel();
      _readyProbeTimer = null;
      if (mounted) {
        setState(
          () => _executionMessage =
              'No se recibió respuesta del Arduino. Verifica el puerto y envía BC? para comprobar la conexión.',
        );
      }
      return;
    }
    _readyProbeAttempts++;
    _connection.add(const CommandSent('BC?'));
  }

  void _queuePlan(_SavedPlan plan) {
    if (plan.motors.isEmpty && plan.servos.isEmpty) return;
    _queuedPlans.add(plan);
    _runningProcesses.add(plan.process.id);
    if (plan.servos.isNotEmpty) _ensureProcessTelemetry();
    if (mounted) {
      setState(
        () => _executionMessage =
            'En cola: "${plan.process.name}" (${_queuedPlans.length}).',
      );
    }
    if (_connection.state.isConnected && !_serialReady && !_isSimulating) {
      _startArduinoReadyProbe();
    }
    _drainQueue();
  }

  bool get _queueTransportReady =>
      _hasExecutionTransport &&
      (_isSimulating ? _telemetry.isSimulationReady : _serialReady);

  void _drainQueue() {
    if (_drainingQueue || !_queueTransportReady || _queuedPlans.isEmpty) return;
    _drainingQueue = true;
    unawaited(_drainQueuedPlans(_executionGeneration));
  }

  Future<void> _drainQueuedPlans(int generation) async {
    while (_queuedPlans.isNotEmpty) {
      if (generation != _executionGeneration) {
        _queuedPlans.clear();
        _runningProcesses.clear();
        break;
      }

      final plan = _queuedPlans.removeAt(0);
      if (mounted) {
        setState(
          () => _executionMessage = 'Ejecutando "${plan.process.name}".',
        );
      }
      try {
        await _executePlan(plan);
      } catch (error) {
        if (mounted) {
          setState(
            () => _executionMessage = 'Proceso "${plan.process.name}": $error',
          );
        }
      } finally {
        if (!_queuedPlans.any(
          (queued) => queued.process.id == plan.process.id,
        )) {
          _runningProcesses.remove(plan.process.id);
        }
        if (mounted) setState(() {});
      }
    }
    _drainingQueue = false;
    _drainQueue();
  }

  Future<void> _executePlan(_SavedPlan plan) async {
    if (!_hasExecutionTransport) {
      throw StateError('Se requiere serial conectado o emulación activa.');
    }
    final executionGeneration = _executionGeneration;
    if (_isSimulating && !_telemetry.isSimulationReady) {
      for (
        var attempt = 0;
        attempt < 100 && _isSimulating && !_telemetry.isSimulationReady;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!_isSimulating || !_telemetry.isSimulationReady) {
        throw StateError(
          'El emulador no quedó listo para ejecutar el proceso.',
        );
      }
    }
    final motorById = {for (final item in _motors) item.id: item};
    final servoById = {for (final item in _servos) item.id: item};
    final groups = <int, List<_WireAction>>{};
    for (final item in plan.motors) {
      final motor = motorById[item.motorId];
      if (motor == null) {
        throw StateError('No se encontró el motor ${item.name}.');
      }
      groups
          .putIfAbsent(item.order, () => [])
          .add(
            _WireAction(
              key: _commandKey(motor.key),
              value: item.steps,
              speed: item.speed,
              isServo: false,
            ),
          );
    }
    for (final item in plan.servos) {
      final servo = servoById[item.servoId];
      if (servo == null) {
        throw StateError('No se encontró el servo ${item.name}.');
      }
      groups
          .putIfAbsent(item.order, () => [])
          .add(
            _WireAction(
              key: _commandKey(servo.key),
              value: item.openValue,
              speed: item.speed,
              isServo: true,
            ),
          );
    }

    for (final order in groups.keys.toList()..sort()) {
      final actions = groups[order]!;
      final line = ArduinoProcessCommandBuilder.line(
        actions.map(
          (item) => ArduinoProcessCommandBuilder.movement(
            key: item.key,
            value: item.value,
            speed: item.speed,
          ),
        ),
      );
      await _sendGroup(line, actions);
      if (executionGeneration != _executionGeneration) {
        throw StateError('La ejecución del proceso fue interrumpida.');
      }
    }
    if (mounted) {
      setState(
        () => _executionMessage = 'Proceso "${plan.process.name}" finalizado.',
      );
    }
  }

  Future<void> _sendGroup(String line, List<_WireAction> actions) async {
    final axes = actions.map((item) => item.key.toUpperCase()).toSet();
    if (axes.length != actions.length) {
      throw StateError(
        'Un actuador no puede tener dos órdenes en el mismo paso.',
      );
    }
    _pendingAxes = axes;
    _pendingServos
      ..clear()
      ..addEntries(
        actions
            .where((item) => item.isServo)
            .expand(
              (item) => [
                MapEntry(
                  'BCS',
                  _PendingServo(item.key.toUpperCase(), item.value),
                ),
                MapEntry(
                  item.key.toUpperCase(),
                  _PendingServo(item.key.toUpperCase(), item.value),
                ),
              ],
            ),
      );
    final finished = Completer<void>();
    _groupFinished = finished;
    if (mounted) {
      setState(() => _executionMessage = 'Enviando por serial: $line');
    }
    if (_isSimulating) {
      _telemetry.recordSent(line);
      _telemetry.sendSimulatedCommand(line);
      await Future<void>.delayed(const Duration(seconds: 5));
      if (!_isSimulating) {
        throw StateError('Se detuvo la emulación durante el paso.');
      }
      _groupFinished = null;
      _pendingAxes = {};
      _pendingServos.clear();
      return;
    }
    _connection.add(CommandSent(line));
    final longest = actions
        .map((item) => item.speed == 0 ? 0.0 : item.value.abs() / item.speed)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final timeout = Duration(
      seconds: (longest * 2 + 15).ceil().clamp(15, 3600).toInt(),
    );
    try {
      await finished.future.timeout(timeout);
    } finally {
      if (identical(_groupFinished, finished)) {
        _groupFinished = null;
        _pendingAxes = {};
        _pendingServos.clear();
      }
    }
  }

  void _onSerialLine(TelemetryLogEntry entry) {
    final line = entry.line.trim();
    if ((entry.source == TelemetrySource.serial ||
            entry.source == TelemetrySource.simulated) &&
        (line == 'BC,INFO,LISTO' || line.startsWith('BC,STATUS,'))) {
      _serialReady = true;
      _readyProbeTimer?.cancel();
      _readyProbeTimer = null;
      _readyProbeAttempts = 0;
      if (mounted && !_startupQueued) {
        setState(
          () => _executionMessage = 'Arduino listo; iniciando procesos.',
        );
      }
      _queueStartupPlans();
    }
    _drainQueue();
    if (entry.source == TelemetrySource.serial &&
        line.startsWith('BC,EVT,FIN,')) {
      final parts = line.split(',');
      if (parts.length >= 4) {
        _completePendingAxis(parts[3]);
      }
    } else if (entry.source == TelemetrySource.serial &&
        line.startsWith('BC,EVT,SENSOR,')) {
      final parts = line.split(',');
      if (parts.length >= 4) _completePendingAxis(parts[3]);
    } else if (entry.source == TelemetrySource.serial &&
        line.startsWith('BC,ERR,SENSOR_BLOQUEADO')) {
      final parts = line.split(',');
      final axis = parts.length >= 4
          ? parts[3]
          : parts.length == 3
          ? parts[2].split(':').last
          : '';
      if (axis.trim().isNotEmpty) {
        _completePendingAxis(axis);
        if (mounted) {
          setState(
            () => _executionMessage =
                'El motor ${axis.trim()} alcanzó su sensor; continúa el proceso.',
          );
        }
      }
    } else if (entry.source == TelemetrySource.serial &&
        line.startsWith('BC') &&
        !line.startsWith('BC,')) {
      final parts = line.split(',');
      if (parts.length >= 4) {
        final key = parts[0].trim().toUpperCase();
        final angle = double.tryParse(parts[2].trim());
        final target = double.tryParse(parts[3].trim());
        final pending = _pendingServos[key];
        if (pending != null &&
            angle != null &&
            target != null &&
            (target - pending.target).abs() < 0.5 &&
            (angle - target).abs() < 0.5) {
          _pendingServos.remove(key);
          _pendingAxes.remove(pending.commandKey);
          if (_pendingAxes.isEmpty && _groupFinished?.isCompleted == false) {
            _groupFinished!.complete();
          }
        }
      }
    } else if (entry.source == TelemetrySource.serial &&
        line.startsWith('BC,ERR,')) {
      _executionGeneration++;
      _failPending(StateError(line));
    } else if (entry.source == TelemetrySource.serial &&
        line == 'BC,EVT,STOP') {
      _executionGeneration++;
      _failPending(StateError('El movimiento fue detenido.'));
    }
  }

  void _completePendingAxis(String axis) {
    final normalized = _commandKey(axis).toUpperCase();
    _pendingAxes.remove(normalized);
    if (_pendingAxes.isEmpty && _groupFinished?.isCompleted == false) {
      _groupFinished!.complete();
    }
  }

  void _failPending(Object error) {
    final finished = _groupFinished;
    if (finished != null && !finished.isCompleted) {
      finished.completeError(error);
    }
    _groupFinished = null;
    _pendingAxes = {};
    _pendingServos.clear();
  }

  Future<void> _createProcess() async {
    final draft = await showDialog<_ProcessDraft>(
      context: context,
      builder: (context) => _ProcessCreateDialog(
        machines: _machines,
        mqttTopics: _mqttTopics.toList()..sort(),
      ),
    );
    if (draft == null) return;
    final process = Process(
      id: DateTime.now().microsecondsSinceEpoch,
      name: draft.name,
      order: 0,
      machineId: draft.machine.id,
      mqttTopic: draft.mqttTopic,
      mqttExpectedMessage: draft.mqttExpectedMessage,
    );
    try {
      await GetIt.I<SystemConfigurationService>().saveProcessDefinition(
        process,
      );
      await _loadOptions();
      if (!mounted) return;
      final plan = _plans.firstWhere((item) => item.process.id == process.id);
      await _openProcess(plan);
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _openProcess(_SavedPlan plan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ProcessDetailPage(
          initialPlan: plan,
          machines: _machines,
          allMachines: _allMachines,
          mqttTopics: _mqttTopics.toList()..sort(),
          motors: _motors,
          servos: _servos,
          onRunProcess: (processId) {
            if (!_hasExecutionTransport) {
              _message('Conecta el serial o inicia la emulación.');
              return;
            }
            if (_runningProcesses.contains(processId)) {
              _message('El proceso ya está en cola o ejecutándose.');
              return;
            }
            final currentPlan = _plans
                .where((item) => item.process.id == processId)
                .firstOrNull;
            if (currentPlan != null) _queuePlan(currentPlan);
          },
          onProcessChanged: (process) async {
            await GetIt.I<SystemConfigurationService>().saveProcessDefinition(
              process,
            );
            await _loadOptions();
          },
          allowDelete: true,
          onChanged: _loadOptions,
        ),
      ),
    );
  }

  Future<void> _deleteProcess(_SavedPlan plan) async {
    if (_runningProcesses.contains(plan.process.id)) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proceso'),
        content: Text(
          '¿Quieres eliminar "${plan.process.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await GetIt.I<SystemConfigurationService>().deleteProcess(
        plan.process.id,
      );
      await _loadOptions();
      if (mounted) _message('Proceso eliminado.');
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _ensureProcessTelemetry() {
    if (_processTelemetryEnabled ||
        !_connection.state.isConnected ||
        _isSimulating) {
      return;
    }
    _connection.add(const CommandSent('BCT100'));
    _processTelemetryEnabled = true;
  }

  void _sendProcessControlCommand(String command) {
    if (_isSimulating) {
      _telemetry.recordSent(command);
      _telemetry.sendSimulatedCommand(command);
      return;
    }
    _connection.add(CommandSent(command));
  }

  static String _commandKey(String key) =>
      ArduinoProcessCommandBuilder.commandKey(key);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Procesos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            FilledButton.icon(
              onPressed: _machines.isEmpty ? null : _createProcess,
              icon: const Icon(Icons.add),
              label: const Text('Crear proceso'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _connectionControls(),
        if (_executionMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_executionMessage!),
          ),
        const SizedBox(height: 12),
        if (_plans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('Crea un proceso para empezar.')),
          ),
        for (final plan in _plans)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: Text(plan.process.name),
              subtitle: Text(
                plan.process.mqttTopic == null
                    ? 'Al conectar el serial'
                    : 'MQTT · ${plan.process.mqttTopic} = '
                          '${plan.process.mqttExpectedMessage}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _runningProcesses.contains(plan.process.id)
                        ? 'Proceso en cola o en ejecución'
                        : 'Ejecutar proceso',
                    onPressed:
                        !_hasExecutionTransport ||
                            _runningProcesses.contains(plan.process.id) ||
                            (plan.motors.isEmpty && plan.servos.isEmpty)
                        ? null
                        : () => _queuePlan(plan),
                    icon: _runningProcesses.contains(plan.process.id)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: _runningProcesses.contains(plan.process.id)
                        ? 'No se puede eliminar mientras se ejecuta'
                        : 'Eliminar proceso',
                    onPressed: _runningProcesses.contains(plan.process.id)
                        ? null
                        : () => _deleteProcess(plan),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _openProcess(plan),
            ),
          ),
      ],
    );
  }

  Widget _connectionControls() => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            _isSimulating
                ? Icons.developer_mode
                : _connection.state.isConnected
                ? Icons.usb
                : Icons.usb_off,
            color: _isSimulating || _connection.state.isConnected
                ? Colors.green
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSimulating
                  ? _telemetry.isSimulationReady
                        ? 'Emulador listo · 5 segundos por paso'
                        : 'Emulador ejecutando homing inicial'
                  : _connection.state.isConnected
                  ? _serialReady
                        ? 'Arduino listo · procesos al conectar'
                        : 'Serial conectado · esperando respuesta del Arduino'
                  : 'Conecta el serial o inicia la emulación',
            ),
          ),
          IconButton(
            tooltip: 'Pausar',
            onPressed: _hasExecutionTransport
                ? () => _sendProcessControlCommand('BCPAUSE')
                : null,
            icon: const Icon(Icons.pause),
          ),
          IconButton(
            tooltip: 'Continuar',
            onPressed: _hasExecutionTransport
                ? () => _sendProcessControlCommand('BCPLAY')
                : null,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Detener todo',
            color: Colors.red,
            onPressed: _hasExecutionTransport
                ? () => _sendProcessControlCommand('BCSTOP')
                : null,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
    ),
  );
}

class _ActionDraft {
  const _ActionDraft({
    required this.kind,
    required this.key,
    required this.order,
    required this.value,
    required this.speed,
    required this.editingMotorId,
    required this.editingServoId,
    required this.motorActionId,
    required this.servoActionId,
    this.motor,
    this.servo,
  });

  final String kind;
  final String key;
  final Motor? motor;
  final Servo? servo;
  final int order;
  final double value;
  final double speed;
  final int? editingMotorId;
  final int? editingServoId;
  final int? motorActionId;
  final int? servoActionId;
}

class _WireAction {
  const _WireAction({
    required this.key,
    required this.value,
    required this.speed,
    required this.isServo,
  });

  final String key;
  final double value;
  final double speed;
  final bool isServo;
}

class _SavedPlan {
  const _SavedPlan({
    required this.process,
    required this.motors,
    required this.servos,
  });

  final Process process;
  final List<ProcessMotors> motors;
  final List<ProcessServo> servos;
}

class _PendingServo {
  const _PendingServo(this.commandKey, this.target);

  final String commandKey;
  final double target;
}

class _ProcessDraft {
  const _ProcessDraft({
    required this.name,
    required this.machine,
    required this.mqttTopic,
    required this.mqttExpectedMessage,
  });

  final String name;
  final SystemMachine machine;
  final String? mqttTopic;
  final String? mqttExpectedMessage;
}

enum _ProcessActivation { serial, mqtt }

class _ProcessCreateDialog extends StatefulWidget {
  const _ProcessCreateDialog({
    required this.machines,
    required this.mqttTopics,
    this.initialProcess,
  });

  final List<SystemMachine> machines;
  final List<String> mqttTopics;
  final Process? initialProcess;

  @override
  State<_ProcessCreateDialog> createState() => _ProcessCreateDialogState();
}

class _ProcessCreateDialogState extends State<_ProcessCreateDialog> {
  final _name = TextEditingController();
  final _topic = TextEditingController();
  final _expectedMessage = TextEditingController();
  SystemMachine? _machine;
  String? _selectedTopic;
  _ProcessActivation _activation = _ProcessActivation.serial;

  @override
  void initState() {
    super.initState();
    final process = widget.initialProcess;
    _name.text = process?.name ?? '';
    _machine =
        widget.machines
            .where((machine) => machine.id == process?.machineId)
            .firstOrNull ??
        widget.machines.firstOrNull;
    _topic.text = process?.mqttTopic ?? '';
    _expectedMessage.text = process?.mqttExpectedMessage ?? '';
    if (process?.mqttTopic != null) {
      _activation = _ProcessActivation.mqtt;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    _expectedMessage.dispose();
    super.dispose();
  }

  bool get _editing => widget.initialProcess != null;

  void _submit() {
    final machine = _machine;
    final name = _name.text.trim();
    if (name.isEmpty || machine == null) return;
    final mqttTopic = _activation == _ProcessActivation.mqtt
        ? _topic.text.trim()
        : null;
    final mqttExpectedMessage = _activation == _ProcessActivation.mqtt
        ? _expectedMessage.text
        : null;
    if (_activation == _ProcessActivation.mqtt &&
        (mqttTopic == null ||
            mqttTopic.isEmpty ||
            mqttExpectedMessage!.isEmpty)) {
      return;
    }
    Navigator.of(context).pop(
      _ProcessDraft(
        name: name,
        machine: machine,
        mqttTopic: mqttTopic,
        mqttExpectedMessage: mqttExpectedMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_editing ? 'Editar proceso' : 'Crear proceso'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SystemMachine>(
              initialValue: _machine,
              decoration: const InputDecoration(
                labelText: 'Máquina',
                border: OutlineInputBorder(),
              ),
              items: widget.machines
                  .map(
                    (machine) => DropdownMenuItem(
                      value: machine,
                      child: Text(machine.name),
                    ),
                  )
                  .toList(),
              onChanged: _editing
                  ? null
                  : (value) => setState(() {
                      _machine = value;
                    }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_ProcessActivation>(
              initialValue: _activation,
              decoration: const InputDecoration(
                labelText: 'Activar proceso cuando',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: _ProcessActivation.serial,
                  child: Text('Al conectar el serial'),
                ),
                DropdownMenuItem(
                  value: _ProcessActivation.mqtt,
                  child: Text('Al recibir un mensaje MQTT'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _activation = value);
              },
            ),
            if (_activation == _ProcessActivation.mqtt) ...[
              const SizedBox(height: 12),
              if (widget.mqttTopics.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedTopic,
                  decoration: const InputDecoration(
                    labelText: 'Topics MQTT recibidos',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.mqttTopics
                      .map(
                        (topic) =>
                            DropdownMenuItem(value: topic, child: Text(topic)),
                      )
                      .toList(),
                  onChanged: (topic) {
                    if (topic != null) {
                      setState(() {
                        _selectedTopic = topic;
                        _topic.text = topic;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _topic,
                onChanged: (_) => setState(() => _selectedTopic = null),
                decoration: const InputDecoration(
                  labelText: 'Topic MQTT (también puedes escribirlo)',
                  hintText: 'maquina/entrada',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expectedMessage,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Texto esperado',
                  hintText: 'INICIAR',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed:
            _name.text.trim().isNotEmpty &&
                _machine != null &&
                (_activation == _ProcessActivation.serial ||
                    (_topic.text.trim().isNotEmpty &&
                        _expectedMessage.text.isNotEmpty))
            ? _submit
            : null,
        child: Text(_editing ? 'Guardar' : 'Crear'),
      ),
    ],
  );
}

class _ProcessDetailPage extends StatefulWidget {
  const _ProcessDetailPage({
    required this.initialPlan,
    required this.machines,
    required this.allMachines,
    required this.mqttTopics,
    required this.motors,
    required this.servos,
    required this.onRunProcess,
    required this.onProcessChanged,
    required this.allowDelete,
    required this.onChanged,
  });

  final _SavedPlan initialPlan;
  final List<SystemMachine> machines;
  final List<SystemMachine> allMachines;
  final List<String> mqttTopics;
  final List<Motor> motors;
  final List<Servo> servos;
  final void Function(int processId) onRunProcess;
  final Future<void> Function(Process process) onProcessChanged;
  final bool allowDelete;
  final Future<void> Function() onChanged;

  @override
  State<_ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<_ProcessDetailPage> {
  late _SavedPlan _plan = widget.initialPlan;
  bool _saving = false;

  int? get _machineId => _plan.process.machineId;

  Set<int> get _machineIds {
    final id = _machineId;
    if (id == null) return const {};
    return {
      id,
      ...widget.allMachines
          .where((item) => item.parentMachineId == id)
          .map((item) => item.id),
    };
  }

  List<Motor> get _machineMotors => widget.motors
      .where((item) => _machineIds.contains(item.systemMachineId))
      .toList();

  List<Servo> get _machineServos => widget.servos
      .where((item) => _machineIds.contains(item.machineId))
      .toList();

  Future<void> _editProcess() async {
    if (_saving) return;
    final draft = await showDialog<_ProcessDraft>(
      context: context,
      builder: (context) => _ProcessCreateDialog(
        machines: widget.machines,
        mqttTopics: widget.mqttTopics,
        initialProcess: _plan.process,
      ),
    );
    if (draft == null) return;
    final updatedProcess = Process(
      id: _plan.process.id,
      name: draft.name,
      order: _plan.process.order,
      machineId: _plan.process.machineId,
      mqttTopic: draft.mqttTopic,
      mqttExpectedMessage: draft.mqttExpectedMessage,
    );
    setState(() => _saving = true);
    try {
      await widget.onProcessChanged(updatedProcess);
      if (!mounted) return;
      setState(() {
        _plan = _SavedPlan(
          process: updatedProcess,
          motors: _plan.motors,
          servos: _plan.servos,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proceso actualizado.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addMovement({
    ProcessMotors? editingMotor,
    ProcessServo? editingServo,
  }) async {
    if (_saving || _machineId == null) return;
    final action = await showDialog<_ActionDraft>(
      context: context,
      builder: (context) => _AddMovementDialog(
        motors: _machineMotors,
        servos: _machineServos,
        existingMotors: _plan.motors,
        existingServos: _plan.servos,
        editingMotor: editingMotor,
        editingServo: editingServo,
        allowTypeChange: true,
      ),
    );
    if (action == null) return;

    final processId = _plan.process.id;
    final motors = _plan.motors
        .where((item) => item.id != action.editingMotorId)
        .toList();
    final servos = _plan.servos
        .where((item) => item.id != action.editingServoId)
        .toList();
    if (action.motor != null) {
      motors.add(
        ProcessMotors(
          id: action.motorActionId ?? DateTime.now().microsecondsSinceEpoch,
          processId: processId,
          motorId: action.motor!.id,
          name: action.motor!.key,
          order: action.order,
          steps: action.value,
          speed: action.speed,
        ),
      );
    } else if (action.servo != null) {
      servos.add(
        ProcessServo(
          id: action.servoActionId ?? DateTime.now().microsecondsSinceEpoch,
          processId: processId,
          servoId: action.servo!.id,
          name: action.servo!.key,
          order: action.order,
          openValue: action.value,
          speed: action.speed,
        ),
      );
    }

    await _saveMovements(
      motors,
      servos,
      isEdit: editingMotor != null || editingServo != null,
    );
  }

  Future<void> _deleteMovement({
    ProcessMotors? motor,
    ProcessServo? servo,
  }) async {
    if (!widget.allowDelete || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Quieres eliminar este movimiento del proceso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveMovements(
      _plan.motors.where((item) => item.id != motor?.id).toList(),
      _plan.servos.where((item) => item.id != servo?.id).toList(),
      isEdit: true,
      isDelete: true,
    );
  }

  Future<void> _saveMovements(
    List<ProcessMotors> motors,
    List<ProcessServo> servos, {
    required bool isEdit,
    bool isDelete = false,
  }) async {
    setState(() => _saving = true);
    try {
      final updated = _SavedPlan(
        process: _plan.process,
        motors: motors,
        servos: servos,
      );
      await GetIt.I<SystemConfigurationService>().saveProcessConfiguration(
        process: _plan.process,
        motors: motors,
        servos: servos,
      );
      await widget.onChanged();
      if (!mounted) return;
      setState(() => _plan = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDelete
                ? 'Movimiento eliminado.'
                : isEdit
                ? 'Movimiento actualizado.'
                : 'Movimiento agregado al proceso.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <int, List<_StepMovement>>{};
    for (final item in _plan.motors) {
      final motor = widget.motors
          .where((candidate) => candidate.id == item.motorId)
          .firstOrNull;
      groups
          .putIfAbsent(item.order, () => [])
          .add(
            _StepMovement(
              name: motor?.key ?? item.name,
              kind: 'Motor',
              value: '${item.steps.toInt()} pasos',
              speed: '${item.speed.toInt()} pasos/s',
              isServo: false,
              command: ArduinoProcessCommandBuilder.movement(
                key: motor?.key ?? item.name,
                value: item.steps,
                speed: item.speed,
              ),
              onEdit: () => _addMovement(editingMotor: item),
              onDelete: widget.allowDelete
                  ? () => _deleteMovement(motor: item)
                  : null,
            ),
          );
    }
    for (final item in _plan.servos) {
      final servo = widget.servos
          .where((candidate) => candidate.id == item.servoId)
          .firstOrNull;
      groups
          .putIfAbsent(item.order, () => [])
          .add(
            _StepMovement(
              name: servo?.key ?? item.name,
              kind: 'Servo',
              value: '${item.openValue.toInt()}°',
              speed: '${item.speed.toInt()}°/s',
              isServo: true,
              command: ArduinoProcessCommandBuilder.movement(
                key: servo?.key ?? item.name,
                value: item.openValue,
                speed: item.speed,
              ),
              onEdit: () => _addMovement(editingServo: item),
              onDelete: widget.allowDelete
                  ? () => _deleteMovement(servo: item)
                  : null,
            ),
          );
    }
    final machineName = widget.machines
        .where((item) => item.id == _machineId)
        .firstOrNull
        ?.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.process.name),
        actions: [
          IconButton(
            tooltip: 'Editar proceso',
            onPressed: _saving ? null : _editProcess,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.precision_manufacturing),
              title: Text(machineName ?? 'Máquina no disponible'),
              subtitle: Text(
                _plan.process.mqttTopic == null
                    ? 'Se inicia al conectar el serial'
                    : 'Se inicia con MQTT: ${_plan.process.mqttTopic} = '
                          '${_plan.process.mqttExpectedMessage}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _plan.motors.isEmpty && _plan.servos.isEmpty
                ? null
                : () => widget.onRunProcess(_plan.process.id),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Ejecutar proceso'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Movimientos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _addMovement,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Agregar movimiento'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Este proceso todavía no tiene movimientos.'),
                ),
              ),
            ),
          for (final order in groups.keys.toList()..sort())
            _StepCard(order: order, movements: groups[order]!),
        ],
      ),
    );
  }
}

class _StepMovement {
  const _StepMovement({
    required this.name,
    required this.kind,
    required this.value,
    required this.speed,
    required this.isServo,
    required this.command,
    required this.onEdit,
    this.onDelete,
  });

  final String name;
  final String kind;
  final String value;
  final String speed;
  final bool isServo;
  final String command;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.order, required this.movements});

  final int order;
  final List<_StepMovement> movements;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final command = ArduinoProcessCommandBuilder.line(
      movements.map((movement) => movement.command),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('$order')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paso $order',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  movements.length == 1
                      ? '1 movimiento'
                      : '${movements.length} movimientos simultáneos',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final movement in movements)
                  InputChip(
                    avatar: Icon(
                      movement.isServo ? Icons.rotate_right : Icons.settings,
                      size: 18,
                    ),
                    backgroundColor: movement.isServo
                        ? colors.tertiaryContainer
                        : colors.primaryContainer,
                    label: Text(
                      '${movement.kind} ${movement.name} · ${movement.value} · '
                      '${movement.speed}',
                    ),
                    tooltip: 'Editar movimiento',
                    onPressed: movement.onEdit,
                    onDeleted: movement.onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comando serial · una línea por paso',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    command,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMovementDialog extends StatefulWidget {
  const _AddMovementDialog({
    required this.motors,
    required this.servos,
    required this.existingMotors,
    required this.existingServos,
    required this.allowTypeChange,
    this.editingMotor,
    this.editingServo,
  });

  final List<Motor> motors;
  final List<Servo> servos;
  final List<ProcessMotors> existingMotors;
  final List<ProcessServo> existingServos;
  final bool allowTypeChange;
  final ProcessMotors? editingMotor;
  final ProcessServo? editingServo;

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _value = TextEditingController();
  final _speed = TextEditingController(text: '5000');
  String _kind = 'motor';
  Motor? _motor;
  Servo? _servo;
  String? _error;

  List<int> get _orders {
    final existing = {
      ...widget.existingMotors.map((item) => item.order),
      ...widget.existingServos.map((item) => item.order),
    };
    final last = existing.isEmpty
        ? 0
        : existing.reduce((a, b) => a > b ? a : b) + 1;
    return List.generate(last + 1, (index) => index);
  }

  int get _initialOrder {
    final existing = {
      ...widget.existingMotors.map((item) => item.order),
      ...widget.existingServos.map((item) => item.order),
    };
    return existing.isEmpty ? 0 : existing.reduce((a, b) => a > b ? a : b);
  }

  late int _selectedOrder = _initialOrder;

  @override
  void initState() {
    super.initState();
    final motor = widget.editingMotor;
    final servo = widget.editingServo;
    if (motor != null) {
      _kind = 'motor';
      _motor = widget.motors
          .where((item) => item.id == motor.motorId)
          .firstOrNull;
      _value.text = motor.steps.round().toString();
      _speed.text = motor.speed.round().toString();
      _selectedOrder = motor.order;
    } else if (servo != null) {
      _kind = 'servo';
      _servo = widget.servos
          .where((item) => item.id == servo.servoId)
          .firstOrNull;
      _value.text = servo.openValue.round().toString();
      _speed.text = servo.speed.round().toString();
      _selectedOrder = servo.order;
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _speed.dispose();
    super.dispose();
  }

  void _submit(int order) {
    final isMotor = _kind == 'motor';
    final value = int.tryParse(_value.text.trim());
    final speed = int.tryParse(_speed.text.trim());
    if ((isMotor && _motor == null) || (!isMotor && _servo == null)) {
      setState(() => _error = 'Selecciona un actuador.');
      return;
    }
    if (value == null || speed == null) {
      setState(() => _error = 'Ingresa valores enteros válidos.');
      return;
    }
    if (isMotor && (speed < 100 || speed > 10000)) {
      setState(
        () => _error = 'La velocidad del motor debe ser 100–10000 pasos/s.',
      );
      return;
    }
    if (!isMotor && (value < 0 || value > 180 || speed < 0 || speed > 720)) {
      setState(
        () => _error = 'El servo requiere ángulo 0–180° y velocidad 0–720°/s.',
      );
      return;
    }
    final key = isMotor ? _motor!.key : _servo!.key;
    final commandKey = ArduinoProcessCommandBuilder.commandKey(
      key,
    ).toUpperCase();
    if (_isDuplicate(order, commandKey)) {
      setState(() => _error = 'Ese actuador ya está en el paso seleccionado.');
      return;
    }
    Navigator.of(context).pop(
      _ActionDraft(
        kind: _kind,
        key: key,
        motor: _motor,
        servo: _servo,
        order: order,
        value: value.toDouble(),
        speed: speed.toDouble(),
        editingMotorId: widget.editingMotor?.id,
        editingServoId: widget.editingServo?.id,
        motorActionId: isMotor ? widget.editingMotor?.id : null,
        servoActionId: isMotor ? null : widget.editingServo?.id,
      ),
    );
  }

  bool _isDuplicate(int order, String commandKey) {
    final duplicateMotor = widget.existingMotors.any((item) {
      if (item.id == widget.editingMotor?.id) return false;
      if (item.order != order) return false;
      final motor = widget.motors
          .where((candidate) => candidate.id == item.motorId)
          .firstOrNull;
      return motor != null &&
          ArduinoProcessCommandBuilder.commandKey(motor.key).toUpperCase() ==
              commandKey;
    });
    final duplicateServo = widget.existingServos.any((item) {
      if (item.id == widget.editingServo?.id) return false;
      if (item.order != order) return false;
      final servo = widget.servos
          .where((candidate) => candidate.id == item.servoId)
          .firstOrNull;
      return servo != null &&
          ArduinoProcessCommandBuilder.commandKey(servo.key).toUpperCase() ==
              commandKey;
    });
    return duplicateMotor || duplicateServo;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.editingMotor != null || widget.editingServo != null
          ? 'Editar movimiento'
          : 'Agregar movimiento',
    ),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Tipo de actuador'),
              items: const [
                DropdownMenuItem(value: 'motor', child: Text('Motor')),
                DropdownMenuItem(value: 'servo', child: Text('Servo')),
              ],
              onChanged: widget.allowTypeChange
                  ? (value) => setState(() {
                      _kind = value ?? 'motor';
                      _motor = null;
                      _servo = null;
                      _speed.text = _kind == 'motor' ? '5000' : '60';
                      _error = null;
                    })
                  : null,
            ),
            const SizedBox(height: 12),
            if (_kind == 'motor')
              DropdownButtonFormField<Motor>(
                initialValue: _motor,
                decoration: const InputDecoration(labelText: 'Motor'),
                items: widget.motors
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.key} · ${item.speed.round()} pasos/s',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _motor = value;
                  if (value != null) {
                    _speed.text = value.speed.round().toString();
                  }
                }),
              )
            else
              DropdownButtonFormField<Servo>(
                initialValue: _servo,
                decoration: const InputDecoration(labelText: 'Servo'),
                items: widget.servos
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.key} · máximo ${item.maxOpen.round()}°',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _servo = value),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText: _kind == 'motor' ? 'Pasos (+ / -)' : 'Ángulo (°)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _speed,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _kind == 'motor'
                    ? 'Velocidad (pasos/s)'
                    : 'Velocidad (°/s)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedOrder,
              decoration: const InputDecoration(
                labelText: 'Paso de ejecución',
                helperText:
                    'El mismo paso ejecuta sus movimientos en paralelo.',
              ),
              items: _orders
                  .map(
                    (order) =>
                        DropdownMenuItem(value: order, child: Text('$order')),
                  )
                  .toList(),
              onChanged: (order) {
                if (order != null) setState(() => _selectedOrder = order);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => _submit(_selectedOrder),
        child: Text(
          widget.editingMotor != null || widget.editingServo != null
              ? 'Guardar'
              : 'Agregar',
        ),
      ),
    ],
  );
}
