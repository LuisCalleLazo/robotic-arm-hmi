abstract final class SystemOverviewMachineTypes {
  static bool isArm(String type) => _normalize(type).contains('BRAZO');

  static bool isSmallBelt(String type) {
    final normalized = _normalize(type);
    return normalized.contains('CINTA') && normalized.contains('PEQUENA');
  }

  static String _normalize(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('Ñ', 'N')
      .replaceAll(RegExp(r'[^A-Z]'), '');
}
