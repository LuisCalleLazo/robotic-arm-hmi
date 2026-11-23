import 'dart:async';

import 'package:get_it/get_it.dart';

import '../peer_to_peer/domain/repositories/peer_repository.dart';
import 'data/database/system_database_manager.dart';
import 'data/datasources/system_local_datasource.dart';
import 'data/repositories/system_position_repository_impl.dart';
import 'data/repositories/system_history_repository_impl.dart';
import 'data/repositories/system_repository_impl.dart';
import 'domain/repositories/system_history_repository.dart';
import 'domain/repositories/system_position_repository.dart';
import 'domain/repositories/system_repository.dart';
import 'domain/services/system_configuration_service.dart';

void registerSystem(GetIt sl) {
  final databaseManager = SystemDatabaseManager(sl<PeerRepository>());
  sl
    ..registerSingleton<SystemDatabaseManager>(databaseManager)
    ..registerLazySingleton(
      () => SystemLocalDataSource(sl<SystemDatabaseManager>()),
    )
    ..registerLazySingleton<SystemRepository>(
      () => SystemRepositoryImpl(sl<SystemLocalDataSource>()),
    )
    ..registerLazySingleton<SystemHistoryRepository>(
      () => SystemHistoryRepositoryImpl(sl<SystemLocalDataSource>()),
    )
    ..registerLazySingleton<SystemPositionRepository>(
      () => SystemPositionRepositoryImpl(sl<SystemLocalDataSource>()),
    )
    ..registerLazySingleton<SystemConfigurationService>(
      () => SystemConfigurationService(
        peer: sl<PeerRepository>(),
        system: sl<SystemRepository>(),
        positions: sl<SystemPositionRepository>(),
      ),
    );
  unawaited(databaseManager.start());
}
