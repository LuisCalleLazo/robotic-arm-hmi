class ProcessHistoric {
  final int id;
  final int processId;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? stopProcess;
  final String? stopKey;
  final bool finishProcess;

  ProcessHistoric({
    required this.id,
    required this.processId,
    required this.startTime,
    this.endTime,
    this.stopProcess,
    this.stopKey,
    required this.finishProcess,
  });
}
