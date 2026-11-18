import 'package:flutter/material.dart';

import '../../domain/entities/peer_entities.dart';
import 'connection_status_chip.dart';
import 'peer_labels.dart';
import 'permission_badge.dart';

class SessionStatusCard extends StatelessWidget {
  const SessionStatusCard({super.key, required this.session});
  final PeerSession session;

  Widget _row(String label, Widget value) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Text('$label: '),
            Flexible(child: value),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = session.role;
    final machine = session.machine;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(role?.icon ?? Icons.link_off_rounded),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    role == null ? 'Sin sesión activa' : 'Rol: ${role.label}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Spacer(),
                ConnectionStatusChip(status: session.status),
              ],
            ),
            if (session.deviceName != null)
              _row('Nombre', Text(session.deviceName!)),
            if (session.isSlave) ...[
              if (machine != null)
                _row(
                  'Máquina',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(machine.icon, size: 18),
                      const SizedBox(width: 6),
                      Flexible(child: Text(machine.label)),
                    ],
                  ),
                ),
              _row('Permiso', PermissionBadge(permission: session.permission)),
              if (session.host != null)
                _row(
                  'Maestro',
                  Text(
                    '${session.masterName ?? session.host} '
                    '(${session.host}:${session.port})',
                  ),
                ),
            ],
            if (session.isMaster) ...[
              _row('Permiso', const Text('Control total')),
              if (session.addresses.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Conexión manual por IP:'),
                for (final a in session.addresses)
                  SelectableText(
                    '$a:${session.port}',
                    style: theme.textTheme.titleSmall,
                  ),
              ],
            ],
            if (session.error != null) ...[
              const SizedBox(height: 12),
              Text(
                session.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
