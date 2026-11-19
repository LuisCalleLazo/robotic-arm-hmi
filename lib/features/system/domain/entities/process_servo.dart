class ProcessServo {
  final int id;
  final int processId;
  final int servoId;
  final String name;
  final int order;
  final double openValue;
  final double speed;

  ProcessServo({
    required this.id,
    required this.processId,
    required this.servoId,
    required this.name,
    required this.order,
    required this.openValue,
    this.speed = 60,
  });
}
