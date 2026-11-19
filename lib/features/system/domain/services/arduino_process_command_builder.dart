class ArduinoProcessCommandBuilder {
  const ArduinoProcessCommandBuilder._();

  static String commandKey(String key) {
    final trimmed = key.trim();
    return trimmed.toUpperCase().startsWith('BC') ? trimmed : 'BC$trimmed';
  }

  static String movement({
    required String key,
    required num value,
    required num speed,
  }) => '${commandKey(key)}${value.round()}:${speed.round()}';

  static String line(Iterable<String> movements) => movements.join(' ');
}
