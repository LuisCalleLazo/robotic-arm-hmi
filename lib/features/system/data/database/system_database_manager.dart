import 'package:flutter/foundation.dart';

import 'system_database.dart';

class SystemDatabaseManager {
  SystemDatabaseManager({SystemDatabase Function()? databaseFactory})
    : _databaseFactory = databaseFactory ?? SystemDatabase.new;

  final SystemDatabase Function() _databaseFactory;
  SystemDatabase? _database;
  Future<SystemDatabase>? _opening;
  bool _disposed = false;

  Future<void> start() async {
    await getDatabase();
  }

  Future<SystemDatabase> getDatabase() async {
    if (_disposed) {
      throw StateError('El administrador de la base de datos está cerrado.');
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

  Future<SystemDatabase> _openDatabase() async {
    final database = _databaseFactory();
    try {
      await database.customSelect('SELECT 1').get();
      if (_disposed) {
        await database.close();
        throw StateError('La aplicación se cerró al abrir la base de datos.');
      }
      _database = database;
      return database;
    } catch (error, stackTrace) {
      if (!identical(_database, database)) {
        await database.close();
      }
      debugPrint(
        'No se pudo abrir la base de datos local: $error\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final database = _database;
    _database = null;
    await database?.close();
  }
}
