import 'package:equatable/equatable.dart';

class PortInfo extends Equatable {
  const PortInfo({required this.name, this.description});

  /// Ej: `COM3`, `/dev/ttyACM0`.
  final String name;

  /// Ej: `Arduino Uno`. Puede venir vacío según el SO/driver.
  final String? description;

  String get label => (description == null || description!.isEmpty)
      ? name
      : '$name — $description';

  @override
  List<Object?> get props => [name, description];
}
