import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/peer_entities.dart';
import '../cubit/peer_cubit.dart';
import 'peer_callbacks.dart';
import 'peer_master_panel.dart';
import 'peer_role_selection_panel.dart';
import 'peer_slave_panel.dart';

/// Flujo completo y embebible: rol → (maestro: contraseña) / (esclavo: máquina)
/// → conexión → callback de destino. Sin Scaffold, sin scroll y sin navegación.
class PeerConnectionPanel extends StatefulWidget {
  const PeerConnectionPanel({
    super.key,
    this.cubit,
    this.defaultPort = PeerConfig.defaultPort,
    this.defaultMasterName = 'Maestro HMI',
    this.defaultSlaveName = '',
    this.onMasterReady,
    this.onSlaveReady,
  });

  final PeerCubit? cubit;
  final int defaultPort;
  final String defaultMasterName;
  final String defaultSlaveName;

  /// A dónde ir cuando el maestro queda escuchando.
  final PeerReadyCallback? onMasterReady;

  /// A dónde ir cuando el esclavo queda conectado (`session.machine` indica la máquina).
  final PeerReadyCallback? onSlaveReady;

  @override
  State<PeerConnectionPanel> createState() => _PeerConnectionPanelState();
}

class _PeerConnectionPanelState extends State<PeerConnectionPanel> {
  PeerRole? _role;

  PeerCubit get _cubit => widget.cubit ?? GetIt.I<PeerCubit>();

  @override
  void initState() {
    super.initState();
    // Si ya hay una sesión, abre directamente su panel.
    _role = _cubit.state.session.role;
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    if (role == null) {
      return PeerRoleSelectionPanel(
        cubit: _cubit,
        onRoleSelected: (r) => setState(() => _role = r),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _role = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Cambiar rol'),
          ),
        ),
        if (role == PeerRole.master)
          PeerMasterPanel(
            cubit: _cubit,
            defaultName: widget.defaultMasterName,
            defaultPort: widget.defaultPort,
            onReady: widget.onMasterReady,
          )
        else
          PeerSlavePanel(
            cubit: _cubit,
            defaultName: widget.defaultSlaveName,
            defaultPort: widget.defaultPort,
            onReady: widget.onSlaveReady,
          ),
      ],
    );
  }
}
