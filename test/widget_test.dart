import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_arm_hmi/features/mqtt/data/mqtt_connection_service.dart';
import 'package:robotic_arm_hmi/features/mqtt/presentation/pages/mqtt_landing_page.dart';

void main() {
  testWidgets('landing page lets the user enter MQTT broker details', (
    tester,
  ) async {
    final service = MqttConnectionService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(home: MqttLandingPage(service: service)),
    );

    expect(find.text('Conexión MQTT'), findsOneWidget);
    await tester.tap(find.text('Conectar a MQTT'));
    await tester.pumpAndSettle();

    expect(find.text('IP o host del broker'), findsOneWidget);
    expect(find.text('Puerto MQTT'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Conectar a MQTT'));
    await tester.pumpAndSettle();
    expect(find.text('IP o host del broker'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
}
