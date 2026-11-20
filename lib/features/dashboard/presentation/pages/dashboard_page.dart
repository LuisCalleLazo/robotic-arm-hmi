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
import '../widgets/scara_arm_hmi_panel.dart';
import '../widgets/serial_console_panel.dart';

enum _SystemView { complete, arm }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showLogs = false;
  _SystemView _systemView = _SystemView.arm;

  Future<void> _sendCommand(String command, {String? simulatedCommand}) async {
    final trimmedCommand = command.trim();
    if (trimmedCommand.isEmpty) return;
    final telemetry = context.read<TelemetryCubit>();
    if (telemetry.state.isSimulating) {
      telemetry.recordSent(trimmedCommand);
      telemetry.sendSimulatedCommand(simulatedCommand ?? trimmedCommand);
      return;
    }
    final peer = GetIt.I<PeerRepository>();
    if (peer.session.isSlave) {
      if (!peer.session.isActive) {
        throw StateError('Conéctate al servidor maestro para enviar comandos.');
      }
      if (!peer.session.permission.canSendCommands) {
        throw StateError(
          'El maestro no te ha dado permiso para enviar comandos.',
        );
      }
      await peer.send(
        PeerMessage(
          type: PeerMessageType.command,
          payload: {'kind': 'serial_command', 'line': trimmedCommand},
        ),
      );
      if (mounted) telemetry.recordSent(trimmedCommand);
      return;
    }
    if (!context.read<ConnectionBloc>().state.isConnected) {
      throw StateError('El puerto serial está desconectado.');
    }
    context.read<ConnectionBloc>().add(CommandSent(trimmedCommand));
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionBloc>().state;
    final telemetry = context.watch<TelemetryCubit>().state;
    final simulation = telemetry.isSimulating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema'),
        actions: [
          BlocBuilder<PeerCubit, PeerState>(
            bloc: GetIt.I<PeerCubit>(),
            builder: (context, peerState) {
              final session = peerState.session;
              final serialConnected = session.isSlave
                  ? session.isActive
                  : connection.isConnected;
              final label = simulation
                  ? 'Simulado'
                  : session.isSlave
                  ? serialConnected
                        ? 'Serial compartido'
                        : 'Maestro desconectado'
                  : serialConnected
                  ? '${connection.selectedPort} · ${connection.baudRate} baud'
                  : 'Serial desconectado';
              final color = simulation
                  ? Colors.lightBlue
                  : serialConnected
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurfaceVariant;
              return Chip(
                avatar: Icon(Icons.circle, size: 12, color: color),
                label: Text(label),
              );
            },
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
          constraints: const BoxConstraints(maxWidth: 1440),
          child: BlocBuilder<PeerCubit, PeerState>(
            bloc: GetIt.I<PeerCubit>(),
            builder: (context, peerState) {
              final session = peerState.session;
              final canSend =
                  simulation ||
                  (session.isSlave
                      ? session.isActive && session.permission.canSendCommands
                      : connection.isConnected);
              final serialConnected = session.isSlave
                  ? session.isActive
                  : connection.isConnected;
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
                    child: _systemView == _SystemView.arm
                        ? ScaraArmHmiPanel(
                            canSendCommands: canSend,
                            simulating: simulation,
                            serialConnected: serialConnected,
                            connectionLabel: session.isSlave
                                ? 'Serial compartido'
                                : connection.isConnected
                                ? 'Conectado'
                                : 'Desconectado',
                            telemetry: context.read<TelemetryCubit>(),
                            onCommand: _sendCommand,
                          )
                        : const _CompleteSystemPlaceholder(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showLogs = !_showLogs),
        icon: Icon(_showLogs ? Icons.close : Icons.terminal),
        label: Text(_showLogs ? 'Cerrar logs' : 'Logs seriales'),
      ),
      bottomSheet: _showLogs
          ? Align(
              alignment: Alignment.bottomRight,
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: math.min(420, MediaQuery.sizeOf(context).height * .6),
                  width: math.min(560, constraints.maxWidth),
                  child: SerialConsolePanel(
                    onClose: () => setState(() => _showLogs = false),
                    onSend: _sendCommand,
                    canSend:
                        simulation ||
                        (GetIt.I<PeerRepository>().session.isSlave
                            ? GetIt.I<PeerRepository>().session.isActive &&
                                  GetIt.I<PeerRepository>()
                                      .session
                                      .permission
                                      .canSendCommands
                            : connection.isConnected),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _CompleteSystemPlaceholder extends StatelessWidget {
  const _CompleteSystemPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Vista de sistema completo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'La vista global de cintas y varios brazos se habilitará al '
            'configurar esos equipos. El control individual del brazo está disponible.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
