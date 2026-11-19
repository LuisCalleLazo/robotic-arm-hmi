import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/peer_to_peer/presentation/cubit/peer_cubit.dart';
import 'features/peer_to_peer/presentation/screens/peer_connection_screen.dart';
import 'features/serial_connection/domain/repositories/serial_repository.dart';
import 'features/serial_connection/presentation/bloc/connection_bloc.dart';
import 'features/system/data/database/system_database_manager.dart';
import 'features/system/domain/services/system_configuration_service.dart';
import 'features/system/presentation/pages/system_shell_page.dart';
import 'features/telemetry/presentation/cubit/telemetry_cubit.dart';

class HmiApp extends StatefulWidget {
  const HmiApp({super.key});

  @override
  State<HmiApp> createState() => _HmiAppState();
}

class _HmiAppState extends State<HmiApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Cierra las conexiones al cerrar la aplicación.
    _lifecycle = AppLifecycleListener(
      onDetach: () {
        unawaited(sl<PeerCubit>().disconnect());
        unawaited(sl<SystemConfigurationService>().dispose());
        unawaited(sl<SystemDatabaseManager>().dispose());
        sl<SerialRepository>().dispose();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Los blocs viven durante toda la app (singletons de get_it),
    // por eso se proveen con `.value` y no se cierran aquí.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectionBloc>.value(value: sl<ConnectionBloc>()),
        BlocProvider<TelemetryCubit>.value(value: sl<TelemetryCubit>()),
        BlocProvider<PeerCubit>.value(value: sl<PeerCubit>()),
      ],
      child: MaterialApp(
        title: 'HMI Arduino',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _RootGate(),
      ),
    );
  }
}

/// Primero requiere una sesión de red; después muestra el sistema completo.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeerCubit, PeerState>(
      buildWhen: (previous, current) =>
          previous.session.isActive != current.session.isActive,
      builder: (context, peerState) {
        if (!peerState.session.isActive) {
          return const PeerConnectionScreen(key: ValueKey('peer-connection'));
        }

        return const SystemShellPage(key: ValueKey('system-shell'));
      },
    );
  }
}
