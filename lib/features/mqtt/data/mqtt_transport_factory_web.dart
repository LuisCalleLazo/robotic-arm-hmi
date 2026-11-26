import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(String host, int port, String clientId) =>
    MqttBrowserClient.withPort(
      '${Uri.base.scheme == 'https' ? 'wss' : 'ws'}://$host',
      clientId,
      port,
    );
