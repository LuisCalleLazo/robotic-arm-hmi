import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/serial_connection/domain/repositories/serial_repository.dart';
import 'features/serial_connection/presentation/bloc/connection_bloc.dart';
import 'features/serial_connection/presentation/pages/connection_page.dart';
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
    // Cierra el puerto serial al cerrar la aplicación.
    _lifecycle = AppLifecycleListener(
      onDetach: () => sl<SerialRepository>().dispose(),
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

/// Muestra la pantalla de conexión o el dashboard según el estado del serial.
/// Si el USB se desconecta, vuelve solo a la pantalla de conexión.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, SerialConnectionState>(
      buildWhen: (previous, current) =>
          previous.isConnected != current.isConnected,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isConnected
              ? const DashboardPage(key: ValueKey('dashboard'))
              : const ConnectionPage(key: ValueKey('connection')),
        );
      },
    );
  }
}
