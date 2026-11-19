import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';

class SerialConsolePanel extends StatelessWidget {
  const SerialConsolePanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = context.watch<TelemetryCubit>().state.consoleEntries;
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Consolas', 'Menlo', 'Courier New'],
      fontSize: 12,
    );

    return Card(
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.swap_vert_rounded),
            title: const Text('Comunicación serial'),
            subtitle: const Text('Mensajes enviados y recibidos'),
            trailing: IconButton(
              tooltip: 'Cerrar panel',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Aún no hay mensajes seriales.',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: entries.length,
                    itemBuilder: (_, index) {
                      final entry = entries[entries.length - 1 - index];
                      final sent = entry.source == TelemetrySource.serialSent;
                      final simulated =
                          entry.source == TelemetrySource.simulated;
                      final color = simulated
                          ? Colors.lightBlueAccent
                          : Colors.greenAccent;
                      final label = sent
                          ? 'ENV'
                          : simulated
                          ? 'SIM'
                          : 'REC';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                label,
                                style: mono.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.line,
                                style: mono.copyWith(color: color),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
