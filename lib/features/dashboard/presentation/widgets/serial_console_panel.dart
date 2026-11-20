import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import 'scara_arm_hmi_panel.dart';

class SerialConsolePanel extends StatefulWidget {
  const SerialConsolePanel({
    required this.onClose,
    required this.onSend,
    required this.canSend,
    super.key,
  });

  final VoidCallback onClose;
  final ArmCommandSender onSend;
  final bool canSend;

  @override
  State<SerialConsolePanel> createState() => _SerialConsolePanelState();
}

class _SerialConsolePanelState extends State<SerialConsolePanel> {
  final _commandController = TextEditingController();

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    try {
      await widget.onSend(command);
      if (mounted) _commandController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo enviar: $error')));
    }
  }

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
              onPressed: widget.onClose,
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
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    enabled: widget.canSend,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      labelText: 'Comando serial',
                      hintText: 'Ej. BC?',
                      isDense: true,
                      prefixIcon: Icon(Icons.terminal),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar comando',
                  onPressed: widget.canSend ? _send : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
