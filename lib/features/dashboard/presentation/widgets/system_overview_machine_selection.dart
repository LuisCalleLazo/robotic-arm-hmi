import '../../../system/domain/entities/system_machine.dart';

List<SystemMachine> availableSystemOverviewMachines({
  required List<SystemMachine> machines,
  required Set<int> assignedMachineIds,
  int? selectedMachineId,
}) =>
    machines
        .where(
          (machine) =>
              machine.id == selectedMachineId ||
              !assignedMachineIds.contains(machine.id),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
