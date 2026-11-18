import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../cubit/peer_cubit.dart';
import 'peer_connection_dialog.dart';
import 'peer_labels.dart';

/// Chip compacto con rol + estado (+ permiso si eres esclavo).
/// Ideal para AppBar, barras laterales o headers. Por defecto abre el diálogo.
class PeerStatusBadge extends StatelessWidget {
  const PeerStatusBadge({super.key, this.cubit, this.onTap});

  final PeerCubit? cubit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = cubit ?? GetIt.I<PeerCubit>();
    return BlocBuilder<PeerCubit, PeerState>(
      bloc: c,
      builder: (context, state) {
        final s = state.session;
        var label = s.role == null
            ? 'Sin conexión'
            : '${s.role!.label} · ${s.status.label}';
        if (s.isSlave && s.isActive) label += ' · ${s.permission.label}';
        return ActionChip(
          avatar: Icon(Icons.circle, size: 12, color: s.status.color),
          label: Text(label),
          visualDensity: VisualDensity.compact,
          onPressed: onTap ?? () => showPeerConnectionDialog(context, cubit: c),
        );
      },
    );
  }
}
