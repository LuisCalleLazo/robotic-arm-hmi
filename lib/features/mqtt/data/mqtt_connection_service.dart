import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart' as mqtt;

import '../domain/entities/mqtt_connection_state.dart';
import '../domain/entities/mqtt_incoming_message.dart';
import 'mqtt_transport_factory.dart' as mqtt_transport;

class MqttConnectionService {
  final _states = StreamController<BrokerConnectionState>.broadcast();
  final _messages = StreamController<MqttIncomingMessage>.broadcast();
  BrokerConnectionState _state = const BrokerConnectionState();
  mqtt.MqttClient? _client;
  StreamSubscription<List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>>>?
  _messageSubscription;
  int _generation = 0;
  bool _disconnecting = false;

  BrokerConnectionState get state => _state;
  Stream<BrokerConnectionState> get states => _states.stream;
  Stream<MqttIncomingMessage> get messages => _messages.stream;

  Future<void> connect({
    required String host,
    required int port,
    String? username,
    String? password,
  }) async {
    final normalizedHost = host.trim();
    if (normalizedHost.isEmpty) {
      throw ArgumentError('Escribe la IP o el nombre del broker MQTT.');
    }
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(
        port,
        'port',
        'El puerto debe estar entre 1 y 65535.',
      );
    }

    final generation = ++_generation;
    await _disconnectClient();
    _emit(
      BrokerConnectionState(
        status: MqttConnectionStatus.connecting,
        host: normalizedHost,
        port: port,
      ),
    );

    final clientId = 'robotic-arm-hmi-${DateTime.now().microsecondsSinceEpoch}';
    final client = mqtt_transport.createMqttClient(
      normalizedHost,
      port,
      clientId,
    );
    client
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 8000
      ..logging(on: false)
      ..onDisconnected = () {
        if (!_disconnecting && generation == _generation) {
          _client = null;
          _emit(
            BrokerConnectionState(
              status: MqttConnectionStatus.disconnected,
              host: normalizedHost,
              port: port,
            ),
          );
        }
      }
      ..connectionMessage = mqtt.MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(mqtt.MqttQos.atMostOnce);
    _client = client;

    try {
      final status = await client.connect(
        username?.trim().isEmpty == true ? null : username?.trim(),
        password?.isEmpty == true ? null : password,
      );
      if (generation != _generation) {
        client.disconnect();
        return;
      }
      if (status?.state != mqtt.MqttConnectionState.connected) {
        throw StateError(
          'El broker rechazó la conexión (${status?.state ?? 'sin respuesta'}).',
        );
      }
      _emit(
        BrokerConnectionState(
          status: MqttConnectionStatus.connected,
          host: normalizedHost,
          port: port,
        ),
      );
      _messageSubscription = client.updates?.listen((batch) {
        for (final received in batch) {
          final message = received.payload;
          if (message is! mqtt.MqttPublishMessage) continue;
          _messages.add(
            MqttIncomingMessage(
              topic: received.topic,
              payload: utf8.decode(
                message.payload.message,
                allowMalformed: true,
              ),
            ),
          );
        }
      });
      client.subscribe('#', mqtt.MqttQos.atMostOnce);
    } catch (error) {
      if (generation == _generation) {
        _client = null;
        client.disconnect();
        _emit(
          BrokerConnectionState(
            status: MqttConnectionStatus.error,
            host: normalizedHost,
            port: port,
            error: '$error',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    ++_generation;
    await _disconnectClient();
    _emit(const BrokerConnectionState());
  }

  Future<void> _disconnectClient() async {
    final client = _client;
    _client = null;
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    if (client == null) return;
    _disconnecting = true;
    try {
      client.disconnect();
    } finally {
      _disconnecting = false;
    }
  }

  void _emit(BrokerConnectionState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  Future<void> dispose() async {
    await disconnect();
    await _states.close();
    await _messages.close();
  }
}
