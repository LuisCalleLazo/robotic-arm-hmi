import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';

/// Tarjetas con el último valor de cada canal.
class ReadingsStrip extends StatelessWidget {
  const ReadingsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TelemetryCubit, TelemetryState>(
      builder: (context, state) {
        final latest = state.latest;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: latest == null
                ? Text(
                    'Esperando datos del Arduino…  '
                    '(formato esperado: T:25.4,H:60)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final channel in state.channels)
                        _ValueTile(label: channel, value: latest[channel]),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value == null ? '—' : value!.toStringAsFixed(2),
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
