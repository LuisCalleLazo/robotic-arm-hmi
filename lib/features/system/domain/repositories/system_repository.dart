import '../entities/motor.dart';
import '../entities/process.dart';
import '../entities/process_motors.dart';
import '../entities/process_servo.dart';
import '../entities/sensor.dart';
import '../entities/servo.dart';
import '../entities/system_machine.dart';

abstract interface class SystemRepository {
  Future<SystemMachine?> getMachine(int id);
  Future<List<SystemMachine>> getMachines();
  Future<void> saveMachine(SystemMachine machine);
  Future<void> deleteMachine(int id);
  Future<void> deleteMachineTree(int id);

  Future<List<Process>> getProcesses();
  Future<void> saveProcess(Process process);
  Future<void> deleteProcess(int id);
  Future<bool> hasProcessHistory(int id);

  Future<List<Sensor>> getSensors();
  Future<void> saveSensor(Sensor sensor);
  Future<void> deleteSensor(int id);

  Future<List<Motor>> getMotors();
  Future<void> saveMotor(Motor motor);
  Future<void> deleteMotor(int id);
  Future<List<Servo>> getServos();
  Future<void> saveServo(Servo servo);
  Future<void> deleteServo(int id);

  Future<List<ProcessMotors>> getProcessMotors(int processId);
  Future<void> saveProcessMotor(ProcessMotors processMotor);
  Future<void> deleteProcessMotor(int id);
  Future<bool> hasProcessMotorHistory(int id);
  Future<List<ProcessServo>> getProcessServos(int processId);
  Future<void> saveProcessServo(ProcessServo processServo);
  Future<void> deleteProcessServo(int id);
}
