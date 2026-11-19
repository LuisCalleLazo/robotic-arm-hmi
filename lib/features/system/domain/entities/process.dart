class Process {
  final int id;
  final String name;
  final int order;
  final int? activationSensorId; // from sensor.dart

  Process({
    required this.id,
    required this.name,
    required this.order,
    this.activationSensorId,
  });
}
