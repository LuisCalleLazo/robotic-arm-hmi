import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/peer_entities.dart';
import '../cubit/peer_cubit.dart';
import 'client_tile.dart';
import 'peer_callbacks.dart';
import 'session_status_card.dart';

/// Panel del maestro: 1) contraseña  2) nombre + puerto  3) servidor activo
/// con la lista de máquinas conectadas. Sin Scaffold ni scroll.
class PeerMasterPanel extends StatefulWidget {
  const PeerMasterPanel({
    super.key,
    this.cubit,
    this.defaultName = 'Maestro HMI',
    this.defaultPort = PeerConfig.defaultPort,
    this.onReady,
  });

  /// Si es null se resuelve con `GetIt.I<PeerCubit>()`.
  final PeerCubit? cubit;
  final String defaultName;
  final int defaultPort;

  /// Destino cuando el servidor queda activo.
  final PeerReadyCallback? onReady;

  @override
  State<PeerMasterPanel> createState() => _PeerMasterPanelState();
}

class _PeerMasterPanelState extends State<PeerMasterPanel> {
  late final _passCtrl = TextEditingController();
  late final _nameCtrl = TextEditingController(text: widget.defaultName);
  late final _portCtrl = TextEditingController(text: '${widget.defaultPort}');
  bool _unlocked = false;
  bool _obscure = true;
  String? _password;
  String? _passwordError;
  String? _nameError;
  String? _portError;

  PeerCubit get _cubit => widget.cubit ?? GetIt.I<PeerCubit>();

  @override
  void dispose() {
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final ok = _cubit.verifyMasterPassword(_passCtrl.text);
    setState(() {
      _unlocked = ok;
      _password = ok ? _passCtrl.text : null;
      _passwordError = ok ? null : 'Contraseña incorrecta';
      if (ok) _passCtrl.clear();
    });
  }

  void _lock() => setState(() {
        _unlocked = false;
        _password = null;
      });

  void _start() {
    final name = _nameCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim());
    final nameError = name.isEmpty ? 'Ingresa un nombre' : null;
    final portError =
        (port == null || port < 1024 || port > 65535) ? 'Puerto: 1024 - 65535' : null;
    setState(() {
      _nameError = nameError;
      _portError = portError;
    });
    if (nameError != null || portError != null || _password == null) return;
    _cubit.startMaster(password: _password!, name: name, port: port!);
  }

  Future<void> _stop() async {
    _lock();
    await _cubit.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PeerCubit, PeerState>(
      bloc: _cubit,
      listenWhen: (p, c) =>
          p.session.isMaster && p.session.isActive && !c.session.isActive,
      listener: (context, state) => _lock(),
      child: BlocListener<PeerCubit, PeerState>(
        bloc: _cubit,
        listenWhen: (p, c) =>
            !p.session.isActive && c.session.isMaster && c.session.isActive,
        listener: (context, state) => widget.onReady?.call(context, state.session),
        child: BlocBuilder<PeerCubit, PeerState>(
          bloc: _cubit,
          builder: (context, state) {
            final view = state.session.isMaster
                ? state.session
                : const PeerSession(role: PeerRole.master);
            final running = view.status == PeerConnectionStatus.listening;
            final busy = view.status == PeerConnectionStatus.connecting;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SessionStatusCard(session: view),
                const SizedBox(height: 16),
                if (running)
                  ..._running(context, view)
                else if (!_unlocked)
                  ..._gate()
                else
                  ..._config(busy),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _gate() => [
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          onSubmitted: (_) => _verify(),
          decoration: InputDecoration(
            labelText: 'Contraseña de maestro',
            border: const OutlineInputBorder(),
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _verify,
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('Entrar como maestro'),
        ),
      ];

  List<Widget> _config(bool busy) => [
        TextField(
          controller: _nameCtrl,
          enabled: !busy,
          decoration: InputDecoration(
            labelText: 'Nombre del maestro (así lo buscan los esclavos)',
            border: const OutlineInputBorder(),
            errorText: _nameError,
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
          onPressed: busy ? null : _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar servidor'),
        ),
      ];

  List<Widget> _running(BuildContext context, PeerSession view) => [
        if (widget.onReady != null) ...[
          FilledButton.icon(
            onPressed: () => widget.onReady!(context, view),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continuar'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _stop,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Detener servidor'),
        ),
        const SizedBox(height: 20),
        Text(
          'Máquinas conectadas (${view.clients.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (view.clients.isEmpty)
          const Text('Esperando máquinas…')
        else
          for (final c in view.clients)
            ClientTile(
              client: c,
              onPermissionChanged: (p) => _cubit.setPermission(c.id, p),
              onKick: () => _cubit.kick(c.id),
            ),
      ];
}
