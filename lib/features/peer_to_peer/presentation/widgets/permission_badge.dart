import 'package:flutter/material.dart';

import '../../domain/entities/peer_entities.dart';
import 'peer_labels.dart';

class PermissionBadge extends StatelessWidget {
  const PermissionBadge({super.key, required this.permission});
  final PeerPermission permission;

  @override
  Widget build(BuildContext context) {
    final color = permission.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(permission.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            permission.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
