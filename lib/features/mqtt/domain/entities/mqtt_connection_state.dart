enum MqttConnectionStatus { disconnected, connecting, connected, error }

class BrokerConnectionState {
  const BrokerConnectionState({
    this.status = MqttConnectionStatus.disconnected,
    this.host,
    this.port,
    this.error,
  });

  final MqttConnectionStatus status;
  final String? host;
  final int? port;
  final String? error;

  bool get isConnected => status == MqttConnectionStatus.connected;
}
