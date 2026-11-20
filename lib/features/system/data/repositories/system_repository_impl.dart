import '../../domain/entities/motor.dart';
import '../../domain/entities/process.dart' as system;
import '../../domain/entities/process_motors.dart';
import '../../domain/entities/process_servo.dart';
import '../../domain/entities/sensor.dart';
import '../../domain/entities/servo.dart';
import '../../domain/entities/system_machine.dart';
import '../../domain/repositories/system_repository.dart';
import '../datasources/system_local_datasource.dart';

class SystemRepositoryImpl implements SystemRepository {
  SystemRepositoryImpl(this._dataSource);

  final SystemLocalDataSource _dataSource;

  @override
  Future<SystemMachine?> getMachine(int id) => _dataSource.getMachine(id);

  @override
  Future<List<SystemMachine>> getMachines() => _dataSource.getMachines();

  @override
  Future<void> saveMachine(SystemMachine machine) =>
      _dataSource.saveMachine(machine);

  @override
  Future<void> deleteMachine(int id) => _dataSource.deleteMachine(id);

  @override
  Future<void> deleteMachineTree(int id) => _dataSource.deleteMachineTree(id);

  @override
  Future<List<system.Process>> getProcesses() => _dataSource.getProcesses();

  @override
  Future<void> saveProcess(system.Process process) =>
      _dataSource.saveProcess(process);

  @override
  Future<void> deleteProcess(int id) => _dataSource.deleteProcess(id);

  @override
  Future<bool> hasProcessHistory(int id) => _dataSource.hasProcessHistory(id);

  @override
  Future<List<Sensor>> getSensors() => _dataSource.getSensors();

  @override
  Future<void> saveSensor(Sensor sensor) => _dataSource.saveSensor(sensor);

  @override
  Future<void> deleteSensor(int id) => _dataSource.deleteSensor(id);

  @override
  Future<List<Motor>> getMotors() => _dataSource.getMotors();

  @override
  Future<void> saveMotor(Motor motor) => _dataSource.saveMotor(motor);

  @override
  Future<List<Servo>> getServos() => _dataSource.getServos();

  @override
  Future<void> saveServo(Servo servo) => _dataSource.saveServo(servo);

  @override
  Future<List<ProcessMotors>> getProcessMotors(int processId) =>
      _dataSource.getProcessMotors(processId);

  @override
  Future<void> saveProcessMotor(ProcessMotors processMotor) =>
      _dataSource.saveProcessMotor(processMotor);

  @override
  Future<void> deleteProcessMotor(int id) => _dataSource.deleteProcessMotor(id);

  @override
  Future<bool> hasProcessMotorHistory(int id) =>
      _dataSource.hasProcessMotorHistory(id);

  @override
  Future<List<ProcessServo>> getProcessServos(int processId) =>
      _dataSource.getProcessServos(processId);

  @override
  Future<void> saveProcessServo(ProcessServo processServo) =>
      _dataSource.saveProcessServo(processServo);

  @override
  Future<void> deleteProcessServo(int id) => _dataSource.deleteProcessServo(id);
}
