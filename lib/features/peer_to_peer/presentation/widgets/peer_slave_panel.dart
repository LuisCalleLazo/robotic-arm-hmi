import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/peer_entities.dart';
import '../cubit/peer_cubit.dart';
import 'peer_callbacks.dart';
import 'peer_labels.dart';
import 'session_status_card.dart';

/// Panel del esclavo: elegir máquina + nombre, buscar maestro por nombre
/// (o conectar por IP) y ver el estado. Sin Scaffold ni scroll.
class PeerSlavePanel extends StatefulWidget {
  const PeerSlavePanel({
    super.key,
    this.cubit,
    this.defaultName = '',
    this.defaultMachine,
    this.defaultHost,
    this.defaultPort = PeerConfig.defaultPort,
    this.onReady,
  });

  /// Si es null se resuelve con `GetIt.I<PeerCubit>()`.
  final PeerCubit? cubit;
  final String defaultName;
  final PeerMachineType? defaultMachine;

  /// Host inicial para la conexión manual (en web usa el host de la página).
  final String? defaultHost;
  final int defaultPort;

  /// Destino cuando el esclavo queda conectado.
  final PeerReadyCallback? onReady;

  @override
  State<PeerSlavePanel> createState() => _PeerSlavePanelState();
}

class _PeerSlavePanelState extends State<PeerSlavePanel> {
  late final _nameCtrl = TextEditingController(text: widget.defaultName);
  late final _filterCtrl = TextEditingController();
  late final _hostCtrl = TextEditingController(
    text: widget.defaultHost ?? (kIsWeb ? Uri.base.host : ''),
  );
  late final _portCtrl = TextEditingController(text: '${widget.defaultPort}');

  PeerMachineType? _machine;
  String? _machineError;
  String? _nameError;
  String? _hostError;
  String? _portError;

  final _found = <PeerMasterInfo>[];
  bool _searching = false;
  StreamSubscription<PeerMasterInfo>? _searchSub;

  PeerCubit get _cubit => widget.cubit ?? GetIt.I<PeerCubit>();

  @override
  void initState() {
    super.initState();
    _machine = widget.defaultMachine;
    if (_cubit.isDiscoverySupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    _nameCtrl.dispose();
    _filterCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _search() {
    _searchSub?.cancel();
    setState(() {
      _found.clear();
      _searching = true;
    });
    _searchSub = _cubit.discoverMasters().listen(
      (m) {
        if (mounted) setState(() => _found.add(m));
      },
      onDone: () {
        if (mounted) setState(() => _searching = false);
      },
      onError: (_) {
        if (mounted) setState(() => _searching = false);
      },
    );
  }

  List<PeerMasterInfo> get _filtered {
    final q = _filterCtrl.text.trim().toLowerCase();
    return _found.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  void _connect(String host, int port) {
    final name = _nameCtrl.text.trim();
    setState(() {
      _machineError = _machine == null ? 'Selecciona la máquina' : null;
      _nameError = name.isEmpty ? 'Ingresa un nombre' : null;
    });
    if (_machine == null || name.isEmpty) return;
    _searchSub?.cancel();
    _cubit.connectSlave(host: host, port: port, name: name, machine: _machine!);
  }

  void _connectManual() {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim());
    final hostError = host.isEmpty ? 'Ingresa la IP del maestro' : null;
    final portError =
        (port == null || port < 1 || port > 65535) ? 'Puerto inválido' : null;
    setState(() {
      _hostError = hostError;
      _portError = portError;
    });
    if (hostError != null || portError != null) return;
    _connect(host, port!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PeerCubit, PeerState>(
      bloc: _cubit,
      listenWhen: (p, c) =>
          !p.session.isActive && c.session.isSlave && c.session.isActive,
      listener: (context, state) => widget.onReady?.call(context, state.session),
      child: BlocBuilder<PeerCubit, PeerState>(
        bloc: _cubit,
        builder: (context, state) {
          final view = state.session.isSlave
              ? state.session
              : const PeerSession(role: PeerRole.slave);
          final connected = view.status == PeerConnectionStatus.connected;
          final busy = view.status == PeerConnectionStatus.connecting;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SessionStatusCard(session: view),
              if (busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              if (connected) ..._connected(context, view) else ..._form(context, busy),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _connected(BuildContext context, PeerSession view) => [
        if (!view.permission.canSendCommands)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Solo puedes ver la telemetría. El maestro debe concederte permiso de control.',
            ),
          ),
        if (widget.onReady != null) ...[
          FilledButton.icon(
            onPressed: () => widget.onReady!(context, view),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continuar'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _cubit.disconnect,
          icon: const Icon(Icons.link_off_rounded),
          label: const Text('Desconectar'),
        ),
      ];

  List<Widget> _form(BuildContext context, bool busy) {
    final theme = Theme.of(context);
    final supported = _cubit.isDiscoverySupported;
    final matches = _filtered;
    return [
      Text('¿Qué máquina es este dispositivo?', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in PeerMachineType.values)
            ChoiceChip(
              avatar: Icon(m.icon, size: 18),
              label: Text(m.label),
              selected: _machine == m,
              onSelected: busy ? null : (_) => setState(() => _machine = m),
            ),
        ],
      ),
      if (_machineError != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _machineError!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      const SizedBox(height: 16),
      TextField(
        controller: _nameCtrl,
        enabled: !busy,
        decoration: InputDecoration(
          labelText: 'Nombre de este dispositivo',
          border: const OutlineInputBorder(),
          errorText: _nameError,
        ),
      ),
      const SizedBox(height: 20),
      if (supported) ...[
        Row(
          children: [
            Expanded(
              child: Text('Maestros disponibles', style: theme.textTheme.titleSmall),
            ),
            if (_searching)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: 'Buscar de nuevo',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: busy ? null : _search,
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _filterCtrl,
          enabled: !busy,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (matches.length == 1) _connect(matches.first.host, matches.first.port);
          },
          decoration: const InputDecoration(
            labelText: 'Buscar maestro por nombre',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _searching
                  ? 'Buscando maestros…'
                  : 'No se encontraron maestros. Verifica que estén en la misma red.',
            ),
          )
        else
          for (final m in matches)
            Card(
              child: ListTile(
                leading: const Icon(Icons.dns_rounded),
                title: Text(m.name),
                subtitle: Text('${m.host}:${m.port}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: busy ? null : () => _connect(m.host, m.port),
              ),
            ),
        ExpansionTile(
          title: const Text('Conectar por IP'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: _manualFields(busy),
        ),
      ] else ...[
        Text('Conectar al maestro', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ..._manualFields(busy),
        const SizedBox(height: 12),
        const Text(
          'En web no se puede buscar por nombre: escribe la IP del maestro. '
          'Sirve la app por http (no https) para poder usar ws://.',
        ),
      ],
    ];
  }

  List<Widget> _manualFields(bool busy) => [
        const SizedBox(height: 8),
        TextField(
          controller: _hostCtrl,
          enabled: !busy,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'IP del maestro',
            hintText: '192.168.1.10',
            border: const OutlineInputBorder(),
            errorText: _hostError,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _portCtrl,
          enabled: !busy,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Puerto',
            border: const OutlineInputBorder(),
            errorText: _portError,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _connectManual,
          icon: const Icon(Icons.link_rounded),
          label: const Text('Conectar'),
        ),
      ];
}
