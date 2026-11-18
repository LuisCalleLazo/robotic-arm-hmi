import 'package:flutter/material.dart';

import '../cubit/peer_cubit.dart';
import '../widgets/peer_callbacks.dart';
import '../widgets/peer_connection_panel.dart';

/// Pantalla completa de conexión:
/// 1) Elegir Maestro / Esclavo
/// 2) Maestro → contraseña → nombre y puerto → servidor activo
///    Esclavo → elegir máquina y nombre → buscar maestro por nombre → conectar
/// 3) Al quedar conectado llama a [onMasterReady] o [onSlaveReady] (tú defines el destino).
class PeerConnectionScreen extends StatelessWidget {
  const PeerConnectionScreen({
    super.key,
    this.onMasterReady,
    this.onSlaveReady,
    this.cubit,
    this.title = 'Conexión HMI',
  });

  /// Destino cuando el dispositivo queda como maestro (servidor escuchando).
  final PeerReadyCallback? onMasterReady;

  /// Destino cuando el dispositivo queda como esclavo (conectado a un maestro).
  final PeerReadyCallback? onSlaveReady;

  final PeerCubit? cubit;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PeerConnectionPanel(
                cubit: cubit,
                onMasterReady: onMasterReady,
                onSlaveReady: onSlaveReady,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
