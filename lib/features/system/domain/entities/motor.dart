class Motor {
  final int id;
  final int systemMachineId;
  final String key;
  final String? keySensorRight;
  final String? keySensorLeft;
  final double speed;
  final String? maxStepsRight;
  final String? maxStepsLeft;

  Motor({
    required this.id,
    required this.systemMachineId,
    required this.key,
    required this.keySensorRight,
    required this.keySensorLeft,
    required this.speed,
    required this.maxStepsRight,
    required this.maxStepsLeft,
  });
}
