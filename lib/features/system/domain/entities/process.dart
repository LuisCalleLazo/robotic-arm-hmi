class Process {
  final int id;
  final String name;
  final int order;
  final int? activationSensorId; // from sensor.dart
  final int? machineId;

  Process({
    required this.id,
    required this.name,
    required this.order,
    this.activationSensorId,
    this.machineId,
  });
}
