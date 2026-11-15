import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../serial_connection/presentation/bloc/connection_bloc.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';

/// Consola cruda del serial: muestra lo que llega y permite enviar comandos.
class SerialConsolePanel extends StatefulWidget {
  const SerialConsolePanel({super.key});

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
    context.read<ConnectionBloc>().add(CommandSent(text));
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Consolas', 'Menlo', 'Courier New'],
      fontSize: 12,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Consola serial', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BlocBuilder<TelemetryCubit, TelemetryState>(
                  buildWhen: (a, b) => a.rawLines != b.rawLines,
                  builder: (context, state) {
                    final lines = state.rawLines;
                    // `reverse: true` mantiene pegado al final (lo más nuevo).
                    return ListView.builder(
                      reverse: true,
                      itemCount: lines.length,
                      itemBuilder: (_, index) => Text(
                        lines[lines.length - 1 - index],
                        style: mono,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    style: mono,
                    decoration: const InputDecoration(
                      hintText: 'Comando para el Arduino (ej: LED_ON)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar',
                  icon: const Icon(Icons.send),
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
