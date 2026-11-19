import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/system/domain/services/arduino_process_command_builder.dart';

void main() {
  test('builds a concurrent BC command line with per-action speeds', () {
    final line = ArduinoProcessCommandBuilder.line([
      ArduinoProcessCommandBuilder.movement(key: 'X', value: 500, speed: 2000),
      ArduinoProcessCommandBuilder.movement(
        key: 'BCY',
        value: -300,
        speed: 800,
      ),
      ArduinoProcessCommandBuilder.movement(key: 'S', value: 90, speed: 60),
    ]);

    expect(line, 'BCX500:2000 BCY-300:800 BCS90:60');
  });
}
