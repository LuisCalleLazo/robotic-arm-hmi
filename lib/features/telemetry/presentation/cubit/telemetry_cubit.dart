import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/ring_buffer.dart';
import '../../../serial_connection/domain/repositories/serial_repository.dart';
import '../../data/parsers/telemetry_parser.dart';
import '../../data/simulators/arduino_serial_simulator.dart';
import '../../domain/entities/sensor_reading.dart';

enum TelemetrySource { serial, peerSerial, serialSent, simulated }

class TelemetryLogEntry extends Equatable {
  const TelemetryLogEntry({required this.line, required this.source});

  final String line;
  final TelemetrySource source;

  @override
  List<Object?> get props => [line, source];
}

class TelemetryState extends Equatable {
  const TelemetryState({
    this.history = const [],
    this.latest,
    this.channels = const [],
    this.consoleEntries = const [],
    this.isSimulating = false,
    this.machineState,
    this.gripperClosed = false,
    this.routeStep,
    this.packetsPerSecond = 0,
    this.totalPackets = 0,
    this.invalidLines = 0,
    this.version = 0,
  });

  /// Ventana deslizante de lecturas (más viejas primero).
  final List<SensorReading> history;
  final SensorReading? latest;

  /// Canales vistos hasta ahora, en orden de aparición.
  final List<String> channels;

  /// Últimas líneas recibidas por serial o generadas por el simulador.
  final List<TelemetryLogEntry> consoleEntries;
  final bool isSimulating;
  final String? machineState;
  final bool gripperClosed;
  final int? routeStep;

  List<String> get rawLines =>
      consoleEntries.map((entry) => entry.line).toList();

  final double packetsPerSecond;
  final int totalPackets;
  final int invalidLines;

  /// Identificador del "snapshot": evita comparar listas grandes en cada emit.
  final int version;

  @override
  List<Object?> get props => [version];
}

/// Escucha las líneas del serial, las interpreta y publica snapshots a ~30 fps
/// (no uno por línea) para que la UI no se sature a altas tasas de datos.
class TelemetryCubit extends Cubit<TelemetryState> {
  TelemetryCubit({
    required SerialRepository repository,
    required this._parser,
    ArduinoSerialSimulator? simulator,
    int historySize = 500,
    int consoleSize = 200,
    Duration refreshInterval = const Duration(milliseconds: 33),
  }) : _simulator = simulator ?? ArduinoSerialSimulator(),
       _history = RingBuffer<SensorReading>(historySize),
       _console = RingBuffer<TelemetryLogEntry>(consoleSize),
       super(const TelemetryState()) {
    _lineSub = repository.lines.listen(_onLine);
    _simulationSub = _simulator.lines.listen(
      (line) => _onLine(line, TelemetrySource.simulated),
    );
    _timer = Timer.periodic(refreshInterval, (_) => _flush());
    _rateWatch.start();
  }

  final TelemetryParser _parser;
  final ArduinoSerialSimulator _simulator;
  final RingBuffer<SensorReading> _history;
  final RingBuffer<TelemetryLogEntry> _console;
  final _lineEvents = StreamController<TelemetryLogEntry>.broadcast();
  final List<String> _channels = [];
  final Stopwatch _rateWatch = Stopwatch();

  late final StreamSubscription<String> _lineSub;
  late final StreamSubscription<String> _simulationSub;
  late final Timer _timer;

  Stream<TelemetryLogEntry> get lineEvents => _lineEvents.stream;

  int _seq = 0;
  int _version = 0;
  int _total = 0;
  int _invalid = 0;
  int _rateCount = 0;
  double _packetsPerSecond = 0;
  bool _dirty = false;
  String? _machineState;
  bool _gripperClosed = false;
  int? _routeStep;

  void _onLine(String line, [TelemetrySource source = TelemetrySource.serial]) {
    final text = line.trim();
    if (text.isEmpty) return;

    _console.add(TelemetryLogEntry(line: text, source: source));
    _lineEvents.add(TelemetryLogEntry(line: text, source: source));
    if (text.startsWith('STATE,')) {
      _machineState = text.substring('STATE,'.length);
    } else if (text.startsWith('EVT,SERVO,')) {
      final angle = int.tryParse(text.substring('EVT,SERVO,'.length));
      if (angle != null) _gripperClosed = angle > 90;
    } else if (text.startsWith('EVT,ROUTE_STEP,')) {
      _routeStep = int.tryParse(text.substring('EVT,ROUTE_STEP,'.length));
    } else if (text == 'EVT,ROUTE_DONE') {
      _routeStep = null;
    }

    final values = _parser.parse(text);
    if (values == null) {
      _invalid++;
    } else {
      for (final key in values.keys) {
        if (!_channels.contains(key)) _channels.add(key);
      }
      _history.add(
        SensorReading(seq: _seq++, timestamp: DateTime.now(), values: values),
      );
      _total++;
      _rateCount++;
    }
    _dirty = true;
  }

  void startSimulation() {
    _machineState = null;
    _gripperClosed = false;
    _routeStep = null;
    _simulator.start();
    _dirty = true;
    _flush();
  }

  void stopSimulation() {
    _simulator.stop();
    _dirty = true;
    _flush();
  }

  void sendSimulatedCommand(String command) {
    _simulator.sendCommand(command);
  }

  void recordSent(String line) {
    _recordConsoleLine(line, TelemetrySource.serialSent);
  }

  void ingestPeerSentLine(String line) {
    _recordConsoleLine(line, TelemetrySource.serialSent);
  }

  void _recordConsoleLine(String line, TelemetrySource source) {
    final text = line.trim();
    if (text.isEmpty) return;
    _console.add(TelemetryLogEntry(line: text, source: source));
    _dirty = true;
    _flush();
  }

  void ingestPeerLine(String line) {
    _onLine(line, TelemetrySource.peerSerial);
  }

  void runSimulatedRoute() {
    _simulator.sendCommand('R');
  }

  void _flush() {
    if (_rateWatch.elapsedMilliseconds >= 1000) {
      _packetsPerSecond = _rateCount * 1000 / _rateWatch.elapsedMilliseconds;
      _rateCount = 0;
      _rateWatch.reset();
      _dirty = true;
    }

    if (!_dirty) return;
    _dirty = false;

    emit(
      TelemetryState(
        history: _history.toList(),
        latest: _history.last,
        channels: List<String>.unmodifiable(_channels),
        consoleEntries: _console.toList(),
        isSimulating: _simulator.isRunning,
        machineState: _machineState,
        gripperClosed: _gripperClosed,
        routeStep: _routeStep,
        packetsPerSecond: _packetsPerSecond,
        totalPackets: _total,
        invalidLines: _invalid,
        version: ++_version,
      ),
    );
  }

  /// Borra historial, consola y contadores.
  void clear() {
    _history.clear();
    _console.clear();
    _channels.clear();
    _machineState = null;
    _gripperClosed = false;
    _routeStep = null;
    _total = 0;
    _invalid = 0;
    _rateCount = 0;
    _packetsPerSecond = 0;
    _dirty = true;
    _flush();
  }

  @override
  Future<void> close() async {
    _timer.cancel();
    await _lineSub.cancel();
    await _simulationSub.cancel();
    await _simulator.dispose();
    await _lineEvents.close();
    return super.close();
  }
}
