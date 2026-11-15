import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';
import '../painters/orientation_painter.dart';

/// Panel 3D: muestra la orientación (roll/pitch/yaw en grados) del último
/// dato recibido. Arrastra con el mouse para orbitar; doble clic para restablecer.
///
/// Si tu IMU entrega un signo distinto al esperado, usa `invertRoll`,
/// `invertPitch` o `invertYaw`.
class OrientationView extends StatefulWidget {
  const OrientationView({
    super.key,
    this.rollKey = 'R',
    this.pitchKey = 'P',
    this.yawKey = 'Y',
    this.invertRoll = false,
    this.invertPitch = false,
    this.invertYaw = false,
  });

  final String rollKey;
  final String pitchKey;
  final String yawKey;
  final bool invertRoll;
  final bool invertPitch;
  final bool invertYaw;

  @override
  State<OrientationView> createState() => _OrientationViewState();
}

class _OrientationViewState extends State<OrientationView> {
  static const double _defaultAzimuth = -0.6;
  static const double _defaultElevation = 0.45;

  double _azimuth = _defaultAzimuth;
  double _elevation = _defaultElevation;

  void _resetView() {
    setState(() {
      _azimuth = _defaultAzimuth;
      _elevation = _defaultElevation;
    });
  }

  void _onPan(DragUpdateDetails details) {
    setState(() {
      _azimuth += details.delta.dx * 0.01;
      _elevation = (_elevation + details.delta.dy * 0.01)
          .clamp(-1.4, 1.4)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Orientación 3D', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Restablecer cámara',
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  onPressed: _resetView,
                ),
              ],
            ),
            Expanded(
              child: ClipRect(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _onPan,
                  onDoubleTap: _resetView,
                  child: BlocBuilder<TelemetryCubit, TelemetryState>(
                    builder: _buildScene,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScene(BuildContext context, TelemetryState state) {
    final theme = Theme.of(context);
    final latest = state.latest;

    final roll = latest?[widget.rollKey];
    final pitch = latest?[widget.pitchKey];
    final yaw = latest?[widget.yawKey];

    if (roll == null || pitch == null || yaw == null) {
      return Center(
        child: Text(
          'Sin datos de orientación.\n'
          'Envía los canales ${widget.rollKey}, ${widget.pitchKey} y '
          '${widget.yawKey} en grados.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: OrientationPainter(
                rollDeg: widget.invertRoll ? -roll : roll,
                pitchDeg: widget.invertPitch ? -pitch : pitch,
                yawDeg: widget.invertYaw ? -yaw : yaw,
                azimuth: _azimuth,
                elevation: _elevation,
                accent: theme.colorScheme.primary,
                gridColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Readout(label: 'Roll', degrees: roll),
              _Readout(label: 'Pitch', degrees: pitch),
              _Readout(label: 'Yaw', degrees: yaw),
            ],
          ),
        ),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.label, required this.degrees});

  final String label;
  final double degrees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          '${degrees.toStringAsFixed(1)}°',
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
