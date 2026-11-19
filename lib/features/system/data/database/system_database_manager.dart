import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../peer_to_peer/domain/entities/peer_connection_status.dart';
import '../../../peer_to_peer/domain/entities/peer_session.dart';
import '../../../peer_to_peer/domain/repositories/peer_repository.dart';
import 'system_database.dart';

class SystemDatabaseManager {
  SystemDatabaseManager(
    this._peerRepository, {
    SystemDatabase Function()? databaseFactory,
  }) : _databaseFactory = databaseFactory ?? SystemDatabase.new;

  final PeerRepository _peerRepository;
  final SystemDatabase Function() _databaseFactory;
  StreamSubscription<PeerSession>? _sessionSubscription;
  SystemDatabase? _database;
  Future<SystemDatabase>? _opening;
  bool _disposed = false;

  Future<void> start() async {
    _sessionSubscription ??= _peerRepository.sessionStream.listen(
      _onSessionChanged,
    );
    await _synchronize(_peerRepository.session);
  }

  Future<SystemDatabase> getDatabase() async {
    if (_disposed) {
      throw StateError('El administrador de la base de datos está cerrado.');
    }
    if (!_isActiveMaster(_peerRepository.session)) {
      throw StateError(
        'La base de datos del sistema solo está disponible '
        'en el servidor maestro activo.',
      );
    }

    final current = _database;
    if (current != null) return current;

    final opening = _opening ??= _openDatabase();
    try {
      return await opening;
    } finally {
      if (identical(_opening, opening)) _opening = null;
    }
  }

  void _onSessionChanged(PeerSession session) {
    unawaited(_synchronize(session));
  }

  Future<void> _synchronize(PeerSession session) async {
    if (_isActiveMaster(session)) {
      try {
        await getDatabase();
      } catch (error, stackTrace) {
        debugPrint(
          'No se pudo abrir la base de datos del sistema: $error\n'
          '$stackTrace',
        );
      }
      return;
    }

    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<SystemDatabase> _openDatabase() async {
    final database = _databaseFactory();
    try {
      await database.customSelect('SELECT 1').get();
      if (_disposed || !_isActiveMaster(_peerRepository.session)) {
        await database.close();
        throw StateError(
          'La sesión dejó de ser maestra al abrir la base '
          'de datos.',
        );
      }
      _database = database;
      return database;
    } catch (_) {
      if (!identical(_database, database)) await database.close();
      rethrow;
    }
  }

  bool _isActiveMaster(PeerSession session) =>
      session.isMaster && session.status == PeerConnectionStatus.listening;

  Future<void> dispose() async {
    _disposed = true;
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    final database = _database;
    _database = null;
    await database?.close();
  }
}
