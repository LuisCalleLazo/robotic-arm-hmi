import '../../domain/entities/process_historic.dart';
import '../../domain/entities/process_historic_motors.dart';
import '../../domain/repositories/system_history_repository.dart';
import '../datasources/system_local_datasource.dart';

class SystemHistoryRepositoryImpl implements SystemHistoryRepository {
  SystemHistoryRepositoryImpl(this._dataSource);

  final SystemLocalDataSource _dataSource;

  @override
  Future<List<ProcessHistoric>> getProcessHistorics(int processId) =>
      _dataSource.getProcessHistorics(processId);

  @override
  Future<void> saveProcessHistoric(ProcessHistoric historic) =>
      _dataSource.saveProcessHistoric(historic);

  @override
  Future<List<ProcessHistoricMotors>> getProcessHistoricMotors(
    int processMotorId,
  ) => _dataSource.getProcessHistoricMotors(processMotorId);

  @override
  Future<void> saveProcessHistoricMotor(ProcessHistoricMotors historicMotor) =>
      _dataSource.saveProcessHistoricMotor(historicMotor);
}
