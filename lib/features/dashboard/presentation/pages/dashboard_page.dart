import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  bool _showLogs = false;

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionBloc>().state;
    final simulation = context.watch<TelemetryCubit>().state.isSimulating;
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
      body: const Center(
        child: Text('Sistema general preparado para la animación futura.'),
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
}
