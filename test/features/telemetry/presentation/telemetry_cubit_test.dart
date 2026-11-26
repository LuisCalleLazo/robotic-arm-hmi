import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/serial_connection/domain/repositories/serial_repository.dart';
import 'package:robotic_arm_hmi/features/telemetry/data/parsers/telemetry_parser.dart';
import 'package:robotic_arm_hmi/features/telemetry/presentation/cubit/telemetry_cubit.dart';

class _FakeSerialRepository extends Fake implements SerialRepository {
  @override
  Stream<String> get lines => const Stream.empty();
}

void main() {
  test('publishes manually sent lines to event listeners', () async {
    final cubit = TelemetryCubit(
      repository: _FakeSerialRepository(),
      parser: TelemetryParser(),
    );
    final lineEvent = cubit.lineEvents.first;

    cubit.recordSent('CGC1');

    expect(
      await lineEvent,
      const TelemetryLogEntry(line: 'CGC1', source: TelemetrySource.serialSent),
    );
    await cubit.close();
  });

  test('keeps only changed consecutive lines in the visible console', () async {
    final cubit = TelemetryCubit(
      repository: _FakeSerialRepository(),
      parser: TelemetryParser(),
    );

    for (var index = 0; index < 200; index++) {
      cubit.ingestSimulatedLine('CPS1');
    }
    cubit.ingestSimulatedLine('CPS0');
    cubit.ingestSimulatedLine('CPS1');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.consoleEntries.map((entry) => entry.line).toList(), [
      'CPS1',
      'CPS0',
      'CPS1',
    ]);
    await cubit.close();
  });
}
