import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../telemetry/presentation/cubit/telemetry_cubit.dart';

class ScaraArmCanvas extends StatelessWidget {
  const ScaraArmCanvas({
    required this.x,
    required this.y,
    required this.z,
    required this.a,
    required this.gripperOpen,
    required this.machineState,
    super.key,
  });

  final double x;
  final double y;
  final double z;
  final double a;
  final double gripperOpen;
  final String machineState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ScaraProcessPainter(
        x: x * _ScaraProcessPainter._maxX,
        y: y * _ScaraProcessPainter._maxY,
        a: a * _ScaraProcessPainter._maxA,
        z: z * _ScaraProcessPainter._maxZ,
        gripperClosed: gripperOpen <= 0.02,
        gripperOpening: gripperOpen,
        machineState: machineState,
        armCount: 1,
        sensorEnabled: false,
        sensorDetected: false,
        objectOnBelt: false,
        objectPicked: false,
        objectDelivered: false,
        objectProgress: 0,
        accent: colors.primary,
        textColor: colors.onSurface,
        mutedColor: colors.onSurfaceVariant,
        surfaceColor: colors.surfaceContainerHighest,
        gridColor: colors.outlineVariant,
        showBelt: false,
        showReadout: false,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class ScaraProcessPanel extends StatefulWidget {
  const ScaraProcessPanel({super.key});

  @override
  State<ScaraProcessPanel> createState() => _ScaraProcessPanelState();
}

class _ScaraProcessPanelState extends State<ScaraProcessPanel> {
  Timer? _timer;
  bool _sensorEnabled = true;
  bool _objectOnBelt = false;
  bool _sensorDetected = false;
  bool _objectPicked = false;
  bool _objectDelivered = false;
  bool _routeStartedForObject = false;
  double _objectProgress = 0;
  DateTime? _deliveredAt;
  int _armCount = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addObject() {
    if (_objectOnBelt || _objectPicked) return;
    setState(() {
      _objectOnBelt = true;
      _sensorDetected = false;
      _objectDelivered = false;
      _routeStartedForObject = false;
      _objectProgress = 0;
      _deliveredAt = null;
    });
  }

  void _tick() {
    final telemetry = context.read<TelemetryCubit>();
    final state = telemetry.state;
    var changed = false;

    if (state.isSimulating &&
        !_objectOnBelt &&
        !_objectPicked &&
        !_objectDelivered) {
      _objectOnBelt = true;
      _sensorDetected = false;
      _routeStartedForObject = false;
      _objectProgress = 0;
      changed = true;
    }

    if (_objectOnBelt && _sensorEnabled && !_sensorDetected) {
      _objectProgress = math.min(0.62, _objectProgress + 0.006);
      changed = true;
      if (_objectProgress >= 0.62) {
        _sensorDetected = true;
        changed = true;
      }
    }

    if (_sensorDetected &&
        !_routeStartedForObject &&
        state.isSimulating &&
        state.machineState == 'IDLE') {
      _routeStartedForObject = true;
      telemetry.runSimulatedRoute();
    }

    if (_objectOnBelt &&
        _sensorDetected &&
        state.routeStep == 0 &&
        state.gripperClosed) {
      _objectOnBelt = false;
      _objectPicked = true;
      changed = true;
    }

    if (_objectPicked && state.routeStep == 3 && !state.gripperClosed) {
      _objectPicked = false;
      _objectDelivered = true;
      _deliveredAt = DateTime.now();
      changed = true;
    }

    final deliveredAt = _deliveredAt;
    if (_objectDelivered &&
        state.isSimulating &&
        deliveredAt != null &&
        DateTime.now().difference(deliveredAt) >
            const Duration(milliseconds: 1200)) {
      _addObject();
      return;
    }

    if (changed || _objectOnBelt || state.isSimulating) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final telemetry = context.watch<TelemetryCubit>().state;
    final latest = telemetry.latest;
    final sensorLabel = !_sensorEnabled
        ? 'Sensor virtual apagado'
        : _sensorDetected
        ? 'Sensor: objeto detectado'
        : 'Sensor virtual: esperando objeto';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Proceso SCARA',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                DropdownButton<int>(
                  value: _armCount,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 brazo')),
                    DropdownMenuItem(value: 2, child: Text('2 brazos')),
                    DropdownMenuItem(value: 3, child: Text('3 brazos')),
                  ],
                  onChanged: (count) {
                    if (count != null) setState(() => _armCount = count);
                  },
                ),
              ],
            ),
            Text(
              'SCARA: columna Z · giro X · extensión Y · muñeca A',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: CustomPaint(
                painter: _ScaraProcessPainter(
                  x: latest?['X'] ?? 8000,
                  y: latest?['Y'] ?? 5500,
                  a: latest?['A'] ?? 1200,
                  z: latest?['Z'] ?? 0,
                  gripperClosed: telemetry.gripperClosed,
                  machineState: telemetry.machineState,
                  armCount: _armCount,
                  sensorEnabled: _sensorEnabled,
                  sensorDetected: _sensorDetected,
                  objectOnBelt: _objectOnBelt,
                  objectPicked: _objectPicked,
                  objectDelivered: _objectDelivered,
                  objectProgress: _objectProgress,
                  accent: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onSurface,
                  mutedColor: theme.colorScheme.onSurfaceVariant,
                  surfaceColor: theme.colorScheme.surfaceContainerHighest,
                  gridColor: theme.colorScheme.outlineVariant,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.sensors,
                        size: 18,
                        color: _sensorDetected
                            ? Colors.greenAccent
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          sensorLabel,
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _objectOnBelt || _objectPicked ? null : _addObject,
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Objeto'),
                ),
                Switch(
                  value: _sensorEnabled,
                  onChanged: (enabled) =>
                      setState(() => _sensorEnabled = enabled),
                ),
              ],
            ),
            if (_armCount > 1)
              Text(
                'Solo el brazo 1 está conectado; los demás son puestos previstos.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScaraProcessPainter extends CustomPainter {
  const _ScaraProcessPainter({
    required this.x,
    required this.y,
    required this.a,
    required this.z,
    required this.gripperClosed,
    required this.machineState,
    required this.armCount,
    required this.sensorEnabled,
    required this.sensorDetected,
    required this.objectOnBelt,
    required this.objectPicked,
    required this.objectDelivered,
    required this.objectProgress,
    this.gripperOpening,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.gridColor,
    this.showBelt = true,
    this.showReadout = true,
  });

  final double x;
  final double y;
  final double a;
  final double z;
  final bool gripperClosed;
  final String? machineState;
  final int armCount;
  final bool sensorEnabled;
  final bool sensorDetected;
  final bool objectOnBelt;
  final bool objectPicked;
  final bool objectDelivered;
  final double objectProgress;
  final double? gripperOpening;
  final Color accent;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color gridColor;
  final bool showBelt;
  final bool showReadout;

  static const double _maxX = 30450;
  static const double _maxY = 11834;
  static const double _maxA = 3426;
  static const double _maxZ = 47829;

  @override
  void paint(Canvas canvas, Size size) {
    final beltTop = size.height * 0.78;
    final beltRect = Rect.fromLTWH(
      size.width * 0.025,
      beltTop,
      size.width * 0.95,
      size.height * 0.13,
    );
    final pick = _geometry(size, 8000, 5500, 41000, 1200);
    final drop = _geometry(size, 16000, 5500, 41000, 1200);
    final sensorX = pick.toolTip.dx.clamp(
      beltRect.left + 12,
      beltRect.right - 12,
    );
    final dropX = drop.toolTip.dx.clamp(
      beltRect.left + 12,
      beltRect.right - 12,
    );
    if (showBelt) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(beltRect, const Radius.circular(9)),
        Paint()..color = surfaceColor.withValues(alpha: 0.85),
      );
      final rollerPaint = Paint()
        ..color = gridColor.withValues(alpha: 0.65)
        ..strokeWidth = 1;
      for (var i = 1; i < 12; i++) {
        final rollerX = beltRect.left + beltRect.width * i / 12;
        canvas.drawLine(
          Offset(rollerX, beltRect.top + 4),
          Offset(rollerX, beltRect.bottom - 4),
          rollerPaint,
        );
      }

      _drawDropZone(canvas, Offset(dropX, beltTop), textColor, gridColor);
      _drawSensor(
        canvas,
        Offset(sensorX, beltTop),
        enabled: sensorEnabled,
        detected: sensorDetected,
      );
      _drawBeltFlow(canvas, beltRect);
    }

    for (var index = armCount - 1; index >= 0; index--) {
      final active = index == 0;
      final geometry = active
          ? _geometry(size, x, y, z, a)
          : _geometry(size, 12000, 6000, 0, 1200, armIndex: index);
      _drawArm(canvas, size, geometry, active: active);
      if (!active) {
        _drawLabel(
          canvas,
          'A${index + 1} previsto',
          Offset(geometry.columnX, size.height * 0.19),
          mutedColor,
          9,
          alignCenter: true,
        );
      }
    }

    if (showBelt && objectOnBelt) {
      final objectX =
          beltRect.left + (sensorX - beltRect.left) * objectProgress / 0.62;
      _drawObject(canvas, Offset(objectX, beltTop - 8), Colors.orangeAccent);
    } else if (showBelt && objectDelivered) {
      _drawObject(canvas, Offset(dropX, beltTop - 8), Colors.lightGreenAccent);
    } else if (showBelt && objectPicked) {
      _drawObject(
        canvas,
        _geometry(size, x, y, z, a).toolTip,
        Colors.orangeAccent,
      );
    }

    if (showReadout) {
      _drawLabel(
        canvas,
        'X ${x.round()}  Y ${y.round()}  A ${a.round()}  Z ${z.round()}',
        Offset(8, size.height - 2),
        mutedColor,
        10,
      );
      _drawLabel(
        canvas,
        machineState ?? 'Sin datos del brazo',
        Offset(size.width - 8, size.height - 2),
        machineState == 'ERROR' ? Colors.redAccent : accent,
        10,
        alignRight: true,
      );
    }
  }

  _ScaraGeometry _geometry(
    Size size,
    double x,
    double y,
    double z,
    double a, {
    int armIndex = 0,
  }) {
    final columnX = armCount == 1
        ? size.width * 0.20
        : size.width * (0.12 + armIndex * 0.48 / math.max(1, armCount - 1));
    final yaw = ((x / _maxX).clamp(0, 1) - 0.5) * 1.05;
    final extension = size.width * (0.20 + (y / _maxY).clamp(0, 1) * 0.28);
    final carriageY = size.height * (0.29 + (z / _maxZ).clamp(0, 1) * 0.22);
    final shoulder = Offset(columnX, carriageY);
    final beamEnd =
        shoulder +
        Offset(math.cos(yaw) * extension, math.sin(yaw) * extension * 0.48);
    final toolTip = beamEnd + Offset(0, 23 + size.height * 0.12);

    return _ScaraGeometry(
      columnX: columnX,
      shoulder: shoulder,
      beamEnd: beamEnd,
      toolTip: toolTip,
      wristAngle: (a / _maxA).clamp(0, 1) * math.pi * 2,
    );
  }

  void _drawArm(
    Canvas canvas,
    Size size,
    _ScaraGeometry geometry, {
    required bool active,
  }) {
    final armBlue = const Color(0xFF1676D2);
    final color = active ? armBlue : mutedColor.withValues(alpha: 0.38);
    final beamHeight = active ? 16.0 : 11.0;
    final beamPaint = Paint()..color = color;
    final framePaint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..strokeWidth = active ? 2 : 1.5;
    final baseTop = size.height * 0.75;
    final baseWidth = active ? 66.0 : 52.0;
    final mastWidth = active ? 34.0 : 25.0;
    final frontX = geometry.columnX - mastWidth / 2;
    final rearX = geometry.columnX + mastWidth / 2;
    final topY = size.height * 0.09;
    final railBottom = baseTop - 8;

    final baseRect = Rect.fromLTWH(
      geometry.columnX - baseWidth / 2,
      baseTop - 28,
      baseWidth,
      28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(5)),
      beamPaint,
    );
    canvas.drawLine(
      Offset(frontX, topY + 10),
      Offset(frontX, railBottom),
      framePaint..strokeWidth = active ? 4 : 3,
    );
    canvas.drawLine(
      Offset(geometry.columnX - 7, topY + 10),
      Offset(geometry.columnX - 7, railBottom),
      framePaint,
    );
    canvas.drawLine(
      Offset(geometry.columnX + 7, topY + 10),
      Offset(geometry.columnX + 7, railBottom),
      framePaint,
    );
    canvas.drawLine(
      Offset(rearX, topY + 10),
      Offset(rearX, railBottom),
      framePaint,
    );

    final capRect = Rect.fromCenter(
      center: Offset(geometry.columnX, topY + 8),
      width: mastWidth + 18,
      height: 15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(7)),
      beamPaint,
    );

    final carriage = Rect.fromCenter(
      center: Offset(geometry.columnX, geometry.shoulder.dy),
      width: mastWidth + 14,
      height: 26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(carriage, const Radius.circular(5)),
      beamPaint,
    );

    final shoulderHousing = Rect.fromCenter(
      center: Offset(geometry.columnX + 8, geometry.shoulder.dy),
      width: 23,
      height: 30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shoulderHousing, const Radius.circular(5)),
      Paint()..color = active ? Colors.blue.shade700 : color,
    );

    final beamStart = Offset(geometry.columnX + 13, geometry.shoulder.dy);
    final beamEnd = geometry.beamEnd;
    final beamPath = Path()
      ..moveTo(beamStart.dx, beamStart.dy - beamHeight / 2)
      ..lineTo(beamEnd.dx, beamEnd.dy - beamHeight / 2)
      ..lineTo(beamEnd.dx, beamEnd.dy + beamHeight / 2)
      ..lineTo(beamStart.dx, beamStart.dy + beamHeight / 2)
      ..close();
    canvas.drawPath(beamPath, beamPaint);

    final telescopicStart = beamStart + (beamEnd - beamStart) * 0.48;
    final innerBeam = Paint()..color = color.withValues(alpha: 0.82);
    canvas.drawLine(
      telescopicStart,
      beamEnd,
      innerBeam
        ..strokeWidth = active ? 6 : 4
        ..strokeCap = StrokeCap.square,
    );

    final motor = Rect.fromCenter(
      center: beamEnd + const Offset(0, 12),
      width: 29,
      height: 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(motor, const Radius.circular(4)),
      Paint()..color = active ? Colors.blue.shade700 : color,
    );
    canvas.drawCircle(
      beamEnd,
      8,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawLine(
      beamEnd + const Offset(0, 23),
      geometry.toolTip,
      framePaint
        ..strokeWidth = active ? 5 : 3
        ..strokeCap = StrokeCap.round,
    );
    _drawGripper(
      canvas,
      geometry.toolTip,
      geometry.wristAngle,
      gripperClosed && active,
      gripperOpening,
      color,
    );

    final pivotCenter = Offset(geometry.columnX, baseTop - 27);
    canvas.drawCircle(
      pivotCenter,
      13,
      Paint()
        ..color = active ? Colors.blue.shade700 : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final yawArc = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawArc(
      Rect.fromCircle(center: pivotCenter, radius: 21),
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      yawArc,
    );

    if (active) {
      _drawLabel(
        canvas,
        'Z',
        Offset(geometry.columnX, geometry.shoulder.dy + 2),
        textColor,
        9,
        alignCenter: true,
      );
      _drawLabel(
        canvas,
        'Y',
        Offset((beamStart.dx + beamEnd.dx) / 2, beamStart.dy - 11),
        textColor,
        9,
        alignCenter: true,
      );
      _drawLabel(
        canvas,
        'X',
        Offset(geometry.columnX, baseTop - 3),
        textColor,
        9,
        alignCenter: true,
      );
      _drawLabel(
        canvas,
        'A',
        Offset(geometry.toolTip.dx + 13, geometry.toolTip.dy - 4),
        textColor,
        9,
      );
    }
  }

  void _drawGripper(
    Canvas canvas,
    Offset tip,
    double angle,
    bool closed,
    double? opening,
    Color color,
  ) {
    final fingerPaint = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final jawGap = opening == null
        ? closed
              ? 3.0
              : 8.0
        : 3.0 + opening.clamp(0, 1) * 7.0;
    final jawAngle = math.sin(angle) * 0.22;

    for (final side in [-1.0, 1.0]) {
      final start = tip + Offset(side * jawGap, 0);
      final end = start + Offset(side * 2 + jawAngle, 14);
      canvas.drawLine(start, end, fingerPaint);
      canvas.drawLine(end, end + Offset(-side * 4, 3), fingerPaint);
    }
    canvas.drawLine(
      tip + const Offset(-6, -2),
      tip + const Offset(6, -2),
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBeltFlow(Canvas canvas, Rect beltRect) {
    final flowPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = beltRect.left + beltRect.width * (0.18 + i * 0.2);
      final y = beltRect.top + beltRect.height / 2;
      canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), flowPaint);
      canvas.drawLine(Offset(x + 2, y - 3), Offset(x + 5, y), flowPaint);
      canvas.drawLine(Offset(x + 2, y + 3), Offset(x + 5, y), flowPaint);
    }
  }

  void _drawSensor(
    Canvas canvas,
    Offset position, {
    required bool enabled,
    required bool detected,
  }) {
    final color = !enabled
        ? mutedColor
        : detected
        ? Colors.greenAccent
        : Colors.orangeAccent;
    canvas.drawLine(
      position,
      position - const Offset(0, 30),
      Paint()
        ..color = mutedColor
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      position - const Offset(0, 33),
      6,
      Paint()..color = color,
    );
    _drawLabel(
      canvas,
      'SENSOR',
      position - const Offset(0, 37),
      color,
      9,
      alignCenter: true,
    );
  }

  void _drawDropZone(Canvas canvas, Offset position, Color color, Color grid) {
    final rect = Rect.fromCenter(
      center: position - const Offset(0, 10),
      width: 25,
      height: 20,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = grid.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawLabel(
      canvas,
      'SALIDA',
      position - const Offset(0, 36),
      color,
      9,
      alignCenter: true,
    );
  }

  void _drawObject(Canvas canvas, Offset position, Color color) {
    final rect = Rect.fromCenter(center: position, width: 15, height: 15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = color,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize, {
    bool alignCenter = false,
    bool alignRight = false,
  }) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignCenter
          ? TextAlign.center
          : alignRight
          ? TextAlign.right
          : TextAlign.left,
    )..layout();
    final offset = Offset(
      alignCenter
          ? position.dx - painter.width / 2
          : alignRight
          ? position.dx - painter.width
          : position.dx,
      position.dy - painter.height,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ScaraProcessPainter oldDelegate) => true;
}

class _ScaraGeometry {
  const _ScaraGeometry({
    required this.columnX,
    required this.shoulder,
    required this.beamEnd,
    required this.toolTip,
    required this.wristAngle,
  });

  final double columnX;
  final Offset shoulder;
  final Offset beamEnd;
  final Offset toolTip;
  final double wristAngle;
}
