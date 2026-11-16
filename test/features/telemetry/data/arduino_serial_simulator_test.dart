import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/telemetry/data/simulators/arduino_serial_simulator.dart';
import 'package:robotic_arm_hmi/features/telemetry/data/parsers/telemetry_parser.dart';

void main() {
  test('emits Arduino protocol logs and simulated positions', () async {
    final simulator = ArduinoSerialSimulator();
    final lines = <String>[];
    simulator.lines.listen(lines.add);

    simulator.start();
    await Future<void>.delayed(Duration.zero);
    expect(lines, contains('EVT,BOOT'));
    expect(lines, contains('EVT,HOMING_START,Z,0'));

    simulator.sendCommand('POS');
    await Future<void>.delayed(Duration.zero);
    expect(lines, contains('CMD,POS'));
    expect(lines, contains('STATE,HOMING'));
    expect(lines.any((line) => line.startsWith('POS,X=')), isTrue);
    expect(const TelemetryParser().parse('POS,X=8000,Y=5500,A=1200,Z=0'), {
      'X': 8000,
      'Y': 5500,
      'A': 1200,
      'Z': 0,
    });

    simulator.stop();
  });

  test(
    'STOP clears references and keeps single-axis homing available',
    () async {
      final simulator = ArduinoSerialSimulator();
      final lines = <String>[];
      simulator.lines.listen(lines.add);

      simulator.start();
      await Future<void>.delayed(Duration.zero);
      simulator.sendCommand('P');
      await Future<void>.delayed(Duration.zero);
      simulator.sendCommand('X500');
      await Future<void>.delayed(Duration.zero);
      simulator.sendCommand('X');
      await Future<void>.delayed(Duration.zero);

      expect(lines, contains('EVT,STOPPED'));
      expect(lines, contains('ERR,NOT_REFERENCED,X'));
      expect(lines, contains('EVT,HOMING_START,X,0'));

      simulator.stop();
    },
  );
}
