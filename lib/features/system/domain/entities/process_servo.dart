class ProcessServo {
  final int id;
  final int processId;
  final int servoId;
  final String name;
  final int order;
  final double openValue;

  ProcessServo({
    required this.id,
    required this.processId,
    required this.servoId,
    required this.name,
    required this.order,
    required this.openValue,
  });
}
