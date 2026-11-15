import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3, radians;

/// Dibuja en 3D una caja (tipo placa/vehículo) con la orientación recibida.
///
/// Convención aeronáutica, con el cuerpo en ejes X adelante, Y izquierda, Z arriba:
///  - roll  (+): ala derecha hacia abajo
///  - pitch (+): nariz hacia arriba
///  - yaw   (+): giro a la derecha (horario visto desde arriba)
///
/// Todo se hace con `vector_math` + `Canvas`, sin dependencias 3D pesadas:
/// proyección en perspectiva, ordenamiento de caras (painter's algorithm),
/// descarte de caras traseras y sombreado simple por cara.
class OrientationPainter extends CustomPainter {
  OrientationPainter({
    required this.rollDeg,
    required this.pitchDeg,
    required this.yawDeg,
    required this.azimuth,
    required this.elevation,
    required this.accent,
    required this.gridColor,
  }) : _rotation = (Matrix4.identity()
         ..rotateZ(-radians(yawDeg))
         ..rotateY(-radians(pitchDeg))
         ..rotateX(radians(rollDeg))),
       _orbit = (Matrix4.identity()
         ..rotateX(elevation)
         ..rotateY(azimuth));

  final double rollDeg;
  final double pitchDeg;
  final double yawDeg;

  /// Giro de la cámara alrededor del objeto (radianes).
  final double azimuth;
  final double elevation;

  final Color accent;
  final Color gridColor;

  final Matrix4 _rotation;
  final Matrix4 _orbit;

  static const double _cameraDistance = 7;
  static const double _gridExtent = 2.5;
  static const double _gridStep = 0.5;
  static const double _gridZ = -1.5;

  // Semi-dimensiones de la caja (X adelante, Y lateral, Z alto).
  static const double _hx = 1.2;
  static const double _hy = 0.8;
  static const double _hz = 0.3;

  /// Vértice i: el bit 0 elige el signo de X, el bit 1 el de Y y el bit 2 el de Z.
  static final List<Vector3> _vertices = List.generate(
    8,
    (i) => Vector3(
      (i & 1) == 0 ? -_hx : _hx,
      (i & 2) == 0 ? -_hy : _hy,
      (i & 4) == 0 ? -_hz : _hz,
    ),
  );

  static final List<_Face> _faces = [
    _Face(
      const [1, 3, 7, 5],
      Vector3(1, 0, 0),
      const Color(0xFFFF8A65),
    ), // frente
    _Face(
      const [0, 4, 6, 2],
      Vector3(-1, 0, 0),
      const Color(0xFF546E7A),
    ), // atrás
    _Face(
      const [2, 3, 7, 6],
      Vector3(0, 1, 0),
      const Color(0xFF607D8B),
    ), // izquierda
    _Face(
      const [0, 1, 5, 4],
      Vector3(0, -1, 0),
      const Color(0xFF607D8B),
    ), // derecha
    _Face(const [4, 5, 7, 6], Vector3(0, 0, 1), null), // arriba (acento)
    _Face(
      const [0, 2, 3, 1],
      Vector3(0, 0, -1),
      const Color(0xFF37474F),
    ), // abajo
  ];

  // ───────────────────────── Transformaciones ─────────────────────────

  /// Mundo (X adelante, Y izquierda, Z arriba) → cámara (X derecha, Y abajo, Z lejos).
  Vector3 _worldToView(Vector3 world) =>
      _orbit.transformed3(Vector3(-world.y, -world.z, world.x));

  Vector3 _bodyToView(Vector3 body) =>
      _worldToView(_rotation.transformed3(body));

  Offset _project(Vector3 view, Size size) {
    final perspective = _cameraDistance / (_cameraDistance + view.z);
    final unit = size.shortestSide / 5.2;
    return Offset(
      size.width / 2 + view.x * unit * perspective,
      size.height / 2 + view.y * unit * perspective,
    );
  }

  // ───────────────────────────── Dibujo ─────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawBox(canvas, size);
    _drawAxes(canvas, size);
  }

  /// Plano de referencia fijo (no gira con el objeto): ayuda a ver la inclinación.
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final steps = (_gridExtent / _gridStep).round();
    for (var i = -steps; i <= steps; i++) {
      final a = i * _gridStep;
      canvas.drawLine(
        _project(_worldToView(Vector3(-_gridExtent, a, _gridZ)), size),
        _project(_worldToView(Vector3(_gridExtent, a, _gridZ)), size),
        paint,
      );
      canvas.drawLine(
        _project(_worldToView(Vector3(a, -_gridExtent, _gridZ)), size),
        _project(_worldToView(Vector3(a, _gridExtent, _gridZ)), size),
        paint,
      );
    }
  }

  void _drawBox(Canvas canvas, Size size) {
    final camera = Vector3(0, 0, -_cameraDistance);
    final light = Vector3(-0.35, -0.6, -0.7)..normalize();

    final drawables = <_DrawableFace>[];
    for (final face in _faces) {
      final corners = [for (final i in face.indices) _bodyToView(_vertices[i])];
      final center = (corners[0] + corners[1] + corners[2] + corners[3]) / 4.0;
      final normal = _bodyToView(face.normal);

      // Cara trasera: no se dibuja.
      if (normal.dot(camera - center) <= 0) continue;

      final diffuse = math.max(0.0, normal.dot(light));
      final brightness = 0.4 + 0.6 * diffuse;
      final color = Color.lerp(
        const Color(0xFF000000),
        face.color ?? accent,
        brightness,
      )!;

      drawables.add(
        _DrawableFace(
          points: [for (final c in corners) _project(c, size)],
          depth: center.z,
          color: color,
        ),
      );
    }

    // De lo más lejano a lo más cercano.
    drawables.sort((a, b) => b.depth.compareTo(a.depth));

    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.25);

    for (final face in drawables) {
      final path = Path()..moveTo(face.points[0].dx, face.points[0].dy);
      for (var i = 1; i < face.points.length; i++) {
        path.lineTo(face.points[i].dx, face.points[i].dy);
      }
      path.close();

      canvas.drawPath(path, fill..color = face.color);
      canvas.drawPath(path, edge);
    }
  }

  void _drawAxes(Canvas canvas, Size size) {
    _drawAxis(canvas, size, Vector3(2.0, 0, 0), const Color(0xFFEF5350), 'X');
    _drawAxis(canvas, size, Vector3(0, 1.5, 0), const Color(0xFF66BB6A), 'Y');
    _drawAxis(canvas, size, Vector3(0, 0, 1.1), const Color(0xFF42A5F5), 'Z');
  }

  void _drawAxis(
    Canvas canvas,
    Size size,
    Vector3 tipBody,
    Color color,
    String label,
  ) {
    final origin = _project(_bodyToView(Vector3.zero()), size);
    final tip = _project(_bodyToView(tipBody), size);

    canvas.drawLine(
      origin,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, tip + const Offset(4, -14));
  }

  @override
  bool shouldRepaint(OrientationPainter old) =>
      old.rollDeg != rollDeg ||
      old.pitchDeg != pitchDeg ||
      old.yawDeg != yawDeg ||
      old.azimuth != azimuth ||
      old.elevation != elevation ||
      old.accent != accent ||
      old.gridColor != gridColor;
}

class _Face {
  _Face(this.indices, this.normal, this.color);

  final List<int> indices;
  final Vector3 normal;

  /// `null` → usa el color de acento del tema.
  final Color? color;
}

class _DrawableFace {
  _DrawableFace({
    required this.points,
    required this.depth,
    required this.color,
  });

  final List<Offset> points;
  final double depth;
  final Color color;
}
