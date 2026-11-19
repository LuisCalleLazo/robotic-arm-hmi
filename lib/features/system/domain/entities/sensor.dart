class Sensor {
  final int id;
  final int? machineId;
  final String key;
  final String name;

  Sensor({
    required this.id,
    this.machineId,
    required this.key,
    required this.name,
  });
}
