import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';

class SerialConsolePanel extends StatefulWidget {
  const SerialConsolePanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  State<SerialConsolePanel> createState() => _SerialConsolePanelState();
}

class _SerialConsolePanelState extends State<SerialConsolePanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final connection = context.read<ConnectionBloc>().state;
    final telemetry = context.read<TelemetryCubit>();
    if (connection.isConnected) {
      context.read<ConnectionBloc>().add(CommandSent(text));
    }
    if (telemetry.state.isSimulating) {
      telemetry.sendSimulatedCommand(text);
    }
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connection = context.watch<ConnectionBloc>().state;
    final telemetry = context.watch<TelemetryCubit>().state;
    final canSend = connection.isConnected || telemetry.isSimulating;
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Consolas', 'Menlo', 'Courier New'],
      fontSize: 12,
    );

    return Card(
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logs de desarrollo',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _ModeBadge(
                  label: connection.isConnected ? 'CONECTADO' : 'DESCONECTADO',
                  color: connection.isConnected
                      ? Colors.greenAccent
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (telemetry.isSimulating) ...[
                  const SizedBox(width: 6),
                  const _ModeBadge(label: 'SIMULADO', color: Colors.lightBlue),
                ],
                IconButton(
                  tooltip: 'Cerrar panel',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: telemetry.isSimulating
                      ? () => context.read<TelemetryCubit>().stopSimulation()
                      : () => context.read<TelemetryCubit>().startSimulation(),
                  icon: Icon(
                    telemetry.isSimulating ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    telemetry.isSimulating
                        ? 'Detener simulación'
                        : 'Iniciar simulación',
                  ),
                ),
                if (telemetry.isSimulating)
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.read<TelemetryCubit>().runSimulatedRoute(),
                    icon: const Icon(Icons.route),
                    label: const Text('Probar ruta'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: telemetry.consoleEntries.isEmpty
                    ? Center(
                        child: Text(
                          'Esperando líneas seriales o inicia la simulación.',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: telemetry.consoleEntries.length,
                        itemBuilder: (_, index) {
                          final entry =
                              telemetry.consoleEntries[telemetry
                                      .consoleEntries
                                      .length -
                                  1 -
                                  index];
                          final color = entry.source == TelemetrySource.serial
                              ? Colors.greenAccent
                              : Colors.lightBlueAccent;
                          final source = entry.source == TelemetrySource.serial
                              ? 'SER'
                              : 'SIM';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    source,
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    enabled: canSend,
                    style: mono,
                    decoration: const InputDecoration(
                      hintText: 'Comando (ej: POS, X500, R, P)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar comando',
                  icon: const Icon(Icons.send),
                  onPressed: canSend ? _submit : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    ),
  );
}
