import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/dashboard/presentation/widgets/system_overview_machine_types.dart';

void main() {
  group('SystemOverviewMachineTypes', () {
    test('matches arm names regardless of case', () {
      expect(SystemOverviewMachineTypes.isArm('Brazo'), isTrue);
      expect(SystemOverviewMachineTypes.isArm('BRAZO SCARA'), isTrue);
      expect(SystemOverviewMachineTypes.isArm('Cinta grande'), isFalse);
    });

    test('matches belt names regardless of case and accents', () {
      expect(SystemOverviewMachineTypes.isSmallBelt('Cinta pequeña'), isTrue);
      expect(SystemOverviewMachineTypes.isSmallBelt('CINTA PEQUEÑA'), isTrue);
      expect(SystemOverviewMachineTypes.isSmallBelt('Cinta grande'), isFalse);
    });
  });
}
