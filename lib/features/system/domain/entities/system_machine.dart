class SystemMachine {
  final int id;
  final String name;
  final String type; // BRAZO SCARA, CINTA PEQUEÑA, CINTA GRANDE
  final int? parentMachineId;

  SystemMachine({
    required this.name,
    required this.type,
    required this.id,
    this.parentMachineId,
  });
}
