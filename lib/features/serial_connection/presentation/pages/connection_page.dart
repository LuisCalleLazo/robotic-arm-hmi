import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/serial_config.dart';
import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../bloc/connection_bloc.dart';

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ConnectionBloc>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<ConnectionBloc, SerialConnectionState>(
                builder: (context, state) {
                  final busy = state.isConnecting;
                  final hasPorts = state.ports.isNotEmpty;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.usb, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Conectar al Arduino',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige el puerto y la velocidad configurada en tu sketch.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Puerto',
                                border: OutlineInputBorder(),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: state.selectedPort,
                                  hint: const Text('Sin puertos'),
                                  items: [
                                    for (final p in state.ports)
                                      DropdownMenuItem(
                                        value: p.name,
                                        child: Text(
                                          p.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (hasPorts && !busy)
                                      ? (name) {
                                          if (name != null) {
                                            bloc.add(PortSelected(name));
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Actualizar puertos',
                            icon: const Icon(Icons.refresh),
                            onPressed: busy
                                ? null
                                : () => bloc.add(const PortsRefreshed()),
                          ),
                        ],
                      ),
                      if (!hasPorts)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No se detectan puertos. Conecta el Arduino por USB.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Baud rate',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: state.baudRate,
                            items: [
                              for (final rate in kBaudRates)
                                DropdownMenuItem(
                                  value: rate,
                                  child: Text('$rate'),
                                ),
                            ],
                            onChanged: busy
                                ? null
                                : (rate) {
                                    if (rate != null) {
                                      bloc.add(BaudRateSelected(rate));
                                    }
                                  },
                          ),
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: state.canConnect
                            ? () => bloc.add(const ConnectRequested())
                            : null,
                        icon: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.power_settings_new),
                        label: Text(busy ? 'Conectando…' : 'Conectar'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.read<TelemetryCubit>().startSimulation(),
                        icon: const Icon(Icons.developer_mode),
                        label: const Text('Probar sin Arduino'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
