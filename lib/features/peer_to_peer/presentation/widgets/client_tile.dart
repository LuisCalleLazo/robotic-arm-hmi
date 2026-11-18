import 'package:flutter/material.dart';

import '../../domain/entities/peer_entities.dart';
import 'peer_labels.dart';

/// Esclavo (máquina) visto por el maestro.
class ClientTile extends StatelessWidget {
  const ClientTile({
    super.key,
    required this.client,
    required this.onPermissionChanged,
    required this.onKick,
  });

  final PeerClient client;
  final ValueChanged<PeerPermission> onPermissionChanged;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(client.machine.icon),
        title: Text(client.name),
        subtitle: Text('${client.machine.label} · ${client.permission.label}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Permitir control',
              child: Switch(
                value: client.permission.canSendCommands,
                onChanged: (v) => onPermissionChanged(
                  v ? PeerPermission.control : PeerPermission.viewOnly,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Expulsar',
              icon: const Icon(Icons.person_remove_rounded),
              onPressed: onKick,
            ),
          ],
        ),
      ),
    );
  }
}
