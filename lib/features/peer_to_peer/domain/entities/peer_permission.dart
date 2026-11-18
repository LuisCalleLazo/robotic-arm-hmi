/// Permiso que el maestro concede a cada esclavo.
enum PeerPermission {
  /// Solo recibe telemetría / estado.
  viewOnly,

  /// Puede enviar comandos al maestro.
  control;

  bool get canSendCommands => this == PeerPermission.control;

  static PeerPermission fromName(String? name) => PeerPermission.values
      .firstWhere((p) => p.name == name, orElse: () => PeerPermission.viewOnly);
}
