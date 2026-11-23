import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/dashboard/presentation/widgets/system_overview_machine_selection.dart';
import 'package:robotic_arm_hmi/features/system/domain/entities/system_machine.dart';

void main() {
  test('hides machines assigned elsewhere but keeps this slot selection', () {
    final machines = [
      SystemMachine(id: 1, name: 'Cinta', type: 'CINTA'),
      SystemMachine(id: 2, name: 'Brazo', type: 'BRAZO'),
      SystemMachine(id: 3, name: 'Libre', type: 'OTRA'),
    ];

    final available = availableSystemOverviewMachines(
      machines: machines,
      assignedMachineIds: {1, 2},
      selectedMachineId: 2,
    );

    expect(available.map((machine) => machine.id), [2, 3]);
  });
}
