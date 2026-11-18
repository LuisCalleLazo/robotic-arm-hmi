/// Configuración fija del feature.
class PeerConfig {
  const PeerConfig._();

  /// Contraseña para entrar como maestro. Cámbiala aquí.
  static const masterPassword = 'Hayden988';

  /// Puerto del servidor WebSocket del maestro.
  static const defaultPort = 8765;

  /// Puerto UDP usado para que los esclavos encuentren maestros por nombre.
  static const discoveryPort = 8766;
}
