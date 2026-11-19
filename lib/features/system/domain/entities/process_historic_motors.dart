class ProcessHistoricMotors {
  final int id;
  final int processMotorId;
  final DateTime startTime;
  final DateTime? endTime;
  final double steps;
  final double speed;

  ProcessHistoricMotors({
    required this.id,
    required this.processMotorId,
    required this.startTime,
    this.endTime,
    required this.steps,
    required this.speed,
  });
}
