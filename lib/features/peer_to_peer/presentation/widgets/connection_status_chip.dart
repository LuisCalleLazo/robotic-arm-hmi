import 'package:flutter/material.dart';

import '../../domain/entities/peer_entities.dart';
import 'peer_labels.dart';

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key, required this.status});
  final PeerConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: status.color),
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
    );
  }
}
