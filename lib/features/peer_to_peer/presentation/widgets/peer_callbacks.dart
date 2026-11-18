import 'package:flutter/widgets.dart';

import '../../domain/entities/peer_entities.dart';

/// Se invoca una vez cuando la conexión queda lista (maestro escuchando /
/// esclavo conectado) y también desde el botón "Continuar".
/// Aquí defines a dónde ir: navegar, cambiar de página, etc.
typedef PeerReadyCallback = void Function(
  BuildContext context,
  PeerSession session,
);
