import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/peer_entities.dart';
import '../cubit/peer_cubit.dart';
import 'role_card.dart';
import 'session_status_card.dart';

/// Selección de rol + estado actual. No navega: avisa con [onRoleSelected].
class PeerRoleSelectionPanel extends StatelessWidget {
  const PeerRoleSelectionPanel({
    super.key,
    required this.onRoleSelected,
    this.cubit,
  });

  final ValueChanged<PeerRole> onRoleSelected;
  final PeerCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final c = cubit ?? GetIt.I<PeerCubit>();
    return BlocBuilder<PeerCubit, PeerState>(
      bloc: c,
      builder: (context, state) {
        final session = state.session;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SessionStatusCard(session: session),
            if (session.role != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onRoleSelected(session.role!),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Abrir sesión'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: c.disconnect,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Desconectar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '¿Cómo vas a entrar?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RoleCard(
              icon: Icons.dns_rounded,
              title: 'Maestro',
              description:
                  'Requiere contraseña. Ve las máquinas conectadas y administra sus permisos.',
              disabledReason: c.isMasterSupported
                  ? null
                  : 'No disponible en web: solo puedes entrar como esclavo.',
              onTap: () => onRoleSelected(PeerRole.master),
            ),
            RoleCard(
              icon: Icons.settings_remote_rounded,
              title: 'Esclavo',
              description:
                  'Elige qué máquina eres y busca a tu maestro por nombre.',
              onTap: () => onRoleSelected(PeerRole.slave),
            ),
          ],
        );
      },
    );
  }
}
