import '../entities/system_position.dart';

abstract interface class SystemPositionRepository {
  Future<List<SystemPosition>> getSystemPositions();
  Future<void> saveSystemPosition(SystemPosition position);
  Future<void> deleteSystemPosition(int id);
}
