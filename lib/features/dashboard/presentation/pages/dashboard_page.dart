import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_hmi/features/view_3d/presentation/widgets/orientation_view.dart';

import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../widgets/line_chart_panel.dart';
import '../widgets/readings_strip.dart';
import '../widgets/serial_console_panel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionBloc>().state;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text('HMI Arduino'),
            const SizedBox(width: 16),
            Chip(
              avatar: const Icon(
                Icons.circle,
                size: 12,
                color: Colors.greenAccent,
              ),
              label: Text(
                '${connection.selectedPort} · ${connection.baudRate} baud',
              ),
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
          IconButton(
            tooltip: 'Desconectar',
            icon: const Icon(Icons.link_off),
            onPressed: () =>
                context.read<ConnectionBloc>().add(const DisconnectRequested()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Padding(
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
            SizedBox(
              width: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: OrientationView()),
                  SizedBox(height: 12),
                  Expanded(child: SerialConsolePanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
