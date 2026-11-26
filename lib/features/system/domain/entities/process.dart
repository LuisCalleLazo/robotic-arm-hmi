class Process {
  final int id;
  final String name;
  final int order;
  final int? machineId;
  final String? mqttTopic;
  final String? mqttExpectedMessage;

  Process({
    required this.id,
    required this.name,
    required this.order,
    this.machineId,
    this.mqttTopic,
    this.mqttExpectedMessage,
  });
}
