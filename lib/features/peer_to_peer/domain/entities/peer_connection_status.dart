enum PeerConnectionStatus {
  disconnected,
  connecting,

  /// Solo maestro: servidor levantado esperando esclavos.
  listening,

  /// Solo esclavo: conectado al maestro.
  connected,
  error,
}
