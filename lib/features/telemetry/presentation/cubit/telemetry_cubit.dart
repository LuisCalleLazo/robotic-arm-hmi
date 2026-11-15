import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/ring_buffer.dart';
import '../../../serial_connection/domain/repositories/serial_repository.dart';
import '../../data/parsers/telemetry_parser.dart';
import '../../domain/entities/sensor_reading.dart';

class TelemetryState extends Equatable {
  const TelemetryState({
    this.history = const [],
    this.latest,
    this.channels = const [],
    this.rawLines = const [],
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

  /// Últimas líneas crudas recibidas (para la consola).
  final List<String> rawLines;

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
    required TelemetryParser parser,
    int historySize = 500,
    int consoleSize = 200,
    Duration refreshInterval = const Duration(milliseconds: 33),
  }) : _parser = parser,
       _history = RingBuffer<SensorReading>(historySize),
       _console = RingBuffer<String>(consoleSize),
       super(const TelemetryState()) {
    _lineSub = repository.lines.listen(_onLine);
    _timer = Timer.periodic(refreshInterval, (_) => _flush());
    _rateWatch.start();
  }

  final TelemetryParser _parser;
  final RingBuffer<SensorReading> _history;
  final RingBuffer<String> _console;
  final List<String> _channels = [];
  final Stopwatch _rateWatch = Stopwatch();

  late final StreamSubscription<String> _lineSub;
  late final Timer _timer;

  int _seq = 0;
  int _version = 0;
  int _total = 0;
  int _invalid = 0;
  int _rateCount = 0;
  double _packetsPerSecond = 0;
  bool _dirty = false;

  void _onLine(String line) {
    final text = line.trim();
    if (text.isEmpty) return;

    _console.add(text);

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
        rawLines: _console.toList(),
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
    return super.close();
  }
}
