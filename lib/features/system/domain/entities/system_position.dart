class SystemPosition {
  final int id;
  final int number;
  final String type; // BRAZO SCARA, CINTA PEQUEÑA, CINTA GRANDE
  final int systemMachineId;

  SystemPosition({
    required this.number,
    required this.systemMachineId,
    required this.type,
    required this.id,
  });
}
