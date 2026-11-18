// Dominio
export 'domain/entities/peer_entities.dart';
export 'domain/repositories/peer_repository.dart';
export 'domain/usecases/watch_peer_messages_usecase.dart';
export 'domain/usecases/watch_peer_session_usecase.dart';

// DI + estado
export 'peer_injection.dart';
export 'presentation/cubit/peer_cubit.dart';

// Pantalla grande
export 'presentation/screens/peer_connection_screen.dart';

// Widgets embebibles
export 'presentation/widgets/peer_callbacks.dart';
export 'presentation/widgets/peer_connection_dialog.dart';
export 'presentation/widgets/peer_connection_panel.dart';
export 'presentation/widgets/peer_master_panel.dart';
export 'presentation/widgets/peer_role_selection_panel.dart';
export 'presentation/widgets/peer_slave_panel.dart';
export 'presentation/widgets/peer_status_badge.dart';
