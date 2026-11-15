import '../entities/port_info.dart';
import '../entities/serial_config.dart';

abstract class SerialRepository {
  /// Puertos seriales detectados en este momento.
  Future<List<PortInfo>> listPorts();

  /// Líneas de texto recibidas (ya separadas por `\n`). Stream broadcast.
  Stream<String> get lines;

  /// Emite `true` al abrir el puerto y `false` al cerrarlo o perderlo.
  Stream<bool> get connectionChanges;

  bool get isConnected;

  /// Lanza una excepción con mensaje legible si no puede abrir el puerto.
  Future<void> connect(SerialConfig config);

  Future<void> disconnect();

  /// Envía [data] al Arduino terminado en `\n`.
  void send(String data);

  void dispose();
}
