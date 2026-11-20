import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../peer_to_peer/domain/entities/peer_entities.dart';
import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import '../../../peer_to_peer/presentation/cubit/peer_cubit.dart';
import '../../../peer_to_peer/presentation/widgets/peer_status_badge.dart';
import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../serial_connection/presentation/pages/connection_page.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../widgets/serial_console_panel.dart';

/// Sistema general. La animación global se incorporará en una iteración futura.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _commandController = TextEditingController();
  bool _showLogs = false;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _sendCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    final peer = GetIt.I<PeerRepository>();
    if (peer.session.isSlave) {
      if (!peer.session.isActive) {
        _showMessage('Conéctate al servidor maestro para enviar comandos.');
        return;
      }
      if (!peer.session.permission.canSendCommands) {
        _showMessage('El maestro no te ha dado permiso para enviar comandos.');
        return;
      }
      try {
        await peer.send(
          PeerMessage(
            type: PeerMessageType.command,
            payload: {'kind': 'serial_command', 'line': command},
          ),
        );
        if (!mounted) return;
        context.read<TelemetryCubit>().recordSent(command);
        _commandController.clear();
      } catch (error) {
        _showMessage('No se pudo enviar el comando: $error');
      }
      return;
    }
    if (!context.read<ConnectionBloc>().state.isConnected) return;
    context.read<ConnectionBloc>().add(CommandSent(command));
    _commandController.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionBloc>().state;
    final telemetry = context.watch<TelemetryCubit>().state;
    final simulation = telemetry.isSimulating;
    final color = simulation
        ? Colors.lightBlue
        : connection.isConnected
        ? Colors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final label = simulation
        ? 'Simulado'
        : connection.isConnected
        ? '${connection.selectedPort} · ${connection.baudRate} baud'
        : 'Serial desconectado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema general'),
        actions: [
          Chip(
            avatar: Icon(Icons.circle, size: 12, color: color),
            label: Text(label),
          ),
          const SizedBox(width: 8),
          const PeerStatusBadge(),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                BlocBuilder<PeerCubit, PeerState>(
                  bloc: GetIt.I<PeerCubit>(),
                  builder: (context, peerState) {
                    final session = peerState.session;
                    final canSend = session.isSlave
                        ? session.isActive && session.permission.canSendCommands
                        : connection.isConnected;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commandController,
                                enabled: canSend,
                                onSubmitted: (_) => _sendCommand(),
                                decoration: InputDecoration(
                                  labelText: session.isSlave
                                      ? 'Comando serial al maestro'
                                      : 'Comando serial',
                                  hintText: 'Ej. BC?',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.terminal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: canSend ? _sendCommand : null,
                              icon: const Icon(Icons.send),
                              label: const Text('Enviar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ListTile(
                          leading: Icon(Icons.mark_email_unread_outlined),
                          title: Text('Respuestas recibidas'),
                          subtitle: Text('Lectura en vivo desde el serial'),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _incomingLines(telemetry.consoleEntries),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showLogs = !_showLogs),
        icon: Icon(_showLogs ? Icons.close : Icons.terminal),
        label: Text(_showLogs ? 'Cerrar logs' : 'Logs seriales'),
      ),
      bottomSheet: _showLogs
          ? LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: math.min(420, MediaQuery.sizeOf(context).height * .6),
                width: math.min(560, constraints.maxWidth),
                child: SerialConsolePanel(
                  onClose: () => setState(() => _showLogs = false),
                ),
              ),
            )
          : null,
    );
  }

  Widget _incomingLines(List<TelemetryLogEntry> entries) {
    final incoming = entries
        .where(
          (entry) =>
              entry.source == TelemetrySource.serial ||
              entry.source == TelemetrySource.peerSerial,
        )
        .toList()
        .reversed
        .take(100)
        .toList();
    if (incoming.isEmpty) {
      return const Center(child: Text('Aún no se recibieron respuestas.'));
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: incoming.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: SelectableText(
          'RX  ${incoming[index].line}',
          style: const TextStyle(color: Colors.green, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
