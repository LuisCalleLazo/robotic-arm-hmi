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
}
