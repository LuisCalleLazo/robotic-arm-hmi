import 'package:flutter/material.dart';

import '../../domain/entities/peer_entities.dart';

extension PeerRoleUi on PeerRole {
  String get label => switch (this) {
        PeerRole.master => 'Maestro',
        PeerRole.slave => 'Esclavo',
      };

  IconData get icon => switch (this) {
        PeerRole.master => Icons.dns_rounded,
        PeerRole.slave => Icons.settings_remote_rounded,
      };
}

extension PeerMachineUi on PeerMachineType {
  String get label => switch (this) {
        PeerMachineType.brazo => 'Brazo',
        PeerMachineType.cintaPequena => 'Cinta transportadora pequeña',
        PeerMachineType.cintaGrande => 'Cinta transportadora grande',
      };

  IconData get icon => switch (this) {
        PeerMachineType.brazo => Icons.precision_manufacturing_rounded,
        PeerMachineType.cintaPequena => Icons.swap_horiz_rounded,
        PeerMachineType.cintaGrande => Icons.sync_alt_rounded,
      };
}

extension PeerPermissionUi on PeerPermission {
  String get label => switch (this) {
        PeerPermission.viewOnly => 'Solo lectura',
        PeerPermission.control => 'Control',
      };

  IconData get icon => switch (this) {
        PeerPermission.viewOnly => Icons.visibility_rounded,
        PeerPermission.control => Icons.gamepad_rounded,
      };

  Color get color => switch (this) {
        PeerPermission.viewOnly => Colors.blueGrey,
        PeerPermission.control => Colors.indigo,
      };
}

extension PeerStatusUi on PeerConnectionStatus {
  String get label => switch (this) {
        PeerConnectionStatus.disconnected => 'Desconectado',
        PeerConnectionStatus.connecting => 'Conectando…',
        PeerConnectionStatus.listening => 'Escuchando',
        PeerConnectionStatus.connected => 'Conectado',
        PeerConnectionStatus.error => 'Error',
      };

  Color get color => switch (this) {
        PeerConnectionStatus.disconnected => Colors.grey,
        PeerConnectionStatus.connecting => Colors.orange,
        PeerConnectionStatus.listening => Colors.green,
        PeerConnectionStatus.connected => Colors.green,
        PeerConnectionStatus.error => Colors.red,
      };
}
