import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_hmi/features/view_3d/presentation/widgets/orientation_view.dart';

import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../widgets/line_chart_panel.dart';
import '../widgets/readings_strip.dart';
import '../widgets/scara_process_panel.dart';
import '../widgets/serial_console_panel.dart';

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
    final isSimulating = context.select<TelemetryCubit, bool>(
      (cubit) => cubit.state.isSimulating,
    );
    final modeColor = isSimulating
        ? Colors.lightBlue
        : connection.isConnected
        ? Colors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final modeLabel = isSimulating
        ? 'Simulado'
        : connection.isConnected
        ? '${connection.selectedPort} · ${connection.baudRate} baud'
        : 'Desconectado';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text('HMI Arduino'),
            const SizedBox(width: 16),
            Chip(
              avatar: Icon(Icons.circle, size: 12, color: modeColor),
              label: Text(modeLabel),
            ),
          ],
        ),
        actions: [
          const _RateIndicator(),
          IconButton(
            tooltip: 'Limpiar datos',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => context.read<TelemetryCubit>().clear(),
          ),
          if (isSimulating)
            IconButton(
              tooltip: 'Salir de la simulación',
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => context.read<TelemetryCubit>().stopSimulation(),
            ),
          IconButton(
            tooltip: 'Desconectar',
            icon: const Icon(Icons.link_off),
            onPressed: () =>
                context.read<ConnectionBloc>().add(const DisconnectRequested()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          final dashboard = compact
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const ReadingsStrip(),
                      const SizedBox(height: 12),
                      const SizedBox(height: 320, child: LineChartPanel()),
                      const SizedBox(height: 12),
                      const SizedBox(height: 380, child: _RobotViewSwitcher()),
                    ],
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReadingsStrip(),
                            SizedBox(height: 12),
                            Expanded(child: LineChartPanel()),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(width: 380, child: _RobotViewSwitcher()),
                    ],
                  ),
                );

          return Stack(
            children: [
              Positioned.fill(child: dashboard),
              if (_showLogs)
                Positioned(
                  right: 16,
                  bottom: 88,
                  width: math.max(1, math.min(480, constraints.maxWidth - 32)),
                  height: math.max(
                    1,
                    math.min(540, constraints.maxHeight - 104),
                  ),
                  child: SerialConsolePanel(
                    onClose: () => setState(() => _showLogs = false),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'robot-stop',
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            onPressed: connection.isConnected || isSimulating
                ? () => sendRobotCommand(context, 'P')
                : null,
            icon: const Icon(Icons.stop),
            label: const Text('STOP'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'serial-logs',
            onPressed: () => setState(() => _showLogs = !_showLogs),
            icon: Icon(_showLogs ? Icons.close : Icons.terminal),
            label: Text(_showLogs ? 'Cerrar logs' : 'Logs'),
          ),
        ],
      ),
    );
  }
}

class _RobotViewSwitcher extends StatefulWidget {
  const _RobotViewSwitcher();

  @override
  State<_RobotViewSwitcher> createState() => _RobotViewSwitcherState();
}

class _RobotViewSwitcherState extends State<_RobotViewSwitcher> {
  bool _showOrientation = false;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.precision_manufacturing_outlined),
            label: Text('Proceso 2D'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.threed_rotation),
            label: Text('Orientación 3D'),
          ),
        ],
        selected: {_showOrientation},
        onSelectionChanged: (selection) =>
            setState(() => _showOrientation = selection.first),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _showOrientation
            ? const OrientationView()
            : const ScaraProcessPanel(),
      ),
    ],
  );
}

class _RateIndicator extends StatelessWidget {
  const _RateIndicator();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryCubit, TelemetryState>(
      buildWhen: (a, b) =>
          a.packetsPerSecond != b.packetsPerSecond ||
          a.invalidLines != b.invalidLines,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              '${state.packetsPerSecond.toStringAsFixed(0)} pkt/s'
              '${state.invalidLines > 0 ? '  ·  ${state.invalidLines} ignoradas' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
