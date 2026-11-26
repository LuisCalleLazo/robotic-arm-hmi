import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String host, int port, String clientId) =>
    MqttServerClient(host, clientId)..port = port;
