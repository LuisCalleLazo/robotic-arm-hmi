import 'package:flutter/material.dart';

import '../cubit/peer_cubit.dart';
import 'peer_connection_panel.dart';

/// Abre el panel completo en un diálogo (útil desde un botón o badge pequeño).
Future<void> showPeerConnectionDialog(
  BuildContext context, {
  PeerCubit? cubit,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PeerConnectionPanel(cubit: cubit),
        ),
      ),
    ),
  );
}
