import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../mqtt/data/mqtt_connection_service.dart';
import '../../../mqtt/domain/entities/mqtt_incoming_message.dart';
import '../../../mqtt/domain/entities/mqtt_connection_state.dart';
import '../../../mqtt/presentation/pages/mqtt_landing_page.dart';
import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../serial_connection/presentation/pages/connection_page.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../widgets/communication_snackbar.dart';
import '../widgets/scara_arm_hmi_panel.dart';
import '../widgets/serial_console_panel.dart';
import '../widgets/system_overview_panel.dart';

enum _SystemView { complete, arm }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  _SystemView _systemView = _SystemView.arm;
  late final StreamSubscription<MqttIncomingMessage> _mqttMessages;
  late final StreamSubscription<TelemetryLogEntry> _serialMessages;
  Timer? _snackbarTimer;
  ({String title, String message, IconData icon})? _pendingMessage;
  ({String title, String message, IconData icon})? _lastMessage;
  String? _lastSerialMessage;

  @override
  void initState() {
    super.initState();
    _mqttMessages = GetIt.I<MqttConnectionService>().messages.listen(
      _showMqttMessage,
    );
    _serialMessages = GetIt.I<TelemetryCubit>().lineEvents.listen(
      _showSerialMessage,
    );
  }

  @override
  void dispose() {
    _mqttMessages.cancel();
    _serialMessages.cancel();
    _snackbarTimer?.cancel();
    super.dispose();
  }

  void _showMqttMessage(MqttIncomingMessage message) {
    _queueMessage(
      title: 'MQTT · ${message.topic}',
      message: message.payload,
      icon: Icons.cloud_download_outlined,
    );
  }

  void _showSerialMessage(TelemetryLogEntry entry) {
    final key = '${entry.source.name}:${entry.line}';
    if (key == _lastSerialMessage) return;
    _lastSerialMessage = key;
    final sent = entry.source == TelemetrySource.serialSent;
    final simulated = entry.source == TelemetrySource.simulated;
    _queueMessage(
      title: sent
          ? 'SERIAL · ENVIADO'
          : simulated
          ? 'SIMULACIÓN · RECIBIDO'
          : 'SERIAL · RECIBIDO',
      message: entry.line,
      icon: sent ? Icons.north_east : Icons.south_west,
    );
  }

  void _queueMessage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    _pendingMessage = (title: title, message: message, icon: icon);
    if (_snackbarTimer != null) return;
    _snackbarTimer = Timer(const Duration(milliseconds: 300), () {
      _snackbarTimer = null;
      final pending = _pendingMessage;
      _pendingMessage = null;
      if (!mounted || pending == null) return;
      _lastMessage = pending;
      _displayMessage(pending);
    });
  }

  void _displayMessage(({String title, String message, IconData icon}) value) {
    showCommunicationSnackBar(
      context,
      title: value.title,
      message: value.message,
      icon: value.icon,
    );
  }

  void _openSerialConsole({required bool canSend}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 560,
          height: 420,
          child: SerialConsolePanel(
            onClose: () => Navigator.of(dialogContext).pop(),
            onSend: _sendCommand,
            canSend: canSend,
          ),
        ),
      ),
    );
  }

  Future<void> _sendCommand(String command, {String? simulatedCommand}) async {
    final trimmedCommand = command.trim();
    if (trimmedCommand.isEmpty) return;
    final telemetry = context.read<TelemetryCubit>();
    if (telemetry.state.isSimulating) {
      if (_isSensorSignal(trimmedCommand)) {
        telemetry.ingestSimulatedLine(trimmedCommand);
        return;
      }
      telemetry.recordSent(trimmedCommand);
      telemetry.sendSimulatedCommand(simulatedCommand ?? trimmedCommand);
      return;
    }
    if (!context.read<ConnectionBloc>().state.isConnected) {
      throw StateError('El puerto serial está desconectado.');
    }
    context.read<ConnectionBloc>().add(CommandSent(trimmedCommand));
  }

  bool _isSensorSignal(String line) =>
      RegExp(r'^[A-Z][A-Z0-9_-]*[01]$', caseSensitive: false).hasMatch(line);

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionBloc>().state;
    final telemetry = context.watch<TelemetryCubit>().state;
    final simulation = telemetry.isSimulating;
    final mqtt = GetIt.I<MqttConnectionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema'),
        actions: [
          StreamBuilder<BrokerConnectionState>(
            stream: mqtt.states,
            initialData: mqtt.state,
            builder: (context, connectionSnapshot) {
              final label = connectionSnapshot.data?.isConnected == true
                  ? 'MQTT · ${connectionSnapshot.data?.host}'
                  : 'MQTT desconectado';
              final color = simulation
                  ? Colors.lightBlue
                  : connectionSnapshot.data?.isConnected == true
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurfaceVariant;
              return Chip(
                avatar: Icon(Icons.circle, size: 12, color: color),
                label: Text(label),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Conexión MQTT',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => showMqttConnectionDialog(context, mqtt),
          ),
          IconButton(
            tooltip: 'Mostrar último mensaje',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: _lastMessage == null
                ? null
                : () => _displayMessage(_lastMessage!),
          ),
          IconButton(
            tooltip: 'Configurar conexión serial',
            icon: const Icon(Icons.usb),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const Dialog(
                child: SizedBox(width: 520, child: ConnectionPage()),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Consola serial',
            icon: const Icon(Icons.terminal),
            onPressed: () => _openSerialConsole(
              canSend: simulation || connection.isConnected,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Builder(
            builder: (context) {
              final canSend = simulation || connection.isConnected;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SegmentedButton<_SystemView>(
                      segments: const [
                        ButtonSegment(
                          value: _SystemView.arm,
                          icon: Icon(Icons.precision_manufacturing_outlined),
                          label: Text('Brazo'),
                        ),
                        ButtonSegment(
                          value: _SystemView.complete,
                          icon: Icon(Icons.account_tree_outlined),
                          label: Text('Sistema completo'),
                        ),
                      ],
                      selected: {_systemView},
                      onSelectionChanged: (selection) =>
                          setState(() => _systemView = selection.first),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _systemView == _SystemView.arm ? 0 : 1,
                      children: [
                        ScaraArmHmiPanel(
                          canSendCommands: canSend,
                          simulating: simulation,
                          serialConnected: connection.isConnected,
                          connectionLabel: connection.isConnected
                              ? '${connection.selectedPort} · ${connection.baudRate} baud'
                              : 'Desconectado',
                          telemetry: context.read<TelemetryCubit>(),
                          onCommand: _sendCommand,
                        ),
                        SystemOverviewPanel(
                          key: ValueKey(_systemView),
                          canSendCommands: canSend,
                          serialConnected: connection.isConnected,
                          simulating: simulation,
                          telemetry: context.read<TelemetryCubit>(),
                          onCommand: (command) => _sendCommand(command),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
