import '../../domain/entities/system_position.dart';
import '../../domain/repositories/system_position_repository.dart';
import '../datasources/system_local_datasource.dart';

class SystemPositionRepositoryImpl implements SystemPositionRepository {
  SystemPositionRepositoryImpl(this._dataSource);

  final SystemLocalDataSource _dataSource;

  @override
  Future<List<SystemPosition>> getSystemPositions() =>
      _dataSource.getSystemPositions();

  @override
  Future<void> saveSystemPosition(SystemPosition position) =>
      _dataSource.saveSystemPosition(position);

  @override
  Future<void> deleteSystemPosition(int id) =>
      _dataSource.deleteSystemPosition(id);
}
