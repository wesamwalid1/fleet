import '../../domain/entities/driver.dart';

class DriverModel {
  final String id;
  final String fullName;

  const DriverModel({this.id = 'DR-001', required this.fullName});

  Driver toEntity() => Driver(id: id, fullName: fullName);
}
