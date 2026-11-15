import 'package:equatable/equatable.dart';

/// Una lectura completa (una línea del Arduino ya interpretada).
class SensorReading extends Equatable {
  const SensorReading({
    required this.seq,
    required this.timestamp,
    required this.values,
  });

  /// Contador creciente: sirve como eje X estable en las gráficas.
  final int seq;
  final DateTime timestamp;

  /// Canal → valor. Ej: `{'T': 25.4, 'H': 60.0}`.
  final Map<String, double> values;

  double? operator [](String channel) => values[channel];

  @override
  List<Object?> get props => [seq, timestamp, values];
}
