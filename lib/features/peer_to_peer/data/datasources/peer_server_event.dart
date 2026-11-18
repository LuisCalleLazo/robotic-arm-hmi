sealed class PeerServerEvent {
  const PeerServerEvent();
}

class ClientConnected extends PeerServerEvent {
  const ClientConnected(this.id, this.name, this.machine);
  final String id;
  final String name;

  /// Id crudo de la máquina enviado por el esclavo (puede ser null o inválido).
  final String? machine;
}

class ClientDisconnected extends PeerServerEvent {
  const ClientDisconnected(this.id);
  final String id;
}

class ClientMessage extends PeerServerEvent {
  const ClientMessage(this.id, this.raw);
  final String id;
  final String raw;
}
