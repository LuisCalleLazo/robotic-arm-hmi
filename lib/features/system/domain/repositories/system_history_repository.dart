import '../entities/process_historic.dart';
import '../entities/process_historic_motors.dart';

abstract interface class SystemHistoryRepository {
  Future<List<ProcessHistoric>> getProcessHistorics(int processId);
  Future<void> saveProcessHistoric(ProcessHistoric historic);
  Future<List<ProcessHistoricMotors>> getProcessHistoricMotors(
    int processMotorId,
  );
  Future<void> saveProcessHistoricMotor(ProcessHistoricMotors historicMotor);
}
