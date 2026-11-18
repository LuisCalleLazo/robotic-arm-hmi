/// Tipo de máquina que representa cada esclavo.
/// Para agregar una máquina nueva: añade un valor aquí y su label/icono en peer_labels.dart.
enum PeerMachineType {
  brazo('brazo'),
  cintaPequena('cinta_transportadora_pequena'),
  cintaGrande('cinta_transportadora_grande');

  const PeerMachineType(this.id);

  /// Identificador estable usado en el protocolo.
  final String id;

  static PeerMachineType? tryParse(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}
