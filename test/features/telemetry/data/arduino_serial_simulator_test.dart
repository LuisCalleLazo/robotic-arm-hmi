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

  test('supports HMI servo and pause/play commands while simulating', () async {
    final simulator = ArduinoSerialSimulator();
    final lines = <String>[];
    simulator.lines.listen(lines.add);

    simulator.start();
    await Future<void>.delayed(Duration.zero);
    simulator.sendCommand('BCS90:60');
    simulator.sendCommand('BC?');
    simulator.sendCommand('BCPAUSE');
    simulator.sendCommand('BCPLAY');
    await Future<void>.delayed(Duration.zero);

    expect(lines, contains('EVT,SERVO,90'));
    expect(lines, contains('CMD,BC?'));
    expect(lines, contains('CMD,BCPAUSE'));
    expect(lines, contains('EVT,PAUSE'));
    expect(lines, contains('STATE,PAUSED'));
    expect(lines, contains('EVT,PLAY'));

    simulator.stop();
  });

  testWidgets('simulates ordered process groups with simultaneous axes', (
    tester,
  ) async {
    final simulator = ArduinoSerialSimulator();
    final lines = <String>[];
    simulator.lines.listen(lines.add);

    simulator.start();
    await tester.pump(const Duration(seconds: 9));
    expect(simulator.isReady, isTrue);
    expect(lines, contains('BC,INFO,LISTO'));
    simulator.sendCommand('BCX100:2000 BCY-100:800');
    await tester.pump(const Duration(seconds: 2));

    expect(lines, contains('BC,EVT,INICIO,BCX,100'));
    expect(lines, contains('BC,EVT,INICIO,BCY,-100'));
    expect(lines.any((line) => line.startsWith('BC,EVT,FIN,BCX,')), isTrue);
    expect(lines.any((line) => line.startsWith('BC,EVT,FIN,BCY,')), isTrue);

    simulator.stop();
  });
}
