import 'package:get_it/get_it.dart';

import '../../features/peer_to_peer/peer_injection.dart';
import '../../features/serial_connection/data/datasources/serial_datasource.dart';
import '../../features/serial_connection/data/repositories/serial_repository_impl.dart';
import '../../features/serial_connection/domain/repositories/serial_repository.dart';
import '../../features/serial_connection/presentation/bloc/connection_bloc.dart';
import '../../features/system/system_injection.dart';
import '../../features/system/domain/services/system_configuration_service.dart';
import '../../features/telemetry/data/parsers/telemetry_parser.dart';
import '../../features/telemetry/data/serial_peer_bridge.dart';
import '../../features/telemetry/presentation/cubit/telemetry_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    // Data
    ..registerLazySingleton<SerialDatasource>(SerialDatasource.new)
    ..registerLazySingleton<SerialRepository>(
      () => SerialRepositoryImpl(sl<SerialDatasource>()),
    )
    ..registerLazySingleton<TelemetryParser>(TelemetryParser.new)
    // Presentation (singletons: el historial sobrevive al cambio de pantalla)
    ..registerLazySingleton<ConnectionBloc>(
      () => ConnectionBloc(
        sl<SerialRepository>(),
        onCommandSent: sl<TelemetryCubit>().recordSent,
      ),
    )
    ..registerLazySingleton<TelemetryCubit>(
      () => TelemetryCubit(
        repository: sl<SerialRepository>(),
        parser: sl<TelemetryParser>(),
      ),
    );

  registerPeerToPeer(sl);
  registerSystem(sl);
  sl<SystemConfigurationService>();
  sl.registerLazySingleton<SerialPeerBridge>(
    () => SerialPeerBridge(
      serial: sl<SerialRepository>(),
      peer: sl(),
      telemetry: sl<TelemetryCubit>(),
    ),
  );
  sl<SerialPeerBridge>();
}
