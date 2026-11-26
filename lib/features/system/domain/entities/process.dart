class Process {
  final int id;
  final String name;
  final int order;
  final int? machineId;
  final String? mqttTopic;
  final String? mqttExpectedMessage;
  final String? mqttCompletionTopic;
  final String? mqttCompletionMessage;

  Process({
    required this.id,
    required this.name,
    required this.order,
    this.machineId,
    this.mqttTopic,
    this.mqttExpectedMessage,
    this.mqttCompletionTopic,
    this.mqttCompletionMessage,
  });
}
