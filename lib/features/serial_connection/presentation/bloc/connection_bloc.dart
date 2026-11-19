import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/port_info.dart';
import '../../domain/entities/serial_config.dart';
import '../../domain/repositories/serial_repository.dart';

// ───────────────────────────── Eventos ─────────────────────────────

sealed class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => const [];
}

class PortsRefreshed extends ConnectionEvent {
  const PortsRefreshed();
}

class PortSelected extends ConnectionEvent {
  const PortSelected(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class BaudRateSelected extends ConnectionEvent {
  const BaudRateSelected(this.baudRate);

  final int baudRate;

  @override
  List<Object?> get props => [baudRate];
}

class ConnectRequested extends ConnectionEvent {
  const ConnectRequested();
}

class DisconnectRequested extends ConnectionEvent {
  const DisconnectRequested();
}

class CommandSent extends ConnectionEvent {
  const CommandSent(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Interno: el repositorio avisó que el puerto se cerró.
class LinkLost extends ConnectionEvent {
  const LinkLost();
}

// ───────────────────────────── Estado ─────────────────────────────

enum LinkStatus { disconnected, connecting, connected }

class SerialConnectionState extends Equatable {
  const SerialConnectionState({
    this.ports = const [],
    this.selectedPort,
    this.baudRate = kDefaultBaudRate,
    this.status = LinkStatus.disconnected,
    this.error,
  });

  final List<PortInfo> ports;
  final String? selectedPort;
  final int baudRate;
  final LinkStatus status;
  final String? error;

  bool get isConnected => status == LinkStatus.connected;
  bool get isConnecting => status == LinkStatus.connecting;
  bool get canConnect =>
      selectedPort != null && status == LinkStatus.disconnected;

  SerialConnectionState copyWith({
    List<PortInfo>? ports,
    String? selectedPort,
    bool clearSelectedPort = false,
    int? baudRate,
    LinkStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return SerialConnectionState(
      ports: ports ?? this.ports,
      selectedPort: clearSelectedPort
          ? null
          : (selectedPort ?? this.selectedPort),
      baudRate: baudRate ?? this.baudRate,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [ports, selectedPort, baudRate, status, error];
}

// ────────────────────────────── Bloc ──────────────────────────────

class ConnectionBloc extends Bloc<ConnectionEvent, SerialConnectionState> {
  ConnectionBloc(this._repository, {void Function(String)? onCommandSent})
    : _onCommandSentLog = onCommandSent,
      super(const SerialConnectionState()) {
    on<PortsRefreshed>(_onPortsRefreshed);
    on<PortSelected>(
      (event, emit) => emit(state.copyWith(selectedPort: event.name)),
    );
    on<BaudRateSelected>(
      (event, emit) => emit(state.copyWith(baudRate: event.baudRate)),
    );
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<CommandSent>(_onCommandSent);
    on<LinkLost>(_onLinkLost);

    _linkSub = _repository.connectionChanges.listen((connected) {
      if (!connected) add(const LinkLost());
    });

    // Detecta Arduinos conectados/desconectados mientras no hay sesión abierta.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.status == LinkStatus.disconnected) add(const PortsRefreshed());
    });

    add(const PortsRefreshed());
  }

  final SerialRepository _repository;
  final void Function(String)? _onCommandSentLog;
  late final StreamSubscription<bool> _linkSub;
  late final Timer _pollTimer;

  Future<void> _onPortsRefreshed(
    PortsRefreshed event,
    Emitter<SerialConnectionState> emit,
  ) async {
    final ports = await _repository.listPorts();
    final names = ports.map((p) => p.name).toSet();

    var selected = state.selectedPort;
    if (selected == null || !names.contains(selected)) {
      selected = _preferredPort(ports);
    }

    emit(
      state.copyWith(
        ports: ports,
        selectedPort: selected,
        clearSelectedPort: selected == null,
      ),
    );
  }

  /// Prefiere un puerto cuya descripción mencione "arduino"; si no, el primero.
  String? _preferredPort(List<PortInfo> ports) {
    if (ports.isEmpty) return null;
    for (final port in ports) {
      if ((port.description ?? '').toLowerCase().contains('arduino')) {
        return port.name;
      }
    }
    return ports.first.name;
  }

  Future<void> _onConnectRequested(
    ConnectRequested event,
    Emitter<SerialConnectionState> emit,
  ) async {
    final port = state.selectedPort;
    if (port == null || state.status != LinkStatus.disconnected) return;

    emit(state.copyWith(status: LinkStatus.connecting, clearError: true));
    try {
      await _repository.connect(
        SerialConfig(portName: port, baudRate: state.baudRate),
      );
      emit(state.copyWith(status: LinkStatus.connected));
    } catch (e) {
      emit(
        state.copyWith(status: LinkStatus.disconnected, error: e.toString()),
      );
    }
  }

  Future<void> _onDisconnectRequested(
    DisconnectRequested event,
    Emitter<SerialConnectionState> emit,
  ) async {
    // Se emite primero para que el `LinkLost` posterior sea ignorado.
    emit(state.copyWith(status: LinkStatus.disconnected, clearError: true));
    await _repository.disconnect();
  }

  void _onCommandSent(CommandSent event, Emitter<SerialConnectionState> emit) {
    if (!state.isConnected) return;
    _onCommandSentLog?.call(event.text);
    _repository.send(event.text);
  }

  void _onLinkLost(LinkLost event, Emitter<SerialConnectionState> emit) {
    if (state.status == LinkStatus.disconnected) return;
    emit(
      state.copyWith(
        status: LinkStatus.disconnected,
        error:
            'Se perdió la conexión con ${state.selectedPort ?? 'el puerto'}.',
      ),
    );
  }

  @override
  Future<void> close() async {
    _pollTimer.cancel();
    await _linkSub.cancel();
    return super.close();
  }
}
