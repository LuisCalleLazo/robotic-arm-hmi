import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';

/// Gráfica en tiempo real con selector de canales.
/// Evita mezclar unidades distintas: por defecto muestra solo el primer canal.
class LineChartPanel extends StatefulWidget {
  const LineChartPanel({super.key});

  @override
  State<LineChartPanel> createState() => _LineChartPanelState();
}

class _LineChartPanelState extends State<LineChartPanel> {
  static const _palette = [
    Color(0xFF4FC3F7),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
    Color(0xFFFFF176),
  ];

  final Set<String> _selected = {};
  bool _userChose = false;

  Color _colorFor(List<String> channels, String channel) =>
      _palette[channels.indexOf(channel) % _palette.length];

  void _toggle(String channel, bool on) {
    setState(() {
      _userChose = true;
      on ? _selected.add(channel) : _selected.remove(channel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: BlocBuilder<TelemetryCubit, TelemetryState>(
          builder: (context, state) {
            final channels = state.channels;
            final selected = _userChose
                ? _selected
                : (channels.isEmpty ? <String>{} : {channels.first});

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Tiempo real', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final channel in channels)
                            FilterChip(
                              label: Text(channel),
                              selected: selected.contains(channel),
                              selectedColor: _colorFor(
                                channels,
                                channel,
                              ).withValues(alpha: 0.35),
                              onSelected: (on) {
                                // Al primer toque, parte de la selección visible.
                                if (!_userChose) _selected.addAll(selected);
                                _toggle(channel, on);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildChart(context, state, selected)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    TelemetryState state,
    Set<String> selected,
  ) {
    final theme = Theme.of(context);
    final history = state.history;

    if (history.length < 2) {
      return const Center(child: Text('Esperando datos…'));
    }
    if (selected.isEmpty) {
      return const Center(child: Text('Selecciona al menos un canal'));
    }

    final bars = <LineChartBarData>[];
    for (final channel in state.channels) {
      if (!selected.contains(channel)) continue;

      final spots = <FlSpot>[
        for (final reading in history)
          if (reading[channel] != null)
            FlSpot(reading.seq.toDouble(), reading[channel]!),
      ];
      if (spots.length < 2) continue;

      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: _colorFor(state.channels, channel),
          barWidth: 1.8,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (bars.isEmpty) return const Center(child: Text('Esperando datos…'));

    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return LineChart(
      LineChartData(
        minX: history.first.seq.toDouble(),
        maxX: history.last.seq.toDouble(),
        lineBarsData: bars,
        lineTouchData: const LineTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: hidden,
          rightTitles: hidden,
          bottomTitles: hidden,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  meta.formattedValue,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
      ),
      // Sin animación: los datos llegan continuamente.
      duration: Duration.zero,
    );
  }
}
