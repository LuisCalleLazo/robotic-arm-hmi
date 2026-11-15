import 'dart:convert';

/// Convierte una línea de texto del Arduino en `canal → valor`.
///
/// Formatos soportados:
///  - `T:25.4,H:60,AX:0.1`   (también `;` como separador y `=` en vez de `:`)
///  - `{"T":25.4,"H":60}`    (JSON plano con valores numéricos)
///
/// Devuelve `null` si la línea no contiene ningún valor numérico válido
/// (por ejemplo mensajes de texto como `ACK:LED_ON`).
class TelemetryParser {
  const TelemetryParser();

  Map<String, double>? parse(String line) {
    final text = line.trim();
    if (text.isEmpty) return null;

    final values = text.startsWith('{')
        ? _parseJson(text)
        : _parseKeyValue(text);
    return values.isEmpty ? null : values;
  }

  Map<String, double> _parseKeyValue(String text) {
    final result = <String, double>{};

    for (final part in text.split(RegExp(r'[,;]'))) {
      final index = part.indexOf(RegExp(r'[:=]'));
      if (index <= 0) continue;

      final key = part.substring(0, index).trim();
      final value = double.tryParse(part.substring(index + 1).trim());
      if (key.isEmpty || value == null || !value.isFinite) continue;

      result[key] = value;
    }
    return result;
  }

  Map<String, double> _parseJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return const <String, double>{};

      final result = <String, double>{};
      decoded.forEach((key, value) {
        if (value is num && value.isFinite) result['$key'] = value.toDouble();
      });
      return result;
    } on FormatException {
      return const <String, double>{};
    }
  }
}
