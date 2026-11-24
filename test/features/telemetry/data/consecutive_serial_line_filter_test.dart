import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/telemetry/data/consecutive_serial_line_filter.dart';

void main() {
  test('accepts a serial line only when it differs from the previous line', () {
    final filter = ConsecutiveSerialLineFilter();

    expect(filter.accept('CPS1'), isTrue);
    expect(filter.accept(' CPS1 '), isFalse);
    expect(filter.accept('CPS0'), isTrue);
    expect(filter.accept('CPS1'), isTrue);
    expect(filter.accept(''), isFalse);

    filter.reset();
    expect(filter.accept('CPS1'), isTrue);
  });

  test('forwards only one of 200 identical sensor reports', () {
    final filter = ConsecutiveSerialLineFilter();
    var forwarded = 0;

    for (var index = 0; index < 200; index++) {
      if (filter.accept('CPS1')) forwarded++;
    }

    expect(forwarded, 1);
  });

  test('allows repeated sensor activation reports through the peer bridge', () {
    final filter = ConsecutiveSerialLineFilter();

    expect(filter.accept('CGC1'), isTrue);
    expect(filter.accept('CGC1', allowRepeated: true), isTrue);
    expect(filter.accept('CGC1', allowRepeated: true), isTrue);
    expect(filter.accept('CGC1'), isFalse);
    expect(filter.accept('CGC0', allowRepeated: true), isTrue);
  });
}
